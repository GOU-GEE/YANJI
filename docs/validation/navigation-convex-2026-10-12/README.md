# 凸透镜与“圈圈感”专项修正 — 2026-10-12

后续按用户补充要求，已独立恢复镜片内栏体背景的适当缩小，同时保留捕获图标文字放大。请参阅[本次修正与验证](../navigation-bar-reduction-2026-10-12/README.md)；下文保留上一轮记录。

保留三个导航项、业务路由和272dp紧凑宽度。本轮只修改导航专用实现、导航验证测试和复现工具；没有修改共享玻璃主题或其他业务实现。旧版本文件在work/navigation-lens-recovery/before留档。

## 原代码调用关系

JADX遗漏了部分大方法调用体，本轮另用原DEX的baksmali输出补查调用位置，文件保存在[调用链原始反汇编](/Users/goulijun/Documents/project/YANJI/work/navigation-lens-recovery/smali/com/coolapk/market/widget/compose/liquid/LiquidGlassTabPanelKt.smali)。

- ps8基础样式 → bn1/os8 copy mask34567保留pressedHeightRatio1.3928572、accentPressedScale1.2和阴影参数。
- TabPanel主方法取pressedHeightRatio调用remember motion（m32620）；LiquidTabMotionState以initialScale1、pressedScale1.3928572驱动独立X/Y弹簧。m32582应用运动缩放，m32616/17的速度修正分别为.75/.25，归一化修正范围±.2。移除产品适配时加入的1.19限高、pressedWidthRatio1.10及endpointLensOutset10dp。
- C5164 → jo8.CompactSpec → qs8：56dp容器、4dp内边距，内容高48dp；m57619明确计算selectionBackdropHeight=48×1.08=51.84dp。1.08有源码依据，保留这一选择捕获区域关系；它不是按压力度，也不替代镜片运动缩放。
- AccentCapture分支向内容函数传ut8 → m32581的lerp(1,1.2,press)。C5164.m32762将AccentCapture设为强调色、非交互内容；m32776将contentScale用于每项GraphicsLayer的X/Y缩放。普通Visible内容不接受该变换。Flutter现在用独立的非交互捕获树，按每项自身中心缩放，连续采样整排内容。
- m32584背景折射height/amount在静止与按压间插值；bn1两端均7/9.8dp；blur从2dp到0。m32591内容height/amount乘press。ik8上传amount=-f2，AGSL按coord+displacement取样。本轮恢复相同符号及原七路色散的有符号位置乘积，不再用正负翻转或横纵压缩补偿视觉。
- m32587为一个半径8dp×press的内阴影；r6f默认black.10、radius24dp、offsetY4dp；yx6默认black.15。kh6默认高光宽.5dp、blur.25dp；oh6为angle45、falloff1、white.5/Plus。移除4dp全周rim、2–7dp同心shoulder和双重接触阴影。

源码定位：[TabPanel](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/com/coolapk/market/widget/compose/liquid/LiquidGlassTabPanelKt.java:2452)、[C5164 AccentCapture](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/com/coolapk/market/widget/compose/liquid/C5164.java:281)、[每项内容缩放](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/com/coolapk/market/widget/compose/liquid/C5164.java:2013)、[qs8高度计算](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/qs8.java:97)、[负折射amount](/Users/goulijun/Documents/project/YANJI/work/apk-analysis-coolapk-16.6.2/runtime-jadx/sources/defpackage/ik8.java:92)。

## 当前渲染路径

实际启用的仍是LiquidNavigationDock → CoolapkNavigationSurface → coolapk_navigation.frag / coolapk_content.frag。coolapk_accent.frag的单树着色方式已被分离捕获替代，保留为兼容注册资产，当前导航不调用它。

页面 → 栏体原生高斯模糊/边缘折射/容器色.63 → Thumb独立背景输入 → 光照/阴影 → 普通可见内容与AccentCapture输出。Thumb内部采样已绘制的栏体，突出部分采样页面。检查确认此前thumbContainer已经透明，本轮没有发现重复应用.63的CPU配置；继续仅对外层施加.63，未用不透明白色填充镜片。

普通内容仅在镜片外绘制，捕获内容仅在镜片内输出，避免两份墨迹重叠；普通树的命中范围保持完整，捕获树无点击和重复语义。ImageFilterLayer是前景过滤，不捕获页面/栏体/阴影。其paintBounds与透明输入底板扩展32dp，并补偿Shader输入原点；背景输出裁剪用完整镜片路径，祖先布局无需扩大整个导航控件。端部不再添加额外outset。

额外压缩保留为Surface的独立legacyCompression诊断开关，生产默认关闭。optics/decorations开关用于依次检查几何、内容、折射和装饰。页面没有新增调参入口。

## 已确认的运行结果

Android16/API36 arm64模拟器yanji_api36，1080×2400，DPR2.625，Impeller OpenGLES。

1. 关闭折射、光照、阴影，用独立捕获颜色平面测量真实输出：左、中、右镜片高度均189px=72dp，完整突出56dp布局上下边界，没有端部裁切。[像素结果](metrics.json)。
2. 独立捕获内容从1到1.2，实际墨迹宽度比为1.190476（像素取整），普通层布局不变。
3. 边缘标记在负amount下向外移动0.95238dp，确认采样方向和DPR转换；另存额外压缩开启的对照图，正式路径关闭补偿。
4. 恢复光照/单一阴影，网格场景检查浅色、深色、liquid/blur/translucent三档的按压、连续跨槽和释放，无Flutter异常；手指停住后镜片尺寸稳定，释放press收敛到0。
5. [7项交互测试日志](/Users/goulijun/Documents/project/YANJI/work/navigation-lens-recovery/widget.log)：点击、连续拖动、反向、取消、RTL、竖向、降级及捕获缩放通过。[静态检查](/Users/goulijun/Documents/project/YANJI/work/navigation-lens-recovery/analyze.log)：No issues found。

[分阶段原生测试日志](/Users/goulijun/Documents/project/YANJI/work/navigation-lens-recovery/stages-final.log)、[全部诊断原图](../coolapk-navigation-2026-10-11/android-convex-final/)。第一次诊断失败是测试CustomPaint采用零高度造成扫描位置不符，已补足约束后重跑；几何及捕获原点检查没有用放宽阈值掩盖失败。

按住目标高度从60.1344dp变为72.200232dp；普通栏体高56dp。按原m32560的材质变换，272dp栏体按压时增至288dp宽、59.294dp高，仅作用于栏体材质，图标整排不随之放大。因此镜片/按压栏体高度比由约1.032提升至约1.218；捕获内容中心缩放1.2，独立于镜片几何与7/9.8dp边缘采样。

## 视觉近似和边界

已确认修复的是任意限高、端部人工外扩、捕获内容未放大、原始/捕获内容去重与交互命中、折射符号及无依据的默认压缩。前景捕获连续采样完整内容，而非整数槽位；镜片输出范围和32dp输入余量也有真实像素证据。

Flutter的阴影采用Gaussian半平面近似与MaskFilter，.5dp高光使用平滑羽化模拟原版blur.25dp，未证明与Android绘制器逐像素一致。背景继续采用已着色栏体+边缘页面的Flutter管线；原版还存在ContainerCapture不透明颜色记录及多种Renderer/SourcePolicy分支，未逐像素移植全部策略。颜色空间/vibrancy、字体及图标样式也仍不同。源参数是静态追踪，未取得酷安运行uniform；没有宣称完全复刻或新版本固定FPS。

本轮仅操作模拟器，手机没有覆盖安装。正常使用版build11和预览版build11分别保存在work/navigation-lens-recovery，正常版不注入演示数据。

## 拼图和录屏

- [同尺寸前后状态拼图](before-after.png)：左端按住、中间停住、跨槽位、右端按住、释放；两版来自同一1080×2400模拟器屏幕，同一裁剪，不改镜片像素。前版状态帧从连续录制中选取释放之前的稳定帧；后版每个停住状态同步捕获，避免错误标注释放后的帧。
- [按栏体高度归一化的目标对照](normalized-reference.png)：三列为修改前、修改后、酷安五项导航；统一栏高140px。酷安栏高手动定位为约94–99px，属于截图归一化估计，不能推导动态uniform。三个导航项与五个导航项的镜片长宽关系并不完全相同。
- [修改前连续录屏](before/recording.mp4)，约11.24秒，50次实际采集，约4.53次/秒。
- [修改后连续录屏](after/recording.mp4)，约42.36秒，40次实际采集，约0.95次/秒，最大采集间隔9.34秒。保存的是实际屏幕连续采集和原始单调时间戳，未经人工插帧或重排成动画；[逐帧时间/操作记录](after/recording.json)保留。

**录制局限**：模拟器原生screenrecord只取得4帧/3.68秒的异常短片，不能覆盖整段操作，已移到work/navigation-lens-recovery/first-after-capture，不作为完整录屏交付。后版屏幕采集开销很高，视频有明显采集间隔，足以检查状态变化但不足以判断正常动画流畅度；不能以此推断App FPS。停住状态另以同步截图人工检查，不把低采集帧率或稀疏帧冒充完整60FPS录屏。

真实main.dart release预览版build11已正常打开，三个导航业务入口继续工作，松手回到灰色平块，连续移动时邻近内容能切入绿色镜片并产生边缘变形。镜片内正常中心内容可读，原始黑色内容不与绿色副本叠绘。预览首次演示数据初始化超过一分钟等待，之后正常完成，未改业务初始化源代码；[启动核对](startup-check.json)未发现原生或Flutter错误。最后留在模拟器今日页。

[构建与源文件哈希](build-record.json)确认四项Android构建配置恢复、未留下临时SQLite钩子。正常版APK未安装手机；原有工作区业务修改保留。
