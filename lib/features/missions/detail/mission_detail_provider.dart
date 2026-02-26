import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/providers.dart';
import '../../../core/kmz/kmz_parser.dart';
import '../../../core/models/mission.dart';
import '../../../core/platform/shizuku_state.dart';
import '../local/local_missions_provider.dart';

final missionDetailProvider = FutureProvider.autoDispose
    .family<Mission, (String id, String source)>((ref, key) async {
  final (id, source) = key;

  if (source == 'local') {
    final repo = ref.watch(localMissionRepositoryProvider);
    final result = await repo.getMission(id);
    if (result == null) {
      throw Exception('Mission not found: $id');
    }
    return KmzParser.parseBytes(result.bytes);
  }

  if (source == 'device') {
    final channel = ref.read(shizukuChannelProvider);
    final kmzPath = '$waypointRoot/$id/$id.kmz';
    final bytes = await channel.readFile(kmzPath);
    if (bytes.isEmpty) {
      throw Exception('Empty KMZ file on device: $id');
    }
    return KmzParser.parseBytes(bytes);
  }

  throw Exception('Unknown source: $source');
});

/// Fetches DB metadata (parentMissionId, sourceType, segmentIndex, etc.)
/// for a local mission. Returns null for device missions.
final missionMetadataProvider = FutureProvider.autoDispose
    .family<({db.Mission mission, db.Mission? parent})?, String>(
        (ref, id) async {
  final dao = ref.watch(missionDaoProvider);
  final row = await dao.getMissionById(id);
  if (row == null) return null;

  db.Mission? parent;
  if (row.parentMissionId != null) {
    parent = await dao.getMissionById(row.parentMissionId!);
  }
  return (mission: row, parent: parent);
});
