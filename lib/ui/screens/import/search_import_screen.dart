import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/providers/providers.dart';

class SearchImportScreen extends ConsumerStatefulWidget {
  const SearchImportScreen({super.key});

  @override
  ConsumerState<SearchImportScreen> createState() => _SearchImportScreenState();
}

class _SearchImportScreenState extends ConsumerState<SearchImportScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  void _onSearch() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await ref
          .read(tmdbServiceProvider)
          .searchMulti(_controller.text);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
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
          if (!_isLoading && _results.isEmpty)
            const Expanded(
              child: Center(child: Text('Search TMDB for movies or TV series')),
            ),
          if (!_isLoading && _results.isNotEmpty)
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
                      context.push(
                        '/import/details/$tmdbId?type=${isSeries ? 'series' : 'movie'}',
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
