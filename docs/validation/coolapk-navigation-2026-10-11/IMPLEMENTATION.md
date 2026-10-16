# 研迹导航栏：酷安 16.6.2 光学移植与验证

本轮凸透镜与圈圈感修正见[最新验证](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-convex-2026-10-12/README.md)，下文保留历史版本参数和结果。

最新紧凑宽度、局部着色、镜片阴影、端部包裹和上下对称的产品调整见 [2026-10-12后续验收](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-volume-2026-10-12/README.md)。以下保留此前版本的实现/验收记录。

项目 `/Users/goulijun/Documents/project/YANJI`。所有原有未提交修改保留；未修改、重签、重打包 APK，未接入酷安业务。

## 源码与对应关系

资料：[专项指南](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/GLASS_NAVIGATION_GUIDE.md)、[完整报告](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/APK_REVERSE_ENGINEERING_REPORT.md)、[原版首页](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/dynamic/home.png)。

主要源文件：[bn1](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/bn1.java)、[os8](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/os8.java)、[TabPanel](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/com/coolapk/market/widget/compose/liquid/LiquidGlassTabPanelKt.java)、[C5164](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/com/coolapk/market/widget/compose/liquid/C5164.java)、[jo8](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/jo8.java)、[qs8](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/qs8.java)、[ax8](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/ax8.java)、[ik8 AGSL](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/glass/shaders/ik8-1.agsl)、[q6f AGSL](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/glass/shaders/q6f-1.agsl)、[oh6 AGSL](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/glass/shaders/oh6-1.agsl)。

背景与宿主源码：[ic8](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/ic8.java)、[uj8](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/uj8.java)、[wq8](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/wq8.java)、[C3895](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/com/coolapk/market/view/main/C3895.java)、[MainFragment](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/com/coolapk/market/view/main/MainFragment.java)、[ps8](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/ps8.java)、[pq8](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/pq8.java)、[LiquidTabMotionState](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/com/coolapk/market/widget/compose/liquid/LiquidTabMotionState.java)。

| 酷安机制 | Flutter 实现 | 边界 |
| --- | --- | --- |
| uj8 → wq8 → ic8 页面 GraphicsLayer / 屏幕坐标换算 | `coolapk_navigation_surface.dart` 的 `_LiveBackdropLayer` 与 `_BackgroundRender`（共享 BackdropKey） | 实时 GPU backdrop，addToScene 时重新上传当前位置；不捕获页面到 CPU，不冻结滚动背景 |
| TabPanel 容器 blur / lens | `coolapk_navigation.frag` 的 bar 分支 | 2dp blur、16dp height、32dp amount；不启用外层色散 |
| Thumb 背景独立光学 | 同 Shader 的独立 Thumb 实例 | 与外层共享原始 backdrop，独立高斯模糊后折射，7dp / 9.8dp 恒定；blur 从 2dp 插值到 0；输出区域不重叠，不采样外层已过滤结果或前景 |
| AccentCapture → Thumb 内容 lens | `_ContentRender` / `coolapk_content.frag` | 仅捕获图标文字；height=7×press、amount=9.8×press；静止原图，按压内容折射与背景插值分开 |
| ik8 / q6f | `coolapk_optics.glsl` | 原 rounded rect SDF、1.5 倍梯度半径、圆弧映射、负 amount、七次采样与原 RGB/alpha 权重 |
| oh6 Default 高光 | `edgeLight` | 45°、falloff=1、白色 .5 加法；边缘宽度/模糊用平滑带近似；非固定整圈描边 |
| bn1 → os8 copy mask 34567 → pq8 / ps8 | `CoolapkNavigationStyle` | 浅色 #FAFAFA、深色 #121212，容器 .63；黑/白选中 .10；半透明降级容器 .90 |
| ax8 / LiquidTabMotionState | `_DockState` 的五个独立弹簧 | position、press、scaleX、scaleY、velocity 分开，见下表；光学不随速度关闭 |
| C5164 → jo8.CompactSpec → qs8 / C3895 主宿主 | `_AppShellState` | 20dp 侧距，480dp 最大宽度；jo8.CompactSpec：外层56dp、padding4dp、内容48dp、镜片51.84dp；隐藏175ms、显示225ms；键盘阈值100dp；隐藏立即取消点击 |

两个背景滤镜共用 BackdropKey，Flutter 引擎在第一个滤镜之前缓存原始页面，两者从该原始输入独立计算。外层输出裁剪为胶囊减去 Thumb，Thumb 输出裁剪为镜片，区域不重叠。每层采用 ImageFilter.compose(outer: opticalShader, inner: ImageFilter.blur)，先由引擎执行完整高斯模糊，再折射和着色；Thumb 的 sigma 从2dp独立插值到0。按压内容仍为单独的图标层，不参与这些背景捕获。

2026-10-12 后续重影修复：删除此前的9点稀疏 Gaussian quadrature。它保留方差却没有保留连续的模糊核，细文字在间隔约3.464dp的位置形成副本，随后被边缘折射放大。新的实测细线与原生高斯参考逐像素比较，外层和静止 Thumb 最大通道误差都为0；旧外层为55。[修复验收](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/GHOST_FIX.md)。

## 文件

文件绝对路径：
- [liquid_navigation_dock.dart](/Users/goulijun/Documents/project/YANJI/lib/design/glass/liquid_navigation_dock.dart)：三槽导航与五条弹簧、指针取消处理、RTL、竖向适配、减弱动态效果。
- [coolapk_navigation_style.dart](/Users/goulijun/Documents/project/YANJI/lib/design/glass/coolapk_navigation_style.dart)：专用参数、颜色、能力枚举与弹簧转换。
- [coolapk_navigation_surface.dart](/Users/goulijun/Documents/project/YANJI/lib/design/glass/coolapk_navigation_surface.dart)：实时背景、独立前景滤镜、三档降级、uniform 绑定。
- [coolapk_navigation.frag](/Users/goulijun/Documents/project/YANJI/assets/shaders/coolapk_navigation.frag)：独立外层 / Thumb 背景分支。
- [coolapk_content.frag](/Users/goulijun/Documents/project/YANJI/assets/shaders/coolapk_content.frag)：独立内容折射。
- [coolapk_optics.glsl](/Users/goulijun/Documents/project/YANJI/assets/shaders/coolapk_optics.glsl)：距离场、折射、原色散权重与方向光。
- [yanji_app.dart](/Users/goulijun/Documents/project/YANJI/lib/app/yanji_app.dart)：主宿主间距、键盘与滚动隐藏；原路由、PageStorageBucket、业务状态保持。
- [liquid_glass_geometry_blended.frag](/Users/goulijun/Documents/project/YANJI/packages/liquid_glass_renderer/lib/assets/shaders/liquid_glass_geometry_blended.frag)：修正旧 opt-in 分支在 GLES 上的导数方向。
- [YANJI_PATCHES.md](/Users/goulijun/Documents/project/YANJI/packages/liquid_glass_renderer/YANJI_PATCHES.md)：记录兼容修复，保留 MIT 许可与来源。
- [pubspec.yaml](/Users/goulijun/Documents/project/YANJI/pubspec.yaml)：注册两个 Shader。
- [liquid_navigation_dock_test.dart](/Users/goulijun/Documents/project/YANJI/test/widget/liquid_navigation_dock_test.dart)：更新不再适用的“静止关闭镜片”等断言，以可观察交互结果验收。
- [navigation_blur_regression_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/navigation_blur_regression_test.dart)：与原生高斯比较细线亮度剖面，防止稀疏取样出现文字副本。
- [coolapk_navigation_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/coolapk_navigation_test.dart)：可重复的网格、细线、小字号文字、彩色块、坐标场与交互渲染测试。
- [navigation_app_runtime_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/navigation_app_runtime_test.dart)：真实应用三路由、滚动、键盘验收。
- [navigation_edge_optics_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/navigation_edge_optics_test.dart)：保留原共享库边缘实验；原导航速度开关断言由专用测试替代。
- [navigation_appearance_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/navigation_appearance_test.dart)：空白采样点随三槽宽度计算。
- [coolapk_navigation_driver.dart](/Users/goulijun/Documents/project/YANJI/test_driver/coolapk_navigation_driver.dart)：保存截图与验收数据。
- [liquid_glass_backdrop_alignment_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/liquid_glass_backdrop_alignment_test.dart)：实际渲染复现、截图同步或共享控件回归。
- [liquid_glass_refraction_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/liquid_glass_refraction_test.dart)：实际渲染复现、截图同步或共享控件回归。
- [liquid_glass_visual_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/liquid_glass_visual_test.dart)：实际渲染复现、截图同步或共享控件回归。
- [navigation_capture.dart](/Users/goulijun/Documents/project/YANJI/integration_test/support/navigation_capture.dart)：实际渲染复现、截图同步或共享控件回归。
- [navigation_motion_performance_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/navigation_motion_performance_test.dart)：无截图读回的连续拖动、背景更新帧耗时诊断。
- [navigation_regression_suite_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/navigation_regression_suite_test.dart)：实际渲染复现、截图同步或共享控件回归。
- [validate_coolapk_navigation.sh](/Users/goulijun/Documents/project/YANJI/tool/validate_coolapk_navigation.sh)：实际渲染复现、截图同步或共享控件回归。

## 参数、坐标和动画

Shader Filter 的第一个 `vec2 uSize` 和第一个 sampler 由引擎提供。背景 uniform 顺序：size[0–1]、bar xywh[2–5]、thumb xywh[6–9]、DPR[10]、press[11]、full[12]、container rgba[13–16]、selection rgba[17–20]、光学 height/amount 四元组[21–24]、part[25]（0外层、1Thumb）。内容顺序：size[0–1]、thumb xywh[2–5]、press[6]、height/amount[7–8]。

所有长度从 dp/逻辑像素转换一次：屏幕逻辑 rect × DPR，height/amount × DPR；引擎 ImageFilter.blur 的 sigma 使用逻辑dp，由引擎应用一次 DPR。Shader 的 frag coord、局部坐标和 SDF 全部用物理像素，UV＝采样物理坐标 / 输入纹理物理尺寸。没有旧库的几何贴图编码、厚度解码或 refractiveIndex 换算。顶边内侧2dp处，t=1−2/16=.875；负amount配合朝外的法线，采样向内移动约16.51dp。坐标页的绿色斜率255/240、材质透过率.37，预计像素绿色差约6.49；实际两种DPR均为+6，中心为0。背景使用 getTransformTo(null) 获取逻辑屏幕坐标（显式 RenderView 目标在本 SDK 包含 DPR），内容坐标相对固定尺寸的离屏图标层。变换、窗口和 DPR 更新时重新上传。采样到纹理边界时钳制；采样颜色按 premultiplied RGBA 组合，不在此额外改变色彩空间。

| 状态 | mass | stiffness | dampingRatio | Flutter damping |
| --- | ---: | ---: | ---: | ---: |
| position | 1 | 1000 | 1.0 | 63.2456 |
| press/effect | 1 | 1000 | 1.0 | 63.2456 |
| scaleX | 1 | 250 | .6 | 18.9737 |
| scaleY | 1 | 250 | .7 | 22.1359 |
| velocity | 1 | 300 | .5 | 17.3205 |

转换公式 c＝2ζ√(km)。TabPanel 的 f17079 使用默认 mask 511，未发现这里覆盖默认弹簧。速度形变按源码 scaleX/(1−clamp(v/10×.75))、scaleY×(1−clamp(v/10×.25))；80ms 无输入后独立速度弹簧制动。释放落位到最近槽位，取消回到原路由，父路由确认提交不重复启动镜片动画。

## 已知适配与未确认部分

- 三项研迹图标、名称、路由与主色保留；正常内容色采用 jo8 的黑/白基准，选中内容按研迹槽位状态着色。原 Compose 双份 AccentCapture 的逐片段运动着色没有原样实现；容器颜色采用源码基准。宽度和槽位适配，不使用旧 64px 小泡泡。
- 主宿主在自动隐藏 / 显示的淡入淡出阶段暂用显式半透明材质，结束后恢复实时液态玻璃，避免 Flutter Opacity 离屏层被玻璃采样自身。这是 Flutter 合成适配，不宣称与 Compose 淡入阶段逐帧同源。
- 横屏继续保留研迹竖向布局；这是产品适配，不是酷安原版横屏逐像素复刻。
- 背景模糊现采用 Flutter 引擎完整高斯核，已验证本机 Impeller 的细线结果；与 Android RenderEffect 跨引擎逐像素一致性仍未验证。
- 原 Android RenderEffect 与 Flutter 纹理的颜色空间 / HDR 处理未取得跨引擎逐像素对照；本实现使用 Flutter 输入的 premultiplied RGBA，不额外转换颜色空间。
- 高光窄带与阴影为 Flutter 绘制适配，未获取原版时间序列或录屏。按压 scale 的接合、80ms 制动窗口、指针速度的采样与端点阻尼属于明确适配，不宣称百分之百一致。
- 本路径不使用共享 `YanjiGlassSurface`，本地 `liquid_glass_renderer` 仅校正旧 opt-in `edgeMagnification` 分支在 GLES 上的 dFdy Y 方向；默认共享光学分支、材质、最终解码和许可证保持原状。该 opt-in 分支已不被新导航使用。默认共享控件维持原行为；使用 indicator 角色的分段选择器在 GLES 上也得到这一方向修正，需以共享控件回归截图核对。
- Full 以 `ImageFilter.isShaderFilterSupported` 和 Shader 加载成功为条件；没有套用 Android API33 门槛。引擎不支持时为 blur；显式 translucent 无 Shader / blur。加载期间显示“背景模糊（材质加载中）”，加载失败报告错误并降级，不能标为 Full。

## 复现与取证

运行入口：[validate_coolapk_navigation.sh](/Users/goulijun/Documents/project/YANJI/tool/validate_coolapk_navigation.sh)。参数 `optics --profile`、`regression --profile`、`app --profile`、`benchmark --profile`、`blur --profile`、`run --profile` 分别执行专用场景、共享控件回归、真实应用验收、无读回性能诊断、细线模糊重影回归和预览启动。设备由 NAV_DEVICE 指定，截图目录由 NAV_RUN 指定。脚本在执行期间暂用 Gradle8.14.3 / AGP8.11.1 / Kotlin2.2.21 和官方 SQLite3.53.1 源码钩子，退出时恢复项目原始配置；不修改 minSdk、SDK、全局代理或用户数据库。此机的原始 Gradle9.3.1 / AGP9.1 / Kotlin2.4 组合曾遇到 Kotlin DSL 与下载故障；兼容组合仅用于本次可重复验证。

截图同步：[navigation_capture.dart](/Users/goulijun/Documents/project/YANJI/integration_test/support/navigation_capture.dart)。Android 转换后的 ImageView 在刚 pump 后可能仍暴露上一帧，先取得一次同步帧，再保存下一帧；同步帧不作为验收图片。仅验证时 CPU 读回，生产渲染没有截图循环。

共享回归入口：[navigation_regression_suite_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/navigation_regression_suite_test.dart)。保留既有 alignment、edge、appearance、refraction 和真实应用玻璃控件场景。旧视觉测试中仅更新导航专用类型、滚动隐藏后的显示准备、主题轮次开始时显式滚回页顶和截图同步，未改共享控件的断言阈值。导航按压弹簧的浮点收敛断言改为 .0001 容差（与模拟器实际值 0.9999999999786174 一致）；共享控件断言不变。

运行结果、设备、截图和录屏见 [RESULTS.md](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/RESULTS.md)。

真实应用测试在原 FlutterView 上检查系统 IME inset 和隐藏点击状态，再转换截图视图。首次启动应先处理 Android 通知权限弹窗，以免系统弹窗抢占键盘焦点；验收驱动仅在脚本明确指定的 emulator-* 测试模拟器上、连接恢复被暂停的测试入口之前设置通知测试权限，避免每次测试卸载重装引发弹窗；不改变实体设备权限。预览初始化会生成学习记录，因此使用条件等待（最长五分钟），而非固定七秒延迟。

键盘断言从真实 FlutterView 窗口读取物理 inset 并除以 DPR；Scaffold 处理避让后会清零 body 子组件的 MediaQuery inset，不能用 Dock 子组件的 inset 判定系统键盘是否出现。主宿主在 Scaffold 上方读取 inset 并控制隐藏。
