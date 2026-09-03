# 研迹 YanJi — 数据库规范与实现状态

2026-09-03 · SYNC v1.1。协议语义以 SYNC.md 为准；本文是数据库结构、持久化状态与迁移的根说明。

## 配置与版本

Flutter 通过 Drift 在后台 isolate 打开 Application Support/yanji.sqlite。

```sql
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;
PRAGMA synchronous = FULL;
PRAGMA recursive_triggers = ON;
PRAGMA busy_timeout = 5000;
```

FULL 优先保证最近写入持久性；发布前做真机 benchmark，未经评审不得改回 NORMAL。
Drift schemaVersion 对应 SQLite user_version，不修改 SQLite 内部 schema_version PRAGMA。Envelope.wire_version、payload_schema_version 与文件版本分别演进。
当前未发布，用户批准直接修订 v1，不人为增加一次无用户数据的迁移；更新 schemas/app_database/drift_schema_v1.json。已有开发用 v1 文件不得误当可兼容旧文件，新建测试库验证。发布后变更必须版本升级和数据保留测试。

## 日志与时钟基础表（M1b，M1c 沿用）

### oplog

不可变字段：op_id 全局主键、workspace_id、origin_device_id、origin_seq、wire_version、hlc_wall_ms、hlc_counter、entity_type、entity_id、action、payload_schema_version、envelope_bytes、signature。

UNIQUE(workspace_id, origin_device_id, origin_seq)。origin 索引和实体索引均包含 workspace_id。payload 和 causal_context 的唯一协议原件保存在 envelope_bytes；索引字段只能由已解析/验证 envelope 派生，不接受独立外部索引输入。

本机可变字段：received_from_device_id、received_at_ms、apply_state、retry_count、local_error。
apply_state：applied、pending_entity_create、pending_dependency、pending_authorization、pending_schema、unauthorized_revoked、invalid_domain。
UPDATE signed 内容、DELETE、REPLACE 复用身份均由 triggers 阻止。完全重复投递在事务内核对字节后 no-op，不能绕过约束。

### workspace_clock_state

PRIMARY KEY(workspace_id, device_id)，字段 next_origin_seq（从 1 开始）、last_hlc_wall_ms、last_hlc_counter。
本地签名日志写入、时钟 tick、序号消费同事务。远端合法操作持久化与 observe HLC 同事务。回滚不得消费序号；事务必须从数据库重读状态，不依赖进程内缓存。

### observed_origins

PRIMARY KEY(workspace_id, device_id, origin_device_id)，max_observed_seq。
这是本机创建新 Operation 的因果上下文，包含已授权观察及其传递 context，不等于连续存储 Frontier。相同设备在不同 Workspace 完全独立。

### sync_quarantine

本机诊断：自增 id、reason、received_at_ms。M1b 不默认保存原始恶意/敏感 payload。坏签名、畸形数据不入 Oplog、不推进 HLC/序号/context。

## M1c 真实业务表

| 表 | 关键列与约束 |
| --- | --- |
| workspaces | id 全局主键；name、stats_timezone、created_at_ms、created_by_device_id 必填 |
| exam_profiles | id=exam_profile/{workspace_id}/default；workspace_id UNIQUE + FK；目标院校、专业、日期、目标分等可空 |
| subjects | id 全局主键；workspace FK；name 必填；category、目标分、满分、排序、archived |
| tasks | id 全局主键；workspace FK；title/status 必填；subject_id 使用复合 workspace+subject FK；预计秒数/日期/备注/排序等 |
| daily_reviews | Workspace 作用域确定性 id；workspace FK；review_date/content 必填；UNIQUE(workspace_id, review_date) |
| study_sessions | id 全局主键；workspace/subject/task/owner 关联；owner_device_id 固定；status/mode/start 必填；completed 必须有合法结束时间 |
| study_session_segments | id 全局主键；复合 workspace+session FK；开始必填、结束可空且不得早于开始；每 Session 最多一个 open Segment |

Session Duration 不存独立同步字段，session_durations 视图从已关闭 Segment 求和（毫秒）；open Segment 的当前显示时长在未来 Timer 层派生。knowledge_node_id 暂保留可空 UUID，不创建或解析暂缓的 KnowledgeTree。

## M1c 同步派生表

- entity_field_clock：workspace/entity/field 主键，winner_op_id、HLC、origin/dot、value_bytes（规范 CBOR）。部分字段即使实体尚未物化也保留索引。
- tombstones：workspace/entity 主键、delete_op_id、HLC/dot；CHECK 禁止 DailyReview。
- text_field_versions：workspace/entity/field/op_id 主键，origin/dot/value/is_active。当前只保存因果活动版本，完整旧版本仍在 Oplog；因果关系通过 op_id 回查 envelope。
- materialization_state：pending_create、pending_dependency、materialized、deleted。
- origin_progress：Workspace/origin 连续持久化前缀，不因 pending materialization 假装成功应用。
- trusted_devices：Workspace/device、公钥、active/pending/revoked、cutoff；从显式 OriginLookup 决策物化，不是另一个授权源。完整 Genesis 授权链仍属后续 Trust 工作。

FK 保持启用，Resolver 先计算必填字段与跨 Workspace 依赖，不依赖 SQL FK 异常做正常分支。SQL NOT NULL/FK/CHECK/UNIQUE 保留为最终完整性防线。

## M1c 事务、重建与命令成功

OperationWriter.execute(BusinessCommand) 和 OperationApplier.receive 都在同一外层 Drift transaction 内调用 Journal 与 ProjectionStore/ConflictResolver。日志、ClockState、ObservedOrigins、字段时钟、正文版本、Tombstone、业务行、Frontier 一起提交；失败整批回滚。SQLite 表更新通知也随事务提交。

本地 create/update 必须最终 materialized，delete 必须 deleted，且该 Operation 已 applied；已 tombstone 实体的本地 create/update 报错并回滚，不能以“幂等忽略”伪装成功。远端缺依赖/未知 schema 可以提交 pending 日志。

结构畸形的已知 payload 在主 Oplog 前进入 quarantine。动态 owner/action invariant 失败标 invalid_domain，不改变业务行。apply_state 支持此新状态，其原始已签名历史保留用于重算。

refreshAuthorization 与实际 Projection 重建同事务：撤销超 cutoff 的历史失效后重算字段、MV Register、Tombstone 及依赖闭包。rebuildEntity 初版扩展到整个 Workspace 重算，以正确处理父实体撤销/删除影响；rebuildWorkspace 使用同一实现。重建只清理派生表，不修改签名历史、ClockState、ObservedOrigins。

projectionDigest 在一致的读事务内对业务表、FieldClock、Tombstone、正文活动版本、materialization_state 规范排序/CBOR/SHA-256。Frontier 和 membership 独立比较，不进入业务 digest；合法未知 schema 推进存储进度不能改变业务 digest。排除 Oplog 投递时间、quarantine、retry、local_error、设备本地时钟/context 等。初版重建优先正确性，性能优化留待 M3 后测量。

## M2/M3 测试数据库边界

三台测试设备各自使用独立文件和生产 WAL/FULL/FK 连接。测试专用 test_policy_base / test_policy_log 保存显式已验证 membership 决策输入及其签名传播历史，不属于生产 schema、备份或 Genesis 协议。业务 Projection 仍完全由生产 Writer/Applier 生成；不直接复制数据库或业务行。细节见 docs/m2-m3.md。

## 后续

StudyPhase、KnowledgeTree、TaskTemplate、ExamAttempt、复杂 Plans 暂缓。M2/M3 接着用三份真实数据库测试随机分区/Gossip/撤销/依赖延迟；不提前进入网络或 UI。

## 备份

不直接复制运行中的 SQLite 主文件。备份使用 SQLite Backup API/一致性快照；恢复新安装生成新 Device ID 与新 key pair，不能把旧私钥作为当前身份。
