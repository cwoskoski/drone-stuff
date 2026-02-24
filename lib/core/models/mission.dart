import 'dart:typed_data';

import 'mission_config.dart';
import 'waypoint.dart';

class Mission {
  final String id;
  final MissionConfig config;
  final List<Waypoint> waypoints;
  final String? author;
  final DateTime? createTime;
  final DateTime? updateTime;
  final Uint8List? rawKmzBytes;

  const Mission({
    required this.id,
    required this.config,
    required this.waypoints,
    this.author,
    this.createTime,
    this.updateTime,
    this.rawKmzBytes,
  });
}
