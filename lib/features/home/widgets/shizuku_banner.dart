import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/shizuku_state.dart';

class ShizukuBanner extends ConsumerWidget {
  const ShizukuBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(shizukuStateProvider);

    return stateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _buildBanner(
        context,
        ref,
        icon: Icons.error_outline,
        color: Colors.red,
        message: 'Could not check Shizuku status',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(shizukuStateProvider),
      ),
      data: (state) {
        if (state == ShizukuState.ready) return const SizedBox.shrink();

        final (icon, color, message, actionLabel, onAction) = switch (state) {
          ShizukuState.notInstalled => (
              Icons.download,
              Colors.orange,
              'Install Shizuku from the Play Store to access DJI mission files',
              'Learn More',
              () {},
            ),
          ShizukuState.notRunning => (
              Icons.play_circle_outline,
              Colors.orange,
              'Open Shizuku and start it via Wireless Debugging',
              'Refresh',
              () => ref.invalidate(shizukuStateProvider),
            ),
          ShizukuState.permissionNeeded => (
              Icons.lock_open,
              Colors.blue,
              'Tap to grant DroneStuff file access via Shizuku',
              'Grant Permission',
              () async {
                final channel = ref.read(shizukuChannelProvider);
                await channel.requestShizukuPermission();
                ref.invalidate(shizukuStateProvider);
              },
            ),
          ShizukuState.ready => (
              Icons.check,
              Colors.green,
              '',
              '',
              () {},
            ),
        };

        return _buildBanner(
          context,
          ref,
          icon: icon,
          color: color,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        );
      },
    );
  }

  Widget _buildBanner(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required Color color,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
