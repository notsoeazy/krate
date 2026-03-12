import 'dart:io';
import 'package:flutter/material.dart';
import 'package:krate/ui/widgets/unavailable_overlay.dart';

class RecentMediaCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? tagText;
  final String? localPosterPath;
  final Widget? progressIndicator;
  final bool isUnavailable;
  final VoidCallback onTap;

  const RecentMediaCard({
    super.key,
    required this.title,
    this.subtitle,
    this.tagText,
    this.localPosterPath,
    this.progressIndicator,
    this.isUnavailable = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Poster
                SizedBox(
                  width: 84, // Slightly wider for 2:3 ratio against 120 height approx
                  child: UnavailableOverlay(
                    isUnavailable: isUnavailable,
                    borderRadius: 0,
                    child: localPosterPath != null && File(localPosterPath!).existsSync()
                        ? Image.file(
                            File(localPosterPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          // Expanded description
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (tagText != null && tagText!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          // Metadata Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tagText!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (progressIndicator != null) ...[
                          const SizedBox(height: 12),
                          // Progress bar
                          progressIndicator!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Icon(Icons.movie, color: Colors.white54, size: 32),
      ),
    );
  }
}
