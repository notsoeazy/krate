import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/content_grid.dart';

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
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (ref.read(libraryTabProvider) != _tabController.index) {
          ref.read(libraryTabProvider.notifier).state = _tabController.index;
        }
      }
    });
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
              // Searchbar
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
              // Library Tabs
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
          ContentGrid(
            type: ContentType.movie,
            query: _searchQuery,
            onRefresh: _refresh,
            showType: false,
          ),
          ContentGrid(
            type: ContentType.series,
            query: _searchQuery,
            onRefresh: _refresh,
            showType: false,
          ),
        ],
      ),
    );
  }
}
