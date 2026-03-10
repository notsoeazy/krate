import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/import_job.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/import/search_import_screen.dart';

class ImportOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const ImportOverlay({super.key, required this.child});

  @override
  ConsumerState<ImportOverlay> createState() => _ImportOverlayState();
}

class _ImportOverlayState extends ConsumerState<ImportOverlay> {
  bool _isExpanded = false;

  void setExpanded(bool value) {
    setState(() {
      _isExpanded = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(importJobsProvider);
    final activeCount = ref.read(importJobsProvider.notifier).activeCount;
    final hasJobs = jobs.isNotEmpty;

    return Stack(
      children: [
        // The main app content
        widget.child,

        // Dimmer background when expanded
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = false),
              child: Container(color: Colors.black54),
            ),
          ),

        // Toast at the top
        ImportToast(onExpand: () => setState(() => _isExpanded = true)),

        // Floating UI at the bottom
        Positioned(
          bottom: 16,
          right: 16,
          left: _isExpanded ? 16 : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Job List Panel (visible when expanded)
              if (_isExpanded) _buildJobPanel(context, jobs),

              const SizedBox(height: 12),

              // FAB / Progress Toggle
              _buildFAB(context, activeCount, hasJobs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAB(BuildContext context, int activeCount, bool hasJobs) {
    final theme = Theme.of(context);

    if (activeCount > 0 && !_isExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$activeCount importing...',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isExpanded) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SearchImportScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Import'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildJobPanel(BuildContext context, List<ImportJob> jobs) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Imports', style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _isExpanded = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: jobs.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _buildJobTile(context, job);
              },
            ),
          ),
          if (jobs.any((j) => !j.isActive))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextButton(
                onPressed: () =>
                    ref.read(importJobsProvider.notifier).dismissCompleted(),
                child: const Text('Clear finished'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobTile(BuildContext context, ImportJob job) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              _buildStatusIcon(job, theme),
            ],
          ),
          const SizedBox(height: 4),
          Text(job.currentStep ?? '', style: theme.textTheme.labelSmall),
          if (job.isActive) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: job.progress,
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

  Widget _buildStatusIcon(ImportJob job, ThemeData theme) {
    if (job.status == ImportJobStatus.done) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 16);
    }
    if (job.status == ImportJobStatus.error) {
      return Icon(Icons.error, color: theme.colorScheme.error, size: 16);
    }
    return const SizedBox.shrink();
  }
}

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
      if (mounted) {
        ref.read(importToastProvider.notifier).dismiss();
      }
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
          builder: (context, offset, child) {
            return Transform.translate(offset: Offset(0, offset), child: child);
          },
          child: GestureDetector(
            onTap: () {
              ref.read(importToastProvider.notifier).dismiss();
              widget.onExpand();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                              : job.currentStep ?? 'Importing...',
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
                    onPressed: () {
                      ref.read(importToastProvider.notifier).dismiss();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final ImportJob job;

  const _StatusIcon({required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (job.status == ImportJobStatus.done) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
    }

    if (job.status == ImportJobStatus.error) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.priority_high, color: Colors.white, size: 16),
      );
    }

    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        value: job.progress > 0 ? job.progress : null,
      ),
    );
  }
}
