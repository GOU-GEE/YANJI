# 架构实现索引

规范仅维护在根目录 [ARCHITECTURE.md](../ARCHITECTURE.md)、[SYNC.md](../SYNC.md)、[PRODUCT.md](../PRODUCT.md)、[ROADMAP.md](../ROADMAP.md)。本文只索引实现，不覆盖根规范。初始评审及批准记录已归档至 reviews/。

- lib/app：GoRouter、Riverpod、Theme、启动状态和响应式导航。
- lib/application：StudyAppController 读模型、生产 Writer 命令、Segment 时间统计。
- lib/features：Onboarding、Subjects、Today/Tasks、Timer/Review、Statistics。
- lib/core/database：Drift schema v1、后台连接、FULL、schema 快照。
- lib/core/clock：HLC 纯转换；持久化由 OperationJournal 事务负责。
- lib/core/ids：UUIDv7 和 Workspace 作用域每日复盘 ID。
- lib/core/crypto：Ed25519 DeviceIdentity、签名/验签、SecureKeyStorage 接口。
- lib/sync/protocol：整数/字节保持精度的确定性 CBOR profile。
- lib/sync/oplog：不可变 Envelope/packet、日志与时钟/context 事务内核。
- lib/sync/conflict：纯因果 Multi-Value Register。
- lib/domain/business_schema.dart：已知业务 payload 与 ID/类型校验。
- lib/sync/operation_pipeline.dart：OperationWriter 与 OperationApplier。
- lib/sync/projection：生产 ConflictResolver 与 ProjectionStore。
- test/database/production_projection_test.dart：真实 SQLite 生产路径验证。
- test/support/replay_reference.dart：保留 M1b 历史参考模型，M1c 不依赖该模型运行。

lib/core/storage/platform_key_storage.dart 已接入 OS secure storage；MemorySecureStorage 仅存在于测试目录。单设备组合根只允许本机持久身份，完整 Genesis 授权链尚待接网前实现。
