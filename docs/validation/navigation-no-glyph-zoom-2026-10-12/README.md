# 取消滑块内图标文字放大

按用户最新要求，取消此前独立AccentCapture的1→1.2按压缩放。移除捕获树的Transform.scale与对应样式参数，图标保持24dp，文字保持10sp；滑块经过相邻槽位时也不施加整体内容放大。主题的强调色和字重保留。

镜片几何鼓起、滑块内栏体背景缩小、负amount边缘折射及高光阴影都未改。边缘仍有局部光学形变，它和已移除的整体放大是两种不同效果。文字样式的height:1.2是行高，普通层和捕获层都原本使用它，不是内容缩放。

7项导航交互测试通过，包括按住与拖动时三个捕获内容的变换后屏幕尺寸保持不变。专项静态检查无问题。预览版build14已安装在Android16/API36模拟器，实际页面完成左端按住→中间停住→跨槽→右端按住→释放，并回到今日页；异常日志扫描为空，手机没有操作。

[同尺寸修改前后对照](before-after.png)来自同一1080×2400模拟器，修改前为build13、修改后为build14。按住左端时图标的绿色像素范围由56×62px变为46×52px；当前版本静止与按住时的中心图标墨迹均为46×52px。检测的颜色阈值和区域保存在[截图指标](screenshot-metrics.json)。这是截图墨迹尺寸，不是图标布局尺寸，不能当成精确的Shader全区域放大系数。

栏体背景和所有光学Shader的哈希与build13相同，确认保留背景缩小与边缘光学路径。[构建记录](build-record.json)保留源文件和APK哈希，临时构建配置恢复。

[本轮屏幕录制](after/recording.mp4)保存22次真实采集、约46.63秒和原始单调时间戳；采集速度约0.49次/秒、最大间隔3.52秒，适合核对停住状态，不足以判断动画流畅度。没有插帧或宣称该采集速度代表App FPS。

[交互测试日志](/Users/goulijun/Documents/project/YANJI/work/navigation-no-glyph-zoom/widget.log)、[静态检查](/Users/goulijun/Documents/project/YANJI/work/navigation-no-glyph-zoom/analyze.log)。上一轮背景缩小的原生像素结果属于build13，本轮不将其内容1.19倍放大结果当作新版本验收。
