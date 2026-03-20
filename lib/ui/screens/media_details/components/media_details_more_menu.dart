import 'package:flutter/material.dart';

class MediaDetailsMoreMenu extends StatelessWidget {
  final VoidCallback onManage;
  final VoidCallback onVaultSync;
  final VoidCallback onFetchMetadata;

  const MediaDetailsMoreMenu({
    super.key,
    required this.onManage,
    required this.onVaultSync,
    required this.onFetchMetadata,
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
        MenuItemButton(
          leadingIcon: const Icon(Icons.video_library_outlined),
          onPressed: onManage,
          style: MenuItemButton.styleFrom(minimumSize: const Size(200, 48)),
          child: const Text('Manage Media'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.sync_outlined),
          onPressed: onVaultSync,
          style: MenuItemButton.styleFrom(minimumSize: const Size(200, 48)),
          child: const Text('Vault Sync'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.refresh_outlined),
          onPressed: onFetchMetadata,
          style: MenuItemButton.styleFrom(minimumSize: const Size(200, 48)),
          child: const Text('Fetch Metadata'),
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
