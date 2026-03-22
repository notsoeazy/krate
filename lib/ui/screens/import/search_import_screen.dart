import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/empty_state_view.dart';
import 'package:krate/ui/screens/import/components/search_result_tile.dart';
import 'package:krate/utils/errors.dart';
import 'package:krate/utils/feedback_utils.dart';

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
        debugPrint('[SearchImportScreen] Search Error: $e');
        if (e is NoInternetException) {
          setState(() => _isOffline = true);
          FeedbackUtils.showErrorSnackBar(
            context,
            'No internet connection. Cannot connect to TMDB.',
          );
        } else {
          FeedbackUtils.showErrorSnackBar(
            context,
            'Search failed',
            error: e is KrateException ? e.message : e.toString(),
          );
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
          // Searchbar
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
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
              ],
              onChanged: (_) => setState(() {}),
              onSubmitted: _onSearch,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // States
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator())),

          if (!_isLoading && _isOffline)
            const Expanded(
              child: EmptyStateView(
                icon: Icons.wifi_off_outlined,
                message: 'No internet connection',
                secondaryMessage: 'Searching requires an internet connection.',
              ),
            ),

          if (!_isLoading && !_isOffline && _results.isEmpty)
            Expanded(
              child: EmptyStateView(
                icon: _hasSearched ? Icons.search_off_outlined : Icons.search,
                message: _hasSearched
                    ? 'No results found'
                    : 'Search TMDB for movies or TV series',
              ),
            ),

          // Results
          if (!_isLoading && !_isOffline && _results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  return SearchResultTile(item: _results[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}
