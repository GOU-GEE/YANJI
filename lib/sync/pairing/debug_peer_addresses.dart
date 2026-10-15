/// Debug-only helper for pointing the embedded transport at manually chosen
/// peers when automatic discovery cannot work, for example an Android emulator
/// that sits behind its own NAT and can never be reached by LAN broadcast.
///
/// Addresses only replace discovery. The peer certificate is still pinned to
/// the fingerprint anchored during pairing, so an override cannot introduce a
/// new identity.
abstract final class DebugPeerAddresses {
  /// `--dart-define=YANJI_SYNC_PEERS=<device-id-or-prefix>=<address>,...`
  ///
  /// Never read unless the build is in debug mode, so a release build cannot be
  /// redirected by a stray environment value.
  static const environmentKey = 'YANJI_SYNC_PEERS';

  /// Syncthing's default listen port, used when an address omits one.
  static const defaultPort = 22000;

  /// Parses comma or semicolon separated `device=address` pairs. Entries
  /// without a key, a separator or a usable address are ignored.
  static Map<String, String> parse(String raw) {
    final result = <String, String>{};
    for (final entry in raw.split(RegExp('[,;]'))) {
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;
      final separator = trimmed.indexOf('=');
      if (separator <= 0) continue;
      final key = trimmed.substring(0, separator).trim();
      final value = normalize(trimmed.substring(separator + 1));
      if (key.isEmpty || value.isEmpty) continue;
      result[key] = value;
    }
    return result;
  }

  /// Accepts `host`, `host:port`, `tcp://host` and `tcp://host:port`, and
  /// returns the Syncthing address form. Bracketed IPv6 literals are kept.
  static String normalize(String address) {
    var value = address.trim();
    if (value.isEmpty) return '';
    if (!value.contains('://')) value = 'tcp://$value';
    final host = value.substring(value.indexOf('://') + 3);
    final bool hasPort;
    if (host.startsWith('[')) {
      final end = host.indexOf(']');
      hasPort = end != -1 && end + 1 < host.length && host[end + 1] == ':';
    } else {
      hasPort = host.contains(':');
    }
    return hasPort ? value : '$value:$defaultPort';
  }

  /// Resolves an override by exact device ID first, then by the longest
  /// matching prefix so a shortened ID can be typed by hand.
  static String? resolve(Map<String, String> overrides, String deviceId) {
    final exact = overrides[deviceId];
    if (exact != null) return exact;
    String? best;
    var bestLength = 0;
    for (final entry in overrides.entries) {
      final key = entry.key;
      if (key.isEmpty || key.length >= deviceId.length) continue;
      if (deviceId.startsWith(key) && key.length > bestLength) {
        best = entry.value;
        bestLength = key.length;
      }
    }
    return best;
  }
}
