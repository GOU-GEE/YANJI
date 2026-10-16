# 鸿蒙设备验收记录（2026-10-16）

环境：官方 Command Line Tools 26.0.0.851 / API 26，Flutter OHOS
3.41.9+ohos-1.0.2 / Dart 3.11.5；HarmonyOS 7.0.0.107 ARM64 手机模拟器。
使用项目独立工具环境，无全局 Flutter 配置变更。官方未签名 HAP 可正常安装到该模拟器。

## 已通过

`integration_test/harmonyos_local_smoke_test.dart`：实际运行多次，关闭并重新
启动应用进程后，设备 ID、Ed25519 公钥和 TLS 证书指纹保持一致。
HUKS 加解密、签名验证、数据库背景 isolate 原生库加载、WAL/FULL、创建目标及任务、
学习/暂停/继续、复盘保存、统计时间、v4→v5 迁移、数据库 integrity_check 全部通过。
用例使用独立验收数据库，不污染正式 `yanji.sqlite`。

设备测试修正了 HUKS 的一个真实接口差异：`isKeyItemExist` 在不存在时
抛出官方错误码 12000011，首次生成只对这个码处理；其他错误继续报错。

`integration_test/harmonyos_crash_recovery_test.dart`：首轮在学习中保留打开的
数据库连接，写入 7 秒持久化 checkpoint 后等待；通过官方 `aa force-stop`
终止进程，再启动应用。恢复后仅保留 checkpoint 内的 7 秒，不累计关闭期间
的时间，任务记录仍在，数据库完整性检查通过。

`integration_test/harmonyos_dart_sync_test.dart`（配合主机侧
`tool/probes/harmonyos_peer_harness_test.dart`）：鸿蒙模拟器与 macOS 主机完成
认证配对、双向记录传输和回执确认，设备输出 `YANJI_HARMONY_CROSS_SYNC_PASS`，
主机输出 `YANJI_HOST_CROSS_SYNC_PASS`。该用例走的是鸿蒙首版选定的 Dart TLS
同步后端，不加载内嵌 Syncthing。

`integration_test/harmonyos_scanner_test.dart`：设备内用 `qr_flutter` 生成
配对二维码 PNG，再交给 `mobile_scanner` 的鸿蒙实现解码，输出
`YANJI_HARMONY_QR_DECODE_PASS`。

完整 App（未签名 HAP）在模拟器上跑通正式界面：Onboarding 三步选择
2027 考研 / 4 个科目 / 跳过可选目标 → 今日页显示倒计时与今日任务；`aa force-stop`
后重新启动直接进入今日页（重启前后截图 hash 一致），说明工作区与科目已落库。
设备日志中无 `EXCEPTION CAUGHT`。

主机侧：`flutter analyze --no-pub` 无问题，`flutter test --no-pub` 235 项全部通过。

界面证据（同一台 API 26 ARM64 模拟器）：

| 截图 | 说明 |
| --- | --- |
| `screenshots/01-onboarding-goal.png` | 正式界面第 1 步，中文字形与主题正常 |
| `screenshots/02-onboarding-subjects.png` | 第 2 步科目选择，状态随步骤保留 |
| `screenshots/03-today-after-restart.png` | `aa force-stop` 后重新启动，直接进入今日页 |
| `screenshots/04-profile-sync.png` | 我的页面：设备与同步在本机未配对时的状态 |

## 重现

先在一次性模拟器中解锁屏幕。模拟器实例使用 6 GB 存储、4 GB 内存，
显式 `-hdcPort 10000`；较大存储配置可能触发本机可用空间检查。

```sh
tool/build_harmonyos_unsigned.sh integration_test/harmonyos_local_smoke_test.dart
# hdc -t <device> install -r ohos/entry/build/default/outputs/default/entry-default-unsigned.hap
# hdc -t <device> shell aa start -a EntryAbility -b com.example.yanji
```

从设备日志确认 `YANJI_HARMONY_SMOKE_PASS` 与 `All tests passed!`，
然后 force-stop 并重新启动，确认 runs 递增和公钥指纹不变。

终止恢复使用第二个用例构建，等待日志出现
`YANJI_HARMONY_READY_FOR_FORCE_STOP` 后再终止；重启应输出
`YANJI_HARMONY_CRASH_RECOVERY_PASS`。重复首轮需换新的验收目录或新模拟器。

跨端同步需要主机与模拟器同时在线。主机先跑
`tool/flutter_ohos.sh test --no-pub tool/probes/harmonyos_peer_harness_test.dart`
（输出 `YANJI_HOST_READY` 并写出 `work/harmonyos/cross-device-invite.txt`，随后等待
约 4 分钟），再把邀请串作为 dart-define 编入设备包：

```sh
export YANJI_DART_DEFINES=$(python3 -c 'import base64,pathlib;print(base64.b64encode(("YANJI_PEER_INVITE="+pathlib.Path("work/harmonyos/cross-device-invite.txt").read_text().strip()).encode()).decode())')
tool/build_harmonyos_unsigned.sh integration_test/harmonyos_dart_sync_test.dart
```

主机监听 `anyIPv4` 并向设备公布 `10.0.2.2`（QEMU 的宿主别名），因此模拟器侧无需
额外端口转发。扫码用例只需
`tool/build_harmonyos_unsigned.sh integration_test/harmonyos_scanner_test.dart`。

## 待验收

真机签名、最低支持系统 5.0.5(17)、系统后台与功耗策略、真机摄像头扫码、
跨机型局域网发现与长时间双向同步、系统实时通知，以及密文损坏/密钥不可用的
设备故障注入。主机错误传播测试不能替代设备故障注入。当前结果不代表已经达到
上架条件。
