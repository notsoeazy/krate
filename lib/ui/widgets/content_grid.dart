import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/library/media_details_screen.dart';
import 'package:krate/ui/widgets/media_card.dart';
import 'package:krate/ui/widgets/empty_state_view.dart';
import 'package:krate/utils/constants.dart';

class ContentGrid extends ConsumerWidget {
  final ContentType type;
  final String query;
  final Future<void> Function() onRefresh;
  final bool showType;

  const ContentGrid({
    super.key,
    required this.type,
    required this.query,
    required this.onRefresh,
    this.showType = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = type == ContentType.movie
        ? moviesProvider
        : seriesProvider;
    final asyncItems = ref.watch(provider);

    return asyncItems.when(
      data: (items) {
        final filtered = items
            .where(
              (i) =>
                  query.isEmpty ||
                  i.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

        if (filtered.isEmpty) {
          // Empty state is also pull-to-refresh-able
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: EmptyStateView(
                    icon: Icons.movie_filter_outlined,
                    message: query.isEmpty
                        ? 'Your vault is empty'
                        : 'No matches found',
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2 / 4.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return MediaCard(
                content: filtered[index],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        MediaDetailsScreen(contentId: filtered[index].id!),
                  ),
                ),
                showType: showType,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
