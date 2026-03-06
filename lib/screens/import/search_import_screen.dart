import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:krate/services/api/tmdb_service.dart';
import 'package:krate/services/api/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krate/screens/import/media_details_import_screen.dart';
import 'package:krate/screens/library/media_details_screen.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/repositories/content_repository.dart';

class SearchImportScreen extends StatefulWidget {
  const SearchImportScreen({super.key});

  @override
  State<SearchImportScreen> createState() => _SearchImportScreenState();
}

class _SearchImportScreenState extends State<SearchImportScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tmdb = context.read<TMDBService>();
      final results = await tmdb.searchMulti(query);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } on KrateNetworkException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "An unexpected error occurred: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Import Media")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Movies or TV Series...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _results = []);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 64,
                        color: theme.colorScheme.error.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _performSearch(_searchController.text),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Try Again"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_isLoading &&
              _results.isEmpty &&
              _searchController.text.isNotEmpty)
            const Expanded(child: Center(child: Text("No results found."))),
          if (!_isLoading && _results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final isMovie = result['media_type'] == 'movie';
                  final title = result[isMovie ? 'title' : 'name'] ?? 'Unknown';
                  final date =
                      result[isMovie ? 'release_date' : 'first_air_date'];
                  final year = (date != null && date.toString().isNotEmpty)
                      ? DateTime.tryParse(date)?.year.toString()
                      : null;
                  final posterPath = result['poster_path'];
                  final tmdbId = result['id'];

                  return FutureBuilder<Content?>(
                    future: context
                        .read<ContentRepository>()
                        .getContentByTmdbId(tmdbId),
                    builder: (context, snapshot) {
                      final existingContent = snapshot.data;
                      final isImported = existingContent != null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isImported
                              ? BorderSide(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.5,
                                  ),
                                )
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          onTap: () {
                            if (isImported) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => MediaDetailsScreen(
                                    content: existingContent,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MediaDetailsImportScreen(
                                        tmdbId: tmdbId,
                                        type: result['media_type'],
                                      ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              // Poster Image
                              SizedBox(
                                width: 80,
                                height: 120,
                                child: posterPath != null
                                    ? CachedNetworkImage(
                                        imageUrl:
                                            "https://image.tmdb.org/t/p/w200$posterPath",
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(color: Colors.white10),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.broken_image),
                                      )
                                    : Container(
                                        color: Colors.white10,
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMovie
                                                  ? Colors.blue.withOpacity(0.2)
                                                  : Colors.orange.withOpacity(
                                                      0.2,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isMovie ? "MOVIE" : "SERIES",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isMovie
                                                    ? Colors.blue[300]
                                                    : Colors.orange[300],
                                              ),
                                            ),
                                          ),
                                          if (isImported) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.green
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check,
                                                    size: 10,
                                                    color: Colors.green,
                                                  ),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    "IN LIBRARY",
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          if (year != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              year,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color
                                                        ?.withOpacity(0.6),
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        result['overview'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
