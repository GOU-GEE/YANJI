# 单设备基础 UI

本轮按 2026-09-03 批准的顺序接入手机日循环，协议和业务 schema 沿用已验收版本。验收结果见 [原生与自动测试记录](validation/single-device-ui-2026-09-03.md)。

UI 视觉与交互统一遵循根目录 [DESIGN.md](../DESIGN.md)。样板迁移记录见 [Design v1 验证](validation/design-system-v1-2026-09-03.md)，Data 页面已于 2026-09-04 增量迁移，见 [验证记录](validation/data-page-2026-09-04.md)；其他非样板业务页仅继承主题。

## 实现入口

- `lib/design/yanji_theme.dart`：Semantic Tokens、Light/Dark Theme、统一控件尺寸和字体尺度。
- `lib/app/yanji_app.dart`：中文 Material 3、GoRouter、手机底部导航、宽屏 Rail、启动 loading/error/retry。
- `lib/application/study_app_controller.dart`：Application Service，生产 Writer 命令、读模型、按工作区时区聚合 Segment。
- `lib/core/storage/platform_key_storage.dart`：系统安全存储的真实身份适配；不向 SQLite 或日志写入私钥。
- `lib/features/`：首次设置、科目管理、今日/任务编辑、计时、日期复盘、基础统计。

所有业务修改通过 OperationWriter → Resolver → Projection。Onboarding 多个创建命令整体提交，失败回滚。停止学习与完成任务是两个独立用户决定；暂停时长不计入 Segment。复盘清空为正文更新，不删除实体。

基础统计从 Session / Segment 计算，日界线由 Workspace.stats_timezone 决定；跨午夜拆分，DST 不固定按 24 小时处理。Timer 的秒刷新不写数据库，后台不依赖 ticker 累加。当前首建工作区使用 Asia/Shanghai；时区设置 UI 和每日学习目标设置暂缓。

## 测试分层

```sh
tool/run_tests.sh fast         # HLC / ID / 编码 / 签名 / 协议参考语义
tool/run_tests.sh database     # 事务、生产投影、应用服务与持久化
tool/run_tests.sh widget       # 日循环、启动异常、设计样板适配与颜色对比
tool/run_tests.sh convergence  # M2 + M3 PR gate
tool/run_tests.sh all
```

支持 `FLUTTER_BIN` 覆盖项目本地 SDK。普通页面迭代运行 widget + analyze；关键数据内核变更执行 convergence / all，Extended / Soak 使用已有独立入口。

## 原生 Android 验收复现

使用专门的全新测试模拟器；日循环测试要求尚未 Onboarding，不自动清库。关闭已有测试进程后再运行第二次重启断言。`--no-uninstall` 必须保留，否则 Flutter test 默认卸载测试应用，不能验证数据保留。

```sh
export PATH="$PWD/.tooling/flutter/bin:$HOME/Library/Android/sdk/platform-tools:$PATH"
flutter test integration_test/single_device_test.dart -d emulator-5554 \
  --no-uninstall --reporter expanded > /tmp/yanji-native-test.log 2>&1
```

测试运行期间，在另一个终端执行宿主生命周期脚本：

```sh
python3 tool/verify_android_lifecycle.py --serial emulator-5554 \
  --log /tmp/yanji-native-test.log --output docs/validation/ui
```

脚本执行真实 HOME、屏幕关闭/唤醒、前台恢复并取图。Integration binding 使用 fullyLive 绘制；后台阶段按实际时间等待至少 65 秒，随后验证暂停/继续/停止、任务完成、复盘及统计。

首次测试退出后，进程已由 Flutter 停止；保留同一应用的数据再次运行：

```sh
flutter test integration_test/single_device_test.dart -d emulator-5554 \
  --no-uninstall --dart-define=YANJI_VERIFY_REOPEN=true --reporter expanded
```

重启分支只读取已有数据并打开统计：验证自定义科目、任务完成、Session owner 与安全存储身份一致、累计时长和复盘正文。需要人工体验时，以常规 main.dart 构建安装覆盖同一包，勿卸载清除数据。

## iPhone Simulator 验收复现

本机专用模拟器为 `YanJi-iPhone-17-Pro`，UDID `18FCF8E1-F549-4F06-BD17-2E3655650CA3`，iOS 26.5 (23F77)。更换机器请用 `flutter devices` 查实际 ID。

同一个 integration_test 使用该设备 ID 运行，保留 `--no-uninstall`。日志出现 `YANJI_STAGE_TIMER_RUNNING` 后，在 Simulator 使用 `⌘L` 锁屏/唤醒、`⇧⌘H` 回到应用，并确认实际显示；测试保留至少 65 秒用于这些操作。随后以 `YANJI_VERIFY_REOPEN=true` 对同一安装数据执行重启断言。

本次发现 simctl 的 `screenConfig power on` 不足以恢复 Simulator 的可见画面，因此不把该命令当作 Sleep/Wake 的替代。最终显示验证使用普通 main.dart 应用与 Simulator 的锁屏/Home 快捷键，详见验收记录。模拟器锁屏不等同于物理设备密码锁屏或资源回收测试。

## 边界

- 单设备 OriginLookup 只允许本机持久身份；不提供远端接收/授权管理 UI，完整 Genesis 授权链尚未实现。
- `flutter_secure_storage` 锁定 10.3.1，与当前 Android compileSdk 36 工具链配合；iOS/macOS 使用插件 Darwin Keychain 实现。
- Key storage 初始化仅在应用 isolate 内串行，不声称跨进程 CAS。Keychain 卸载保留、设备迁移/恢复与真实设备保护行为需在后续恢复/真机 Gate 验证。
- 原生包名仍是 com.example.yanji；正式发布需确定标识与签名。
- 热力图、复杂计划、番茄钟、备份、LAN/QR 和 Extended/Soak 留待后续；模拟器测试不能替代真机或无限状态空间证明。
