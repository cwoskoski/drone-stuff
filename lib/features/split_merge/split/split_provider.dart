import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/kmz/kmz_writer.dart';
import '../../../core/models/action_group.dart';
import '../../../core/models/mission.dart';
import '../../../core/models/mission_config.dart';
import '../../../core/models/waypoint.dart';
import '../../../core/utils/flight_calculator.dart';
import '../../missions/local/local_mission_repository.dart';
import '../../missions/local/local_missions_provider.dart';

class SplitConfig {
  final int waypointsPerSegment;
  final int overlap;
  final List<FinishAction> segmentFinishActions;
  final Duration? maxFlightTime;

  const SplitConfig({
    this.waypointsPerSegment = 150,
    this.overlap = 1,
    this.segmentFinishActions = const [],
    this.maxFlightTime,
  });
}

class SplitSegmentInfo {
  final int startIndex;
  final int endIndex;
  final int waypointCount;
  final FinishAction finishAction;

  const SplitSegmentInfo({
    required this.startIndex,
    required this.endIndex,
    required this.waypointCount,
    required this.finishAction,
  });
}

/// Compute the segment layout without actually splitting.
List<SplitSegmentInfo> computeSegments(
  int totalWaypoints,
  SplitConfig config,
) {
  final segments = <SplitSegmentInfo>[];
  final step = config.waypointsPerSegment - config.overlap;
  var start = 0;
  var segIndex = 0;

  while (start < totalWaypoints) {
    var end = start + config.waypointsPerSegment;
    if (end > totalWaypoints) end = totalWaypoints;

    final isLast = end >= totalWaypoints;
    final defaultAction =
        isLast ? FinishAction.goHome : FinishAction.noAction;
    final finishAction = segIndex < config.segmentFinishActions.length
        ? config.segmentFinishActions[segIndex]
        : defaultAction;

    segments.add(SplitSegmentInfo(
      startIndex: start,
      endIndex: end - 1,
      waypointCount: end - start,
      finishAction: finishAction,
    ));

    start += step;
    if (start >= totalWaypoints) break;
    segIndex++;
  }

  return segments;
}

/// Compute segment layout by maximum flight time per segment.
List<SplitSegmentInfo> computeSegmentsByTime(
  List<Waypoint> waypoints,
  Duration maxTime,
  int overlap,
  List<FinishAction> customActions,
) {
  if (waypoints.isEmpty) return [];

  final segments = <SplitSegmentInfo>[];
  var start = 0;
  var segIndex = 0;

  while (start < waypoints.length) {
    final remaining = waypoints.sublist(start);
    var count = waypointsForMaxTime(remaining, maxTime);

    // Ensure we don't exceed bounds
    if (start + count > waypoints.length) {
      count = waypoints.length - start;
    }

    final end = start + count;
    final isLast = end >= waypoints.length;
    final defaultAction =
        isLast ? FinishAction.goHome : FinishAction.noAction;
    final finishAction = segIndex < customActions.length
        ? customActions[segIndex]
        : defaultAction;

    segments.add(SplitSegmentInfo(
      startIndex: start,
      endIndex: end - 1,
      waypointCount: count,
      finishAction: finishAction,
    ));

    if (isLast) break;

    // Advance with overlap
    final step = count - overlap;
    start += step < 1 ? 1 : step;
    segIndex++;
  }

  return segments;
}

/// Split a mission into segments, returning new Mission objects.
List<Mission> splitMission(Mission source, SplitConfig config) {
  final segments = config.maxFlightTime != null
      ? computeSegmentsByTime(
          source.waypoints,
          config.maxFlightTime!,
          config.overlap,
          config.segmentFinishActions,
        )
      : computeSegments(source.waypoints.length, config);
  final results = <Mission>[];

  for (final seg in segments) {
    final sourceWaypoints =
        source.waypoints.sublist(seg.startIndex, seg.endIndex + 1);

    // Re-index waypoints from 0 and remap action groups
    final reindexed = <Waypoint>[];
    for (var i = 0; i < sourceWaypoints.length; i++) {
      final wp = sourceWaypoints[i];
      final remappedGroups = wp.actionGroups.map((g) {
        return ActionGroup(
          groupId: g.groupId,
          startIndex: g.startIndex - seg.startIndex,
          endIndex: g.endIndex - seg.startIndex,
          mode: g.mode,
          triggerType: g.triggerType,
          actions: g.actions,
        );
      }).toList();

      reindexed.add(Waypoint(
        index: i,
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
    }

    final segConfig = MissionConfig(
      finishAction: seg.finishAction,
      flyToWaylineMode: source.config.flyToWaylineMode,
      exitOnRCLost: source.config.exitOnRCLost,
      executeRCLostAction: source.config.executeRCLostAction,
      globalTransitionalSpeed: source.config.globalTransitionalSpeed,
      droneEnumValue: source.config.droneEnumValue,
      droneSubEnumValue: source.config.droneSubEnumValue,
    );

    results.add(Mission(
      id: '',
      config: segConfig,
      waypoints: reindexed,
      author: source.author,
      createTime: source.createTime,
      updateTime: source.updateTime,
    ));
  }

  return results;
}

enum SplitStep { idle, splitting, saving, done, error }

class SplitState {
  final SplitStep step;
  final String message;
  final int segmentsSaved;
  final int totalSegments;

  const SplitState({
    this.step = SplitStep.idle,
    this.message = '',
    this.segmentsSaved = 0,
    this.totalSegments = 0,
  });
}

final splitExecutorProvider =
    AsyncNotifierProvider.autoDispose<SplitExecutor, SplitState>(
  SplitExecutor.new,
);

class SplitExecutor extends AsyncNotifier<SplitState> {
  @override
  Future<SplitState> build() async => const SplitState();

  Future<void> executeSplit({
    required Mission source,
    required String parentId,
    required SplitConfig config,
  }) async {
    try {
      state = const AsyncData(SplitState(
        step: SplitStep.splitting,
        message: 'Splitting mission...',
      ));

      final segments = splitMission(source, config);

      state = AsyncData(SplitState(
        step: SplitStep.saving,
        message: 'Saving segments...',
        totalSegments: segments.length,
      ));

      final repo = ref.read(localMissionRepositoryProvider);

      for (var i = 0; i < segments.length; i++) {
        final segment = segments[i];
        final kmzBytes = KmzWriter.buildKmz(segment);

        await repo.saveSplitSegment(
          parentId: parentId,
          segmentIndex: i,
          mission: segment,
          kmzBytes: kmzBytes,
        );

        state = AsyncData(SplitState(
          step: SplitStep.saving,
          message: 'Saved segment ${i + 1} of ${segments.length}',
          segmentsSaved: i + 1,
          totalSegments: segments.length,
        ));
      }

      state = AsyncData(SplitState(
        step: SplitStep.done,
        message: 'Split complete! ${segments.length} segments created.',
        segmentsSaved: segments.length,
        totalSegments: segments.length,
      ));
    } catch (e) {
      state = AsyncData(SplitState(
        step: SplitStep.error,
        message: 'Split failed: $e',
      ));
    }
  }

  void reset() {
    state = const AsyncData(SplitState());
  }
}
