import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drone_stuff/core/database/app_database.dart';
import 'package:drone_stuff/core/database/providers.dart';
import 'package:drone_stuff/main.dart';
import 'package:drone_stuff/features/missions/local/local_missions_provider.dart';

void main() {
  testWidgets('DroneStuffApp renders with tabs', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsPathProvider.overrideWithValue('/tmp/test'),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const DroneStuffApp(),
      ),
    );

    expect(find.text('DroneStuff'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
  });
}
