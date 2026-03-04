import 'package:flutter/material.dart';
import '../repository/content_repository.dart';
import '../repository/episodes_repository.dart';
import '../services/api/tmdb_services.dart';
import '../models/app/content.dart';
import '../models/app/episode_local.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TMDBTestWidget extends StatefulWidget {
  const TMDBTestWidget({Key? key}) : super(key: key);

  @override
  State<TMDBTestWidget> createState() => _TMDBTestWidgetState();
}

class _TMDBTestWidgetState extends State<TMDBTestWidget> {
  final ContentRepository _contentRepo = ContentRepository();
  final EpisodesRepository _episodesRepo = EpisodesRepository();
  late final TMDBService _tmdbService;

  final TextEditingController _searchController = TextEditingController();

  List<Content> _allContent = [];
  Map<int, List<Episode>> _episodesByContent = {};

  List<dynamic> _searchResults = [];
  bool _loading = false;
  bool _searching = false;
  String _selectedType = 'movie'; // movie or tv

  @override
  void initState() {
    super.initState();
    _tmdbService = TMDBService(_contentRepo, _episodesRepo);
    _loadLocalData();
    _printDbPath();
  }

Future<void> _printDbPath() async {
    final databasesPath = await getDatabasesPath();
    final fullPath = join(databasesPath, 'app_database.db');

    print('📦 DATABASE DIRECTORY: $databasesPath');
    print('📄 FULL DATABASE PATH: $fullPath');
  }

  Future<void> _loadLocalData() async {
    final allContent = await _contentRepo.getAllContent();

    final episodesMap = <int, List<Episode>>{};
    for (var content in allContent) {
      final eps = await _episodesRepo.getEpisodesByContentId(content.id!);
      episodesMap[content.id!] = eps;
    }

    setState(() {
      _allContent = allContent;
      _episodesByContent = episodesMap;
    });
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _searching = true;
      _searchResults = [];
    });

    List<dynamic> results;

    if (_selectedType == 'movie') {
      results = await _tmdbService.searchMovies(_searchController.text);
    } else {
      results = await _tmdbService.searchSeries(_searchController.text);
    }

    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  Future<void> _saveItem(dynamic item) async {
    setState(() => _loading = true);

    if (_selectedType == 'movie') {
      await _tmdbService.fetchAndSaveMovie(item['id']);
    } else {
      await _tmdbService.fetchAndSaveSeries(item['id']);
    }

    await _loadLocalData();

    setState(() => _loading = false);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TMDB Search & Local Test')),
      body: Column(
        children: [
          // 🔎 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search TMDB...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'movie', child: Text('Movie')),
                    DropdownMenuItem(value: 'tv', child: Text('Series')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                ),
                IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ],
            ),
          ),

          if (_searching) const CircularProgressIndicator(),

          // 🔎 SEARCH RESULTS
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  final content = _searchResults[index];

                  return ListTile(
                    title: Text(content.title),
                    subtitle: Text('TMDB ID: ${content.tmdbId}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _saveItem(content),
                    ),
                  );
                },
              ),
            ),

          const Divider(),

          // 📦 LOCAL DATABASE CONTENT
          Expanded(
            child: ListView.builder(
              itemCount: _allContent.length,
              itemBuilder: (context, index) {
                final content = _allContent[index];
                final episodes = _episodesByContent[content.id!] ?? [];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(
                      '${content.title} (${content.contentType})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'TMDB: ${content.tmdbId} | Episodes: ${episodes.length}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(content.description),
                      ),
                      if (episodes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: episodes.map((ep) {
                              return Text(
                                'S${ep.seasonNumber}E${ep.episodeNumber}: ${ep.title} '
                                '(${_formatDate(ep.airDate)}) '
                                '${ep.duration != null ? '- ${ep.duration} min' : ''}',
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
