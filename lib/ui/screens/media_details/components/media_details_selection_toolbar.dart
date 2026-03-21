import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';

class MediaDetailsSelectionToolbar extends ConsumerWidget {
  final int contentId;
  final int selectedCount;

  const MediaDetailsSelectionToolbar({
    super.key,
    required this.contentId,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(watchedSelectionProvider(contentId).notifier);
    final selectionState = ref.read(watchedSelectionProvider(contentId));
    final service = ref.read(watchProgressServiceProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => notifier.exitSelectionMode(),
            child: const Text('Cancel'),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: selectedCount > 0
                ? () async {
                    await service.clearEpisodesProgress(
                      selectionState.selectedEpisodeIds.toList(),
                      contentId,
                    );
                    notifier.exitSelectionMode();
                  }
                : null,
            child: const Text('Clear selected'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: selectedCount > 0
                ? () async {
                    await service.markEpisodesFinished(
                      selectionState.selectedEpisodeIds.toList(),
                      contentId,
                    );
                    notifier.exitSelectionMode();
                  }
                : null,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: Text('Watched $selectedCount'),
          ),
        ],
      ),
    );
  }
}
