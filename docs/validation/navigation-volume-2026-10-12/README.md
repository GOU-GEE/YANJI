# 镜片体积、端部包裹与上下对称 — 2026-10-12

本轮凸透镜与圈圈感修正见[最新验证](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-convex-2026-10-12/README.md)，下文保留历史版本参数和结果。

根据本轮酷安参考图补足滑块立体感和栏体在镜片内缩小的行为，沿用此前的紧凑布局、略微突出的高度及图标文字局部变绿。

## 修改

- 此前只有外层胶囊投影，滑块缺少独立投影。新增按压力度淡入的滑块柔影和接触影（逻辑blur 7/2dp，偏移3/1dp），可以落在栏体和页面上，但裁掉滑块内部。阴影在两次背景捕获之后绘制，不会进入折射输入造成重复阴影。
- 在滑块材质增加4dp柔和反射带与2–7dp内侧暗肩，使玻璃边缘有厚度。明暗方向与光学坐标分开，立体感不靠增加高度；按压目标仍为60.1344dp，速度及弹簧限高61.6896dp。
- 接近左右端时沿导航轴每侧渐增至10dp额外包裹宽度，0.65槽位内平滑退回普通宽度。当前272dp三项导航按住端点时，镜片比放大后的栏体左右端多伸出约4.96dp。适配竖向轴和RTL。
- 滑块内捕获的栏体沿导航轴收窄8%，横轴保持中心最大12%的内凹包络，镜片外的栏体保持原状。因此端部轮廓也收进滑块，能够在镜片内部看见左右端边界。
- 光学压缩以滑块/栏体共同中心为基准，横轴映射对上下镜像对称。色散强度改为位置乘积的绝对值，使七路采样在上下边界也镜像对应；光照与下方投影仍可有方向感，但不改变内凹几何。
- 图标/文字的布局尺寸仍是24dp/10dp，只有镜片内部的局部光学变形；其余路由和交互不变。

酷安反编译样式[os8.java](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/os8.java:39)明确包含innerShadowRadius、outerShadowRadius、outerShadowOffsetY等参数。本轮端部外扩、收窄及明暗系数依据参考图调校，不宣称与原APK逐像素完全一致。

代码：[滑块几何和阴影](/Users/goulijun/Documents/project/YANJI/lib/design/glass/liquid_navigation_dock.dart)、[局部采样及体积光照](/Users/goulijun/Documents/project/YANJI/assets/shaders/coolapk_optics.glsl)、[滑块背景](/Users/goulijun/Documents/project/YANJI/assets/shaders/coolapk_navigation.frag)。

## 验证

Android16/API36 arm64模拟器yanji_api36，DPR2.625，Impeller OpenGLES。验证入口仍为[可恢复构建脚本](/Users/goulijun/Documents/project/YANJI/tool/validate_coolapk_navigation.sh)的lens目标。

- [7项交互测试](/Users/goulijun/Documents/project/YANJI/work/navigation-volume-widget.log)：左右端及RTL包裹、共同中心、无整体图标文字放大、点击/拖动/反向/取消/竖向/降级检查通过。
- [静态检查](/Users/goulijun/Documents/project/YANJI/work/navigation-volume-analyze.log)：No issues found。
- [原生渲染测试](/Users/goulijun/Documents/project/YANJI/work/navigation-volume-render.log)新增高对比探针，测量三个横向位置的上下内凹差、镜片内左右端部轮廓及其对称性；完整页面截图检查左右端和跨槽状态。

原生测试全部通过。[像素结果](metrics.json)：三个横向位置（中心及±15dp）的上内凹8px、下内凹9px，差1个物理像素（DPR2.625约0.38dp，来自边界像素落点）；坐标映射本身上下镜像对称。镜片外栏高146px、内部129px。左右端栏体向内收进9.75/10.75px，端部轮廓距镜片外沿36/37px，左右差1px。

[完整页面状态对比](navigation-frames.png)来自真实渲染截图裁剪拼接；[全部原图](../coolapk-navigation-2026-10-11/android-lens-volume/)保留。[左右端](boundary-left-detail.png)、[右端](boundary-right-detail.png)、[上下内凹](boundary-held-detail.png)使用蓝底探针确认轮廓实际位于镜片内。前景墨迹发生12232个像素位置变化，折射仍有效。截图采集过程不代表连续动画时序，本轮未重新测量FPS。

本轮仅操作模拟器，手机仍待覆盖修正版。

正常使用版build8（YANJI_PREVIEW=false）的[APK](/Users/goulijun/Documents/project/YANJI/work/phone-update-2026-10-12/yanji-normal-build8.apk)已准备好。签名SHA256与手机原App一致，release mapping保留go.Seq.getRef，包含此前的同步组件启动修复；没有覆盖手机。构建号仅在构建参数中指定，项目pubspec版本不改。

模拟器安装build8 release预览版（YANJI_PREVIEW=true），[源码和APK记录](build-record.json)保存哈希并确认四项Android构建配置恢复、无临时SQLite钩子、pubspec版本仍为0.1.0+1。演示版启动会生成学习记录；[最终启动核对](startup-check.json)和[release静止截图](release-rest.png)保留实际运行证据。

预览生成期间首次60秒页面等待未完成，随后已正常进入今日页，未发现原生abort或Flutter错误。最终release的[按压细节](release-held-detail.png)、[移动细节](release-slide-detail.png)也已在模拟器实际渲染并截图复核，页面可交互。本轮未修改预览初始化逻辑。
