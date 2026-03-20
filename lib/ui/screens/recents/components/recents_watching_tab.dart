import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/content_grid.dart';

class RecentsWatchingTab extends ConsumerWidget {
  const RecentsWatchingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchingAsync = ref.watch(watchingContentProvider);

    return ContentGrid(
      asyncData: watchingAsync,
      emptyMessage: 'Nothing being watched right now',
      emptyIcon: Icons.play_circle_outline,
      onRefresh: () async => ref.invalidate(watchingContentProvider),
    );
  }
}
