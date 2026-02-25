import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../missions/device/device_missions_provider.dart';
import '../missions/local/local_missions_provider.dart';
import 'push_provider.dart';
import 'widgets/device_target_picker.dart';

class PushScreen extends ConsumerStatefulWidget {
  final String localMissionId;

  const PushScreen({super.key, required this.localMissionId});

  @override
  ConsumerState<PushScreen> createState() => _PushScreenState();
}

class _PushScreenState extends ConsumerState<PushScreen> {
  String? _selectedUuid;
  bool _createBackup = true;

  @override
  Widget build(BuildContext context) {
    final deviceMissions = ref.watch(deviceMissionsProvider);
    final pushState = ref.watch(pushProvider);
    final localMission = ref.watch(
      localMissionsProvider.select((data) => data.whenData(
            (missions) => missions
                .where((m) => m.id == widget.localMissionId)
                .firstOrNull,
          )),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Push to Device')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Source mission card
          _SourceCard(
            localMissionId: widget.localMissionId,
            localMission: localMission,
          ),

          // Backup toggle
          SwitchListTile(
            title: const Text('Backup existing KMZ'),
            subtitle: const Text('Save device KMZ before overwriting'),
            value: _createBackup,
            onChanged: (value) => setState(() => _createBackup = value),
          ),
          const Divider(),

          // Target selection header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Select target device mission',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          // Device missions list
          deviceMissions.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 8),
                  Text('Failed to load device missions: $error'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(deviceMissionsProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (missions) => DeviceTargetPicker(
              missions: missions,
              selectedUuid: _selectedUuid,
              onSelected: (uuid) => setState(() => _selectedUuid = uuid),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _PushButton(
        enabled: _selectedUuid != null,
        onPressed: () => _confirmAndPush(context, deviceMissions),
        pushState: pushState,
      ),
    );
  }

  void _confirmAndPush(BuildContext context, AsyncValue deviceMissions) {
    if (_selectedUuid == null) return;

    final targetUuid = _selectedUuid!;
    final displayUuid =
        '${targetUuid.substring(0, 8)}...${targetUuid.substring(targetUuid.length - 4)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Push'),
        content: Text(
          'Replace device mission $displayUuid with local mission?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executePush();
            },
            child: const Text('Push'),
          ),
        ],
      ),
    );
  }

  void _executePush() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PushProgressDialog(
        localMissionId: widget.localMissionId,
        targetUuid: _selectedUuid!,
        createBackup: _createBackup,
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String localMissionId;
  final AsyncValue localMission;

  const _SourceCard({
    required this.localMissionId,
    required this.localMission,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source Mission',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            localMission.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (mission) {
                if (mission == null) {
                  return const Text('Mission not found');
                }
                final id = localMissionId;
                final displayId = id.length > 20
                    ? '${id.substring(0, 8)}...${id.substring(id.length - 4)}'
                    : id;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      displayId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    Text('${mission.waypointCount} waypoints'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PushButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final AsyncValue<PushState> pushState;

  const _PushButton({
    required this.enabled,
    required this.onPressed,
    required this.pushState,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.upload),
          label: const Text('Push to Device'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }
}

class _PushProgressDialog extends ConsumerStatefulWidget {
  final String localMissionId;
  final String targetUuid;
  final bool createBackup;

  const _PushProgressDialog({
    required this.localMissionId,
    required this.targetUuid,
    required this.createBackup,
  });

  @override
  ConsumerState<_PushProgressDialog> createState() =>
      _PushProgressDialogState();
}

class _PushProgressDialogState extends ConsumerState<_PushProgressDialog> {
  @override
  void initState() {
    super.initState();
    // Start push after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushProvider.notifier).pushMission(
            localMissionId: widget.localMissionId,
            targetUuid: widget.targetUuid,
            createBackup: widget.createBackup,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pushState = ref.watch(pushProvider);

    return AlertDialog(
      title: Text(pushState.when(
        loading: () => 'Pushing...',
        error: (_, __) => 'Error',
        data: (state) => switch (state.step) {
          PushStep.idle => 'Preparing...',
          PushStep.backingUp => 'Backing Up',
          PushStep.pushing => 'Pushing',
          PushStep.verifying => 'Verifying',
          PushStep.success => 'Success',
          PushStep.error => 'Error',
        },
      )),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          pushState.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => _buildResult(
              context,
              Icons.error_outline,
              Colors.red,
              'Error: $e',
            ),
            data: (state) => switch (state.step) {
              PushStep.idle ||
              PushStep.backingUp ||
              PushStep.pushing ||
              PushStep.verifying =>
                _buildProgress(context, state),
              PushStep.success => _buildResult(
                  context,
                  Icons.check_circle,
                  Colors.green,
                  state.message,
                  sizes: state,
                ),
              PushStep.error => _buildResult(
                  context,
                  Icons.error_outline,
                  Colors.red,
                  state.message,
                  sizes: state,
                ),
            },
          ),
        ],
      ),
      actions: [
        if (pushState.value?.step == PushStep.success ||
            pushState.value?.step == PushStep.error ||
            pushState.hasError)
          FilledButton(
            onPressed: () {
              ref.read(pushProvider.notifier).reset();
              Navigator.pop(context);
              if (pushState.value?.step == PushStep.success) {
                Navigator.pop(context); // Also pop push screen
              }
            },
            child: const Text('Done'),
          ),
      ],
    );
  }

  Widget _buildProgress(BuildContext context, PushState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(state.message),
      ],
    );
  }

  Widget _buildResult(
    BuildContext context,
    IconData icon,
    Color color,
    String message, {
    PushState? sizes,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (sizes?.expectedSize != null) ...[
          const SizedBox(height: 8),
          Text(
            'Expected: ${sizes!.expectedSize} bytes\n'
            'Primary: ${sizes.primarySize} bytes\n'
            'Temp: ${sizes.tempSize} bytes',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
