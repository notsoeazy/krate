import 'package:flutter/material.dart';

import '../services/api/tmdb_service.dart';

class TMDBTestWidget extends StatefulWidget {
  const TMDBTestWidget({Key? key}) : super(key: key);

  @override
  State<TMDBTestWidget> createState() => _TMDBTestWidgetState();
}

class _TMDBTestWidgetState extends State<TMDBTestWidget> {
  final TMDBService _tmdbService = TMDBService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  // For expanded series: tmdbId -> {season_number: [episodes]}
  Map<int, Map<int, List<Map<String, dynamic>>>> _seriesEpisodes = {};
  Set<int> _expandedSeries = {};
  bool _searching = false;
  String _selectedType = 'multi'; // multi, movie, or tv

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;
    setState(() {
      _searching = true;
      _searchResults = [];
    });
    List<Map<String, dynamic>> results;
    if (_selectedType == 'movie') {
      results = await _tmdbService.searchMovies(_searchController.text);
    } else if (_selectedType == 'tv') {
      results = await _tmdbService.searchSeries(_searchController.text);
    } else {
      results = await _tmdbService.searchMulti(_searchController.text);
      // Filter out 'person' results, keep only movie and tv
      results = results.where((item) => item['media_type'] == 'movie' || item['media_type'] == 'tv').toList();
    }
    setState(() {
      _searchResults = results;
      _searching = false;
      _seriesEpisodes.clear();
      _expandedSeries.clear();
    });
  }

  Future<void> _toggleExpandSeries(int tmdbId) async {
    if (_expandedSeries.contains(tmdbId)) {
      setState(() {
        _expandedSeries.remove(tmdbId);
      });
      return;
    }
    if (_seriesEpisodes.containsKey(tmdbId)) {
      setState(() {
        _expandedSeries.add(tmdbId);
      });
      return;
    }
    // Fetch seasons/episodes from TMDB
    final details = await _tmdbService.getSeriesDetails(tmdbId);
    final int numSeasons = details['number_of_seasons'] ?? 0;
    Map<int, List<Map<String, dynamic>>> seasonMap = {};
    for (int season = 1; season <= numSeasons; season++) {
      final seasonDetails = await _tmdbService.getSeasonDetails(tmdbId, season);
      final episodes = (seasonDetails['episodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      seasonMap[season] = episodes;
    }
    setState(() {
      _seriesEpisodes[tmdbId] = seasonMap;
      _expandedSeries.add(tmdbId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TMDB API Search Test')),
      body: Column(
        children: [
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
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'multi', child: Text('Multi')),
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
          if (_searching) const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  final title = item['title'] ?? item['name'] ?? '';
                  final overview = item['overview'] ?? '';
                  final posterPath = item['poster_path'];
                  final backdropPath = item['backdrop_path'];
                  final tmdbId = item['id'];
                  final releaseDate = item['release_date'] ?? item['first_air_date'] ?? '';
                  final imageBase = 'https://image.tmdb.org/t/p/w500';
                  final isSeries = (item['media_type'] == 'tv') || (_selectedType == 'tv') || (item['name'] != null && item['title'] == null);
                  final isExpanded = _expandedSeries.contains(tmdbId);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      children: [
                        ListTile(
                          leading: posterPath != null
                              ? Image.network(imageBase + posterPath, width: 60, fit: BoxFit.cover)
                              : const SizedBox(width: 60, child: Icon(Icons.image_not_supported)),
                          title: Text(title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (releaseDate.isNotEmpty) Text('Release: $releaseDate'),
                              if (overview.isNotEmpty) Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(overview, maxLines: 3, overflow: TextOverflow.ellipsis),
                              ),
                              if (backdropPath != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Image.network(imageBase + backdropPath, height: 80, fit: BoxFit.cover),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Text('TMDB: $tmdbId'),
                          onTap: isSeries
                              ? () => _toggleExpandSeries(tmdbId)
                              : null,
                        ),
                        if (isSeries && isExpanded)
                          _seriesEpisodes[tmdbId] == null
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _seriesEpisodes[tmdbId]!.entries.map((seasonEntry) {
                                      final seasonNum = seasonEntry.key;
                                      final episodes = seasonEntry.value;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Season $seasonNum', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ...episodes.map((ep) {
                                            final epTitle = ep['name'] ?? '';
                                            final epNum = ep['episode_number'] ?? '';
                                            final epDuration = ep['runtime'] ?? ep['duration'] ?? '';
                                            return Padding(
                                              padding: const EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
                                              child: Text('Ep $epNum: $epTitle${epDuration != '' ? ' (${epDuration} min)' : ''}'),
                                            );
                                          }).toList(),
                                        ],
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
