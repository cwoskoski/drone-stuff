import 'package:drift/drift.dart';

class Missions extends Table {
  TextColumn get id => text()();
  TextColumn get fileName => text()();
  TextColumn get author => text().nullable()();
  IntColumn get createTime => integer().nullable()();
  IntColumn get waypointCount => integer().withDefault(const Constant(0))();
  TextColumn get finishAction => text().withDefault(const Constant('goHome'))();
  TextColumn get filePath => text()();
  IntColumn get importedAt => integer()();
  TextColumn get sourceType =>
      text().withDefault(const Constant('imported'))();
  TextColumn get parentMissionId => text().nullable()();
  IntColumn get segmentIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
