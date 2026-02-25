import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drone_stuff/main.dart';
import 'package:drone_stuff/features/missions/local/local_missions_provider.dart';

void main() {
  testWidgets('DroneStuffApp renders with tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsPathProvider.overrideWithValue('/tmp/test'),
        ],
        child: const DroneStuffApp(),
      ),
    );

    expect(find.text('DroneStuff'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
  });
}
