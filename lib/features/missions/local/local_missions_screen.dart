import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import 'local_missions_provider.dart';

class LocalMissionsScreen extends ConsumerWidget {
  const LocalMissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(localMissionsProvider);

    return missionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (missions) {
        if (missions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No imported missions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to import a KMZ file',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: missions.length,
          itemBuilder: (context, index) => _LocalMissionCard(
            mission: missions[index],
            onDelete: () => _deleteMission(context, ref, missions[index]),
          ),
        );
      },
    );
  }

  Future<void> _deleteMission(
    BuildContext context,
    WidgetRef ref,
    Mission mission,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete mission?'),
        content: Text('Remove "${mission.fileName}" from local storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(localMissionRepositoryProvider);
      await repo.deleteMission(mission.id);
    }
  }
}

class _LocalMissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback onDelete;

  const _LocalMissionCard({required this.mission, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final importDate = DateTime.fromMillisecondsSinceEpoch(mission.importedAt);

    return Dismissible(
      key: ValueKey(mission.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Let the dialog handle it
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(_sourceIcon(mission.sourceType)),
          ),
          title: Text(mission.fileName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mission.author != null)
                Text('Author: ${mission.author}'),
              Row(
                children: [
                  Text('${mission.waypointCount} waypoints'),
                  const Text('  ·  '),
                  _SourceBadge(sourceType: mission.sourceType),
                ],
              ),
              Text(
                'Imported ${DateFormat.yMMMd().add_Hm().format(importDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () => context.push('/detail/${mission.id}/local'),
        ),
      ),
    );
  }

  IconData _sourceIcon(String sourceType) {
    switch (sourceType) {
      case 'split':
        return Icons.call_split;
      case 'merged':
        return Icons.merge;
      case 'edited':
        return Icons.edit;
      default:
        return Icons.file_download;
    }
  }
}

class _SourceBadge extends StatelessWidget {
  final String sourceType;

  const _SourceBadge({required this.sourceType});

  @override
  Widget build(BuildContext context) {
    final color = switch (sourceType) {
      'split' => Colors.orange,
      'merged' => Colors.purple,
      'edited' => Colors.teal,
      _ => Colors.blue,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        sourceType,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
