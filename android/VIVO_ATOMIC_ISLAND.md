# vivo 原子岛 / 原子通知接入审计

审计日期：2026-09-30

## 当前结论

YANJI 的实时状态来自现有学习会话：`active`、`paused`、`finished`，通过 Flutter `StudyLiveActivity` 通道同步到 iOS ActivityKit 和 Android。Android 目前由 `AndroidOngoingActivityManager` 分发到已存在的 OPPO Seedling/Fluid Cloud 适配器，未被厂商适配器处理时使用普通持续通知。该结构可作为后续 vivo 适配的扩展点。

当前 Dart 模型只允许一个本机活动会话，字段包括 session ID、subject、状态、elapsed/today 总秒数、target 和免打扰状态；没有 task ID、expected end time 或独立 `cancelled` 状态。iOS 使用 ActivityKit 状态更新；Android fallback 的固定通知 ID 是 `2401`，原生状态保存在 SharedPreferences，点击后经 pending action 进入 GoRouter `/timer`。Flutter `detached` 生命周期会调用 `finishStudyForProcessExit()` 并停止当前会话；因此单看 SharedPreferences 不能保证被杀进程后活动仍可恢复。此生命周期约定需要在任何恢复实现前确认。

OPPO 适配代码和官方 Seedling AAR 已存在，但当前 `android/local.properties` 未配置 OPPO 所需的六项集成值；现有接入说明也要求服务场景和 UPK 获批。因此从当前工作区状态看，OPPO 服务尚未启用，Android 会走普通通知 fallback。

本次未添加 vivo SDK、通知 extras、scene、模板、Manifest 项或原生资源。公开可访问的 vivo 开放平台文档目录未提供原子通知第三方接入指导；文档中心搜索“原子通知”未返回文档，页面显示登录入口。vivo 官方用户支持页面列出的公开原子通知场景包括航班、火车、会议、酒店、电影、快递、信息、互传、蓝牙和外卖等，没有学习计时/学习任务。该用户支持列表不是开发者 scene 清单，不能据此断言不存在私有接入，也不能把 YANJI 映射到会议等无关场景。

因此当前不能安全确认 YANJI 的 scene、模板、最低 API/OriginOS 版本、支持机型、官方能力检测方式、通知 extras、更新顺序字段、权限/白名单或本地创建协议。提示中出现的 `notification.superx.*` 字段没有在本次可访问的官方文档中得到确认，未写入代码。

## 已核对的官方资料

- [vivo 开放平台](https://developers.vivo.com/)：公开能力目录及文档中心入口。
- [vivo 原子通知用户支持说明](https://aikefu.vivo.com.cn/imgtextdata/ssr/imagetext/544681c2-a4d6-11ef-b4cc-0a907a12022c)：2026-04-01 更新，列出用户侧支持场景、系统开关和部分卡片展示位置。此页不是第三方开发 API 文档。
- [vivo X200 系列常见问题](https://www.vivo.com.cn/service/questions/all?categoryId=158&questionId=1744)：说明 OriginOS 5 的用户侧原子岛功能及其设置入口。该信息不能作为第三方 API 的最低版本要求。

## 需要 vivo 官方确认

请在 vivo 开放平台开发者助手提单（或联系 `developers@vivo.com`），确认并取得书面接入资料：

1. 学习/专注/计时是否有正式支持的 scene；若没有，是否接受新 scene 申请或自定义 scene，具体审核条件是什么。
2. 正式接入指南、SDK/API 或本地 `Notification` 协议、Demo、官方字段常量及版本记录规则。
3. YANJI 是否需要企业应用资质、包名和签名绑定、白名单、测试账号、场景/模板审核或上线审核。
4. scene 与模板支持的最低 Android 和 OriginOS 版本、vivo/iQOO 机型范围，以及官方 capability 检测接口。
5. 用户通知权限、原子岛开关、各展示位置的前置条件；失败时是否允许/建议普通通知兜底。
6. Create、Update、Pause/Resume、End 的生命周期、更新频率、完成态保留、重启恢复及稳定实例 ID 规则。
7. 是否支持客户端本地更新；如果必须远程推送，再确认官方 Push 原子通知契约和服务端接入要求。

拿到这些资料后，再复用 `OngoingActivityState`、`AndroidOngoingActivityManager` 和现有 Flutter `StudyLiveActivity` 通道增加独立 `VivoAtomicIslandAdapter`，并为正式 Mapper/Payload 增加 JVM 单测。现有业务只有单个活动会话，Android 普通通知使用固定 ID `2401`；该 ID 是普通通知 fallback 的 ID，不能据此推断 vivo 实例 ID 规则。

## 仍需真机验证

当前环境没有可用的 `adb` 命令，因此无法识别或验证 vivo/iQOO 真机。取得官方接入契约和真机后，仍需核验系统开关、通知授权、各展示触点、冷启动 Deep Link、暂停/恢复、完成/结束、进程重启和设备重启行为。
