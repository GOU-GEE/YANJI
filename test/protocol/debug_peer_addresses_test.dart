import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/sync/pairing/debug_peer_addresses.dart';

void main() {
  test('parses device=address pairs and normalizes the Syncthing form', () {
    final parsed = DebugPeerAddresses.parse(
      ' 01991f82-aaaa = 10.0.2.2 , 01991f82-bbbb=tcp://127.0.0.1:22001; bad ',
    );
    expect(parsed, {
      '01991f82-aaaa': 'tcp://10.0.2.2:22000',
      '01991f82-bbbb': 'tcp://127.0.0.1:22001',
    });
  });

  test('normalizes addresses without a scheme or port', () {
    expect(
      DebugPeerAddresses.normalize('192.168.1.5'),
      'tcp://192.168.1.5:22000',
    );
    expect(
      DebugPeerAddresses.normalize('tcp://192.168.1.5'),
      'tcp://192.168.1.5:22000',
    );
    expect(
      DebugPeerAddresses.normalize('tcp://192.168.1.5:22001'),
      'tcp://192.168.1.5:22001',
    );
    expect(
      DebugPeerAddresses.normalize('tcp://[::1]:22001'),
      'tcp://[::1]:22001',
    );
    expect(DebugPeerAddresses.normalize('  '), '');
  });

  test('resolves exact IDs before the longest matching prefix', () {
    final overrides = {
      '01991f82': 'tcp://10.0.0.1:22000',
      '01991f82-aaaa': 'tcp://10.0.0.2:22000',
      '01991f82-aaaa-7000-8000-000000000001': 'tcp://10.0.0.3:22000',
    };
    expect(
      DebugPeerAddresses.resolve(
        overrides,
        '01991f82-aaaa-7000-8000-000000000001',
      ),
      'tcp://10.0.0.3:22000',
    );
    expect(
      DebugPeerAddresses.resolve(
        overrides,
        '01991f82-aaaa-7000-8000-000000000002',
      ),
      'tcp://10.0.0.2:22000',
    );
    expect(DebugPeerAddresses.resolve(overrides, 'ffffffff'), isNull);
  });
}
