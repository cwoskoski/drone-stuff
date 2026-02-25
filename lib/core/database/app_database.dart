import 'package:drift/drift.dart';

import 'daos/mission_dao.dart';
import 'tables/missions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Missions], daos: [MissionDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
