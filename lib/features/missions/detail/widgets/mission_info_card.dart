import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/mission.dart';
import '../../../../core/models/mission_config.dart';
import '../../../../core/utils/flight_calculator.dart';

class MissionInfoCard extends StatelessWidget {
  final Mission mission;

  const MissionInfoCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final config = mission.config;
    final theme = Theme.of(context);
    final flight = estimateFlight(mission.waypoints);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mission Info', style: theme.textTheme.titleMedium),
            const Divider(),
            if (mission.author != null)
              _InfoRow(label: 'Author', value: mission.author!),
            if (mission.createTime != null)
              _InfoRow(
                label: 'Created',
                value: DateFormat.yMMMd().add_Hm().format(mission.createTime!),
              ),
            if (mission.updateTime != null)
              _InfoRow(
                label: 'Updated',
                value: DateFormat.yMMMd().add_Hm().format(mission.updateTime!),
              ),
            _InfoRow(
              label: 'Waypoints',
              value: '${mission.waypoints.length}',
            ),
            _InfoRow(
              label: 'Est. Flight Time',
              value: formatDuration(flight.flightTime),
            ),
            _InfoRow(
              label: 'Total Distance',
              value: formatDistance(flight.totalDistance),
            ),
            _InfoRow(
              label: 'Finish Action',
              value: config.finishAction.displayName,
            ),
            _InfoRow(
              label: 'Fly-to Mode',
              value: config.flyToWaylineMode,
            ),
            _InfoRow(
              label: 'RC Lost Action',
              value: config.executeRCLostAction,
            ),
            _InfoRow(
              label: 'Transit Speed',
              value: '${config.globalTransitionalSpeed} m/s',
            ),
            _InfoRow(
              label: 'Drone',
              value:
                  'Enum ${config.droneEnumValue} / Sub ${config.droneSubEnumValue}',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _InfoRow({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(child: child ?? Text(value ?? '')),
        ],
      ),
    );
  }
}

