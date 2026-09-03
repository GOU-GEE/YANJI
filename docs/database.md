# 数据库实现索引

数据库规范和版本策略集中维护于根目录 [DATABASE.md](../DATABASE.md)，同步语义见 [SYNC.md](../SYNC.md)。

源文件：lib/core/database/schema.drift、app_database.dart、connection.dart。
生成代码：lib/core/database/app_database.g.dart。
版本快照：schemas/app_database/drift_schema_v1.json。
事务内核：lib/sync/oplog/operation_journal.dart。

本轮按批准直接修订未发布的 schema v1。新增 workspace_clock_state、observed_origins、sync_quarantine，修改 Oplog envelope/索引/apply_state，FULL 替代旧配置。

OperationJournal 继续承担日志与时钟内核。生产入口 OperationWriter/OperationApplier 在同一外层事务接入真实 Projection、FieldClock、Tombstone 和正文版本。详情见 [M1c 实现](m1c.md)。

常用命令：

```sh
dart run build_runner build
dart run drift_dev make-migrations
flutter test test/database
```

未发布 v1 本轮快照通过 drift_dev schema dump 更新。未来发布后的变更使用版本提升与 migration，不再直接覆盖已发布快照。
