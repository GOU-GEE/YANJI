import 'package:flutter/material.dart';

import '../platform/study_live_activity.dart';

/// Debug-only capability and lifecycle surface for the HONOR adapter.
class HonorMagicCapsuleDebugPage extends StatefulWidget {
  const HonorMagicCapsuleDebugPage({super.key});

  @override
  State<HonorMagicCapsuleDebugPage> createState() =>
      _HonorMagicCapsuleDebugPageState();
}

class _HonorMagicCapsuleDebugPageState
    extends State<HonorMagicCapsuleDebugPage> {
  Map<Object?, Object?>? _result;
  bool _busy = false;

  Future<void> _refresh() async {
    setState(() => _busy = true);
    final result = await StudyLiveActivity.checkHonorMagicCapsuleSupport();
    if (!mounted) return;
    setState(() {
      _result = result;
      _busy = false;
    });
  }

  Future<void> _run(String action) async {
    setState(() => _busy = true);
    final result = await StudyLiveActivity.debugHonorMagicCapsule(action);
    if (!mounted) return;
    setState(() {
      _result = result;
      _busy = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final capability =
        _result?['capability'] as Map<Object?, Object?>? ?? _result;
    const labels = <String, String>{
      'manufacturer': 'Manufacturer',
      'brand': 'Brand',
      'model': 'Model',
      'androidVersion': 'Android',
      'magicOsVersion': 'MagicOS',
      'suggestionsKitAvailable': 'Suggestions Kit',
      'permissionStatus': 'Data-feedback permission',
      'globalReachEnabled': 'YOYO globalReach',
      'sceneApproved': 'Scene approved',
      'dataConsentGranted': 'YANJI data consent',
      'stateContractApproved': 'State schema approved',
      'stateMapperReady': 'State mapper implemented',
      'selectedAdapter': 'Selected adapter',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('HONOR 灵动胶囊调试'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新能力状态',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          const Text('此页面只检查适配和生命周期入口。当前没有获批的学习场景，调试操作不会伪造外卖、出行等事件。'),
          const SizedBox(height: 16),
          if (capability != null)
            ...labels.entries.map(
              (entry) => ListTile(
                dense: true,
                title: Text(entry.value),
                subtitle: Text('${capability[entry.key] ?? 'unknown'}'),
              ),
            )
          else
            const ListTile(
              title: Text('尚未取得能力信息'),
              subtitle: Text('请在 Android 设备上打开此调试页。'),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _action('开始', 'start'),
              _action('更新', 'update'),
              _action('暂停', 'pause'),
              _action('恢复', 'resume'),
              _action('恢复状态', 'restore'),
              _action('完成', 'complete'),
              _action('取消', 'cancel'),
            ],
          ),
          if (_result?['dispatched'] != null) ...[
            const SizedBox(height: 12),
            Text('系统反馈已发送：${_result!['dispatched']}'),
          ],
        ],
      ),
    );
  }

  Widget _action(String label, String action) => OutlinedButton(
    onPressed: _busy ? null : () => _run(action),
    child: Text(label),
  );
}
