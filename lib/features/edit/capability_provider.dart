import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/models/drone_capability.dart';
import '../../core/platform/shizuku_channel.dart';
import '../../core/platform/shizuku_state.dart';

final droneCapabilityProvider =
    FutureProvider.autoDispose<DroneCapability>((ref) async {
  final shizukuState = await ref.watch(shizukuStateProvider.future);

  if (shizukuState != ShizukuState.ready) {
    return const DroneCapability();
  }

  final channel = ref.read(shizukuChannelProvider);

  String? speedJson;
  String? gimbalJson;
  String? lostActionJson;
  String? zoomJson;
  String? generalJson;

  // Read each file independently — failures are non-fatal
  try {
    final bytes = await channel.readFile('$capabilityDir/speed.json');
    if (bytes.isNotEmpty) speedJson = utf8.decode(bytes);
  } catch (_) {}

  try {
    final bytes = await channel.readFile('$capabilityDir/gimbal.json');
    if (bytes.isNotEmpty) gimbalJson = utf8.decode(bytes);
  } catch (_) {}

  try {
    final bytes = await channel.readFile('$capabilityDir/lost_action.json');
    if (bytes.isNotEmpty) lostActionJson = utf8.decode(bytes);
  } catch (_) {}

  try {
    final bytes = await channel.readFile('$capabilityDir/zoom.json');
    if (bytes.isNotEmpty) zoomJson = utf8.decode(bytes);
  } catch (_) {}

  try {
    final bytes = await channel.readFile('$capabilityDir/general.json');
    if (bytes.isNotEmpty) generalJson = utf8.decode(bytes);
  } catch (_) {}

  return DroneCapability.fromJsonFiles(
    speedJson: speedJson,
    gimbalJson: gimbalJson,
    lostActionJson: lostActionJson,
    zoomJson: zoomJson,
    generalJson: generalJson,
  );
});
