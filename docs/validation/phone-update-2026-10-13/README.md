# 真机更新与启动闪退复测 — 2026-10-13

已通过无线调试将RMX3820（Android16）的研迹从build3覆盖更新为build15，版本名0.1.0。安装包是YANJI_PREVIEW=false的正常使用版，包含最近的导航栏修正：取消图标文字按压放大，保留镜片鼓起、栏体内凹与折射。

使用adb install -r覆盖安装，未卸载、清空数据或改变运行时权限。签名SHA256与原包一致；App UID10435、ceDataInode4387446和首次安装时间均保持不变。实际界面继续读取已有任务、累计学习记录和设备列表，没有进入首次设置流程。

## 旧故障确认

本次在更新前真机启动build3，复现SIGABRT。20:54:33的崩溃记录明确显示Abort message: failed to find method Seq.getRef，堆栈位于Java_go_Seq_init、go.Seq.<clinit>和engine.Engine.<clinit>。这与此前确认的同步组件consumer ProGuard规则丢失、R8裁剪JNI按名称查找的方法一致。

此前已在[插件构建配置](/Users/goulijun/Documents/project/YANJI/packages/yanji_syncthing/android/build.gradle)导出[原AAR的保留规则](/Users/goulijun/Documents/project/YANJI/packages/yanji_syncthing/android/consumer-rules.pro)。本轮正式构建mapping仍保留go.Seq、getRef(int)和engine.Engine的原名。之前修正版仅留在模拟器/本地，本次才覆盖手机上的旧build3。

[旧版崩溃摘录](/Users/goulijun/Documents/project/YANJI/work/phone-update-2026-10-13/old-crash-extract.log)、[正式构建保留方法](/Users/goulijun/Documents/project/YANJI/work/phone-update-2026-10-13/kept-native-methods.txt)。

## 更新后复测

- 三次冷启动通过。首次进程23342持续完成页面检查；另两次进程25953、26278分别在启动10秒后存活并绘制真实页面。
- 今日、数据、我的三个入口正常切换，检查期间进程保持23342，已有业务数据可读取。
- 后台停留后返回前台，进程仍为26278，没有异常退出或重建。
- 更新开始时间之后的应用日志及Android crash缓冲区，没有新的SIGABRT、Seq.getRef缺失、Java致命异常或未处理Dart异常。最后App保持打开。

结论：此前已复现的Seq.getRef启动闪退在本轮真机复测中不再出现。覆盖范围为启动、三个主页面和前后台恢复；不据此保证所有业务和长期运行场景都不存在其他崩溃。日志有Flutter帧时间回退的clamping信息，属于引擎处理过的非致命记录，没有将其算作闪退，也没有声称日志完全无错误级输出。

[复测指标](verification.json)、[路由检查](route-check.json)、[冷启动与恢复](runtime-check.json)、[构建记录](build-record.json)。本次无需再改业务实现，保留工作区已有用户修改；临时Android工具链及SQLite hook配置均已还原。

## 交付

[正常使用版APK](/Users/goulijun/Documents/project/YANJI/work/phone-update-2026-10-13/yanji-normal-build15.apk)已安装手机。此前build3 APK仅作为本地故障对照留存，未回退安装。

实机截图：[今日](today.png)、[数据](statistics.png)、[我的](profile.png)、[第三次冷启动](cold-start-3.png)。截图包含本机既有业务内容，仅留在本地验证目录。
