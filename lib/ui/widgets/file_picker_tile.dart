import 'package:flutter/material.dart';

class FilePickerTile extends StatelessWidget {
  final String? selectedFilePath;
  final VoidCallback onTap;

  const FilePickerTile({
    super.key,
    required this.selectedFilePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Source File'),
        subtitle: Text(
          selectedFilePath?.split('/').last ?? 'Not selected',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const Icon(Icons.file_open_outlined),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
