import 'dart:async';

import 'package:flutter/material.dart';

import '../platform/study_live_activity.dart';

/// One debug surface for the existing Android ongoing-activity adapters.
class OppoFluidCloudDebugPage extends StatefulWidget {
  const OppoFluidCloudDebugPage({super.key});

  @override
  State<OppoFluidCloudDebugPage> createState() =>
      _OppoFluidCloudDebugPageState();
}

class _OppoFluidCloudDebugPageState extends State<OppoFluidCloudDebugPage> {
  Map<Object?, Object?>? oppoCapability;
  Map<Object?, Object?>? xiaomiCapability;
  Map<Object?, Object?>? oppoLastResult;
  Map<Object?, Object?>? xiaomiLastResult;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(checkSupport());
  }

  Future<void> checkSupport() async {
    setState(() => busy = true);
    final results = await Future.wait([
      StudyLiveActivity.checkOppoFluidCloudSupport(),
      StudyLiveActivity.checkXiaomiFocusSupport(),
    ]);
    if (!mounted) return;
    setState(() {
      oppoCapability = results[0];
      xiaomiCapability = results[1];
      oppoLastResult = null;
      xiaomiLastResult = null;
      busy = false;
    });
  }

  Future<void> runAction(String action, {required bool xiaomi}) async {
    setState(() => busy = true);
    final result = xiaomi
        ? await StudyLiveActivity.debugXiaomiSuperIsland(action)
        : await StudyLiveActivity.debugOppoFluidCloud(action);
    if (!mounted) return;
    setState(() {
      if (xiaomi) {
        xiaomiLastResult = result;
      } else {
        oppoLastResult = result;
      }
      busy = false;
    });
  }

  String value(Map<Object?, Object?>? source, String key) {
    final item = source?[key];
    if (item == null) return '未检测';
    if (item is bool) return item ? '支持' : '不支持';
    return item.toString().isEmpty ? '—' : item.toString();
  }

  String protocolValue() {
    final version = xiaomiCapability?['protocolVersion'];
    if (version == 2) return 'HyperOS 2 / 焦点通知';
    if (version == 3) return 'HyperOS 3 / 小米超级岛';
    return version == null ? '未检测' : '不支持（$version）';
  }

  Widget statusLine(
    String label,
    String key, {
    Map<Object?, Object?>? source,
    String? overrideValue,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            overrideValue ?? value(source, key),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget actionButton(String label, String action, {required bool xiaomi}) =>
      OutlinedButton(
        onPressed: busy ? null : () => runAction(action, xiaomi: xiaomi),
        child: Text(label),
      );

  Widget resultDetails(Map<Object?, Object?>? result, {required bool xiaomi}) {
    if (result == null) return const SizedBox.shrink();
    final sent = result['dispatched'] == true;
    final reason = result['reason']?.toString();
    final message = sent
        ? '调试通知已发送；是否进入系统界面仍需真机确认。'
        : xiaomi && reason == 'business_not_approved'
        ? '尚未配置小米批准的 business 场景，因此没有发送焦点通知。'
        : '请求未发送：${reason ?? '检查设备能力和接入配置。'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text('最近请求：${result['status'] ?? '—'}'),
        Text(message),
        if (result['notificationId'] != null)
          Text('Notification ID：${result['notificationId']}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('实时活动调试')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xiaomi / HyperOS',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                statusLine(
                  '设备',
                  'manufacturer',
                  source: xiaomiCapability,
                  overrideValue:
                      '${value(xiaomiCapability, 'manufacturer')} / '
                      '${value(xiaomiCapability, 'brand')}',
                ),
                statusLine(
                  '协议与适配器',
                  'protocolVersion',
                  source: xiaomiCapability,
                  overrideValue: protocolValue(),
                ),
                statusLine(
                  '焦点通知权限',
                  'focusPermission',
                  source: xiaomiCapability,
                ),
                statusLine(
                  'Android 通知权限',
                  'androidNotificationPermission',
                  source: xiaomiCapability,
                ),
                statusLine(
                  '超级岛系统能力',
                  'islandFeatureSupported',
                  source: xiaomiCapability,
                ),
                statusLine(
                  '场景已配置',
                  'businessConfigured',
                  source: xiaomiCapability,
                ),
                statusLine(
                  '已选 Adapter',
                  'selectedAdapter',
                  source: xiaomiCapability,
                ),
                statusLine(
                  'Notification ID',
                  'notificationId',
                  source: xiaomiCapability,
                ),
                statusLine(
                  'Activity ID',
                  'activityId',
                  source: xiaomiCapability,
                ),
                statusLine('检测结果', 'reason', source: xiaomiCapability),
                if ((xiaomiCapability?['error'] as String?)?.isNotEmpty ??
                    false)
                  Text('检测错误：${xiaomiCapability!['error']}'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    actionButton('创建', 'create', xiaomi: true),
                    actionButton('更新', 'update', xiaomi: true),
                    actionButton('进度', 'progress', xiaomi: true),
                    actionButton('暂停', 'pause', xiaomi: true),
                    actionButton('恢复', 'resume', xiaomi: true),
                    actionButton('完成', 'complete', xiaomi: true),
                    actionButton('取消', 'cancel', xiaomi: true),
                  ],
                ),
                resultDetails(xiaomiLastResult, xiaomi: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPPO 流体云',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                statusLine('厂商', 'manufacturer', source: oppoCapability),
                statusLine(
                  'Seedling 泛在服务',
                  'seedlingSupported',
                  source: oppoCapability,
                ),
                statusLine(
                  '系统意图',
                  'systemIntentSupported',
                  source: oppoCapability,
                ),
                statusLine(
                  'Fluid Cloud',
                  'fluidCloudSupported',
                  source: oppoCapability,
                ),
                statusLine('项目配置已齐全', 'appConfigured', source: oppoCapability),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    actionButton('创建', 'create', xiaomi: false),
                    actionButton('更新', 'update', xiaomi: false),
                    actionButton('进度', 'progress', xiaomi: false),
                    actionButton('暂停', 'pause', xiaomi: false),
                    actionButton('恢复', 'resume', xiaomi: false),
                    actionButton('完成', 'complete', xiaomi: false),
                    actionButton('取消', 'cancel', xiaomi: false),
                    actionButton('移除', 'remove', xiaomi: false),
                  ],
                ),
                resultDetails(oppoLastResult, xiaomi: false),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: busy ? null : checkSupport,
            icon: const Icon(Icons.refresh),
            label: const Text('重新检测'),
          ),
        ),
        const Text('调试状态使用固定测试 ID，不写入学习记录。小米场景未获批时，Xiaomi 调试不会发送焦点通知。'),
        if (busy) const LinearProgressIndicator(),
      ],
    ),
  );
}
