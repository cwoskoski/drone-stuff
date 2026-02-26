import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
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
    final slotDao = ref.read(deviceSlotDaoProvider);
    final entries = await channel.listFiles(waypointRoot);

    // Filter to UUID folders and sort alphabetically for stable slot numbering
    final uuids = entries.where((name) => uuidPattern.hasMatch(name)).toList()
      ..sort();

    final missions = <DeviceMission>[];
    for (var i = 0; i < uuids.length; i++) {
      final name = uuids[i];
      final slotNumber = i + 1;

      // Look up stored slot name from DB
      final slot = await slotDao.getByUuid(name);
      final slotName = slot?.name;

      // Ensure slot row exists in DB
      if (slot == null) {
        await slotDao.upsertSlot(DeviceSlotsCompanion.insert(
          uuid: name,
          slotNumber: slotNumber,
        ));
      } else if (slot.slotNumber != slotNumber) {
        // Update slot number if position changed
        await slotDao.upsertSlot(DeviceSlotsCompanion(
          uuid: Value(name),
          slotNumber: Value(slotNumber),
          name: Value(slotName),
          updatedAt: Value(slot.updatedAt),
        ));
      }

      final kmzPath = '$waypointRoot/$name/$name.kmz';
      try {
        final size = await channel.fileSize(kmzPath);
        final bytes = await channel.readFile(kmzPath);

        if (bytes.isEmpty) {
          missions.add(DeviceMission(
            uuid: name,
            kmzSizeBytes: size,
            slotNumber: slotNumber,
            name: slotName,
          ));
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
          slotNumber: slotNumber,
          name: slotName,
        ));
      } catch (_) {
        missions.add(DeviceMission(
          uuid: name,
          slotNumber: slotNumber,
          name: slotName,
        ));
      }
    }

    return missions;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMissions());
  }

  Future<void> deleteMission(String uuid) async {
    final channel = ref.read(shizukuChannelProvider);
    final slotDao = ref.read(deviceSlotDaoProvider);
    final missionDir = '$waypointRoot/$uuid';

    // Delete all files in the mission folder
    final files = await channel.listFiles(missionDir);
    for (final file in files) {
      await channel.deleteFile('$missionDir/$file');
    }
    // Delete the folder itself
    await channel.deleteFile(missionDir);

    // Clear slot name in DB
    await slotDao.deleteSlot(uuid);

    await refresh();
  }
}
