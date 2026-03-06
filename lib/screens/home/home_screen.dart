import 'package:flutter/material.dart';
import 'package:krate/repositories/episode_repository.dart';
import 'package:krate/screens/library/media_details_screen.dart';
import 'package:krate/screens/player/player_screen.dart';
import 'package:provider/provider.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/repositories/content_repository.dart';
import 'package:krate/repositories/watch_progress_repository.dart';
import 'package:krate/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Content> _continueWatching = [];
  List<Content> _recentlyAdded = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final contentRepo = context.read<ContentRepository>();
      final wpRepo = context.read<WatchProgressRepository>();

      final results = await Future.wait([
        wpRepo.getInProgressContent(limit: 10),
        contentRepo.getRecentlyAdded(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _continueWatching = results[0];
          _recentlyAdded = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Krate"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            if (_continueWatching.isNotEmpty)
              HorizontalMediaRow(
                title: "Continue Watching",
                items: _continueWatching,
                onItemSelected: (content) async {
                  final episodeRepo = context.read<EpisodeRepository>();
                  final wpRepo = context.read<WatchProgressRepository>();

                  // In getInProgressContent(), we should have received content with progress info
                  // But our current JOIN query returns a List<Content>.
                  // Let's fetch the most recent progress for this content to get the episodeId.
                  final progress = await wpRepo.getInProgress(limit: 50);
                  final latestForContent = progress.firstWhere(
                    (p) => p['contentId'] == content.id,
                    orElse: () => {},
                  );

                  if (latestForContent.isEmpty) return;

                  final episode = await episodeRepo.getById(
                    latestForContent['episodeId'] as int,
                  );
                  if (mounted && episode != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          episode: episode,
                          contentId: content.id!,
                        ),
                      ),
                    );
                  }
                },
              ),

            HorizontalMediaRow(
              title: "Recently Added",
              items: _recentlyAdded,
              onItemSelected: (content) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MediaDetailsScreen(content: content),
                  ),
                );
              },
            ),

            if (_continueWatching.isEmpty && _recentlyAdded.isEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.movie_creation_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your vault is empty.",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Jump to Import Tab via MainView state?
                        },
                        child: const Text("Start Importing"),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
