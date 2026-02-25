import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../missions/device/device_missions_screen.dart';
import '../missions/import/import_provider.dart';
import '../missions/local/local_missions_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DroneStuff'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.phone_android), text: 'Device'),
            Tab(icon: Icon(Icons.folder), text: 'Local'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DeviceMissionsScreen(),
          LocalMissionsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _importKmz(context),
        tooltip: 'Import KMZ',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _importKmz(BuildContext context) async {
    try {
      final imported =
          await ref.read(importProvider.notifier).importKmzFile();
      if (imported && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission imported successfully')),
        );
        _tabController.animateTo(1); // Switch to Local tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }
}
