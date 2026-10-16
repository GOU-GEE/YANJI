# Liquid Glass · 2026-09-27

## 技术与兼容性

- Flutter 3.47.2 stable / Dart 3.13.2。
- pub.dev API 核实最新 `liquid_glass_renderer` 为 `0.2.0-dev.4`，要求 Flutter >=3.32.4、Dart >=3.0 <4.0；已锁定版本，依赖解析无冲突。
- 不包含 Compose 或原生导航实现，Android/iOS 使用相同 Flutter UI。
- Android minSdk 24 / targetSdk 36 / compileSdk 36 保持原配置。
- 未发现项目禁用 Impeller。真正的能力检查是 `ImageFilter.isShaderFilterSupported`，不把操作系统版本当作渲染器保证；模拟器原生测试断言此值为 true。
- Android 额外通过 `yanji/glass` channel 读取 API，API 33 以下主动降级；API 33+ 仍需支持 shader backdrop filter。
- 不支持的平台、Skia、channel 不可用时使用 FakeGlass；`--dart-define=YANJI_GLASS_REDUCED=true` 可强制低成本模式。
- 包本身是实验版本，需要 Android 实机继续验证 Vulkan/OpenGL 后端和功耗。

## 文件与结构

新增 `lib/design/glass/`：

- `liquid_glass_quality.dart`：缓存能力/平台选择。
- `yanji_glass_theme.dart`：浅色/深色、外层/指示器光学参数及 scroll clearance scope。
- `liquid_glass_surface.dart`：可复用、局部裁剪的 LiquidRoundedSuperellipse + LiquidGlassLayer + LiquidGlass，fallback 使用库的 FakeGlass。
- `liquid_navigation_dock.dart`：三个按钮、一个移动玻璃指示器、弹簧运动、按压反馈。

修改 `lib/app/yanji_app.dart` 为 Scaffold → Stack → 正文 RepaintBoundary + Positioned Dock。正文正常绘制在玻璃后方。
修改 `lib/features/shared.dart` 仅增加正文滚动 clearance；底部取现有安全留白与 Dock clearance 的最大值，避免叠加大量空白。横屏留出左侧阅读空间。
修改 Android MainActivity 增加仅查询系统版本的 channel；保留之前已有 live activity 逻辑。
修改 pubspec.yaml / pubspec.lock 添加经过检查的渲染库。

正文卡片、图表及普通标题栏继续使用实体材质。项目没有独立悬浮 FAB/Toolbar；现有弹窗主要是输入、选择与确认表单，此轮保持其阅读材质。新 Surface 可用于后续浮层。

## 光学与交互

- 外层最大 260×68、连续圆角 32；横屏 72×232。
- 外层 blur 8、thickness 10、refractiveIndex 1.12、saturation 1.18。
- 指示器 blur 4、thickness 14、refractiveIndex 1.18、saturation 1.28。
- 色散 .012：库的 final renderer 在小于 .01 时直接跳过 RGB 分离，参数轻微高于该阈值。
- 浅色外层 tint .09、深色 .14；指示器 .14/.18；深色降低照明强度。
- 两个有界玻璃层；图标不用 shader。重叠形状若共享一个光学层会被合为一个表面，因此指示器使用独立小层采样外层玻璃。
- 位置用 unbounded AnimationController + SpringSimulation，质量 1、刚度 360、阻尼 30；快速切换继承即时位置与速度。
- 拉伸取决于实际速度：运动轴最多 +12%，垂直轴最多 -5%；横屏交换轴。
- 按压用独立弹簧，最多缩小 4.5%；图标选中放大仅 1.06。
- 无障碍名称、Tooltip、按钮触摸区域、三个 GoRouter 路径保留。
- reduce motion / accessible navigation 时直接定位，关闭物理形变与动画。
- 键盘出现时隐藏 Dock，避免遮挡输入区域。
- 能力探测缓存、控制器 dispose；库缓存 shader program 并释放旧几何纹理。动画限制于 Dock，正文有独立 repaint boundary。

## 检查结果

- dart format：完成。
- flutter pub get：通过，无冲突。
- flutter analyze：No issues found。
- 现有完整 flutter test：142 项通过。
- 新增移动/横竖形变/快速反向/减少动态效果测试：3 项通过。
- 现有 design system + 新 Dock 测试联合运行：10 项通过。
- Android debug APK：成功构建。
- iOS simulator build：成功构建。
- iOS 原生 Impeller integration test 和 screenshot driver：通过。
- 实际检查浅色/深色今天、数据、我的，长任务列表滚动、卡片滚动、跨两格与反向切换、横屏竖向 Dock。12 张截图在同名目录中，使用隔离内存数据库生成。未修改仓库或真实设备的业务数据库。
- git diff --check：通过。

### 构建信息与验证边界

第三方库的两份 GLSL 在编译备用 SkSL 时发出已知“不支持 Skia”警告；Impeller 编译和两平台构建成功。降级路径不加载这些 shader。这是库的后端限制，不是应用分析错误。
iOS 工具链提示项目已有非标准 CocoaPods 配置可迁移到 Swift Package Manager；本次未改动已有依赖管理结构。
未连接 Android 真机，没有宣称 Android 实机视觉验收或稳定 60 FPS，也未用 debug 模拟器代替 profile 性能数据。
后续应在 Android 13+ 中端真机和旧 Android 上验证降级、滚动帧耗时、纹理内存与功耗；重点微调 blur、thickness、照明、spring 阻尼。当前参数集中在 glass theme 与 Dock 内。

## 重现

```sh
.tooling/flutter/bin/flutter test
.tooling/flutter/bin/flutter test test/widget/liquid_navigation_dock_test.dart
.tooling/flutter/bin/flutter analyze
.tooling/flutter/bin/flutter build apk --debug
.tooling/flutter/bin/flutter build ios --simulator
.tooling/flutter/bin/flutter drive --driver=test_driver/liquid_glass_driver.dart --target=integration_test/liquid_glass_visual_test.dart -d <device-id>
```

截图为 Flutter 原生视图捕获，不包含系统弹窗或状态栏。原有布局参考见 `glass-dock-2026-09-04/`。

## 后续交互调整

- 图标下新增“今日 / 数据 / 我的”，玻璃泡扩大至横向最大 64×56、纵向 56×64，包裹图标和文字。
- 从选中玻璃泡开始可沿导航主轴拖动，途中预览选中状态，松手提交路由切换，取消则返回原 Tab。
- 指示器按实时拖动速度形变，外层 Dock 跟随拉动轻微平移和伸缩，松手使用独立弹簧回弹。
- 横竖两个方向的拖动、反向切换、松手提交及外层恢复测试均通过；原有点击仍然有效。
- Tint alpha 保持：外层浅色 .09 / 深色 .14；指示器浅色 .14 / 深色 .18；指示器额外主题色反馈 .035～.06。

### 导航文字折射修正

将 Dock 内绘制顺序改为“外层玻璃 → 图标/文字 → 内层玻璃泡”。内部玻璃泡通过实时 backdrop 采样图标与文字，边缘经过 glyph 时可折射，而非在泡上方绘制始终清晰的图标。内层 blur 从 4 调整到 .6、折射率从 1.18 调整到 1.22，避免 glyph 模糊盖过边缘透镜形变。Tint alpha 保持不变。
静态分析、12 项相关测试、iOS 模拟器构建通过，并在运行中的 iPhone 17 Pro 模拟器实际拖动确认路由切换正常。
