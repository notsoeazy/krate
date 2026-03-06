import 'package:flutter/material.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/data/models/episode.dart';

class EpisodeTile extends StatefulWidget {
  final Episode episode;
  final VoidCallback onPlay;
  final bool isCurrentlyPlaying;

  const EpisodeTile({
    super.key,
    required this.episode,
    required this.onPlay,
    this.isCurrentlyPlaying = false,
  });

  @override
  State<EpisodeTile> createState() => _EpisodeTileState();
}

class _EpisodeTileState extends State<EpisodeTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFile = widget.episode.fileStatus == FileStatus.ready;
    final episode = widget.episode;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        onExpansionChanged: (_) {},
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasFile
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${episode.episodeNumber ?? ''}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: hasFile
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        title: Text(
          episode.title ?? 'Episode ${episode.episodeNumber}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: widget.isCurrentlyPlaying
                ? FontWeight.bold
                : FontWeight.w500,
            color: hasFile
                ? null
                : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.4),
          ),
        ),
        subtitle: episode.airDate != null
            ? Text(
                'Aired: ${episode.airDate!.year}-${episode.airDate!.month.toString().padLeft(2, '0')}-${episode.airDate!.day.toString().padLeft(2, '0')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: hasFile
                      ? null
                      : theme.textTheme.labelSmall?.color?.withValues(
                          alpha: 0.4,
                        ),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasFile)
              IconButton(
                icon: const Icon(Icons.play_circle_filled, size: 28),
                color: theme.colorScheme.primary,
                onPressed: widget.onPlay,
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.save_alt, // Indicator for missing/not locally available
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (episode.description != null &&
                    episode.description!.isNotEmpty)
                  Text(
                    episode.description!,
                    textAlign: TextAlign.left,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasFile ? null : theme.disabledColor,
                    ),
                  )
                else
                  Text(
                    'No description available.',
                    textAlign: TextAlign.left,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.disabledColor,
                    ),
                  ),
                if (hasFile && episode.videoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'File: ${episode.videoPath!.split('/').last}',
                      textAlign: TextAlign.left,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
