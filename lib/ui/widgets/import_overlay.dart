import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/import_job.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/import/search_import_screen.dart';

/// Root overlay widget that wraps the main shell body.
class ImportOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const ImportOverlay({super.key, required this.child});

  @override
  ConsumerState<ImportOverlay> createState() => _ImportOverlayState();
}

class _ImportOverlayState extends ConsumerState<ImportOverlay> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(importJobsProvider);
    final activeCount = ref.read(importJobsProvider.notifier).activeCount;
    final hasJobs = jobs.isNotEmpty;

    return Stack(
      children: [
        widget.child,

        // Scrim when panel is expanded
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = false),
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.scrim.withValues(alpha: 0.54),
              ),
            ),
          ),

        // FAB + job panel at bottom-right
        Positioned(
          bottom: 16,
          right: 16,
          left: _isExpanded ? 16 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isExpanded) _buildJobPanel(context, jobs),
              const SizedBox(height: 12),
              _buildFAB(context, activeCount, hasJobs),
            ],
          ),
        ),
      ],
    );
  }

  // FAB

  Widget _buildFAB(BuildContext context, int activeCount, bool hasJobs) {
    if (_isExpanded) return const SizedBox.shrink();

    // Active import in progress (Spinner)
    if (activeCount > 0) {
      return FloatingActionButton.extended(
        onPressed: () => setState(() => _isExpanded = true),
        icon: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        label: Text('$activeCount importing…'),
      );
    }

    // Default FAB
    return FloatingActionButton.extended(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SearchImportScreen()),
      ),
      icon: const Icon(Icons.add),
      label: const Text('Import'),
    );
  }

  // Job Panel

  Widget _buildJobPanel(BuildContext context, List<ImportJob> jobs) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Imports', style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _isExpanded = false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Job list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: jobs.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) =>
                    _buildJobTile(context, jobs[index], theme),
              ),
            ),

            // Clear finished button
            if (jobs.any((j) => !j.isActive))
              TextButton(
                onPressed: () =>
                    ref.read(importJobsProvider.notifier).dismissCompleted(),
                child: const Text('Clear finished'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTile(BuildContext context, ImportJob job, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Media Type Icon
              Icon(
                job.contentType == ContentType.series
                    ? Icons.tv
                    : Icons.movie_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusIcon(job: job),
            ],
          ),
          const SizedBox(height: 4),
          Text(job.currentStep ?? '', style: theme.textTheme.labelSmall),
          if (job.isActive) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: null,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
          if (job.hasFailed) ...[
            const SizedBox(height: 4),
            Text(
              job.error ?? 'Unknown error',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Import Toast

/// Top-of-screen notification chip shown when a job completes or fails.
class ImportToast extends ConsumerStatefulWidget {
  final VoidCallback onExpand;

  const ImportToast({super.key, required this.onExpand});

  @override
  ConsumerState<ImportToast> createState() => _ImportToastState();
}

class _ImportToastState extends ConsumerState<ImportToast> {
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) ref.read(importToastProvider.notifier).dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(importToastProvider);
    if (job == null) return const SizedBox.shrink();

    _startTimer();

    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          tween: Tween(begin: -100.0, end: 0.0),
          builder: (context, offset, child) =>
              Transform.translate(offset: Offset(0, offset), child: child),
          child: GestureDetector(
            onTap: () {
              ref.read(importToastProvider.notifier).dismiss();
              widget.onExpand();
            },
            // Toast Box
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _StatusIcon(job: job),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            job.status == ImportJobStatus.done
                                ? 'Import complete'
                                : job.status == ImportJobStatus.error
                                ? 'Import failed'
                                : job.currentStep ?? 'Importing…',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: job.status == ImportJobStatus.error
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () =>
                          ref.read(importToastProvider.notifier).dismiss(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Status Icon

class _StatusIcon extends StatelessWidget {
  final ImportJob job;

  const _StatusIcon({required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Done Status
    if (job.status == ImportJobStatus.done) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: theme.colorScheme.tertiaryContainer,
        child: Icon(
          Icons.check,
          color: theme.colorScheme.onTertiaryContainer,
          size: 14,
        ),
      );
    }

    // Error Status
    if (job.status == ImportJobStatus.error) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.priority_high,
          color: theme.colorScheme.onErrorContainer,
          size: 14,
        ),
      );
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        value: job.progress > 0 ? job.progress : null,
      ),
    );
  }
}
