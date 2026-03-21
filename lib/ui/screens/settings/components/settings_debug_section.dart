import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/import_job.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/ui/widgets/confirmation_dialog.dart';
import 'package:krate/ui/screens/media_details/components/media_details_season_selection_modal.dart';

class SettingsDebugSection extends ConsumerWidget {
  const SettingsDebugSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock series for testing season selection
    final mockSeries = Content(
      id: 999,
      title: 'Debug Series',
      contentType: ContentType.series,
      totalSeasons: 5,
      isFavorite: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      podPath: '/debug/path',
      localPosterPath: null,
      tmdbPosterPath: null,
      releaseDate: DateTime(2024),
      runtime: 45,
      description: 'Debug overview text for testing layouts.',
      fileStatus: FileStatus.ready,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ExpansionTile(
            title: const Text('SnackBars'),
            leading: const Icon(Icons.notifications_outlined),
            children: [
              ListTile(
                title: const Text('Info SnackBar'),
                dense: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This is an info message')),
                  );
                },
              ),
              ListTile(
                title: const Text('Success SnackBar'),
                dense: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Operation completed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Error SnackBar'),
                dense: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('An error occurred during the operation'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Action SnackBar'),
                dense: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Content deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ExpansionTile(
            title: const Text('Dialogs'),
            leading: const Icon(Icons.wb_iridescent_outlined),
            children: [
              ListTile(
                title: const Text('Confirm (Default)'),
                dense: true,
                onTap: () => ConfirmationDialog.show(
                  context,
                  title: 'Confirm Action',
                  message: 'Are you sure you want to proceed?',
                ),
              ),
              ListTile(
                title: const Text('Confirm (Destructive)'),
                dense: true,
                onTap: () => ConfirmationDialog.show(
                  context,
                  title: 'Delete Content?',
                  message: 'This action cannot be undone. All data will be lost.',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                ),
              ),
              ListTile(
                title: const Text('Sync Required style'),
                dense: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sync Required'),
                      content: const Text(
                        'Changes or an existing library were detected in your vault directory. Sync now?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Later'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Sync Now'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ExpansionTile(
            title: const Text('Modals'),
            leading: const Icon(Icons.layers_outlined),
            children: [
              ListTile(
                title: const Text('Season Selection Modal'),
                dense: true,
                onTap: () => MediaDetailsSeasonSelectionModal.show(context, mockSeries),
              ),
              ListTile(
                title: const Text('Quick Actions Style Modal'),
                dense: true,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    builder: (context) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Quick Actions Mock',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.favorite_outline),
                            title: const Text('Add to favorites'),
                            onTap: () => Navigator.pop(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.history_rounded),
                            title: const Text('Clear watch history'),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ExpansionTile(
            title: const Text('Global Toasts'),
            leading: const Icon(Icons.ads_click),
            children: [
              ListTile(
                title: const Text('Toggle Sync Toast'),
                subtitle: const Text('Simulates a background vault sync'),
                dense: true,
                onTap: () {
                  final isSyncing = ref.read(vaultSyncProvider).isSyncing;
                  if (isSyncing) {
                    ref.read(vaultSyncProvider.notifier).debugUpdate(isSyncing: false);
                  } else {
                    ref.read(vaultSyncProvider.notifier).debugUpdate(
                      isSyncing: true,
                      status: 'Syncing vault metadata...',
                      progress: 0.45,
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Show Import Toast (Success)'),
                dense: true,
                onTap: () {
                  ref.read(importToastProvider.notifier).show(
                    ImportJob(
                      id: 'debug-success',
                      title: 'Debug Movie Import',
                      contentType: ContentType.movie,
                      status: ImportJobStatus.done,
                      currentStep: 'Import complete!',
                      startedAt: DateTime.now(),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Show Import Toast (Error)'),
                dense: true,
                onTap: () {
                  ref.read(importToastProvider.notifier).show(
                    ImportJob(
                      id: 'debug-error',
                      title: 'Failed Series Import',
                      contentType: ContentType.series,
                      status: ImportJobStatus.error,
                      currentStep: 'Ffmpeg failed to process stream',
                      error: 'Encoding error',
                      startedAt: DateTime.now(),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Dismiss Toasts'),
                dense: true,
                onTap: () {
                  ref.read(vaultSyncProvider.notifier).debugUpdate(isSyncing: false);
                  ref.read(importToastProvider.notifier).dismiss();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
