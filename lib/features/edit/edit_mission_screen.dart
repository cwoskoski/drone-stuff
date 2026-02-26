import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/drone_capability.dart';
import '../../core/models/mission.dart';
import '../../core/models/mission_config.dart';
import '../missions/detail/mission_detail_provider.dart';
import '../missions/local/local_mission_repository.dart';
import '../missions/local/local_missions_provider.dart';
import 'capability_provider.dart';
import 'edit_mission_provider.dart';
import 'widgets/finish_action_selector.dart';

class EditMissionScreen extends ConsumerStatefulWidget {
  final String missionId;
  final String source;

  const EditMissionScreen({
    super.key,
    required this.missionId,
    required this.source,
  });

  @override
  ConsumerState<EditMissionScreen> createState() => _EditMissionScreenState();
}

class _EditMissionScreenState extends ConsumerState<EditMissionScreen> {
  FinishAction? _finishAction;
  double _transitionalSpeed = 10.0;
  double _bulkSpeed = 10.0;
  double _bulkAltitude = 50.0;
  bool _initialized = false;

  bool _changeFinishAction = false;
  bool _changeSpeed = false;
  bool _changeBulkSpeed = false;
  bool _changeBulkAlt = false;

  @override
  Widget build(BuildContext context) {
    final missionAsync =
        ref.watch(missionDetailProvider((widget.missionId, widget.source)));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Mission')),
      body: missionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (mission) => _buildContent(context, mission),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Mission mission) {
    final capabilityAsync = ref.watch(droneCapabilityProvider);
    final capability = capabilityAsync.value ?? const DroneCapability();

    // Initialize state values from mission data, clamped to capability range
    if (!_initialized) {
      _finishAction = mission.config.finishAction;
      _transitionalSpeed = mission.config.globalTransitionalSpeed
          .clamp(capability.speedMin, capability.speedMax);
      if (mission.waypoints.isNotEmpty) {
        _bulkSpeed = mission.waypoints.first.waypointSpeed
            .clamp(capability.speedMin, capability.speedMax);
        _bulkAltitude = mission.waypoints.first.executeHeight.clamp(2.0, 500.0);
      }
      _initialized = true;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Capability info banner
        _buildCapabilityBanner(capability, capabilityAsync.isLoading),
        const SizedBox(height: 8),

        // Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Editing creates a new copy — original is preserved.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Finish Action
        SwitchListTile(
          title: const Text('Change Finish Action'),
          value: _changeFinishAction,
          onChanged: (v) => setState(() => _changeFinishAction = v),
        ),
        if (_changeFinishAction) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FinishActionSelector(
              value: _finishAction!,
              onChanged: (v) => setState(() => _finishAction = v),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Transitional Speed
        SwitchListTile(
          title: const Text('Change Transitional Speed'),
          value: _changeSpeed,
          onChanged: (v) => setState(() => _changeSpeed = v),
        ),
        if (_changeSpeed)
          _buildSliderRow(
            label: 'Transitional Speed',
            unit: 'm/s',
            value: _transitionalSpeed,
            min: capability.speedMin,
            max: capability.speedMax,
            onChanged: (v) => setState(() => _transitionalSpeed = v),
          ),
        const SizedBox(height: 8),

        // Bulk waypoint speed
        SwitchListTile(
          title: const Text('Set All Waypoint Speeds'),
          subtitle: Text('Current range: ${_speedRange(mission)} m/s'),
          value: _changeBulkSpeed,
          onChanged: (v) => setState(() => _changeBulkSpeed = v),
        ),
        if (_changeBulkSpeed)
          _buildSliderRow(
            label: 'Waypoint Speed',
            unit: 'm/s',
            value: _bulkSpeed,
            min: capability.speedMin,
            max: capability.speedMax,
            onChanged: (v) => setState(() => _bulkSpeed = v),
          ),
        const SizedBox(height: 8),

        // Bulk altitude
        SwitchListTile(
          title: const Text('Set All Waypoint Altitudes'),
          subtitle: Text('Current range: ${_altRange(mission)} m'),
          value: _changeBulkAlt,
          onChanged: (v) => setState(() => _changeBulkAlt = v),
        ),
        if (_changeBulkAlt)
          _buildSliderRow(
            label: 'Altitude',
            unit: 'm',
            value: _bulkAltitude,
            min: 2.0,
            max: 500.0,
            onChanged: (v) => setState(() => _bulkAltitude = v),
          ),
        const SizedBox(height: 24),

        // Save button
        FilledButton.icon(
          onPressed: _hasChanges()
              ? () => _executeEdit(context, mission, capability)
              : null,
          icon: const Icon(Icons.save),
          label: const Text('Save as New Mission'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilityBanner(DroneCapability capability, bool isLoading) {
    if (isLoading) {
      return Card(
        color: Colors.grey.shade100,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading drone capabilities...'),
            ],
          ),
        ),
      );
    }

    final color = capability.isFromDevice ? Colors.green : Colors.amber;
    final icon = capability.isFromDevice ? Icons.check_circle : Icons.info;
    final text = capability.isFromDevice
        ? 'Using drone capability limits'
        : 'Using default limits (drone not connected)';

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(color: color.shade700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String unit,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$label: ${value.toStringAsFixed(1)} $unit'),
              Text('${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)} $unit',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 10).round().clamp(1, 1000),
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  bool _hasChanges() {
    return _changeFinishAction ||
        _changeSpeed ||
        _changeBulkSpeed ||
        _changeBulkAlt;
  }

  String _speedRange(Mission m) {
    if (m.waypoints.isEmpty) return 'N/A';
    final speeds = m.waypoints.map((w) => w.waypointSpeed);
    return '${speeds.reduce((a, b) => a < b ? a : b)}–'
        '${speeds.reduce((a, b) => a > b ? a : b)}';
  }

  String _altRange(Mission m) {
    if (m.waypoints.isEmpty) return 'N/A';
    final alts = m.waypoints.map((w) => w.executeHeight);
    return '${alts.reduce((a, b) => a < b ? a : b)}–'
        '${alts.reduce((a, b) => a > b ? a : b)}';
  }

  Future<void> _executeEdit(
    BuildContext context,
    Mission mission,
    DroneCapability capability,
  ) async {
    // Load original KMZ bytes
    final repo = ref.read(localMissionRepositoryProvider);
    final result = await repo.getMission(widget.missionId);
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission not found')),
        );
      }
      return;
    }

    // Clamp values to capability range before saving
    final clampedSpeed =
        _transitionalSpeed.clamp(capability.speedMin, capability.speedMax);
    final clampedBulkSpeed =
        _bulkSpeed.clamp(capability.speedMin, capability.speedMax);
    final clampedAlt = _bulkAltitude.clamp(2.0, 500.0);

    final config = EditConfig(
      finishAction: _changeFinishAction ? _finishAction : null,
      transitionalSpeed: _changeSpeed ? clampedSpeed : null,
      bulkSpeed: _changeBulkSpeed ? clampedBulkSpeed : null,
      bulkAltitude: _changeBulkAlt ? clampedAlt : null,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditProgressDialog(
        sourceMissionId: widget.missionId,
        originalKmzBytes: result.bytes,
        originalMission: mission,
        config: config,
      ),
    );
  }
}

class _EditProgressDialog extends ConsumerStatefulWidget {
  final String sourceMissionId;
  final dynamic originalKmzBytes;
  final Mission originalMission;
  final EditConfig config;

  const _EditProgressDialog({
    required this.sourceMissionId,
    required this.originalKmzBytes,
    required this.originalMission,
    required this.config,
  });

  @override
  ConsumerState<_EditProgressDialog> createState() =>
      _EditProgressDialogState();
}

class _EditProgressDialogState extends ConsumerState<_EditProgressDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editExecutorProvider.notifier).executeEdit(
            sourceMissionId: widget.sourceMissionId,
            originalKmzBytes: widget.originalKmzBytes,
            originalMission: widget.originalMission,
            config: widget.config,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editExecutorProvider);

    return AlertDialog(
      title: Text(editState.when(
        loading: () => 'Editing...',
        error: (_, __) => 'Error',
        data: (s) => switch (s.step) {
          EditStep.idle => 'Preparing...',
          EditStep.editing => 'Editing',
          EditStep.saving => 'Saving',
          EditStep.done => 'Done',
          EditStep.error => 'Error',
        },
      )),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          editState.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => _result(Icons.error_outline, Colors.red, '$e'),
            data: (s) => switch (s.step) {
              EditStep.idle ||
              EditStep.editing ||
              EditStep.saving =>
                _progress(s.message),
              EditStep.done =>
                _result(Icons.check_circle, Colors.green, s.message),
              EditStep.error =>
                _result(Icons.error_outline, Colors.red, s.message),
            },
          ),
        ],
      ),
      actions: [
        if (editState.value?.step == EditStep.done ||
            editState.value?.step == EditStep.error ||
            editState.hasError)
          FilledButton(
            onPressed: () {
              ref.read(editExecutorProvider.notifier).reset();
              Navigator.pop(context);
              if (editState.value?.step == EditStep.done) {
                context.go('/');
              }
            },
            child: const Text('Done'),
          ),
      ],
    );
  }

  Widget _progress(String msg) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(msg),
      ],
    );
  }

  Widget _result(IconData icon, Color color, String msg) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 12),
        Text(msg, textAlign: TextAlign.center),
      ],
    );
  }
}
