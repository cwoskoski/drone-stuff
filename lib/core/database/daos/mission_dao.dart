import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/missions_table.dart';

part 'mission_dao.g.dart';

@DriftAccessor(tables: [Missions])
class MissionDao extends DatabaseAccessor<AppDatabase> with _$MissionDaoMixin {
  MissionDao(super.db);

  Stream<List<Mission>> getAllMissions() {
    return (select(missions)
          ..orderBy([(t) => OrderingTerm.desc(t.importedAt)]))
        .watch();
  }

  Future<Mission?> getMissionById(String id) {
    return (select(missions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertMission(MissionsCompanion entry) {
    return into(missions).insert(entry);
  }

  Future<void> deleteMission(String id) {
    return (delete(missions)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Mission>> getSegments(String parentId) {
    return (select(missions)
          ..where((t) => t.parentMissionId.equals(parentId))
          ..orderBy([(t) => OrderingTerm.asc(t.segmentIndex)]))
        .watch();
  }
}
