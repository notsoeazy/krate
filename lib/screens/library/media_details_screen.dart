import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/models/app/episode.dart';
import 'package:krate/repositories/episode_repository.dart';
import 'package:krate/services/import_service.dart';
import 'package:krate/screens/player/player_screen.dart';
import 'package:krate/screens/import/series_episode_picker_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:krate/constants.dart';
import 'package:krate/services/api/tmdb_service.dart';
import 'package:krate/models/api/episode_api.dart';

class MediaDetailsScreen extends StatefulWidget {
  final Content content;

  const MediaDetailsScreen({super.key, required this.content});

  @override
  State<MediaDetailsScreen> createState() => _MediaDetailsScreenState();
}

class _MediaDetailsScreenState extends State<MediaDetailsScreen> {
  int _selectedSeason = 1;
  List<Episode> _episodes = [];
  bool _isLoadingEpisodes = false;
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    if (widget.content.contentType != ContentType.movie) {
      _loadEpisodes();
    }
  }

  Future<void> _loadEpisodes() async {
    setState(() => _isLoadingEpisodes = true);
    final repo = context.read<EpisodeRepository>();
    final tmdb = context.read<TMDBService>();

    // 1. Load imported episodes from DB
    final imported = await repo.getEpisodesBySeason(
      widget.content.id!,
      _selectedSeason,
    );

    // 2. Try to fetch FULL season details from TMDB to show "missing" episodes
    List<Episode> fullList = [];
    try {
      if (widget.content.tmdbId != null) {
        final seasonData = await tmdb.getSeasonDetails(
          widget.content.tmdbId!,
          _selectedSeason,
        );
        final episodeMaps = seasonData['episodes'] as List? ?? [];
        final tmdbEpisodes = episodeMaps
            .map((e) => EpisodeApi.fromMap(e as Map<String, dynamic>))
            .toList();

        final importedMap = {for (var e in imported) e.episodeNumber: e};

        for (var apiEp in tmdbEpisodes) {
          final existing = importedMap[apiEp.episodeNumber];
          if (existing != null) {
            fullList.add(existing);
          } else {
            // Create a "Ghost" episode (not in DB)
            fullList.add(Episode.fromApi(apiEp, widget.content.id!));
          }
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch season details from TMDB: $e");
      // Fallback to just what we have in DB if TMDB fails
      fullList = imported;
    }

    if (mounted) {
      setState(() {
        _episodes = fullList;
        _isLoadingEpisodes = false;
      });
    }
  }

  Future<void> _deleteContent() async {
    bool deleteFiles = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Delete Media?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "This will permanently remove '${widget.content.title}' from your library.",
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text("Delete media files from disk"),
                value: deleteFiles,
                activeColor: Colors.red,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  if (val != null) setDialogState(() => deleteFiles = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("DELETE", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final importService = context.read<ImportService>();
      await importService.deleteContent(
        widget.content,
        deleteFiles: deleteFiles,
      );
      if (mounted) {
        Navigator.of(context).pop(); // Back to Library
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "'${widget.content.title}' deleted${deleteFiles ? ' (including files)' : ''}.",
            ),
          ),
        );
      }
    }
  }

  Future<void> _editMovieFile() async {
    if (_isPickingFile) return;

    final importService = context.read<ImportService>();
    if (importService.isImporting) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An import is already in progress.")),
        );
      }
      return;
    }

    setState(() => _isPickingFile = true);

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'webm'],
        dialogTitle: "Change Video File",
      );
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }

    if (result != null && result.files.single.path != null && mounted) {
      final importService = context.read<ImportService>();
      final episodeRepo = context.read<EpisodeRepository>();

      // Since it's a movie, it has exactly one episode record
      final episodes = await episodeRepo.getEpisodesByContentId(
        widget.content.id!,
      );
      if (episodes.isEmpty) return;

      try {
        // We reuse the existing import logic to move the file to the correct place
        // However, importMovie normally creates a NEW content record.
        // We should probably add a dedicated re-import or update file method to ImportService.
        // For now, let's just do it here or add it to ImportService.
        // I'll add an updateMovieFile to ImportService to be cleaner.
        await importService.updateMovieFile(
          widget.content,
          result.files.single.path!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Movie file updated successfully.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to update file: $e")));
        }
      }
    }
  }

  void _importMoreEpisodes() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                SeriesEpisodePickerScreen(content: widget.content),
          ),
        )
        .then((_) => _loadEpisodes()); // Refresh list when coming back
  }

  Future<void> _manageEpisodes() async {
    final List<Episode> selectedEpisodes = [];
    bool deleteFiles = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final importedEpisodes = _episodes
              .where((e) => e.videoPath != null)
              .toList();

          return AlertDialog(
            title: const Text("Manage Episodes"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selected episodes will be removed from your Krate library.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Uncheck 'Delete media files' if you only want to remove the database entry.",
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 16),
                  if (importedEpisodes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(child: Text("No imported episodes found.")),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: importedEpisodes.length,
                        itemBuilder: (context, index) {
                          final ep = importedEpisodes[index];
                          final isSelected = selectedEpisodes.contains(ep);
                          return CheckboxListTile(
                            title: Text(
                              "S${ep.seasonNumber}E${ep.episodeNumber}: ${ep.title ?? 'Episode'}",
                            ),
                            subtitle: Text(
                              ep.videoPath?.split('/').last ?? '',
                              maxLines: 1,
                            ),
                            value: isSelected,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedEpisodes.add(ep);
                                } else {
                                  selectedEpisodes.remove(ep);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const Divider(),
                  CheckboxListTile(
                    title: const Text(
                      "Permanently delete media files from disk",
                    ),
                    subtitle: const Text("This action cannot be undone"),
                    value: deleteFiles,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => deleteFiles = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              TextButton(
                onPressed: selectedEpisodes.isEmpty
                    ? null
                    : () async {
                        final importService = context.read<ImportService>();
                        await importService.deleteEpisodes(
                          widget.content,
                          selectedEpisodes,
                          deleteFiles: deleteFiles,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadEpisodes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${selectedEpisodes.length} episodes removed${deleteFiles ? ' and deleted from disk' : ''}.",
                              ),
                            ),
                          );
                        }
                      },
                child: const Text(
                  "REMOVE SELECTED",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMovie = widget.content.contentType == ContentType.movie;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'delete') {
                    _deleteContent();
                  } else if (value == 'edit_file') {
                    _editMovieFile();
                  } else if (value == 'import_episodes') {
                    _importMoreEpisodes();
                  } else if (value == 'manage_episodes') {
                    _manageEpisodes();
                  }
                },
                itemBuilder: (context) => [
                  if (isMovie)
                    const PopupMenuItem(
                      value: 'edit_file',
                      child: ListTile(
                        leading: Icon(Icons.edit_note),
                        title: Text("Change File"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (!isMovie) ...[
                    const PopupMenuItem(
                      value: 'import_episodes',
                      child: ListTile(
                        leading: Icon(Icons.add_to_photos_outlined),
                        title: Text("Import/Edit Episodes"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'manage_episodes',
                      child: ListTile(
                        leading: Icon(Icons.edit_calendar_outlined),
                        title: Text("Manage Episodes"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        "Delete Media",
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildBackdrop()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.content.title,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.content.tagline != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  widget.content.tagline!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.content.voteAverage > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.content.voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (widget.content.releaseDate != null)
                        _buildChip(widget.content.releaseDate!.year.toString()),
                      if (widget.content.runtime != null)
                        _buildChip("${widget.content.runtime} min"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text("Overview", style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    widget.content.description ?? "No overview available.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.8,
                      ),
                    ),
                  ),

                  if (!isMovie) ...[
                    const SizedBox(height: 32),
                    _buildSeasonSelector(),
                    const SizedBox(height: 16),
                    _buildEpisodeList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMovie ? _buildMoviePlayButton() : null,
    );
  }

  Widget _buildBackdrop() {
    if (widget.content.localBackdropPath != null &&
        File(widget.content.localBackdropPath!).existsSync()) {
      return Image.file(
        File(widget.content.localBackdropPath!),
        fit: BoxFit.cover,
      );
    }
    if (widget.content.backdropPath != null) {
      return CachedNetworkImage(
        imageUrl:
            "https://image.tmdb.org/t/p/w780${widget.content.backdropPath}",
        fit: BoxFit.cover,
      );
    }
    return Container(color: Colors.white10);
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildMoviePlayButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton.icon(
          onPressed: () async {
            if (!widget.content.hasFile) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Media file is missing from your library."),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            final repo = context.read<EpisodeRepository>();
            final episodes = await repo.getEpisodesByContentId(
              widget.content.id!,
            );
            if (episodes.isNotEmpty && mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    episode: episodes.first,
                    contentId: widget.content.id!,
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 32),
          label: const Text("PLAY MOVIE"),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonSelector() {
    return Row(
      children: [
        Text("Episodes", style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        DropdownButton<int>(
          value: _selectedSeason,
          underline: const SizedBox(),
          items: List.generate(
            widget.content.totalSeasons,
            (i) =>
                DropdownMenuItem(value: i + 1, child: Text("Season ${i + 1}")),
          ),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedSeason = val);
              _loadEpisodes();
            }
          },
        ),
      ],
    );
  }

  Widget _buildEpisodeList() {
    if (_isLoadingEpisodes) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _episodes.length,
      itemBuilder: (context, index) {
        final ep = _episodes[index];
        final hasFile = ep.videoPath != null;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "${ep.episodeNumber}. ${ep.title ?? 'Episode ${ep.episodeNumber}'}",
          ),
          subtitle: Text(
            ep.description ?? "No description.",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
          trailing: hasFile
              ? IconButton(
                  icon: const Icon(Icons.play_circle_fill, size: 32),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          episode: ep,
                          contentId: widget.content.id!,
                        ),
                      ),
                    );
                  },
                )
              : Icon(
                  Icons.cloud_off_outlined,
                  color: Theme.of(
                    context,
                  ).iconTheme.color?.withValues(alpha: 0.2),
                ),
        );
      },
    );
  }
}
