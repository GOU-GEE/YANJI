> 历史记录：本评审已批准，协议建议已由根目录 SYNC v1.1 等规范替代，文内“待确认”仅反映当时状态。

# 初始化架构评审 · 2026-09-03

## 结论与边界

保留 Flutter/Dart、Drift/SQLite、本地离线优先、签名 Operation、字段级 LWW、永久 Tombstone 和 LAN P2P 的总体架构。先初始化工程和可独立验证的基础组件；下列涉及协议语义的修订是建议，尚未作为已批准规范实现。

交接说明与根目录四份文档共同作为输入。原始规范保留；实现说明放在 docs，避免复制多份完整规范后发生漂移。

## 需要明确的技术问题

| 当前方案 | 问题及影响 | 推荐修改 | 迁移成本 / 时机 |
| --- | --- | --- | --- |
| daily_reviews.id 为全局主键，ID 为 daily_review:日期；逻辑上却只在 workspace 内唯一 | 两个 Workspace 的同日复盘会撞主键 | 使用 (workspace_id, id) 复合主键，关联查询包含 workspace | 当前无数据，成本低；业务表建表前确认 |
| origin_seq 按设备全局递增，Frontier 按 workspace 记录连续前缀 | 多 Workspace 交错写入造成某 Workspace 永久存在序号空洞 | 明确每 Workspace 的 origin 流与唯一约束，或限定设备身份只属于一个 Workspace | 首个 Writer 定稿前确认，不能只改唯一索引 |
| 任意顺序 Replay；业务表存在 NOT NULL 和关联实体 | update 先于 create、Session 先于 Subject 到达时不能直接落业务行 | 已验签 Operation 先持久化，按字段归并，必需信息齐全再物化；依赖未齐与未知 schema 区分状态 | 本地 Replay 前；中等实现成本 |
| 只凭 HLC 保存长文本 winner/loser | HLC 全序不能证明因果并发；按到达顺序留副本会产生不同 conflict 集合 | 补充字段版本的因果依据；冲突 ID 与版本集合按内容确定；detected_at 等本地元数据不纳入收敛比较 | 长文本 Writer 前；需要补充协议字段 |
| device.add/revoke 也同步；接收时要求 origin 当前可信 | Genesis 存在信任引导问题；撤销前历史如何接收会影响全量恢复与收敛 | 明确 QR 锚定的信任根、授权链、撤销优先规则及历史操作接受边界 | Trust 与网络实现前；中高设计成本 |
| Ed25519.sign(Operation)，未定义签名字节 | JSON 键顺序、数字编码、接收元数据导致验签不一致 | 明确规范编码、签名域、整数范围、未知版本保留策略；区分不可变 envelope 与可变本机投递状态 | 签名上线前；低成本但要固定测试向量 |
| HLC 只描述比较；origin_seq 连续递增 | 崩溃、回拨、并发写入、备份恢复可能重复序号或倒退 | HLC 与序号持久化并加入写事务；回滚不得消耗序号；备份导入新设备不能复制旧私钥/继续旧 origin | Writer 与恢复前；中等成本 |
| Session 的结束时间/时长/结束设备逐字段 LWW；路线图要求暂停继续 | 跨字段组合可能失去业务一致性；仅 started_at 无法扣除暂停 | 定义结束操作原子字段组或确定性派生规则；单独设计暂停区间与跨日统计口径 | Timer 前；中等成本 |
| 永久删除 + 确定性每日复盘 ID | 删除当天复盘后，同日重建仍是被永久删除的 ID | 明确清空内容是否替代删除，或增加逻辑实体代际；不得偷偷允许 restore | Review 前；产品语义决策 |
| WAL + synchronous=NORMAL，同时强调数据不丢 | 应用崩溃与断电持久性不是同一保证，NORMAL 不承诺所有最近提交抗断电 | 当前按原规范配置，发布前讨论是否使用 FULL 并测量性能 | 低成本配置变更；详见 SQLite 官方说明 |

## 范围差异

交接说明：基础长期任务/周计划属于 V0.1，AI 属于 V0.3；ROADMAP 把较完整的长期计划放 V0.2、AI 放 V0.4。当前基础设施不受影响，暂按交接说明保留 V0.1 基础计划要求，不提前开发 AI；进入相关里程碑前统一版本表。

## 当前工程目录

```text
lib/
  app/                    # Router、状态注入、Theme、启动壳
  core/
    database/             # Drift schema、迁移、原生连接
    clock/                # HLC
    ids/                  # UUIDv7
    logging/              # 分类别结构化日志
  sync/
    oplog/                # Operation 模型和本机存储基础
test/                     # 时钟、ID、数据库、启动测试
docs/                     # 实现说明、评审、阶段任务
schemas/                  # Drift schema 版本快照
android/ ios/ macos/ windows/
```

后续按需建立 domain、core/crypto、features/{onboarding,today,subjects,tasks,timer,plans,statistics,review,settings} 和 sync/{conflict,trust,protocol,transport,discovery,pairing}。iPadOS 与 iOS 共用 ios runner。

## 第一阶段任务拆分

1. M0：官方 Flutter 多平台骨架、Git、静态检查、测试入口、Router、状态注入、Theme、日志。
2. M1a：原生 Drift/SQLite 连接、schemaVersion=1、迁移快照、Oplog 存储与不可变保护、UUIDv7、纯 HLC 算法及测试。
3. M1b：按本评审明确序号流/签名编码；实现系统安全存储身份、签名、验签与持久化 HLC。
4. M1c：业务 Projection、FieldClock、Tombstone 与 OperationWriter 同事务；验证故障回滚和重启。
5. M2/M3：三份独立 SQLite 的乱序、重复、缺失补齐、Gossip、删除、签名和撤销测试。比较业务状态与确定性同步状态，排除本机接收时间等元数据。

通过 M3 才开始核心业务页面。网络与二维码仍放后期。

## 本轮完成与验证

已生成四个平台 runner、启动壳和依赖注入，完成 UUIDv7、HLC 纯算法、不可变 Operation 存储模型、Drift v1 Oplog schema、后台连接及迁移快照。静态检查和 16 项基础测试通过。

M1a 尚不包含完整业务数据库；M1b/M1c 及后续测试门槛仍待完成。当前缺少完整 Xcode、Android SDK，平台构建未验证。下一步先定稿序号流与签名编码，再实现安全身份和 OperationWriter。

## 参考

- [Flutter 安装](https://docs.flutter.dev/install/manual)
- [Drift Setup](https://drift.simonbinder.eu/setup/)
- [Drift Migration](https://drift.simonbinder.eu/migrations/)
- [SQLite synchronous](https://www.sqlite.org/pragma.html#pragma_synchronous)
