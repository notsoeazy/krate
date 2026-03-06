import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/episode_tile.dart';

class MediaDetailsScreen extends ConsumerWidget {
  final int contentId;
  const MediaDetailsScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentProvider(contentId));

    return contentAsync.when(
      data: (content) {
        if (content == null) {
          return const Scaffold(body: Center(child: Text('Content not found')));
        }
        return _MediaDetailsScaffold(content: content);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _MediaDetailsScaffold extends ConsumerStatefulWidget {
  final Content content;
  const _MediaDetailsScaffold({required this.content});

  @override
  ConsumerState<_MediaDetailsScaffold> createState() =>
      _MediaDetailsScaffoldState();
}

class _MediaDetailsScaffoldState extends ConsumerState<_MediaDetailsScaffold>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final seasonCount = widget.content.totalSeasons > 0
        ? widget.content.totalSeasons
        : 1;
    _tabController = TabController(length: seasonCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.content;
    final isSeries = content.contentType == ContentType.series;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildBackdrop(context, content),
                title: Text(
                  content.title,
                  style: const TextStyle(
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                titlePadding: EdgeInsetsDirectional.only(
                  start: 48,
                  bottom: isSeries ? 16 : 16, // Unified bottom padding
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetadataRow(context, content),
                    const SizedBox(height: 16),
                    if (content.tagline != null && content.tagline!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          content.tagline!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    Text(
                      content.description ?? 'No description available.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (isSeries)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: List.generate(
                      content.totalSeasons,
                      (i) => Tab(text: 'Season ${i + 1}'),
                    ),
                  ),
                ),
              ),
            if (!isSeries && content.fileStatus == FileStatus.ready)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _MoviePlayButton(contentId: content.id!),
                ),
              ),
          ];
        },
        body: isSeries
            ? TabBarView(
                controller: _tabController,
                children: List.generate(
                  content.totalSeasons,
                  (i) => _SeasonEpisodeList(
                    contentId: content.id!,
                    seasonNumber: i + 1,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, Content content) {
    return Row(
      children: [
        if (content.releaseDate != null)
          _buildBadge(context, '${content.releaseDate!.year}'),
        const SizedBox(width: 8),
        if (content.runtime != null)
          _buildBadge(context, '${content.runtime} min'),
        const SizedBox(width: 8),
        _buildBadge(context, content.contentType.name.toUpperCase()),
        const Spacer(),
        IconButton(
          icon: Icon(
            content.isFavorite ? Icons.favorite : Icons.favorite_border,
          ),
          color: content.isFavorite ? Colors.red : null,
          onPressed: () async {
            await ref
                .read(contentRepoProvider)
                .setFavorite(content.id!, !content.isFavorite);
            ref.invalidate(contentProvider(content.id!));
            ref.invalidate(moviesProvider);
            ref.invalidate(seriesProvider);
          },
        ),
      ],
    );
  }

  Widget _buildBackdrop(BuildContext context, Content content) {
    if (content.localBackdropPath != null) {
      final file = File(content.localBackdropPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, alignment: Alignment.center);
      }
    }

    if (content.tmdbBackdropPath != null) {
      return CachedNetworkImage(
        imageUrl:
            '$kTmdbImageBase/$kTmdbBackdropSize${content.tmdbBackdropPath}',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        placeholder: (context, url) => Container(color: Colors.black26),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _SeasonEpisodeList extends ConsumerWidget {
  final int contentId;
  final int seasonNumber;

  const _SeasonEpisodeList({
    required this.contentId,
    required this.seasonNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(
      mergedEpisodesProvider((
        contentId: contentId,
        seasonNumber: seasonNumber,
      )),
    );

    return episodesAsync.when(
      data: (eps) {
        if (eps.isEmpty) {
          return const Center(
            child: Text('No episodes found for this season.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
          itemCount: eps.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final ep = eps[index];
            return EpisodeTile(
              episode: ep,
              onPlay: () {
                if (ep.id != null) {
                  context.push('/player/${ep.id}');
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading episodes: $e')),
    );
  }
}

class _MoviePlayButton extends ConsumerWidget {
  final int contentId;
  const _MoviePlayButton({required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(contentEpisodesProvider(contentId));
    final theme = Theme.of(context);

    return episodesAsync.when(
      data: (eps) {
        if (eps.isEmpty) return const SizedBox.shrink();
        final movieEp = eps.first;

        return ElevatedButton.icon(
          onPressed: () => context.push('/player/${movieEp.id}'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play Movie'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
