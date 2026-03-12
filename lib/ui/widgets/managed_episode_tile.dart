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
  final VoidCallback? onAddSubtitles;

  const ManagedEpisodeTile({
    super.key,
    required this.episode,
    this.mode = ManagedTileMode.normal,
    this.isSelected = false,
    this.onSelectedChanged,
    this.onImport,
    this.stagedFile,
    this.onRemoveFile,
    this.onAddSubtitles,
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
        subtitle: _buildSubtitleColumn(theme),
        secondary: _buildEpisodeNumber(theme),
        controlAffinity: ListTileControlAffinity.leading,
      );
    }

    // Normal Mode
    return Column(
      children: [
        ListTile(
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
          subtitle: _buildSubtitle(theme),
          trailing: _buildTrailing(theme),
        ),
        if (_hasSubtitles) _buildSubtitleList(theme),
      ],
    );
  }

  bool get _hasSubtitles => episode.subtitles.isNotEmpty || (stagedFile?.subtitlePaths.isNotEmpty ?? false);

  Widget _buildSubtitleList(ThemeData theme) {
    final paths = stagedFile?.subtitlePaths ?? episode.subtitles.map((s) => s.path).toList();
    return Padding(
      padding: const EdgeInsets.only(left: 72.0, right: 16.0, bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.subtitles, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatSubtitleList(paths),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSubtitleList(List<String> paths) {
    if (paths.isEmpty) return '';
    final names = paths.map((p) => p.split('/').last).toList();
    if (names.length <= 1) return names.first;
    return '${names.first} +${names.length - 1}';
  }

  Widget _buildSubtitleColumn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle(theme)!,
        if (_hasSubtitles) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.subtitles, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _formatSubtitleList(stagedFile?.subtitlePaths ?? episode.subtitles.map((s) => s.path).toList()),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
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
          color: episode.hasFile || stagedFile != null
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (episode.hasFile || stagedFile != null)
          IconButton(
            icon: const Icon(Icons.subtitles_outlined, size: 20),
            onPressed: onAddSubtitles,
            tooltip: 'Add Subtitles',
          ),
        IconButton(
          icon: Icon(stagedFile != null
              ? Icons.close
              : (episode.hasFile ? Icons.swap_horiz : Icons.add_circle_outline)),
          color: (episode.hasFile || stagedFile != null)
              ? (stagedFile != null ? theme.colorScheme.error : theme.colorScheme.primary)
              : null,
          onPressed: stagedFile != null ? onRemoveFile : onImport,
          tooltip: stagedFile != null
              ? 'Remove selected file'
              : (episode.hasFile ? 'Replace File' : 'Import File'),
        ),
      ],
    );
  }
}
