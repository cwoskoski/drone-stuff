import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/detail/:id/:source',
      builder: (context, state) {
        // Placeholder for DS-008
        return Scaffold(
          appBar: AppBar(title: const Text('Mission Detail')),
          body: Center(
            child: Text(
              'Mission: ${state.pathParameters['id']}\n'
              'Source: ${state.pathParameters['source']}',
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/push/:id',
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Push Mission')),
          body: const Center(child: Text('Push — coming soon')),
        );
      },
    ),
    GoRoute(
      path: '/split/:id',
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Split Mission')),
          body: const Center(child: Text('Split — coming soon')),
        );
      },
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Mission')),
          body: const Center(child: Text('Edit — coming soon')),
        );
      },
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
