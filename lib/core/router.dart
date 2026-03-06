import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/ui/screens/home/home_screen.dart';
import 'package:krate/ui/screens/import/media_details_import_screen.dart';
import 'package:krate/ui/screens/import/search_import_screen.dart';
import 'package:krate/ui/screens/import/series_episode_picker_screen.dart';
import 'package:krate/ui/screens/library/library_screen.dart';
import 'package:krate/ui/screens/library/media_details_screen.dart';
import 'package:krate/ui/screens/player/player_screen.dart';
import 'package:krate/ui/screens/recents/recents_screen.dart';
import 'package:krate/ui/screens/settings/settings_screen.dart';
import 'package:krate/ui/screens/shell_screen.dart';
import 'package:krate/ui/screens/storage_setup_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final vaultStatus = ref.watch(vaultStatusProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      if (vaultStatus.isLoading) return null;

      final status = vaultStatus.value ?? VaultStatus.rootMissing;
      final isSettingUp = state.matchedLocation == '/setup';

      if (status != VaultStatus.ok && !isSettingUp) {
        return '/setup';
      }
      if (status == VaultStatus.ok && isSettingUp) {
        return '/';
      }
      return null;
    },
    routes: [
      // Storage Setup
      GoRoute(
        path: '/setup',
        builder: (context, state) => const StorageSetupScreen(),
      ),

      // Main Shell with 4 tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          // Recents
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recents',
                builder: (context, state) => const RecentsScreen(),
              ),
            ],
          ),
          // Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Detail Screen (pushed above shell)
      GoRoute(
        path: '/details/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return MediaDetailsScreen(contentId: id);
        },
      ),

      // Player Screen (full-screen)
      GoRoute(
        path: '/player/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return PlayerScreen(episodeId: id);
        },
      ),

      // Import Flow
      GoRoute(
        path: '/import',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchImportScreen(),
        routes: [
          GoRoute(
            path: 'details/:tmdbId',
            builder: (context, state) {
              final tmdbId = int.parse(state.pathParameters['tmdbId']!);
              final typeStr = state.uri.queryParameters['type'] ?? 'movie';
              return MediaDetailsImportScreen(
                tmdbId: tmdbId,
                type: typeStr == 'series'
                    ? ContentType.series
                    : ContentType.movie,
              );
            },
          ),
          GoRoute(
            path: 'picker/:tmdbId',
            builder: (context, state) {
              final tmdbId = int.parse(state.pathParameters['tmdbId']!);
              return SeriesEpisodePickerScreen(tmdbId: tmdbId);
            },
          ),
        ],
      ),
    ],
  );
});
