import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/device_mission.dart';

class DeviceTargetPicker extends StatelessWidget {
  final List<DeviceMission> missions;
  final String? selectedUuid;
  final ValueChanged<String> onSelected;

  const DeviceTargetPicker({
    super.key,
    required this.missions,
    required this.selectedUuid,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_android, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No missions found on device',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create a dummy mission in DJI GoFly first',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        final isSelected = mission.uuid == selectedUuid;
        final uuid = mission.uuid;
        final displayUuid =
            '${uuid.substring(0, 8)}...${uuid.substring(uuid.length - 4)}';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: RadioListTile<String>(
            value: mission.uuid,
            groupValue: selectedUuid,
            onChanged: (value) {
              if (value != null) onSelected(value);
            },
            title: Text(
              displayUuid,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mission.author != null)
                  Text('Author: ${mission.author}'),
                Row(
                  children: [
                    if (mission.waypointCount > 0)
                      Text('${mission.waypointCount} waypoints'),
                    if (mission.waypointCount > 0 && mission.kmzSizeBytes > 0)
                      const Text('  ·  '),
                    if (mission.kmzSizeBytes > 0)
                      Text(_formatSize(mission.kmzSizeBytes)),
                  ],
                ),
                if (mission.createTime != null)
                  Text(DateFormat.yMMMd()
                      .add_Hm()
                      .format(mission.createTime!)),
              ],
            ),
            isThreeLine: mission.author != null,
          ),
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
