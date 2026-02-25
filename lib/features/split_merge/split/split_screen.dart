import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/mission.dart';
import '../../../core/models/mission_config.dart';
import '../../edit/widgets/finish_action_selector.dart';
import '../../missions/detail/mission_detail_provider.dart';
import 'split_preview_screen.dart';
import 'split_provider.dart';

class SplitScreen extends ConsumerStatefulWidget {
  final String missionId;
  final String source;

  const SplitScreen({
    super.key,
    required this.missionId,
    required this.source,
  });

  @override
  ConsumerState<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends ConsumerState<SplitScreen> {
  int _waypointsPerSegment = 150;
  int _overlap = 1;
  List<FinishAction>? _customFinishActions;

  @override
  Widget build(BuildContext context) {
    final missionAsync =
        ref.watch(missionDetailProvider((widget.missionId, widget.source)));

    return Scaffold(
      appBar: AppBar(title: const Text('Split Mission')),
      body: missionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (mission) => _buildContent(context, mission),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Mission mission) {
    final config = SplitConfig(
      waypointsPerSegment: _waypointsPerSegment,
      overlap: _overlap,
      segmentFinishActions: _customFinishActions ?? [],
    );
    final segments = computeSegments(mission.waypoints.length, config);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mission summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Source Mission',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('${mission.waypoints.length} waypoints'),
                if (mission.author != null) Text('Author: ${mission.author}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Waypoints per segment
        Text('Waypoints per segment: $_waypointsPerSegment',
            style: Theme.of(context).textTheme.titleSmall),
        Slider(
          value: _waypointsPerSegment.toDouble(),
          min: 50,
          max: mission.waypoints.length.toDouble().clamp(50, 500),
          divisions:
              ((mission.waypoints.length.clamp(50, 500) - 50) / 10).round(),
          label: '$_waypointsPerSegment',
          onChanged: (v) => setState(() {
            _waypointsPerSegment = v.round();
            _customFinishActions = null;
          }),
        ),
        const SizedBox(height: 8),

        // Overlap
        Text('Overlap: $_overlap waypoint(s)',
            style: Theme.of(context).textTheme.titleSmall),
        Slider(
          value: _overlap.toDouble(),
          min: 0,
          max: 3,
          divisions: 3,
          label: '$_overlap',
          onChanged: (v) => setState(() {
            _overlap = v.round();
            _customFinishActions = null;
          }),
        ),
        const SizedBox(height: 16),

        // Segment preview
        Text('Segments (${segments.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...segments.asMap().entries.map((entry) {
          final i = entry.key;
          final seg = entry.value;
          final color = _segmentColor(i);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Text('${i + 1}',
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text(
                  'WP ${seg.startIndex}–${seg.endIndex} (${seg.waypointCount} pts)'),
              subtitle: Text(_finishActionLabel(seg.finishAction)),
              trailing: IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _editSegmentAction(i, seg.finishAction),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // Preview map button
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SplitPreviewScreen(
                mission: mission,
                config: config,
              ),
            ),
          ),
          icon: const Icon(Icons.map),
          label: const Text('Preview on Map'),
        ),
        const SizedBox(height: 8),

        // Split button
        FilledButton.icon(
          onPressed: () => _executeSplit(context, mission, config),
          icon: const Icon(Icons.call_split),
          label: const Text('Split Mission'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  void _editSegmentAction(int index, FinishAction current) {
    showDialog(
      context: context,
      builder: (ctx) {
        var selected = current;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text('Segment ${index + 1} Finish Action'),
            content: FinishActionSelector(
              value: selected,
              onChanged: (v) => setDialogState(() => selected = v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    final segments = computeSegments(
                      // We need the segment count for sizing the list
                      // Recompute to get correct count
                      1000, // dummy, we'll resize below
                      SplitConfig(
                        waypointsPerSegment: _waypointsPerSegment,
                        overlap: _overlap,
                      ),
                    );
                    // Initialize custom actions from defaults if needed
                    _customFinishActions ??=
                        segments.map((s) => s.finishAction).toList();
                    if (index < _customFinishActions!.length) {
                      _customFinishActions![index] = selected;
                    }
                  });
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _executeSplit(
      BuildContext context, Mission mission, SplitConfig config) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SplitProgressDialog(
        mission: mission,
        parentId: widget.missionId,
        config: config,
      ),
    );
  }

  String _finishActionLabel(FinishAction action) {
    return switch (action) {
      FinishAction.goHome => 'Go Home',
      FinishAction.noAction => 'No Action (hover)',
      FinishAction.autoLand => 'Auto Land',
      FinishAction.backToFirstWaypoint => 'Back to First',
    };
  }

  Color _segmentColor(int index) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}

class _SplitProgressDialog extends ConsumerStatefulWidget {
  final Mission mission;
  final String parentId;
  final SplitConfig config;

  const _SplitProgressDialog({
    required this.mission,
    required this.parentId,
    required this.config,
  });

  @override
  ConsumerState<_SplitProgressDialog> createState() =>
      _SplitProgressDialogState();
}

class _SplitProgressDialogState extends ConsumerState<_SplitProgressDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splitExecutorProvider.notifier).executeSplit(
            source: widget.mission,
            parentId: widget.parentId,
            config: widget.config,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final splitState = ref.watch(splitExecutorProvider);

    return AlertDialog(
      title: Text(splitState.when(
        loading: () => 'Splitting...',
        error: (_, __) => 'Error',
        data: (s) => switch (s.step) {
          SplitStep.idle => 'Preparing...',
          SplitStep.splitting => 'Splitting',
          SplitStep.saving => 'Saving',
          SplitStep.done => 'Done',
          SplitStep.error => 'Error',
        },
      )),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          splitState.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => _result(Icons.error_outline, Colors.red, '$e'),
            data: (s) => switch (s.step) {
              SplitStep.idle ||
              SplitStep.splitting =>
                _progress(s.message),
              SplitStep.saving => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: s.totalSegments > 0
                          ? s.segmentsSaved / s.totalSegments
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(s.message),
                  ],
                ),
              SplitStep.done =>
                _result(Icons.check_circle, Colors.green, s.message),
              SplitStep.error =>
                _result(Icons.error_outline, Colors.red, s.message),
            },
          ),
        ],
      ),
      actions: [
        if (splitState.value?.step == SplitStep.done ||
            splitState.value?.step == SplitStep.error ||
            splitState.hasError)
          FilledButton(
            onPressed: () {
              ref.read(splitExecutorProvider.notifier).reset();
              Navigator.pop(context);
              if (splitState.value?.step == SplitStep.done) {
                context.go('/'); // Go home to see segments
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
      children: [const CircularProgressIndicator(), const SizedBox(height: 12), Text(msg)],
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
