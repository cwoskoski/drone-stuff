import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/kmz/kmz_writer.dart';
import '../../core/models/mission.dart';
import '../../core/models/mission_config.dart';
import '../../core/models/waypoint.dart';
import '../missions/local/local_missions_provider.dart';

class EditConfig {
  final FinishAction? finishAction;
  final double? transitionalSpeed;
  final double? bulkSpeed;
  final double? bulkAltitude;

  const EditConfig({
    this.finishAction,
    this.transitionalSpeed,
    this.bulkSpeed,
    this.bulkAltitude,
  });
}

enum EditStep { idle, editing, saving, done, error }

class EditState {
  final EditStep step;
  final String message;

  const EditState({
    this.step = EditStep.idle,
    this.message = '',
  });
}

final editExecutorProvider =
    AsyncNotifierProvider.autoDispose<EditExecutor, EditState>(
  EditExecutor.new,
);

class EditExecutor extends AsyncNotifier<EditState> {
  @override
  Future<EditState> build() async => const EditState();

  Future<void> executeEdit({
    required String sourceMissionId,
    required Uint8List originalKmzBytes,
    required Mission originalMission,
    required EditConfig config,
  }) async {
    try {
      state = const AsyncData(EditState(
        step: EditStep.editing,
        message: 'Applying changes...',
      ));

      // Build modified waypoints if bulk changes requested
      List<Waypoint>? modifiedWaypoints;
      if (config.bulkSpeed != null || config.bulkAltitude != null) {
        modifiedWaypoints = originalMission.waypoints.map((wp) {
          return Waypoint(
            index: wp.index,
            longitude: wp.longitude,
            latitude: wp.latitude,
            executeHeight: config.bulkAltitude ?? wp.executeHeight,
            waypointSpeed: config.bulkSpeed ?? wp.waypointSpeed,
            heading: wp.heading,
            turn: wp.turn,
            useStraightLine: wp.useStraightLine,
            actionGroups: wp.actionGroups,
            gimbalHeading: wp.gimbalHeading,
          );
        }).toList();
      }

      // Use rewriteKmz for DOM-level modification
      final editedBytes = KmzWriter.rewriteKmz(
        originalKmzBytes,
        finishAction: config.finishAction,
        speed: config.transitionalSpeed,
        waypoints: modifiedWaypoints,
      );

      state = const AsyncData(EditState(
        step: EditStep.saving,
        message: 'Saving edited mission...',
      ));

      final repo = ref.read(localMissionRepositoryProvider);
      await repo.importKmz(editedBytes, 'edited_${originalMission.author ?? "mission"}.kmz');

      state = const AsyncData(EditState(
        step: EditStep.done,
        message: 'Edit saved as new mission.',
      ));
    } catch (e) {
      state = AsyncData(EditState(
        step: EditStep.error,
        message: 'Edit failed: $e',
      ));
    }
  }

  void reset() {
    state = const AsyncData(EditState());
  }
}
