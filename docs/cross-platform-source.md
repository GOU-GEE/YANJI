# 三端共用源码与构建

Android、iOS、鸿蒙统一维护 `lib/`、`assets/` 和 `packages/`。平台目录保留通知、安全存储和启动窗口等原生接入；鸿蒙使用固定 Flutter OHOS 工具链，Android／iOS 使用标准 Flutter。修改界面与业务后，不需要按平台复制 Dart 文件。

2026-10-31 将完整鸿蒙适配分支合并回主目录，保留主目录后续修改：移除 mock 子会话、导航滚动常驻、键盘避让时实时玻璃采样、同步状态页和考试日期布局。统一启动动画为 300 ms，内部前 75 ms 随放大渐显，时钟外部保持实色遮罩。Android／iOS 继续使用原生 Impeller 光学后端；鸿蒙使用当前帧采样后端，不将鸿蒙存储实现或 Dart 同步选择强加给其他平台。

## Android 手机更新

从本仓库根目录构建真实入口，不复用其他工作目录中历史 APK 或带预览开关的验收包：

```sh
bash tool/build_android_release.sh <递增构建号>
adb -s <手机序列号> install -r build/app/outputs/flutter-apk/app-release.apk
```

脚本显式关闭 `YANJI_PREVIEW` 与 `YANJI_GLASS_REDUCED`，输出源目录、提交和 APK SHA-256，在产物旁写入 JSON 来源记录。覆盖安装前核对包名、构建号和已安装 APK 的签名证书；若签名不一致，应使用原签名重新构建，不应通过卸载解决。覆盖安装不清除应用数据。

## SDK 与依赖

标准工具链位于 `.tooling/flutter`，鸿蒙工具链由 `tool/harmonyos-toolchain.json` 固定，入口为 `tool/flutter_ohos.sh`。两套 Flutter SDK 固定的基础包版本不同，切换前保留相应锁文件，在同一目录串行执行所选 SDK 的 `pub get`，不能只切编译器而沿用另一套 `.dart_tool/package_config.json`。

标准 SDK：

```sh
.tooling/flutter/bin/flutter pub get
.tooling/flutter/bin/flutter analyze --no-pub
.tooling/flutter/bin/flutter test --no-pub
```

鸿蒙：

```sh
tool/flutter_ohos.sh pub get
tool/flutter_ohos.sh analyze --no-pub
tool/build_harmonyos_unsigned.sh
```

在 SDK 切换产生新的基础包锁定后，再次用 `--enforce-lockfile` 验证相应 SDK。不要把 SDK 的依赖锁差异误认为平台源码需要分叉。验收包、mock 数据和日志留在忽略目录 `work/`，不提交真机内容。
