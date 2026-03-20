import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/ui/widgets/media_info_row.dart';
import 'package:krate/ui/widgets/media_overview_section.dart';

class MediaImportPreview extends StatelessWidget {
  final Content content;
  final ContentType type;

  const MediaImportPreview({
    super.key,
    required this.content,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MediaInfoRow(content: content, typeOverride: type),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.all(8),
          child: MediaOverviewSection(content: content),
        ),
      ],
    );
  }
}
