import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/design/glass/glass_notice.dart';

void main() {
  test(
    'notice errors retain the Chinese explanation and remove technical English',
    () {
      expect(GlassNotice.chineseMessage('Bad state: 暂无已配对设备'), '暂无已配对设备');
      expect(
        GlassNotice.chineseMessage('StateError: Workspace Genesis 与二维码不一致'),
        '学习空间身份记录 与二维码不一致',
      );
      expect(
        RegExp('[A-Za-z]').hasMatch(
          GlassNotice.chineseMessage('SocketException: Connection timed out'),
        ),
        isFalse,
      );
    },
  );
}
