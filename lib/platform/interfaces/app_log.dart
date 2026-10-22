// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// A plain-text diagnostic log a tester can read and paste back.
///
/// Line tags are a contract with the CI smoke test, which fails the build on
/// any `FAIL` or `ERROR` line: `INFO` is routine, `FAIL` is a platform adapter
/// that could not start or stopped working, `ERROR` is an uncaught exception.
abstract interface class AppLog {
  /// False for the no-op log, so callers can skip work only a log needs.
  bool get enabled;

  void info(String message);

  /// A platform adapter could not start, or failed after starting.
  void failure(String adapter, Object error);

  /// An exception nothing else caught.
  void error(Object error, StackTrace? stack);
}

/// Used where no log is kept (Linux, tests).
class NoAppLog implements AppLog {
  const NoAppLog();

  @override
  bool get enabled => false;

  @override
  void info(String message) {}

  @override
  void failure(String adapter, Object error) {}

  @override
  void error(Object error, StackTrace? stack) {}
}
