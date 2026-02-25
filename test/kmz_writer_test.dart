import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drone_stuff/core/kmz/kmz_parser.dart';
import 'package:drone_stuff/core/kmz/kmz_writer.dart';
import 'package:drone_stuff/core/models/mission_config.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _loadFixture(String name) {
  return File('test/fixtures/$name').readAsBytesSync();
}

void main() {
  group('KmzWriter.buildKmz', () {
    test('round-trip: parse → write → parse produces matching models', () {
      final original = _loadFixture('havasu_lake_desert.kmz');
      final mission1 = KmzParser.parseBytes(original);

      final written = KmzWriter.buildKmz(mission1);
      final mission2 = KmzParser.parseBytes(written);

      expect(mission2.waypoints.length, mission1.waypoints.length);
      expect(mission2.author, mission1.author);
      expect(mission2.config.finishAction, mission1.config.finishAction);
      expect(mission2.config.flyToWaylineMode, mission1.config.flyToWaylineMode);
      expect(mission2.config.exitOnRCLost, mission1.config.exitOnRCLost);
      expect(mission2.config.droneEnumValue, mission1.config.droneEnumValue);
      expect(
          mission2.config.globalTransitionalSpeed,
          mission1.config.globalTransitionalSpeed);
    });

    test('round-trip preserves waypoint data', () {
      final original = _loadFixture('havasu_lake_desert_1.kmz');
      final mission1 = KmzParser.parseBytes(original);

      final written = KmzWriter.buildKmz(mission1);
      final mission2 = KmzParser.parseBytes(written);

      for (var i = 0; i < mission1.waypoints.length; i++) {
        final wp1 = mission1.waypoints[i];
        final wp2 = mission2.waypoints[i];
        expect(wp2.index, wp1.index, reason: 'index mismatch at $i');
        expect(wp2.longitude, wp1.longitude,
            reason: 'longitude mismatch at $i');
        expect(wp2.latitude, wp1.latitude,
            reason: 'latitude mismatch at $i');
        expect(wp2.executeHeight, wp1.executeHeight,
            reason: 'executeHeight mismatch at $i');
        expect(wp2.waypointSpeed, wp1.waypointSpeed,
            reason: 'speed mismatch at $i');
        expect(wp2.heading.mode, wp1.heading.mode,
            reason: 'heading mode mismatch at $i');
        expect(wp2.turn.mode, wp1.turn.mode,
            reason: 'turn mode mismatch at $i');
        expect(wp2.actionGroups.length, wp1.actionGroups.length,
            reason: 'actionGroups count mismatch at $i');
      }
    });

    test('generated KMZ contains both required entries', () {
      final original = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(original);
      final written = KmzWriter.buildKmz(mission);

      final archive = ZipDecoder().decodeBytes(written);
      final names = archive.files.map((f) => f.name).toList();
      expect(names, contains('wpmz/template.kml'));
      expect(names, contains('wpmz/waylines.wpml'));
    });

    test('generated XML uses correct namespace declarations', () {
      final original = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(original);
      final written = KmzWriter.buildKmz(mission);

      final archive = ZipDecoder().decodeBytes(written);
      for (final file in archive.files) {
        if (file.name.endsWith('.kml') || file.name.endsWith('.wpml')) {
          final xml = utf8.decode(file.content as List<int>);
          expect(xml, contains('http://www.opengis.net/kml/2.2'));
          expect(xml, contains('http://www.dji.com/wpmz/1.0.6'));
        }
      }
    });

    test('written KMZ file size is reasonable', () {
      final original = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(original);
      final written = KmzWriter.buildKmz(mission);

      // Written file should be within 5x of original (XML pretty-printing
      // and minor formatting differences are expected)
      expect(written.length, greaterThan(original.length ~/ 5));
      expect(written.length, lessThan(original.length * 5));
    });

    test('validates via KmzParser after generation', () {
      final original = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(original);
      final written = KmzWriter.buildKmz(mission);

      // Should not throw
      KmzParser.validate(written);
    });
  });

  group('KmzWriter.rewriteKmz', () {
    test('rewriteKmz with modified finishAction changes only that field', () {
      final original = _loadFixture('havasu_lake_desert.kmz');
      final mission1 = KmzParser.parseBytes(original);
      expect(mission1.config.finishAction, FinishAction.goHome);

      final rewritten = KmzWriter.rewriteKmz(
        original,
        finishAction: FinishAction.autoLand,
      );
      final mission2 = KmzParser.parseBytes(rewritten);

      expect(mission2.config.finishAction, FinishAction.autoLand);
      // Other fields preserved
      expect(mission2.waypoints.length, mission1.waypoints.length);
      expect(mission2.author, mission1.author);
      expect(mission2.config.flyToWaylineMode, mission1.config.flyToWaylineMode);
    });

    test('rewriteKmz with modified speed updates correctly', () {
      final original = _loadFixture('havasu_lake_desert.kmz');
      final rewritten = KmzWriter.rewriteKmz(original, speed: 15.0);
      final mission = KmzParser.parseBytes(rewritten);
      expect(mission.config.globalTransitionalSpeed, 15.0);
    });

    test('rewritten KMZ passes validation', () {
      final original = _loadFixture('havasu_lake_desert.kmz');
      final rewritten = KmzWriter.rewriteKmz(
        original,
        finishAction: FinishAction.noAction,
      );
      KmzParser.validate(rewritten);
    });
  });

  group('Python cross-validation', () {
    test('generated KMZ can be parsed by push_waypoints.py', () {
      final original = _loadFixture('havasu_lake_desert.kmz');
      final mission = KmzParser.parseBytes(original);
      final written = KmzWriter.buildKmz(mission);

      // Write to temp file and validate with Python
      final tmpFile = File('test/fixtures/roundtrip_test.kmz');
      tmpFile.writeAsBytesSync(written);

      final result = Process.runSync('python3', [
        '-c',
        '''
import sys, zipfile, xml.etree.ElementTree as ET
try:
    zf = zipfile.ZipFile("${tmpFile.path}")
    assert "wpmz/template.kml" in zf.namelist()
    assert "wpmz/waylines.wpml" in zf.namelist()
    ET.fromstring(zf.read("wpmz/template.kml"))
    tree = ET.fromstring(zf.read("wpmz/waylines.wpml"))
    ns = "http://www.dji.com/wpmz/1.0.6"
    count = len(tree.findall(".//{%s}index" % ns))
    assert count == 395, f"Expected 395 waypoints, got {count}"
    print("OK")
except Exception as e:
    print(f"FAIL: {e}", file=sys.stderr)
    sys.exit(1)
''',
      ]);

      // Clean up
      tmpFile.deleteSync();

      expect(result.exitCode, 0,
          reason: 'Python validation failed: ${result.stderr}');
    });
  });
}
