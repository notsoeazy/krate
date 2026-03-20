import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/ui/screens/media_details/media_details_screen.dart';
import 'package:krate/ui/widgets/media_card.dart';
import 'package:krate/ui/widgets/empty_state_view.dart';

class ContentGrid extends ConsumerWidget {
  final AsyncValue<List<Content>> asyncData;
  final String query;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showType;

  const ContentGrid({
    super.key,
    required this.asyncData,
    required this.onRefresh,
    required this.emptyMessage,
    required this.emptyIcon,
    this.query = '',
    this.showType = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: asyncData.when(
        data: (items) {
          final filtered = items
              .where(
                (i) =>
                    query.isEmpty ||
                    i.title.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

          if (filtered.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: EmptyStateView(
                    icon: emptyIcon,
                    message: query.isEmpty ? emptyMessage : 'No matches found',
                  ),
                ),
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
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final content = filtered[index];
              return MediaCard(
                content: content,
                width: double.infinity,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        MediaDetailsScreen(contentId: content.id!),
                  ),
                ),
                showType: showType,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [Center(child: Text('Error: $e'))],
        ),
      ),
    );
  }
}
