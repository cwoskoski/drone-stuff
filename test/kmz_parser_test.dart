import 'dart:io';
import 'dart:typed_data';

import 'package:drone_stuff/core/kmz/kmz_parser.dart';
import 'package:drone_stuff/core/models/mission_config.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return file.readAsBytesSync();
}

void main() {
  group('KmzParser', () {
    test('parses main Havasu Lake Desert KMZ with 395 waypoints', () {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(bytes);

      expect(mission.waypoints.length, 395);
      expect(mission.author, 'litchi-hub');
      expect(mission.config.finishAction, FinishAction.goHome);
      expect(mission.createTime, isNotNull);
      expect(mission.createTime!.isUtc, true);
    });

    test('parses split file _1 with 150 waypoints', () {
      final bytes = _loadFixture('havasu_lake_desert_1.kmz');
      final mission = KmzParser.parseBytes(bytes);
      expect(mission.waypoints.length, 150);
    });

    test('parses split file _2 with 150 waypoints', () {
      final bytes = _loadFixture('havasu_lake_desert_2.kmz');
      final mission = KmzParser.parseBytes(bytes);
      expect(mission.waypoints.length, 150);
    });

    test('parses split file _3 with 97 waypoints', () {
      final bytes = _loadFixture('havasu_lake_desert_3.kmz');
      final mission = KmzParser.parseBytes(bytes);
      expect(mission.waypoints.length, 97);
    });

    test('waypoints have valid coordinates', () {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(bytes);

      for (final wp in mission.waypoints) {
        expect(wp.longitude, isNot(0.0),
            reason: 'Waypoint ${wp.index} longitude should not be 0');
        expect(wp.latitude, isNot(0.0),
            reason: 'Waypoint ${wp.index} latitude should not be 0');
        expect(wp.longitude, inInclusiveRange(-180.0, 180.0));
        expect(wp.latitude, inInclusiveRange(-90.0, 90.0));
      }
    });

    test('waypoints have valid altitude and speed', () {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(bytes);

      for (final wp in mission.waypoints) {
        expect(wp.executeHeight, greaterThan(0.0),
            reason: 'Waypoint ${wp.index} should have positive altitude');
        expect(wp.waypointSpeed, greaterThan(0.0),
            reason: 'Waypoint ${wp.index} should have positive speed');
      }
    });

    test('waypoints have heading and turn params', () {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(bytes);
      final wp = mission.waypoints.first;

      expect(wp.heading.mode, isNotEmpty);
      expect(wp.turn.mode, isNotEmpty);
    });

    test('first waypoint has action groups', () {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(bytes);
      final wp = mission.waypoints.first;

      expect(wp.actionGroups, isNotEmpty);
      expect(wp.actionGroups.first.actions, isNotEmpty);
      expect(
        wp.actionGroups.first.actions.first.actuatorFunc,
        'gimbalRotate',
      );
    });

    test('mission config is parsed correctly', () {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(bytes);

      expect(mission.config.finishAction, FinishAction.goHome);
      expect(mission.config.flyToWaylineMode, 'safely');
      expect(mission.config.exitOnRCLost, 'goContinue');
      expect(mission.config.executeRCLostAction, 'goBack');
      expect(mission.config.globalTransitionalSpeed, 10.0);
      expect(mission.config.droneEnumValue, 65535);
      expect(mission.config.droneSubEnumValue, 0);
    });

    test('preserves raw KMZ bytes for round-trip', () {
      final bytes = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(bytes);
      expect(mission.rawKmzBytes, bytes);
    });

    test('validate rejects invalid data', () {
      expect(
        () => KmzParser.validate(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<KmzParseException>()),
      );
    });
  });
}
