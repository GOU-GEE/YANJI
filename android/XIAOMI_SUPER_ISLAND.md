# YANJI 小米超级岛 / 焦点通知接入记录

审计与实现基线：2026-09-30。官方开发指南和方案提报说明目前显示的最近更新时间为 2026-01-29。

## 当前架构与接入点

YANJI 的业务状态只有一套：Flutter StudyLiveActivity.sync 把当前学习会话同步到原生，Android 使用 OngoingActivityState(sessionId, subject, status, elapsedSeconds, todayTotalSeconds, targetSeconds, doNotDisturbEnabled)。状态为 active、paused 或终止态；一个设备只允许一个活动学习会话。

Android 分发顺序是 OPPO Seedling/流体云、Xiaomi HyperOS Adapter、现有 Android 通知 fallback。小米设备必须同时报告 Xiaomi/Redmi/Poco 家族候选、焦点协议版本、对应超级岛能力和焦点通知权限才会选择 Xiaomi Adapter。Poco 不因品牌本身被认定支持。

现有项目没有 vivo Adapter 实现。android/VIVO_ATOMIC_ISLAND.md 是先前审计说明，不代表 vivo 已接入。

## Xiaomi Adapter 行为

| YANJI 状态 | OS3 摘要态 | 展开态 / 焦点卡片 | OS2 状态栏 | 操作 |
| --- | --- | --- | --- | --- |
| active / 开始 | 学习中；小岛用系统应用图标，大岛突出短状态和科目 | 标题 学习中，正文为科目；Android 通知使用系统计时器 | ticker 学习中 | 使用当前稳定 notification ID |
| active / 状态同步 | 展示不变时不重复发通知；真正展示字段变化时更新同一 ID | 同上 | 同上 | notify(2401, updated) |
| paused | 已暂停 | 已暂停，正文为科目；计时器停止 | ticker 已暂停 | 原生通知操作可继续 |
| resumed | 学习中 | 计时器继续 | ticker 学习中 | 原生通知操作可暂停 |
| 完成、取消、用户结束 | 立即移除 | 立即移除 | 立即移除 | NotificationManager.cancel(2401) |
| Android / 焦点权限缺失、协议不支持或场景未配置 | 不发送 Xiaomi payload | 由当前 Android fallback 处理 | fallback | 不循环请求小米权限 |

摘要信息保持简短，未把进度条虚构成 12 小时计时进度。YANJI 当前没有学习目标时长，因此 targetSeconds == 0，不会生成百分比。OS2 使用 ticker；OS3 使用 param_island，islandProperty=1 表示信息展示为主。AOD 只显示 学习中 或 已暂停，使用系统默认应用图标。展开首次不自动弹出，普通更新不自动展开。

当前活动沿用固定 notification ID 2401，与现有单活动 Android fallback 相同；创建、暂停、恢复、同步和结束都不会随机换 ID。状态仍保存于现有 SharedPreferences，并在应用恢复时由当前 Flutter 学习会话重新同步。Android 13+ 通知授权与小米焦点通知授权分别检测。暂停/继续由不可变 PendingIntent 交给原生 BroadcastReceiver 处理，不依赖 Flutter isolate 已在运行。内容点击复用 yanji://live-activity/open，交由 Flutter GoRouter 跳到 /timer。

Android 原生持久化会话可在进程重建后读取；没有新增开机广播来强行拉起应用。若系统在重启时清除通知，下一次应用启动/恢复时由持久化的 Flutter 学习会话重新同步；这条设备重启路径仍需真机确认。

焦点通知使用独立稳定 channel study_timer_xiaomi_focus，Importance 为 DEFAULT，关闭声音和振动；普通 Android fallback 保持原有低打扰 channel。该应用仍只有一个生产通知 ID。仅调试操作使用 2403。

## OS 与协议

实现读取 Settings.System 的 notification_focus_protocol：

- 2：HyperOS 2 焦点通知；payload 加入 ticker，不带岛摘要数据。
- 3：HyperOS 3；payload 使用 param_v2 并增加摘要岛数据，要求系统 persist.sys.feature.island 能力为真。
- 其他版本：普通 Android fallback。

小米 canShowFocus ContentProvider 查询在单线程 executor 执行，结果缓存 60 秒；应用返回前台时清缓存并重新同步。Android 通知授权和 Xiaomi 焦点授权分别报告。

所有 Xiaomi 通知参数集中在 ongoing/xiaomi。唯一的 JSON 通知扩展 key 是 miui.focus.param。当前 JSON 使用 param_v2，protocol 字段暂未发送：当前官方指南示例写了 protocol: 1，但基础字段表没有说明其语义，未将样例数字当成已确认的长期协议。正式开通前应向小米确认该字段是否必需、含义和版本规则。

## 场景与业务审核判断

YANJI 可提交的候选场景是**用户主动开始、可暂停/继续并由用户结束的专注学习计时**。它有清楚的开始动作和持续中的状态，用户会反复查看当前学习状态，符合小米公开准入原则的候选方向。适配器将岛的显示生命周期限制在 12 小时；没有伪造 taxi、外卖或导航业务。

公开场景支持参考图没有列出学习/专注计时。小米说明支持参考场景可新增，因此仍需提交“专注学习计时”新场景预审，不能把代码中的候选文案视作获批 business。构建属性 xiaomi.focus.business 默认空；收到小米批准的正式值后才可设置。未配置时，Android 只发原有普通通知。

HyperOS 3 模板库的官方链接当前返回 403/大文件读取限制，未能在本执行环境完整下载其 PDF。代码按开发指南公开 JSON 示例与 2026-01-29 模板库可检索摘录构建基础图文摘要草案；其最终组件组合和 textInfo 字段必须以管理中心可下载模板 PDF 与小米联调结果为准。当前不能声称已通过小米模板验收。

## 申请材料草案

| 小米方案字段 | 当前可填内容 | 仍需提供 / 确认 |
| --- | --- | --- |
| 应用名称 | 研迹 / YANJI | 应用商店正式名称 |
| 包名 | 当前工程 com.example.yanji | 正式包名；当前值仍是示例包名 |
| App ID | 未配置 | 小米澎湃 OS 开发者平台创建应用后取得 |
| 业务场景 | 用户主动开始的专注学习计时 | 小米新场景预审与正式审核结果 |
| business | 未配置 | 小米批准后给出的准确字段值 |
| OS2/OS3 模板 | OS2 ticker + 基础信息；OS3 信息型摘要 | 依据模板 PDF 和审核反馈最终选定 |
| 通知 Channel ID | study_timer_xiaomi_focus | 小米确认审核表是否要求使用小米推送平台 channel；本接入不使用 MiPush |
| Channel 名称 | 学习计时 | 小米确认 |
| Channel 描述 | 显示用户主动开始的学习计时状态 | 小米确认 |
| 通知出现时机 | 用户在 YANJI 开始学习后 | 审核确认 |
| 更新节点 | 科目/状态变化、暂停、恢复；不按秒推送 | 审核确认 |
| 刷新频率 | 仅可见状态发生变化时调用；无周期性每秒通知 | 小米给出的频次要求 |
| 预计持续时长 | 由用户结束，Xiaomi 展示最多 12 小时 | 产品/审核确认是否需进一步限制业务会话时长 |
| 消失时机 | 用户结束/完成/取消立即 cancel；系统兜底最长 12 小时 | 小米审核确认 |
| 摘要态 | 学习中 / 已暂停；小岛系统图标 | 模板图和截图 |
| 展开态 | 状态 + 科目；通知提供暂停/继续/结束 | 系统模板最终图和交互图 |
| OS2 状态栏 | ticker 学习中 / 已暂停 | 实机截图 |
| AOD | 学习中 / 已暂停，系统应用图标 | 实机截图 |
| 公司主体、负责人、联系方式 | 未提供 | 申请人补充 |
| 测试设备版本截图 | 未提供 | HyperOS 2 与 3 测试机提供 |
| APK 与签名指纹 | 当前 Release 仍使用 debug signing 配置 | 正式包、Release 签名；开发/正式证书指纹 |

## 小米平台人工流程

1. 在小米澎湃 OS 开发者平台创建/确认应用，补齐正式包名、App ID、开发者主体和签名指纹。
2. 为“专注学习计时”提交场景预审；附场景说明、开始/暂停/恢复/结束全部节点、状态展示文案、时长与刷新策略。
3. 预审通过后补交完整方案：大岛、小岛、展开态、焦点通知卡片、OS2 状态栏、AOD 示意和展示时长。
4. OS2 焦点通知按官方流程向 mipush-permission@xiaomi.com 申请开发测试包/临时权限，邮件带应用名、包名、App ID、联系人、场景审核截图和测试机版本截图。此测试权限流程不代表本项目接入 MiPush。
5. 按小米后台要求配置 App ID 和 Debug 标识，安装测试包，在 OS2/OS3 真机联调。当前没有配置 App ID，不要把示例 com.example.yanji 提交为最终身份。
6. 充分自测后，从管理中心申请线上验证，提交正式签名 APK 和可复现步骤；复杂场景还需小米要求的测试账号/白名单条件。OS2 与 OS3 需合并在同一 APK 验证。
7. 通过上线验证并发布后，小米文档说明首次开通会灰度放量，约 7–15 天逐步到 100%。若新增场景，需要重新走方案审核与上线验证。

没有向小米发送邮件或提交审核。

## 本地验证限制

当前环境未找到 adb，没有 Xiaomi/Redmi HyperOS 2 或 3 真机，因此未验证系统实际显示、权限开关、锁屏/AOD、小米状态栏焦点通知、系统清除策略和冷启动点击。代码/构建测试通过也不等于小米已授权或设备一定展示。

本机验证结果：

- `flutter test`：通过。
- `flutter analyze`：全量检查被既有 `lib/features/target_goal.dart` 的 `use_build_context_synchronously` lint 阻断；本次修改的两个 Dart 文件单独分析通过。
- Xiaomi `XiaomiSuperIslandMapperTest`：通过；包括 OS2/OS3、运行/暂停/恢复/终态、business 必填、JSON、中文长度、时间与进度边界。
- Android `assembleDebug`：通过。
- Android 全量 `testDebugUnitTest`：17 项中有 2 项既有 HONOR Mapper 测试失败（MagicOS 版本门槛及完成/取消映射）；Xiaomi Mapper 测试单独通过。
- Android Release：Kotlin 编译通过；Java 编译被 Flutter 自动生成的 `GeneratedPluginRegistrant.java` 中 dev-only `integration_test` 插件引用阻断。Release APK 尚未生成。
- `flutter build ios --no-codesign`：通过。

Android 构建期间还报告了当前 Liquid Glass shader 无法转换为 SkSL 的警告；Debug APK 仍成功生成。这些 shader 和现存测试/lint 问题不由 Xiaomi Adapter 引入。

官方资料：

- [开发指南](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=2131)
- [业务介绍与准入原则](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=2140)
- [OS2 / OS3 版本差异](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=2141)
- [接入流程](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=2132)
- [方案提报说明](https://dev.mi.com/xiaomihyperos/documentation/detail?pId=2144)
