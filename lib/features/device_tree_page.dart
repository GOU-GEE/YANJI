import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../application/study_app_controller.dart';
import '../core/storage/platform_key_storage.dart';
import '../design/yanji_theme.dart';
import '../sync/pairing/device_pairing_coordinator.dart';
import '../sync/pairing/pairing_invite.dart';
import '../sync/trust/trust_chain.dart';
import 'shared.dart';

class DevicePage extends StatefulWidget {
  const DevicePage(this.app, {super.key, this.coordinatorFactory});

  final StudyAppController app;
  final Future<DevicePairingCoordinator> Function()? coordinatorFactory;

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  DevicePairingCoordinator? coordinator;
  PairingInvite? invite;
  PairingCard? card;
  StreamSubscription<IncomingPairRequest>? incomingSubscription;
  Timer? clock;
  Object? error;
  bool working = true;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final value =
          await (widget.coordinatorFactory?.call() ??
              DevicePairingCoordinator.open(
                widget.app,
                PlatformTlsIdentityStorage(),
              ));
      if (!mounted) {
        await value.close();
        return;
      }
      coordinator = value;
      incomingSubscription = value.incomingRequests.stream.listen(
        _reviewRequest,
      );
      clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      if (widget.app.isReady) await _newInvite();
      if (mounted) setState(() => working = false);
    } catch (caught) {
      final value = coordinator;
      coordinator = null;
      if (value != null) await value.close();
      if (mounted) {
        setState(() {
          error = caught;
          working = false;
        });
      }
    }
  }

  Future<void> _newInvite() async {
    final value = await coordinator!.createInvitation();
    if (mounted) {
      setState(() {
        invite = value;
        card ??= value.card;
      });
    }
  }

  Future<void> _reviewRequest(IncomingPairRequest request) async {
    if (!mounted) {
      request.reject();
      return;
    }
    setState(() => invite = null);
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认新设备'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.deviceName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              request.platform,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: YanJiSpacing.lg),
            const Text('请确认两台设备显示的安全码完全相同：'),
            const SizedBox(height: YanJiSpacing.sm),
            Center(
              child: SelectableText(
                request.safetyCode,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: YanJiSpacing.md),
            const YanJiCaption('只有你正在操作另一台设备且安全码一致时才允许。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('拒绝'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('安全码一致'),
          ),
        ],
      ),
    );
    if (approved == true) {
      request.approve();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('设备已添加，正在发送完整学习记录。')));
      }
    } else {
      request.reject();
    }
  }

  Future<void> _scanAndJoin() async {
    final raw = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerPage()),
    );
    if (raw == null || !mounted) return;
    PairingCard scanned;
    try {
      scanned = PairingCard.decode(raw);
    } catch (caught) {
      _showError(caught);
      return;
    }
    final code = await _pasteInvite(
      title: '输入临时配对口令',
      detail: '二维码只确认设备身份。请再输入该设备当前显示的临时配对口令。',
    );
    if (code == null || !mounted) return;
    await _join(code, expectedCard: scanned);
  }

  Future<void> _enterAndJoin() async {
    final raw = await _pasteInvite(
      title: '输入配对口令',
      detail: '可直接粘贴另一台设备复制的完整临时配对口令。',
    );
    if (raw == null || !mounted) return;
    await _join(raw);
  }

  Future<void> _join(String raw, {PairingCard? expectedCard}) async {
    PairingInvite parsed;
    try {
      parsed = PairingInvite.decode(
        raw,
        nowMs: DateTime.now().millisecondsSinceEpoch,
      );
      if (expectedCard != null && !expectedCard.matches(parsed)) {
        throw const FormatException('配对口令不属于刚才扫描的设备');
      }
    } catch (caught) {
      _showError(caught);
      return;
    }
    setState(() => working = true);
    try {
      final session = await coordinator!.beginJoin(
        parsed,
        deviceName: _deviceName(),
        platform: Platform.operatingSystem,
      );
      if (!mounted) {
        await session.cancel();
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('核对安全码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请核对已有设备上显示的安全码：'),
              const SizedBox(height: YanJiSpacing.lg),
              SelectableText(
                session.safetyCode,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: YanJiSpacing.md),
              const YanJiCaption('安全码不同可能表示连接被冒充，请立即取消。'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('安全码一致'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await session.confirm();
        if (mounted) context.go('/');
      } else {
        await session.cancel();
      }
    } catch (caught) {
      if (mounted) _showError(caught);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<String?> _pasteInvite({
    required String title,
    required String detail,
  }) => showDialog<String>(
    context: context,
    builder: (_) => _PairingCodeDialog(title: title, detail: detail),
  );

  Future<void> _revoke(TrustedPeer peer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('撤销“${peer.deviceName}”？'),
        content: const Text('撤销是永久操作。该设备之后产生的记录将不再被信任；设备丢失时也应立即撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('永久撤销'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.app.revokeTrustedPeer(peer);
      if (mounted) setState(() {});
    } catch (caught) {
      if (mounted) _showError(caught);
    }
  }

  void _showError(Object caught) {
    final message = caught.toString().replaceFirst(
      RegExp(r'^(Exception|StateError):\s*'),
      '',
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static String _deviceName() {
    try {
      final value = Platform.localHostname.trim();
      if (value.isNotEmpty) return value;
    } catch (_) {}
    return '我的${Platform.operatingSystem}设备';
  }

  @override
  void dispose() {
    clock?.cancel();
    unawaited(incomingSubscription?.cancel());
    final value = coordinator;
    if (value != null) unawaited(value.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentInvite = invite;
    final currentCard = card;
    final remaining = currentInvite == null
        ? 0
        : ((currentInvite.expiresAtMs - DateTime.now().millisecondsSinceEpoch) /
                  1000)
              .ceil()
              .clamp(0, PairingInvite.lifetime.inSeconds);
    final peers = widget.app.trustedPeers
        .where((peer) => peer.deviceId != widget.app.identity.deviceId)
        .toList();
    return PageBody(
      title: widget.app.isReady ? '设备与同步' : '从已有设备导入',
      maxWidth: YanJiLayout.form,
      children: [
        if (working) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: YanJiSpacing.lg),
        ],
        if (error != null) ...[
          EmptyMessage(
            '无法启动设备配对',
            '请检查本地网络和系统权限后重试。',
            action: FilledButton(
              onPressed: () {
                setState(() {
                  error = null;
                  working = true;
                });
                unawaited(_open());
              },
              child: const Text('重试'),
            ),
          ),
        ] else if (!widget.app.isReady) ...[
          Text('带回我的学习空间', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: YanJiSpacing.sm),
          const YanJiCaption('在已有研迹数据的设备上打开“我的 → 设备与同步”，再扫描它显示的二维码。'),
          const SizedBox(height: YanJiSpacing.xl),
          FilledButton.icon(
            key: const Key('scan-pairing-qr'),
            onPressed: working || coordinator == null ? null : _scanAndJoin,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('扫描已有设备'),
          ),
          const SizedBox(height: YanJiSpacing.sm),
          OutlinedButton.icon(
            key: const Key('enter-pairing-code'),
            onPressed: working || coordinator == null ? null : _enterAndJoin,
            icon: const Icon(Icons.keyboard_outlined),
            label: const Text('输入配对口令'),
          ),
          const SizedBox(height: YanJiSpacing.md),
          const YanJiCaption('设备二维码保持不变；临时配对口令两分钟后失效且只能使用一次。连接还会核验证书指纹和双端安全码。'),
        ] else ...[
          Text('添加另一台设备', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: YanJiSpacing.sm),
          const YanJiCaption('设备二维码保持不变。新设备扫描后，再输入本页当前的临时配对口令并核对双端安全码。'),
          const SizedBox(height: YanJiSpacing.lg),
          if (currentCard != null) ...[
            Center(
              child: Semantics(
                label: '本机固定设备二维码',
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(YanJiSpacing.sm),
                  child: QrImageView(
                    key: ValueKey(currentCard.deviceHint),
                    data: currentCard.encode(),
                    size: 240,
                  ),
                ),
              ),
            ),
          ] else ...[
            const EmptyMessage('正在准备设备二维码', '首次生成安全身份可能需要几秒。'),
          ],
          const SizedBox(height: YanJiSpacing.sm),
          Center(
            child: Text(
              remaining > 0 ? '临时配对口令：剩余 $remaining 秒 · 仅可使用一次' : '临时配对口令已失效',
            ),
          ),
          const SizedBox(height: YanJiSpacing.md),
          OutlinedButton.icon(
            onPressed: coordinator == null || working ? null : _newInvite,
            icon: const Icon(Icons.refresh),
            label: Text(remaining > 0 ? '刷新配对口令' : '生成配对口令'),
          ),
          if (currentInvite != null && remaining > 0) ...[
            const SizedBox(height: YanJiSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: currentInvite.encode()),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('配对口令已复制，请勿转发给他人。')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('复制配对口令'),
            ),
          ],
          const SizedBox(height: YanJiSpacing.sm),
          OutlinedButton.icon(
            key: const Key('enter-pairing-code'),
            onPressed: working || coordinator == null ? null : _enterAndJoin,
            icon: const Icon(Icons.keyboard_outlined),
            label: const Text('输入配对口令'),
          ),
          const Divider(height: YanJiSpacing.xxl),
          Text('已授权设备', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: YanJiSpacing.sm),
          if (peers.isEmpty)
            const YanJiCaption('暂无其他设备。')
          else
            for (final peer in peers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(peer.active ? Icons.devices : Icons.block),
                title: Text(peer.deviceName),
                subtitle: Text(
                  peer.active ? '${peer.platform} · 已授权' : '已永久撤销',
                ),
                trailing: peer.active
                    ? TextButton(
                        onPressed: () => _revoke(peer),
                        child: const Text('撤销'),
                      )
                    : null,
              ),
        ],
      ],
    );
  }
}

class _PairingCodeDialog extends StatefulWidget {
  const _PairingCodeDialog({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  State<_PairingCodeDialog> createState() => _PairingCodeDialogState();
}

class _PairingCodeDialogState extends State<_PairingCodeDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    controller.text = clipboard?.text?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        YanJiCaption(widget.detail),
        const SizedBox(height: YanJiSpacing.md),
        TextField(
          key: const Key('pairing-code-input'),
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'yanji://pair-code…'),
        ),
      ],
    ),
    actions: [
      TextButton.icon(
        onPressed: _paste,
        icon: const Icon(Icons.content_paste),
        label: const Text('粘贴'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text.trim()),
        child: const Text('连接'),
      ),
    ],
  );
}

class _ScannerPage extends StatefulWidget {
  const _ScannerPage();

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool handled = false;

  Future<void> _detected(BarcodeCapture capture) async {
    if (handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || !raw.startsWith('yanji://pair?')) continue;
      handled = true;
      await controller.stop();
      if (mounted) Navigator.pop(context, raw);
      return;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('扫描设备二维码'),
      actions: [
        IconButton(
          tooltip: '开关闪光灯',
          onPressed: controller.toggleTorch,
          icon: const Icon(Icons.flashlight_on_outlined),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: controller, onDetect: _detected),
        Center(
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(YanJiRadius.card),
              ),
            ),
          ),
        ),
        const SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(YanJiSpacing.lg),
              child: Text(
                '将另一台设备的研迹二维码放入框内',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
