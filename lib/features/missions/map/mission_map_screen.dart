import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/waypoint.dart';
import '../detail/mission_detail_provider.dart';
import 'mission_map_provider.dart';
import 'widgets/route_polyline.dart';
import 'widgets/waypoint_marker.dart';

class MissionMapScreen extends ConsumerStatefulWidget {
  final String id;
  final String source;

  const MissionMapScreen({
    super.key,
    required this.id,
    required this.source,
  });

  @override
  ConsumerState<MissionMapScreen> createState() => _MissionMapScreenState();
}

class _MissionMapScreenState extends ConsumerState<MissionMapScreen> {
  bool _satellite = false;

  static const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _esriTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/'
      'World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  Widget build(BuildContext context) {
    final missionAsync =
        ref.watch(missionDetailProvider((widget.id, widget.source)));

    return Scaffold(
      appBar: AppBar(title: const Text('Mission Map')),
      body: missionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (mission) {
          final points = waypointsToLatLngs(mission.waypoints);
          final camera = fitBounds(points);
          final markerIndices = thinMarkerIndices(mission.waypoints.length);

          return FlutterMap(
            options: MapOptions(
              initialCameraFit: camera,
            ),
            children: [
              TileLayer(
                urlTemplate: _satellite ? _esriTileUrl : _osmTileUrl,
                userAgentPackageName: 'com.example.dronestuff',
              ),
              PolylineLayer(
                polylines: buildRoutePolylines(mission.waypoints),
              ),
              MarkerLayer(
                markers: markerIndices.map((i) {
                  final wp = mission.waypoints[i];
                  return Marker(
                    point: LatLng(wp.latitude, wp.longitude),
                    width: 24,
                    height: 24,
                    child: GestureDetector(
                      onTap: () => _showWaypointDetails(context, wp),
                      child: WaypointMarker(index: wp.index),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => setState(() => _satellite = !_satellite),
        tooltip: _satellite ? 'Street view' : 'Satellite view',
        child: Icon(_satellite ? Icons.map : Icons.satellite),
      ),
    );
  }

  void _showWaypointDetails(BuildContext context, Waypoint wp) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waypoint ${wp.index}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Latitude: ${wp.latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${wp.longitude.toStringAsFixed(6)}'),
            Text('Altitude: ${wp.executeHeight} m'),
            Text('Speed: ${wp.waypointSpeed} m/s'),
            Text('Heading mode: ${wp.heading.mode}'),
            Text('Heading angle: ${wp.heading.angle}°'),
            Text('Turn mode: ${wp.turn.mode}'),
            if (wp.gimbalHeading != null) ...[
              Text('Gimbal pitch: ${wp.gimbalHeading!.pitchAngle}°'),
              Text('Gimbal yaw: ${wp.gimbalHeading!.yawAngle}°'),
            ],
            if (wp.actionGroups.isNotEmpty)
              Text('Action groups: ${wp.actionGroups.length}'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
