import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'features/missions/local/local_missions_provider.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final docsDir = await getApplicationDocumentsDirectory();

  runApp(
    ProviderScope(
      overrides: [
        documentsPathProvider.overrideWithValue(docsDir.path),
      ],
      child: const DroneStuffApp(),
    ),
  );
}

class DroneStuffApp extends StatelessWidget {
  const DroneStuffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DroneStuff',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
