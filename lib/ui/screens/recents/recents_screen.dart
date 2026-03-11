import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/media_card.dart';
import 'package:krate/ui/widgets/history_item_card.dart';
import 'package:krate/ui/screens/library/media_details_screen.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Recents'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Added'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _HistoryView(),
          _RecentlyAddedView(),
          _CompletedView(),
        ],
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  final String message;
  final IconData icon;
  const _PlaceholderView({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryView extends ConsumerWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryListProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(watchHistoryListProvider),
      child: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                _PlaceholderView(
                  icon: Icons.history,
                  message: 'No watch history',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return HistoryItemCard(row: items[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [Center(child: Text('Error loading history'))],
        ),
      ),
    );
  }
}

class _RecentlyAddedView extends ConsumerWidget {
  const _RecentlyAddedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addedAsync = ref.watch(recentlyAddedAllProvider);
    return _buildContentGrid(
      context,
      addedAsync,
      'No recently added items',
      Icons.new_releases_outlined,
      () async => ref.invalidate(recentlyAddedAllProvider),
    );
  }
}

class _CompletedView extends ConsumerWidget {
  const _CompletedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(completedContentProvider);
    return _buildContentGrid(
      context,
      completedAsync,
      'No completed items',
      Icons.task_alt,
      () async => ref.invalidate(completedContentProvider),
    );
  }
}

Widget _buildContentGrid(
  BuildContext context,
  AsyncValue<List<Content>> asyncData,
  String emptyMessage,
  IconData emptyIcon,
  Future<void> Function() onRefresh,
) {
  return RefreshIndicator(
    onRefresh: onRefresh,
    child: asyncData.when(
      data: (items) {
        if (items.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 200),
              _PlaceholderView(icon: emptyIcon, message: emptyMessage),
            ],
          );
        }
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            childAspectRatio: 2 / 4.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final content = items[index];
            return MediaCard(
              content: content,
              showType: true,
              width: double.infinity,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MediaDetailsScreen(contentId: content.id!),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [Center(child: Text('Error loading data'))],
      ),
    ),
  );
}
