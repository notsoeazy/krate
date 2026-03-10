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
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _isOffline = false;
  bool _hasSearched = false;

  void _onSearch() async {
    if (_controller.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _isOffline = false;
      _hasSearched = true;
    });
    try {
      final results = await ref
          .read(tmdbServiceProvider)
          .searchMulti(_controller.text);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        // Check if it's a connectivity issue
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Content')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _onSearch(),
              decoration: InputDecoration(
                hintText: 'Search movies or series...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _onSearch,
                ),
              ),
            ),
          ),
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
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No internet connection',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Searching requires an internet connection.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
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
                    leading: item['poster_path'] != null
                        ? Image.network(
                            '$kTmdbImageBase/w92${item['poster_path']}',
                            width: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.movie_outlined, size: 50),
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
