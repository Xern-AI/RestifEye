import 'dart:io';

import 'package:restifeye/platform/linux/xdg_autostart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late XdgAutostart autostart;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('RestifEye_autostart_');
    autostart = XdgAutostart(configHome: tmp.path);
  });

  tearDown(() => tmp.delete(recursive: true));

  test('enable writes a valid desktop entry; disable removes it', () async {
    expect(await autostart.isEnabled(), isFalse);

    await autostart.setEnabled(true);
    expect(await autostart.isEnabled(), isTrue);
    final content = File(
      '${tmp.path}/autostart/com.xernai.restifeye.desktop',
    ).readAsStringSync();
    expect(content, contains('[Desktop Entry]'));
    expect(content, contains('Exec='));
    expect(content, contains('Name=RestifEye'));

    await autostart.setEnabled(false);
    expect(await autostart.isEnabled(), isFalse);
  });

  test('disable when never enabled is a no-op', () async {
    await autostart.setEnabled(false);
    expect(await autostart.isEnabled(), isFalse);
  });
}
