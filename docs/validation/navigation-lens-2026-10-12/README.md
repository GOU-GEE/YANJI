# 滑块高度、局部内凹与前景折射 — 2026-10-12

后续增加独立镜片阴影、端部包裹和上下对称检查，见[最新记录](../navigation-volume-2026-10-12/README.md)。本页保留上一轮build6记录。

按用户提供的酷安参考图调整导航，保留272dp紧凑宽度、三项路由和按滑块边界局部变绿的行为。

- 静止栏高56dp，按压栏体最多增长4%至58.24dp。滑块静止高51.84dp，按压目标60.1344dp；速度形变与弹簧过冲限高61.6896dp，上下边缘只略微突出。
- 滑块内采样已经绘制的导航材质，沿较短轴局部收窄；滑块纵向中心收窄最多12%，到两端渐变为0。按压时朝外采样，使捕获的导航栏上下边界向内弯曲，滑块外的栏体不受此局部映射影响。略微超出栏体的镜片边缘可以采样页面并折射。
- 图标、文字保持24dp/10dp布局，没有按压整体缩放。恢复仅滑块内部的前景光学变形，使用相同局部映射、边缘折射和七路RGB色散采样。内部采样着主色，外部保持黑色/深色主题白色；图标横跨镜片边界时保留局部变色。
- 页面文字仍通过外层原生高斯模糊，不恢复此前导致重影的稀疏九点模糊。渲染顺序是页面→栏体材质→滑块材质折射→独立图标文字折射。

1.16压力比例、限高、12%局部收窄和按压时折射方向是依据本轮参考图的产品调校；并非宣称与原APK逐像素完全相同。圆角距离场、边缘折射和七路色散保留此前源码转写的基础。

## 实际验证

Android16/API36 arm64模拟器yanji_api36，DPR2.625，Impeller OpenGLES。

- [7项交互测试日志](/Users/goulijun/Documents/project/YANJI/work/navigation-lens-widget.log)：紧凑宽度、玻璃增长而图标文字布局不变、拖动镜片限高、点击/反向拖动/取消/RTL/竖向/降级全部通过。
- [静态检查](/Users/goulijun/Documents/project/YANJI/work/navigation-lens-analyze.log)：No issues found。
- [原生渲染与完整页面测试日志](/Users/goulijun/Documents/project/YANJI/work/navigation-lens-final.log)：全部通过；真实Flutter主程序加载、拖动和松手截图无异常。
- [像素测量](metrics.json)：对蓝底材质探针，滑块外栏体高度146px、内部129px，约收窄6.48dp；外部高度与静止值差不超过2px。独立图形探针的11769个墨迹像素发生位置变化，确认实际前景光学变形。
- [静止/按压/移动/松手截图拼图](navigation-frames.png)来自完整页面的原生渲染截图，裁剪与拼接，没有修改镜片像素；[全部原图](../coolapk-navigation-2026-10-11/android-lens-final/)保留。此拼图是状态对比，不是连续录屏，也未重新测量FPS。
- [内部栏体凹陷](boundary-held-detail.png)、[前景折射探针](glyphs-refracted-detail.png)使用高对比背景检查局部行为。探针与页面截图均在真实模拟器渲染，而非软件生成效果图。

## 构建与设备

最终模拟器使用build6 release预览版（YANJI_PREVIEW=true），可直接交互查看。正常使用版本build6使用YANJI_PREVIEW=false，已保留用于以后覆盖手机；本轮没有操作手机。

[最终release静止截图](release-rest.png)、[按压截图](release-held.png)、[移动截图](release-slide.png)来自原生屏幕捕获，已核对。[启动记录](startup-check.json)保留正常加载页面和存活进程证据。演示版首启生成学习记录需等待；只在测试模拟器上处理通知许可。

[正常版本APK](/Users/goulijun/Documents/project/YANJI/work/phone-update-2026-10-12/yanji-normal-build6.apk)包含同步组件consumer规则修复，R8 mapping保留go.Seq.getRef及go/engine成员；签名和原App一致。手机当前仍是此前存在启动闪退的build3，待手机方便时覆盖修正版。

[构建与源码记录](build-record.json)保存APK哈希和相关源码哈希。[复现脚本](/Users/goulijun/Documents/project/YANJI/tool/validate_coolapk_navigation.sh)新增lens目标与临时NAV_BUILD_NUMBER，Android兼容工具链和SQLite钩子在退出时恢复；项目版本仍为0.1.0+1。
