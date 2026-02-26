import 'dart:convert';

import 'package:drone_stuff/core/models/drone_capability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DroneCapability defaults', () {
    test('default constructor has sensible values', () {
      const cap = DroneCapability();
      expect(cap.speedMin, 0.1);
      expect(cap.speedMax, 15.0);
      expect(cap.speedDefault, 10.0);
      expect(cap.gimbalPitchMin, -90.0);
      expect(cap.gimbalPitchMax, 35.0);
      expect(cap.gimbalRollMin, -90.0);
      expect(cap.gimbalRollMax, 90.0);
      expect(cap.lostActions, ['goBack', 'goHome', 'hover']);
      expect(cap.zoomCapabilities, isEmpty);
      expect(cap.isFromDevice, false);
    });
  });

  group('DroneCapability.fromJsonFiles', () {
    test('parses speed JSON', () {
      final speedJson = jsonEncode({
        'min': 1.0,
        'max': 12.0,
        'default': 8.0,
      });

      final cap = DroneCapability.fromJsonFiles(speedJson: speedJson);

      expect(cap.speedMin, 1.0);
      expect(cap.speedMax, 12.0);
      expect(cap.speedDefault, 8.0);
      expect(cap.isFromDevice, true);
    });

    test('parses gimbal JSON', () {
      final gimbalJson = jsonEncode({
        'pitchMin': -120.0,
        'pitchMax': 45.0,
        'rollMin': -45.0,
        'rollMax': 45.0,
      });

      final cap = DroneCapability.fromJsonFiles(gimbalJson: gimbalJson);

      expect(cap.gimbalPitchMin, -120.0);
      expect(cap.gimbalPitchMax, 45.0);
      expect(cap.gimbalRollMin, -45.0);
      expect(cap.gimbalRollMax, 45.0);
      expect(cap.isFromDevice, true);
    });

    test('parses lost action JSON', () {
      final lostActionJson = jsonEncode({
        'actions': ['hover', 'land', 'goBack'],
      });

      final cap = DroneCapability.fromJsonFiles(lostActionJson: lostActionJson);

      expect(cap.lostActions, ['hover', 'land', 'goBack']);
      expect(cap.isFromDevice, true);
    });

    test('parses zoom JSON', () {
      final zoomJson = jsonEncode({
        'cameras': [
          {'name': 'Wide', 'maxZoom': 6.0},
          {'name': 'Tele', 'maxZoom': 30.0},
        ],
      });

      final cap = DroneCapability.fromJsonFiles(zoomJson: zoomJson);

      expect(cap.zoomCapabilities.length, 2);
      expect(cap.zoomCapabilities[0].name, 'Wide');
      expect(cap.zoomCapabilities[0].maxZoom, 6.0);
      expect(cap.zoomCapabilities[1].name, 'Tele');
      expect(cap.zoomCapabilities[1].maxZoom, 30.0);
      expect(cap.isFromDevice, true);
    });

    test('parses integer values as doubles', () {
      final speedJson = jsonEncode({
        'min': 1,
        'max': 15,
        'default': 10,
      });

      final cap = DroneCapability.fromJsonFiles(speedJson: speedJson);

      expect(cap.speedMin, 1.0);
      expect(cap.speedMax, 15.0);
      expect(cap.speedDefault, 10.0);
    });

    test('parses string number values', () {
      final speedJson = jsonEncode({
        'min': '0.5',
        'max': '14.0',
        'default': '7.0',
      });

      final cap = DroneCapability.fromJsonFiles(speedJson: speedJson);

      expect(cap.speedMin, 0.5);
      expect(cap.speedMax, 14.0);
      expect(cap.speedDefault, 7.0);
    });

    test('partial failure: bad speed JSON still parses gimbal', () {
      final gimbalJson = jsonEncode({
        'pitchMin': -100.0,
        'pitchMax': 50.0,
        'rollMin': -30.0,
        'rollMax': 30.0,
      });

      final cap = DroneCapability.fromJsonFiles(
        speedJson: 'not valid json!!!',
        gimbalJson: gimbalJson,
      );

      // Speed falls back to defaults
      expect(cap.speedMin, 0.1);
      expect(cap.speedMax, 15.0);
      // Gimbal parsed correctly
      expect(cap.gimbalPitchMin, -100.0);
      expect(cap.gimbalPitchMax, 50.0);
      expect(cap.isFromDevice, true);
    });

    test('all invalid JSON falls back to defaults', () {
      final cap = DroneCapability.fromJsonFiles(
        speedJson: '{bad',
        gimbalJson: 'nope',
        lostActionJson: '???',
        zoomJson: '',
      );

      expect(cap.speedMin, 0.1);
      expect(cap.speedMax, 15.0);
      expect(cap.gimbalPitchMin, -90.0);
      expect(cap.gimbalPitchMax, 35.0);
      expect(cap.isFromDevice, false);
    });

    test('all null inputs returns defaults with isFromDevice false', () {
      final cap = DroneCapability.fromJsonFiles();

      expect(cap.speedMin, 0.1);
      expect(cap.speedMax, 15.0);
      expect(cap.speedDefault, 10.0);
      expect(cap.isFromDevice, false);
    });

    test('partial speed fields: only min set, others default', () {
      final speedJson = jsonEncode({'min': 2.0});

      final cap = DroneCapability.fromJsonFiles(speedJson: speedJson);

      expect(cap.speedMin, 2.0);
      expect(cap.speedMax, 15.0); // default
      expect(cap.speedDefault, 10.0); // default
      expect(cap.isFromDevice, true);
    });

    test('empty actions list keeps defaults', () {
      final lostActionJson = jsonEncode({'actions': []});

      final cap = DroneCapability.fromJsonFiles(lostActionJson: lostActionJson);

      expect(cap.lostActions, ['goBack', 'goHome', 'hover']); // defaults
      expect(cap.isFromDevice, false);
    });

    test('zoom with missing name defaults to Unknown', () {
      final zoomJson = jsonEncode({
        'cameras': [
          {'maxZoom': 10.0},
        ],
      });

      final cap = DroneCapability.fromJsonFiles(zoomJson: zoomJson);

      expect(cap.zoomCapabilities.length, 1);
      expect(cap.zoomCapabilities[0].name, 'Unknown');
      expect(cap.zoomCapabilities[0].maxZoom, 10.0);
    });
  });
}
