import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/mission_dao.dart';
import '../../../core/kmz/kmz_parser.dart';
import '../../../core/models/mission.dart' as models;

class LocalMissionRepository {
  final MissionDao _dao;
  final String _documentsPath;
  static const _uuid = Uuid();

  LocalMissionRepository({
    required MissionDao dao,
    required String documentsPath,
  })  : _dao = dao,
        _documentsPath = documentsPath;

  String get _missionsDir => p.join(_documentsPath, 'missions');

  /// Import a KMZ file: parse it, store the file, insert metadata into DB.
  Future<String> importKmz(Uint8List bytes, String fileName) async {
    final mission = KmzParser.parseBytes(bytes);
    final id = _uuid.v4();
    final relPath = 'missions/$id.kmz';
    final absPath = p.join(_documentsPath, relPath);

    // Store KMZ file
    final dir = Directory(_missionsDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File(absPath).writeAsBytesSync(bytes);

    // Insert metadata into DB
    await _dao.insertMission(MissionsCompanion(
      id: Value(id),
      fileName: Value(fileName),
      author: Value(mission.author),
      createTime: Value(mission.createTime?.millisecondsSinceEpoch),
      waypointCount: Value(mission.waypoints.length),
      finishAction: Value(mission.config.finishAction.name),
      filePath: Value(relPath),
      importedAt: Value(DateTime.now().millisecondsSinceEpoch),
      sourceType: const Value('imported'),
    ));

    return id;
  }

  /// Load a mission's metadata and KMZ bytes.
  Future<({Mission metadata, Uint8List bytes})?> getMission(String id) async {
    final row = await _dao.getMissionById(id);
    if (row == null) return null;

    final absPath = p.join(_documentsPath, row.filePath);
    final file = File(absPath);
    if (!file.existsSync()) return null;

    final bytes = file.readAsBytesSync();
    return (metadata: row, bytes: bytes);
  }

  /// Delete a mission from DB and filesystem.
  Future<void> deleteMission(String id) async {
    final row = await _dao.getMissionById(id);
    if (row != null) {
      final absPath = p.join(_documentsPath, row.filePath);
      final file = File(absPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    await _dao.deleteMission(id);
  }

  /// Delete a mission and all its child segments from DB and filesystem.
  Future<void> deleteMissionWithSegments(String id) async {
    // Delete child segment files first
    final segments = await _dao.getSegmentsList(id);
    for (final seg in segments) {
      final absPath = p.join(_documentsPath, seg.filePath);
      final file = File(absPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    await _dao.deleteSegments(id);

    // Then delete the parent itself
    await deleteMission(id);
  }

  /// Get segments list for a parent (non-stream, for UI queries).
  Future<List<Mission>> getSegmentsList(String parentId) {
    return _dao.getSegmentsList(parentId);
  }

  /// Save a split segment linked to a parent mission.
  Future<String> saveSplitSegment({
    required String parentId,
    required int segmentIndex,
    required models.Mission mission,
    required Uint8List kmzBytes,
    String? parentFileName,
  }) async {
    final id = _uuid.v4();
    final relPath = 'missions/$id.kmz';
    final absPath = p.join(_documentsPath, relPath);

    final dir = Directory(_missionsDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File(absPath).writeAsBytesSync(kmzBytes);

    // Derive segment name from parent: "foo.kmz" → "foo_1.kmz"
    final baseName = parentFileName != null
        ? parentFileName.replaceAll(RegExp(r'\.kmz$', caseSensitive: false), '')
        : 'segment';
    final segFileName = '${baseName}_${segmentIndex + 1}.kmz';

    await _dao.insertMission(MissionsCompanion(
      id: Value(id),
      fileName: Value(segFileName),
      author: Value(mission.author),
      createTime: Value(mission.createTime?.millisecondsSinceEpoch),
      waypointCount: Value(mission.waypoints.length),
      finishAction: Value(mission.config.finishAction.name),
      filePath: Value(relPath),
      importedAt: Value(DateTime.now().millisecondsSinceEpoch),
      sourceType: const Value('split'),
      parentMissionId: Value(parentId),
      segmentIndex: Value(segmentIndex),
    ));

    return id;
  }

  /// Watch all missions ordered by import time.
  Stream<List<Mission>> watchAllMissions() => _dao.getAllMissions();

  /// Watch segments of a parent mission.
  Stream<List<Mission>> watchSegments(String parentId) =>
      _dao.getSegments(parentId);
}
