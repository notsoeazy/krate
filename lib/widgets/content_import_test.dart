import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api/tmdb_service.dart';
import '../services/storage_service.dart';
import '../services/content_service.dart';
import '../services/import_service.dart';
import '../services/path_service.dart';
import '../services/file_service.dart';
import '../services/image_download_service.dart';

class ContentImportTest extends StatefulWidget {
  const ContentImportTest({Key? key}) : super(key: key);

  @override
  State<ContentImportTest> createState() => _ContentImportTestState();
}

class _ContentImportTestState extends State<ContentImportTest> {
  final TMDBService _tmdbService = TMDBService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();

  String? _rootDirectory; // selected root directory
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  String _selectedType = 'multi'; // multi, movie, or tv

  // ContentService setup
  late final PathService _pathService;
  late final FileService _fileService;
  late final ImageDownloadService _imageService;
  late final ImportService _importService;
  late final ContentService _contentService;

  @override
  void initState() {
    super.initState();
    _loadRootDirectory();

    _pathService = PathService();
    _fileService = FileService();
    _imageService = ImageDownloadService();
    _importService = ImportService(
      pathService: _pathService,
      fileService: _fileService,
      imageService: _imageService,
    );
    _contentService = ContentService(
      contentRepo: _importService.contentRepo,
      episodeRepo: _importService.episodeRepo,
      importService: _importService,
    );
  }

  Future<void> _loadRootDirectory() async {
    final path = await _storageService.getRootDirectory();
    setState(() {
      _rootDirectory = path;
    });
  }

  Future<void> _pickRootDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await _storageService.setRootDirectory(result);
      setState(() {
        _rootDirectory = result;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Root directory set: $result')));
    }
  }

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
      results = results
          .where(
            (item) =>
                item['media_type'] == 'movie' || item['media_type'] == 'tv',
          )
          .toList();
    }

    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  Future<void> _importContent(Map<String, dynamic> item) async {
    final mediaType =
        item['media_type'] ?? (_selectedType == 'tv' ? 'tv' : 'movie');
    final tmdbId = item['id'] as int;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Importing...')));

    try {
      if (mediaType == 'movie') {
        final movieData = await _tmdbService.getMovieDetails(tmdbId);
        final content =
            await _contentService.importMovieFromTMDB(movieData: movieData);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Movie "${content.title}" imported successfully!'),
        ));
      } else if (mediaType == 'tv') {
        final seriesData = await _tmdbService.getSeriesDetails(tmdbId);
        final content =
            await _contentService.importSeriesFromTMDB(seriesData: seriesData);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Series "${content.title}" imported successfully!'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TMDB API Import Test')),
      body: Column(
        children: [
          // Root directory picker
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _rootDirectory ?? 'No root directory selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickRootDirectory,
                  child: const Text('Set Root Directory'),
                ),
              ],
            ),
          ),
          // Search bar
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
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          // Search results list
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  final title = item['title'] ?? item['name'] ?? '';
                  final tmdbId = item['id'];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text('TMDB ID: $tmdbId'),
                      trailing: IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => _importContent(item),
                      ),
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