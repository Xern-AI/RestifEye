import 'package:restifeye/app/version.dart';
import 'package:restifeye/core/clock.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/data/database.dart';
import 'package:restifeye/data/settings_repository.dart';
import 'package:restifeye/platform/interfaces/break_notifier.dart';
import 'package:restifeye/platform/interfaces/update_checker.dart';
import 'package:restifeye/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubChecker implements UpdateChecker {
  _StubChecker(this.version);
  final String? version;
  int calls = 0;

  @override
  Future<String?> latestVersion() async {
    calls++;
    return version;
  }
}

class _StubNotifier implements BreakNotifier {
  final List<String> infos = [];

  @override
  Future<void> showInfo({required String title, required String body}) async =>
      infos.add(title);

  @override
  Stream<WarningAction> get actions => const Stream.empty();

  @override
  Future<void> dismissWarning() async {}

  @override
  Future<void> showWarning({
    required BreakKind kind,
    required Duration startsIn,
    required bool canSnooze,
    required bool canSkip,
  }) async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  group('isNewerVersion', () {
    test('compares semver correctly', () {
      expect(isNewerVersion(current: '0.1.0', candidate: '0.2.0'), isTrue);
      expect(isNewerVersion(current: '0.1.0', candidate: 'v1.0.0'), isTrue);
      expect(isNewerVersion(current: '1.2.3', candidate: '1.2.3'), isFalse);
      expect(isNewerVersion(current: '1.2.3', candidate: '1.2.2'), isFalse);
      expect(isNewerVersion(current: '1.10.0', candidate: '1.9.9'), isFalse);
      expect(isNewerVersion(current: '1.0.0', candidate: '1.0'), isFalse);
      expect(isNewerVersion(current: '1.0.0', candidate: 'nonsense'), isFalse);
    });
  });

  group('UpdateService', () {
    late AppDatabase db;
    late SettingsRepository settings;
    late ManualClock clock;
    late _StubNotifier notifier;

    setUp(() {
      db = AppDatabase.inMemory();
      settings = SettingsRepository(db);
      clock = ManualClock(startAt: DateTime(2026, 7, 1));
      notifier = _StubNotifier();
    });

    tearDown(() => db.close());

    UpdateService service(String? latest) => UpdateService(
      checker: _StubChecker(latest),
      notifier: notifier,
      settings: settings,
      clock: clock,
    );

    test('notifies when a newer version exists', () async {
      final found = await service('99.0.0').maybeCheck();
      expect(found, '99.0.0');
      expect(notifier.infos, hasLength(1));
    });

    test('stays quiet when up to date or offline', () async {
      expect(await service(appVersion).maybeCheck(), isNull);
      clock.advance(const Duration(days: 8));
      expect(await service(null).maybeCheck(), isNull);
      expect(notifier.infos, isEmpty);
    });

    test('respects the weekly cadence', () async {
      final checker = _StubChecker('99.0.0');
      final svc = UpdateService(
        checker: checker,
        notifier: notifier,
        settings: settings,
        clock: clock,
      );
      await svc.maybeCheck();
      clock.advance(const Duration(days: 2));
      await svc.maybeCheck(); // within a week: no network call
      expect(checker.calls, 1);

      clock.advance(const Duration(days: 6));
      await svc.maybeCheck();
      expect(checker.calls, 2);
    });

    test('respects the opt-out flag', () async {
      await settings.setFlag(SettingsRepository.flagUpdateCheck, false);
      expect(await service('99.0.0').maybeCheck(), isNull);
      expect(notifier.infos, isEmpty);
    });
  });
}
