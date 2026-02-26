import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/device_slots_table.dart';

part 'device_slot_dao.g.dart';

@DriftAccessor(tables: [DeviceSlots])
class DeviceSlotDao extends DatabaseAccessor<AppDatabase>
    with _$DeviceSlotDaoMixin {
  DeviceSlotDao(super.db);

  Stream<List<DeviceSlot>> watchAll() {
    return (select(deviceSlots)
          ..orderBy([(t) => OrderingTerm.asc(t.slotNumber)]))
        .watch();
  }

  Future<DeviceSlot?> getByUuid(String uuid) {
    return (select(deviceSlots)..where((t) => t.uuid.equals(uuid)))
        .getSingleOrNull();
  }

  Future<void> upsertSlot(DeviceSlotsCompanion entry) {
    return into(deviceSlots).insertOnConflictUpdate(entry);
  }

  Future<void> deleteSlot(String uuid) {
    return (delete(deviceSlots)..where((t) => t.uuid.equals(uuid))).go();
  }
}
