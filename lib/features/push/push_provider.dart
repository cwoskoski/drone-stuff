import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../core/database/app_database.dart';
import '../../core/database/providers.dart';
import '../../core/platform/shizuku_channel.dart';
import '../../core/platform/shizuku_state.dart';
import '../missions/local/local_missions_provider.dart';

enum PushStep { idle, backingUp, pushing, verifying, success, error }

class PushState {
  final PushStep step;
  final String message;
  final int? primarySize;
  final int? tempSize;
  final int? expectedSize;

  const PushState({
    this.step = PushStep.idle,
    this.message = '',
    this.primarySize,
    this.tempSize,
    this.expectedSize,
  });

  PushState copyWith({
    PushStep? step,
    String? message,
    int? primarySize,
    int? tempSize,
    int? expectedSize,
  }) {
    return PushState(
      step: step ?? this.step,
      message: message ?? this.message,
      primarySize: primarySize ?? this.primarySize,
      tempSize: tempSize ?? this.tempSize,
      expectedSize: expectedSize ?? this.expectedSize,
    );
  }
}

final pushProvider =
    AsyncNotifierProvider.autoDispose<PushNotifier, PushState>(
  PushNotifier.new,
);

class PushNotifier extends AsyncNotifier<PushState> {
  @override
  Future<PushState> build() async => const PushState();

  Future<void> pushMission({
    required String localMissionId,
    required String targetUuid,
    required bool createBackup,
  }) async {
    final channel = ref.read(shizukuChannelProvider);
    final repo = ref.read(localMissionRepositoryProvider);
    final documentsPath = ref.read(documentsPathProvider);
    final slotDao = ref.read(deviceSlotDaoProvider);

    try {
      // Load local mission KMZ bytes
      final result = await repo.getMission(localMissionId);
      if (result == null) {
        state = AsyncData(const PushState(
          step: PushStep.error,
          message: 'Local mission not found',
        ));
        return;
      }
      final Uint8List bytes = result.bytes;
      final sourceFileName = result.metadata.fileName;

      final devicePrimary = '$waypointRoot/$targetUuid/$targetUuid.kmz';
      final deviceTemp = '$waypointRoot/kmzTemp/$targetUuid.kmz';

      // Backup existing KMZ
      if (createBackup) {
        state = const AsyncData(PushState(
          step: PushStep.backingUp,
          message: 'Backing up existing KMZ...',
        ));

        try {
          final existingBytes = await channel.readFile(devicePrimary);
          if (existingBytes.isNotEmpty) {
            final backupDir = Directory(p.join(documentsPath, 'backups'));
            if (!backupDir.existsSync()) {
              backupDir.createSync(recursive: true);
            }
            final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
            final backupPath = p.join(
              backupDir.path,
              '${targetUuid}_$timestamp.kmz',
            );
            File(backupPath).writeAsBytesSync(existingBytes);
          }
        } catch (e) {
          // Backup failure is non-fatal — continue with push
        }
      }

      // Push to primary location
      state = const AsyncData(PushState(
        step: PushStep.pushing,
        message: 'Pushing to primary location...',
      ));
      await channel.writeFile(devicePrimary, bytes);

      // Push to kmzTemp
      state = const AsyncData(PushState(
        step: PushStep.pushing,
        message: 'Pushing to kmzTemp...',
      ));
      await channel.writeFile(deviceTemp, bytes);

      // Verify file sizes
      state = const AsyncData(PushState(
        step: PushStep.verifying,
        message: 'Verifying file sizes...',
      ));
      final primarySize = await channel.fileSize(devicePrimary);
      final tempSize = await channel.fileSize(deviceTemp);
      final expectedSize = bytes.length;

      if (primarySize != expectedSize || tempSize != expectedSize) {
        state = AsyncData(PushState(
          step: PushStep.error,
          message: 'Size mismatch! '
              'Expected: $expectedSize, '
              'Primary: $primarySize, '
              'Temp: $tempSize',
          primarySize: primarySize,
          tempSize: tempSize,
          expectedSize: expectedSize,
        ));
        return;
      }

      // Auto-name the slot from the source file
      final existingSlot = await slotDao.getByUuid(targetUuid);
      await slotDao.upsertSlot(DeviceSlotsCompanion(
        uuid: Value(targetUuid),
        name: Value(sourceFileName),
        slotNumber: Value(existingSlot?.slotNumber ?? 0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));

      state = AsyncData(PushState(
        step: PushStep.success,
        message: 'Push complete! Reload the mission in DJI GoFly.',
        primarySize: primarySize,
        tempSize: tempSize,
        expectedSize: expectedSize,
      ));
    } on ShizukuException catch (e) {
      state = AsyncData(PushState(
        step: PushStep.error,
        message: 'Shizuku error: ${e.message}',
      ));
    } catch (e) {
      state = AsyncData(PushState(
        step: PushStep.error,
        message: 'Push failed: $e',
      ));
    }
  }

  void reset() {
    state = const AsyncData(PushState());
  }
}
