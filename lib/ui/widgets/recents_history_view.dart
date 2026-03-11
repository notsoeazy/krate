import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/empty_state_view.dart';
import 'package:krate/ui/widgets/history_item_card.dart';

class RecentsHistoryView extends ConsumerWidget {
  const RecentsHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryListProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(watchHistoryListProvider),
      child: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                EmptyStateView(
                  icon: Icons.history,
                  message: 'No watch history',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return HistoryItemCard(row: items[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [Center(child: Text('Error loading history'))],
        ),
      ),
    );
  }
}
