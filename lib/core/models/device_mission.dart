import 'mission_config.dart';

class DeviceMission {
  final String uuid;
  final int kmzSizeBytes;
  final String? author;
  final DateTime? createTime;
  final int waypointCount;
  final FinishAction? finishAction;

  const DeviceMission({
    required this.uuid,
    this.kmzSizeBytes = -1,
    this.author,
    this.createTime,
    this.waypointCount = 0,
    this.finishAction,
  });
}
