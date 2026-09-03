# 研迹 YanJi — 产品与开发路线图

文档职责：版本范围、开发顺序和 Milestone 的唯一事实来源。

## v1.1 冻结的版本范围

- V0.1：基础计划（长期任务、周安排、每日任务），计时/记录/复盘/统计/备份/LAN 同步。
- V0.2：阶段、月计划、完整长期规划、知识树、真题等考研专业化。
- V0.3：复盘增强。
- V0.4：AI；旧交接说明中的 AI V0.3 已失效，不提前开发。

## M1 子阶段与门槛

M0/M1a 已有工程、纯 HLC、ID、数据库底座保留。
M1b：Workspace 内 seq、持久化 HLC/observe、causal context、deterministic CBOR envelope、Ed25519 身份/签名/验签、secure key storage 抽象与固定 golden vectors。
M1c 前验证：双 Workspace 交错序号、事务回滚、重启、远端 HLC、固定字节与往返、逐字节篡改拒绝、未知 schema 保留、乱序 create/dependency 重试、并发复盘与因果解决、超 cutoff 撤回、新安装恢复新身份。
乱序/冲突/cutoff 可先在参考模型验证语义；只有门槛通过后才进入完整持久化 Projection、FieldClock、Tombstone、OperationWriter。M3 仍必须用三份真实 SQLite 证明完整系统收敛，参考模型不能替代。

平台工具链缺失不阻塞纯 Dart/SQLite；secure storage 真机、runner、Timer 生命周期、mDNS、相机前须补齐并通过 flutter doctor。

## 总体原则

研迹采用：

> 先底层可靠，再业务可用，最后做高级功能。

不能一开始同时开发：

```
UI

统计

P2P

AI

真题

知识树
```

必须分阶段。

# Milestone 0 — 项目初始化

目标：

> 建立一个长期可维护的 Flutter 工程。

完成：

```
Flutter 项目

Android

iOS

iPadOS

Windows

macOS
```

配置：

```
Git

README

代码规范

静态检查

测试框架

日志系统
```

建立文档：

```
PRODUCT.md

ARCHITECTURE.md

SYNC.md

DATABASE.md

ROADMAP.md

CHANGELOG.md
```

# Milestone 1 — 本地数据核心

这是整个项目最重要的阶段。

先完全不碰网络。

实现：

```
Drift

SQLite

Migration

Repository
```

数据库基础设施。

## ID

实现：

```
UUIDv7
```

## Clock

实现：

```
Hybrid Logical Clock
```

必须有单元测试。

## Device Identity

实现：

```
Device ID

Ed25519 Key Pair

Secure Storage
```

## Operation

实现：

```
Operation Model

Operation Serializer

Operation Signature

Operation Verify
```

## OperationWriter

所有业务修改统一经过：

```
OperationWriter
```

确保：

```
Projection
+
Oplog
+
FieldClock
```

同事务提交。

# Milestone 2 — 同步数据模型

实现：

```
Oplog

Field Clock

Tombstone

Origin Progress

Frontier

Trusted Devices
```

实现：

# Conflict Resolver

支持：

```
Create

Update

Delete

Field-Level LWW
```

# Milestone 3 — 本地多设备模拟测试

这是同步系统最重要的阶段。

暂时：

# 不写任何 P2P 网络代码。

创建：

```
Device A Database

Device B Database

Device C Database
```

分别产生 Operation。

测试：

```
乱序

重复

延迟

丢包模拟

不同传播路径

离线修改

删除冲突
```

必须证明：

```
Replay相同Operations
↓
不同顺序
↓
所有数据库最终Projection一致
```

通过以后才能继续。

# Milestone 4 — V0.1 基础业务

开始做用户真正能用的产品。

## Onboarding

第一次启动：

```
考试年份

考试日期

目标学校

目标专业

考试科目

目标分
```

## Subjects

实现：

```
新增科目

修改

排序

归档

目标分
```

## Today

实现首页：

```
考研倒计时

今日学习时间

今日任务

各科学习时间

开始学习
```

## V0.1 基础计划

长期任务、周安排、每日任务之间的基础组织关系在 V0.1 完成；复杂阶段、月计划与完整规划视图属于 V0.2。

# Milestone 5 — Task

实现：

```
创建

编辑

删除

完成

取消

科目关联

预计时间

计划日期

优先级
```

实现：

```
TaskTemplate
```

用于重复任务。

# Milestone 6 — Study Timer

实现整个产品最高频功能。

支持：

```
普通计时

暂停

继续

结束
```

V1 只有 owner 能控制 Session；pause/resume 用 Segment 模型，时长由 Segment 求和。

计时基于：

```
started_at
```

而不是依赖：

```
每秒 +1
```

确保：

```
锁屏

App暂停

系统挂起
```

以后计时仍然正确。

StudySession：

关联：

```
Subject

Task

KnowledgeNode
```

# Milestone 7 — Pomodoro

增加：

```
25 + 5

50 + 10

自定义
```

以及：

```
本地通知
```

# Milestone 8 — Daily Review

实现：

```
每日复盘

历史复盘

按日期查看
```

同步支持：

```
因果 Multi-Value Register
```

# Milestone 9 — Statistics V0.1

实现：

## 今日

```
学习总时间

科目分布

Session Timeline
```

## 本周

```
每日时间

科目时间

任务完成率
```

## 全部

```
累计时间

学习天数

最长连续学习

学习热力图
```

# Milestone 10 — 本地可用版本

此时必须达到：

> 即使完全没有同步功能，研迹也已经是一款可以每天使用的考研学习记录 App。

需要重点测试：

```
Android

iPhone
```

核心体验。

# Milestone 11 — YSP 网络层

开始实现：

# YanJi Sync Protocol

首先完成：

```
Peer Transport

TLS

Hello

Frontier Exchange

Operation Batch

ACK
```

# Milestone 12 — mDNS Discovery

实现：

```
_yanji-sync._tcp
```

自动发现附近：

```
Trusted Device
```

先从：

```
Desktop ↔ Desktop
```

或：

```
Android ↔ Desktop
```

调试。

再覆盖 iOS。

# Milestone 13 — Peer Authentication

实现：

```
TLS Fingerprint

Ed25519 Challenge

Trusted Devices
```

陌生设备：

```
不能同步
```

# Milestone 14 — 增量同步

实现：

```
Exchange Frontier

Calculate Missing Ops

Send Batch

Verify Signature

Apply

ACK
```

支持：

```
A ↔ B
```

继续测试：

```
A ↔ B ↔ C
```

Gossip Sync。

# Milestone 15 — QR Pairing

实现：

# YPP/1

流程：

```
添加设备

↓

生成 Pair Secret

↓

生成二维码

↓

新设备扫描

↓

TLS Pinning

↓

用户确认

↓

建立 Trust

↓

全量同步
```

实现：

```
Pair Secret

一次性

2分钟过期
```

# Milestone 16 — Device Management

设置页加入：

```
我的设备
```

显示：

```
当前设备

已配对设备

最后同步时间

在线状态
```

支持：

```
移除设备
```

生成：

```
device.revoke
```

# Milestone 17 — V0.1 正式版

V0.1 必须具备：

```
Onboarding

Today

Subjects

Tasks

Basic Plans

Study Timer

Pomodoro

Daily Review

Statistics

Heatmap

Local Backup

QR Pairing

LAN P2P Sync

Multi Device
```

平台：

```
Android

iOS

iPadOS

Windows

macOS
```

其中：

```
Android
iPhone
```

体验优先。

# V0.2 — 考研专业化

V0.2 开始重点拉开和普通效率软件的差距。

## Study Phase

增加：

```
基础

强化

真题

冲刺
```

## Knowledge Tree

支持：

```
Subject

Chapter

Knowledge Point
```

例如：

```
数学一
└ 高等数学
   ├ 极限
   ├ 导数
   └ 积分
```

## 学习进度

显示：

```
第一轮

第二轮

第三轮

完成比例
```

## 长期计划

增加：

```
月计划

周计划

阶段计划
```

## ExamAttempt

增加：

```
真题

模考

练习卷
```

记录：

```
分数

正确率

用时

错题数量
```

## 成绩趋势

例如：

```
93
101
108
112
119
```

生成趋势图。

# V0.3 — 复盘增强

增加：

```
周复盘

月复盘

学习趋势

计划完成率

预计 VS 实际
```

增加：

```
科目投入偏差
```

例如：

```
数学目标占比
30%

实际
22%
```

# V0.4 — AI

AI 开始接入。

但定位仍然是：

# 学习数据分析助手

不是聊天机器人。

实现：

## AI 日报

根据：

```
Task

StudySession

DailyReview
```

自动总结。

## AI 周报

分析：

```
时间趋势

任务完成率

科目投入

学习效率
```

## AI 计划建议

例如：

```
数学本周投入不足

建议下周增加3小时
```

## AI 计划拆分

用户输入：

```
8月底前完成408第一轮
```

系统辅助拆成：

```
阶段
周
日
```

# V0.5 — Backup 增强

增加：

```
加密 .yanji 备份

完整恢复

数据校验

重建 Projection
```

高级设置：

```
验证数据库

Replay Oplog

修复 Projection
```

# V0.6 — P2P 增强

研究增加：

```
Nearby Connections

Bluetooth / Wi-Fi Direct
```

用于：

```
Android ↔ Android

Android ↔ iPhone

iPhone ↔ iPhone
```

在没有传统 LAN 的情况下同步。

但：

> LAN P2P 永远作为基础同步协议。

# V1.0 — 正式稳定版

V1.0 目标：

> 成为一款真正适合长期考研使用的成熟工具。

包含：

```
目标院校

考试倒计时

Subjects

Tasks

Plans

Study Timer

Pomodoro

Study Sessions

Knowledge Tree

Study Phases

真题 / 模考

Daily Review

Weekly Review

Statistics

Heatmap

Backup

P2P Sync

Multi Device

Device Trust
```

# V1.x 后续

根据用户实际需求考虑：

```
桌面小组件

手机Widget

系统快捷指令

Apple Watch

Wear OS

快捷启动计时

CSV导入导出

NAS备份
```

# 暂不承诺的功能

即使进入 V1，也不优先做：

```
社区

好友

排行榜

资料交易

广告系统

云账号

中心服务器

强社交

短视频式内容

复杂AI聊天
```

# 开发优先级原则

出现需求冲突时：

优先顺序：

```
1 数据安全

2 数据正确

3 离线可靠

4 同步可靠

5 高频使用体验

6 性能

7 UI

8 新功能

9 动画与视觉效果
```

# 每个版本发布前必须验证

## 数据

```
不会丢数据
```

## Timer

```
锁屏后正确

App挂起后正确
```

## Operation

```
幂等

乱序安全
```

## Sync

```
两设备一致

三设备一致

重复同步一致
```

## Tombstone

```
删除数据不会复活
```

## Backup

```
可真正恢复
```

# 项目最终方向

不要把研迹做成：

> 功能很多但每天没人愿意打开的软件。

而应该不断优化：

```
查看今天
↓
开始学习
↓
完成任务
↓
结束学习
↓
看到成果
↓
晚上复盘
```

这个最核心的日循环。

只要这个循环体验足够好，后续：

```
计划
知识树
成绩
AI
多设备
```

才真正有价值。
## M1c 验收范围

七类业务实体、真实 FieldClock/Tombstone/MV Register、OperationWriter/Applier 统一 Resolver、自动 pending 物化、撤销后真实重算、rebuildEntity/Workspace 和 projectionDigest；所有测试使用真实 SQLite。完成后先进入 M2/M3 三设备随机收敛测试，不增加网络、QR、mDNS、UI、统计图表或 AI。

## M2/M3 验证范围与后续顺序

M2：三份独立 SQLite 文件、六条字节队列、Frontier Diff/Gossip、固定乱序/并发/删除/依赖/Timer/授权/撤销/重启场景。

M3：可重放 seed 与完整 ScenarioLog、随机四类业务动作及网络/重启/授权事件、有上限的 convergence phase、五层结果断言、三设备重建一致性、失败 seed corpus、性能记录。PR 配置 10 × 200，Extended 100 × 1000，Soak 100 × 2000；配置规模不等于已执行规模，实际运行结果以 docs/validation 与 CHANGELOG 为准。Shrinker 为后续增强项，暂不做投影性能优化。

M3 Gate 通过后的开发顺序：基础业务 UI（Onboarding、Subjects、Today、Tasks、Timer、Daily Review）→ 单设备可用 → Xcode/Android 工具链及平台构建/真机验证 → LAN Transport。M3 完成不自动表示平台或网络已验证。
