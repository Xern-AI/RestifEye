// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../interfaces/app_log.dart';
import '../interfaces/context_signals.dart';
import 'consent_store.dart';
import 'user_registry.dart';

/// Meeting detection: the microphone or camera is open in any app.
///
/// Focus Assist / Do Not Disturb is deliberately absent. Windows has no
/// public API for its state; the only routes are undocumented WNF calls or
/// reverse-engineered registry blobs that change between builds, and a busy
/// signal that silently breaks on the next Windows update is worse than none.
class WindowsContextSignals implements ContextSignals {
  WindowsContextSignals({required this.registry, required this.log});

  final UserRegistry registry;
  final AppLog log;
  bool _reported = false;
  String? _lastApp;

  /// Throws when the registry cannot be read, so startup can log it.
  void probe() => readConsentStore(registry);

  @override
  Future<bool> isBusy() async {
    try {
      final app = captureInUse(readConsentStore(registry));
      if (app != _lastApp) {
        log.info(app == null ? 'mic/camera free' : 'mic/camera in use by $app');
        _lastApp = app;
      }
      return app != null;
    } on Object catch (e) {
      if (!_reported) log.failure('meeting', e);
      _reported = true;
      return false;
    }
  }
}
