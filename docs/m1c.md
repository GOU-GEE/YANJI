# M1c — 生产 Projection 与 OperationWriter

批准文件：[历史存档](reviews/2026-09-03-m1c-approval.md)。协议和数据规范已同步到根目录 SYNC.md、DATABASE.md、ARCHITECTURE.md、ROADMAP.md。

## 入口

- `lib/sync/operation_pipeline.dart`：`BusinessCommand`、`OperationWriter.execute`、`OperationApplier.receive/refreshAuthorization/rebuildEntity/rebuildWorkspace/projectionDigest`。
- `lib/domain/business_schema.dart`：结构、ID、日期、IANA 时区、scalar patch、Session 原子动作校验。
- `lib/sync/projection/conflict_resolver.dart`：因果极大版本、并发 winner、Tombstone、Owner/Segment 状态机、依赖闭包。
- `lib/sync/projection/projection_store.dart`：真实 SQL 派生表写入及规范 digest。
- `lib/core/database/schema.drift`：全部表、NOT NULL/FK/CHECK/UNIQUE 与只读 duration 派生视图。

本地与远端共用 resolver；本地成功只在日志/时钟/Projection 外层事务提交后返回。M1b OperationJournal 是底层内核，业务不得绕过 OperationWriter 直接使用它。

## 真实 SQLite 验收

2026-09-03 本机验证：全量 62 项测试通过（新增 19 项生产路径测试）；flutter analyze 无问题；格式检查通过；固定签名向量独立 oracle 复核通过。已更新 Drift schema v1 快照。

`test/database/production_projection_test.dart` 覆盖：

- 本地签名日志、业务行、字段时钟、序号、Frontier 同步成功。
- 本地和远端 Projection 写入故障注入后的整批回滚。
- 本地与远端结果 digest 一致。
- update-before-create、缺必填字段、缺 Subject、跨 Workspace FK、依赖晚到自动恢复。
- 独立字段合并、同字段并发收敛、因果优先于 HLC、显式 null patch。
- 两份并发复盘真实活动版本、因果解决、清空后重写与禁止 hard delete。
- delete-before-create、晚到 update、删除父实体后的依赖闭包。
- revoke cutoff 后真实业务行和字段时钟重算。
- 清空派生状态后 rebuildEntity/Workspace digest 一致；文件关闭重开后保持数据。
- Session start/pause/resume/stop 原子动作、非 Owner 拒绝、乱序动作与暂停后结束；completed 不可能保留 open Segment。
- 静态畸形 payload quarantine、合法未知 schema pending。

## 实现取舍与下一步

rebuildEntity 当前扩展到整个 Workspace。全量重算避免第一版遗漏依赖回退，代价是随历史量增长的计算和写入成本；先通过 M3，再用测量决定是否优化为实体依赖闭包增量重建。

membership 表仍物化显式 OriginLookup 决策，完整 Genesis/授权链算法不在本次新增范围。安全存储仍是抽象，未接入平台实现。没有新增网络、相机、QR、UI 或统计图表。

接下来是 M2/M3 三设备文件数据库随机收敛测试，不直接进入 UI 或网络。
