# 研迹 YanJi

专门面向考研学生的本地优先、离线优先学习计划与学习记录工具。

Flutter / Dart · Drift / SQLite · Android / iOS / iPadOS 优先，保留 macOS / Windows 工程入口。无需账号与中心服务器；后续采用 LAN P2P 同步不可变、签名 Operation，不同步 SQLite 文件。

## 当前状态

M0/M1a/M1b 保留，已接入 M1c 生产数据路径：七类业务表、FieldClock、Tombstone、正文活动版本、物化状态、Frontier 和 membership 决策视图。

本地 `OperationWriter.execute` 与远端 `OperationApplier.receive` 通过同一个 Resolver，在同一 SQLite 事务内更新签名日志、时钟与真实 Projection。支持依赖晚到自动物化、撤销后重算、rebuildEntity/rebuildWorkspace 与 projectionDigest。

M2/M3 PR Gate 已验收；基础业务 UI 已接入生产数据路径：Onboarding、科目管理、今日/任务、计时、复盘和基础统计。真实身份使用 OS secure storage；单设备组合根只允许本机身份，完整 Genesis 授权链和 LAN/QR 尚未实现。iPhone / Android 模拟器日循环与重启 Gate 均通过，已达到本轮 Single-Device Alpha Ready。具体证据和范围见 [单设备验收记录](docs/validation/single-device-ui-2026-09-03.md)。

规范职责见 [ARCHITECTURE.md](ARCHITECTURE.md)；版本范围见 [ROADMAP.md](ROADMAP.md)；[M1c 实现与验证](docs/m1c.md)；[M2/M3 收敛验证](docs/m2-m3.md)。

UI/UX 唯一规范为 [DESIGN.md](DESIGN.md)。第一套设计样板覆盖 Onboarding / Today / Task / Timer，包含系统明暗主题和移动端适配；原始要求已归档，验证范围见 [Design v1 记录](docs/validation/design-system-v1-2026-09-03.md)。

数据页已进一步迁移为七日趋势、可切换科目 Donut 与学习积累；口径与截图见 [Data 页面验证](docs/validation/data-page-2026-09-04.md)。

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

本机已安装 Android SDK/API 36 模拟器、Xcode 26.6、CocoaPods 1.17.0，Xcode 许可及首次初始化已完成。iOS 26.5 runtime 与专用 iPhone 17 Pro 模拟器已安装，使用项目 SDK PATH 运行 flutter doctor 全部通过。macOS Keychain 应用构建仍需要开发签名证书，本机尚无有效证书。Windows 构建必须在 Windows 环境验证。最新平台状态以验收记录为准。

具备工具链后启动：

```sh
flutter run -d macos
# 或 flutter devices 查询已连接手机，再运行 flutter run -d <device-id>
```

原生包标识暂用 Flutter 的 `com.example.yanji`，发布前需要确定正式标识和签名团队。

日常分层测试和原生验收命令见 [单设备 UI 开发说明](docs/single-device-ui.md)。

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

业务写入统一通过 OperationWriter，在同一 SQLite transaction 中提交 Projection、Oplog、FieldClock 等状态。UI 不直接访问数据库，业务层不访问网络，Sync 不依赖 UI。

签名内容不可变，删除使用永久 Tombstone，私钥只进入操作系统安全存储。先通过三设备离线回放收敛测试，再做业务与 LAN P2P。不要提前加入账号、云同步、社交、AI 聊天或公网穿透。
