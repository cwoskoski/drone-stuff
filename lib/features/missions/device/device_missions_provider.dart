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

    // Find the highest existing slot number so new UUIDs get appended
    int maxSlot = 0;
    for (final uuid in uuids) {
      final slot = await slotDao.getByUuid(uuid);
      if (slot != null && slot.slotNumber > maxSlot) {
        maxSlot = slot.slotNumber;
      }
    }

    final missions = <DeviceMission>[];
    for (final name in uuids) {
      // Look up stored slot from DB
      var slot = await slotDao.getByUuid(name);

      // New UUID not yet in DB — assign next slot number
      if (slot == null) {
        maxSlot++;
        await slotDao.upsertSlot(DeviceSlotsCompanion.insert(
          uuid: name,
          slotNumber: maxSlot,
        ));
        slot = await slotDao.getByUuid(name);
      }

      final slotNumber = slot!.slotNumber;
      final slotName = slot.name;

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

    // Sort by slot number for display
    missions.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));

    return missions;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadMissions());
  }
}
