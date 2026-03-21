import 'package:flutter/material.dart';
import 'package:krate/utils/constants.dart';

class MediaDetailsMoreMenu extends StatelessWidget {
  final ContentType contentType;
  final VoidCallback onManage;
  final VoidCallback onVaultSync;
  final VoidCallback onFetchMetadata;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onMarkSeasons;
  final VoidCallback onMarkFinished;
  final VoidCallback onClearSeriesProgress;

  const MediaDetailsMoreMenu({
    super.key,
    required this.contentType,
    required this.onManage,
    required this.onVaultSync,
    required this.onFetchMetadata,
    required this.onEnterSelectionMode,
    required this.onMarkSeasons,
    required this.onMarkFinished,
    required this.onClearSeriesProgress,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      menuChildren: [
        if (contentType == ContentType.series)
          MenuItemButton(
            leadingIcon: const Icon(Icons.playlist_add_check_rounded),
            onPressed: onEnterSelectionMode,
            style: MenuItemButton.styleFrom(minimumSize: const Size(260, 48)),
            child: const Text('Mark episodes as watched'),
          ),
        if (contentType == ContentType.series)
          MenuItemButton(
            leadingIcon: const Icon(Icons.done_all_rounded),
            onPressed: onMarkSeasons,
            style: MenuItemButton.styleFrom(minimumSize: const Size(260, 48)),
            child: const Text('Mark seasons as watched'),
          ),
        if (contentType == ContentType.movie)
          MenuItemButton(
            leadingIcon: const Icon(Icons.done_all_rounded),
            onPressed: onMarkFinished,
            style: MenuItemButton.styleFrom(minimumSize: const Size(260, 48)),
            child: const Text('Mark as watched'),
          ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.sync_outlined),
          onPressed: onVaultSync,
          style: MenuItemButton.styleFrom(minimumSize: const Size(260, 48)),
          child: const Text('Vault Sync'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.refresh_outlined),
          onPressed: onFetchMetadata,
          style: MenuItemButton.styleFrom(minimumSize: const Size(260, 48)),
          child: const Text('Fetch Metadata'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.video_library_outlined),
          onPressed: onManage,
          style: MenuItemButton.styleFrom(minimumSize: const Size(260, 48)),
          child: const Text('Manage Media'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.history_rounded),
          onPressed: onClearSeriesProgress,
          style: MenuItemButton.styleFrom(minimumSize: const Size(260, 48)),
          child: const Text('Clear watch history'),
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }
}
