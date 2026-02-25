import 'dart:io';
import 'dart:typed_data';

import 'package:drone_stuff/core/kmz/kmz_parser.dart';
import 'package:drone_stuff/core/kmz/kmz_writer.dart';
import 'package:drone_stuff/core/models/action_group.dart';
import 'package:drone_stuff/core/models/mission.dart';
import 'package:drone_stuff/core/models/mission_config.dart';
import 'package:drone_stuff/core/models/waypoint.dart';
import 'package:drone_stuff/features/split_merge/merge/merge_provider.dart';
import 'package:drone_stuff/features/split_merge/split/split_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Mission testMission;
  late Uint8List testKmzBytes;

  setUpAll(() {
    final file = File('docs/Havasu Lake Desert.kmz');
    testKmzBytes = file.readAsBytesSync();
    testMission = KmzParser.parseBytes(testKmzBytes);
  });

  group('computeSegments', () {
    test('splits 395 waypoints into 3 segments with default config', () {
      final segments = computeSegments(
        395,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      expect(segments.length, 3);
      expect(segments[0].startIndex, 0);
      expect(segments[0].endIndex, 149);
      expect(segments[0].waypointCount, 150);
      expect(segments[1].startIndex, 149);
      expect(segments[1].endIndex, 298);
      expect(segments[1].waypointCount, 150);
      expect(segments[2].startIndex, 298);
      expect(segments[2].endIndex, 394);
      expect(segments[2].waypointCount, 97);
    });

    test('intermediate segments default to noAction, last to goHome', () {
      final segments = computeSegments(
        395,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      expect(segments[0].finishAction, FinishAction.noAction);
      expect(segments[1].finishAction, FinishAction.noAction);
      expect(segments[2].finishAction, FinishAction.goHome);
    });

    test('respects custom finishAction overrides', () {
      final segments = computeSegments(
        395,
        const SplitConfig(
          waypointsPerSegment: 150,
          overlap: 1,
          segmentFinishActions: [
            FinishAction.autoLand,
            FinishAction.noAction,
            FinishAction.backToFirstWaypoint,
          ],
        ),
      );

      expect(segments[0].finishAction, FinishAction.autoLand);
      expect(segments[1].finishAction, FinishAction.noAction);
      expect(segments[2].finishAction, FinishAction.backToFirstWaypoint);
    });

    test('handles zero overlap', () {
      final segments = computeSegments(
        300,
        const SplitConfig(waypointsPerSegment: 150, overlap: 0),
      );

      expect(segments.length, 2);
      expect(segments[0].startIndex, 0);
      expect(segments[0].endIndex, 149);
      expect(segments[1].startIndex, 150);
      expect(segments[1].endIndex, 299);
    });

    test('handles mission smaller than segment size', () {
      final segments = computeSegments(
        50,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      expect(segments.length, 1);
      expect(segments[0].startIndex, 0);
      expect(segments[0].endIndex, 49);
      expect(segments[0].waypointCount, 50);
      expect(segments[0].finishAction, FinishAction.goHome);
    });
  });

  group('splitMission', () {
    test('splits real mission into 3 segments', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      expect(segments.length, 3);
      expect(segments[0].waypoints.length, 150);
      expect(segments[1].waypoints.length, 150);
      expect(segments[2].waypoints.length, 97);
    });

    test('each segment has waypoints re-indexed from 0', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      for (final seg in segments) {
        for (var i = 0; i < seg.waypoints.length; i++) {
          expect(seg.waypoints[i].index, i);
        }
      }
    });

    test('overlap waypoints share same coordinates', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      // Last waypoint of seg 1 == first waypoint of seg 2
      final seg1Last = segments[0].waypoints.last;
      final seg2First = segments[1].waypoints.first;
      expect(seg1Last.latitude, seg2First.latitude);
      expect(seg1Last.longitude, seg2First.longitude);

      // Last waypoint of seg 2 == first waypoint of seg 3
      final seg2Last = segments[1].waypoints.last;
      final seg3First = segments[2].waypoints.first;
      expect(seg2Last.latitude, seg3First.latitude);
      expect(seg2Last.longitude, seg3First.longitude);
    });

    test('split segments have correct finishAction', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      expect(segments[0].config.finishAction, FinishAction.noAction);
      expect(segments[1].config.finishAction, FinishAction.noAction);
      expect(segments[2].config.finishAction, FinishAction.goHome);
    });

    test('split segments generate valid KMZ files', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      for (final seg in segments) {
        final kmz = KmzWriter.buildKmz(seg);
        // Should parse without error
        final reparsed = KmzParser.parseBytes(kmz);
        expect(reparsed.waypoints.length, seg.waypoints.length);
      }
    });

    test('preserves source config fields in segments', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      for (final seg in segments) {
        expect(seg.config.flyToWaylineMode,
            testMission.config.flyToWaylineMode);
        expect(seg.config.globalTransitionalSpeed,
            testMission.config.globalTransitionalSpeed);
        expect(seg.author, testMission.author);
      }
    });
  });

  group('mergeMissions', () {
    test('merges split segments back to original waypoint count', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      final merged = mergeMissions(segments, overlap: 1);

      // 150 + (150-1) + (97-1) = 395
      expect(merged.waypoints.length, testMission.waypoints.length);
    });

    test('merged waypoints are re-indexed from 0', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      final merged = mergeMissions(segments, overlap: 1);

      for (var i = 0; i < merged.waypoints.length; i++) {
        expect(merged.waypoints[i].index, i);
      }
    });

    test('merged waypoints match original coordinates', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      final merged = mergeMissions(segments, overlap: 1);

      for (var i = 0; i < merged.waypoints.length; i++) {
        expect(merged.waypoints[i].latitude,
            testMission.waypoints[i].latitude);
        expect(merged.waypoints[i].longitude,
            testMission.waypoints[i].longitude);
      }
    });

    test('merged mission uses first mission config', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      final merged = mergeMissions(segments, overlap: 1);

      expect(merged.config.flyToWaylineMode,
          testMission.config.flyToWaylineMode);
      expect(merged.config.globalTransitionalSpeed,
          testMission.config.globalTransitionalSpeed);
    });

    test('merged mission generates valid KMZ', () {
      final segments = splitMission(
        testMission,
        const SplitConfig(waypointsPerSegment: 150, overlap: 1),
      );

      final merged = mergeMissions(segments, overlap: 1);
      final kmz = KmzWriter.buildKmz(merged);
      final reparsed = KmzParser.parseBytes(kmz);
      expect(reparsed.waypoints.length, testMission.waypoints.length);
    });

    test('throws on empty mission list', () {
      expect(() => mergeMissions([]), throwsArgumentError);
    });

    test('returns single mission unchanged', () {
      final result = mergeMissions([testMission]);
      expect(identical(result, testMission), true);
    });
  });
}
