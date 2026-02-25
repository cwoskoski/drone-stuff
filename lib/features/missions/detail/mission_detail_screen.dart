import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/action_group.dart';
import '../../../core/models/mission.dart';
import '../../../core/models/waypoint.dart';
import 'mission_detail_provider.dart';
import 'widgets/mission_info_card.dart';

class MissionDetailScreen extends ConsumerWidget {
  final String id;
  final String source;

  const MissionDetailScreen({
    super.key,
    required this.id,
    required this.source,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionDetailProvider((id, source)));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _displayTitle(),
          style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
        ),
      ),
      body: missionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, error),
        data: (mission) => _buildContent(context, mission),
      ),
    );
  }

  String _displayTitle() {
    if (id.length > 20) {
      return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
    }
    return id;
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load mission',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Mission mission) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        MissionInfoCard(mission: mission),
        _ActionButtons(id: id, source: source),
        _WaypointList(waypoints: mission.waypoints),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String id;
  final String source;

  const _ActionButtons({required this.id, required this.source});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => context.push('/map/$id/$source'),
            icon: const Icon(Icons.map),
            label: const Text('View Map'),
          ),
          if (source == 'local')
            OutlinedButton.icon(
              onPressed: () => context.push('/push/$id'),
              icon: const Icon(Icons.upload),
              label: const Text('Push'),
            ),
          OutlinedButton.icon(
            onPressed: () => context.push('/split/$id'),
            icon: const Icon(Icons.call_split),
            label: const Text('Split'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.push('/edit/$id'),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _WaypointList extends StatelessWidget {
  final List<Waypoint> waypoints;

  const _WaypointList({required this.waypoints});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Waypoints (${waypoints.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          ...waypoints.map((wp) => _WaypointTile(waypoint: wp)),
        ],
      ),
    );
  }
}

class _WaypointTile extends StatelessWidget {
  final Waypoint waypoint;

  const _WaypointTile({required this.waypoint});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: CircleAvatar(
        radius: 14,
        child: Text(
          '${waypoint.index}',
          style: const TextStyle(fontSize: 11),
        ),
      ),
      title: Text(
        '${waypoint.latitude.toStringAsFixed(6)}, '
        '${waypoint.longitude.toStringAsFixed(6)}',
        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
      ),
      subtitle: Text(
        'Alt: ${waypoint.executeHeight}m  Speed: ${waypoint.waypointSpeed}m/s',
        style: const TextStyle(fontSize: 12),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailText(
                'Heading: ${waypoint.heading.mode} '
                '(${waypoint.heading.angle}°)',
              ),
              _DetailText(
                'Turn: ${waypoint.turn.mode} '
                '(damping: ${waypoint.turn.dampingDist}m)',
              ),
              if (waypoint.gimbalHeading != null)
                _DetailText(
                  'Gimbal: pitch ${waypoint.gimbalHeading!.pitchAngle}° '
                  'yaw ${waypoint.gimbalHeading!.yawAngle}°',
                ),
              _DetailText(
                'Straight line: ${waypoint.useStraightLine ? "yes" : "no"}',
              ),
              if (waypoint.actionGroups.isNotEmpty)
                _ActionGroupsSection(groups: waypoint.actionGroups),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailText extends StatelessWidget {
  final String text;

  const _DetailText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ActionGroupsSection extends StatelessWidget {
  final List<ActionGroup> groups;

  const _ActionGroupsSection({required this.groups});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          'Action Groups (${groups.length}):',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        ...groups.map((g) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Text(
                'Group ${g.groupId}: ${g.actions.length} actions '
                '(${g.triggerType})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )),
      ],
    );
  }
}
