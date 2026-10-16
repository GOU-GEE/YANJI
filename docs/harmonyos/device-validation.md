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

## 待验收

真机签名、最低支持系统 5.0.5(17)、系统后台与功耗策略、扫码摄像头权限、
跨设备网络发现与双向同步、系统实时通知，以及密文损坏/密钥不可用的设备故障注入。
主机错误传播测试不能替代设备故障注入。当前结果不代表已经达到上架条件。
