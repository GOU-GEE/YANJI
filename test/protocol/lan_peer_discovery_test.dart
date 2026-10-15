import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/sync/transport/lan_peer_discovery.dart';

class _Action<T extends BonsoirEvent> implements BonsoirAction<T> {
  final events = StreamController<T>.broadcast();
  @override
  bool isReady = false;
  @override
  bool isStopped = false;
  @override
  Stream<T> get eventStream => events.stream;
  @override
  Future<void> initialize() async {
    isReady = true;
  }

  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {
    isStopped = true;
    await events.close();
  }
}

class _Browse extends _Action<BonsoirDiscoveryEvent> with ServiceResolver {
  final resolvedNames = <String>[];
  BonsoirService service(
    String id,
    int port, {
    List<String> addresses = const ['127.0.0.1'],
  }) => BonsoirService(
    name: id,
    type: BonjourPeerDiscovery.serviceType,
    port: port,
    hostAddresses: addresses,
    attributes: {'hint': BonjourPeerDiscovery.deviceHint(id)},
  );
  @override
  Future<void> start() async {
    events.add(
      BonsoirDiscoveryServiceFoundEvent(
        service: service('known', 4000, addresses: []),
      ),
    );
  }

  @override
  Future<void> resolveService(BonsoirService found) async {
    resolvedNames.add(found.name);
    events.add(
      BonsoirDiscoveryServiceResolvedEvent(service: service('unknown', 8000)),
    );
    events.add(
      BonsoirDiscoveryServiceResolvedEvent(service: service('pending', 0)),
    );
    events.add(
      BonsoirDiscoveryServiceResolvedEvent(
        service: service('pending', 4001, addresses: []),
      ),
    );
    events.add(
      BonsoirDiscoveryServiceResolvedEvent(service: service('known', 4000)),
    );
    events.add(
      BonsoirDiscoveryServiceLostEvent(service: service('known', 4000)),
    );
    events.add(
      BonsoirDiscoveryServiceUpdatedEvent(service: service('known', 4002)),
    );
    events.add(
      BonsoirDiscoveryServiceResolvedEvent(service: service('pending', 4003)),
    );
  }

  @override
  bool supportsMdnsHostname() => false;
}

class _Platform extends BonsoirPlatformInterface {
  final broadcasts = <(_Action<BonsoirBroadcastEvent>, BonsoirService)>[];
  final browse = _Browse();
  @override
  BonsoirAction<BonsoirBroadcastEvent> createBroadcastAction(
    BonsoirService service, {
    bool printLogs = false,
  }) {
    final action = _Action<BonsoirBroadcastEvent>();
    broadcasts.add((action, service));
    return action;
  }

  @override
  BonsoirAction<BonsoirDiscoveryEvent> createDiscoveryAction(
    String type, {
    bool printLogs = false,
  }) {
    expect(type, BonjourPeerDiscovery.serviceType);
    return browse;
  }
}

void main() {
  test('native discovery resolves fresh addresses, filters records and disposes sessions', () async {
    final original = BonsoirPlatformInterface.instance;
    final platform = _Platform();
    BonsoirPlatformInterface.instance = platform;
    final discovery = BonjourPeerDiscovery();
    try {
      await discovery.advertise('self', 4000);
      await discovery.advertise('self', 5000);
      expect(platform.broadcasts.first.$1.isStopped, isTrue);
      expect(platform.broadcasts.last.$2.port, 5000);
      expect(
        platform.broadcasts.last.$2.attributes['hint'],
        BonjourPeerDiscovery.deviceHint('self'),
      );
      final peers = await discovery.find({'known', 'pending'});
      expect(peers.map((p) => p.deviceId), ['known', 'pending']);
      expect(peers.map((p) => p.port), [4002, 4003]);
      expect(platform.browse.resolvedNames, ['known']);
      expect(platform.browse.isStopped, isTrue);
    } finally {
      await discovery.close();
      BonsoirPlatformInterface.instance = original;
    }
    expect(platform.broadcasts.last.$1.isStopped, isTrue);
  });
}
