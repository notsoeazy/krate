import 'package:flutter/material.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/media_details/components/media_management_episode_tile.dart';
import 'package:krate/utils/feedback_utils.dart';

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
        MediaManagementEpisodeTile(
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
          onImport: () => notifier.pickMediaWithSubtitles(
            episodeId: movieEp.id!,
            episodeHasFile: movieEp.hasFile,
            onError: (err) => FeedbackUtils.showErrorSnackBar(context, err),
          ),
          onAddSubtitles: () => notifier.pickSubtitles(
            episodeId: movieEp.id!,
            existingVideoPath: movieEp.videoPath,
            onError: (err) => FeedbackUtils.showErrorSnackBar(context, err),
          ),
          onRemoveFile: () => notifier.removeStaged(movieEp.id!),
        ),
      ],
    );
  }
}
