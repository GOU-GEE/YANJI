# Changelog

## Unreleased · M2/M3 Convergence Verification · 2026-09-03

- 新增三个独立文件数据库 DeviceHarness，使用生产连接、签名、Writer/Applier、Resolver、Projection；重启实际关闭并重建数据库和身份对象。
- 新增六条字节队列及 Frontier Diff/Gossip，覆盖重复、乱序、延迟、失败投递、分区和恢复；独立持久化的测试 membership policy 经签名消息传播后触发真实授权重验。
- 新增 19 项 M2 固定场景、10 个 seed × 200 actions 的 M3 日常场景，以及同 seed 完整 trace/签名字节/状态重放测试。逐表、字段、有效授权状态、Frontier、invariant 和三设备 rebuild 均验证一致。
- 修复固定场景发现的 digest 问题：Frontier 和 membership 改为独立比较，使未知 schema 仅推进存储进度而不改变业务 digest。新增可选确定性 ID 注入，应用默认 UUIDv7 行为保持不变。
- 新增失败 trace、regression seed corpus、PR/Extended/Soak 运行入口和性能记录工具。当前随机 seed 无失败；digest 问题由固定场景永久回归覆盖。
- 验证：全量 92 项测试通过（约 4 分钟）；flutter analyze、格式检查、固定 CBOR/Ed25519 向量独立 oracle 均通过。随机样本实际覆盖 53 次重启、14 次撤销、28 条 future schema 和 32 次坏签名注入。
- 已执行范围为 PR 样本及重放验证；Extended/Soak 配置未执行。完整 Genesis/QR、系统安全存储、真实平台构建和 LAN 网络不在本轮实现。详细记录见 docs/m2-m3.md、docs/validation/m2-m3-2026-09-03.md。

## M1c Production Projection 历史 · 2026-09-03

- 保留 M0/M1a/M1b，新增七类真实 SQLite 业务实体，以及 FieldClock、Tombstone、正文活动版本、物化状态、Frontier 和 TrustedDevice 决策视图；更新未发布 schema v1 与快照。
- 实现 OperationWriter / OperationApplier，日志、签名、序号、HLC、Context 与生产 Projection 在同一事务提交，本地和远端共用 Resolver。
- 实现 scalar 因果优先和并发确定性 winner、显式字段 patch、持久化 MV Register、永久删除、缺创建/缺依赖挂起及自动重试。
- 实现固定 Owner 的 Session 原子 start/pause/resume/stop，时长由 Segment 派生；本地无效命令整体回滚。
- refreshAuthorization 接入真实业务状态重算；提供 rebuildEntity、rebuildWorkspace 和确定性 projectionDigest。
- 验证：flutter analyze 无问题；62 项测试全部通过，其中新增 19 项真实 SQLite 生产路径测试；格式检查通过；M1b 固定签名向量保持不变且独立 oracle 复核通过。
- 取舍：rebuildEntity 当前重算整个 Workspace。TrustedDevice 物化已验证 OriginLookup 决策；完整 Genesis 授权链和平台安全存储仍待后续实现。下一阶段为 M2/M3 三设备文件数据库随机收敛测试。

## SYNC v1.1 / M1b 历史 · 2026-09-03

- 将批准决策落实到 SYNC、ARCHITECTURE、DATABASE，并更新 PRODUCT/ROADMAP 的产品语义和版本范围；历史评审移至 docs/reviews。
- 保留 M0/M1a 工程，按批准修订未发布 schema v1，改为 Workspace 内 origin_seq、FULL、ClockState、observed origins、apply_state 和 quarantine；更新 schema 快照。
- 实现确定性 CBOR、不可变 Envelope/原始 signed bytes、Ed25519 身份/签名/验签、SecureKeyStorage 抽象和恢复时新建身份。
- 新增日志/时钟/context 事务内核、重复幂等、未知 schema 保留与转发、授权重验及 cutoff 日志失效。
- 新增长文本因果 Multi-Value Register；使用测试参考模型验证乱序创建、晚到依赖、冲突解决及撤销后的重物化。
- 固定公开测试 seed、公钥、envelope、CBOR hex、签名；Python cbor2/cryptography 独立 oracle 复核，不在测试时重新生成期待值。
- 验证：flutter analyze 无问题；43 项测试通过；格式检查通过；固定向量独立复核通过。
- 边界：生产业务 Projection/FieldClock/Tombstone/完整 OperationWriter、Genesis 授权链、OS secure storage 真机适配、备份归档恢复和网络尚未实现。跨平台向量当前只在 macOS 执行，其他平台后续使用同一向量验证。

## M0/M1a 初始化历史 · 2026-09-03

- 阅读交接说明与四份原始规范，记录架构问题、待定决策和初始化任务。
- 初始化本地 Git 与 Flutter 3.47.2 多平台工程；iPadOS 使用 iOS runner。
- 添加 GoRouter、Riverpod、Material 3 启动壳和分类日志。
- 添加 UUIDv7、日历日期确定性 ID、可测试的纯 HLC 状态转换。
- 添加 Drift/SQLite 后台连接、v1 schema、Oplog 不可变约束和数据库测试。
- 添加文档、迁移快照配置与静态检查配置。
- 验证：静态检查通过；16 项基础测试通过，包括文件数据库重开和事务失败回滚。平台构建未验证（本机缺少完整 Xcode 与 Android SDK）。
- 尚未实现签名、系统安全身份、OperationWriter、完整业务模型或同步引擎。
