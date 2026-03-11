import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/library/media_details_screen.dart';
import 'package:krate/ui/widgets/recent_media_card.dart';

class HistoryItemCard extends ConsumerWidget {
  final Map<String, dynamic> row;

  const HistoryItemCard({super.key, required this.row});

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
        dateText =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    }

    return RecentMediaCard(
      title: title,
      subtitle: subtitle,
      tagText: dateText.isNotEmpty ? 'Watched $dateText' : null,
      localPosterPath: localPosterPath,
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
              const SizedBox(height: 4),
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
