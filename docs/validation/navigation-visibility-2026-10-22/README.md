# 导航栏显隐期间保留玻璃 — 2026-10-22

旧代码在 visibility != 1 时强制 refractBackdrop=false，将表面切换为不采样的半透明材质。动画结束再开启折射，因此出现材质跳变。外层 Opacity 的离屏层也是原来关闭采样的原因。

AppShell 改用导航专用 NavigationDockTransition：单一进度控制位移和 .92→1 的轻微收缩，取消外层 Opacity，保留实时背景过滤器。移出屏幕后 Offstage 停止绘制，隐藏位移包含边缘间距和溢出范围。快速反向时沿当前进度返回，保持同一玻璃实例。三个入口、业务路由、玻璃着色参数和图标大小均未修改。

## 验证

- 11 项控件和图层测试通过：显隐/反向、横竖布局、按压拖动和原有导航交互。
- 静态检查通过。
- Android API36 ARM64 模拟器原生渲染验证：浅/深色、底栏/侧栏、35%/70%/100% 共 12 个位置，采样材质与相同几何下不采样对照的像素平均差异 6.31–25.69/255；液态玻璃能力已就绪。网格截图肉眼可见折射/模糊，未看到自采样灰块。该数值用于确认采样确实开启，并非完整光学精度指标。
- 实际 App 页面验证通过：今日/数据/我的、滚动隐藏/出现、滚动位置恢复、真实键盘避让。中间帧采集时的可见进度为隐藏 .511、出现 .396；对应截图可能尚未进入屏幕，故不将它们单独作为折射的视觉证据。
- 材质拼图 light-material-comparison.png 和 dark-material-comparison.png：同一背景与几何，上排关闭采样，下排保持采样。它们是材质诊断对照，并非原始旧版动画的完整截图。

完整原生截图分别保存在 ../coolapk-navigation-2026-10-11/android-visibility-2026-10-22/ 和 ../coolapk-navigation-2026-10-11/android-visibility-app-2026-10-22/。

## 安装

正常使用版：/Users/goulijun/Documents/project/YANJI/work/navigation-visibility-2026-10-22/yanji-normal-build23.apk（YANJI_PREVIEW=false）。
模拟器预览版：同目录 yanji-preview-build23.apk（YANJI_PREVIEW=true），沿用独立预览数据。

用户将验证改回模拟器，手机已断开；本轮不宣称真机验证或安装成功。此前在手机安装的独立测试应用 com.example.yanji.navigationprobe 因缺少测试插件未完成验证，没有改动正常应用的数据；应在下次连接后清理该测试应用。模拟器测试插件问题已通过重新生成开发插件注册解决。

原有共享玻璃 Shader 的 SkSL 编译警告仍在构建日志中；本次 Android 原生运行使用 Impeller，导航专用 Shader 实际运行通过。实际页面测试结束时工具尝试清理旧的独立测试包，报告 DELETE_FAILED_INTERNAL_ERROR；测试本身全部通过，正常 App 随后以最新预览包覆盖安装验证。
