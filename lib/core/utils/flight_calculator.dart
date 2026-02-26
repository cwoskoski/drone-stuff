import 'dart:math';

import '../models/waypoint.dart';

/// Great-circle distance between two lat/lon points in meters (Haversine).
double haversineDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadius = 6371000.0; // meters
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * pi / 180;

/// 3D distance between two waypoints (haversine + altitude delta).
double waypointDistance(Waypoint wp1, Waypoint wp2) {
  final hDist = haversineDistance(
    wp1.latitude,
    wp1.longitude,
    wp2.latitude,
    wp2.longitude,
  );
  final dAlt = wp2.executeHeight - wp1.executeHeight;
  return sqrt(hDist * hDist + dAlt * dAlt);
}

/// Estimate total flight distance and time for a waypoint list.
///
/// Each leg's time is computed using the *destination* waypoint's speed.
({double totalDistance, Duration flightTime}) estimateFlight(
  List<Waypoint> waypoints,
) {
  if (waypoints.length < 2) {
    return (totalDistance: 0.0, flightTime: Duration.zero);
  }

  var totalDist = 0.0;
  var totalSeconds = 0.0;

  for (var i = 1; i < waypoints.length; i++) {
    final dist = waypointDistance(waypoints[i - 1], waypoints[i]);
    totalDist += dist;
    final speed = waypoints[i].waypointSpeed;
    if (speed > 0) {
      totalSeconds += dist / speed;
    }
  }

  return (
    totalDistance: totalDist,
    flightTime: Duration(milliseconds: (totalSeconds * 1000).round()),
  );
}

/// Format a Duration as a human-readable string, e.g. "5m 23s" or "1h 12m".
String formatDuration(Duration d) {
  final totalSeconds = d.inSeconds;
  if (totalSeconds <= 0) return '0s';

  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
  if (minutes > 0) {
    return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
  }
  return '${seconds}s';
}

/// Format a distance in meters as a human-readable string.
String formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.round()} m';
}

/// Walk waypoints accumulating flight time; return the count of waypoints
/// that fit within [maxTime].
///
/// Returns at least 2 (minimum viable segment) or waypoints.length if the
/// entire list fits within the budget.
int waypointsForMaxTime(List<Waypoint> waypoints, Duration maxTime) {
  if (waypoints.length <= 2) return waypoints.length;

  final budgetSeconds = maxTime.inMilliseconds / 1000.0;
  var accumulated = 0.0;

  for (var i = 1; i < waypoints.length; i++) {
    final dist = waypointDistance(waypoints[i - 1], waypoints[i]);
    final speed = waypoints[i].waypointSpeed;
    final legTime = speed > 0 ? dist / speed : 0.0;
    accumulated += legTime;

    if (accumulated > budgetSeconds) {
      // Return count including waypoint i (the one that exceeded budget)
      // so segments overlap correctly; minimum 2
      return i < 2 ? 2 : i;
    }
  }

  return waypoints.length;
}
