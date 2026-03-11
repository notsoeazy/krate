import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/ui/screens/library/media_details_screen.dart';
import 'package:krate/ui/widgets/empty_state_view.dart';
import 'package:krate/ui/widgets/media_card.dart';

class RecentsContentGrid extends StatelessWidget {
  final AsyncValue<List<Content>> asyncData;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;

  const RecentsContentGrid({
    super.key,
    required this.asyncData,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: asyncData.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 200),
                EmptyStateView(icon: emptyIcon, message: emptyMessage),
              ],
            );
          }
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 2 / 4.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final content = items[index];
              return MediaCard(
                content: content,
                showType: true,
                width: double.infinity,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MediaDetailsScreen(contentId: content.id!),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [Center(child: Text('Error loading data'))],
        ),
      ),
    );
  }
}
