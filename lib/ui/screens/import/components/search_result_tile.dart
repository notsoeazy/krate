import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/import/media_details_import_screen.dart';
import 'package:krate/ui/screens/media_details/media_details_screen.dart';
import 'package:krate/utils/constants.dart';

class SearchResultTile extends ConsumerWidget {
  final Map<String, dynamic> item;

  const SearchResultTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tmdbId = item['id'] as int;
    final localContentAsync = ref.watch(contentByTmdbIdProvider(tmdbId));
    final theme = Theme.of(context);
    final title = item['title'] ?? item['name'] ?? 'Unknown';
    final type = item['media_type'] == 'tv' ? 'Series' : 'Movie';
    final year = (item['release_date'] ?? item['first_air_date'] ?? '')
        .split('-')
        .first;

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: item['poster_path'] != null
            ? Image.network(
                '$kTmdbImageBase/w92${item['poster_path']}',
                width: 48,
                height: 72,
                fit: BoxFit.cover,
              )
            : SizedBox(
                width: 48,
                height: 72,
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.movie_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
      title: Text(title),
      subtitle: Row(
        children: [
          Text('$type • $year'),
          localContentAsync.when(
            data: (content) {
              if (content == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Imported',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
      onTap: () {
        final localContent = localContentAsync.valueOrNull;
        if (localContent != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  MediaDetailsScreen(contentId: localContent.id!),
            ),
          );
          return;
        }

        final isSeries = item['media_type'] == 'tv';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MediaDetailsImportScreen(
              tmdbId: tmdbId,
              type: isSeries ? ContentType.series : ContentType.movie,
            ),
          ),
        );
      },
    );
  }
}
