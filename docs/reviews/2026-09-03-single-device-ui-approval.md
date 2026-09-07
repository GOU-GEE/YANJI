# M2/M3 日常 Gate 验收通过 · 进入基础业务 UI

本轮 M2/M3 执行结果验收通过。

正式状态：

```text
M0      ✅
M1a     ✅
M1b     ✅
M1c     ✅
M2      ✅
M3 PR Gate ✅
M3 Extended / Soak ⏳ 后续独立执行
```

当前有限随机样本不是无限状态空间的形式化证明，因此文档中继续保留这一边界描述。

但现有证据已经满足进入单设备产品开发阶段的工程门槛，不继续阻塞 UI。

---

# 一、本轮验收结论

以下结果接受：

```text
92 项全量 Flutter 测试通过
flutter analyze 无问题
dart format 无变化
固定 CBOR / Ed25519 oracle 通过
```

M2：

```text
3 个独立文件 SQLite
Production Resolver
Production OperationWriter
真实签名 Operation
真实 Projection
```

固定场景测试通过。

M3：

```text
10 seeds
×
200 random actions
```

全部通过。

并覆盖了：

```text
乱序
重复
失败投递
设备重启
撤销
Future Schema
Bad Signature
13 种网络 scheduler event
Timer 状态机
```

Seed 重放两次得到：

```text
相同 Trace
相同签名字节
相同最终状态指纹
```

说明随机 Harness 具备确定性重放能力。

---

# 二、projectionDigest 当前修改批准

批准：

```text
projectionDigest
```

只覆盖确定性业务派生状态：

```text
业务 Projection
FieldClock
Tombstone
MV Register
Materialization
```

不要包含：

```text
Frontier
membership
received_at
peer metadata
本机日志
```

Frontier 和 membership：

继续使用独立断言验证。

这样职责更加清晰：

```text
Projection Digest
→ “业务最终状态是否一致”

Frontier Assertion
→ “合法 Operation 是否完整传播”

Membership Assertion
→ “授权派生状态是否一致”
```

不要重新把三者揉成一个 Hash。

---

# 三、M3 Extended / Soak 不阻塞当前 UI

目前：

```text
Extended
100 × 1000

Soak
100 × 2000
```

已经有入口但尚未执行。

这不阻塞下一阶段。

原因：

当前日常 Gate 已经证明：

```text
随机测试框架本身工作正常

固定 seed 可重放

三设备真实 SQLite 可以收敛

Incremental / Rebuild 可以保持一致
```

Extended / Soak 作为：

# 后续高强度稳定性 Gate

处理。

建议时间点：

```text
基础 UI 可用
↓
核心业务模型趋于稳定
↓
P2P 网络接入前
或
第一次 Alpha 发布前
↓
执行 Extended / Soak
```

如果随机测试运行时间增长明显：

允许独立 CI / 手动运行。

不要放进每次普通开发循环。

---

# 四、现在进入产品开发阶段

下一阶段目标：

# 单设备版本真正可用

即：

即使完全关闭：

```text
P2P
QR
LAN
```

用户仍然能够每天正常使用研迹。

从现在开始可以建立：

```text
features/
```

业务 UI。

---

# 五、第一批 UI 开发顺序

不要同时铺开全部页面。

正式顺序：

```text
1. App Shell / Navigation

2. Onboarding

3. Subjects

4. Today

5. Tasks

6. Study Timer

7. Daily Review

8. Basic Statistics
```

---

# 六、第一步：App Shell

先搭建真正手机端导航。

底部导航：

```text
今天

计划

+

数据

我的
```

其中中央：

```text
+
```

作为主操作按钮。

点击弹出：

```text
开始学习

添加任务

写复盘
```

“记录成绩”暂时可以等 ExamAttempt 上线后加入。

---

# 七、Navigation 原则

需要支持：

```text
Android Phone
iPhone
```

优先。

同时架构不能锁死：

```text
iPad
Windows
macOS
```

手机：

```text
Bottom Navigation
```

未来大屏：

```text
NavigationRail / Sidebar
```

业务页面不能依赖固定屏幕宽度。

---

# 八、Onboarding

第一次打开：

不要登录。

不要注册。

流程建议：

```text
欢迎使用研迹
↓
考试信息
↓
考试科目
↓
目标分
↓
完成
```

最少填写：

```text
考试名称
考试日期
目标学校（可跳过）
目标专业（可跳过）
考试科目
```

目标分：

允许跳过。

不要因为：

```text
目标院校暂未确定
```

阻止用户进入 App。

---

# 九、Onboarding 完成条件

完成后必须通过现有：

```text
OperationWriter
```

创建：

```text
Workspace
ExamProfile
Subjects
```

UI 不允许：

```text
直接 INSERT SQLite
```

仍然坚持：

```text
UI
↓
Command
↓
OperationWriter
↓
Resolver
↓
Projection
```

---

# 十、Subjects 页面

第一版功能：

```text
查看科目

新增科目

修改名称

设置目标分

排序

归档
```

默认可以提供快捷模板：

```text
政治
英语一
英语二
数学一
数学二
数学三
408
专业课
```

但：

用户可以自由创建自定义科目。

---

# 十一、不要把科目模板写死到数据库 Schema

默认模板属于：

```text
Product / UI preset
```

不是：

```text
数据库枚举限制
```

即：

Subject.name 应继续允许任意文本。

未来用户可能创建：

```text
数据结构
专业课二
日语
396经济类联考
自定义科目
```

---

# 十二、Today 首页

首页第一版只显示最有价值的信息。

建议：

```text
距离考试还有 XXX 天

今天学习
0h 00m / 今日目标

今日任务
0 / N

科目时间

今日任务列表

开始学习
```

不要现在加入：

```text
复杂图表
AI建议
成就动画
大量卡片
```

---

# 十三、首页主按钮

最重要：

# 开始学习

必须明显。

典型流程：

```text
打开研迹
↓
开始学习
↓
选择 Subject
↓
可选 Task
↓
开始
```

目标：

用户 2～3 次操作即可进入计时。

---

# 十四、Task V0.1

支持：

```text
title

subject

scheduled_date

estimated_seconds

priority

status

note
```

第一版可以先不暴露：

```text
复杂阶段计划
KnowledgeNode
```

UI。

数据库后续可以扩展。

---

# 十五、Task 状态

UI 主要使用：

```text
Todo
Completed
Cancelled
```

`Doing`：

可以由：

```text
当前 Active StudySession
```

表现。

不要让用户为了开始学习还要手动：

```text
Todo → Doing
```

增加操作。

---

# 十六、Task 与 StudySession 关联

用户从任务点击：

```text
开始学习
```

则创建 Session：

```text
subject_id
task_id
owner_device_id
```

结束学习后：

Task 不自动强制完成。

弹出：

```text
本次学习完成

1h 32m

是否完成任务？

[暂不]
[完成]
```

让用户自己决定。

---

# 十七、Timer 是第一批 UI 中最高优先级

Timer 页面必须极简。

例如：

```text
数学一

高等数学 · 极限

01:32:41

[暂停]

[结束学习]
```

不要在计时页面放：

```text
复杂统计
排行榜
大量设置
```

计时时：

用户主要任务是：

> 学习。

---

# 十八、Timer 必须继续遵守已有 Domain 规则

UI 不能自己：

```text
每秒写数据库
```

时间显示：

使用本地 UI ticker。

真实时间事实：

来自：

```text
SessionSegment.started_at
SessionSegment.ended_at
```

---

# 十九、锁屏 / App 生命周期

现在开始 UI 后：

必须尽早验证：

```text
App background
App foreground
手机锁屏
系统暂停 Flutter UI
```

Timer 显示仍然正确。

不能依赖：

```text
Timer.periodic
```

累计真实 duration。

`Timer.periodic` 只允许负责：

> 刷新屏幕显示。

---

# 二十、Daily Review

第一版：

```text
日期

复盘正文
```

即可。

不要一开始强制三个文本框。

可以在 UI 给 Prompt：

```text
今天完成了什么？

遇到了什么问题？

明天准备怎么调整？
```

但底层：

仍然可以先保存一个：

```text
content
```

---

# 二十一、Daily Review 删除行为

继续遵守产品语义：

```text
删除复盘
=
content = ""
```

不能生成 Tombstone。

---

# 二十二、Statistics 第一版

先只做：

```text
今日总学习时间

本周每天学习时间

各科学习时间

累计学习时间

连续学习天数
```

以及：

# 学习热力图

如果热力图实现会明显拖慢第一阶段：

允许放到 Statistics 第二小步。

---

# 二十三、Statistics 数据来源

统计必须来自：

```text
StudySession
+
StudySessionSegment
```

不要另建：

```text
daily_total_hours
```

作为真值。

可以未来做 Cache。

第一版先从事实数据聚合。

---

# 二十四、Workspace Timezone

所有：

```text
今天
本周
连续学习
热力图
```

按照：

```text
Workspace.stats_timezone
```

计算。

不要使用当前设备：

```text
DateTime.now().timeZone
```

直接决定历史统计日界线。

---

# 二十五、State Management

现有 Riverpod 可以继续。

要求：

```text
UI Provider
↓
Application Service / Repository
```

不要让 Widget：

```text
直接操作 Drift DAO
```

---

# 二十六、页面状态必须覆盖

至少设计：

```text
loading

empty

data

error
```

例如 Tasks：

空状态：

```text
今天还没有任务

[添加第一个任务]
```

不要留下：

```text
空白页面
```

---

# 二十七、UI 测试开始加入

现有 92 项底层测试继续保留。

业务 UI 开始后增加：

```text
Widget Test
```

重点测试：

```text
Onboarding 能完成

创建 Subject 后显示

创建 Task 后 Today 显示

完成 Task 后状态更新

开始 Session 后 Timer 显示 Active

Pause / Resume UI 正确

Stop 后 Session 完成

DailyReview 保存后重开仍存在
```

不要过度截图测试每一个视觉细节。

重点测试业务行为。

---

# 二十八、不要破坏底层测试速度边界

现在全量测试约：

```text
4分钟
```

随着 UI 测试增加：

建议逐渐拆成：

```text
fast unit
database
convergence
widget
```

方便日常开发选择运行。

例如：

普通页面开发：

不必每次都重新执行 10 × 200 random convergence。

但：

提交关键数据层改动时必须执行。

---

# 二十九、Extended / Soak 的触发条件

以下修改发生时：

建议重新跑至少 Extended：

```text
Resolver
OperationWriter
Causal Context
FieldClock
Tombstone
MV Register
Authorization
Session State Machine
Rebuild
```

纯 UI：

```text
字体
布局
页面组件
```

无需重复跑大型 Soak。

---

# 三十、暂时不要开始 LAN Transport

明确继续推迟：

```text
mDNS
Bonjour
TLS Socket
QR
Camera
LAN Transport
```

直到：

# 单设备核心日循环可用。

即真正完成：

```text
Onboarding
↓
Today
↓
Task
↓
Start Study
↓
Pause / Resume
↓
Stop
↓
Daily Review
↓
Statistics
```

---

# 三十一、平台工具链现在可以开始补

UI 阶段同时完成开发机配置：

```text
Xcode
Android SDK
Android Emulator
iOS Simulator
```

执行：

```text
flutter doctor
```

确保：

```text
Android
iOS
macOS
```

开发能力通过。

Windows：

如果当前主开发机是 macOS：

暂时无法在 macOS 本地完整构建 Windows Runner。

不因此阻塞手机开发。

后续在：

```text
Windows 实机 / CI
```

验证。

---

# 三十二、UI 第一目标设备

优先：

# iPhone Simulator

第二：

# Android Emulator

然后：

```text
Android 真机
iPhone 真机
iPad Simulator
macOS
```

不要第一阶段同时追求所有平台视觉完全一致。

---

# 三十三、第一版视觉原则

继续保持：

```text
Mobile First
简单
安静
克制
长期使用
```

避免：

```text
过度渐变
过度卡片
复杂动画
信息轰炸
```

首先把信息层级和操作效率做好。

---

# 三十四、下一阶段完成 Gate

基础业务 UI 阶段完成时：

必须能在手机模拟器走完整流程：

```text
首次打开

↓

创建考研目标

↓

创建科目

↓

创建今日任务

↓

开始学习

↓

锁屏/后台模拟

↓

暂停

↓

继续

↓

结束学习

↓

查看今天学习时长

↓

完成任务

↓

填写每日复盘

↓

查看基础统计

↓

关闭 App

↓

重新启动

↓

数据全部正确存在
```

做到这里：

才能判定：

# YanJi Single-Device Alpha Ready

---

# 三十五、之后的路线

顺序保持：

```text
M2/M3 PR Gate
✅

↓

Single-Device UI
← 当前

↓

Simulator / 真机验证

↓

Extended / Soak

↓

LAN Transport

↓

QR Pairing

↓

Multi-device Real Network

↓

Alpha
```

不要跳过单设备产品验证直接进入网络开发。

---

# 最终原则

同步系统当前已经证明了较强的确定性基础。

从现在开始：

> 不要为了展示底层技术而设计产品。

UI 只需要让用户觉得：

```text
记录任务很简单
开始学习很简单
停止学习很可靠
今天学了什么一目了然
每天复盘很自然
```

先把这个循环做好。

这是下一阶段唯一优先目标。