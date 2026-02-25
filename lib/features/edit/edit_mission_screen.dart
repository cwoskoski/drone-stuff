import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/mission.dart';
import '../../core/models/mission_config.dart';
import '../missions/detail/mission_detail_provider.dart';
import '../missions/local/local_mission_repository.dart';
import '../missions/local/local_missions_provider.dart';
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
  final _speedController = TextEditingController();
  final _bulkSpeedController = TextEditingController();
  final _bulkAltController = TextEditingController();
  bool _changeFinishAction = false;
  bool _changeSpeed = false;
  bool _changeBulkSpeed = false;
  bool _changeBulkAlt = false;

  @override
  void dispose() {
    _speedController.dispose();
    _bulkSpeedController.dispose();
    _bulkAltController.dispose();
    super.dispose();
  }

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
    // Initialize defaults from mission
    _finishAction ??= mission.config.finishAction;
    if (_speedController.text.isEmpty) {
      _speedController.text =
          mission.config.globalTransitionalSpeed.toString();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _speedController,
              decoration: const InputDecoration(
                labelText: 'Transitional Speed (m/s)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        const SizedBox(height: 8),

        // Bulk waypoint speed
        SwitchListTile(
          title: const Text('Set All Waypoint Speeds'),
          subtitle:
              Text('Current range: ${_speedRange(mission)} m/s'),
          value: _changeBulkSpeed,
          onChanged: (v) => setState(() => _changeBulkSpeed = v),
        ),
        if (_changeBulkSpeed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _bulkSpeedController,
              decoration: const InputDecoration(
                labelText: 'Waypoint Speed (m/s)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        const SizedBox(height: 8),

        // Bulk altitude
        SwitchListTile(
          title: const Text('Set All Waypoint Altitudes'),
          subtitle:
              Text('Current range: ${_altRange(mission)} m'),
          value: _changeBulkAlt,
          onChanged: (v) => setState(() => _changeBulkAlt = v),
        ),
        if (_changeBulkAlt)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _bulkAltController,
              decoration: const InputDecoration(
                labelText: 'Altitude (m)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        const SizedBox(height: 24),

        // Save button
        FilledButton.icon(
          onPressed: _hasChanges()
              ? () => _executeEdit(context, mission)
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

  Future<void> _executeEdit(BuildContext context, Mission mission) async {
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

    final config = EditConfig(
      finishAction: _changeFinishAction ? _finishAction : null,
      transitionalSpeed: _changeSpeed
          ? double.tryParse(_speedController.text)
          : null,
      bulkSpeed: _changeBulkSpeed
          ? double.tryParse(_bulkSpeedController.text)
          : null,
      bulkAltitude: _changeBulkAlt
          ? double.tryParse(_bulkAltController.text)
          : null,
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
