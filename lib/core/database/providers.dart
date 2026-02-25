import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'daos/mission_dao.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'drone_stuff.db'));
      return NativeDatabase.createInBackground(file);
    }),
  );
  ref.onDispose(() => db.close());
  return db;
});

final missionDaoProvider = Provider<MissionDao>((ref) {
  return ref.watch(appDatabaseProvider).missionDao;
});
