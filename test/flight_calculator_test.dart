import 'package:drone_stuff/core/models/waypoint.dart';
import 'package:drone_stuff/core/utils/flight_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Waypoint _wp({
  required int index,
  required double lat,
  required double lon,
  double height = 50.0,
  double speed = 10.0,
}) {
  return Waypoint(
    index: index,
    latitude: lat,
    longitude: lon,
    executeHeight: height,
    waypointSpeed: speed,
  );
}

void main() {
  group('haversineDistance', () {
    test('returns 0 for identical points', () {
      expect(haversineDistance(0, 0, 0, 0), 0.0);
    });

    test('New York to Los Angeles ~3944 km', () {
      // JFK: 40.6413, -73.7781  LAX: 33.9425, -118.4081
      final dist = haversineDistance(40.6413, -73.7781, 33.9425, -118.4081);
      expect(dist, closeTo(3944000, 50000)); // within 50 km
    });

    test('London to Paris ~344 km', () {
      final dist = haversineDistance(51.5074, -0.1278, 48.8566, 2.3522);
      expect(dist, closeTo(344000, 5000)); // within 5 km
    });

    test('short distance ~111 km per degree latitude at equator', () {
      final dist = haversineDistance(0, 0, 1, 0);
      expect(dist, closeTo(111195, 500));
    });

    test('antipodal points ~20000 km', () {
      final dist = haversineDistance(0, 0, 0, 180);
      expect(dist, closeTo(20015087, 1000));
    });
  });

  group('waypointDistance', () {
    test('same position returns 0', () {
      final wp = _wp(index: 0, lat: 0, lon: 0);
      expect(waypointDistance(wp, wp), 0.0);
    });

    test('includes altitude delta', () {
      final wp1 = _wp(index: 0, lat: 0, lon: 0, height: 0);
      final wp2 = _wp(index: 1, lat: 0, lon: 0, height: 100);
      expect(waypointDistance(wp1, wp2), closeTo(100, 0.01));
    });

    test('3D distance is greater than horizontal distance', () {
      final wp1 = _wp(index: 0, lat: 34.0, lon: -114.0, height: 50);
      final wp2 = _wp(index: 1, lat: 34.001, lon: -114.001, height: 100);
      final hDist = haversineDistance(34.0, -114.0, 34.001, -114.001);
      final dist3d = waypointDistance(wp1, wp2);
      expect(dist3d, greaterThan(hDist));
    });
  });

  group('estimateFlight', () {
    test('empty list returns zero', () {
      final result = estimateFlight([]);
      expect(result.totalDistance, 0.0);
      expect(result.flightTime, Duration.zero);
    });

    test('single waypoint returns zero', () {
      final result = estimateFlight([_wp(index: 0, lat: 0, lon: 0)]);
      expect(result.totalDistance, 0.0);
      expect(result.flightTime, Duration.zero);
    });

    test('two waypoints with known distance and speed', () {
      // ~111.2 km apart (1 degree latitude at equator), speed 10 m/s
      final wps = [
        _wp(index: 0, lat: 0, lon: 0, speed: 10),
        _wp(index: 1, lat: 1, lon: 0, speed: 10),
      ];
      final result = estimateFlight(wps);
      expect(result.totalDistance, closeTo(111195, 500));
      // time = 111195 / 10 = 11119.5 s ≈ 185 min
      expect(result.flightTime.inSeconds, closeTo(11120, 50));
    });

    test('uses destination waypoint speed', () {
      final wps = [
        _wp(index: 0, lat: 0, lon: 0, speed: 5),
        _wp(index: 1, lat: 0.001, lon: 0, speed: 20),
      ];
      final result = estimateFlight(wps);
      final dist = result.totalDistance;
      // Time should use speed=20, not speed=5
      final expectedSeconds = dist / 20;
      expect(
        result.flightTime.inMilliseconds,
        closeTo(expectedSeconds * 1000, 50),
      );
    });

    test('accumulates multiple legs', () {
      final wps = [
        _wp(index: 0, lat: 0, lon: 0, speed: 10),
        _wp(index: 1, lat: 0.001, lon: 0, speed: 10),
        _wp(index: 2, lat: 0.002, lon: 0, speed: 10),
        _wp(index: 3, lat: 0.003, lon: 0, speed: 10),
      ];
      final result = estimateFlight(wps);
      // 3 legs of ~111.2 m each at 10 m/s
      expect(result.totalDistance, closeTo(333.6, 5));
      expect(result.flightTime.inSeconds, closeTo(33, 2));
    });
  });

  group('formatDuration', () {
    test('zero duration', () {
      expect(formatDuration(Duration.zero), '0s');
    });

    test('seconds only', () {
      expect(formatDuration(const Duration(seconds: 45)), '45s');
    });

    test('minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 5, seconds: 23)), '5m 23s');
    });

    test('minutes only (exact)', () {
      expect(formatDuration(const Duration(minutes: 10)), '10m');
    });

    test('hours and minutes', () {
      expect(
          formatDuration(const Duration(hours: 1, minutes: 12)), '1h 12m');
    });

    test('hours only (exact)', () {
      expect(formatDuration(const Duration(hours: 2)), '2h');
    });

    test('negative duration returns 0s', () {
      expect(formatDuration(const Duration(seconds: -5)), '0s');
    });
  });

  group('formatDistance', () {
    test('short distance in meters', () {
      expect(formatDistance(500), '500 m');
    });

    test('1 km exactly', () {
      expect(formatDistance(1000), '1.00 km');
    });

    test('long distance in km', () {
      expect(formatDistance(12345), '12.35 km');
    });
  });

  group('waypointsForMaxTime', () {
    test('empty list returns 0', () {
      expect(waypointsForMaxTime([], const Duration(minutes: 5)), 0);
    });

    test('single waypoint returns 1', () {
      expect(
        waypointsForMaxTime(
            [_wp(index: 0, lat: 0, lon: 0)], const Duration(minutes: 5)),
        1,
      );
    });

    test('all waypoints fit within budget', () {
      // 3 waypoints, ~111m apart each at 10 m/s = ~11s per leg, 22s total
      final wps = [
        _wp(index: 0, lat: 0, lon: 0, speed: 10),
        _wp(index: 1, lat: 0.001, lon: 0, speed: 10),
        _wp(index: 2, lat: 0.002, lon: 0, speed: 10),
      ];
      expect(waypointsForMaxTime(wps, const Duration(minutes: 1)), 3);
    });

    test('splits at correct point with tight budget', () {
      // Each leg ~111m at 10 m/s = ~11.1s per leg
      final wps = List.generate(
        10,
        (i) => _wp(index: i, lat: i * 0.001, lon: 0, speed: 10),
      );
      // Budget of 25s should fit ~2 legs (22.2s), 3rd leg exceeds at 33.3s
      final count = waypointsForMaxTime(wps, const Duration(seconds: 25));
      expect(count, 3); // wp 0, 1, 2 (two legs fit, third leg starts wp 3)
    });

    test('returns at least 2 for non-trivial lists', () {
      // Even with 0 budget, should return at least 2
      final wps = [
        _wp(index: 0, lat: 0, lon: 0, speed: 10),
        _wp(index: 1, lat: 1, lon: 0, speed: 10),
        _wp(index: 2, lat: 2, lon: 0, speed: 10),
      ];
      expect(
        waypointsForMaxTime(wps, Duration.zero),
        greaterThanOrEqualTo(2),
      );
    });
  });
}
