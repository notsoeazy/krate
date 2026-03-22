import 'package:flutter/material.dart';

class FilePickerTile extends StatelessWidget {
  final String? selectedFilePath;
  final List<String> subtitlePaths;
  final VoidCallback onPickFiles; // Renamed for clarity: handles media (+ optional subs)
  final VoidCallback onPickSubtitles; // Keeping for adding more subtitles later
  final VoidCallback onClear;

  const FilePickerTile({
    super.key,
    required this.selectedFilePath,
    this.subtitlePaths = const [],
    required this.onPickFiles,
    required this.onPickSubtitles,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = selectedFilePath != null;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Source File'),
              subtitle: Text(
                hasFile ? selectedFilePath!.split('/').last : 'Not selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: const Icon(Icons.movie_outlined),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasFile) ...[
                    IconButton(
                      icon: const Icon(Icons.subtitles_outlined),
                      tooltip: 'Add Subtitles',
                      onPressed: onPickSubtitles,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Remove Media',
                      onPressed: onClear,
                    ),
                  ] else
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Select Media & Subtitles',
                      onPressed: onPickFiles,
                    ),
                ],
              ),
            ),
            if (hasFile && subtitlePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.subtitles,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatSubtitleList(subtitlePaths),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatSubtitleList(List<String> paths) {
    if (paths.isEmpty) return 'No subtitles selected';
    final names = paths.map((p) => p.split('/').last).toList();
    if (names.length <= 1) return names.first;
    return '${names.first} +${names.length - 1}';
  }
}
