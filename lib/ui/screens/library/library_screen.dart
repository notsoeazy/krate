import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/library/media_details_screen.dart';
import 'package:krate/ui/widgets/media_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SearchController _searchController = SearchController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(libraryTabProvider);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Invalidates all content list providers so both tabs and Home cards refresh.
  Future<void> _refresh() async {
    ref.invalidate(moviesProvider);
    ref.invalidate(seriesProvider);
    ref.invalidate(recentMoviesProvider);
    ref.invalidate(recentSeriesProvider);
    ref.invalidate(continueWatchingProvider);
    // Wait for the current tab's data to finish reloading
    final provider = _tabController.index == 0
        ? moviesProvider
        : seriesProvider;
    await ref.read(provider.future);
  }

  @override
  Widget build(BuildContext context) {
    // React to Home "See All" taps even when mounted in IndexedStack
    ref.listen<int>(libraryTabProvider, (_, next) {
      if (_tabController.index != next) _tabController.animateTo(next);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh library',
            onPressed: _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              // M3 SearchBar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search your vault…',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                  onChanged: (val) => setState(() => _searchQuery = val),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Movies'),
                  Tab(text: 'Series'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ContentGrid(
            type: ContentType.movie,
            query: _searchQuery,
            onRefresh: _refresh,
          ),
          _ContentGrid(
            type: ContentType.series,
            query: _searchQuery,
            onRefresh: _refresh,
          ),
        ],
      ),
    );
  }
}

class _ContentGrid extends ConsumerWidget {
  final ContentType type;
  final String query;
  final Future<void> Function() onRefresh;

  const _ContentGrid({
    required this.type,
    required this.query,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final provider = type == ContentType.movie
        ? moviesProvider
        : seriesProvider;
    final asyncItems = ref.watch(provider);

    return asyncItems.when(
      data: (items) {
        final filtered = items
            .where(
              (i) =>
                  query.isEmpty ||
                  i.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

        if (filtered.isEmpty) {
          // Empty state is also pull-to-refresh-able
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_filter_outlined,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty
                              ? 'Your vault is empty'
                              : 'No matches found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2 / 4.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return MediaCard(
                content: filtered[index],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        MediaDetailsScreen(contentId: filtered[index].id!),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
