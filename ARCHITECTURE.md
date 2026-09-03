# 研迹 YanJi — 总体技术架构

2026-09-03 · 与 SYNC v1.1 对齐。当前 M0/M1a 工程保留。

## 文档职责与优先级

| 根文档 | 唯一事实来源 |
| --- | --- |
| PRODUCT.md | 产品定位、功能边界、产品行为 |
| ARCHITECTURE.md | 总体技术架构 |
| SYNC.md | Operation、合并、Trust、Pairing、同步协议 |
| ROADMAP.md | 版本范围、开发顺序、Milestone |

交叉冲突时更具体的领域文档优先。DATABASE.md 维护数据库结构和持久化实现，并遵循 SYNC.md 的协议规则。docs/reviews 只保存历史；批准 docs/adr 下 ADR 的同一 commit 必须修改对应根规范。docs 下实现说明只说明代码位置和验证结果，不创设协议。

## 技术方向

Flutter / Dart，Mobile First、Desktop Enhanced。Android / iPhone 为 P0，iPadOS / Windows / macOS 为 P1；iPadOS 复用 iOS runner。

Local First + Offline First + P2P + Multi Master + Operation Log + Eventually Consistent。每台设备有完整本地副本，设备平等，无账号服务器、云数据库、中心同步服务器或公网穿透。核心业务完全离线可用。

```text
Flutter UI
  ↓ Application / Domain
Repository → OperationWriter
  ↓ 同一 SQLite transaction
Projection + Oplog + FieldClock + ClockState
  ↑
Sync Engine → Verify / Trust / Resolver
  ↕ Operation bytes + signature
LAN discovery → TCP / TLS 1.3 → YSP/1
```

UI 不直接访问 SQLite；业务层不直接访问网络；Sync 不依赖 UI；网络只搬运 Operation，Resolver 决定状态。

## 数据基础

Drift / SQLite，后台 isolate，Application Support/yanji.sqlite。WAL、foreign_keys=ON、synchronous=FULL。未经真机测量和评审不得改回 NORMAL。

从第一天使用 Drift schemaVersion、MigrationStrategy、schema snapshot。当前尚未发布的 v1 允许修订；发布后显式迁移，禁止静默删库升级。

Workspace 保留多空间能力，具有 IANA stats_timezone。普通实体 UUIDv7；确定性实体包含 workspace_id，例如 daily_review/{workspace_id}/{date}。

每个 Workspace + local device 的 next_origin_seq、HLC 和观察上下文持久化。序号、时钟、签名日志和业务派生状态在同事务提交。观察合法远端操作同样持久化 HLC。

## Operation 与回放

Envelope 和本机 delivery metadata 分离。RFC 8949 Deterministic CBOR、Ed25519、原始 signed bytes 保存及转发；签名规范细节只在 SYNC.md 维护。固定 golden vectors 锁定字节和签名。

普通字段采用因果优先、并发时 Field-Level LWW；因果关系由 dot + causal_context 判断。长文本保留未被因果覆盖的 Multi-Value Register 版本集合，HLC 仅决定默认显示 winner。

普通实体永久 Tombstone；DailyReview 的清空语义由 PRODUCT.md 定义，不使用 Tombstone。Projection 是当前有效 Operation 集合的派生结果。

存储与应用分离：applied、pending_entity_create、pending_dependency、pending_authorization、pending_schema；撤销后 unauthorized_revoked。授权/依赖晚到后重试，不依赖网络到达顺序。坏签名/畸形输入进入本机 quarantine，不能污染主日志。

## 身份与信任

Device ID + Ed25519 key pair。私钥不入 SQLite/Oplog/备份日志，只进入 OS secure storage；数据库仅保存公钥和 key reference。

Genesis 自签 + QR 锚定 genesis hash/inviter + 可验证 device.add 授权历史。撤销永久作用于 ID，使用 Workspace 内 cutoff_seq；超 cutoff 操作即使已经应用也要撤回并重新物化。完整授权链验证不能被单纯“签名通过”替代。

Backup 与 Sync 分开。新安装恢复数据时生成全新身份，不克隆旧 origin；历史公钥保留，新身份必须取得合法授权后才能同步。

## Timer 与统计

StudySession 有 owner_device_id。V1 只有 owner 可 pause/resume/stop，其他设备只读。暂停/继续使用 StudySessionSegment，时长始终由 Segment 求和，跨午夜按 Workspace.stats_timezone 拆分统计。并行学习保留多个 Session，不自动覆盖。

## LAN P2P

mDNS / Bonjour `_yanji-sync._tcp`，不广播学习正文、目标学校、用户名或 Workspace 名称。TCP + TLS 1.3 + fingerprint pinning + Ed25519 challenge；仅受信任设备交换 Workspace Frontier、Operation batch 和 ACK。

YSP/1 为同步协议，YPP/1 为 QR 配对。QR 使用一次性 256-bit secret、2 分钟有效、用户确认和六位校验码，额外锚定 Workspace Genesis。打开应用后短时发现并同步，可手动同步；不依赖全天后台驻留。

## 工程组织

```text
lib/
  app/                    # Router、注入、Theme
  core/
    database/ crypto/ clock/ ids/ logging/
  domain/                 # 随业务阶段增加
  sync/
    oplog/ protocol/ conflict/ trust/
    discovery/ transport/ pairing/  # 网络阶段增加
  features/               # 随业务阶段增加
    onboarding/ today/ subjects/ tasks/ timer/
    plans/ statistics/ review/ settings/
test/
schemas/
docs/
  reviews/
  adr/                    # 有决策时按需新增
```

保持可读，关键 HLC、Trust、因果、回放、Tombstone 代码说明原因。日志分类 APP/DATABASE/SYNC/AUTH/FRONTIER/OPS/VERIFY/APPLY/CONFLICT；不记录密钥或学习正文。

## 验证与平台门槛

开发顺序以 ROADMAP.md 为准。M1b 验证序号、时钟、签名、编码和因果参考模型；M1c 实现完整 Projection/FieldClock/Tombstone/OperationWriter；M3 验证三份真实数据库收敛。尚未完成的层不得通过测试替身宣称已经上线。

纯 Dart/SQLite 开发不被平台工具链缺失阻塞。OS secure storage 真机、iOS/Android runner、Timer 生命周期、mDNS、相机前必须补齐工具链并通过对应 flutter doctor 项目。FULL 的持久性和性能在真机发布门槛验证。

## M1c 生产路径

OperationWriter.execute(command) 与 OperationApplier.receive(packet) 通过同一 Resolver/ProjectionStore 物化真实业务表，Journal、Projection、字段时钟、Tombstone、正文版本、Frontier 在同一外层事务提交。重建先采用全 Workspace 重算，包含依赖闭包；不清理历史日志或回退 HLC。范围和验收以 ROADMAP.md 与 SYNC.md 为准。

## M2/M3 验证层

测试 Harness 使用三份独立文件数据库和生产连接，设备之间只传播签名字节。SimulatedTransport 处理路由、队列和可达性，不理解业务语义；重启销毁并重建数据库与 Identity/Writer/Applier 对象。确定性 ID/时钟注入仅用于复现，生产默认保持 UUIDv7/HLC。

显式 membership policy 的签名传播夹具位于 test/，用独立 policy workspace 和测试表保存验证输入，不实现或注册生产 Genesis/授权链。每轮最终分别比较业务、字段时钟、删除、正文版本、有效 Operation、membership 和 Frontier，再检查 invariant 和全量重建。测试入口与已运行规模见 docs/m2-m3.md。
