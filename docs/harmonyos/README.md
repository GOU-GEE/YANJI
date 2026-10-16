# 研迹鸿蒙适配

工作分支：`codex/harmonyos-adaptation`。开发基线为 `3a1a6232f`，已推送到 GitHub main。本文记录实施状态；最初的可行性评估见上一级目录中的 `harmonyos-flutter-feasibility-2026-10-16.md`。

## 当前进度

| 阶段 | 状态 | 剩余验收 |
| --- | --- | --- |
| SDK 与依赖 | Flutter OHOS 3.41.9+ohos-1.0.2 / Dart 3.11.5、官方 API 26 工具可用；锁定依赖安装、代码生成、静态检查、231 项测试通过；通用工程产出未签名 HAP | 调试签名、设备运行 |
| SQLite | 官方 OHOS 编译器从源码构建 SQLite 3.53.4，已打入完整 App 未签名 HAP；Drift 及 sqlite3 Dart API、schema v5 保持；46 项主机数据库/学习回归通过 | 设备原生加载、WAL、迁移、终止恢复 |
| 安全存储 | 未开始 | HUKS 支持的密钥存储与身份持久化 |
| 单机学习闭环 | 未开始鸿蒙验收 | 创建任务、计时、复盘、统计、后台恢复 |
| Dart 跨端同步 | 未开始鸿蒙接线 | 传输选择、状态确认、扫码/mDNS、双向跨端同步 |
| Syncthing 内嵌 | 独立验证项 | 不作为上述首版路径的前置条件 |

已接入用户提供的官方 Command Line Tools 26.0.0.851（macOS ARM64），内含 SDK 26.0.0.105 / API 26、ohpm 26.0.0.630、Hvigor 6.26.8、Node 24.14.1。无业务依赖的通用工程已产出 `entry-default-unsigned.hap`；Flutter 在产物生成后的签名检查退出，因为尚未配置调试签名。当前没有鸿蒙设备或已下载的模拟器镜像；未完成设备运行验收。

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

接入官方工具后，`flutter pub get --enforce-lockfile` 已完整通过。主机回归结果：`flutter analyze --no-pub` 无问题，`flutter test --no-pub` 231 项全部通过。原始日志保存在忽略的 `work/harmonyos/` 目录。

## 验收边界

主机上的 Flutter 测试用于检查版本调整有没有破坏现有 Dart/Widget 行为，不能证明 SQLite 动态库、HUKS、权限和后台行为在鸿蒙可用。后续先用无业务依赖的通用 Flutter 工程验证 HAP 构建，再进入 SQLite 和安全存储适配；完整 App 构建也可能触发 SQLite hook，不能用它替代独立的工具链验证。

当前生成的 ohos 工程不含签名身份或证书。拿到可用工具链后再在本地配置调试签名；证书、私钥、Profile 和本地 SDK 路径不得提交。

## SQLite 原生适配

`packages/sqlite3` 保留上游 3.5.2 生产 Dart 代码与 MIT 许可，仅增加 OHOS hook。该 hook 通过输入编译器识别官方 OHOS 工具链，显式指定 `aarch64-linux-ohos` / sysroot 编译校验过的 SQLite 3.53.4 源码；其他平台继续使用上游 hook。来源、哈希和更新要求见该包的 `YANJI_PATCHES.md`。原生输出 `libyanji_sqlite3.so` 已确认为 AArch64 ELF，依赖 OHOS `libc.so`，未链接 glibc。

应用持久化目录通过鸿蒙原生通道获取 `context.filesDir`；其他平台继续使用 path_provider。数据库初始化、迁移和 WAL 配置不变。完整 Debug HAP 已生成，但缺少签名时 Flutter 命令仍会在最后一步退出。
