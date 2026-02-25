import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/kmz/kmz_parser.dart';
import '../../../core/models/mission.dart';
import '../../missions/local/local_mission_repository.dart';
import '../../missions/local/local_missions_provider.dart';
import 'merge_provider.dart';

class MergeScreen extends ConsumerStatefulWidget {
  const MergeScreen({super.key});

  @override
  ConsumerState<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends ConsumerState<MergeScreen> {
  final List<String> _selectedIds = [];
  int _overlap = 1;

  @override
  Widget build(BuildContext context) {
    final missionsAsync = ref.watch(localMissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Merge Missions')),
      body: missionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (missions) => _buildContent(context, missions),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<db.Mission> missions) {
    if (missions.isEmpty) {
      return const Center(child: Text('No local missions available'));
    }

    return Column(
      children: [
        // Overlap setting
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Text('Overlap: $_overlap',
                  style: Theme.of(context).textTheme.titleSmall),
              Expanded(
                child: Slider(
                  value: _overlap.toDouble(),
                  min: 0,
                  max: 3,
                  divisions: 3,
                  label: '$_overlap',
                  onChanged: (v) => setState(() => _overlap = v.round()),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Select missions in order (${_selectedIds.length} selected)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),

        // Mission list
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: missions.length,
            onReorder: (oldIndex, newIndex) {
              // Only handle reordering of selected items
            },
            itemBuilder: (context, index) {
              final mission = missions[index];
              final isSelected = _selectedIds.contains(mission.id);
              final selectionOrder = _selectedIds.indexOf(mission.id);

              return Card(
                key: ValueKey(mission.id),
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedIds.add(mission.id);
                      } else {
                        _selectedIds.remove(mission.id);
                      }
                    });
                  },
                  title: Text(mission.fileName),
                  subtitle: Text(
                    '${mission.waypointCount} waypoints'
                    '${isSelected ? "  ·  #${selectionOrder + 1}" : ""}',
                  ),
                  secondary: isSelected
                      ? CircleAvatar(
                          child: Text('${selectionOrder + 1}'),
                        )
                      : null,
                ),
              );
            },
          ),
        ),

        // Merge button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _selectedIds.length >= 2
                  ? () => _executeMerge(context)
                  : null,
              icon: const Icon(Icons.merge),
              label: Text('Merge ${_selectedIds.length} Missions'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _executeMerge(BuildContext context) async {
    // Load full missions in order
    final repo = ref.read(localMissionRepositoryProvider);
    final missions = <Mission>[];

    for (final id in _selectedIds) {
      final result = await repo.getMission(id);
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mission $id not found')),
          );
        }
        return;
      }
      missions.add(KmzParser.parseBytes(result.bytes));
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MergeProgressDialog(
        missions: missions,
        overlap: _overlap,
      ),
    );
  }
}

class _MergeProgressDialog extends ConsumerStatefulWidget {
  final List<Mission> missions;
  final int overlap;

  const _MergeProgressDialog({
    required this.missions,
    required this.overlap,
  });

  @override
  ConsumerState<_MergeProgressDialog> createState() =>
      _MergeProgressDialogState();
}

class _MergeProgressDialogState extends ConsumerState<_MergeProgressDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mergeExecutorProvider.notifier).executeMerge(
            missions: widget.missions,
            overlap: widget.overlap,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mergeState = ref.watch(mergeExecutorProvider);

    return AlertDialog(
      title: Text(mergeState.when(
        loading: () => 'Merging...',
        error: (_, __) => 'Error',
        data: (s) => switch (s.step) {
          MergeStep.idle => 'Preparing...',
          MergeStep.merging => 'Merging',
          MergeStep.saving => 'Saving',
          MergeStep.done => 'Done',
          MergeStep.error => 'Error',
        },
      )),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mergeState.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => _result(Icons.error_outline, Colors.red, '$e'),
            data: (s) => switch (s.step) {
              MergeStep.idle ||
              MergeStep.merging ||
              MergeStep.saving =>
                _progress(s.message),
              MergeStep.done =>
                _result(Icons.check_circle, Colors.green, s.message),
              MergeStep.error =>
                _result(Icons.error_outline, Colors.red, s.message),
            },
          ),
        ],
      ),
      actions: [
        if (mergeState.value?.step == MergeStep.done ||
            mergeState.value?.step == MergeStep.error ||
            mergeState.hasError)
          FilledButton(
            onPressed: () {
              ref.read(mergeExecutorProvider.notifier).reset();
              Navigator.pop(context);
              if (mergeState.value?.step == MergeStep.done) {
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
