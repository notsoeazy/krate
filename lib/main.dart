import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';

import 'package:krate/theme.dart';
import 'package:krate/screens/screens.dart';
import 'package:krate/repositories/content_repository.dart';
import 'package:krate/repositories/episode_repository.dart';
import 'package:krate/repositories/watch_progress_repository.dart';
import 'package:krate/services/api/tmdb_service.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/services/import_service.dart';
import 'package:krate/services/artwork_service.dart';
import 'package:krate/services/metadata_service.dart';
import 'package:krate/services/scanner_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Media Kit for video playback
  MediaKit.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        // Repositories
        ChangeNotifierProvider(create: (_) => ContentRepository()),
        Provider(create: (_) => EpisodeRepository()),
        Provider(create: (_) => WatchProgressRepository()),

        // Services
        Provider(create: (_) => TMDBService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
        Provider(create: (_) => ArtworkService()),
        Provider(create: (_) => MetadataService()),

        // Import Service (depends on others)
        ChangeNotifierProxyProvider6<
          ContentRepository,
          EpisodeRepository,
          ArtworkService,
          StorageService,
          TMDBService,
          MetadataService,
          ImportService
        >(
          create: (context) => ImportService(
            contentRepo: context.read<ContentRepository>(),
            episodeRepo: context.read<EpisodeRepository>(),
            artworkService: context.read<ArtworkService>(),
            storageService: context.read<StorageService>(),
            tmdbService: context.read<TMDBService>(),
            metadataService: context.read<MetadataService>(),
          ),
          update:
              (
                _,
                contentRepo,
                episodeRepo,
                artworkService,
                storageService,
                tmdbService,
                metadataService,
                importService,
              ) => importService!
                ..updateDependencies(
                  contentRepo: contentRepo,
                  episodeRepo: episodeRepo,
                  artworkService: artworkService,
                  storageService: storageService,
                  tmdbService: tmdbService,
                  metadataService: metadataService,
                ),
        ),

        // Scanner Service (The library heartbeat)
        ChangeNotifierProxyProvider4<
          ContentRepository,
          EpisodeRepository,
          MetadataService,
          StorageService,
          ScannerService
        >(
          create: (context) => ScannerService(
            contentRepo: context.read<ContentRepository>(),
            episodeRepo: context.read<EpisodeRepository>(),
            metadataService: context.read<MetadataService>(),
            storageService: context.read<StorageService>(),
          ),
          update:
              (
                _,
                contentRepo,
                episodeRepo,
                metadataService,
                storageService,
                scanner,
              ) => scanner!
                ..updateDependencies(
                  contentRepo: contentRepo,
                  episodeRepo: episodeRepo,
                  metadataService: metadataService,
                  storageService: storageService,
                ),
        ),
      ],
      child: const KrateApp(),
    ),
  );
}

class KrateApp extends StatelessWidget {
  const KrateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: KrateTheme.darkTheme,
      home: Consumer<StorageService>(
        builder: (context, storage, _) {
          return FutureBuilder<bool>(
            future: storage.verifyStorageRoot().then((exists) {
              if (!exists) return false;
              return storage.isStorageReady();
            }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.data == true) {
                return const MainView();
              }

              return const StorageSelectionScreen();
            },
          );
        },
      ),
    );
  }
}
