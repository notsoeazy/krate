import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/library/media_details_screen.dart';
import 'package:krate/ui/widgets/horizontal_media_row.dart';
import 'package:krate/ui/widgets/continue_watching_row.dart';

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
    final theme = Theme.of(context);
    final hasData =
        (continueWatching.valueOrNull?.isNotEmpty ?? false) ||
        (recentMovies.valueOrNull?.isNotEmpty ?? false) ||
        (recentSeries.valueOrNull?.isNotEmpty ?? false);

    final isLoading =
        continueWatching.isLoading ||
        recentMovies.isLoading ||
        recentSeries.isLoading;

    if (!hasData && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 80,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('Your library is empty', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Import your favourite movies or series',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(shellTabIndexProvider.notifier).state = 1;
              },
              icon: const Icon(Icons.add),
              label: const Text('Go to Library'),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        // Continue Watching
        continueWatching.when(
          data: (items) => ContinueWatchingRow(
            items: items,
            onSeeAll: () {
              ref.read(shellTabIndexProvider.notifier).state = 2;
            },
          ),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const SizedBox.shrink(),
        ),

        // Recent Movies
        recentMovies.when(
          data: (items) => HorizontalMediaRow(
            title: 'Movies',
            items: items,
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
          data: (items) => HorizontalMediaRow(
            title: 'Series',
            items: items,
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

