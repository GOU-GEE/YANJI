# 紧凑导航与滑块遮罩 — 2026-10-12

后续参考图的高度、局部内凹和前景折射更新见[最新验证记录](../navigation-lens-2026-10-12/README.md)。下面的截图和78/56压力比例是此前版本；当前实现以最新记录为准。

按本轮澄清实现的产品行为：

- 三项导航静止宽度272dp、高56dp，居中；88dp/槽位＋两侧4dp内边距，按可用空间与480dp上限约束。导航项增多时自然宽度增长；例如四项360dp，直到达到宿主可用宽度才铺满。
- 按住或拖动时外层玻璃最多放大4%，选中镜片保留原78/56压力比例和速度形变。图标保持24dp、文字10dp，固定字重；无额外缩放，也不再让前景参与折射放大。
- 镜片内图标/文字为主色绿色，镜片外为黑色（深色主题为白色）；同一个图标进入一半就只变色一半。使用圆角矩形距离场ShaderMask，只有一份控件树，路由与无障碍语义不重复。
- 页面→外层高斯模糊/折射/材质色→镜片→阴影/图标。镜片有独立backdrop标识，采样已经画出的导航栏；其内部不会因为按压而直接切成未模糊页面。镜片越出栏体边缘的部分可以采样页面并产生折射。镜片上不再重复覆盖一层容器色，静止选中色.10按压时降到0。外层2dp模糊、16/32dp折射及.63材质色保留。

这是按用户最新要求调整后的渲染顺序，替代此前“外层与Thumb独立采样原页面”的版本；不将本轮产品适配声称为原APK逐像素完全一致。

## 验证与查看

Android16/API36 arm64模拟器yanji_api36，1080×2400，DPR2.625，release预览构建，Impeller OpenGLES。模拟器窗口已打开，应用停在今日页供交互查看。

- [7项Widget测试日志](/Users/goulijun/Documents/project/YANJI/work/phone-update-2026-10-12/navigation-widget-tests.log)：新增紧凑宽度、按压时图标文字矩形保持不变、玻璃裁剪区增大；原点击/拖动/取消、RTL/竖向、反向速度和降级检查通过。
- [静态检查](/Users/goulijun/Documents/project/YANJI/work/phone-update-2026-10-12/navigation-analyze.log)：No issues found。
- [静止截图](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-compact-2026-10-12/rest.png)、[按压截图](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-compact-2026-10-12/drag-0.png)、[移动中截图](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-compact-2026-10-12/drag-1.png)。均为实际模拟器屏幕捕获，已人工核对。
- [同一图标局部变绿证据](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-compact-2026-10-12/colour-pixels.json)：移动中“我的”图标区域同时有518个黑色像素与58个绿色像素，证明并非整槽跳色；[裁剪细节](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-compact-2026-10-12/navigation-partial-detail.png)。
- [截图关键帧GIF](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-compact-2026-10-12/navigation-keyframes.gif)：由实际截图轮播，供查看各阶段；不是连续录屏或实际动画时序。本次原生录屏只取得1.08秒文件，已留在work作为未采用的采集尝试，不作为完整交互录像。
- [启动核对](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-compact-2026-10-12/startup-check.json)：预览release应用进程持续存活，同步组件未再触发原生启动崩溃。未重新测量FPS。

## 必要的发布构建修复

[yanji_syncthing Android配置](/Users/goulijun/Documents/project/YANJI/packages/yanji_syncthing/android/build.gradle)现在随插件导出[consumer-rules.pro](/Users/goulijun/Documents/project/YANJI/packages/yanji_syncthing/android/consumer-rules.pro)，其两条keep规则来自原engine.aar内的proguard.txt。此前只解包classes.jar和JNI库，丢失规则，R8裁剪go.Seq.getRef导致native abort。改用稳定源文件路径后，插件AAR和最终mapping均保留该方法及go/engine类成员；同一release路径已在模拟器运行验证。保留原许可证，未改同步协议和数据库逻辑。

[复现脚本](/Users/goulijun/Documents/project/YANJI/tool/validate_coolapk_navigation.sh)新增build（正常数据版本）及preview-build（演示数据版本）；构建时正常再生各模式的插件注册文件，避免残留测试插件导致release编译错误。临时兼容工具链和SQLite钩子退出时恢复。

## 手机状态

按用户要求先在模拟器查看效果，暂不继续操作手机。此前最后覆盖到手机的是build3，该构建存在同步组件启动闪退；最终修正包尚未覆盖到手机。

[准备好的正常使用APK：build4，非预览](/Users/goulijun/Documents/project/YANJI/work/phone-update-2026-10-12/yanji-normal-build4.apk)已保留，签名与手机原App一致；[构建与源码记录](/Users/goulijun/Documents/project/YANJI/docs/validation/navigation-compact-2026-10-12/build-record.json)。手机重新方便连接后可覆盖安装，保持原有数据。
