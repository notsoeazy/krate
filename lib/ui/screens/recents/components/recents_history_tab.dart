import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/empty_state_view.dart';
import 'package:krate/ui/screens/media_details/media_details_screen.dart';
import 'package:krate/ui/screens/recents/components/recents_history_card.dart';
import 'package:krate/utils/extensions.dart';

class RecentsHistoryTab extends ConsumerWidget {
  const RecentsHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryListProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(watchHistoryListProvider),
      child: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                const SizedBox(height: 8),
                EmptyStateView(
                  icon: Icons.history,
                  message: 'No watch history',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _HistoryItem(row: items[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [Center(child: Text('Error loading history'))],
        ),
      ),
    );
  }
}

class _HistoryItem extends ConsumerWidget {
  final Map<String, dynamic> row;

  const _HistoryItem({required this.row});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contentId = row['contentId'] as int;
    final episodeId = row['episodeId'] as int;
    final title = row['title'] as String? ?? 'Unknown';
    final season = row['seasonNumber'] as int?;
    final episode = row['episodeNumber'] as int?;
    final episodeTitle = row['episodeTitle'] as String?;
    final finishedAtStr = row['finishedAt'] as String?;
    final localPosterPath = row['localPosterPath'] as String?;

    final progressAsync = ref.watch(watchProgressProvider(episodeId));

    String subtitle = '';
    if (season != null && episode != null) {
      subtitle = 'S$season E$episode';
      if (episodeTitle != null) subtitle += ' - $episodeTitle';
    }

    String dateText = '';
    if (finishedAtStr != null) {
      final dt = DateTime.tryParse(finishedAtStr);
      if (dt != null) {
        dateText = dt.toHistoryFormat();
      }
    }

    final isUnavailable = row['fileStatus'] == 'missing';

    return RecentsHistoryCard(
      title: title,
      subtitle: subtitle,
      tagText: dateText.isNotEmpty ? 'Watched $dateText' : null,
      localPosterPath: localPosterPath,
      isUnavailable: isUnavailable,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MediaDetailsScreen(contentId: contentId),
          ),
        );
      },
      progressIndicator: progressAsync.when(
        data: (progress) {
          if (progress == null) return const SizedBox.shrink();
          final isFinished = progress.isFinished;
          final duration = Duration(milliseconds: progress.durationMs);
          final position = Duration(milliseconds: progress.positionMs);
          final minLeft = (duration - position).inMinutes;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: progress.durationMs > 0
                    ? progress.positionMs / progress.durationMs
                    : 0,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
                color: isFinished ? theme.colorScheme.primary : null,
              ),
              const SizedBox(height: 8),
              // Time Remaining Text
              Text(
                isFinished ? 'Completed' : '$minLeft mins left',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isFinished
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
            ],
          );
        },
        loading: () => const LinearProgressIndicator(minHeight: 4),
        error: (error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}
