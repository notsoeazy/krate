import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/media_details/media_management_screen.dart';
import 'package:krate/ui/screens/player/player_screen.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/ui/screens/media_details/components/media_details_backdrop.dart';
import 'package:krate/ui/screens/media_details/components/media_details_more_menu.dart';
import 'package:krate/ui/screens/media_details/components/media_details_season_list.dart';
import 'package:krate/ui/screens/media_details/components/media_details_selection_toolbar.dart';
import 'package:krate/ui/screens/media_details/components/media_details_season_selection_modal.dart';
import 'package:krate/ui/widgets/confirmation_dialog.dart';
import 'package:krate/ui/widgets/media_info_row.dart';
import 'package:krate/ui/widgets/media_overview_section.dart';
import 'package:krate/utils/errors.dart';
import 'package:krate/utils/feedback_utils.dart';

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
    final content = widget.content;
    final isSeries = content.contentType == ContentType.series;

    void fetchMetadata() async {
      try {
        final notifier = ref.read(importJobsProvider.notifier);
        final service = ref.read(importServiceProvider);
        if (isSeries) {
          await notifier.fetchMetadataSeries(
            service: service,
            content: content,
          );
        } else {
          await notifier.fetchMetadataMovie(service: service, content: content);
        }
        if (context.mounted) {
          FeedbackUtils.showSuccessSnackBar(
            context,
            'Metadata updated successfully',
          );
        }
      } catch (e) {
        debugPrint('[MediaDetailsScreen] Fetch Metadata Error: $e');
        if (context.mounted) {
          if (e is NoInternetException) {
            FeedbackUtils.showErrorSnackBar(
              context,
              'No internet connection. Cannot connect to TMDB.',
            );
          } else {
            FeedbackUtils.showErrorSnackBar(
              context,
              'Failed to fetch metadata',
              error: e,
            );
          }
        }
      }
    }

    void vaultSync() async {
      if (content.podPath == null) return;
      try {
        await ref
            .read(vaultSyncProvider.notifier)
            .syncPod(content.podPath!, content.id!);
        if (context.mounted) {
          FeedbackUtils.showSuccessSnackBar(
            context,
            'Vault synced successfully',
          );
        }
      } catch (e) {
        debugPrint('[MediaDetailsScreen] Vault Sync Error: $e');
        if (context.mounted) {
          if (e is NoInternetException) {
            FeedbackUtils.showErrorSnackBar(
              context,
              'No internet connection. Cannot connect to TMDB.',
            );
          } else {
            FeedbackUtils.showErrorSnackBar(
              context,
              'Vault sync failed',
              error: e,
            );
          }
        }
      }
    }

    final resumeEpisodeAsync = ref.watch(resumeEpisodeProvider(content.id!));
    if (_manualSeasonIndex == null && resumeEpisodeAsync.hasValue) {
      final ep = resumeEpisodeAsync.value;
      if (ep != null &&
          ep.seasonNumber != null &&
          ep.seasonNumber! <= _tabController.length &&
          ep.seasonNumber! - 1 != _tabController.index) {
        // Defer switching to the next frame to avoid building during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _manualSeasonIndex == null) {
            _tabController.animateTo(ep.seasonNumber! - 1);
          }
        });
      }
    }

    final headerSlivers = [
      _MediaDetailsAppBar(
        content: content,
        onVaultSync: vaultSync,
        onFetchMetadata: fetchMetadata,
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MediaOverviewSection(content: content),
              const SizedBox(height: 24),
              _MediaDetailsActionRow(
                contentId: content.id!,
                contentType: content.contentType,
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

    final selectionState = ref.watch(watchedSelectionProvider(content.id!));

    return Scaffold(
      body: isSeries
          ? NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) =>
                  headerSlivers,
              body: TabBarView(
                controller: _tabController,
                children: List.generate(
                  content.totalSeasons,
                  (i) => MediaDetailsSeasonList(
                    contentId: content.id!,
                    seasonNumber: i + 1,
                  ),
                ),
              ),
            )
          : CustomScrollView(slivers: headerSlivers),
      bottomNavigationBar: selectionState.isSelectionMode
          ? MediaDetailsSelectionToolbar(
              contentId: content.id!,
              selectedCount: selectionState.selectedEpisodeIds.length,
            )
          : null,
    );
  }
}

class _MediaDetailsAppBar extends ConsumerWidget {
  final Content content;
  final VoidCallback onVaultSync;
  final VoidCallback onFetchMetadata;

  const _MediaDetailsAppBar({
    required this.content,
    required this.onVaultSync,
    required this.onFetchMetadata,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SliverAppBar(
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
        MediaDetailsMoreMenu(
          contentType: content.contentType,
          onManage: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  MediaManagementScreen(contentId: content.id!),
            ),
          ),
          onVaultSync: onVaultSync,
          onFetchMetadata: onFetchMetadata,
          onEnterSelectionMode: () {
            ref
                .read(watchedSelectionProvider(content.id!).notifier)
                .enterSelectionMode();
          },
          onMarkSeasons: () =>
              MediaDetailsSeasonSelectionModal.show(context, content),
          onMarkFinished: () async {
            if (content.contentType == ContentType.movie) {
              final service = ref.read(watchProgressServiceProvider);
              final snapshot = await service.markSeasonFinished(content.id!, 0);
              if (context.mounted) {
                FeedbackUtils.showUndoSnackBar(
                  context,
                  'Marked "${content.title}" as watched',
                  () async {
                    await service.restoreSnapshot(content.id!, snapshot);
                  },
                );
              }
            }
          },
          onClearSeriesProgress: () async {
            final confirmed = await ConfirmationDialog.show(
              context,
              title: 'Clear watch history?',
              message:
                  'This will remove all watch progress for ${content.title}. This action cannot be undone.',
              confirmLabel: 'Clear',
              isDestructive: true,
            );
            if (confirmed) {
              final service = ref.read(watchProgressServiceProvider);
              final snapshot = await service.clearSeriesProgress(content.id!);
              if (context.mounted) {
                FeedbackUtils.showUndoSnackBar(
                  context,
                  'Cleared history for "${content.title}"',
                  () async {
                    await service.restoreSnapshot(content.id!, snapshot);
                  },
                );
              }
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        background: Stack(
          fit: StackFit.expand,
          children: [
            MediaDetailsBackdrop(content: content),
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
                      child: MediaInfoRow(
                        content: content,
                        useOnBackdrop: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaDetailsActionRow extends ConsumerWidget {
  final int contentId;
  final ContentType contentType;

  const _MediaDetailsActionRow({
    required this.contentId,
    required this.contentType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resumeEpisodeAsync = ref.watch(resumeEpisodeProvider(contentId));

    return resumeEpisodeAsync.when(
      data: (episode) {
        if (episode == null) return const SizedBox.shrink();
        String label = contentType == ContentType.series
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
              episode,
              finalLabel,
              episode.hasFile,
              theme,
            );
          },
          loading: () =>
              _buildButtonRow(context, ref, episode, label, false, theme),
          error: (_, _) => _buildButtonRow(
            context,
            ref,
            episode,
            label,
            episode.hasFile,
            theme,
          ),
        );
      },
      loading: () => _buildButtonRow(context, ref, null, 'Play', false, theme),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildButtonRow(
    BuildContext context,
    WidgetRef ref,
    Episode? episode,
    String label,
    bool hasFile,
    ThemeData theme, {
    bool loading = false,
  }) {
    const rowHeight = 52.0;

    // We need the content to get favorite status
    final contentAsync = ref.watch(contentProvider(contentId));
    final content = contentAsync.valueOrNull;

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
                  : const Icon(Icons.play_arrow_rounded, size: 28),
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
          const SizedBox(width: 16),
          // Favorite Toggle
          SizedBox(
            width: rowHeight,
            height: rowHeight,
            child: FilledButton.tonal(
              onPressed: content != null
                  ? () async {
                      await ref
                          .read(contentRepoProvider)
                          .setFavorite(contentId, !content.isFavorite);
                      ref.invalidate(contentProvider(contentId));
                      ref.invalidate(moviesProvider);
                      ref.invalidate(seriesProvider);
                      ref.invalidate(recentMoviesProvider);
                      ref.invalidate(recentSeriesProvider);
                      ref.invalidate(continueWatchingProvider);
                    }
                  : null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: Icon(
                content?.isFavorite == true
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                color: content?.isFavorite == true
                    ? theme.colorScheme.error
                    : null,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  SliverTabBarDelegate(this._tabBar);

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
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(SliverTabBarDelegate old) => false;
}
