import 'package:flutter/material.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/managed_episode_tile.dart';

class MediaManagementMovieList extends StatelessWidget {
  final Episode movieEp;
  final MediaManagementState state;
  final MediaManagementNotifier notifier;

  const MediaManagementMovieList({
    super.key,
    required this.movieEp,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ManagedEpisodeTile(
          episode: movieEp,
          mode: state.isDeleteMode
              ? ManagedTileMode.delete
              : ManagedTileMode.normal,
          isSelected: state.deleteSelections.contains(movieEp.id),
          onSelectedChanged: (val) => notifier.toggleDeleteSelection(
            movieEp.id!,
            selected: val == true,
          ),
          stagedFile: state.stagedFiles[movieEp.id],
          onImport: () => notifier.pickFile(
            episodeId: movieEp.id!,
            episodeHasFile: movieEp.hasFile,
          ),
          onRemoveFile: () => notifier.removeStaged(movieEp.id!),
        ),
      ],
    );
  }
}
