import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/kmz/kmz_parser.dart';
import '../../../core/models/device_mission.dart';
import '../../../core/platform/shizuku_channel.dart';
import '../../../core/platform/shizuku_state.dart';

final deviceMissionsProvider =
    AsyncNotifierProvider.autoDispose<DeviceMissionsNotifier, List<DeviceMission>>(
  DeviceMissionsNotifier.new,
);

class DeviceMissionsNotifier extends AsyncNotifier<List<DeviceMission>> {
  @override
  Future<List<DeviceMission>> build() => _loadMissions();

  Future<List<DeviceMission>> _loadMissions() async {
    final channel = ref.read(shizukuChannelProvider);
    final entries = await channel.listFiles(waypointRoot);

    final missions = <DeviceMission>[];
    for (final name in entries) {
      if (!uuidPattern.hasMatch(name)) continue;

      final kmzPath = '$waypointRoot/$name/$name.kmz';
      try {
        final size = await channel.fileSize(kmzPath);
        final bytes = await channel.readFile(kmzPath);

        if (bytes.isEmpty) {
          missions.add(DeviceMission(uuid: name, kmzSizeBytes: size));
          continue;
        }

        final mission = KmzParser.parseBytes(bytes);
        missions.add(DeviceMission(
          uuid: name,
          kmzSizeBytes: size,
          author: mission.author,
          createTime: mission.createTime,
          waypointCount: mission.waypoints.length,
          finishAction: mission.config.finishAction,
        ));
      } catch (_) {
        missions.add(DeviceMission(uuid: name));
      }
    }

    return missions;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMissions());
  }
}
