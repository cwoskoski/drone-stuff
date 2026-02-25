import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/kmz/kmz_writer.dart';
import '../../../core/models/action_group.dart';
import '../../../core/models/mission.dart';
import '../../../core/models/waypoint.dart';
import '../../missions/local/local_mission_repository.dart';
import '../../missions/local/local_missions_provider.dart';

/// Merge multiple missions into one, removing overlap waypoints at boundaries.
Mission mergeMissions(List<Mission> missions, {int overlap = 1}) {
  if (missions.isEmpty) {
    throw ArgumentError('No missions to merge');
  }
  if (missions.length == 1) return missions.first;

  final merged = <Waypoint>[];
  var globalIndex = 0;

  for (var m = 0; m < missions.length; m++) {
    final waypoints = missions[m].waypoints;
    // Skip overlap waypoints from the start of non-first missions
    final startOffset = (m > 0 && overlap > 0)
        ? overlap.clamp(0, waypoints.length)
        : 0;

    for (var i = startOffset; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final indexOffset = globalIndex - i;
      final remappedGroups = wp.actionGroups.map((g) {
        return ActionGroup(
          groupId: g.groupId,
          startIndex: g.startIndex + indexOffset,
          endIndex: g.endIndex + indexOffset,
          mode: g.mode,
          triggerType: g.triggerType,
          actions: g.actions,
        );
      }).toList();

      merged.add(Waypoint(
        index: globalIndex,
        longitude: wp.longitude,
        latitude: wp.latitude,
        executeHeight: wp.executeHeight,
        waypointSpeed: wp.waypointSpeed,
        heading: wp.heading,
        turn: wp.turn,
        useStraightLine: wp.useStraightLine,
        actionGroups: remappedGroups,
        gimbalHeading: wp.gimbalHeading,
      ));
      globalIndex++;
    }
  }

  final baseConfig = missions.first.config;

  return Mission(
    id: '',
    config: baseConfig,
    waypoints: merged,
    author: missions.first.author,
    createTime: missions.first.createTime,
    updateTime: missions.first.updateTime,
  );
}

enum MergeStep { idle, merging, saving, done, error }

class MergeState {
  final MergeStep step;
  final String message;

  const MergeState({
    this.step = MergeStep.idle,
    this.message = '',
  });
}

final mergeExecutorProvider =
    AsyncNotifierProvider.autoDispose<MergeExecutor, MergeState>(
  MergeExecutor.new,
);

class MergeExecutor extends AsyncNotifier<MergeState> {
  @override
  Future<MergeState> build() async => const MergeState();

  Future<void> executeMerge({
    required List<Mission> missions,
    required int overlap,
  }) async {
    try {
      state = const AsyncData(MergeState(
        step: MergeStep.merging,
        message: 'Merging missions...',
      ));

      final merged = mergeMissions(missions, overlap: overlap);

      state = const AsyncData(MergeState(
        step: MergeStep.saving,
        message: 'Saving merged mission...',
      ));

      final kmzBytes = KmzWriter.buildKmz(merged);
      final repo = ref.read(localMissionRepositoryProvider);
      await repo.importKmz(kmzBytes, 'merged_${missions.length}_segments.kmz');

      state = AsyncData(MergeState(
        step: MergeStep.done,
        message: 'Merge complete! ${merged.waypoints.length} waypoints.',
      ));
    } catch (e) {
      state = AsyncData(MergeState(
        step: MergeStep.error,
        message: 'Merge failed: $e',
      ));
    }
  }

  void reset() {
    state = const AsyncData(MergeState());
  }
}
