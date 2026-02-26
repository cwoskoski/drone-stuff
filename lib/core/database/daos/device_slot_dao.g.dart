// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_slot_dao.dart';

// ignore_for_file: type=lint
mixin _$DeviceSlotDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeviceSlotsTable get deviceSlots => attachedDatabase.deviceSlots;
  DeviceSlotDaoManager get managers => DeviceSlotDaoManager(this);
}

class DeviceSlotDaoManager {
  final _$DeviceSlotDaoMixin _db;
  DeviceSlotDaoManager(this._db);
  $$DeviceSlotsTableTableManager get deviceSlots =>
      $$DeviceSlotsTableTableManager(_db.attachedDatabase, _db.deviceSlots);
}
