# Changelog

## Unreleased · Data 页面 · 2026-09-04

- 七日趋势替换 Progress Bar 列表：保留真实点、轻微平滑与面积、触摸精确时长、本周累计与上周整周比较；未来日期留空。
- 单张科目 Donut 支持本周/累计切换，中心总时长，列表实际时长与占比，圆环/列表触摸提示。
- 新增学习天数、最长连续学习与自然日日均，预留热力图；只从 Session / Segment 构建临时只读统计，不新增表或统计写入。
- 新增 5 项聚合测试、3 项图表 Widget 测试和 1 项原生视觉集成测试。口径、截图和验收范围见 docs/validation/data-page-2026-09-04.md。

## Unreleased · Design System v1 · 2026-09-03

- 根据用户设计 brief 研究 Linear / Notion / Cal.com 参考，建立根目录 DESIGN.md 为唯一 UI/UX 规范；原文完整归档，保留产品与架构优先级。
- 新增 YanJi Semantic Tokens 和系统明暗主题。第一批只迁移 Onboarding、Today、Task、Timer 与必要共享组件；其他业务页面仅继承主题。
- 表单和弹层支持键盘避让，任务/摘要支持小屏大字重排；Timer 操作位于底部且可滚动；修正快捷动作读屏标签、宽屏 Rail 语义隔离和 sheet 覆盖范围。
- 新增 5 项设计验证，覆盖对比度和四种窗口/文字/主题场景；与原 Widget 日循环合计 8 项。结果与原生截图见 docs/validation/design-system-v1-2026-09-03.md。

## Unreleased · Single-Device UI · 2026-09-03

- 新增手机导航及宽屏 Rail，按批准顺序完成首次目标/科目设置、科目管理、Today/Tasks、Segment 计时、每日复盘和基础统计。
- Riverpod 接入真实文件数据库、系统安全存储身份与 Application Service；业务修改全部经过生产 Writer，Onboarding 多实体创建整体回滚。既有工作区与当前身份不匹配时禁止自动重新授权。
- 统计使用 Workspace IANA 时区日界线并拆分跨午夜区间；ticker 只刷新显示，暂停不累计，清空复盘写正文更新。
- 新增 Widget 日循环及错误状态、应用服务文件重开/跨午夜/DST/事务回滚/身份隔离验证。全量 98 项测试通过，保留原 92 项；固定 CBOR/Ed25519 oracle 通过。原生日循环、后台/锁屏和进程重启单独验收。
- 增加 fast/database/widget/convergence/all 分层入口与 Android 宿主生命周期脚本。补齐 Android SDK/模拟器、Xcode、CocoaPods；具体原生构建和验证边界见 docs/validation/single-device-ui-2026-09-03.md。
- iPhone 17 Pro / iOS 26.5 与 Android API 36 原生日循环、独立进程重启全部通过；iPhone 普通应用补充实际锁屏/唤醒与 Active Session 跨模拟器重启恢复。普通 iOS/Android Debug 构建通过，flutter doctor 全部通过；macOS Keychain 构建仍缺开发签名证书。
- 达到 Single-Device Alpha Ready（模拟器日循环验收范围）。当前未开始 LAN/QR、热力图、复杂计划或 Extended/Soak；该状态不等于真机验收、正式 Alpha 发布或完整 V0.1 发布。

## M2/M3 Convergence Verification 历史 · 2026-09-03

- 新增三个独立文件数据库 DeviceHarness，使用生产连接、签名、Writer/Applier、Resolver、Projection；重启实际关闭并重建数据库和身份对象。
- 新增六条字节队列及 Frontier Diff/Gossip，覆盖重复、乱序、延迟、失败投递、分区和恢复；独立持久化的测试 membership policy 经签名消息传播后触发真实授权重验。
- 新增 19 项 M2 固定场景、10 个 seed × 200 actions 的 M3 日常场景，以及同 seed 完整 trace/签名字节/状态重放测试。逐表、字段、有效授权状态、Frontier、invariant 和三设备 rebuild 均验证一致。
- 修复固定场景发现的 digest 问题：Frontier 和 membership 改为独立比较，使未知 schema 仅推进存储进度而不改变业务 digest。新增可选确定性 ID 注入，应用默认 UUIDv7 行为保持不变。
- 新增失败 trace、regression seed corpus、PR/Extended/Soak 运行入口和性能记录工具。当前随机 seed 无失败；digest 问题由固定场景永久回归覆盖。
- 验证：全量 92 项测试通过（约 4 分钟）；flutter analyze、格式检查、固定 CBOR/Ed25519 向量独立 oracle 均通过。随机样本实际覆盖 53 次重启、14 次撤销、28 条 future schema 和 32 次坏签名注入。
- 已执行范围为 PR 样本及重放验证；Extended/Soak 配置未执行。完整 Genesis/QR、系统安全存储、真实平台构建和 LAN 网络不在本轮实现。详细记录见 docs/m2-m3.md、docs/validation/m2-m3-2026-09-03.md。

## M1c Production Projection 历史 · 2026-09-03

- 保留 M0/M1a/M1b，新增七类真实 SQLite 业务实体，以及 FieldClock、Tombstone、正文活动版本、物化状态、Frontier 和 TrustedDevice 决策视图；更新未发布 schema v1 与快照。
- 实现 OperationWriter / OperationApplier，日志、签名、序号、HLC、Context 与生产 Projection 在同一事务提交，本地和远端共用 Resolver。
- 实现 scalar 因果优先和并发确定性 winner、显式字段 patch、持久化 MV Register、永久删除、缺创建/缺依赖挂起及自动重试。
- 实现固定 Owner 的 Session 原子 start/pause/resume/stop，时长由 Segment 派生；本地无效命令整体回滚。
- refreshAuthorization 接入真实业务状态重算；提供 rebuildEntity、rebuildWorkspace 和确定性 projectionDigest。
- 验证：flutter analyze 无问题；62 项测试全部通过，其中新增 19 项真实 SQLite 生产路径测试；格式检查通过；M1b 固定签名向量保持不变且独立 oracle 复核通过。
- 取舍：rebuildEntity 当前重算整个 Workspace。TrustedDevice 物化已验证 OriginLookup 决策；完整 Genesis 授权链和平台安全存储仍待后续实现。下一阶段为 M2/M3 三设备文件数据库随机收敛测试。

## SYNC v1.1 / M1b 历史 · 2026-09-03

- 将批准决策落实到 SYNC、ARCHITECTURE、DATABASE，并更新 PRODUCT/ROADMAP 的产品语义和版本范围；历史评审移至 docs/reviews。
- 保留 M0/M1a 工程，按批准修订未发布 schema v1，改为 Workspace 内 origin_seq、FULL、ClockState、observed origins、apply_state 和 quarantine；更新 schema 快照。
- 实现确定性 CBOR、不可变 Envelope/原始 signed bytes、Ed25519 身份/签名/验签、SecureKeyStorage 抽象和恢复时新建身份。
- 新增日志/时钟/context 事务内核、重复幂等、未知 schema 保留与转发、授权重验及 cutoff 日志失效。
- 新增长文本因果 Multi-Value Register；使用测试参考模型验证乱序创建、晚到依赖、冲突解决及撤销后的重物化。
- 固定公开测试 seed、公钥、envelope、CBOR hex、签名；Python cbor2/cryptography 独立 oracle 复核，不在测试时重新生成期待值。
- 验证：flutter analyze 无问题；43 项测试通过；格式检查通过；固定向量独立复核通过。
- 边界：生产业务 Projection/FieldClock/Tombstone/完整 OperationWriter、Genesis 授权链、OS secure storage 真机适配、备份归档恢复和网络尚未实现。跨平台向量当前只在 macOS 执行，其他平台后续使用同一向量验证。

## M0/M1a 初始化历史 · 2026-09-03

- 阅读交接说明与四份原始规范，记录架构问题、待定决策和初始化任务。
- 初始化本地 Git 与 Flutter 3.47.2 多平台工程；iPadOS 使用 iOS runner。
- 添加 GoRouter、Riverpod、Material 3 启动壳和分类日志。
- 添加 UUIDv7、日历日期确定性 ID、可测试的纯 HLC 状态转换。
- 添加 Drift/SQLite 后台连接、v1 schema、Oplog 不可变约束和数据库测试。
- 添加文档、迁移快照配置与静态检查配置。
- 验证：静态检查通过；16 项基础测试通过，包括文件数据库重开和事务失败回滚。平台构建未验证（本机缺少完整 Xcode 与 Android SDK）。
- 尚未实现签名、系统安全身份、OperationWriter、完整业务模型或同步引擎。

### 2026-09-04 数据页展示精简

- 去除四个主导航页面的重复页头标签。
- 趋势提示改为图内节点浮层；科目切换右对齐，圆环使用环外名称/时长引导线标注。
- 实现自适应年度学习热力图、历史年份切换和日期触摸详情。
- 保持 Session / Segment 统计来源与日均口径不变。

### 2026-09-04 连续学习热力图

- 趋势提示移到标题旁并增加纵轴；圆环移除点击效果；积累指标分散对齐。
- 热力图从首次学习日起连续排列，数据页最多两行，“查看更多”进入全屏历史列表，末行补浅色占位。
- 时长图例改为 0–<1h、≥1h、≥2h、≥4h、≥6h，移除底部时区文字。


- 添加任务改为居中弹窗，增加本地科目/时长识别与手动覆盖，去掉优先级和备注控件。
- 我的科目支持一级/二级展开管理，数据库 v2 无损添加父科目引用。
- 关联任务累计真实学习片段，达到预计时长自动完成，支持重启补判。


- 任务支持当日/每日模式及空名称自动生成，每日按当地自然日重新计算进度。
- 开始学习新增取消按钮；科目移除目标分编辑，增加可恢复删除与折叠回收区、彻底删除确认。
- 删除科目从统计排除、恢复重新计入；数据库无损升级至 v3。

- 我的页面移除考试目标与每日复盘入口；模拟器调试默认关闭连接 Mac 硬件键盘，便于使用中文软件键盘。
