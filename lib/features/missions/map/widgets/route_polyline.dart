import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/models/waypoint.dart';

/// Build polylines from waypoints.
///
/// With no [segmentColors], returns a single blue polyline through all points.
/// With [segmentColors], splits waypoints into equal segments with different
/// colors (for DS-010 split preview).
List<Polyline> buildRoutePolylines(
  List<Waypoint> waypoints, {
  List<Color>? segmentColors,
}) {
  if (waypoints.isEmpty) return [];

  final points = waypoints
      .map((w) => LatLng(w.latitude, w.longitude))
      .toList();

  if (segmentColors == null || segmentColors.isEmpty) {
    return [
      Polyline(
        points: points,
        color: Colors.blue,
        strokeWidth: 3,
      ),
    ];
  }

  final segmentSize = (waypoints.length / segmentColors.length).ceil();
  final polylines = <Polyline>[];

  for (var i = 0; i < segmentColors.length; i++) {
    final start = i * segmentSize;
    var end = (i + 1) * segmentSize;
    if (end > points.length) end = points.length;
    // Include previous last point to connect segments
    final segStart = i == 0 ? start : start;
    final segPoints = points.sublist(
      i == 0 ? segStart : segStart - 1,
      end,
    );
    if (segPoints.length >= 2) {
      polylines.add(Polyline(
        points: segPoints,
        color: segmentColors[i],
        strokeWidth: 3,
      ));
    }
  }

  return polylines;
}
