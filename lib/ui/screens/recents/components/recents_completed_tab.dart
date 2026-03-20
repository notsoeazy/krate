import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/content_grid.dart';

class RecentsCompletedTab extends ConsumerWidget {
  const RecentsCompletedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(completedContentProvider);

    return ContentGrid(
      asyncData: completedAsync,
      emptyMessage: 'No completed movies or series',
      emptyIcon: Icons.task_alt,
      onRefresh: () async => ref.invalidate(completedContentProvider),
    );
  }
}
