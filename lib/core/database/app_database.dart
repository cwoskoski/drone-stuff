import 'package:drift/drift.dart';

import 'daos/device_slot_dao.dart';
import 'daos/mission_dao.dart';
import 'tables/device_slots_table.dart';
import 'tables/missions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Missions, DeviceSlots], daos: [MissionDao, DeviceSlotDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(deviceSlots);
          }
        },
      );
}
