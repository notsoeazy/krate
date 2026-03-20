import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';

class MediaManagementBottomBar extends StatelessWidget {
  final MediaManagementState state;
  final Content content;
  final List<Episode> episodes;
  final VoidCallback onImport;
  final VoidCallback onDelete;

  const MediaManagementBottomBar({
    super.key,
    required this.state,
    required this.content,
    required this.episodes,
    required this.onImport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.importButtonEnabled && !state.deleteButtonEnabled) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            if (state.importButtonEnabled)
              Expanded(
                child: FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.link),
                  label: Text(
                    'Import ${state.stagedFiles.length} '
                    'File${state.stagedFiles.length == 1 ? '' : 's'}',
                  ),
                ),
              ),
            if (state.deleteButtonEnabled) ...[
              if (state.importButtonEnabled) const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text('Delete ${state.deleteSelections.length}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
