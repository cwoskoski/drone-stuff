import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import 'local_mission_repository.dart';

final localMissionRepositoryProvider = Provider<LocalMissionRepository>((ref) {
  return LocalMissionRepository(
    dao: ref.watch(missionDaoProvider),
    documentsPath: ref.watch(_documentsPathProvider),
  );
});

final _documentsPathProvider = Provider<String>((ref) {
  // This will be overridden at app startup
  throw UnimplementedError('documentsPath not initialized');
});

final documentsPathProvider = _documentsPathProvider;

final localMissionsProvider = StreamProvider<List<Mission>>((ref) {
  final repo = ref.watch(localMissionRepositoryProvider);
  return repo.watchAllMissions();
});
