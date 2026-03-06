import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/horizontal_media_row.dart';

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
            onPressed: () {
              // TODO: Navigate to search/library
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
        child: ListView(
          children: [
            // Continue Watching
            continueWatching.when(
              data: (items) => HorizontalMediaRow(
                title: 'Continue Watching',
                items: items,
                onSeeAll: () {
                  // TODO: Go to Library or Recents
                },
                onItemSelected: (item) {
                  // TODO: Navigate to Player
                },
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const SizedBox.shrink(),
            ),

            // Movies
            recentMovies.when(
              data: (items) => HorizontalMediaRow(
                title: 'Movies',
                items: items,
                onSeeAll: () {
                  // Navigate to Library (Movies tab)
                  // Using shell navigation or branch index
                },
                onItemSelected: (item) => context.push('/details/${item.id}'),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),

            // Series
            recentSeries.when(
              data: (items) => HorizontalMediaRow(
                title: 'Series',
                items: items,
                onSeeAll: () {
                  // Navigate to Library (Series tab)
                },
                onItemSelected: (item) => context.push('/details/${item.id}'),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
