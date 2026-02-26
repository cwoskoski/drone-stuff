import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/mission.dart';
import '../../../core/models/mission_config.dart';
import '../../missions/map/mission_map_provider.dart';
import '../../missions/map/widgets/waypoint_marker.dart';
import 'split_provider.dart';

class SplitPreviewScreen extends StatefulWidget {
  final Mission mission;
  final SplitConfig config;

  const SplitPreviewScreen({
    super.key,
    required this.mission,
    required this.config,
  });

  @override
  State<SplitPreviewScreen> createState() => _SplitPreviewScreenState();
}

class _SplitPreviewScreenState extends State<SplitPreviewScreen> {
  bool _satellite = false;

  static const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _esriTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/'
      'World_Imagery/MapServer/tile/{z}/{y}/{x}';

  static const _segmentColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final segments = widget.config.maxFlightTime != null
        ? computeSegmentsByTime(
            widget.mission.waypoints,
            widget.config.maxFlightTime!,
            widget.config.overlap,
            widget.config.segmentFinishActions,
          )
        : computeSegments(widget.mission.waypoints.length, widget.config);
    final allPoints = waypointsToLatLngs(widget.mission.waypoints);
    final camera = fitBounds(allPoints);

    return Scaffold(
      appBar: AppBar(title: const Text('Split Preview')),
      body: Column(
        children: [
          // Map
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCameraFit: camera),
              children: [
                TileLayer(
                  urlTemplate: _satellite ? _esriTileUrl : _osmTileUrl,
                  userAgentPackageName: 'com.example.dronestuff',
                ),
                // Polylines per segment
                PolylineLayer(
                  polylines: segments.asMap().entries.map((entry) {
                    final i = entry.key;
                    final seg = entry.value;
                    final points = widget.mission.waypoints
                        .sublist(seg.startIndex, seg.endIndex + 1)
                        .map((w) => LatLng(w.latitude, w.longitude))
                        .toList();
                    return Polyline(
                      points: points,
                      color: _segmentColors[i % _segmentColors.length],
                      strokeWidth: 3,
                    );
                  }).toList(),
                ),
                // Boundary markers (first & last of each segment)
                MarkerLayer(
                  markers: _buildBoundaryMarkers(segments),
                ),
              ],
            ),
          ),
          // Legend
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: segments.asMap().entries.map((entry) {
                  final i = entry.key;
                  final seg = entry.value;
                  final color = _segmentColors[i % _segmentColors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 4,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Seg ${i + 1}: WP ${seg.startIndex}–${seg.endIndex} '
                          '(${seg.waypointCount} pts)',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        _FinishActionBadge(action: seg.finishAction),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => setState(() => _satellite = !_satellite),
        child: Icon(_satellite ? Icons.map : Icons.satellite),
      ),
    );
  }

  List<Marker> _buildBoundaryMarkers(List<SplitSegmentInfo> segments) {
    final markers = <Marker>[];
    final waypoints = widget.mission.waypoints;

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final color = _segmentColors[i % _segmentColors.length];

      // First waypoint of segment
      final first = waypoints[seg.startIndex];
      markers.add(Marker(
        point: LatLng(first.latitude, first.longitude),
        width: 28,
        height: 28,
        child: WaypointMarker(index: seg.startIndex, color: color),
      ));

      // Last waypoint of segment
      final last = waypoints[seg.endIndex];
      markers.add(Marker(
        point: LatLng(last.latitude, last.longitude),
        width: 28,
        height: 28,
        child: WaypointMarker(index: seg.endIndex, color: color),
      ));
    }

    return markers;
  }
}

class _FinishActionBadge extends StatelessWidget {
  final FinishAction action;

  const _FinishActionBadge({required this.action});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (action) {
      FinishAction.goHome => ('Home', Colors.green),
      FinishAction.noAction => ('Hover', Colors.amber),
      FinishAction.autoLand => ('Land', Colors.blue),
      FinishAction.backToFirstWaypoint => ('Back', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
