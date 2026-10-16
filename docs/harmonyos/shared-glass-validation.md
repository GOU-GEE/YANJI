# 共用玻璃渲染排查（2026-10-16）

## 结论与修正

缺少液态折射是全局能力降级，影响所有使用 `YanjiGlassSurface` 的组件。前一次导航修复只增强了导航在 Skia 上的兼容材质，不能证明全局完整折射恢复。

原因有三层：

1. 当前鸿蒙模拟器使用 Skia，运行时 `ImageFilter.isShaderFilterSupported=false`；`LiquidGlassLayer` 使用 `FakeGlass`。模糊、透明填色和边缘光不等同于完整折射。
2. `YanjiGlassQuality` 原来只为 Apple 和符合条件的 Android 开启 high，遗漏鸿蒙。即使鸿蒙真机启用了支持 shader 滤镜的 Impeller，所有共用组件也会被强制降为 reduced。
3. 共用 `FakeGlass` 的染色和高光还使用 multiply/screen/hardLight/overlay。模拟器驱动编译涉及 `GL_KHR_blend_equation_advanced` 的着色器失败，相关绘制丢失；Dart 侧交互测试仍会通过。

已修正平台质量策略：鸿蒙按实际 shader 滤镜能力选择 high/reduced，不调用 Android 专用 SDK 查询。保留 Web、显式 reduced 配置及 Android API 33 的原有限制。平台名称用于兼容上游 Flutter SDK 未包含 OHOS 枚举的情况。

已修正共用兼容渲染器：Skia 上的染色和高光改用 source-over，避免不受支持的高级混合。shader-capable 引擎及完整液态路径保留原有混合方式。此改动应用于所有共用玻璃表面，不限于导航。

没有强制模拟器绕过能力检查，也没有把兼容材质验收视作完整折射恢复。当前模拟器仍是 reduced，因此**本次修正不会让模拟器上的全部组件出现原版液态折射**。完整效果需要有支持能力的鸿蒙设备验收；另行实现 Skia 的完整折射渲染器属于独立工作，当前未完成。

## 组件清单

| 组件 | 路径及当前模拟器表现 |
| --- | --- |
| 导航 | 独立的导航 shader；Skia 走前次增加的实时模糊、高光和仿射透镜兼容路径 |
| 共用面板 | `YanjiGlassSurface` → `LiquidGlassLayer` → `FakeGlass`，保留模糊、透明填色和边缘光 |
| 弹窗、下拉菜单 | 共用 modal 材质降级为 FakeGlass；额外填色保护文字对比度 |
| 分段选择器 | 静止时轻量材质；移动指示器使用共用玻璃，Skia 不提供完整折射 |
| 按钮与普通控件 | 原设计使用 `refractBackdrop=false` 的轻量材质，保留弹性反馈，不是本次 SDK 导致取消折射 |
| 信息浮层与顶部提示 | `GlassFloatingSurface` 使用标准背景模糊，本来就不依赖 shader 滤镜 |

## 验证

- 3 项质量选择策略测试：鸿蒙 shader 能力开关、Web/显式 reduced 优先级、Android API 边界及 Apple 行为。
- 相关主机测试共 **29 项通过**，静态检查无问题；未将此计数当作重新运行全量测试。
- `harmonyos_shared_glass_test.dart` 在 API 26 ARM64 模拟器运行实际共用组件，验证浅色/深色、下拉选择、分段拖动、弹窗确认、提示显示；生成 10 张原生窗口截图。
- 新增严格运行脚本 `tool/run_harmonyos_shared_glass.sh`：每次启动新进程，持续检查该进程原生日志；即使 Flutter 测试通过，只要出现 shader compilation error 也失败。早期交互通过但出现原生编译错误的结果不计作材质验收通过。
- 修复后严格验收通过，当前应用进程的原生 shader 编译错误和高级混合错误均为 **0**。修复前“Flutter 通过但有 shader 错误”的日志已用于反向核对，会被拒绝。
- 运行结果明确记录 `platform=ohos`、`shaderFiltersSupported=false`、`quality=reduced`、`fullRefractionVerified=false`。这些用例验证渲染模式及控件交互，不宣称验证了不存在的完整折射。

结果：[validation/shared-glass.json](validation/shared-glass.json)。截图：[浅色弹窗](screenshots/shared-glass/light-dialog.png)、[深色总览](screenshots/shared-glass/dark-overview.png)。网格用于检查材质是否模糊/透光，不属于正式应用。

正式 App 也已重新构建安装，打开[开始学习弹窗](screenshots/shared-glass/app-study-dialog.jpeg)后，当前进程无原生 shader 编译错误或 Flutter 异常。

复现：

```sh
tool/run_harmonyos_shared_glass.sh 127.0.0.1:10001
# 构建、安装并启动测试，检查 Flutter 结果和原生 shader 错误。
```

截图及 result.json 写入应用的 files/shared-glass-acceptance。完成后重新构建 `lib/main.dart` 恢复正式 App。
