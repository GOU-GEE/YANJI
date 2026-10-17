# 鸿蒙完整玻璃渲染（2026-10-16）

## 目标与实现

本轮替代此前的磨砂／仿射兼容效果，恢复导航栏折射、七路色散、按压透镜中的栏体收缩，以及数据页日／周／月滑块的完整光学材质。

当前 API 26 ARM64 模拟器仍使用 Skia，原生 `ImageFilter.shader` 不可用。通过启动参数实际尝试 Impeller 后，Vulkan 初始化报告设备缺少必要纹理格式，应用无法创建渲染上下文；因此没有修改 SDK 强行开启 Impeller。

新增 OHOS 专用的显式背景采样后端：在合成阶段读取当前帧已绘制的层，按画面中的实际顺序绘制到独立离屏场景，再把图像交给原版 FragmentShader。仅捕获组件附近的区域，避免每个透镜分配整屏图像。不会把本层或后续图标、阴影采入背景，也不会缓存上一帧截图代替实时背景。构造独立场景时不复用或修改主场景的 `engineLayer` 句柄，避免多个玻璃组件共存时破坏 retained rendering。

导航沿用 `coolapk_navigation.frag` / `coolapk_content.frag` 的原有公式、参数及七路色散，绘制顺序仍为页面 → 外栏 → 透镜 → 阴影与独立图标。图标离屏输入保留到下一次绘制，避免惰性光栅化时纹理提前释放。

通用玻璃沿用原有形状距离场、折射率、厚度、色散、灯光与采样逻辑。Skia 专用几何入口处理了三项运行时编译限制：统一直接读取形状 uniform；使用常量数组索引；以相邻半个物理像素的距离场差分替代不支持的屏幕导数。原生 Impeller 入口保留屏幕导数。两条路径共享光学主体代码，未另设“鸿蒙视觉参数”。

质量策略在 OHOS 使用完整采样后端；Web、显式 `YANJI_GLASS_REDUCED` 和 Android API 33 的限制继续生效。iPhone／Android 保留原生 shader-filter 路径及其 uniform 布局。鸿蒙另用采样入口，两套入口共享光学主体代码，专用采样区域不会进入原生入口。

## 验收范围

`harmonyos_full_glass_test.dart` 复用原导航几何、图标采样、折射方向、栏体收缩、通用边缘折射和背景坐标用例；没有降低原有像素阈值。栏体边界测量取连续材质区域，排除与栏体分离的单像素色散边线；Android GLES 对照发现旧测量会将这种边线误算为不对称收缩。此外验证：

- 黑白背景在启用光学后出现色散，关闭光学时保持中性；
- 只更新背景的独立重绘边界，透镜同步显示新内容；
- 真实日／周／月分段控件在浅色、深色拖动时使用完整玻璃层，没有 FakeGlass；
- 面板、下拉菜单、弹窗、分段控件和提示同时显示时无合成层冲突。

原设计中静止的分段指示器使用轻量材质，拖动／切换时开启折射；普通控件显式关闭背景折射、信息浮层使用标准模糊的行为也保留，和其他平台一致。

## 复现

```sh
tool/run_harmonyos_full_glass.sh 127.0.0.1:10001
```

脚本只覆盖安装，不卸载模块或清除数据库。每次启动新进程，收集日志与实际窗口截图；必须 Flutter 用例全部通过，且没有原生 shader 编译错误或 SkSL 错误，才计为通过。截图和指标写入 `work/harmonyos/full-glass`。验收后重新构建带 `YANJI_PREVIEW=true` 的主应用，恢复已有 mock 数据。

本轮本机数据、运行结果和对照截图见下方最终验收记录。真机性能、后台策略与摄像头仍不在本轮结论范围内。

## 对照指标

Android 使用 API 36 ARM64、Flutter 3.47.2 / Impeller OpenGLES，运行同一份导航光学用例并全部通过。不同 DPR 下结果按逻辑像素归一化：

| 指标 | 鸿蒙 Skia / DPR 3.0 | Android GLES / DPR 2.625 |
| --- | ---: | ---: |
| 凸起透镜高度 | 72.00 dp | 72.00 dp |
| 图标输入缩放比例 | 1.208 | 1.190 |
| 边缘标记向外位移 | 1.034 dp | 0.952 dp |
| 栏体上／下收缩 | 3.000 / 3.000 dp | 3.048 / 3.048 dp |
| 两端收缩 | 3.667 dp | 3.429 dp |
| 透镜内／外栏体高度比 | 0.8929 | 0.8904 |

上述差异小于一个物理像素的取整范围。原验收阈值保持不变：标记向外位移 > 0.3 dp；上下收缩均 > 2 dp 且相差不超过一个物理像素；两端收缩 > 2 dp；图标比例介于 1.15–1.26。

鸿蒙额外验证中，中性背景关闭光学后的色散像素为 0，开启后为 1895；仅更新独立背景重绘边界后，12692 个采样像素发生变化。通用边缘折射的边缘／内侧／中心响应分别为 5.000 / 1.375 / 0.000，保持边缘强、中心清晰。

主机全量 **240 项通过**。本记录最初仅完成 iOS Metal 目标的 7 个着色器编译，iPhone 界面因本机 `xcrun` 与 Xcode 库架构不匹配尚未回归。随后通过本地兼容工具入口完成实际构建、安装与运行；鸿蒙／iPhone／Android 均通过同一套 7 个场景，详见[三端界面重新验收](ui-reacceptance.md)。Metal 编译检查本身仍不作为界面验收通过的替代。

结构化记录：[鸿蒙完整验收](validation/full-glass.json)、[Android 对照](validation/full-glass-android.json)、[Metal 编译](validation/full-glass-metal.json)。

Android 对照首次安装时，Flutter 工具因版本回退自动卸载并重装测试 App，清除了该 Android 模拟器中的旧 App 数据。此后对照保留测试 App；鸿蒙始终仅覆盖安装，原数据库及 mock 数据保留。额外启动的 Android／iPhone 模拟器在验证后已关闭。

最终 OHOS 严格验收于 21:29 完成，6 项设备场景全部通过（框架计数包含 setUpAll / tearDownAll 为 +8），原生 shader 编译错误与 SkSL 错误均为 0。本轮最终运行没有触发截图重试。静态检查无问题；最后补验的 39 项玻璃与导航主机测试也全部通过。

效果截图：[浅色导航长按](screenshots/full-glass/stage4-light-liquid-held.png)、[深色导航长按](screenshots/full-glass/stage4-dark-liquid-held.png)、[浅色分段拖动](screenshots/full-glass/light-full-segment-held.png)、[深色分段拖动](screenshots/full-glass/dark-full-segment-held.png)、[中性背景开启色散](screenshots/full-glass/dispersion-enabled.png)。设备用例中的圆形指针属于 Flutter 测试工具，正式 App 没有此标记。

正式 preview 主应用已覆盖安装并恢复已有 mock 数据：累计 35h32m、14 个学习日、今日 1h54m、任务 3/18。正式页面的[统计页静止](screenshots/full-glass/app-statistics.jpeg)、[导航拖动](screenshots/full-glass/app-navigation-dragged.jpeg)均由系统截图获取，没有 Flutter 测试指针；应用日志中没有 Flutter 异常或 shader 编译错误。

正式统计页还实际切换了周／月范围：周视图显示 13h00m，月视图显示 35h32m，沿用已有学习记录。
