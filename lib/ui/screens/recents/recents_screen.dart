import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/recents/components/recents_history_tab.dart';
import 'package:krate/ui/screens/recents/components/recents_watching_tab.dart';
import 'package:krate/ui/screens/recents/components/recents_completed_tab.dart';

class RecentsScreen extends ConsumerStatefulWidget {
  const RecentsScreen({super.key});

  @override
  ConsumerState<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends ConsumerState<RecentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(recentsTabProvider);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (ref.read(recentsTabProvider) != _tabController.index) {
          ref.read(recentsTabProvider.notifier).state = _tabController.index;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // React to Home "See All" taps even when mounted in IndexedStack
    ref.listen<int>(recentsTabProvider, (_, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
        // Tabs: History, Watching, Completed
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Watching'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      // Tab Views
      body: TabBarView(
        controller: _tabController,
        children: const [
          RecentsHistoryTab(),
          RecentsWatchingTab(),
          RecentsCompletedTab(),
        ],
      ),
    );
  }
}
