import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../design/yanji_motion.dart';

import '../design/glass/glass_controls.dart';
import '../design/glass/glass_notice.dart';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../application/study_app_controller.dart';
import '../core/storage/platform_key_storage.dart';
import '../design/yanji_theme.dart';
import '../sync/pairing/device_pairing_coordinator.dart';
import '../sync/pairing/pairing_invite.dart';
import 'shared.dart';

class DevicePage extends StatefulWidget {
  const DevicePage(
    this.app, {
    super.key,
    this.coordinatorFactory,
    this.disposeCoordinator = true,
  });

  final StudyAppController app;
  final Future<DevicePairingCoordinator> Function()? coordinatorFactory;
  final bool disposeCoordinator;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_open());
    });
  }

  Future<T> _withPairingProgress<T>(
    String message,
    Future<T> Function() action,
  ) => withBlockingProgress(context, message, action);

  Future<void> _open() async {
    try {
      final value = await _withPairingProgress(
        '正在准备设备配对',
        () =>
            widget.coordinatorFactory?.call() ??
            DevicePairingCoordinator.open(
              widget.app,
              PlatformTlsIdentityStorage(),
            ),
      );
      if (!mounted) {
        if (widget.disposeCoordinator) await value.close();
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
      builder: (dialogContext) => GlassAlertDialog(
        title: const Text('确认新设备'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.deviceName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(switch (request.platform.toLowerCase()) {
              'android' => '安卓设备',
              'ios' => '苹果移动设备',
              'macos' => '苹果电脑',
              'windows' => '电脑',
              'linux' => '电脑',
              _ => '另一台设备',
            }, style: Theme.of(context).textTheme.bodySmall),
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
          GlassTextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('拒绝'),
          ),
          GlassFilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('安全码一致'),
          ),
        ],
      ),
    );
    if (approved == true) {
      request.approve();
      if (mounted) {
        final complete = await _withPairingProgress(
          '正在传送记录，等待另一台设备完成配对',
          () => request.completion,
        );
        if (mounted) {
          GlassNotice.show(
            context,
            complete ? '配对完成，记录已保存。' : '配对未完成，已有记录保留。请查看另一台设备的提示后重试。',
          );
        }
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
    final different =
        widget.app.workspace != null &&
        widget.app.workspace!.id != parsed.workspaceId;
    if (different) {
      if (widget.app.runningSession != null) {
        _showError(StateError('请先结束正在进行的计时，再合并配对'));
        return;
      }
      final merge = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => GlassAlertDialog(
          title: const Text('合并记录并配对'),
          content: const Text(
            '两台设备各有一个学习空间。将保留双方的科目、任务、学习时长和复盘，使用邀请设备的考试目标。本机原有学习空间也会保留。是否合并并配对？',
          ),
          actionBar: Row(
            children: [
              Expanded(
                child: GlassTextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const FittedBox(child: Text('取消')),
                ),
              ),
              const SizedBox(width: YanJiSpacing.xs),
              Expanded(
                child: GlassFilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const FittedBox(child: Text('保留记录')),
                ),
              ),
            ],
          ),
        ),
      );
      if (merge != true || !mounted) return;
    }
    setState(() => working = true);
    try {
      final session = await _withPairingProgress(
        '正在连接邀请设备',
        () => coordinator!.beginJoin(
          parsed,
          deviceName: _deviceName(),
          platform: Platform.operatingSystem,
          mergeExisting: different,
        ),
      );
      if (!mounted) {
        await session.cancel();
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => GlassAlertDialog(
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
            GlassTextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            GlassFilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('安全码一致'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _withPairingProgress('正在保存记录并完成配对', session.confirm);
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

  void _showError(Object caught) {
    final message = caught is SocketException
        ? '无法连接配对设备。首次配对请连接同一个 Wi-Fi，保持两端研迹打开，然后刷新配对口令重试。'
        : caught is TimeoutException
        ? '等待配对响应超时。请保持两端研迹打开，刷新配对口令后重试。'
        : caught.toString().replaceFirst(
            RegExp(r'^(Exception|StateError):\s*'),
            '',
          );
    GlassNotice.show(context, message);
  }

  static String _deviceName() {
    try {
      final value = Platform.localHostname.trim();
      if (value.isNotEmpty) return value;
    } catch (_) {}
    return '我的${Platform.operatingSystem}设备';
  }

  Widget _pairingAction({
    Key? key,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) => GlassOutlinedButton(
    key: key,
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 20), const SizedBox(width: 6), Text(label)],
      ),
    ),
  );

  @override
  void dispose() {
    clock?.cancel();
    unawaited(incomingSubscription?.cancel());
    final value = coordinator;
    if (value != null && widget.disposeCoordinator) {
      unawaited(value.close());
    }
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
    return PageBody(
      title: widget.app.isReady ? '设备与同步' : '从已有设备导入',
      maxWidth: YanJiLayout.form,
      children: [
        MotionSwap(
          identity: (error != null, widget.app.isReady),
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                EmptyMessage(
                  '无法启动设备配对',
                  '请检查本地网络和系统权限后重试。',
                  action: GlassFilledButton(
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
                Text(
                  '带回我的学习空间',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: YanJiSpacing.sm),
                const YanJiCaption(
                  '在已有研迹数据的设备上打开“我的”，点击“设备与同步”右侧加号，再扫描它显示的二维码。',
                ),
                const SizedBox(height: YanJiSpacing.xl),
                GlassFilledButton.icon(
                  key: const Key('scan-pairing-qr'),
                  onPressed: working || coordinator == null
                      ? null
                      : _scanAndJoin,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('扫描已有设备'),
                ),
                const SizedBox(height: YanJiSpacing.sm),
                GlassOutlinedButton.icon(
                  key: const Key('enter-pairing-code'),
                  onPressed: working || coordinator == null
                      ? null
                      : _enterAndJoin,
                  icon: const Icon(Icons.keyboard_outlined),
                  label: const Text('输入配对口令'),
                ),
                const SizedBox(height: YanJiSpacing.md),
                const YanJiCaption(
                  '首次配对请让两台设备连接同一个 Wi-Fi，并保持研迹打开。临时配对口令两分钟后失效且只能使用一次。配对完成后可在不同网络下自动同步。',
                ),
              ] else ...[
                Text(
                  '添加另一台设备',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: YanJiSpacing.sm),
                const YanJiCaption(
                  '首次配对请让两台设备连接同一个 Wi-Fi，并保持研迹打开。新设备扫描后，输入本页当前的临时配对口令并核对双端安全码。首次配对会同步全部历史；配对完成后可在不同网络下自动同步，也可点击我的页“设备与同步”右侧的“同步”等待完成。',
                ),
                const SizedBox(height: YanJiSpacing.lg),
                MotionSwap(
                  identity: currentCard?.deviceHint,
                  alignment: Alignment.center,
                  child: currentCard != null
                      ? Center(
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
                        )
                      : const EmptyMessage('正在准备设备二维码', '首次生成安全身份可能需要几秒。'),
                ),
                const SizedBox(height: YanJiSpacing.sm),
                Center(
                  child: Text(
                    remaining > 0
                        ? '临时配对口令：剩余 $remaining 秒 · 仅可使用一次'
                        : '临时配对口令已失效',
                  ),
                ),
                const SizedBox(height: YanJiSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _pairingAction(
                        key: const Key('refresh-pairing-code'),
                        onPressed: coordinator == null || working
                            ? null
                            : _newInvite,
                        icon: Icons.refresh,
                        label: remaining > 0 ? '刷新配对口令' : '生成配对口令',
                      ),
                    ),
                    const SizedBox(width: YanJiSpacing.sm),
                    Expanded(
                      child: _pairingAction(
                        key: const Key('scan-pairing-qr-ready'),
                        onPressed: working || coordinator == null
                            ? null
                            : _scanAndJoin,
                        icon: Icons.qr_code_scanner,
                        label: '扫描设备二维码',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: YanJiSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _pairingAction(
                        key: const Key('copy-pairing-code'),
                        onPressed: currentInvite == null || remaining <= 0
                            ? null
                            : () async {
                                await Clipboard.setData(
                                  ClipboardData(text: currentInvite.encode()),
                                );
                                if (context.mounted) {
                                  GlassNotice.show(context, '配对口令已复制，请勿转发给他人。');
                                }
                              },
                        icon: Icons.copy,
                        label: '复制配对口令',
                      ),
                    ),
                    const SizedBox(width: YanJiSpacing.sm),
                    Expanded(
                      child: _pairingAction(
                        key: const Key('enter-pairing-code'),
                        onPressed: working || coordinator == null
                            ? null
                            : _enterAndJoin,
                        icon: Icons.keyboard_outlined,
                        label: '输入配对口令',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
  Widget build(BuildContext context) => GlassAlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
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
    actionBar: Row(
      key: const Key('pairing-code-actions'),
      children: [
        Expanded(
          child: GlassTextButton(
            onPressed: _paste,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: EdgeInsets.zero,
            ),
            child: const Text('粘贴'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GlassTextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: EdgeInsets.zero,
            ),
            child: const Text('取消'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GlassFilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: EdgeInsets.zero,
            ),
            child: const Text('连接'),
          ),
        ),
      ],
    ),
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
    appBar: GlassAppBar(
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
