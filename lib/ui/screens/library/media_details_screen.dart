import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/library/media_management_screen.dart';
import 'package:krate/ui/screens/player/player_screen.dart';
import 'package:krate/ui/widgets/episode_tile.dart';
import 'package:krate/ui/widgets/expandable_text.dart';
import 'package:krate/data/models/episode.dart';

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
  int? _manualSeasonIndex;

  @override
  void initState() {
    super.initState();
    final seasonCount = widget.content.totalSeasons > 0
        ? widget.content.totalSeasons
        : 1;
    _tabController = TabController(length: seasonCount, vsync: this);
    _tabController.addListener(_onSeasonTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSeasonTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _manualSeasonIndex = _tabController.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.content;
    final isSeries = content.contentType == ContentType.series;

    final resumeEpisodeAsync = ref.watch(resumeEpisodeProvider(content.id!));

    // Update tab index based on resume episode if not manually changed
    ref.listen(resumeEpisodeProvider(content.id!), (previous, next) {
      if (_manualSeasonIndex == null && next.hasValue && next.value != null) {
        final ep = next.value!;
        if (ep.seasonNumber != null &&
            ep.seasonNumber! <= _tabController.length) {
          _tabController.animateTo(ep.seasonNumber! - 1);
        }
      }
    });

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              stretch: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildCircularButton(
                  context,
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  content.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 8,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 56,
                  bottom: 16,
                ),
                background: _buildBackdrop(context, content),
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
              ),
              actions: [_buildMoreMenu(context, content)],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _buildMetadataRow(context, content),
                    const SizedBox(height: 16),
                    ExpandableText(
                      text: content.description ?? 'No description available.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    _buildContinueButton(
                      context,
                      ref,
                      content,
                      resumeEpisodeAsync,
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
                    onTap: (index) =>
                        setState(() => _manualSeasonIndex = index),
                    tabs: List.generate(
                      content.totalSeasons,
                      (i) => Tab(text: 'Season ${i + 1}'),
                    ),
                  ),
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
      ],
    );
  }

  Widget _buildBackdrop(BuildContext context, Content content) {
    Widget image;
    if (content.localBackdropPath != null) {
      final file = File(content.localBackdropPath!);
      if (file.existsSync()) {
        image = Image.file(
          file,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        );
      } else {
        image = _buildPosterFallback(content);
      }
    } else if (content.tmdbBackdropPath != null) {
      image = CachedNetworkImage(
        imageUrl:
            '$kTmdbImageBase/$kTmdbBackdropSize${content.tmdbBackdropPath}',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        placeholder: (context, url) => Container(color: Colors.black26),
        errorWidget: (context, url, error) => _buildPosterFallback(content),
      );
    } else {
      image = _buildPosterFallback(content);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black45,
                Colors.transparent,
                Colors.transparent,
                Colors.black87,
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPosterFallback(Content content) {
    if (content.localPosterPath != null) {
      final file = File(content.localPosterPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, alignment: Alignment.center);
      }
    }
    if (content.tmdbPosterPath != null) {
      return CachedNetworkImage(
        imageUrl: '$kTmdbImageBase/$kTmdbPosterSize${content.tmdbPosterPath}',
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    }
    return Container(color: Colors.black26);
  }

  Widget _buildCircularButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildContinueButton(
    BuildContext context,
    WidgetRef ref,
    Content content,
    AsyncValue<Episode?> resumeEpisodeAsync,
  ) {
    return resumeEpisodeAsync.when(
      data: (episode) {
        if (episode == null) return const SizedBox.shrink();

        final hasFile = episode.hasFile;
        String label = 'Play';
        if (content.contentType == ContentType.series) {
          label = 'Play S${episode.seasonNumber}:E${episode.episodeNumber}';
        } else {
          label = 'Play Movie';
        }

        final progressAsync = ref.watch(watchProgressProvider(episode.id!));
        return progressAsync.when(
          data: (progress) {
            final isResume =
                progress != null &&
                progress.positionMs > 0 &&
                !progress.isFinished;
            final finalLabel = isResume
                ? label.replaceFirst('Play', 'Resume')
                : label;

            return _buildActualContinueButton(
              context,
              ref,
              content,
              episode,
              finalLabel,
              hasFile,
            );
          },
          loading: () => _buildLoadingContinueButton(context, label),
          error: (_, _) => _buildActualContinueButton(
            context,
            ref,
            content,
            episode,
            label,
            hasFile,
          ),
        );
      },
      loading: () => _buildLoadingContinueButton(context, 'Play'),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildActualContinueButton(
    BuildContext context,
    WidgetRef ref,
    Content content,
    Episode episode,
    String label,
    bool hasFile,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasFile
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          PlayerScreen(episodeId: episode.id!),
                    ),
                  )
                : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.12,
              ),
              disabledForegroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.38,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              content.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: content.isFavorite ? Colors.red : null,
            ),
            onPressed: () async {
              await ref
                  .read(contentRepoProvider)
                  .setFavorite(content.id!, !content.isFavorite);
              ref.invalidate(contentProvider(content.id!));
              ref.invalidate(moviesProvider);
              ref.invalidate(seriesProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContinueButton(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreMenu(BuildContext context, Content content) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'manage') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      MediaManagementScreen(contentId: content.id!),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'manage',
              child: ListTile(
                leading: Icon(Icons.video_library),
                title: Text('Manage Media'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ),
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(episodeId: ep.id!),
                    ),
                  );
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
