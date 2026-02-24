import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shizuku_channel.dart';

enum ShizukuState {
  notInstalled('Shizuku is not installed'),
  notRunning('Shizuku is not running'),
  permissionNeeded('Shizuku permission required'),
  ready('Shizuku is ready');

  final String displayMessage;
  const ShizukuState(this.displayMessage);

  static ShizukuState fromString(String value) {
    switch (value) {
      case 'not_installed':
        return ShizukuState.notInstalled;
      case 'not_running':
        return ShizukuState.notRunning;
      case 'permission_needed':
        return ShizukuState.permissionNeeded;
      case 'ready':
        return ShizukuState.ready;
      default:
        return ShizukuState.notInstalled;
    }
  }
}

final shizukuChannelProvider = Provider<ShizukuChannel>((ref) {
  return ShizukuChannel();
});

final shizukuStateProvider =
    AutoDisposeFutureProvider<ShizukuState>((ref) async {
  final channel = ref.watch(shizukuChannelProvider);
  return channel.getShizukuState();
});
