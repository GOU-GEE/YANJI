# 模拟器联调：调试对端地址（2026-10-15）

## 为什么需要

Android 模拟器位于自己的 NAT 之后（客户机 `10.0.2.x`，宿主机 `10.0.2.2`）。
它的局域网广播和入站连接都到不了宿主机，因此默认的动态发现无法在
「Android 模拟器 ↔ iOS 模拟器」之间建立连接。配对握手使用二维码里的地址直连，
也受同一限制。

为此新增一个**仅 debug 构建读取**的手动对端地址覆盖：

- 地址只替代发现过程；对端证书仍固定为配对时锚定的指纹，
  所以覆盖地址不会引入新的身份。
- release/profile 构建忽略该变量。
- 实现见 [debug_peer_addresses.dart](/Users/goulijun/Documents/project/YANJI/lib/sync/pairing/debug_peer_addresses.dart)，
  接线在 [device_pairing_coordinator.dart](/Users/goulijun/Documents/project/YANJI/lib/sync/pairing/device_pairing_coordinator.dart) 的 `transportPeers`。

## 用法

```
flutter run -d <device> --dart-define=YANJI_SYNC_PEERS=<设备ID或前缀>=<地址>[,<...>]
```

- 地址接受 `host`、`host:port`、`tcp://host`、`tcp://host:port`；缺省端口 22000。
- 多个条目用逗号或分号分隔。
- 设备 ID 精确匹配优先，否则取最长前缀匹配（便于手输缩短 ID）。

### 推荐组合：iOS 模拟器作对端，Android 模拟器经 adb reverse 连接

1. 两端正常安装并打开 App。配对需要一次可达的连接：让 **Android 模拟器作为加入端**、
   iOS 模拟器作为邀请端时，邀请地址是宿主机的局域网地址，Android 模拟器可以出站访问。
2. 在宿主机上让 Android 模拟器把 iOS 侧的 Syncthing 监听端口（缺省 22000）反向映射到宿主机：
   ```
   adb reverse tcp:22000 tcp:22000
   ```
   这样 Android 模拟器内的 `127.0.0.1:22000` 即指向宿主机上的 iOS 模拟器。
3. 用覆盖地址启动 Android 侧的 debug 构建：
   ```
   flutter run -d emulator-5554 \
     --dart-define=YANJI_SYNC_PEERS=<iOS设备ID>=tcp://127.0.0.1:22000
   ```
4. 在「我的 → 同步」观察待同步/已确认条数，并核对双端记录一致。

## 边界

这是**调试手段，不是产品功能**：地址来自构建参数，仅在 debug 生效。

它可用于：配对后的操作文件交换、回执、去重、UI 同步状态、断线重连。

它**不能**替代真机验收：真实局域网发现（Bonjour/NSD）、Wi-Fi 切换、热点、
系统挂起/Doze、iOS 本地网络权限弹窗、公共中继行为仍需真机验证。

截至本文档，本机只完成了单元层验证（`transportPeers` 带出规范化地址，
见 [device_sync_reconnect_test.dart](/Users/goulijun/Documents/project/YANJI/test/application/device_sync_reconnect_test.dart)
与 [debug_peer_addresses_test.dart](/Users/goulijun/Documents/project/YANJI/test/protocol/debug_peer_addresses_test.dart)），
**未**跑通「Android 模拟器 ↔ iOS 模拟器」的端到端同步。
