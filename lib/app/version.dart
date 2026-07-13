/// Single source of truth for the app's own version.
/// Keep in sync with pubspec.yaml version when tagging releases.
const appVersion = '0.1.0';

/// GitHub repo used by the update check (and the site links).
const githubRepoSlug = 'xernai/breaktime';

/// True when [candidate] is a strictly newer semver than [current].
/// Tolerates a leading 'v' and missing segments; returns false on garbage.
bool isNewerVersion({required String current, required String candidate}) {
  List<int>? parse(String v) {
    final cleaned = v.trim().replaceFirst(RegExp('^v'), '');
    final core = cleaned.split(RegExp('[+-]')).first;
    final parts = core.split('.');
    final numbers = <int>[];
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null) return null;
      numbers.add(n);
    }
    while (numbers.length < 3) {
      numbers.add(0);
    }
    return numbers;
  }

  final a = parse(current);
  final b = parse(candidate);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (b[i] > a[i]) return true;
    if (b[i] < a[i]) return false;
  }
  return false;
}
