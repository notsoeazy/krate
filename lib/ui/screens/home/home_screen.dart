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
          data: (items) => _ContinueWatchingRow(
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

// ── Continue Watching row ─────────────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Continue Watching', style: theme.textTheme.titleMedium),
              // TextButton — correct M3 low-emphasis action
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
        ),
        SizedBox(
          height: 240,
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

// ── Single Continue Watching card ─────────────────────────────────────────────

class _ContinueWatchingItemCard extends ConsumerWidget {
  final Content content;
  const _ContinueWatchingItemCard({required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resumeEpisodeAsync = ref.watch(resumeEpisodeProvider(content.id!));
    final isLoading = resumeEpisodeAsync.isLoading;

    return SizedBox(
      width: 120,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          resumeEpisodeAsync.whenData((episode) {
            if (episode == null || !episode.hasFile) {
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
            // Poster card
            MediaCard(content: content, onTap: () {}, width: 120),

            // Loading overlay — colorScheme.scrim instead of Colors.black38
            if (isLoading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.scrim.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(12),
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

            // Play icon overlay
            if (!isLoading)
              Positioned(
                bottom: 36,
                left: 0,
                right: 0,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
