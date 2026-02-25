import 'package:flutter/material.dart';

import '../../../core/models/mission_config.dart';

class FinishActionSelector extends StatelessWidget {
  final FinishAction value;
  final ValueChanged<FinishAction> onChanged;

  const FinishActionSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Finish Action', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...FinishAction.values.map((action) {
          final (label, description, color) = _actionInfo(action);
          final selected = action == value;

          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            color: selected ? color.withAlpha(30) : null,
            child: RadioListTile<FinishAction>(
              value: action,
              groupValue: value,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              title: Text(label),
              subtitle: Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              secondary: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              dense: true,
            ),
          );
        }),
      ],
    );
  }

  (String, String, Color) _actionInfo(FinishAction action) {
    return switch (action) {
      FinishAction.goHome => (
          'Go Home',
          'Drone returns to home point',
          Colors.green,
        ),
      FinishAction.noAction => (
          'No Action',
          'Drone hovers at last waypoint',
          Colors.amber,
        ),
      FinishAction.autoLand => (
          'Auto Land',
          'Drone lands at last waypoint',
          Colors.blue,
        ),
      FinishAction.backToFirstWaypoint => (
          'Back to First',
          'Drone flies back to first waypoint',
          Colors.orange,
        ),
    };
  }
}
