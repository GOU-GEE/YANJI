import 'dart:convert';
import 'dart:typed_data';

/// RFC 8949 §4.2.1, restricted to SYNC.md's integer-only, text-map-key profile.
/// No JSON conversion: uint64 and byte strings must retain their exact values.
final class DeterministicCbor {
  static const maxBytes = 4 * 1024 * 1024;
  static const maxDepth = 64;
  static final _maxUint = (BigInt.one << 64) - BigInt.one;
  static final _minInt = -(BigInt.one << 63);

  static Uint8List encode(Object? value) {
    final out = BytesBuilder(copy: false);
    void header(int major, BigInt n) {
      if (n < BigInt.zero || n > _maxUint) {
        throw const FormatException('CBOR range');
      }
      if (n < BigInt.from(24)) {
        out.addByte((major << 5) | n.toInt());
      } else {
        final width = n <= BigInt.from(255)
            ? 1
            : n <= BigInt.from(65535)
            ? 2
            : n <= BigInt.from(0xffffffff)
            ? 4
            : 8;
        out.addByte((major << 5) | {1: 24, 2: 25, 4: 26, 8: 27}[width]!);
        for (var shift = (width - 1) * 8; shift >= 0; shift -= 8) {
          out.addByte(((n >> shift) & BigInt.from(255)).toInt());
        }
      }
    }

    void write(Object? item, int depth) {
      if (depth > maxDepth) throw const FormatException('CBOR nesting limit');
      if (item == null) {
        out.addByte(0xf6);
      } else if (item is bool) {
        out.addByte(item ? 0xf5 : 0xf4);
      } else if (item is int || item is BigInt) {
        final n = item is int ? BigInt.from(item) : item as BigInt;
        if (n < _minInt || n > _maxUint) {
          throw const FormatException('Integer out of profile');
        }
        header(n.isNegative ? 1 : 0, n.isNegative ? -BigInt.one - n : n);
      } else if (item is Uint8List) {
        header(2, BigInt.from(item.length));
        out.add(item);
      } else if (item is String) {
        final bytes = utf8.encode(item);
        if (utf8.decode(bytes) != item) {
          throw const FormatException('Invalid Unicode');
        }
        header(3, BigInt.from(bytes.length));
        out.add(bytes);
      } else if (item is List<Object?>) {
        header(4, BigInt.from(item.length));
        for (final child in item) {
          write(child, depth + 1);
        }
      } else if (item is Map<String, Object?>) {
        final keys = item.keys.map((key) => (key, encode(key))).toList()
          ..sort((a, b) => compareBytes(a.$2, b.$2));
        header(5, BigInt.from(keys.length));
        for (final key in keys) {
          out.add(key.$2);
          write(item[key.$1], depth + 1);
        }
      } else {
        throw const FormatException('Unsupported CBOR type or map key');
      }
      if (out.length > maxBytes) throw const FormatException('CBOR size limit');
    }

    write(value, 0);
    return out.takeBytes();
  }

  static Object? decode(Uint8List bytes) {
    if (bytes.length > maxBytes) throw const FormatException('CBOR size limit');
    final reader = _Reader(bytes);
    final value = reader.read(0);
    if (reader.offset != bytes.length ||
        compareBytes(encode(value), bytes) != 0) {
      throw const FormatException('Non-deterministic CBOR or trailing bytes');
    }
    return value;
  }

  static int compareBytes(List<int> a, List<int> b) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) return a[i].compareTo(b[i]);
    }
    return a.length.compareTo(b.length);
  }
}

final class _Reader {
  _Reader(this.bytes);
  final Uint8List bytes;
  int offset = 0;
  int byte() {
    if (offset >= bytes.length) throw const FormatException('Truncated CBOR');
    return bytes[offset++];
  }

  BigInt argument(int ai) {
    if (ai < 24) return BigInt.from(ai);
    final width = {24: 1, 25: 2, 26: 4, 27: 8}[ai];
    if (width == null) throw const FormatException('Indefinite/reserved CBOR');
    var n = BigInt.zero;
    for (var i = 0; i < width; i++) {
      n = (n << 8) | BigInt.from(byte());
    }
    return n;
  }

  Object? read(int depth) {
    if (depth > DeterministicCbor.maxDepth) {
      throw const FormatException('CBOR nesting limit');
    }
    final first = byte(), major = first >> 5, ai = first & 31;
    if (major == 7) {
      return switch (ai) {
        20 => false,
        21 => true,
        22 => null,
        _ => throw const FormatException('Float/simple value forbidden'),
      };
    }
    if (major == 6) throw const FormatException('Tags forbidden');
    final n = argument(ai);
    if (major == 0 || major == 1) {
      final value = major == 0 ? n : -BigInt.one - n;
      if (value < -(BigInt.one << 63)) {
        throw const FormatException('int64 underflow');
      }
      return value <= BigInt.from(0x7fffffffffffffff) ? value.toInt() : value;
    }
    // Every member consumes at least one byte: reject huge lengths before allocation.
    if (n > BigInt.from(bytes.length - offset)) {
      throw const FormatException('Truncated container');
    }
    final length = n.toInt();
    if (major == 2 || major == 3) {
      final part = Uint8List.fromList(bytes.sublist(offset, offset + length))
          .asUnmodifiableView();
      offset += length;
      return major == 2 ? part : utf8.decode(part, allowMalformed: false);
    }
    if (major == 4) {
      return List<Object?>.unmodifiable(
        List.generate(length, (_) => read(depth + 1)),
      );
    }
    if (major == 5) {
      final map = <String, Object?>{};
      for (var i = 0; i < length; i++) {
        final key = read(depth + 1);
        if (key is! String || map.containsKey(key)) {
          throw const FormatException('Invalid/duplicate map key');
        }
        map[key] = read(depth + 1);
      }
      return Map<String, Object?>.unmodifiable(map);
    }
    throw const FormatException('Invalid major type');
  }
}
