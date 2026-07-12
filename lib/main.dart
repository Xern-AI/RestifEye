import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'services/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boot = await bootstrap();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(boot.db),
        engineServiceProvider.overrideWithValue(boot.service),
      ],
      child: const BreakTimeApp(),
    ),
  );
}
