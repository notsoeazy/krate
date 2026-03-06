import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krate/services/import_service.dart';

class ImportProgressOverlay extends StatelessWidget {
  const ImportProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ImportService>(
      builder: (context, importService, _) {
        if (!importService.isImporting) return const SizedBox.shrink();

        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceVariant,
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: importService.progress > 0
                              ? importService.progress
                              : null,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Importing...",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          importService.currentTaskTitle ?? "Media",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: importService.progress,
                            minHeight: 2,
                            backgroundColor: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
