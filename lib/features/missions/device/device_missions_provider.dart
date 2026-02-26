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

    final uuids =
        entries.where((name) => uuidPattern.hasMatch(name)).toList();

    // First pass: load all missions (unordered)
    final missions = <DeviceMission>[];
    for (final name in uuids) {
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

    // Sort by createTime descending (newest first) to match DJI Fly display order.
    // Missions without createTime sort to the end.
    missions.sort((a, b) {
      final ta = a.createTime?.millisecondsSinceEpoch ?? 0;
      final tb = b.createTime?.millisecondsSinceEpoch ?? 0;
      if (ta != tb) return tb.compareTo(ta);
      return a.uuid.compareTo(b.uuid);
    });

    // Second pass: assign slot numbers and look up DB names
    final result = <DeviceMission>[];
    for (var i = 0; i < missions.length; i++) {
      final m = missions[i];
      final slotNumber = i + 1;

      final slot = await slotDao.getByUuid(m.uuid);
      final slotName = slot?.name;

      if (slot == null) {
        await slotDao.upsertSlot(DeviceSlotsCompanion.insert(
          uuid: m.uuid,
          slotNumber: slotNumber,
        ));
      } else if (slot.slotNumber != slotNumber) {
        await slotDao.upsertSlot(DeviceSlotsCompanion(
          uuid: Value(m.uuid),
          slotNumber: Value(slotNumber),
          name: Value(slotName),
          updatedAt: Value(slot.updatedAt),
        ));
      }

      result.add(DeviceMission(
        uuid: m.uuid,
        kmzSizeBytes: m.kmzSizeBytes,
        author: m.author,
        createTime: m.createTime,
        waypointCount: m.waypointCount,
        finishAction: m.finishAction,
        slotNumber: slotNumber,
        name: slotName,
      ));
    }

    return result;
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
