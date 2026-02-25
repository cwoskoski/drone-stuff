import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drone_stuff/core/database/app_database.dart';
import 'package:drone_stuff/core/database/daos/mission_dao.dart';
import 'package:drone_stuff/core/kmz/kmz_parser.dart';
import 'package:drone_stuff/core/models/mission.dart' as models;
import 'package:drone_stuff/features/missions/local/local_mission_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _loadFixture(String name) {
  return File('test/fixtures/$name').readAsBytesSync();
}

void main() {
  late AppDatabase db;
  late MissionDao dao;
  late LocalMissionRepository repo;
  late Directory tmpDir;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.missionDao;
    tmpDir = Directory.systemTemp.createTempSync('drone_stuff_test_');
    repo = LocalMissionRepository(dao: dao, documentsPath: tmpDir.path);
  });

  tearDown(() async {
    await db.close();
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  group('importKmz', () {
    test('imports a KMZ and stores metadata in DB', () async {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final id = await repo.importKmz(bytes, 'Havasu Lake Desert.kmz');

      expect(id, isNotEmpty);

      final row = await dao.getMissionById(id);
      expect(row, isNotNull);
      expect(row!.fileName, 'Havasu Lake Desert.kmz');
      expect(row.author, 'litchi-hub');
      expect(row.waypointCount, 395);
      expect(row.finishAction, 'goHome');
      expect(row.sourceType, 'imported');
      expect(row.parentMissionId, isNull);
    });

    test('stores KMZ file on filesystem', () async {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final id = await repo.importKmz(bytes, 'test.kmz');

      final kmzFile = File('${tmpDir.path}/missions/$id.kmz');
      expect(kmzFile.existsSync(), true);
      expect(kmzFile.readAsBytesSync(), bytes);
    });
  });

  group('getMission', () {
    test('returns metadata and bytes for existing mission', () async {
      final bytes = _loadFixture('havasu_lake_desert_1.kmz');
      final id = await repo.importKmz(bytes, 'split1.kmz');

      final result = await repo.getMission(id);
      expect(result, isNotNull);
      expect(result!.metadata.fileName, 'split1.kmz');
      expect(result.bytes, bytes);
    });

    test('returns null for nonexistent mission', () async {
      final result = await repo.getMission('nonexistent-id');
      expect(result, isNull);
    });
  });

  group('deleteMission', () {
    test('removes DB entry and file', () async {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final id = await repo.importKmz(bytes, 'delete_me.kmz');

      final kmzFile = File('${tmpDir.path}/missions/$id.kmz');
      expect(kmzFile.existsSync(), true);

      await repo.deleteMission(id);

      final row = await dao.getMissionById(id);
      expect(row, isNull);
      expect(kmzFile.existsSync(), false);
    });
  });

  group('saveSplitSegment', () {
    test('links segment to parent via parentMissionId', () async {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final parentId = await repo.importKmz(bytes, 'parent.kmz');

      final segmentMission = KmzParser.parseBytes(
          _loadFixture('havasu_lake_desert_1.kmz'));
      final segmentBytes = _loadFixture('havasu_lake_desert_1.kmz');

      final segId = await repo.saveSplitSegment(
        parentId: parentId,
        segmentIndex: 1,
        mission: segmentMission,
        kmzBytes: segmentBytes,
      );

      final row = await dao.getMissionById(segId);
      expect(row, isNotNull);
      expect(row!.parentMissionId, parentId);
      expect(row.segmentIndex, 1);
      expect(row.sourceType, 'split');
      expect(row.waypointCount, 150);
    });
  });

  group('watchAllMissions', () {
    test('returns missions ordered by import time descending', () async {
      final bytes1 = _loadFixture('havasu_lake_desert_1.kmz');
      final bytes2 = _loadFixture('havasu_lake_desert_2.kmz');

      await repo.importKmz(bytes1, 'first.kmz');
      await Future.delayed(const Duration(milliseconds: 10));
      await repo.importKmz(bytes2, 'second.kmz');

      final missions = await repo.watchAllMissions().first;
      expect(missions.length, 2);
      // Most recent first
      expect(missions[0].fileName, 'second.kmz');
      expect(missions[1].fileName, 'first.kmz');
    });
  });

  group('watchSegments', () {
    test('returns segments ordered by segment index', () async {
      final parentBytes = _loadFixture('havasu_lake_desert.kmz');
      final parentId = await repo.importKmz(parentBytes, 'parent.kmz');

      for (var i = 3; i >= 1; i--) {
        final segBytes = _loadFixture('havasu_lake_desert_$i.kmz');
        final segMission = KmzParser.parseBytes(segBytes);
        await repo.saveSplitSegment(
          parentId: parentId,
          segmentIndex: i,
          mission: segMission,
          kmzBytes: segBytes,
        );
      }

      final segments = await repo.watchSegments(parentId).first;
      expect(segments.length, 3);
      expect(segments[0].segmentIndex, 1);
      expect(segments[1].segmentIndex, 2);
      expect(segments[2].segmentIndex, 3);
    });
  });
}
