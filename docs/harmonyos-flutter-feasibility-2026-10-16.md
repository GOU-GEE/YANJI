# 研迹 Flutter 鸿蒙适配可行性评估

评估日期：2026-10-16（Asia/Shanghai）。对象是当前工作区中的研迹手机应用，目标为独立 HarmonyOS 应用。结论来自项目源码、锁定依赖的实际包清单、适配仓库 Git 引用及源码；尚未生成 HAP 或在鸿蒙设备运行。

## 结论与建议

**有条件可行，适合先做验证项目；当前依赖不能原样编译为鸿蒙应用。** 业务模型、操作签名、冲突解决、学习记录和大部分 Flutter 页面可以继续使用。主要投入集中在 SDK 版本收敛、SQLite 原生库加载、安全存储和平台插件。

建议以 **Flutter 3.41.9+ohos-1.0.2 发布版**作为第一轮验证基线，降低少量依赖的版本要求；保留现有 Android/iOS 环境，在隔离副本中验证。3.44.9 适配版可作为对照，其已核对的发布说明仍标注 canary，不能仅因为版本更接近现有项目就默认更适合发布。

**首版同步优先复用现有 Dart TLS 局域网同步，Syncthing 内嵌引擎单独立项验证。** 这能继续验证跨端同步，同时避免把首版能否运行完全绑定在 Go 移植上。该建议会改变当前同步入口和状态汇报，需要实际接线与互通测试，不能视为现成功能。

## 1. SDK 和依赖版本

### 已核对的版本

| 项目 | 本次检查结果 | 对研迹的影响 |
| --- | --- | --- |
| 当前项目 SDK | 本地缓存版本记录为 Flutter 3.47.2 / Dart 3.13.2 | 根工程要求 `sdk: ^3.13.2` |
| 当前自研同步插件 | `yanji_syncthing` 同样要求 Dart `^3.13.2` | 切到较早 SDK 时，即使暂不使用同步，保留此依赖也会阻止解析 |
| 鸿蒙发布基线 | `oh-3.41.9-release`，提交 `62357a93d653bf844f730bb1f4b7cc9e2139d14e`，对应 tag `3.41.9+ohos-1.0.2` | 上游 Dart 基线 3.11.5；不能满足当前两个 `^3.13.2` 约束 |
| 鸿蒙开发分支 | `oh-3.44.9-dev`，提交 `4cd1ef145b1e70c6b43b2e59b8192fe5b235f8a1`；远端有 `3.44.9+ohos-0.0.1-canary1` tag | Dart 基线 3.12.2，仍不能满足当前根工程和同步插件的要求 |
| 3.47 鸿蒙版 | 本次远端 heads/tags 检查未找到可采用的 3.47 发布引用 | 不以尚未交付的版本作为当前实施前提 |

Dart 3.11.5 来自 3.41.9 上游 DEPS 指向的 Dart `tools/VERSION`；鸿蒙发布分支另有自己的 Dart 补丁引用，本次未下载运行其 Dart SDK，因此这里区分“基线版本”和运行验证。3.44 分支 DEPS/DEPS_ohos 的 Dart 引用均对应 3.12.2。

[SDK 发布分支与版本说明](https://gitcode.com/CPF-Flutter/flutter_flutter/tree/3.41.9+ohos-1.0.2)、[3.44 开发分支](https://gitcode.com/CPF-Flutter/flutter_flutter/tree/oh-3.44.9-dev)。

### 版本收敛不只涉及根工程

当前锁定的 `go_router 18.0.1` 明确要求 Dart `^3.12.0`、Flutter `>=3.44.0`，所以不能放进 3.41 发布基线。它引入的 `cupertino_ui`、`material_ui` 也有相同代际要求。Pub 官方版本元数据中，`go_router 17.5.0` 要求 Dart `^3.10.0`、Flutter `>=3.38.0`，可作为候选；尚未验证其全部 API 和导航行为兼容。

当前锁定的 `bonsoir_android 7.1.3`、`webview_flutter_android 4.14.1`、`webview_flutter_wkwebview 3.26.1` 也要求 Flutter 3.44 / Dart 3.12。**即使本次目标是鸿蒙，Pub 仍需要解析清单中的跨平台依赖，不能忽略这些版本约束。** 需要在隔离工程重新解析并锁定整个依赖图。

`drift 2.34.4`、`drift_dev 2.34.6`、`sqlite3 3.5.2`、`path_provider 2.1.6`、`webview_flutter 4.14.1` 和 `build_runner 2.16.1` 自身的 SDK 下限在 3.41 / Dart 3.11 基线以内。它们仍分别存在平台实现或原生构建问题，不能把“版本允许”当作“鸿蒙可运行”。

本次对 `lib/` 和两个本地包的 `lib/` 共 **90 个 Dart 文件**，使用分析器的 Dart 3.11 语言特性集合检查，得到 **0 个语法诊断**。这说明降低项目声明值得尝试；不证明旧 SDK 的框架 API、依赖解析、Kernel/AOT 编译或运行都兼容。

[go_router 版本记录](https://pub.dev/packages/go_router/versions/17.5.0)。

### 工具链准备

3.41.9+ohos-1.0.2 的已核对发布说明配套 DevEco Studio / Command Line Tools 26.0.0 Release，应用编译最低 SDK 为 26.0.0，应用最低运行 SDK 配置为 5.0.5(17)。3.44 canary 的说明使用不同配套，并标注最低运行 API 26；插件说明中另有不同测试组合，不能混用这些数字推断兼容范围。

本机标准 Applications 目录未发现 DevEco，`hdc` / `hvigor` / `ohpm` 未在当前 PATH 中，三个常见 SDK 环境变量未配置。因此本次未做鸿蒙编译和设备运行，后续应以选定 SDK、插件和设备组成的实际组合验收。

## 2. 现有插件逐项判断

“可复用”指源码有复用基础，仍需在选定 SDK 下完成构建及运行验收。

| 依赖 / 模块 | 当前锁定版本 | 判断 | 具体处理 |
| --- | --- | --- | --- |
| Riverpod | 2.6.1 | 可复用主体 | 状态管理没有平台插件；验证鸿蒙生命周期触发 |
| `path` / `uuid` / `crypto` / `cryptography` / `timezone` / `http` | 1.9.1 / 4.6.0 / 3.0.7 / 2.9.0 / 0.11.1 / 1.6.0 | 可复用主体 | Dart 算法和数据处理继续使用；随机数、网络、TLS 与时区初始化需运行验证 |
| `qr_flutter` | 4.1.0 | 可复用主体 | 二维码生成是 Flutter 绘制，不需要相机插件 |
| `go_router` | 18.0.1 | 需要版本调整 | 3.41 基线评估 17.5.0；验证页面跳转、返回栈、ShellRoute 和计时入口 |
| `path_provider` | 2.1.6 | 有鸿蒙候选 | CPF 适配分支基于 2.1.5，已有 `path_provider_ohos`，实现应用支持目录；选择整个适配包或验证平台包注册，固定引用 |
| `flutter_secure_storage` | 10.3.1 | 需要替换 / 改造 | 当前包没有 ohos；已检查候选还存在接口版本和密钥存放问题，详见下文 |
| Drift / SQLite | 2.34.4 / 3.5.2 | 保留数据层，适配底座 | 保留表、事务、迁移与业务查询；重做原生库供应及加载验证 |
| `mobile_scanner` | Git v7.4.0 | 有鸿蒙候选 | CPF 的 `br_v7.1.4_ohos` 已含 ohos 插件；项目用到的 QR 格式、rawValue、start/stop、闪光灯等接口有对应源码，需降版或合入适配并实测 |
| `bonsoir` | 7.1.5 | 有社区候选，仍需验收 | `oh-flutter/bonsoir` 有同版本 beta 适配，含原生 mDNS 和 TXT 属性处理；验证本项目 hint、地址解析、IPv4/IPv6、换网重发现 |
| `webview_flutter` | 4.14.1 | 可以缩减首版依赖 | 当前 `lib/` 未发现导入或使用；首版评估移除。若确需使用，CPF 有 4.13.1 适配引用，需额外确认 API 与平台视图 |
| `liquid_glass_renderer` / 自绘 Shader | 本地 0.2.0-dev.4 | 先降级视觉 | SDK 版本声明允许尝试；渲染能力取决于鸿蒙引擎，首版使用项目已有 reduced/fallback 分支 |
| 学习实况 / 锁屏接口 | 自研 MethodChannel | 需要新增鸿蒙实现 | 当前支持判断仅覆盖 Android/iOS；鸿蒙不会自动得到计时展示和原生操作能力 |
| `yanji_syncthing` | 本地 0.1.0 | 需要新增平台实现 | 清单仅 Android/iOS/macOS，Windows 另有进程桥接；无 ohos 实现 |
| 测试工具 | `integration_test` 等 | 使用适配 SDK 版本 | 鸿蒙 SDK 的 integration_test 清单有 ohos 注册；当前官方 SDK 包没有，不宜直接沿用注册文件 |

候选来源：[路径插件](https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_path_provider-v2.1.5_ohos)、[扫码插件](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/tree/br_v7.1.4_ohos)、[Bonsoir 鸿蒙适配](https://gitcode.com/oh-flutter/bonsoir)、[WebView 适配](https://gitcode.com/CPF-Flutter/flutter_packages/tree/br_webview_flutter-v4.13.1_ohos)。这些是候选来源，尚未在研迹中安装或运行。

### 安全存储：不能直接套现成候选

现有 `PlatformKeyStorage` 保存签名身份 seed，`PlatformTlsIdentityStorage` 保存 TLS 私钥；应用组合根在打开时就加载身份。因此这既是同步问题，也是应用启动前置条件。

已检查的 CPF `br_v9.2.4_ohos` 中，`flutter_secure_storage_ohos` 是一个独立 Dart 包，要求 `flutter_secure_storage_platform_interface ^1.0.1`；当前 10.3.1 使用 `^2.0.1`，直接同时加入会发生主版本约束冲突。额外核对的 `br_v11.2.0_ohos_dev` 中，该子包仍声明旧接口。

此外，已检查版本的 `RSACipher18Implementation.ets` 将生成的 RSA 公私钥编码后写入 Preferences，再从中恢复。其保护应用 secret 的包装私钥并未体现为 HUKS 内不可导出的密钥。这不满足研迹现有“私钥进入操作系统安全存储、不采用明文回退”的要求。此判断针对本次固定提交中的实现，不推断所有同名包都相同。

建议增加小型鸿蒙安全存储适配：使用 HUKS 中的不可导出包装密钥保护持久化 secret，提供现有读取/写入语义；保留当前身份格式和首次安装原子化逻辑。必须验收重启身份不变、解锁前后行为、备份恢复和读取失败时不静默重建身份。

[已检查的安全存储分支](https://gitcode.com/CPF-Flutter/fluttertpc_flutter_secure_storage/tree/br_v9.2.4_ohos)、[HUKS 加解密开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-v5/huks-encryption-decryption-arkts-V5)。

### 数据库：版本允许不代表 SQLite 能加载

当前 `connection.dart` 使用 `NativeDatabase.createInBackground`，锁定的 `sqlite3 3.5.2` 使用 build hooks / code assets 加载 SQLite，而非旧的 `sqlite3_flutter_libs` 自动打包路线。

鸿蒙 3.41 发布分支已有 native assets 集成，但其 `OhosAssetTarget` 明确暂时把 hooks 的目标 OS 传为 Linux，以兼容尚不认识 ohos 的第三方包。当前 sqlite3 的默认 hook 会据此选择 Linux 预编译库。**Linux arm64 库不能因 CPU 架构相同就视为鸿蒙可用库。** 必须检查最终选择、ABI 和加载结果。

CPF `fluttertpc_sqlite3_flutter_libs` 的已检查 3.41 开发分支仍主要提供 legacy 插件；其中 sqlite3 子包为 3.3.0，而当前 Drift 要求 sqlite3 `^3.4.0`。不能用依赖强制覆盖掩盖这个差异。

优先验证：保持当前 Drift/SQLite API 和 schema，使用兼容鸿蒙的 SQLite 原生库，补齐 hook 或配置外部库加载。是否能仅用官方配置完成，需在实际 SDK 下确认；不要未经验证就替换成系统关系型数据库或回退整个 Drift 版本。

验收至少包含：后台数据库 isolate、WAL、事务回滚、外键、忙等待、原有迁移、应用被终止后的重新打开，以及操作日志与投影摘要一致。

[SQLite 适配来源](https://gitcode.com/CPF-Flutter/fluttertpc_sqlite3_flutter_libs/tree/br_3.41_dev)、[sqlite3 上游加载机制](https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3)。

## 3. 同步引擎

### 可以继续使用的部分

- Operation 编码、签名、HLC、Frontier、授权链、冲突解决与投影重建是 Dart 层实现，协议无需因新增平台而改变。
- `OperationFileExchange` 的文件格式和签名校验可以保留，文件路径、原子写入、目录行为需设备验证。
- 已有 `FileSyncEngine` 抽象，以及 Go `Execute(JSON)` 的 start/configure/scan/status/stop 边界，方便将平台桥接集中处理。

### Syncthing 当前不能直接复用的部分

1. `go.mod` 虽然表面 require `syncthing v1.30.0`，但通过 replace 使用本地 `.tooling/syncthing-2.1.5`；构建脚本也固定下载并验证 **2.1.5**。实际应评估 2.1.5。
2. 同步源码要求 **Go >=1.26.2**；本地 Go 为 1.27.1，其 `go tool dist list` 不含 ohos/openharmony。当前构建脚本仅覆盖 Apple、Android、Windows 和本机 harness。
3. Apple/Android 用 gomobile 生成的框架/AAR不能装入鸿蒙应用；Windows 进程桥接也不能直接挪到手机。需要新增 ohos 插件、适合的本地 ABI、线程队列、资源释放和打包配置。
4. `FSWatcherEnabled=false` 已避免依赖文件监视器运行，是有利因素；仍要验证 Syncthing 数据库、网络接口枚举、DNS、TLS、TCP/QUIC、文件锁、后台恢复。Go 的 CGO 路线会使用 mattn SQLite，非 CGO 路线使用 modernc SQLite，两条都需要分别确认目标兼容。
5. 社区确有 Go 鸿蒙移植工作，也有第三方 CLI 自述使用 Go 1.26.7 鸿蒙工具链运行于鸿蒙 PC；这不能证明手机 HAP 内嵌动态库已可用。本次检查到的 Go 1.26 源码分支名称和 VERSION 也不足以证明所需 port 已交付，未获得并运行适用工具链。

因此判断为：**引擎业务源码与 JSON 协议可保留，平台编译/加载/运行是独立待验证项；尚无充分依据承诺可直接打出可用 .so。** 若保留 Syncthing，应先验证最小 Go 库调用，再逐步加入 SQLite 和双节点同步，不要直接从完整 App 排错。

[Go 社区仓库](https://gitcode.com/openharmony-sig/ohos_golang_go)、[第三方 CLI 的鸿蒙支持边界](https://github.com/DingTalk-Real-AI/dingtalk-workspace-cli/blob/main/docs/openharmony.md)。

### 已有 Dart TLS 路线可以降低首版风险

`DevicePairingCoordinator.syncPairedDevices()` 已实现配对设备认证、双方挑战签名、Frontier 差异、Operation 分批交换；`PinnedTlsTransport` 提供证书指纹固定和 CBOR 帧传输。代码还会尝试缓存的已认证端点，发现服务受限时不一定完全失去连接能力。已有协议与设备重连测试覆盖这些路径，但本次未重新运行，也未在鸿蒙验证。

当前 App 手动/自动同步入口实际走 `AutomaticSyncController` 的文件引擎，Dart 同步方法尚不是鸿蒙的现成替代实现。启用它需要：

- 选择传输后端，改接手动同步、前台恢复、错误处理和状态 UI；不要把直接交换 Operation 的后端伪装成共享目录引擎。
- 使成功/失败和待同步数量的语义符合真实确认结果；现有 `syncPairedDevices()` 的返回值不能直接充当文件 ACK 统计。
- 禁用鸿蒙端 Syncthing 启动；验证 Android/iOS 侧仍能接受现有 Dart 监听端的协议，并检查并行传输的幂等性。
- 接入可用 mDNS，或验证二维码 IP 提示和缓存端点路径；验证 Dart SecureSocket/SecureServerSocket、接口枚举和系统网络权限。
- 首版按双端前台局域网同步验收；跨公网发现、中继、长期后台传输没有因此获得，需要单独设计。

## 4. 最小验证顺序与通过条件

| 顺序 | 验证内容 | 通过条件 | 不通过时的决策 |
| --- | --- | --- | --- |
| 1 | 固定 3.41 发布版，收敛 root/local SDK、路由及传递依赖 | 隔离工程依赖解析、静态分析、普通页面 HAP 构建通过 | 明确具体 API/依赖阻碍，再比较 3.44 canary，不先升级整个产品 |
| 2 | SQLite 原生资源与后台数据库连接 | 创建数据、事务/迁移、关闭重启和强制终止后恢复可靠 | 先修 hook/加载层；此项通过前不进入完整业务适配 |
| 3 | HUKS 支持的安全存储 | 身份和 TLS 密钥重启稳定，读取失败不产生新身份 | 修平台安全存储；不以 Preferences 明文回退 |
| 4 | reduced 视觉下的单设备闭环 | 创建科目/任务、计时、复盘、统计、后台恢复可用 | 定位实际页面和生命周期问题 |
| 5 | 扫码 / mDNS / Dart TLS 跨端互通 | 鸿蒙与现有平台双向配对、同步、断网重连，投影最终一致 | 分开排查扫码、发现、传输和应用层确认 |
| 6 | 可选 Syncthing 小型验证项目 | Go 库调用、索引库持久化、双节点文件同步、后台恢复逐项通过 | 保留 Dart 首版后端；不阻塞核心功能 |

本轮建议：允许进入隔离验证阶段；在 SQLite、安全存储和跨端同步验证通过前，不把项目状态标记为“鸿蒙适配完成”或估算确定上线日期。

## 5. 交付范围与证据

本轮仅新增评估文档及 `work/harmony-flutter-feasibility-2026-10-16/` 中的独立研究资料；未修改产品实现、根依赖清单或锁文件，未安装鸿蒙 SDK，未执行下载仓库中的构建脚本。

- `dependency-audit.json`：当前锁定依赖的版本约束与平台声明审查；不是完整 Pub 求解器。独立配置读取 136 项，其中两个 SDK 测试包本地缺失而未纳入扫描。
- `syntax-audit.json`：90 个文件的 Dart 3.11 语法检查；不涉及框架 API 和设备执行。
- `sources.json`：下载检查的各仓库引用及固定提交。
- `pubspec.snapshot.yaml` / `pubspec.snapshot.lock`：本次依赖审查快照。

涉及产品代码的主要位置：`pubspec.yaml`、`lib/core/database/connection.dart`、`lib/core/storage/platform_key_storage.dart`、`lib/sync/pairing/device_pairing_coordinator.dart`、`lib/sync/files/automatic_sync_controller.dart`、`packages/yanji_syncthing/`、`tool/build_syncthing.py`、`lib/platform/study_live_activity.dart`、`lib/design/glass/liquid_glass_quality.dart`。
