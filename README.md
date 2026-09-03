# 研迹 YanJi

专门面向考研学生的本地优先、离线优先学习计划与学习记录工具。

Flutter / Dart · Drift / SQLite · Android / iOS / iPadOS 优先，保留 macOS / Windows 工程入口。无需账号与中心服务器；后续采用 LAN P2P 同步不可变、签名 Operation，不同步 SQLite 文件。

## 当前状态

M0/M1a/M1b 保留，已接入 M1c 生产数据路径：七类业务表、FieldClock、Tombstone、正文活动版本、物化状态、Frontier 和 membership 决策视图。

本地 `OperationWriter.execute` 与远端 `OperationApplier.receive` 通过同一个 Resolver，在同一 SQLite 事务内更新签名日志、时钟与真实 Projection。支持依赖晚到自动物化、撤销后重算、rebuildEntity/rebuildWorkspace 与 projectionDigest。

M1c 不增加网络、QR、mDNS 或 UI。完整 Genesis 授权链和 OS secure storage 平台适配仍未完成；membership 通过已明确的 OriginLookup 接口提供。M2/M3 已建立三份真实文件数据库、模拟 Transport、固定场景及可重放随机收敛验证。后续按 ROADMAP 推进基础业务 UI、单设备可用和平台验证，再接入 LAN Transport。

规范职责见 [ARCHITECTURE.md](ARCHITECTURE.md)；版本范围见 [ROADMAP.md](ROADMAP.md)；[M1c 实现与验证](docs/m1c.md)；[M2/M3 收敛验证](docs/m2-m3.md)。

## 开发环境

本次使用 Flutter **3.47.2**（stable，revision d3b14c8769）、Dart **3.13.2**。SDK 安装于本项目 `.tooling/flutter`，已从 Git 排除；没有修改用户全局 PATH。

现有项目目录执行：

```sh
export PATH="$PWD/.tooling/flutter/bin:$PATH"
flutter pub get
dart run build_runner build
flutter analyze
flutter test
```

修改数据库 schema 时还需要运行 `dart run drift_dev make-migrations`，维护版本快照与迁移；不能只重新生成数据库代码。

测试覆盖签名固定向量、逐字节篡改、双 Workspace 序号、事务回滚、重启与远端 HLC、未知 schema、因果复盘与 cutoff 参考回放。M1c 增加真实 SQLite 生产路径测试，M2/M3 增加三设备文件数据库与随机收敛测试。当前执行结果见 CHANGELOG.md；固定 CBOR/签名 golden vector 保持不变。

其他机器先按 [Flutter 官方安装说明](https://docs.flutter.dev/install/manual) 安装对应 SDK；`.tooling` 不随仓库分发。依赖锁定在 pubspec.lock，生成的数据库代码和 schema 快照一并提交。

当前机器没有 Android SDK、完整 Xcode 或 CocoaPods；只能先运行 Dart/Flutter 测试与静态检查。Android/iOS/macOS 原生构建需要补齐对应工具链；Windows 构建必须在 Windows 环境验证。

具备工具链后启动：

```sh
flutter run -d macos
# 或 flutter devices 查询已连接手机，再运行 flutter run -d <device-id>
```

原生包标识暂用 Flutter 的 `com.example.yanji`，发布前需要确定正式标识和签名团队。

## 文档入口

- [PRODUCT.md](PRODUCT.md)：产品范围。
- [ARCHITECTURE.md](ARCHITECTURE.md)：总体架构及文档职责。
- [SYNC.md](SYNC.md)：SYNC v1.1 协议规范。
- [ROADMAP.md](ROADMAP.md)：完整路线图。
- [DATABASE.md](DATABASE.md)：数据库结构与持久化规则。
- [历史评审](docs/reviews/2026-09-03-initial-review.md)与[批准记录](docs/reviews/2026-09-03-sync-v1.1-approval.md)：只作历史存档。
- [docs/architecture.md](docs/architecture.md)：当前实现与分层。
- [docs/database.md](docs/database.md)：数据库、版本与迁移。
- [docs/sync-protocol.md](docs/sync-protocol.md)：同步实现状态与必测矩阵。
- [CHANGELOG.md](CHANGELOG.md)：实施记录。

## 开发约束

业务写入将统一通过 OperationWriter，在同一 SQLite transaction 中提交 Projection、Oplog、FieldClock 等状态。UI 不直接访问数据库，业务层不访问网络，Sync 不依赖 UI。

签名内容不可变，删除使用永久 Tombstone，私钥只进入操作系统安全存储。先通过三设备离线回放收敛测试，再做业务与 LAN P2P。不要提前加入账号、云同步、社交、AI 聊天或公网穿透。
