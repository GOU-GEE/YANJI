# 同步实现与测试状态

唯一协议规范：[SYNC.md](../SYNC.md)。历史批准记录：[SYNC v1.1 批准](reviews/2026-09-03-sync-v1.1-approval.md)。

## M1b 已实现

- Workspace 内序号及数据库持久化 HLC/context；合法 remote observe；事务失败回滚。
- Dot/context 因果判断；普通 HLC winner 比较；长文本 Multi-Value Register 纯算法。
- RFC 8949 Core Deterministic CBOR 应用 profile，int64/uint64、bytes、嵌套值及严格解析。
- Envelope 与 signature/local metadata 分离；原始 signed bytes 保存/转发。
- Ed25519 身份、签名/验签，secure key storage 抽象，新安装恢复时换新 origin/key。
- 接收内核：显式授权策略、坏签名/畸形 quarantine、重复 no-op、同身份不同内容拒绝、未知 schema 保留、pending authorization 重试。
- membership 变化后调用 refreshAuthorization：重新审查历史，标记超 cutoff 操作；正常 Gossip 排除 pending_authorization 和 unauthorized_revoked。HLC 不回退。

## 固定向量

test/fixtures/operation_v1.json 固定公开 seed 00..1f、公钥、Envelope、CBOR hex 和签名。
Dart 测试读取文件，不运行时生成期待值。tool/verify_golden_vector.py 使用独立 cbor2/cryptography 复核；其 --write 只用于经评审的向量更新，不能用于自动接受失败。

当前向量在 macOS Dart/Flutter 测试验证；其他目标平台必须复用同一文件。未声称已执行 Android/iOS/Windows 测试。

## M1c 前门槛的验证层级

| 门槛 | 验证位置与边界 |
| --- | --- |
| 双 Workspace 交错 seq、并发命令、回滚、文件重开、HLC observe | test/database/operation_journal_test.dart；真实 SQLite |
| 固定 bytes/signature、parse/serialize、每个 signed byte 篡改 | test/protocol/cbor_crypto_test.dart；独立 oracle |
| 未知 schema 保留/转发、待授权重试、cutoff 更新日志状态 | test/database/operation_journal_test.dart；授权决策由显式测试策略给定 |
| update-before-create、依赖晚到、并发复盘/解决、撤销后重算 | test/protocol/replay_gate_test.dart；可执行参考模型，非生产表 |
| 新安装恢复必须新 ID/Key | test/core/identity_test.dart；身份生命周期，非完整备份解包 |

本轮执行结果：43 项 Flutter 测试通过，flutter analyze 无问题，独立 Python oracle 与格式检查通过。

## M1c 生产路径

M1c 将前述算法接入真实 Drift 业务表，新增统一 Writer/Applier、因果优先 scalar Resolver、持久化 MV Register、Tombstone、依赖重试和撤销后重算。
production_projection_test.dart 使用独立真实 SQLite（包含文件重开测试），不使用 replay_reference 作为被测生产路径。实现和验收索引见 [docs/m1c.md](m1c.md)。

## 后续边界

仍未实现完整 Genesis/QR 授权链、并发撤销授权闭包、OS secure storage 平台适配、备份文件格式与网络。OriginLookup 必须提供已验证的 membership 决策；trusted_devices 是该决策的物化视图，不能自我授权。

M2/M3 已接入三份真实文件数据库、随机乱序/重复/分区/Gossip/删除/撤销/依赖延迟，以及 digest、逐表状态、Frontier、invariant 和 rebuild 比较。运行规模和结果见 [收敛验证](m2-m3.md)。完整生产授权链和 LAN Transport 仍是独立后续工作。
