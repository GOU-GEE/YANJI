import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import 'package:bonsoir/bonsoir.dart';

/// Discovery records are untrusted connection hints, never trust credentials.
final class DiscoveredPeer {
  const DiscoveredPeer(this.deviceId, this.addresses, this.port);
  final String deviceId;
  final List<String> addresses;
  final int port;
}

abstract interface class LanPeerDiscovery {
  Future<void> advertise(String deviceId, int port);
  Future<List<DiscoveredPeer>> find(Set<String> deviceIds);
  Future<void> close();
}

/// Use native Bonjour/NSD so the OS tracks interface and address changes.
final class BonjourPeerDiscovery implements LanPeerDiscovery {
  static const serviceType = '_yanji-sync._tcp';
  BonsoirBroadcast? _broadcast;

  static String deviceHint(String deviceId) =>
      crypto.sha256.convert(utf8.encode(deviceId)).toString().substring(0, 32);

  @override
  Future<void> advertise(String deviceId, int port) async {
    await close();
    final broadcast = BonsoirBroadcast(
      printLogs: false,
      service: BonsoirService(
        name: 'YanJi-${deviceHint(deviceId)}',
        type: serviceType,
        port: port,
        attributes: {'hint': deviceHint(deviceId), 'protocol': '2'},
      ),
    );
    _broadcast = broadcast;
    await broadcast.initialize();
    await broadcast.start();
  }

  @override
  Future<List<DiscoveredPeer>> find(Set<String> deviceIds) async {
    if (deviceIds.isEmpty) return [];
    final discovery = BonsoirDiscovery(type: serviceType, printLogs: false);
    final idsByHint = {for (final id in deviceIds) deviceHint(id): id};
    final found = <String, DiscoveredPeer>{};
    final complete = Completer<void>();
    StreamSubscription<BonsoirDiscoveryEvent>? subscription;
    try {
      await discovery.initialize();
      subscription = discovery.eventStream!.listen(
        (event) {
          if ((event is BonsoirDiscoveryServiceFoundEvent ||
                  event is BonsoirDiscoveryServiceUpdatedEvent) &&
              event.service!.hostAddresses.isEmpty) {
            unawaited(
              event.service!
                  .resolve(discovery.serviceResolver)
                  .catchError((Object _) {}),
            );
          } else if (event is BonsoirDiscoveryServiceFoundEvent ||
              event is BonsoirDiscoveryServiceResolvedEvent ||
              event is BonsoirDiscoveryServiceUpdatedEvent) {
            final service = event.service!;
            final id = idsByHint[service.attributes['hint']];
            if (id != null &&
                deviceIds.contains(id) &&
                service.port > 0 &&
                service.port <= 65535 &&
                service.hostAddresses.isNotEmpty) {
              found[id] = DiscoveredPeer(
                id,
                service.hostAddresses,
                service.port,
              );
              if (found.length == deviceIds.length && !complete.isCompleted) {
                complete.complete();
              }
            }
          } else if (event is BonsoirDiscoveryServiceLostEvent) {
            found.remove(idsByHint[event.service.attributes['hint']]);
          }
        },
        onError: (Object _) {
          if (!complete.isCompleted) complete.complete();
        },
      );
      await discovery.start();
      await complete.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {},
      );
      return found.values.toList();
    } finally {
      await subscription?.cancel();
      if (discovery.isReady && !discovery.isStopped) await discovery.stop();
    }
  }

  @override
  Future<void> close() async {
    final broadcast = _broadcast;
    _broadcast = null;
    if (broadcast != null && broadcast.isReady && !broadcast.isStopped) {
      await broadcast.stop();
    }
  }
}
