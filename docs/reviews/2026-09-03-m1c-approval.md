# M1b 验收通过 · 开始 M1c

M1b 当前状态验收通过。

当前实现和测试结果满足进入 M1c 的条件：

- Workspace-scoped origin_seq 已实现；
- HLC/context 已数据库持久化；
- transaction rollback 不消费 seq；
- remote HLC observe 已实现；
- Dot + causal context 因果判断已实现；
- Field LWW 所需 winner 比较基础已实现；
- 长文本 Multi-Value Register 算法已实现；
- RFC 8949 deterministic CBOR profile 已实现；
- immutable envelope 与 local metadata 已分离；
- signed bytes 原样保存及转发已实现；
- Ed25519 identity / sign / verify 已实现；
- secure key storage abstraction 已建立；
- restore/new install 使用新 Device Identity 的基础语义已验证；
- quarantine / duplicate / unknown schema / pending authorization 基础接收逻辑已实现；
- membership refreshAuthorization 和 revoke cutoff 基础行为已实现；
- 固定 golden vector 已由独立 Python oracle 复核；
- 43 项 Flutter 测试通过；
- flutter analyze 通过。

现在进入：

# M1c — Production Projection + OperationWriter

本阶段不要增加网络、QR、mDNS 或 UI 功能。

目标是：

> 将 M1b 已验证的协议与算法接入真实 Drift 业务数据库，建立“本地业务写入 → Signed Operation → Projection”以及“Remote Operation → Resolver → Projection”的完整生产路径。

---

# 一、M1c 核心目标

完成以下生产组件：

```text
Business Schema

Projection Store

FieldClock

Tombstone

OperationWriter

OperationApplier

Conflict Resolver

Materialization / Pending Dependency

Rebuild Projection
```

最终必须做到：

```text
本地 Command
↓
生成 Operation
↓
签名
↓
同事务写入 Oplog + Projection
```

以及：

```text
Remote Signed Operation
↓
Verify
↓
Persist
↓
Authorization
↓
Resolver
↓
Projection
```

---

# 二、先建立真实业务 Schema

M1c 第一批只实现同步系统验证所必需的业务实体。

不要一次把整个产品数据库全部做完。

优先：

```text
Workspace

ExamProfile

Subject

Task

StudySession

StudySessionSegment

DailyReview
```

同步基础表：

```text
Oplog

WorkspaceClockState

ObservedOrigins / Frontier

FieldClock

Tombstone

TrustedDevice / Membership materialization

Quarantine / local delivery state
```

可以暂缓：

```text
StudyPhase

KnowledgeTree

TaskTemplate

ExamAttempt

复杂 Plans
```

等底层通过 M3 后再扩展。

---

# 三、业务表 ID 规则必须遵守已有规范

普通实体：

```text
UUIDv7
```

每日复盘：

```text
daily_review/{workspace_id}/{YYYY-MM-DD}
```

并继续保持：

```text
UNIQUE(workspace_id, review_date)
```

不要重新引入跨 Workspace deterministic ID 碰撞。

---

# 四、FieldClock 正式生产化

实现真实：

```text
entity_field_clock
```

至少保存：

```text
workspace_id
entity_type
entity_id
field_name

winner_op_id

hlc_wall_ms
hlc_counter
origin_device_id
origin_seq
```

如果因果判断需要：

可以引用 Operation 中的 dot/context。

FieldClock 本身是：

> 当前 Projection winner 的索引。

真正历史事实仍然来自：

```text
Oplog
```

---

# 五、普通字段 Resolver

对于普通 scalar field：

例如：

```text
Task.title
Task.status
Task.estimated_seconds
Subject.name
ExamProfile.target_school
```

规则：

### 情况 1

没有现有版本：

```text
incoming wins
```

### 情况 2

existing happens-before incoming：

```text
incoming wins
```

### 情况 3

incoming happens-before existing：

```text
ignore incoming for projection
```

### 情况 4

concurrent：

使用：

```text
HLC
→ origin_device_id
→ 必要时 op_id
```

得到确定性 winner。

必须保证：

> 到达顺序不同，不影响最终 Projection。

---

# 六、Patch Operation 必须只影响显式字段

例如 Operation：

```json
{
  "entity_type": "task",
  "action": "update",
  "payload": {
    "title": "高数极限40题"
  }
}
```

只能修改：

```text
title
```

不得因为 payload 中没有：

```text
estimated_seconds
```

就将该字段设为：

```text
NULL
```

即：

# Update 是字段 Patch，不是整行替换。

---

# 七、Create 不得拥有特殊覆盖特权

由于 Operation 可以乱序：

```text
update
↓
create
```

是合法情况。

因此：

```text
create
```

本质也应看成：

> 提供一组初始字段版本。

不能简单：

```text
INSERT ROW
```

然后覆盖已经存在的 newer fields。

例如：

先收到：

```text
Task.update title = B
```

之后收到：

```text
Task.create title = A
```

如果 update 是更新版本：

最终必须：

```text
title = B
```

---

# 八、Pending Materialization

业务表有 NOT NULL 和 FK 约束，因此不要为了乱序 Replay 放宽所有数据库约束。

正式建立：

```text
materialization state
```

例如：

```text
pending_create
pending_dependency
materialized
```

可以采用：

```text
Oplog
+
FieldState/Resolver state
```

已经知道部分字段，但尚不足以创建合法业务行时：

```text
不要向 Projection 写半成品行
```

例如：

```text
Task.title
```

已到，

但是必须字段尚缺：

则继续 pending。

等必要 create/field 到达后：

自动 materialize。

---

# 九、Dependency Late Arrival

例如：

```text
StudySession
```

引用：

```text
Subject
```

但 Subject 尚未到达。

Operation 可以：

```text
verified
authorized
persisted
```

但是 Projection：

```text
pending_dependency
```

Subject 后来 materialize：

必须触发：

```text
retry dependent entities
```

最终 StudySession 自动落入业务表。

不能要求：

> 用户重新同步一次

或者：

> App 重启以后才恢复。

---

# 十、不要把 SQL Foreign Key 当同步 Resolver

FK 是：

> 数据完整性最后防线。

不是：

> 同步协议。

Resolver 必须提前知道：

```text
dependency missing
```

并正确 pending。

不要依赖：

```text
INSERT → FOREIGN KEY ERROR
```

作为正常控制流。

---

# 十一、Tombstone 生产化

实现真实 Tombstone。

对于普通永久删除实体：

```text
delete
```

产生 Tombstone。

一旦有效 Tombstone 生效：

普通：

```text
create
update
```

不能复活该：

```text
entity_id
```

除非未来协议明确增加 restore generation。

V1 不实现。

---

# 十二、DailyReview 例外

DailyReview：

# 不允许 hard delete。

“删除复盘”：

实际生成：

```text
content = ""
```

update Operation。

不得创建：

```text
DailyReview Tombstone
```

---

# 十三、长文本 MV Register 正式持久化

不要只保留：

```text
text_conflicts winner / loser
```

实现真正的：

```text
active causal versions
```

建议设计类似：

```text
text_field_versions

workspace_id
entity_type
entity_id
field_name

op_id
origin_device_id
origin_seq

value

is_active
```

或者等效结构。

Resolver 根据 causal context：

移除已经被 incoming causally supersede 的旧版本。

如果与已有 active version 并发：

两个都保留。

Projection 使用确定性 winner 显示。

---

# 十四、解决长文本冲突

用户以后解决：

```text
A
B
```

产生 Operation C。

C 的 causal context 必须覆盖：

```text
A
B
```

Resolver Replay 后：

active versions：

```text
{C}
```

不要通过：

```text
DELETE conflict row
```

来“解决”冲突。

冲突消失必须是：

> Operation 历史的自然结果。

---

# 十五、StudySession 模型按批准方案实现

Session：

```text
id
workspace_id
subject_id
task_id?
knowledge_node_id?
owner_device_id
status
created/start metadata
```

计时实际时间使用：

# StudySessionSegment

例如：

```text
session_id

segment_id

started_at_ms

ended_at_ms
```

总 Duration：

```text
SUM(segment duration)
```

不要把：

```text
duration_seconds
```

作为另一个需要同步维护的独立真值。

可以作为：

```text
derived/cache
```

但必须可重算。

---

# 十六、V1 Timer Owner 规则

Session 创建时：

```text
owner_device_id
```

固定。

只有 Owner 可以产生：

```text
pause
resume
stop
```

其他设备：

```text
read-only
```

M1c 可以先在 Domain/Resolver 层建立 invariant。

UI 后面再处理提示。

---

# 十七、Session 状态应由事件/字段组合保持业务一致

避免：

```text
ended_at
duration
status
```

三个字段独立 LWW 后组合成非法状态。

建议定义明确的原子业务动作：

```text
session.start

session.pause

session.resume

session.stop
```

这些 Operation Payload 中属于一个业务动作的字段：

必须一起验证和 Apply。

不要允许出现：

```text
status = completed

但最后 Segment 仍 open
```

这样的 Projection。

---

# 十八、OperationWriter

M1c 最重要的生产组件。

推荐接口类似：

```text
OperationWriter.execute(command)
```

职责：

```text
1. validate domain command
2. begin transaction
3. load workspace clock
4. allocate seq
5. tick HLC
6. capture causal context
7. build envelope
8. canonical CBOR
9. sign
10. persist oplog
11. apply through SAME resolver
12. persist clock
13. commit
```

关键原则：

# Local Operation 和 Remote Operation 必须尽可能走同一个 Resolver。

不要出现：

```text
本地修改直接 UPDATE tasks
远端修改走 ConflictResolver
```

否则两套语义迟早分叉。

正确：

```text
Local command
↓
Operation
↓
Resolver
↓
Projection
```

Remote：

```text
Operation
↓
Resolver
↓
Projection
```

区别只在：

```text
Operation 是本地产生还是远程收到
```

---

# 十九、本地修改成功定义

UI 得到：

```text
成功
```

只能发生在：

```text
Operation
+
Projection
+
Clock State
```

整个事务：

```text
COMMIT
```

以后。

不允许：

UI 已显示成功，但 Oplog 写失败。

---

# 二十、Remote Operation 接收事务

Remote：

```text
signed bytes
+
signature
```

完成基础 Verify/Auth 后：

建议：

```text
BEGIN

insert oplog

apply resolver

update field state

update projection

update origin progress

COMMIT
```

如果 Projection 因 dependency/schema 等不能 materialize：

Oplog 可以成功保存，

对应状态 pending。

---

# 二十一、Unauthorized Revoked 重算

现有 refreshAuthorization 已能重新标记历史 Operation。

M1c 需要接入真实 Projection：

如果 Operation：

```text
原来 authorized
```

后来因为 revoke cutoff：

```text
unauthorized_revoked
```

则：

# 必须重建其影响实体。

V1 可以先实现简单但正确的方法：

```text
rebuildEntity(entity_type, entity_id)
```

流程：

```text
清除该实体 Projection
清除其 FieldClock / MV Register derived state
读取该实体所有当前有效 Operations
按 Resolver 重放
```

不必一开始做高性能增量回滚。

优先：

# Correctness > Performance

---

# 二十二、建议直接实现 rebuildEntity

这是非常重要的调试和修复原语。

接口：

```text
rebuildEntity(...)
```

以及后续：

```text
rebuildWorkspace(...)
```

都从：

```text
有效 Oplog
```

重新生成 Projection。

它以后可以用于：

```text
authorization changed
migration
debug
database repair
backup restore
```

---

# 二十三、Projection Determinism Hash

M1c/M3 建议增加测试工具：

```text
projectionDigest(workspace)
```

对同步业务 Projection：

```text
规范排序
规范编码
hash
```

例如 SHA-256。

排除：

```text
received_at
local log
retry counter
```

等本机元数据。

M3 最终可以直接断言：

```text
DeviceA.digest
==
DeviceB.digest
==
DeviceC.digest
```

这样比手工逐表比较可靠。

---

# 二十四、M1c 测试

必须使用：

# 真实 SQLite

至少新增以下测试。

## Local Write

```text
Command
↓
Operation
↓
Projection
```

三者同时成功。

---

## Local Rollback

人为令 Projection apply 失败：

```text
oplog 不得残留
seq 不得前进
clock committed state 不得前进
```

---

## Local / Remote Semantic Equivalence

同一个逻辑 Operation：

作为本地操作产生

和：

作为 Remote Operation Apply

最终 Projection 必须一致。

---

## Update Before Create

真实 SQLite：

```text
update
↓
create
```

最终正确 materialize。

---

## Missing Dependency

```text
Session
↓
Subject later
```

最终自动 materialize。

---

## Field Merge

A 改 title。

B 改 estimatedSeconds。

最终两个修改都存在。

---

## Same Field Concurrent

不同到达顺序：

最终 winner 相同。

---

## MV Register

两个并发 DailyReview：

最终两个 active versions 一致。

---

## Resolve MV Register

新 Operation causally supersede 两个版本：

最终只剩一个 active version。

---

## Tombstone

```text
create
delete
old update
```

实体不得复活。

不同到达顺序也一样。

---

## Revocation Rebuild

先 Apply：

```text
Device X #101
```

之后：

```text
revoke X cutoff=100
```

Projection 必须回到：

```text
没有 #101 影响
```

---

## Rebuild Entity

正常运行所得 Projection：

和：

```text
清空 derived state
rebuildEntity
```

结果完全一样。

---

## Rebuild Workspace

最终可以加：

```text
rebuildWorkspace
```

结果与增量 Apply 完全一致。

---

# 二十五、M1c 验收标准

只有达到以下条件才算 M1c 完成：

```text
真实业务 Projection 可用
```

```text
OperationWriter 完整事务化
```

```text
本地/远端统一 Resolver
```

```text
FieldClock 生产化
```

```text
Tombstone 生产化
```

```text
MV Register 持久化
```

```text
乱序 Materialization 可用
```

```text
Missing Dependency 自动恢复
```

```text
Revocation 可以重算真实 Projection
```

```text
rebuildEntity 可用
```

```text
所有测试通过
```

```text
flutter analyze 无问题
```

---

# 二十六、M1c 期间明确不做

暂时禁止进入：

```text
mDNS

TLS Transport

QR

Camera

Bonjour

Nearby Connections

真实 LAN Sync

完整 UI

统计图表

AI
```

这些不能帮助证明数据层正确性。

---

# 二十七、M1c 完成后的下一步

不是立即做网络。

进入：

# M2 / M3 Convergence Testing

建立三份：

```text
device_a.sqlite
device_b.sqlite
device_c.sqlite
```

使用真正的：

```text
OperationWriter

Signature

Authorization

Resolver

Projection

FieldClock

Tombstone
```

运行随机化测试：

```text
乱序
重复
分区
重新连接
Gossip
Concurrent Edit
Delete
Revoke
Dependency Delay
```

最终比较：

```text
Projection Digest
```

证明收敛。

只有 M3 通过：

才开始核心业务 UI 和 P2P 网络层。