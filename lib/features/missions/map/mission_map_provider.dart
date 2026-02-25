import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/waypoint.dart';

/// Convert waypoints to LatLng points for map display.
List<LatLng> waypointsToLatLngs(List<Waypoint> waypoints) {
  return waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();
}

/// Build a thinned list of marker indices for large missions.
///
/// For <= 100 waypoints, returns all indices.
/// For > 100, returns every 10th index plus first and last.
List<int> thinMarkerIndices(int waypointCount) {
  if (waypointCount <= 100) {
    return List.generate(waypointCount, (i) => i);
  }

  final indices = <int>{0, waypointCount - 1};
  for (var i = 0; i < waypointCount; i += 10) {
    indices.add(i);
  }

  final sorted = indices.toList()..sort();
  return sorted;
}

/// Compute a CameraFit that shows all waypoints with padding.
CameraFit? fitBounds(List<LatLng> points) {
  if (points.isEmpty) return null;
  if (points.length == 1) {
    return CameraFit.coordinates(
      coordinates: [
        LatLng(points[0].latitude - 0.001, points[0].longitude - 0.001),
        LatLng(points[0].latitude + 0.001, points[0].longitude + 0.001),
      ],
      padding: const EdgeInsets.all(48),
    );
  }
  return CameraFit.coordinates(
    coordinates: points,
    padding: const EdgeInsets.all(48),
  );
}
