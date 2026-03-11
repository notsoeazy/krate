import 'package:flutter/material.dart';
import 'package:krate/ui/screens/import/media_details_import_screen.dart';
import 'package:krate/utils/constants.dart';

class SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const SearchResultTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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
      subtitle: Text('$type • $year'),
      onTap: () {
        final tmdbId = item['id'];
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
