import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});
  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  String? paired;
  Future<void> scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerPage()),
    );
    if (code == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认添加设备'),
        content: Text('检测到设备：${code.replaceFirst('yanji://device/', '')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认配对'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => paired = code.replaceFirst('yanji://device/', ''));
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('添加设备'),
      actions: [
        IconButton(
          tooltip: '扫描设备二维码',
          onPressed: scan,
          icon: const Icon(Icons.qr_code_scanner),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '已添加设备',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (paired == null)
          const Text('暂无已添加设备')
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.devices),
            title: Text(paired!),
            subtitle: const Text('可进行学习记录同步'),
            trailing: TextButton(
              onPressed: () => setState(() => paired = null),
              child: const Text('解除'),
            ),
          ),
        const SizedBox(height: 40),
        const Center(child: Text('本机设备二维码')),
        const SizedBox(height: 12),
        Center(
          child: QrImageView(
            data: 'yanji://device/yanji-local-device',
            size: 220,
          ),
        ),
        const SizedBox(height: 12),
        const Center(child: Text('使用另一台设备扫描此二维码')),
      ],
    ),
  );
}

class _ScannerPage extends StatelessWidget {
  const _ScannerPage();
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('扫描设备二维码')),
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.pop(c, 'yanji://device/demo-device'),
        child: const Text('模拟识别二维码'),
      ),
    ),
  );
}
