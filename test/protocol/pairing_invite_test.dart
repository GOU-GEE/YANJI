import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/sync/pairing/pairing_invite.dart';
import 'package:yanji/sync/protocol/deterministic_cbor.dart';

void main() {
  const workspace = '01991f82-0000-7000-8000-000000000101';
  const inviter = '01991f82-0000-7000-8000-000000000102';
  const inviteId = '01991f82-0000-7000-8000-000000000103';
  final bytes32 = Uint8List.fromList(List<int>.generate(32, (i) => i));

  PairingInvite invite({int expiresAtMs = 120000}) => PairingInvite(
    workspaceId: workspace,
    workspaceGenesisHash: bytes32,
    inviteId: inviteId,
    inviterDeviceId: inviter,
    identityPublicKey: Uint8List.fromList(bytes32.reversed.toList()),
    tlsCertificateSha256: Uint8List.fromList(bytes32),
    pairSecret: Uint8List.fromList(List<int>.filled(32, 7)),
    port: 48173,
    expiresAtMs: expiresAtMs,
    ipHints: const ['192.168.1.12', 'fe80::1'],
  );

  test('YPP/2 temporary token round trips every authenticated field', () {
    final original = invite();
    final parsed = PairingInvite.decode(original.encode(), nowMs: 1);
    expect(parsed.workspaceId, workspace);
    expect(parsed.inviteId, inviteId);
    expect(parsed.inviterDeviceId, inviter);
    expect(parsed.workspaceGenesisHash, original.workspaceGenesisHash);
    expect(parsed.identityPublicKey, original.identityPublicKey);
    expect(parsed.tlsCertificateSha256, original.tlsCertificateSha256);
    expect(parsed.pairSecret, original.pairSecret);
    expect(parsed.port, 48173);
    expect(parsed.ipHints, ['192.168.1.12', 'fe80::1']);
  });

  test('expired, overlong, malformed and extended tokens are rejected', () {
    expect(
      () => PairingInvite.decode(invite(expiresAtMs: 100).encode(), nowMs: 100),
      throwsFormatException,
    );
    expect(
      () =>
          PairingInvite.decode(invite(expiresAtMs: 120001).encode(), nowMs: 0),
      throwsFormatException,
    );
    expect(
      () => PairingInvite.decode('yanji://device/demo', nowMs: 0),
      throwsFormatException,
    );
    final raw = invite().encode().split('data=').last;
    final map = Map<String, Object?>.from(
      DeterministicCbor.decode(base64Url.decode(base64Url.normalize(raw)))!
          as Map<String, Object?>,
    )..['unexpected'] = true;
    final extended = base64Url
        .encode(DeterministicCbor.encode(map))
        .replaceAll('=', '');
    expect(
      () => PairingInvite.decode(
        'yanji://pair-code?v=2&data=$extended',
        nowMs: 1,
      ),
      throwsFormatException,
    );
  });

  test('stable device QR excludes rotating invitation material', () {
    final first = invite();
    final second = PairingInvite(
      workspaceId: first.workspaceId,
      workspaceGenesisHash: first.workspaceGenesisHash,
      inviteId: '01991f82-0000-7000-8000-000000000104',
      inviterDeviceId: first.inviterDeviceId,
      identityPublicKey: first.identityPublicKey,
      tlsCertificateSha256: first.tlsCertificateSha256,
      pairSecret: Uint8List.fromList(List<int>.filled(32, 99)),
      port: 49100,
      expiresAtMs: 119000,
      ipHints: const ['10.0.0.8'],
    );
    expect(first.card.encode(), second.card.encode());
    expect(first.encode(), isNot(second.encode()));
    final card = PairingCard.decode(first.card.encode());
    expect(card.matches(first), isTrue);
    expect(card.matches(second), isTrue);
  });

  test('safety code is stable and binds both identity keys', () async {
    final original = invite();
    final joining = Uint8List.fromList(List<int>.filled(32, 9));
    expect(await original.safetyCode(joining), matches(r'^\d{3} \d{3}$'));
    expect(
      await original.safetyCode(joining),
      await original.safetyCode(joining),
    );
    expect(
      await original.safetyCode(Uint8List.fromList(List<int>.filled(32, 8))),
      isNot(await original.safetyCode(joining)),
    );
  });

  test('pair secret is constant-time checked, expires, and consumes once', () {
    final original = invite();
    final session = PairingInvitationSession(original);
    expect(
      session.consume(
        inviteId: inviteId,
        pairSecret: Uint8List.fromList(List<int>.filled(32, 8)),
        nowMs: 1,
      ),
      isFalse,
    );
    expect(
      session.consume(
        inviteId: inviteId,
        pairSecret: original.pairSecret,
        nowMs: 1,
      ),
      isTrue,
    );
    expect(
      session.consume(
        inviteId: inviteId,
        pairSecret: original.pairSecret,
        nowMs: 1,
      ),
      isFalse,
    );
    expect(session.consumed, isTrue);
  });
}
