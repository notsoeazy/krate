import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/library/media_management_screen.dart';
import 'package:krate/ui/screens/player/player_screen.dart';

import 'package:krate/ui/widgets/expandable_text.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/ui/widgets/media_backdrop.dart';
import 'package:krate/ui/widgets/media_more_menu_button.dart';
import 'package:krate/ui/widgets/season_episode_list.dart';
import 'package:krate/ui/widgets/sliver_tab_bar_delegate.dart';

// Max expanded height of the backdrop
const double _kExpandedHeight = 340.0;

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
    _tabController.removeListener(_onSeasonTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onSeasonTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() => _manualSeasonIndex = _tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.content;
    final isSeries = content.contentType == ContentType.series;
    final resumeEpisodeAsync = ref.watch(resumeEpisodeProvider(content.id!));

    void fetchMetadata() async {
      try {
        final notifier = ref.read(importJobsProvider.notifier);
        final service = ref.read(importServiceProvider);
        if (isSeries) {
          await notifier.fetchMetadataSeries(service: service, content: content);
        } else {
          await notifier.fetchMetadataMovie(service: service, content: content);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    void vaultSync() async {
      if (content.podPath == null) return;
      try {
        await ref.read(vaultSyncProvider.notifier).syncPod(content.podPath!, content.id!);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    ref.listen(resumeEpisodeProvider(content.id!), (previous, next) {
      if (_manualSeasonIndex == null && next.hasValue && next.value != null) {
        final ep = next.value!;
        if (ep.seasonNumber != null &&
            ep.seasonNumber! <= _tabController.length) {
          _tabController.animateTo(ep.seasonNumber! - 1);
        }
      }
    });

    final headerSlivers = [
      SliverAppBar(
        expandedHeight: _kExpandedHeight,
        pinned: true,
        stretch: true,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final settings = context
                .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
            if (settings == null) return const SizedBox.shrink();
            final deltaExtent = settings.maxExtent - settings.minExtent;
            final t =
                (1.0 -
                        (settings.currentExtent - settings.minExtent) /
                            deltaExtent)
                    .clamp(0.0, 1.0);
            return Opacity(
              opacity: t > 0.8 ? (t - 0.8) * 5 : 0.0,
              child: Text(
                content.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          MediaMoreMenuButton(
            onManage: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    MediaManagementScreen(contentId: content.id!),
              ),
            ),
            onVaultSync: vaultSync,
            onFetchMetadata: fetchMetadata,
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          centerTitle: false,
          background: Stack(
            fit: StackFit.expand,
            children: [
              MediaBackdrop(content: content),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final settings = context
                        .dependOnInheritedWidgetOfExactType<
                          FlexibleSpaceBarSettings
                        >();
                    final opacity = settings != null
                        ? ((settings.currentExtent - settings.minExtent) /
                                  (settings.maxExtent - settings.minExtent))
                              .clamp(0.0, 1.0)
                        : 1.0;

                    return Opacity(
                      opacity: opacity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildPoster(content),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    content.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: const [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 8,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildHeaderInfoRow(content, theme),
                                  const SizedBox(height: 8),
                                  if (content.voteAverage > 0)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          content.voteAverage.toStringAsFixed(
                                            1,
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const Text(
                                          ' / 10',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  if (content.tagline != null &&
                                      content.tagline!.isNotEmpty)
                                    Text(
                                      content.tagline!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.white70,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description:',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ExpandableText(
                text: content.description ?? 'No description available.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (content.genres != null && content.genres!.isNotEmpty)
                _buildGenreChips(content, theme),
              const SizedBox(height: 24),
              _buildContinueButton(
                context,
                ref,
                content,
                resumeEpisodeAsync,
                theme,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      if (isSeries)
        SliverPersistentHeader(
          pinned: true,
          delegate: SliverTabBarDelegate(
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              onTap: (index) => setState(() => _manualSeasonIndex = index),
              tabs: List.generate(
                content.totalSeasons,
                (i) => Tab(text: 'Season ${i + 1}'),
              ),
            ),
          ),
        ),
    ];

    return Scaffold(
      body: isSeries
          ? NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) =>
                  headerSlivers,
              body: TabBarView(
                controller: _tabController,
                children: List.generate(
                  content.totalSeasons,
                  (i) => SeasonEpisodeList(
                    contentId: content.id!,
                    seasonNumber: i + 1,
                  ),
                ),
              ),
            )
          : CustomScrollView(slivers: headerSlivers),
    );
  }

  // Header Metadata
  Widget _buildHeaderInfoRow(Content content, ThemeData theme) {
    final parts = <String>[];
    if (content.releaseDate != null) {
      parts.add('${content.releaseDate!.year}');
    }
    if (content.contentType == ContentType.series) {
      if (content.totalSeasons > 0) {
        parts.add(
          '${content.totalSeasons} '
          '${content.totalSeasons == 1 ? 'Season' : 'Seasons'}',
        );
      }
      if (content.totalEpisodes > 0) {
        parts.add(
          '${content.totalEpisodes} '
          '${content.totalEpisodes == 1 ? 'Episode' : 'Episodes'}',
        );
      }
    } else {
      if (content.runtime != null) {
        parts.add('${content.runtime} min');
      }
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    final style = theme.textTheme.bodySmall?.copyWith(color: Colors.white70);
    return Row(
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('•', style: style),
            ),
          Text(parts[i], style: style),
        ],
      ],
    );
  }

  // Poster
  Widget _buildPoster(Content content) {
    ImageProvider? image;
    if (content.localPosterPath != null) {
      final f = File(content.localPosterPath!);
      if (f.existsSync()) {
        image = FileImage(f);
      }
    } else if (content.tmdbPosterPath != null) {
      image = CachedNetworkImageProvider(
        '$kTmdbImageBase/w342${content.tmdbPosterPath}',
      );
    }

    return Container(
      width: 110,
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image != null
            ? Image(
                key: ValueKey(content.updatedAt),
                image: image,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey[900],
                child: Icon(
                  content.contentType == ContentType.series
                      ? Icons.tv
                      : Icons.movie,
                  color: Colors.white24,
                  size: 40,
                ),
              ),
      ),
    );
  }

  // Genres
  Widget _buildGenreChips(Content content, ThemeData theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: (content.genres ?? []).map((genre) {
        return Chip(
          label: Text(genre),
          labelStyle: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  // Actions
  Widget _buildContinueButton(
    BuildContext context,
    WidgetRef ref,
    Content content,
    AsyncValue<Episode?> resumeEpisodeAsync,
    ThemeData theme,
  ) {
    return resumeEpisodeAsync.when(
      data: (episode) {
        if (episode == null) return const SizedBox.shrink();
        String label = content.contentType == ContentType.series
            ? 'Play S${episode.seasonNumber}:E${episode.episodeNumber}'
            : 'Play Movie';
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
            return _buildButtonRow(
              context,
              ref,
              content,
              episode,
              finalLabel,
              episode.hasFile,
              theme,
            );
          },
          loading: () => _buildButtonRow(
            context,
            ref,
            content,
            episode,
            label,
            false,
            theme,
            loading: true,
          ),
          error: (_, _) => _buildButtonRow(
            context,
            ref,
            content,
            episode,
            label,
            episode.hasFile,
            theme,
          ),
        );
      },
      loading: () => _buildButtonRow(
        context,
        ref,
        content,
        null,
        'Play',
        false,
        theme,
        loading: true,
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildButtonRow(
    BuildContext context,
    WidgetRef ref,
    Content content,
    Episode? episode,
    String label,
    bool hasFile,
    ThemeData theme, {
    bool loading = false,
  }) {
    const rowHeight = 52.0;
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: (hasFile && !loading && episode != null)
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PlayerScreen(episodeId: episode.id!),
                      ),
                    )
                  : null,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, rowHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(rowHeight / 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: rowHeight,
            height: rowHeight,
            child: FilledButton.tonal(
              onPressed: () async {
                await ref
                    .read(contentRepoProvider)
                    .setFavorite(content.id!, !content.isFavorite);
                ref.invalidate(contentProvider(content.id!));
                ref.invalidate(moviesProvider);
                ref.invalidate(seriesProvider);
                ref.invalidate(recentMoviesProvider);
                ref.invalidate(recentSeriesProvider);
                ref.invalidate(continueWatchingProvider);
              },
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                minimumSize: Size(rowHeight, rowHeight),
              ),
              child: Icon(
                content.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                color: content.isFavorite ? theme.colorScheme.error : null,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



