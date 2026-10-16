# 镜片内栏体缩小修正

后续用户要求取消图标文字放大，已在build14移除；镜片内栏体缩小保持。请参阅[最新修改记录](../navigation-no-glyph-zoom-2026-10-12/README.md)，以下为build13的历史结果。

本轮在上一版凸透镜基础上恢复用户要求的“透过镜片看导航栏适当缩小”。改动仅集中在导航材质实现及对应验证，没有改动三个业务入口、共享玻璃主题或其他业务文件。

## 分层关系

- 镜片几何继续使用1.3928572的按压目标，56dp底栏上对应约72.2dp高的镜片。
- 栏体背景经过独立采样映射：纵向取样增量12%，沿槽位方向8%；中心内容对应约1/1.12的栏体高度。映射随按压连续插值，上下围绕同一中心对称内凹，端点的栏体圆头也缩进镜片内。
- 图标文字的AccentCapture仍独立按压放大1.2，不使用上述缩小参数。普通可见内容保持原尺寸，仅在镜片外绘制，避免重影。
- 折射仍采用原来的负amount、7dp边缘带和色散，高光与阴影不变。松手时背景缩小量随press归零，回到平灰选中块。

生产路径的reduceBarThroughLens默认开启，仅传到_OpticalBackground；_OpticalContent不接收它。legacyCompression仅保留为旧压缩对照开关，默认关闭。新增两个缩小系数是根据参考图适配Flutter采样的视觉调整，未声称它们是酷安原版uniform。

## 验证与交付

Android16/API36模拟器，1080×2400，DPR2.625。高对比蓝底关闭装饰及前景，仅开启光学；固定同一72.2dp镜片、56dp栏体，分别开关背景缩小并扫描真实输出像素：

- 左、中、右三个位置的栏体高度比均为0.89041；上下边界各缩进3.04762dp，差值为0px。
- 左、右端圆头均缩进3.42857dp，镜片几何保持不变，边界真实出现在镜片内。
- 前景捕获墨迹放大比仍为1.19048；三个位置的完整镜片输出高度均189px=72dp（像素取整）。负折射的边缘标记仍向外移动0.95238dp。
- 网格场景中浅色、深色及liquid/blur/translucent三档的按住、跨槽、停住和释放回归通过；停住后尺寸稳定，释放press收敛至0。降级保持无Shader的简化材质，不声称有相同的折射采样效果。
- 7项导航交互测试通过，专项静态检查无问题。构建仍有原有共享玻璃包的SkSL后端编译警告；本轮导航Shader在实际Impeller OpenGLES路径运行通过，未改共享包。

[像素结果](metrics.json)、[高对比开关对照](background-probe.png)、[原生诊断原图](../coolapk-navigation-2026-10-11/android-bar-reduction/)、[原生测试日志](/Users/goulijun/Documents/project/YANJI/work/navigation-bar-reduction/native.log)、[交互测试](/Users/goulijun/Documents/project/YANJI/work/navigation-bar-reduction/widget.log)、[静态检查](/Users/goulijun/Documents/project/YANJI/work/navigation-bar-reduction/analyze.log)。

修改前后同尺寸截图与录屏保存在before/after子目录，操作顺序为左端按住→中间停住→跨槽位→右端按住→释放。录屏由真实模拟器屏幕采集和原始单调时间戳组成，不插帧；采集帧率不代表App渲染帧率。

- [同尺寸前后状态对比](before-after.png)，[按底栏高度归一化的酷安参考对照](normalized-reference.png)。镜片外观和前景大小保留，新增栏体缩小仅出现在镜片内。白色页面上的变化较细，另用[高对比背景](background-probe.png)与[网格按住截图](grid-held.png)确认真实边界。
- [修改前录屏](before/recording.mp4)：14.40秒，65次实际采集，4.58次/秒，最大间隔0.26秒。
- [修改后录屏](after/recording.mp4)：14.69秒，65次实际采集，4.49次/秒，最大间隔0.32秒。原始时间戳在相应recording.json中。此采集速度适合检查连续状态，不能作为高帧率流畅度证据。

实际main.dart预览版build13已安装并正常打开，录制后回到今日页；原生及Flutter异常扫描为空。构建前后pubspec一致，临时Android工具链配置和SQLite hook已恢复。[构建记录](build-record.json)保留APK与源文件哈希。没有制作或安装新的手机使用版APK，本轮按用户要求只留模拟器预览版。

只操作模拟器，没有安装到手机。仍是Flutter背景采样与曲面光学的视觉近似，不能称为酷安逐像素复刻。
