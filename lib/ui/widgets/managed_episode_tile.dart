import 'package:flutter/material.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';

enum ManagedTileMode { normal, delete }

/// A [ListTile]-based widget for displaying an episode in the management screen.
class ManagedEpisodeTile extends StatelessWidget {
  final Episode episode;
  final ManagedTileMode mode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectedChanged;
  final VoidCallback? onImport;
  final StagedFile? stagedFile;
  final VoidCallback? onRemoveFile;

  const ManagedEpisodeTile({
    super.key,
    required this.episode,
    this.mode = ManagedTileMode.normal,
    this.isSelected = false,
    this.onSelectedChanged,
    this.onImport,
    this.stagedFile,
    this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Delete Mode
    if (mode == ManagedTileMode.delete) {
      return CheckboxListTile(
        value: isSelected,
        onChanged: episode.hasFile ? onSelectedChanged : null,
        enabled: episode.hasFile,
        title: Text(
          episode.title ?? 'Episode ${episode.episodeNumber}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: episode.hasFile
                ? null
                : theme.colorScheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
        // File Status Subtitle
        subtitle: _buildSubtitle(theme),
        // Episode Number Leading
        secondary: _buildEpisodeNumber(theme),
        controlAffinity: ListTileControlAffinity.leading,
      );
    }

    // Normal Mode
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildEpisodeNumber(theme),
      title: Text(
        episode.title ?? 'Episode ${episode.episodeNumber}',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: episode.hasFile || stagedFile != null
              ? null
              : theme.colorScheme.onSurface.withValues(alpha: 0.38),
        ),
      ),
      // File Status Subtitle
      subtitle: _buildSubtitle(theme),
      // Action Buttons
      trailing: _buildTrailing(theme),
    );
  }

  Widget _buildEpisodeNumber(ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '${episode.episodeNumber ?? ''}',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: episode.hasFile
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget? _buildSubtitle(ThemeData theme) {
    if (stagedFile != null) {
      final isReplace = stagedFile!.isReplace;
      return Row(
        children: [
          Icon(
            isReplace ? Icons.swap_horiz : Icons.file_present,
            size: 14,
            color: isReplace
                ? theme.colorScheme.secondary
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${stagedFile!.path.split('/').last}${isReplace ? ' (Replace)' : ''}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isReplace
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (episode.videoPath != null) {
      return Text(
        episode.videoPath!.split('/').last,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      'Missing file',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.error.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildTrailing(ThemeData theme) {
    if (stagedFile != null) {
      return IconButton(
        icon: const Icon(Icons.close, size: 20),
        onPressed: onRemoveFile,
        tooltip: 'Remove selected file',
      );
    }

    return IconButton(
      icon: Icon(episode.hasFile ? Icons.swap_horiz : Icons.add_circle_outline),
      color: episode.hasFile ? theme.colorScheme.primary : null,
      onPressed: onImport,
      tooltip: episode.hasFile ? 'Replace File' : 'Import File',
    );
  }
}
