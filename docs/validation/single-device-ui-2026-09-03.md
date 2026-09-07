# 单设备 UI 验证 · 2026-09-03

## 已执行结果

| 验证 | 结果 |
| --- | --- |
| 全量 Flutter 测试 | **98 项通过**，4 分 13 秒；保留已验收 92 项 |
| Widget 分层重跑 | **3 项通过**，10 秒 |
| flutter analyze | **无问题** |
| dart format | lib / integration_test / 新增测试格式通过 |
| 固定 CBOR / Ed25519 Python oracle | **通过**，固定向量未修改 |
| Android API 36 ARM 日循环 | **通过**，1 分 38 秒（不含构建） |
| Android 常规 main.dart Debug APK | **构建通过**，148 秒；可安装体验 |
| Android 独立进程重启 | **通过**，6 秒（不含构建）；保留数据重新安装/启动 |
| flutter doctor | **全部通过**（当前进程 PATH 包含项目 Flutter SDK） |
| iPhone 17 Pro / iOS 26.5 日循环 | **通过**，2 分 7 秒（不含构建） |
| iPhone 独立进程重启 | **通过**，6 秒（不含构建） |
| iOS 普通 main.dart Simulator Debug 构建 | **通过**，32.5 秒；覆盖安装保留数据 |
| iPhone 普通应用锁屏/活动计时恢复 | **通过**，实际锁屏画面、解锁后计时、模拟器重启后 Active Session 恢复 |
| macOS Debug 构建 | 被 Keychain 开发签名要求阻止；本机 0 个有效 codesigning identity |
| Extended / Soak | 未执行，按批准不阻塞 UI 开发 |

## Android 原生 Gate

设备为新建 `yanji_api36` / `emulator-5554`，Android 16 API 36，ARM64。使用真实应用启动、Drift 文件 SQLite 和 flutter_secure_storage，不注入内存身份或测试数据库。

1. 首次设置考试目标、默认科目与自定义「原生验证科目」。
2. 创建今日任务「完成一篇英语阅读」，从任务开始学习。
3. 宿主 adb 实际 HOME、等待 5 秒、屏幕关闭、等待 5 秒、唤醒、解锁并恢复应用。
4. 等待实际时间至少 65 秒，显示由 Segment 时间戳恢复；暂停 2 秒 duration 保持不变，再继续并结束。
5. 用户选择完成任务，保存今日复盘，查看累计时间与连续学习天数。
6. 第一进程退出；第二次 `--no-uninstall --dart-define=YANJI_VERIFY_REOPEN=true` 启动，仅从既有持久化读取。
7. 验证自定义科目、完成任务、已结束 Session、累计时长 ≥ 60 秒、完整复盘、Session owner 与安全存储 Device ID 一致。
8. 构建普通 main.dart APK 并覆盖安装，实际 force-stop/start；原生 UI hierarchy 确认 Today 展示 0h 01m、任务 1/1 和已勾选的任务。

截图：[锁屏恢复后的 Timer](ui/android-timer.png)、[保存后的统计](ui/android-statistics.png)、[普通应用重启后的 Today](ui/android-reopened-today.png)。截图已逐张检查，未见布局溢出。

初次测试脚本的短等待不足以覆盖原生异步保存，已改为等待 Onboarding 完成并滚动到懒加载控件。集成测试默认绘制策略在背景恢复时出现黑屏，改用 fullyLive 后获得正常页面截图；未通过更改 Timer 时间逻辑回避。

## iPhone 原生 Gate 与显示复核

使用专用 iPhone 17 Pro / iOS 26.5 (23F77)，UDID `18FCF8E1-F549-4F06-BD17-2E3655650CA3`。与 Android 运行同一套真实 SQLite / Keychain 日循环及独立进程重启断言，全部通过。iOS 键盘导致按钮落在懒加载范围外，验收脚本补充滚动定位后通过。

第一轮宿主验证用 Safari 前台切换和 simctl screenConfig 关闭/打开屏幕，行为断言通过，但截图持续黑色；该画面没有作为成功证据。重启专用模拟器后恢复可见显示，保留了原数据库与活动 Session；未更改应用计时逻辑或清除数据。

随后在普通 main.dart 应用复核：活动计时跨整个模拟器重启继续；用 Simulator `⌘L` 锁屏/唤醒，确认实际系统锁屏画面，再用 `⇧⌘H` 回到应用，显示 `00:05:19`，继续计时并成功结束。原生按钮 AX 点击不足以证明锁屏，以实际截图为准。最后 terminate / launch 普通应用，Today 仍为任务 1/1、累计 0h 06m。额外的约 5 分钟来自这段显示验证 Session。

截图：[实际锁屏](ui/ios-locked.png)、[恢复后的 Timer](ui/ios-timer.png)、[最终统计](ui/ios-statistics.png)、[普通应用重新启动后的 Today](ui/ios-reopened-today.png)。均已逐张检查。Simulator 的锁屏与后台测试不能代替物理 iPhone 密码锁屏/内存回收验证。

## 新增本地行为覆盖

Widget 验证手机 390 × 844 的完整目标→科目→任务→计时→完成任务→复盘重开→统计流程及启动失败重试。Application 测试验证文件重开后活动 Session 和正文、跨午夜拆分、纽约 DST 的 23 小时日界线、Onboarding 整体事务回滚，以及替换身份不能自动获得旧工作区权限。

M3 仍运行 10 seeds × 200 actions 及同 seed 重放；有限样本不是无限状态空间的形式化证明。未修改同步协议、Schema、Resolver 或签名向量。

## 工具链和待验范围

Flutter 3.47.2 / Dart 3.13.2；Android SDK / Emulator 37.1.11；Xcode 26.6 build 17F113；CocoaPods 1.17.0。用户已完成 Xcode license accept / runFirstLaunch。

iOS runtime 为 iOS 26.5 (23F77) arm64，已完成约 8.52 GB 下载及安装，创建专用 iPhone 17 Pro 模拟器。初次构建因尚无 runtime 而缺少 scheme destination；安装后 iOS 构建、日循环和独立进程重启均已通过。首次 iOS 构建 154.6 秒，普通应用构建 32.5 秒；Simulator 首次系统迁移约 6 分钟，之后重启约 7 秒。

macOS 缺少开发签名证书；保留真实 Keychain 权限，不使用明文或内存密钥绕过。Android/iPhone 真机、iPad、Windows 仍未验收。

**YanJi Single-Device Alpha Ready（本轮 iPhone / Android 模拟器日循环验收范围）**。两个模拟器已安装普通应用，可直接体验。该状态不代表真机、完整 V0.1 或正式 Alpha 发布；接网/发布前仍需后续门槛。
