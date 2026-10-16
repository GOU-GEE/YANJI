# 导航背景文字重影修复 — 2026-10-12

本轮凸透镜与圈圈感修正见[最新验证](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-convex-2026-10-12/README.md)，下文保留历史版本参数和结果。

最新紧凑宽度、局部着色、镜片阴影、端部包裹和上下对称的产品调整见 [2026-10-12后续验收](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-volume-2026-10-12/README.md)。以下保留此前版本的实现/验收记录。

此前将2dp高斯模糊近似为9个稀疏采样点，偏移为±√3×sigma（逻辑约3.464dp）。该近似虽然匹配方差，但会把细字和细线叠成几份，再被16dp/32dp边缘折射放大；尤其在“学习热力图”“查看更多”穿过胶囊时可见。普通线性坐标场没有暴露这个模糊核问题。

现在删除稀疏模糊计算，使用 Flutter 引擎的 ImageFilter.blur。外层和Thumb有两个独立的 optical Shader 实例，分别组合“高斯模糊→折射→材质色/高光”，共用一个 BackdropKey 的原始页面输入；引擎缓存的是当前帧过滤前背景。输出裁剪区域互不重叠，Thumb不会再采样已处理的外层。图标文字的前景滤镜和弹簧状态保留，未削弱折射参数来隐藏错误，也没有改动其他共享玻璃组件。

## 修改文件

- [coolapk_navigation_surface.dart](/Users/goulijun/Documents/project/YANJI/lib/design/glass/coolapk_navigation_surface.dart)：原生高斯组合滤镜、共享原始 backdrop、两块不重叠裁剪区域。
- [coolapk_navigation.frag](/Users/goulijun/Documents/project/YANJI/assets/shaders/coolapk_navigation.frag)：按 part 分别处理外层/Thumb，每层输入已独立模糊。
- [coolapk_optics.glsl](/Users/goulijun/Documents/project/YANJI/assets/shaders/coolapk_optics.glsl)：删除9点稀疏核，保留折射与色散算法。
- [coolapk_content.frag](/Users/goulijun/Documents/project/YANJI/assets/shaders/coolapk_content.frag)：匹配共享折射函数签名，内容层不额外模糊。
- [navigation_blur_regression_test.dart](/Users/goulijun/Documents/project/YANJI/integration_test/navigation_blur_regression_test.dart)：一物理像素黑线的41点亮度剖面，与原生高斯参考比较；外层/Thumb在press=0、.5、1时独立检查。
- [validate_coolapk_navigation.sh](/Users/goulijun/Documents/project/YANJI/tool/validate_coolapk_navigation.sh)：新增 blur --profile 复现入口。

## 已取得的验证

Android16 / API36 arm64模拟器，1080×2400，Flutter3.47.2 / Impeller OpenGLES / profile。

- 修复前DPR2.625外层最大通道误差55，原有实现无法通过新细线回归。[失败日志](/Users/goulijun/Documents/project/YANJI/work/navigation-ghost-before.log)、[旧模糊图](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-ghost-before/gaussian-bar-actual.png)、[原生参考](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-ghost-before/gaussian-bar-reference.png)。
- 修复后DPR2.625，外层/Thumb在press=0、.5、1六组剖面的最大通道误差全部0；[数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-ghost-pressure/metrics.json)、[日志](/Users/goulijun/Documents/project/YANJI/work/navigation-ghost-pressure.log)。
- DPR2.0同样六组亮度剖面最大通道误差全部0。[数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-ghost-dpr2/metrics.json)、[日志](/Users/goulijun/Documents/project/YANJI/work/navigation-ghost-dpr2.log)。
- 最终 main.dart 预览应用已实际运行，在同一“数据”页手动切换后截图复核“学习热力图/查看更多”背景文字：不再产生稀疏取样的多份副本。[用户反馈原图](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/ghost-fix-user-before.png)、[修复后完整截图](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/ghost-fix-app-statistics.png)、[底栏细节](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/ghost-fix-app-navigation-detail.png)。模拟器系统日期切换到10月12日，统计值会变化，这两张应用图只作视觉复核；定量比较使用上面的受控细线场景。
- 静态检查通过，无诊断。[日志](/Users/goulijun/Documents/project/YANJI/work/navigation-ghost-analyze.log)。
- 完整光学/交互矩阵通过：浅深、静止/按压、连续跨槽/反向/取消、三档/窄屏、RTL/竖向；边缘绿色差+6、中心0、按压改变3176个墨迹像素，滚动图片改变65265个底栏像素。[数据](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-ghost-optics/metrics.json)、[日志](/Users/goulijun/Documents/project/YANJI/work/navigation-ghost-optics.log)。
- [可重复中文背景截图](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/android-ghost-pressure/chinese-background-navigation.png)已人工检查：背景呈连续模糊，导航文字清晰，不再出现稀疏核生成的等间隔文字副本。

原生 blur 使用逻辑长度，由引擎应用DPR；Shader几何/height/amount仍转换为物理像素一次。折射仍会使背景字形放大或弯曲，这是保留的光学效果。跨Android RenderEffect与Flutter引擎的高斯核、色彩空间逐像素等价，以及真机/iOS表现仍未验证。

最终预览应用留在 emulator-5554 运行，Flutter连接已正常分离；密度恢复420/DPR2.625。Android四项构建配置与pubspec逐字节核对恢复成功，没有留下临时SQLite钩子。

[重新构建的预览APK](/Users/goulijun/Documents/project/YANJI/build/app/outputs/flutter-apk/app-profile.apk)、[最终源码与APK SHA256 / 配置核对](/Users/goulijun/Documents/project/YANJI/docs/validation/coolapk-navigation-2026-10-11/ghost-fix-fingerprint.json)。这是YANJI_PREVIEW测试构建，非生产发布包。本次没有重新测量无截图性能，早先耗时记录属于修复前管线；不作新版本固定FPS声明。
