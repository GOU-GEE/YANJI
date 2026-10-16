# 研迹鸿蒙适配

工作分支：`codex/harmonyos-adaptation`。开发基线为 `3a1a6232f`，已推送到 GitHub main。本文记录实施状态；最初的可行性评估见上一级目录中的 `harmonyos-flutter-feasibility-2026-10-16.md`。

## 当前进度

| 阶段 | 状态 | 剩余验收 |
| --- | --- | --- |
| SDK 与依赖 | Flutter OHOS 3.41.9+ohos-1.0.2 / Dart 3.11.5、官方 API 26 工具可用；锁定依赖安装、代码生成、静态检查、237 项主机测试通过；通用工程和完整 App 产出未签名 HAP，模拟器运行通过 | 真机调试签名 |
| SQLite | 官方 OHOS 编译器从源码构建 SQLite 3.53.4，已打入完整 App 未签名 HAP；Drift 及 sqlite3 Dart API、schema v5 保持；46 项主机数据库/学习回归通过 | 最低支持版本与真机验收 |
| 安全存储 | 已接入 HUKS AES-256-GCM；4 项主机存储及 2 项错误界面测试、8 项原生故障测试通过；独立测试包清理后身份/TLS 不变，新实例学习与重启通过 | 真机及真实硬件密钥故障验收 |
| 单机学习闭环 | API 26 ARM64 模拟器通过任务、计时、暂停、复盘、统计、迁移、重启及进程强制终止恢复；正式界面走完 Onboarding→今日页，强杀重启后直接进入今日页 | 真机和系统后台策略 |
| Dart 跨端同步 | 已作为鸿蒙同步后端接入；API 26 模拟器与 macOS 主机完成认证配对、双向传输与回执确认 | 真机、多机型、长时间稳定性 |
| 扫码与设备发现 | 设备内二维码解码用例通过；mDNS 鸿蒙实现已接入 | 真机摄像头与跨设备发现 |
| Syncthing 内嵌 | 独立验证：上游 Go 工具链无法编译 OHOS 目标；Linux shim 在设备上因 initial-exec TLS 重定位加载失败 | 需要 `ohos_golang_go` fork 的专项移植 |

已接入用户提供的官方 Command Line Tools 26.0.0.851（macOS ARM64），内含 SDK 26.0.0.105 / API 26、ohpm 26.0.0.630、Hvigor 6.26.8、Node 24.14.1。无业务依赖的通用工程已产出 `entry-default-unsigned.hap`；Flutter 在产物生成后的签名检查退出，因为尚未配置调试签名。已安装并启动官方 API 26 ARM64 手机模拟器，完成原生存储和本机数据流程验收；详细结果见 `device-validation.md`。

## 工具链

固定版本记录在 `tool/harmonyos-toolchain.json`。Flutter 源码固定到提交 `62357a93d653bf844f730bb1f4b7cc9e2139d14e`。工具缓存放在 Git 忽略的 `.tooling` 中；脚本只为本次命令设置环境，不更改全局 Flutter 或系统设置。

准备 Flutter 鸿蒙 SDK：

```sh
tool/bootstrap_flutter_ohos.sh
tool/flutter_ohos.sh --version
```

如已有同版本 SDK，可通过 `YANJI_FLUTTER_OHOS_HOME` 指定。`bootstrap_flutter_ohos.sh` 会检查提交号，不会把已有目录重置到其他版本。

准备官方工具后，`YANJI_HARMONYOS_TOOLS` 可指向解压后的 `command-line-tools` 目录，也可指向 DevEco Studio 的 `.app` 目录。脚本会识别 `sdk` 和常见工具目录；如 SDK 单独安装，显式指定 `DEVECO_SDK_HOME`。

```sh
export YANJI_HARMONYOS_TOOLS="/absolute/path/to/command-line-tools"
tool/flutter_ohos.sh doctor -v
tool/flutter_ohos.sh pub get --enforce-lockfile
tool/flutter_ohos.sh analyze --no-pub
tool/flutter_ohos.sh test --no-pub
```

官网下载入口：[Command Line Tools](https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos)。本分支按所选 Flutter release 的配套配置编译 SDK 26.0.0、最低运行版本 5.0.5(17)。包名暂沿用项目的 `com.example.yanji`，正式发布前再统一确定应用标识。

## 第一阶段的兼容调整

- 应用与 `yanji_syncthing` 的 Dart 下限改为 3.11.5；这不表示 Syncthing 已有鸿蒙实现。
- 路由固定为 `go_router 17.5.0`。
- `bonsoir 7.1.5` 要求的 Android 实现需要 Dart 3.12，改用 7.1.4 并由解析器选出兼容实现；未强制覆盖不兼容包。
- `build_runner 2.16.1` 与较新的 `drift_dev` 会引入不兼容 SDK 固定 meta 版本的 analyzer；改用 `build_runner 2.15.0` / `drift_dev 2.34.0`，保留 Drift 和 SQLite 运行版本。
- 移除当前没有业务导入的 WebView 依赖，更新锁文件。
- 配对请求使用显式构造参数赋值，替代新的私有字段命名参数语法。
- `SizeTransition` 使用旧 SDK 支持的顶部轴对齐参数；动效仍从顶部展开。
- 重新生成 Drift 输出，schema 文件和 schemaVersion 保持不变。生成器还调整了视图依赖元数据，后续由现有数据库、统计和收敛测试验证。
- `.metadata` 保留原平台的创建/迁移记录，仅增加 ohos 记录。

接入官方工具后，`flutter pub get --enforce-lockfile` 已完整通过。主机回归结果：`flutter analyze --no-pub` 无问题，`flutter test --no-pub` 237 项全部通过（含新增存储回归）。原始日志保存在忽略的 `work/harmonyos/` 目录。

## 验收边界

主机上的 Flutter 测试用于检查版本调整有没有破坏现有 Dart/Widget 行为，不能证明 SQLite 动态库、HUKS、权限和后台行为在鸿蒙可用。后续先用无业务依赖的通用 Flutter 工程验证 HAP 构建，再进入 SQLite 和安全存储适配；完整 App 构建也可能触发 SQLite hook，不能用它替代独立的工具链验证。

当前生成的 ohos 工程不含签名身份或证书。拿到可用工具链后再在本地配置调试签名；证书、私钥、Profile 和本地 SDK 路径不得提交。

## SQLite 原生适配

`packages/sqlite3` 保留上游 3.5.2 生产 Dart 代码与 MIT 许可，仅增加 OHOS hook。该 hook 通过输入编译器识别官方 OHOS 工具链，显式指定 `aarch64-linux-ohos` / sysroot 编译校验过的 SQLite 3.53.4 源码；其他平台继续使用上游 hook。来源、哈希和更新要求见该包的 `YANJI_PATCHES.md`。原生输出 `libyanji_sqlite3.so` 已确认为 AArch64 ELF，依赖 OHOS `libc.so`，未链接 glibc。

应用持久化目录通过鸿蒙原生通道获取 `context.filesDir`；其他平台继续使用 path_provider。数据库初始化、迁移和 WAL 配置不变。完整 Debug HAP 已生成，但缺少签名时 Flutter 命令仍会在最后一步退出。

## 安全存储

鸿蒙通过 `yanji/platform.v1` 调用应用内的 `HuksSecretStore`。包装密钥由 HUKS 生成并保管，Preferences 只保存带版本号、随机 nonce 和认证标签的密文；AAD 绑定具体存储键名。三个原有存储键及其 JSON 格式保持不变，Ed25519 身份和 TLS 身份使用同一抽象；其他平台继续使用 flutter_secure_storage。

读写在原生端串行执行。已有密文但 HUKS key 不存在、认证失败、版本不支持或数据损坏时均报错；不清除记录、不生成替代身份、不降级明文。写入已有记录前先验证其可解密，随后等待 Preferences flush。平台不提供导出包装密钥或删除身份的通道。

实现参考：[HUKS 加解密](https://github.com/openharmony/docs/blob/master/en/application-dev/security/UniversalKeystoreKit/huks-encryption-decryption-arkts.md)。目前编译、主机边界测试、模拟器实际加解密及身份/TLS 跨进程重启一致性均通过；新增 8 项模拟器原生故障注入通过，覆盖损坏密文、记录串换和包装密钥丢失；见 [安全存储验收](security-validation.md)。早期同包名测试模块卸载导致旧模拟器包装密钥不可用，旧数据与实例已保留；现已改为独立测试应用，并在新实例验证其安装、运行和卸载均不影响正式凭据。

## Dart 局域网同步

鸿蒙首版不内嵌 Syncthing，改用项目已有的 Dart TLS 局域网增量同步（设备认证、签名校验、缺失记录交换），跨端协议不变。`AutomaticSyncController` 新增 `AutomaticSyncBackend`：鸿蒙默认 `dartTls`，其他平台保持 `embeddedSyncthing`；也可用 `--dart-define=YANJI_SYNC_BACKEND=dart` 在主机上显式选择，便于测试。

为按设备显示真实状态，`DevicePairingCoordinator.syncPairedDeviceResults()` 返回逐设备结果，`sync.complete` 携带响应方的 frontier 作为回执；Dart 后端据此计算待同步条数和确认状态。旧协议的响应方不带 frontier 时，UI 显示"等待设备确认"而不是伪造"已同步"。离线未确认、重连补传和工作区切换都有主机测试覆盖，且该路径不会调用原生引擎。

## 扫码与设备发现

`mobile_scanner` 改用 CPF-Flutter 的鸿蒙适配源（`fluttertpc_mobile_scanner`，固定提交 `f5a4ff5`），鸿蒙侧由华为 ScanKit 实现，替代上游 ML Kit；`module.json5` 声明 `ohos.permission.CAMERA` 及使用场景说明。`bonsoir` 的鸿蒙实现（`oh-flutter/bonsoir` 的 `BonsoirPlugin.ets`）已接入插件注册，使用 `@kit.NetworkKit` 的 mDNS。

## Syncthing 内嵌验证

`tool/probe_syncthing_ohos.py` 是与应用隔离的 ABI 探针，不参与构建和运行：它分别尝试用上游 Go 工具链编译 `c-shared` 的 OHOS 目标，以及编译 Linux shim 后在设备上 `dlopen`。当前结果（Go 1.27.1）是原生 OHOS 目标编译失败，Linux shim 虽能编译但设备加载报 `initial-exec TLS resolves to dynamic definition`。结论：内嵌 Syncthing 需要 `ohos_golang_go` 一类 fork 的专项移植，因此不作为首版路径的前置条件。

## 共用玻璃渲染

已修正鸿蒙即使支持 shader 滤镜也被全局降为 reduced 的质量选择问题。
共用 FakeGlass 在 Skia 下的染色/高光改用受支持的混合模式，修复模拟器底层着色器编译失败导致的绘制丢失。
当前官方模拟器的 shader 滤镜能力仍为 false，只能显示兼容材质；全局完整折射尚未在鸿蒙设备验证。
相关 29 项主机测试及模拟器共用控件交互通过，见[共用玻璃排查](shared-glass-validation.md)。
