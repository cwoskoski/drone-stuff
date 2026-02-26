import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/device_mission.dart';
import '../../home/widgets/shizuku_banner.dart';

import 'device_missions_provider.dart';

class DeviceMissionsScreen extends ConsumerWidget {
  const DeviceMissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(deviceMissionsProvider);

    return Column(
      children: [
        const ShizukuBanner(),
        Expanded(
          child: missionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildError(context, ref, error),
            data: (missions) {
              if (missions.isEmpty) {
                return _buildEmpty(context, ref);
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(deviceMissionsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: missions.length,
                  itemBuilder: (context, index) =>
                      _MissionCard(mission: missions[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No missions found on device',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                ref.read(deviceMissionsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load device missions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () =>
                ref.read(deviceMissionsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final DeviceMission mission;

  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final uuid = mission.uuid;
    final displayUuid =
        '${uuid.substring(0, 8)}...${uuid.substring(uuid.length - 4)}';
    final title = mission.name ?? 'Slot ${mission.slotNumber}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${mission.slotNumber}'),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot ${mission.slotNumber}  ·  $displayUuid',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            Row(
              children: [
                if (mission.waypointCount > 0)
                  Text('${mission.waypointCount} waypoints')
                else
                  Text('Empty', style: TextStyle(color: Colors.grey[500])),
                if (mission.waypointCount > 0 && mission.kmzSizeBytes > 0)
                  const Text('  ·  '),
                if (mission.kmzSizeBytes > 0)
                  Text(_formatSize(mission.kmzSizeBytes)),
              ],
            ),
            if (mission.createTime != null)
              Text(DateFormat.yMMMd().add_Hm().format(mission.createTime!)),
          ],
        ),
        isThreeLine: true,
        onTap: () => context.push('/detail/${mission.uuid}/device'),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
