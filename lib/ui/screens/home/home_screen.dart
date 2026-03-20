import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/media_details/media_details_screen.dart';
import 'package:krate/ui/widgets/media_card_row.dart';
import 'package:krate/ui/screens/home/components/continue_watching_row.dart';
import 'package:krate/ui/screens/home/components/home_empty_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatching = ref.watch(continueWatchingProvider);
    final recentMovies = ref.watch(recentMoviesProvider);
    final recentSeries = ref.watch(recentSeriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Krate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search library',
            onPressed: () {
              ref.read(shellTabIndexProvider.notifier).state = 1;
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(continueWatchingProvider);
          ref.invalidate(recentMoviesProvider);
          ref.invalidate(recentSeriesProvider);
        },
        child: _buildContent(
          context,
          ref,
          continueWatching,
          recentMovies,
          recentSeries,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Content>> continueWatching,
    AsyncValue<List<Content>> recentMovies,
    AsyncValue<List<Content>> recentSeries,
  ) {
    final hasData =
        (continueWatching.valueOrNull?.isNotEmpty ?? false) ||
        (recentMovies.valueOrNull?.isNotEmpty ?? false) ||
        (recentSeries.valueOrNull?.isNotEmpty ?? false);

    final isLoading =
        continueWatching.isLoading ||
        recentMovies.isLoading ||
        recentSeries.isLoading;

    if (!hasData && !isLoading) {
      return const HomeEmptyState();
    }

    return ListView(
      children: [
        // Continue Watching
        continueWatching.when(
          data: (items) => ContinueWatchingRow(
            items: items,
            onSeeAll: () {
              ref.read(recentsTabProvider.notifier).state = 0;
              ref.read(shellTabIndexProvider.notifier).state = 2;
            },
          ),
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
        ),

        // Recent Movies
        recentMovies.when(
          data: (items) => MediaCardRow(
            title: 'Movies',
            items: items,
            showType: false,
            onSeeAll: () {
              ref.read(libraryTabProvider.notifier).state = 0;
              ref.read(shellTabIndexProvider.notifier).state = 1;
            },
            onItemSelected: (item) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MediaDetailsScreen(contentId: item.id!),
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
        ),

        // Recent Series
        recentSeries.when(
          data: (items) => MediaCardRow(
            title: 'Series',
            items: items,
            showType: false,
            onSeeAll: () {
              ref.read(libraryTabProvider.notifier).state = 1;
              ref.read(shellTabIndexProvider.notifier).state = 1;
            },
            onItemSelected: (item) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MediaDetailsScreen(contentId: item.id!),
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
