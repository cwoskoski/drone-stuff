import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'daos/mission_dao.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'drone_stuff'));
  ref.onDispose(() => db.close());
  return db;
});

final missionDaoProvider = Provider<MissionDao>((ref) {
  return ref.watch(appDatabaseProvider).missionDao;
});
