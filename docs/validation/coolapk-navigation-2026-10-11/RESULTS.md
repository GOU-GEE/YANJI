# Android 实测与交付记录 — 2026-10-11

后续已修复文字多份重影，并改为引擎高斯模糊；最新实现与验收见 [GHOST_FIX.md](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/GHOST_FIX.md)。下文保留此前版本的验收记录和性能数据，不将旧性能测量当作新渲染管线的测量。

代码、参数与源码对应关系见 [IMPLEMENTATION.md](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/IMPLEMENTATION.md)。

## 实际环境

- 新建 Android 模拟器 yanji_api36 / emulator-5554，sdk_gphone64_arm64，Android16 / API36；不是实体手机。
- 1080×2400，密度420（DPR2.625）；另以密度320（DPR2.0）复核。当前密度已恢复420。
- Flutter3.47.2 stable，Dart3.13.2，engine a804b26164；Android Impeller OpenGLES；Apple M1 Pro / Android Emulator OpenGL ES Translator（Metal）。[版本记录](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/flutter-version.txt)
- Android 渲染测试均为 profile；widget 测试在宿主 Flutter 测试引擎执行。
- 最终预览使用真实 main.dart 与原有业务控制器，YANJI_PREVIEW=true 使用独立的 yanji_preview.sqlite；本次模拟器是测试环境。

## 已通过的检查

| 检查 | 结果与证据 |
| --- | --- |
| 相关源码、验收代码静态检查 | No issues found；[日志](/Users/goulijun/Documents/project/YANJI/work/navigation-final-analyze.log) |
| Widget 行为与共享控件 | 20项通过；点击、按住、跨槽、反向、取消、重新操作、RTL/竖向、减弱动态、模式/窄屏、滚动；[日志](/Users/goulijun/Documents/project/YANJI/work/navigation-unit-tests.log) |
| 专用光学与场景矩阵 | DPR2.625 两个测试场景通过；浅/深、拖动/取消、三档/窄屏、RTL与竖向适配；[数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-optics-final/metrics.json)、[日志](/Users/goulijun/Documents/project/YANJI/work/coolapk-navigation-optics-final.log) |
| DPR2.0 最终 Shader 复核 | 独立边缘/中心、内容、滚动图片测试通过；[数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-dpr2-pixels-final/metrics.json)、[日志](/Users/goulijun/Documents/project/YANJI/work/coolapk-navigation-dpr2-pixels-final.log) |
| 真实应用 | 今日/数据/我的、滚动隐藏/恢复、跨路由位置记忆、真实系统 IME inset、隐藏后禁用点击均通过；[日志](/Users/goulijun/Documents/project/YANJI/work/coolapk-navigation-app.log) |
| 原共享回归 | 6个测试场景通过（运行输出+7包含tearDownAll）；背景对齐、旧边缘、淡入、自定义弹窗、下拉、弹性卡片、分段指示器、浅深与真实横屏；65张截图；[日志](/Users/goulijun/Documents/project/YANJI/work/coolapk-navigation-regression.log) |

真实应用测试完成后，验证脚本因执行期间被编辑而出现末尾命令读取错误；测试本身全部通过，五项项目配置均核对为恢复原值。脚本随后冻结版本，共享回归、性能和最终DPR复核均完整退出成功。

## 像素证据

| DPR | 顶边内侧2dp绿色差 | 中心绿色差 | 按压改变的黑色墨迹像素 | 图片滚动改变的底栏像素 |
| --- | ---: | ---: | ---: | ---: |
| 2.625 | +6 | 0 | 3177 | 64388 |
| 2.0 | +6 | 0 | 1414 | 43827 |

外层探针64dp高、没有Thumb遮挡；实际导航场景56dp高。两种DPR的顶边取样方向和逻辑位移一致。中心直接采原内容；页面更新改变实时背景。墨迹比较使用同一白底且没有文字缩放，证明独立内容纹理的采样变化。像素数量受分辨率、抗锯齿和自适应宽度影响，不用于宣称两幅图逐像素相等。小字号/细线/彩块与圆角场景也已人工查看。

## 截图与视频

- 真实页面：[今日](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-app-final/app-today.png)、[数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-app-final/app-statistics.png)、[我的](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-app-final/app-profile.png)。
- 隐藏与恢复：[滚动隐藏](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-app-final/app-scroll-hidden.png)、[滚动显示](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-app-final/app-scroll-shown.png)、[系统键盘](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-app-final/native-ime.png)、[关闭键盘](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-app-final/app-keyboard-dismissed.png)。
- 独立材质：[浅色按住](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-optics-final/light-held.png)、[深色拖动](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-optics-final/dark-drag-3.png)、[三档液态](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-optics-final/tier-liquid-narrow.png)、[背景模糊](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-optics-final/tier-blur-narrow.png)、[半透明](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-optics-final/tier-translucent-narrow.png)。
- 内容层：[正常](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-optics-final/content-normal.png)、[按压](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-optics-final/content-pressed.png)。
- 共享组件：[弹窗与下拉](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-regression-final/light-study-subject-dropdown.png)、[弹性卡片](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-regression-final/dark-profile-elastic-held.png)、[分段镜片](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-regression-final/light-range-glass-held.png)、[实际横屏](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-regression-final/light-landscape.png)。
- [DPR2.0 原生交互录屏](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/navigation-interactions-dpr2.mp4)：H264，1080×2400，115.78秒，包含长按、跨槽、反向、取消和模式场景；[媒体元数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/video-info.json)。这一段是在最终Shader提前退出优化之前录制，视觉参数与交互机制相同；最终版本另有像素复核。

- [最终真实应用录屏](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/navigation-app-final.mp4)：最终 profile 构建，DPR2.625，原生输入覆盖长按、跨槽、回拖、三页切换和上下滚动；文件时间轴21.47秒，1080×2400。录制单独进行，不混入性能测量。[媒体元数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/app-video-info.json)。
- [最终应用运行截图](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/app-preview-running.png)、[底栏原生截图细节](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/app-navigation-detail.png)。

## 性能与限制

无截图压力场景：180次合成反向拖动，同时持续重绘整屏坐标页；排除GPU热身。238帧，build p50/p95=19.191/77.137ms，raster p50/p95=87.055/200.949ms，最大raster=387.204ms，操作窗口26.203秒。[完整数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-motion-performance-final/metrics.json)、[运行日志](/Users/goulijun/Documents/project/YANJI/work/coolapk-navigation-performance-before-content-clip.log)。

真实 main.dart 原生输入窗口：35.013743秒内125个有效帧，build p50/p95=9.689/62.884ms，raster p50/p95=58.169/211.739ms，最大raster=439.083ms。输入包括整段原生滑动、长按、三路由点击和页面上下滚动；测量期间没有截图、录像、WidgetTester 或坐标页。通过 VM 单调时钟起止范围和帧编号排除 DDS 的历史事件重播。[逐帧数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/native-app-motion-metrics.json)。事件帧数不是固定时间窗口FPS（静态画面不会持续绘制），这些数据仍只代表本机模拟器，实际应用交互也有明显掉帧，尚未达到真机流畅度验收。

这个复合压力场景在此模拟器上明显偏慢；它包含坐标页绘制，不能当作导航Shader独立耗时或目标手机FPS。额外内容裁剪的试验没有证实收益，已回退；[试验数据](/Users/goulijun/Documents/project/YANJI/work/navigation-content-clip-experiment/metrics.json)保留供核查。截图验收的帧数据另包含CPU读回，也不能用于固定帧率结论。常规生产渲染使用GPU backdrop/前景离屏层，不执行CPU截图或每帧图片解码。

源码参数、负amount、圆角SDF、圆弧映射、原色散权重与五条弹簧是主要一致性证据。Gaussian核、高光窄带/阴影、按压接合/制动、三槽/竖向与主色、AccentCapture着色方式属于明确适配。原版uniform时间序列、交互录屏、跨引擎颜色空间/HDR逐像素对照尚未取得，不能宣称100%复刻。

iOS/macOS/Windows/Web没有完成实际视觉验收；此机无可用Xcode模拟器。平台代码没有新增API31/33门槛，能力由Flutter引擎检查；Web显式使用降级。原共享库三个旧Shader仍存在SkSL编译警告（本次Impeller路径可运行），其Skia行为没有据此宣称完全验证。minSdk保持原值26，许可与来源保留。

复现入口：[validate_coolapk_navigation.sh](/Users/goulijun/Documents/project/YANJI/tool/validate_coolapk_navigation.sh)。兼容构建工具链和原配置恢复说明见实现文档。

## 最终运行与配置恢复

最终 main.dart profile 预览已安装并留在 emulator-5554 运行，Flutter 连接已正常分离。恢复后逐字节核对 Android 四项构建配置与 pubspec.yaml，五项均与本次保存的原值一致（pubspec含永久新增的两个Shader声明，没有临时SQLite钩子）。DPR恢复2.625，minSdk26未变；保留现有未提交修改，没有执行提交或重置。

[已构建的预览APK](/Users/goulijun/Documents/project/YANJI/build/app/outputs/flutter-apk/app-profile.apk)、[最终源码与APK SHA256 / 配置核对](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/code-fingerprint.json)。这份APK启用了YANJI_PREVIEW，供检查，不是生产发布包。
