import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/library/media_details_screen.dart';
import 'package:krate/ui/screens/player/player_screen.dart';
import 'package:krate/ui/widgets/horizontal_media_row.dart';
import 'package:krate/ui/widgets/media_card.dart';

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
              ref.read(shellTabIndexProvider.notifier).state = 1; // Library
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Your library is empty',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Import your favorite movies or series',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(shellTabIndexProvider.notifier).state = 1; // Library
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
          data: (items) => _ContinueWatchingRow(
            items: items,
            onSeeAll: () {
              ref.read(shellTabIndexProvider.notifier).state = 2; // Recents
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
              ref.read(libraryTabProvider.notifier).state = 0; // Movies tab
              ref.read(shellTabIndexProvider.notifier).state = 1; // Library
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

        // Series
        recentSeries.when(
          data: (items) => HorizontalMediaRow(
            title: 'Series',
            items: items,
            onSeeAll: () {
              ref.read(libraryTabProvider.notifier).state = 1; // Series tab
              ref.read(shellTabIndexProvider.notifier).state = 1; // Library
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

// ---------------------------------------------------------------------------
// Continue Watching row — custom implementation so each card can resolve its
// own resume episode before launching the player.
// ---------------------------------------------------------------------------

/// Renders the "Continue Watching" horizontal row.
class _ContinueWatchingRow extends StatelessWidget {
  final List<Content> items;
  final VoidCallback onSeeAll;

  const _ContinueWatchingRow({required this.items, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Continue Watching', style: theme.textTheme.titleMedium),
              InkWell(
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'See all →',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _ContinueWatchingItemCard(content: items[index]),
          ),
        ),
      ],
    );
  }
}

/// A single Continue Watching card.
///
/// Resolves [resumeEpisodeProvider] per-content so the tap always opens the
/// correct episode — identical logic to the Play button in [MediaDetailsScreen].
class _ContinueWatchingItemCard extends ConsumerWidget {
  final Content content;
  const _ContinueWatchingItemCard({required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeEpisodeAsync = ref.watch(resumeEpisodeProvider(content.id!));
    final isLoading = resumeEpisodeAsync.isLoading;

    return GestureDetector(
      onTap: () {
        resumeEpisodeAsync.whenData((episode) {
          if (episode == null || !episode.hasFile) {
            // No playable episode — open the details screen instead.
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MediaDetailsScreen(contentId: content.id!),
              ),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlayerScreen(episodeId: episode.id!),
            ),
          );
        });
      },
      child: Stack(
        children: [
          // Shared MediaCard for poster / title / progress bar rendering.
          MediaCard(content: content, onTap: () {}, width: 120),

          // Spinner while the resume episode is resolving.
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),

          // Play icon overlay when ready.
          if (!isLoading)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
