import 'dart:io';

import 'package:krate/constants.dart';
import 'package:krate/models/api/movie_api.dart';
import 'package:krate/models/api/tv_series_api.dart';
import 'package:krate/models/api/episode_api.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/models/app/episode.dart';
import 'package:krate/repositories/content_repository.dart';
import 'package:krate/repositories/episode_repository.dart';
import 'package:krate/services/import_service.dart';
// import 'package:krate/utils/title_cleaner.dart';

class ContentService {
  final ContentRepository contentRepo;
  final EpisodeRepository episodeRepo;
  final ImportService importService;

  ContentService({
    required this.contentRepo,
    required this.episodeRepo,
    required this.importService,
  });

  /// Import a movie (local video + TMDB metadata)
  Future<Content> importMovie({
    required MovieApi api,
    required String sourceVideoPath,
  }) async {
    // final cleanTitle = TitleCleaner.clean(api.title);

    // Convert API model to app model
    Content content = Content.fromMovieApi(api);

    // Insert content to database first (status pending)
    int contentId = await contentRepo.insertContent(content);
    content = content.copyWith(id: contentId);

    // Save video locally
    final videoPath = await importService.importMovie(
      tmdbId: api.id,
      title: api.title,
      sourceVideo: File(sourceVideoPath),
      posterPath: api.posterPath ?? '',
      backdropPath: api.backdropPath ?? '',
    );

    // Update database with local video path
    content = content.copyWith(
      videoPath: videoPath,
      localPosterPath: await importService.pathService.getMoviePosterPath(
        api.id,
      ),
      localBackdropPath: await importService.pathService.getMovieBackdropPath(
        api.id,
      ),
      status: StatusType.ready,
    );
    await contentRepo.updateContent(content);

    return content;
  }

  /// Import a TV series (local episode video + TMDB metadata)
  Future<Content> importSeriesEpisode({
    required TvSeriesApi seriesApi,
    required EpisodeApi episodeApi,
    required String sourceVideoPath,
  }) async {
    // final cleanTitle = TitleCleaner.clean(seriesApi.name);

    // Check if series content already exists
    Content? existingSeries = await contentRepo.getContentByTmdbId(
      seriesApi.id,
    );

    Content seriesContent;
    if (existingSeries == null) {
      // Convert API model to app model and insert
      seriesContent = Content.fromSeriesApi(seriesApi);
      int contentId = await contentRepo.insertContent(seriesContent);
      seriesContent = seriesContent.copyWith(id: contentId);

      // Download series images
      await importService.setupSeriesImages(
        seriesId: seriesApi.id,
        posterPath: seriesApi.posterPath ?? '',
        backdropPath: seriesApi.backdropPath ?? '',
      );
    } else {
      seriesContent = existingSeries;
    }

    // Save episode video
    final videoPath = await importService.importEpisode(
      seriesTitle: seriesApi.name,
      seriesId: seriesApi.id,
      seasonNumber: episodeApi.seasonNumber,
      episodeNumber: episodeApi.episodeNumber,
      sourceVideo: File(sourceVideoPath),
    );

    // Convert episode API model to app model
    final episode = Episode.fromApi(
      episodeApi,
      seriesContent.id!,
    ).copyWith(videoPath: videoPath);

    // Insert episode to database
    await episodeRepo.insertEpisode(episode);

    return seriesContent;
  }

  Future<Content> importSeriesFromTMDB({
    required TvSeriesApi seriesApi,
    required List<EpisodeApi> allEpisodes, // flattened list of all episodes
  }) async {
    // Check if series already exists
    Content? existingSeries = await contentRepo.getContentByTmdbId(
      seriesApi.id,
    );

    Content seriesContent;
    if (existingSeries == null) {
      seriesContent = Content.fromSeriesApi(seriesApi);
      final contentId = await contentRepo.insertContent(seriesContent);
      seriesContent = seriesContent.copyWith(id: contentId);

      // Download series images
      await importService.setupSeriesImages(
        seriesId: seriesApi.id,
        posterPath: seriesApi.posterPath ?? '',
        backdropPath: seriesApi.backdropPath ?? '',
      );
    } else {
      seriesContent = existingSeries;
    }

    // Import all episodes (videoPath is null for now)
    for (final episodeApi in allEpisodes) {
      final episode = Episode.fromApi(
        episodeApi,
        seriesContent.id!,
      ).copyWith(videoPath: null); // videoPath is null
      await episodeRepo.insertEpisode(episode);
    }

    // Update series status to ready
    seriesContent = seriesContent.copyWith(status: StatusType.ready);
    await contentRepo.updateContent(seriesContent);

    return seriesContent;
  }
}
