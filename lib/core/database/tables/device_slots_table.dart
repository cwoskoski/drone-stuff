import 'package:drift/drift.dart';

class DeviceSlots extends Table {
  TextColumn get uuid => text()();
  TextColumn get name => text().nullable()();
  IntColumn get slotNumber => integer()();
  IntColumn get updatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}
