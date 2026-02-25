import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/edit/edit_mission_screen.dart';
import '../features/home/home_screen.dart';
import '../features/missions/detail/mission_detail_screen.dart';
import '../features/missions/map/mission_map_screen.dart';
import '../features/push/push_screen.dart';
import '../features/split_merge/merge/merge_screen.dart';
import '../features/split_merge/split/split_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/detail/:id/:source',
      builder: (context, state) {
        return MissionDetailScreen(
          id: state.pathParameters['id']!,
          source: state.pathParameters['source']!,
        );
      },
    ),
    GoRoute(
      path: '/map/:id/:source',
      builder: (context, state) {
        return MissionMapScreen(
          id: state.pathParameters['id']!,
          source: state.pathParameters['source']!,
        );
      },
    ),
    GoRoute(
      path: '/push/:id',
      builder: (context, state) {
        return PushScreen(
          localMissionId: state.pathParameters['id']!,
        );
      },
    ),
    GoRoute(
      path: '/split/:id/:source',
      builder: (context, state) {
        return SplitScreen(
          missionId: state.pathParameters['id']!,
          source: state.pathParameters['source']!,
        );
      },
    ),
    GoRoute(
      path: '/edit/:id/:source',
      builder: (context, state) {
        return EditMissionScreen(
          missionId: state.pathParameters['id']!,
          source: state.pathParameters['source']!,
        );
      },
    ),
    GoRoute(
      path: '/merge',
      builder: (context, state) => const MergeScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: const Center(child: Text('Settings — coming soon')),
        );
      },
    ),
  ],
);
