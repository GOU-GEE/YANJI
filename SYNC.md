# 研迹 YanJi SYNC v1.1 — 数据与 P2P 同步规范

文档状态：2026-09-03 批准冻结 v1.1。本文件是 Operation、合并、Trust、Pairing 与同步协议的唯一事实来源。总体架构见 ARCHITECTURE.md，产品语义见 PRODUCT.md，版本范围见 ROADMAP.md。历史评审不覆盖根规范。

## 1. 总体架构

正式确定为：

```
Flutter App
│
├── UI / Business
│
├── Drift
│    └── SQLite
│
├── Sync Engine
│    ├── Operation Log
│    ├── Conflict Resolver
│    ├── Device Trust
│    └── Peer Discovery
│
└── Local P2P Transport
     ├── mDNS / Bonjour 发现
     └── TLS 1.3 加密连接
```

支持：

```
Android
iOS
iPadOS
Windows
macOS
```

每台设备都有：

```
自己的 SQLite
自己的 Device ID
自己的身份密钥
完整业务数据副本
完整 Operation Log
已信任设备列表
```

**不存在中心节点。**

例如：

```
      iPhone
      ↕    ↘
     iPad ↔ Mac
```

A 可以把来自 B 的数据继续同步给 C。

# 2. 数据分成三类

这是数据库设计非常重要的一条规则。

## A. 同步数据

这些需要在所有设备保持一致：

```
目标院校
考试日期
科目
学习计划
任务
学习 Session
复习进度
每日复盘
真题成绩
模考成绩
知识点
```

## B. 本机数据

不应该同步：

```
窗口大小
当前页面
主题
通知权限
本机下载路径
最后一次打开页面
本机数据库设置
```

例如：

Mac 可以深色模式。

iPhone 可以浅色模式。

互不影响。

## C. 安全数据

绝对不进入 Operation Log：

```
设备私钥
TLS 私钥
QR Pair Secret
临时 Session Key
```

必须进入操作系统安全存储：

```
iOS / iPadOS
→ Keychain

Android
→ Keystore

macOS
→ Keychain

Windows
→ OS Credential / Protected Storage
```

SQLite 只保存：

> 公钥 / fingerprint / key reference

不保存私钥明文。

# 3. SQLite 基础配置

数据库：

```
yanji.sqlite
```

SQLite 使用：

```
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;
PRAGMA synchronous = FULL;
```

SQLite WAL 模式允许读取操作和写入操作更好地并发，比较适合“前台 UI 读取 + 后台同步写入”的场景。SQLite 官方同时提醒，复制 WAL 数据库文件时不能只复制主 `.db` 文件，因为未 checkpoint 的已提交数据可能还位于 WAL 中。

这也进一步说明：

# 我们绝对不通过复制 SQLite 文件来同步。

Flutter 数据层采用：

```
Drift
+
SQLite
```

Drift 当前原生实现可以覆盖 Flutter 的移动端和桌面平台，并支持把数据库操作放进后台 isolate，避免阻塞 UI。

# 4. ID 规范

普通业务对象统一使用：

# UUIDv7

例如：

```
01991f8d-0ef2-7c1d-b30b-7dd5ba8e7d31
```

UUIDv7 已经属于 RFC 9562 标准 UUID 类型，适合分布式系统生成全局 ID。

优点是：

```
设备 A 创建任务
设备 B 创建任务
设备 C 创建 Session
```

完全不需要服务器分配 ID。

冲突概率可以忽略。

# 5. Workspace 作用域确定性 ID

普通实体使用 UUIDv7。天然唯一实体统一使用 `{entity_type}/{workspace_id}/{logical_key}`。
每日复盘 ID 为 `daily_review/{workspace_id}/{YYYY-MM-DD}`，仍可使用全局 id 主键，同时保留 UNIQUE(workspace_id, review_date)。日历日期不随设备时区转换。

# 6. Workspace

用户的数据不是属于“账号”。

而属于：

# Workspace

例如：

```
workspace_id:
01991f82-....

name:
我的2028考研

created_at:
2026-09-03
```

以后甚至可以允许：

```
我的2028考研
我的英语学习
我的公务员考试
```

但 V1 一个用户默认一个 workspace。

# 7. Workspace

Workspace 保存 id、name、created_at_ms、created_by_device_id、schema_version，以及 IANA `stats_timezone`（例如 Asia/Shanghai）。所有今日、本周、热力图、连续学习天数按该时区统计。跨午夜 Segment 按该时区边界分摊。

表结构与本机数据库版本由 [DATABASE.md](DATABASE.md) 维护。

# 8. 第二组：本机身份

```
CREATE TABLE local_device (
    device_id TEXT PRIMARY KEY,

    device_name TEXT NOT NULL,
    platform TEXT NOT NULL,

    identity_public_key BLOB NOT NULL,

    identity_private_key_ref TEXT NOT NULL,

    tls_cert_fingerprint BLOB NOT NULL,
    tls_private_key_ref TEXT NOT NULL,

    created_at_ms INTEGER NOT NULL
);
```

注意：

```
identity_private_key_ref
```

只是类似：

> yanji.identity.private

这样的系统安全存储引用。

真正私钥不在 SQLite。

# 9. Trusted Devices

```
CREATE TABLE trusted_devices (
    workspace_id TEXT NOT NULL,
    device_id TEXT NOT NULL,

    device_name TEXT NOT NULL,
    platform TEXT,

    identity_public_key BLOB NOT NULL,

    tls_cert_fingerprint BLOB NOT NULL,

    trust_state TEXT NOT NULL,
    -- active
    -- revoked

    paired_at_ms INTEGER NOT NULL,

    revoked_at_ms INTEGER,

    last_seen_at_ms INTEGER,

    PRIMARY KEY (
        workspace_id,
        device_id
    )
);
```

例如：

```
我的2028考研

✓ John iPhone
✓ iPad Pro
✓ MacBook Pro
```

# 10. 持久化 Hybrid Logical Clock

HLC = (wall_ms, counter)，普通字段排序为 (wall_ms, counter, origin_device_id)。它用于确定性排序，不用于判断并发或计算学习时长。
每个 (workspace_id, local_device_id) 持久保存 next_origin_seq、last_hlc_wall_ms、last_hlc_counter。
本地 tick、签名、日志、Projection、FieldClock 和 ClockState 必须同事务提交。失败不得消费序号或推进已提交时钟。
合法远端 Operation 到达后也必须在存储事务内 observe(remote_hlc) 并持久化；下一次本地操作必须晚于已观察的远端事件。未认证或授权未决数据不得推进本地因果状态。

# 11. Operation Log 与本机投递状态

Oplog 保存原始 envelope_bytes、signature 和可查询的不可变索引字段。唯一身份为 op_id 和 (workspace_id, origin_device_id, origin_seq)。
原始字节不得重新编码后替换；Gossip 传输相同 bytes + signature。

本机 metadata 与签名 envelope 分离，至少包括 received_from_device_id、received_at_ms、apply_state、retry_count、local_error。
apply_state 包含 applied、pending_entity_create、pending_dependency、pending_authorization、pending_schema，以及撤销后使用的 unauthorized_revoked。
存储成功不等于已经物化。invalid_signature、malformed 进入本机 quarantine/诊断，不进入正常主 Oplog。
索引、SQL 和不可变 triggers 见 [DATABASE.md](DATABASE.md)。

# 12. Workspace 内 origin_seq

每个 (workspace_id, origin_device_id) 从 1 独立连续递增。
同一设备交错写入 Workspace A/B 时，两者分别产生 1,2,3…，互不消费对方序号。
Frontier 始终属于一个 Workspace。数据库唯一约束为 UNIQUE(workspace_id, origin_device_id, origin_seq)。

# 13. Operation Envelope 与 CBOR 签名格式

wire_version=1，包含且仅包含以下协议字段：

```text
wire_version
workspace_id
op_id
origin_device_id
origin_seq
hlc_wall_ms
hlc_counter
causal_context
entity_type
entity_id
action
payload_schema_version
payload
```

signature 不在 envelope 内。`signature = Ed25519.sign(envelope_bytes)`。
envelope_bytes 使用 RFC 8949 §4.2.1 Core Deterministic CBOR：最短长度编码、确定长度容器、按编码后键字节排序。禁止普通 jsonEncode 签名、浮点、tag、undefined 和不定长编码。

V1 应用映射（envelope、context、payload map）使用 text key；允许值 int64、uint64、text、bytes、bool、null、array、map。uint64 超过 Dart signed int 范围时使用 BigInt，不能先转换到 double/int。控制字段（seq、时钟）取非负 signed int64，seq 从 1 开始；payload 可用完整 uint64。拒绝重复 map key、畸形 UTF-8、额外尾字节和非确定性编码。

接收时先对原始 envelope_bytes 验签，再解析/验证结构及确定性编码；重新编码只用于检查编码规范，不能作为验签输入。签名合法不等于 membership 合法。未知 payload schema 仍保存、转发原始字节。

本机 metadata（received_from/at、apply_state、retry_count、local_error、detected_at）绝不参与签名。wire_version 与 payload_schema_version、本机 Drift schemaVersion 三者独立。

Golden vector 固定 seed、public key、envelope、CBOR hex、signature hex，修改编码导致向量变化属于 breaking change。向量只使用公开测试密钥，绝不用生产身份。

## Dot 与因果上下文

Dot = (origin_device_id, origin_seq)，始终在同一 Workspace 比较。
causal_context 映射 origin → 已观察版本。缺省为 0，不包含当前 dot；同 origin 的前一序号必须已经观察。
同 origin：A.seq < B.seq ⇒ A happens-before B。
不同 origin：B.context[A.origin] >= A.seq ⇒ A happens-before B。
双向都不成立才是并发。不同 Workspace 不存在可比较的因果关系。

Frontier 的连续存储前缀与观察上下文是不同概念：已验证、已授权的 seq=3 可以先到，即使缺 2；存储 Frontier 不得越过空洞。context 的序列覆盖语义遵循同 origin 的 happens-before 规则；高序号隐含该 origin 的先前事件。保留可信远端的传递因果上下文。

# 14. 为什么 Operation 必须签名

因为未来可能出现：

```
iPhone
  ↓
iPad
  ↓
Mac
```

Mac 收到的数据可能是：

> iPad 转发来的 iPhone Operation。

所以 Mac 必须验证：

```
这条 Operation
真的由 iPhone 创建
```

而不是：

```
iPad 假装 iPhone 创建
```

每个设备都有：

```
Ed25519 private key
Ed25519 public key
```

Operation 使用私钥签名。

其他设备使用 trusted_devices 里的：

```
identity_public_key
```

验证。

Dart 的现有密码库已经直接支持 Ed25519。

# 15. Operation 是不可变的

这是铁规则。

一旦生成：

```
OP #932
```

永远不能：

```
UPDATE oplog SET payload = ...
```

修改任务的时候：

不是修改 OP #932。

而是：

```
创建 OP #933
```

所以：

```
Operation Log
=
Append Only
```

# 16. 所有本地修改原子写入

完整 OperationWriter 在一个 SQLite transaction 中读取 ClockState、分配 seq、tick HLC、构造包含当前 context 的 envelope、签名、更新 Projection、写 Oplog、更新 FieldClock、持久化 ClockState/context，然后提交。
任一步失败全部回滚。网络层不能直接更新业务表。
M1b 先验证 clock + signed log 的事务内核；M1c 才接入完整业务 Projection/FieldClock/Tombstone。

# 17. Field Clock

为了避免整个对象互相覆盖，我们做：

# 字段级冲突解决

需要表：

```
CREATE TABLE entity_field_clock (
    workspace_id TEXT NOT NULL,

    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    field_name TEXT NOT NULL,

    hlc_wall_ms INTEGER NOT NULL,
    hlc_counter INTEGER NOT NULL,

    origin_device_id TEXT NOT NULL,
    op_id TEXT NOT NULL,

    PRIMARY KEY (
        workspace_id,
        entity_type,
        entity_id,
        field_name
    )
);
```

# 18. 为什么必须字段级同步

假设任务：

```
标题：
高数极限30题

预计时间：
90分钟
```

iPhone 修改：

```
标题
→ 高数极限40题
```

iPad 同时修改：

```
预计时间
→ 120分钟
```

如果整行覆盖：

必定丢一个修改。

字段级合并以后：

```
标题：
高数极限40题

预计：
120分钟
```

两个修改都保留下来。

# 19. 普通字段：因果优先， concurrent 时 LWW

仅 payload 中显式存在的字段参与该次写入；缺失字段不是 null。create 同样提供初始字段版本，不覆盖已有的更新版本。
每个字段先保留未被因果覆盖的版本；若 existing happens-before incoming 则 incoming 取代它，反向则 incoming 不改变当前字段；并发版本以 HLC → origin_device_id → op_id 决定 winner。
完整重算采用“先取因果极大版本集合，再按确定性总序选 winner”，避免将因果比较与并发 tie-break 混成非传递排序。FieldClock 是 winner 索引，历史事实仍在 Oplog。

# 20. Delete 必须特殊处理

绝对不能这样：

```
iPhone 删除任务 A

iPad 离线
仍然保存任务 A

两天后同步

任务 A 又出现
```

这叫：

# Zombie Resurrection

所以删除不是：

```
DELETE FROM tasks
```

而是创建：

# Tombstone

```
CREATE TABLE tombstones (
    workspace_id TEXT NOT NULL,

    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,

    delete_op_id TEXT NOT NULL,

    hlc_wall_ms INTEGER NOT NULL,
    hlc_counter INTEGER NOT NULL,

    origin_device_id TEXT NOT NULL,

    PRIMARY KEY (
        workspace_id,
        entity_type,
        entity_id
    )
);
```

收到任何：

```
update
```

如果 entity 已经存在 Tombstone：

# 直接忽略。

即使这个 Update 时间更晚。

# 21. 永久 Tombstone 的适用范围

普通实体删除不可恢复，同一 entity_id 的后续 create/update 不能复活；重新创建使用新 UUID。多个有效 delete 确定性归并。
DailyReview 是例外：V1 的“删除复盘”是写 content=""，不发 entity.delete、不生成 Tombstone，当天之后仍可使用同一 ID 填写。产品语义见 PRODUCT.md。

# 22. 学习科目表

```
CREATE TABLE subjects (
    id TEXT PRIMARY KEY,

    workspace_id TEXT NOT NULL,

    name TEXT NOT NULL,

    category TEXT,
    -- politics
    -- english
    -- math
    -- major
    -- custom

    target_score_x100 INTEGER,
    max_score_x100 INTEGER,

    sort_order INTEGER NOT NULL DEFAULT 0,

    archived INTEGER NOT NULL DEFAULT 0
);
```

用：

```
score_x100
```

不用浮点。

例如：

```
125.5 分
=
12550
```

避免不同环境浮点行为带来的问题。

# 23. 考研目标

```
CREATE TABLE exam_profile (
    workspace_id TEXT PRIMARY KEY,

    exam_name TEXT,

    exam_date TEXT,

    target_school TEXT,
    target_major TEXT,

    target_total_score_x100 INTEGER
);
```

日期：

```
2028-12-23
```

使用：

```
YYYY-MM-DD
```

因为这是“日历日期”。

不应该因为用户去了日本、美国或者中国而发生变化。

# 24. Study Phase

```
CREATE TABLE study_phases (
    id TEXT PRIMARY KEY,

    workspace_id TEXT NOT NULL,

    subject_id TEXT,

    name TEXT NOT NULL,

    start_date TEXT,
    end_date TEXT,

    sort_order INTEGER NOT NULL,

    status TEXT NOT NULL
);
```

例如：

```
数学

基础阶段
强化阶段
真题阶段
冲刺阶段
```

# 25. Knowledge Tree

```
CREATE TABLE knowledge_nodes (
    id TEXT PRIMARY KEY,

    workspace_id TEXT NOT NULL,

    subject_id TEXT NOT NULL,

    parent_id TEXT,

    name TEXT NOT NULL,

    node_type TEXT NOT NULL,

    sort_order INTEGER NOT NULL DEFAULT 0,

    mastery INTEGER
);
```

例如：

```
408
└ 数据结构
   ├ 线性表
   ├ 栈
   ├ 队列
   ├ 树
   │ ├ 二叉树
   │ └ AVL
   └ 图
```

# 26. Tasks

```
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,

    workspace_id TEXT NOT NULL,

    title TEXT NOT NULL,

    subject_id TEXT,
    knowledge_node_id TEXT,
    phase_id TEXT,

    scheduled_date TEXT,

    due_at_ms INTEGER,

    estimated_seconds INTEGER,

    priority INTEGER NOT NULL DEFAULT 0,

    status TEXT NOT NULL,
    -- todo
    -- doing
    -- completed
    -- cancelled

    completed_at_ms INTEGER,

    note TEXT
);
```

# 27. 重复任务不要直接塞进 Tasks

例如：

> 每天背200个单词

设计成模板：

```
CREATE TABLE task_templates (
    id TEXT PRIMARY KEY,

    workspace_id TEXT NOT NULL,

    title TEXT NOT NULL,

    subject_id TEXT,

    recurrence_rule TEXT NOT NULL,

    start_date TEXT NOT NULL,

    end_date TEXT,

    active INTEGER NOT NULL DEFAULT 1
);
```

然后每天生成：

```
Task Instance
```

这样历史记录才不会变化。

# 28. StudySession 与 Segment

Session 包含 id、workspace_id、subject_id、task_id、knowledge_node_id、owner_device_id、status、started_at_ms、ended_at_ms、mode、note。
StudySessionSegment 包含 id、workspace_id、session_id、started_at_ms、ended_at_ms。
Pause 关闭当前 Segment，Resume 创建新 Segment，Stop 关闭最后 Segment 并把 Session.status 设为 completed。Duration 唯一真值为 Segment 有效区间之和，禁止同时维护多个独立时长真值。
持久化区间及锁屏/挂起恢复必须经过 Timer 阶段的生命周期测试。

# 29. Timer Owner

只有 Session.owner_device_id 能 pause/resume/stop，其他设备仅可只读显示正在学习。
V1 不支持 iPhone 开始、iPad 停止。未来 ownership transfer / lease 另行设计。
Owner 校验属于业务授权，与 membership 合法和签名合法分别校验。

# 30. 不允许两个设备偷偷争夺 Active Timer

如果：

iPhone：

> 开始数学

iPad 同时：

> 开始408

不自动覆盖。

保留两个 Session。

然后提示：

```
检测到两个重叠的学习记录

数学
14:00–15:30

408
14:20–15:40

[保留全部]
[修正记录]
```

避免同步系统自作聪明地删除用户数据。

# 31. DailyReview

ID = daily_review/{workspace_id}/{YYYY-MM-DD}，数据库同时保留 UNIQUE(workspace_id, review_date)。content 使用下节 Multi-Value Register。
删除按钮写空内容，不生成 Tombstone；并发离线内容仍按因果上下文合并，不能用清空静默抹掉未观察的版本。

# 32. 长文本 Multi-Value Register

DailyReview.content 和未来长笔记正文保留当前未被因果覆盖的版本集合。
并发 A、B 得到 {A,B}；UI 默认显示按 (HLC, origin_device_id) 最大的版本，其他版本完整保留。
用户选择/合并时产生 C，其 context 必须同时观察 A、B，集合变为 {C}。
先到 C、后到 A/B 或任意 Gossip 路径都必须得到同一集合，不依赖到达顺序。

如需 Conflict ID，基于 workspace_id、entity_type、entity_id、field_name、sorted(op_ids) 的确定性编码取哈希。detected_at_ms 仅本机 metadata，不参与 ID、winner、签名或收敛比较。原 winner + loser copy / text_conflicts 模型已由版本集合替代。

# 33. 真题 / 模考

直接统一成：

```
CREATE TABLE exam_attempts (
    id TEXT PRIMARY KEY,

    workspace_id TEXT NOT NULL,

    subject_id TEXT,

    title TEXT NOT NULL,

    exam_type TEXT NOT NULL,
    -- mock
    -- past_paper
    -- practice

    exam_year INTEGER,

    taken_at_ms INTEGER NOT NULL,

    score_x100 INTEGER,
    max_score_x100 INTEGER,

    duration_seconds INTEGER,

    correct_count INTEGER,
    wrong_count INTEGER,

    note TEXT
);
```

这样：

```
2024数学一真题
2025数学一真题
张宇八套卷1
408模拟卷
```

都可以使用同一个模型。

# 34. Device Sync Progress

我们需要知道：

> 对方已经拥有哪些 Operation。

```
CREATE TABLE origin_progress (
    workspace_id TEXT NOT NULL,

    origin_device_id TEXT NOT NULL,

    max_contiguous_seq INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY(
        workspace_id,
        origin_device_id
    )
);
```

例如 iPhone：

```
自己的 Operation:
1–1032

iPad:
1–842

Mac:
1–391
```

表示：

```
iPhone 已经拥有：

Phone #1-1032
iPad  #1-842
Mac   #1-391
```

# 35. Vector Frontier

连接时，设备交换：

```
{
  "iPhone": 1032,
  "iPad": 842,
  "Mac": 391
}
```

iPad 返回：

```
{
  "iPhone": 1017,
  "iPad": 842,
  "Mac": 391
}
```

马上知道：

```
iPad 缺：

iPhone #1018–1032
```

只发：

15 个 Operation。

# 36. Operation Log V1 不删除

这一点我建议非常明确：

# V1 永久保留 Oplog。

暂时不做复杂 compaction。

为什么？

考研软件数据量非常小。

假设：

```
每天20个 Operation
×
365天
×
4年
```

也只有：

```
29,200 Operations
```

就算每条平均 1KB：

也就是几十 MB。

完全值得。

换来的好处非常大：

```
任意设备都可以完整恢复
任意设备都可以给新设备初始化
可以审计
可以排查同步 Bug
可以重建数据库
```

# 37. Projection 思想

真正同步的是：

```
Operation Log
```

这些：

```
tasks
subjects
study_sessions
...
```

可以理解为：

# Projection

也就是方便 UI 查询的“当前状态”。

理论上我们甚至可以：

```
删除所有业务表
↓
读取 oplog
↓
重新 replay
↓
恢复整个数据库
```

所以以后设置里可以有：

> 高级 → 重建本地数据库索引

用于修复异常。

# 38. Synchronization Protocol

协议名称暂定：

# YSP — YanJi Sync Protocol

版本：

```
YSP/1
```

# 39. Peer Discovery

同一局域网使用：

# mDNS / Bonjour

服务：

```
_yanji-sync._tcp
```

Apple 官方把 Bonjour 描述为基于 mDNS 与 DNS-SD 的本地网络服务发现方式，可以完成 advertise、browse、connect；iOS/iPadOS 上使用本地网络还需要声明相关隐私权限。

广告不要广播：

```
目标学校
用户名
学习内容
workspace名称
```

只公布必要信息：

```
protocol = 1
device_hint = abc123
port = xxxx
```

# 40. 建立连接

网络连接：

```
TCP
↓
TLS 1.3
↓
YanJi Sync Protocol
```

不传明文 HTTP。

第一次配对：

QR 里面带：

```
TLS Certificate Fingerprint
```

新设备必须进行：

# Certificate Pinning

因此即使局域网有人进行中间人攻击：

证书 fingerprint 不匹配：

```
立即终止连接
```

# 41. 已配对设备认证

建立 TLS 后：

Responder：

```
生成随机 nonce
```

例如：

```
d93b7c8e....
```

Initiator：

```
Ed25519.sign(
    nonce
    + workspace_id
    + initiator_device_id
    + responder_device_id
)
```

Responder 使用：

```
trusted_devices.identity_public_key
```

验证。

所以仅知道：

```
IP
端口
设备ID
```

没有设备私钥也不能同步。

# 42. YSP Hello

认证后双方发送：

```
{
  "protocol": 1,
  "schema_version": 1,

  "workspace_id": "...",
  "device_id": "...",

  "frontier": {
    "deviceA": 932,
    "deviceB": 221,
    "deviceC": 98
  }
}
```

# 43. 计算 Diff

A：

```
A 932
B 221
C 98
```

B：

```
A 900
B 225
C 98
```

那么：

A → B：

```
A #901–932
```

B → A：

```
B #222–225
```

# 44. Batch

Operation 不要一条一条发。

例如：

```
最多256条 / batch
```

协议：

```
OPS_BATCH

origin_device:
A

from_seq:
901

to_seq:
932

operations:
[ ... ]
```

# 45. 接收、验证与乱序重试

1. 限制消息大小、识别 workspace/envelope 版本，取得可信来源公钥。
2. 对原始 envelope_bytes 验签；解析校验 CBOR/profile/字段；畸形与坏签名进入 quarantine。
3. 验证 Genesis 授权历史与 cutoff。缺授权证明时保留待审状态，不影响业务、时钟或观察上下文。
4. 在事务内检查 op_id 和 workspace-origin-seq；完全相同为幂等 no-op，同身份不同内容拒绝。
5. 保存原始 bytes/signature。未知 payload schema → pending_schema；缺 create → pending_entity_create；缺实体依赖 → pending_dependency。
6. 对合法已授权操作 observe HLC 并持久化；计算连续存储 Frontier。
7. 依赖/授权/可识别 schema 到达后自动 retry。update-before-create、Session-before-Subject 都合法。
8. Projection 永远从当前有效 Operation 集合派生；撤销使操作失效时必须重新计算受影响状态。

ACK 区分已持久化与已物化，不能因 pending 状态丢弃或重复消费序号。未知合法 schema 可以继续 Gossip。

# 46. 幂等与身份冲突

同一已验签 envelope_bytes + signature 重复投递不改变状态；必须同时核对 op_id 和 workspace-origin-seq。
同一身份对应不同字节为冲突/伪造诊断，不得 INSERT OR IGNORE 静默吞掉，也不得 REPLACE 原 Operation。
同一 Operation 被转发 100 次时，HLC/观察状态无需重复推进。

# 47. Operation 不要求按时间到达

可能：

```
#103
```

先到。

```
#102
```

后到。

系统不能出错。

通过：

```
HLC
+
Field Clock
```

决定最终状态。

但是：

```
max_contiguous_seq
```

只有：

```
1
2
3
4
...
```

连续拥有以后才能推进。

例如拥有：

```
1–101
103
104
```

那么：

```
max_contiguous_seq = 101
```

不是104。

# 48. QR Pairing Protocol

协议：

# YPP — YanJi Pairing Protocol

版本：

```
YPP/1
```

旧设备点击：

> 添加设备

生成：

```
invite_id
pair_secret
expires_at
```

pair_secret：

```
256-bit secure random
```

有效期：

# 2分钟

且：

# 只能使用一次。

# 49. QR 内容

建议不是普通 JSON。

二维码：

```
yanji://pair?v=1&data=BASE64URL(...)
```

data 内部使用紧凑编码。QR 必须包含 workspace_genesis_hash、inviter 身份公钥/指纹、TLS fingerprint 和 pair_secret。新设备先锚定用户扫描的 Inviter，再验证 Genesis 到 Inviter 的授权链；失败则终止配对。

逻辑内容：

```
{
  "v": 1,

  "workspace_id": "...",
  "workspace_genesis_hash": "SHA-256 of canonical genesis envelope bytes",

  "invite_id": "...",

  "inviter_device_id": "...",

  "identity_public_key": "...",

  "tls_cert_sha256": "...",

  "pair_secret": "...",

  "service": "_yanji-sync._tcp",

  "port": 48173,

  "expires_at_ms": 1788426500000
}
```

可以额外带：

```
local IP hints
```

例如：

```
192.168.1.12
```

但 IP 只是 hint。

不能作为身份依据。

# 50. 为什么 QR 必须包含 Fingerprint

新设备扫描以后知道：

> 我真正应该连接的是哪一台设备。

因此：

```
QR
↓
TLS Fingerprint
↓
服务器证书
```

必须完全一致。

否则：

```
Pairing Failed
```

# 51. Pair Secret 的作用

即使攻击者：

```
知道你的 IP
知道端口
知道你正在配对
```

没有：

```
256-bit Pair Secret
```

也无法提交 Pair Request。

# 52. Pairing 流程

完整流程：

```
Device A
点击添加设备

↓

生成 Invite

↓

显示 QR

↓

Device B
扫描 QR

↓

读取
workspace_id
fingerprint
pair_secret

↓

连接 Device A

↓

TLS fingerprint 验证

↓

发送 Pair Request

↓

A 验证 Pair Secret

↓

B 发送：
Device ID
Device Name
Identity Public Key
TLS Fingerprint

↓

A 弹窗

“iPad Pro 请求加入研迹”

↓

用户允许

↓

双方确认验证码

↓

A 创建 device.add Operation

↓

发送历史 Operations

↓

B Replay

↓

同步完成
```

# 53. 6位安全验证码

虽然扫描二维码已经非常安全，我仍建议保留：

```
482 731
```

两台设备同时显示。

验证码从：

```
Pair Secret
+
Device A Public Key
+
Device B Public Key
```

派生。

用户看到：

```
iPhone
482 731

iPad
482 731
```

确认相同。

再点击：

> 允许。

这样可以明显降低误配对风险。

# 54. device.add 也必须是 Operation

设备关系不是单独偷偷写数据库。

配对成功后：

生成：

```
entity_type:
device

action:
system

payload:
{
   "type": "device.add",
   ...
}
```

因此：

iPhone 添加 iPad。

以后 Mac 也会收到：

```
device.add(iPad)
```

于是：

```
iPhone
iPad
Mac
```

拥有一致的信任列表。

# 55. Workspace Genesis 与授权链

首条 workspace.genesis 包含 workspace_id、root_device_id、root_device_public_key，由 root 自签。
Genesis 自签不意味着可以信任任意自称的根。QR 通过 workspace_genesis_hash 和用户明确选择的 inviter 身份建立信任锚。
之后 device.add 必须由当前 active 的已授权设备签名；验证 Genesis → membership history → inviter 的完整链。
授权证明可以晚于业务操作到达；pending_authorization 不进入有效 Projection。
同一 Device ID 不得换公钥，不得在永久 revoke 后再次 add。

# 56. 永久撤销与 cutoff

device.revoke payload 必须包含 target_device_id、max_allowed_origin_seq。cutoff 属于当前 Workspace 内目标 origin 流。
seq <= cutoff 保留为可验证的历史候选；seq > cutoff 永远无效。设备连接认证在 revoke 后立即拒绝；转发也不能绕过 cutoff。
同一目标的多个合法撤销取最严格 cutoff（min），防止消息顺序或较宽的新 cutoff 重新放行。
撤销到达前已应用的超 cutoff 操作标为 unauthorized_revoked，并从有效操作集合移除、重新物化受影响实体。若该操作是授权操作，其后代授权也必须重新验证，不能只删除一行业务数据。
同一 ID 永不复活；重新加入物理设备必须使用新 Device ID 和新 key pair。历史公钥保留以验证旧日志。

并发互相撤销、撤销授权者导致的授权闭包变化需要 Trust 阶段的固定点/收敛测试；M1b cutoff 参考验证不等于完整 membership 验证器。

# 57. 一个现实安全限制

因为没有服务器：

假设手机丢了。

那台手机已经拥有的数据：

# 无法远程擦除。

这是纯本地架构无法避免的。

Device Revocation 只能做到：

> 其他设备以后不再接受它同步。

不能做到：

> 远程删除丢失设备上的 SQLite。

所以产品需要明确告诉用户这一点。

# 58. 协议与数据库版本

wire_version 定义 envelope/编码，payload_schema_version 定义业务 payload，本机 Drift schemaVersion 定义 SQLite 表。
可解析 envelope、身份合法且签名有效，但 payload schema 较新时，原样存储、标记 pending_schema，不 apply，允许 Gossip；升级后重新 Replay。
无法识别的 wire version 不能猜测验证/业务语义，留本机诊断等待升级。
当前未发布的 schema v1 允许按批准的 v1.1 直接修订；发布后必须显式 migration。

# 59. 本地同步状态

增加：

```
CREATE TABLE peer_sync_state (
    workspace_id TEXT NOT NULL,

    peer_device_id TEXT NOT NULL,
    origin_device_id TEXT NOT NULL,

    peer_known_seq INTEGER NOT NULL DEFAULT 0,

    updated_at_ms INTEGER NOT NULL,

    PRIMARY KEY (
        workspace_id,
        peer_device_id,
        origin_device_id
    )
);
```

这是性能优化。

真正事实仍然来自：

```
oplog
+
origin_progress
```

# 60. V1 同步状态机

正式定义：

```
DISCONNECTED

↓

DISCOVERED

↓

CONNECTING

↓

TLS_VERIFIED

↓

AUTHENTICATING

↓

EXCHANGE_HELLO

↓

COMPARE_FRONTIER

↓

SEND_OPS
RECEIVE_OPS

↓

VERIFY

↓

APPLY

↓

ACK

↓

IN_SYNC

↓

DISCONNECTED
```

# 61. 自动同步策略

主要使用手机，所以不要让 App 一直后台扫描。

建议：

用户打开研迹：

```
mDNS扫描 3～5秒
```

发现已配对设备：

```
自动连接
↓
自动增量同步
```

如果没有：

什么都不发生。

iOS/iPadOS 对本地网络发现和后台行为有自己的权限和生命周期限制，因此产品不应该依赖“App 被杀掉后仍永久后台同步”。Apple 对 Bonjour、本地网络访问和附近设备通信均要求相应权限配置。

所以产品文案应该是：

> 打开研迹后自动同步附近设备。

而不是：

> 24小时后台同步。

# 62. 手动同步

设备页面：

```
附近设备

● iPad Pro
  刚刚同步

● MacBook Pro
  2小时前

[立即同步]
```

点一次：

开始扫描。

# 63. 全量同步其实也很简单

新设备：

```
frontier = {}
```

旧设备：

```
iPhone = 1002
iPad = 721
Mac = 391
```

那么直接：

```
把所有 oplog 发过去
```

新设备：

```
Replay
```

即可。

因为研迹不存大量视频或图片：

这点数据完全可以接受。

# 64. Backup 和 Sync 要分开

Sync：

```
设备之间保持一致
```

Backup：

```
防止所有设备一起丢失
```

因为没有服务器：

建议提供：

# 加密离线备份文件

例如：

```
YanJiBackup-2028-09-03.yanji
```

用户可以：

```
AirDrop
U盘
NAS
文件App
移动硬盘
```

自己保存。

# 65. Backup 不直接打包正在运行的 SQLite

恢复到新安装不得复制旧私钥作为当前身份。恢复 Workspace、Oplog、业务数据和历史公钥后，必须生成新 Device ID、新 Ed25519 key pair，未来使用新 origin。新身份仍需合法 membership/recovery 授权流程，不能仅凭恢复数据库自封 active。

正确流程：

```
暂停写入
↓
SQLite Backup API / checkpoint
↓
生成一致性快照
↓
打包
↓
加密
```

避免 WAL 状态下粗暴复制数据库文件。SQLite 官方明确指出，活动状态下 WAL 文件属于数据库持久状态的一部分，遗漏它可能造成数据丢失或损坏。

# 66. 安全模型

最终我们保护四件事情。

### ① 身份

```
Ed25519
```

### ② 第一次信任

```
QR
+
256bit Pair Secret
+
Fingerprint
+
用户确认
```

### ③ 网络传输

```
TLS 1.3
+
Certificate Pinning
```

### ④ 数据来源

```
每条 Operation
Ed25519 Signature
```

因此：

```
局域网监听者
```

无法看到学习数据。

陌生设备：

```
无法加入 Workspace。
```

已配对设备转发：

```
无法伪造其他设备产生的 Operation。
```

# 67. 第一版暂时不做数据库本身加密

V1：

```
SQLite 明文
+
操作系统 App Sandbox
+
OS Secure Storage 保存私钥
+
P2P 加密传输
```

V2 如果需要进一步保护：

```
SQLCipher
```

可以提供：

> 数据库密码 / Face ID 解锁

但第一版不建议增加这个工程复杂度。

# 68. 第一版同步范围

V1 正式支持：

```
✅ Android ↔ Android
✅ Android ↔ iPhone
✅ Android ↔ Windows
✅ Android ↔ Mac
✅ iPhone ↔ iPad
✅ iPhone ↔ Mac
✅ iPhone ↔ Windows
✅ Windows ↔ Mac
```

条件：

# 位于同一局域网。

例如：

```
家庭 Wi-Fi
宿舍 Wi-Fi
手机热点
```

# 69. 手机热点是一个很重要的 fallback

比如：

```
iPhone
+
Windows 笔记本
```

没有公共 Wi-Fi。

直接：

> 手机开热点。

电脑加入热点。

然后：

```
研迹自动发现
↓
P2P同步
```

仍然：

# 完全不需要互联网。

# 70. V1 暂时不做

为了控制开发范围，明确砍掉：

```
❌ 云服务器

❌ 用户账号

❌ 手机验证码

❌ Firebase

❌ Supabase

❌ WebSocket公网中继

❌ NAT穿透

❌ TURN

❌ Internet跨城市同步

❌ 完整CRDT

❌ 后台永久同步

❌ SQLite文件同步
```

# 71. V1 的一致性模型

研迹不是银行系统。

我们追求：

# Eventual Consistency

也就是：

```
设备离线
↓
各自工作
↓
重新相遇
↓
交换 Operation
↓
自动合并
↓
最终一致
```

不是：

```
每次修改都必须实时一致
```

# 72. 一个完整实例

上午：

iPad：

```
OP iPad#81
创建：
英语阅读任务
```

iPhone：

```
OP Phone#120
数学学习 Session

OP Phone#121
完成高数任务
```

两个设备此时完全离线。

晚上：

```
iPhone ↔ iPad
```

交换 Frontier。

Phone：

```
Phone 121
iPad 80
```

iPad：

```
Phone 119
iPad 81
```

因此：

```
Phone → iPad
#120
#121
iPad → Phone
#81
```

最后：

Phone：

```
Phone 121
iPad 81
```

iPad：

```
Phone 121
iPad 81
```

状态完全一致。

# 73. 第三台设备加入

MacBook：

```
frontier = {}
```

它不一定必须找到手机。

如果只发现：

```
iPad
```

也可以：

```
Mac ← iPad
```

得到：

```
所有来自：

Phone
iPad
以及过去其他设备
```

的 Operation。

因为：

# Operation 可以 Gossip。

这正是去中心化架构的核心。

# 74. 代码模块建议

Flutter 工程建议：

```
lib/

core/
  database/
  crypto/
  clock/
  ids/

sync/
  discovery/
  transport/
  pairing/
  protocol/
  oplog/
  resolver/
  trust/

features/
  today/
  tasks/
  timer/
  plans/
  subjects/
  statistics/
  review/
  settings/
```

最关键：

```
业务层不能直接调用网络层。
```

业务层只需要：

```
Repository
↓
SQLite
+
Operation Writer
```

Sync Engine 自己负责：

```
SQLite ↔ Peer
```

# 75. 最终核心写入流程

UI → Command → Domain/Repository → OperationWriter → SQLite Transaction。
事务中：ClockState/seq → HLC tick → context + envelope → deterministic CBOR → Ed25519 → Projection + Oplog + FieldClock/Tombstone + ClockState → Commit。
提交后通知 UI，网络只负责后续搬运不可变 Operation。

# 76. 最终同步流程

```
打开研迹

↓

mDNS / Bonjour

↓

发现 Trusted Device

↓

TLS

↓

Certificate Pinning

↓

Ed25519 Challenge

↓

Exchange Frontier

↓

Calculate Missing Operations

↓

Batch Transfer

↓

Signature Verification

↓

Insert Oplog

↓

Conflict Resolution

↓

Update Projection

↓

ACK

↓

In Sync
```

# 77. 最终配对流程

```
旧设备
生成 Invite

↓

256-bit Pair Secret
+
TLS Fingerprint
+
Device Public Key

↓

QR

↓

新设备扫描

↓

验证 TLS Fingerprint

↓

Pair Request

↓

旧设备用户确认

↓

6位验证码

↓

device.add Operation

↓

建立 Trust

↓

全量 Oplog Sync

↓

Replay

↓

完成
```

# 78. V1 最终技术方案

| 模块                     | 决定                      |
| ------------------------ | ------------------------- |
| UI                       | Flutter                   |
| 数据层                   | Drift                     |
| Database                 | SQLite                    |
| SQLite Mode              | WAL                       |
| ID                       | UUIDv7                    |
| 时间排序                 | Hybrid Logical Clock      |
| 同步模型                 | Operation Log             |
| 冲突                     | Field-level LWW           |
| 长文本冲突               | Causal Multi-Value Register |
| 删除                     | Permanent Tombstone       |
| 数据一致性               | Eventual Consistency      |
| P2P发现                  | mDNS / Bonjour            |
| Transport                | TCP + TLS 1.3             |
| Peer Authentication      | Ed25519 Challenge         |
| Operation Authentication | Ed25519 Signature         |
| 首次配对                 | QR + Pair Secret          |
| QR Token                 | 256-bit / One-time / 2min |
| 身份校验                 | Certificate Pinning       |
| 同步范围 V1              | LAN                       |
| 云服务器                 | 无                        |
| 用户账号                 | 无                        |
| Operation Retention      | 永久                      |
| 新设备初始化             | 全量 Operation Replay     |

# 79. 我认为最重要的五条“不可违反原则”

**第一：**

> 永远不能直接同步 SQLite 文件。

**第二：**

> 每次业务修改必须和 Operation 在同一个 SQLite Transaction 中完成。

**第三：**

> Operation 一旦产生，永远不可修改。

**第四：**

> Delete 一旦生成 Tombstone，旧设备的普通 Update 永远不能把对象复活。

**第五：**

> 网络只负责搬运 Operation，Conflict Resolver 才负责决定当前状态。

这样以后即使我们：

```
换 P2P 技术
增加 Bluetooth
增加 Nearby
增加局域网 QUIC
甚至增加用户自建服务器
```

业务数据库和同步模型都不用推翻重做。

# 80. 最终一句话架构

研迹不是：

```
SQLite
+
局域网复制
```

而是：

# 一个本地优先、无中心、多主节点、基于签名 Operation Log 的个人学习数据库。

即：

```
Local First
+
Offline First
+
Peer to Peer
+
Multi Master
+
Eventually Consistent
+
User Owned Data
```

这套架构足够支撑研迹从 V0.1 一直发展到真正成熟的多端产品。
## 编码参考

[RFC 8949 §4.2.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-4.2.1)、[RFC 8032](https://www.rfc-editor.org/rfc/rfc8032.html)。

## M1c 生产物化规则（2026-09-03 批准）

实体：workspace、exam_profile、subject、task、study_session、study_session_segment、daily_review。后者 Segment 只通过 Session 原子动作产生，不接受独立 scalar update。
ExamProfile 使用 exam_profile/{workspace_id}/default；Workspace 的 entity_id 等于 workspace_id；普通业务 ID 为 UUIDv7；DailyReview ID/日期必须一致。

业务已知 schema payload 严格校验字段和类型。可解析但缺创建必填字段的远端 create 保留 pending_create，缺引用实体保留 pending_dependency，不插入半成品业务行。外键作为最后防线，依赖判断在 SQL 写入之前进行。所有依赖到达后自动重试。DailyReview delete 非法；清空 content 是普通因果 update。

Session 只接受 session.start/pause/resume/stop/delete。start payload 包含 owner_device_id（等于 origin）、subject_id、started_at_ms、segment_id、mode，可选 task_id/knowledge_node_id/note。pause/stop 包含 segment_id、ended_at_ms；resume 包含新 segment_id、started_at_ms。只有固定 owner 能控制或删除 Session；拒绝独立更新 status/ended_at/duration。首次 start 定义 owner；同 origin 的重复 start 取最早 seq，不同 origin 冲突由确定性总序选一个起始版本。后续 owner 动作按 origin_seq 验证状态转换，缺先前动作/目标 Segment 时 pending_dependency，时间区间非法或非 owner 控制标 invalid_domain。Stop 同时关闭最后 Segment 和完成 Session；暂停状态 Stop 必须引用最后关闭 Segment 的结束时间。Duration 由 Segment 区间求和，不入同步 payload。

materialization_state 区分 pending_create、pending_dependency、materialized、deleted。Oplog apply_state 额外记录 invalid_domain（例如动态 owner 校验失败）；这不等同于坏签名/畸形 envelope，保留原始签名历史以便确定性重算。已知 payload 的静态畸形输入进入 quarantine。

OperationWriter/OperationApplier 在同一数据库事务中运行 Journal 与同一个 ConflictResolver/ProjectionStore。本地成功必须等外层事务 commit，且本地命令目标已物化或完成有效删除。远端 pending 可以提交日志。
rebuildEntity 可以扩展到整个 Workspace 的依赖闭包；M1c 初版直接全 Workspace 重算以保证跨实体依赖及撤销一致性。Oplog、ClockState、ObservedOrigins 不因重建删除或回退。TrustedDevice 表物化显式 OriginLookup 决策，尚不替代完整 Genesis 授权链验证器。
projectionDigest 对业务表、FieldClock、Tombstone、正文活动版本和 materialization 状态按规范排序/CBOR/SHA-256；排除接收时间、重试、日志等本机元数据。

M2/M3 验证中 Frontier 和 membership 独立逐项比较，不纳入业务 projectionDigest。合法未知 schema 仍推进连续存储进度且可 Gossip，但不得改变业务 digest。超 cutoff 的历史禁止正常 Gossip，因此各库已撤销 Oplog 的本地保留集合可以不同；合法 Operation 集合和授权状态必须一致，已撤销历史不得影响任何业务派生状态。
