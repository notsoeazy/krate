import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/import/media_details_import_screen.dart';

class SearchImportScreen extends ConsumerStatefulWidget {
  const SearchImportScreen({super.key});

  @override
  ConsumerState<SearchImportScreen> createState() => _SearchImportScreenState();
}

class _SearchImportScreenState extends ConsumerState<SearchImportScreen> {
  final SearchController _searchController = SearchController();
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _isOffline = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _isOffline = false;
      _hasSearched = true;
    });
    try {
      final results = await ref.read(tmdbServiceProvider).searchMulti(query);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        final isOffline =
            e.toString().toLowerCase().contains('socket') ||
            e.toString().toLowerCase().contains('network') ||
            e.toString().toLowerCase().contains('connection');
        if (isOffline) {
          setState(() => _isOffline = true);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Content')),
      body: Column(
        children: [
          // M3 SearchBar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search movies or series…',
              leading: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              trailing: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _onSearch(_searchController.text),
                ),
              ],
              onSubmitted: _onSearch,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // ── States ────────────────────────────────────────────────────
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator())),

          if (!_isLoading && _isOffline)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_outlined,
                      size: 64,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No internet connection',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Searching requires an internet connection.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          if (!_isLoading && !_isOffline && _results.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  _hasSearched
                      ? 'No results found'
                      : 'Search TMDB for movies or TV series',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),

          // ── Results ───────────────────────────────────────────────────
          if (!_isLoading && !_isOffline && _results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];
                  final title = item['title'] ?? item['name'] ?? 'Unknown';
                  final type = item['media_type'] == 'tv' ? 'Series' : 'Movie';
                  final year =
                      (item['release_date'] ?? item['first_air_date'] ?? '')
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
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
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
                            type: isSeries
                                ? ContentType.series
                                : ContentType.movie,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
