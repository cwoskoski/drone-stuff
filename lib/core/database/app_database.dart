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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDeviceSlots();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(deviceSlots);
          }
          if (from < 3) {
            await _seedDeviceSlots();
          }
        },
      );

  /// Seed the known UUID-to-slot mapping from the physical device.
  Future<void> _seedDeviceSlots() async {
    const knownSlots = {
      1: 'BF27D098-B216-4A90-9AB2-63BF6A46D2A0',
      2: 'C4495C2B-33DF-4BFF-98AB-AF40118A1E72',
      3: 'E0BF23B2-642F-49A0-A240-904BA4914E35',
      4: 'E8CACCB9-FB9F-4557-93B0-C5C6A5693E6C',
      5: '6D481C41-0EE1-4E6A-92B3-B92D1393DAAB',
      6: '59ED1065-A3D9-40D4-8129-B5B0CE917641',
      7: 'D3318012-44E8-463F-858C-F7893D499EC0',
      8: 'FDB07F9D-BF45-401B-B893-17ED107101CA',
      9: 'D55E13BD-4DE6-4322-AF07-F44D41449519',
      10: 'A8A88107-FAB5-41FC-9749-B99ABCD0EFB8',
    };
    for (final entry in knownSlots.entries) {
      await into(deviceSlots).insertOnConflictUpdate(
        DeviceSlotsCompanion.insert(
          uuid: entry.value,
          slotNumber: entry.key,
        ),
      );
    }
  }
}
