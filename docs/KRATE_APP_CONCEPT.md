# Krate — App Concept & Technical Reference

Krate is an offline-first, local media manager and player built with Flutter, currently exclusive to **Android**. It manages movies and TV series stored on your device. Metadata is fetched from TMDB, artwork is downloaded and stored locally, and all state is double-written to both a local SQLite database and a `.metadata.json` file inside each media pod — so the library is portable and resilient. Future support for Desktop (Linux, Windows) is planned.

---

## Architecture Overview

```
User ──► Riverpod Providers ──► Services ──► SQLite DB (cache)
                                       ├──► .metadata.json (source of truth)
                                       ├──► Filesystem (krate_vault/)
                                       └──► MethodChannel (Android Native Picker)
```

**State Management:** Riverpod (`flutter_riverpod`) with `FutureProvider`, `StateNotifier`, and `Provider` for dependency injection.

**Navigation:** Standard Flutter `Navigator` (`Navigator.push`, `Navigator.pop`, `Navigator.popUntil`) with a custom persistent bottom-nav shell (`ShellScreen`). The app root is a plain `MaterialApp` — no GoRouter. The vault status check in `main.dart` decides whether to show `ShellScreen` or `StorageSetupScreen`.

**Database:** `sqflite` — singleton `AppDatabase`. 4 tables: `content`, `episodes`, `watch_progress`, `watch_history`.

**Metadata file:** `.metadata.json` inside each pod directory — if the DB is wiped, the entire library can be rebuilt by scanning these files via `VaultSyncService`.

---

## Vault Directory Structure

The vault lives inside a user-selected root folder (persisted via `SharedPreferences`):

```
<user-selected root>/
└── krate_vault/
    ├── movies/
    │   └── Movie-Title_Year_TMDBID/          ← "Pod" folder
    │       ├── .metadata.json                 ← Source of truth
    │       ├── poster.jpg
    │       ├── backdrop.jpg
    │       ├── Movie-Title.mp4               ← Renamed from source
    │       └── Movie-Title.en.vtt            ← Subtitles alongside media
    └── series/
        └── Series-Title_Year_TMDBID/          ← Pod folder
            ├── .metadata.json                 ← Source of truth (all episodes inside)
            ├── poster.jpg
            ├── backdrop.jpg
            └── Season_01/
                ├── Series-Title_S01E01.mkv
                ├── Series-Title_S01E01.en.srt ← Episode-specific subtitles
                └── Series-Title_S01E02.mkv
```

Pod folder naming is handled by `StorageService.ensurePodDir()`:

- Pattern: `slugified-title_year_tmdbId`
- Episode files: `slugified-title_S01E01.ext` inside `Season_NN/` subdirectories

---

## The `.metadata.json` File

Written (or overwritten) by `MetadataService.scribe()` after every import, link, re-link, delete, or rescan operation. It captures the full state of the pod.

**Schema (movies):**

```json
{
  "version": 1,
  "type": "movie",
  "tmdbId": 12345,
  "title": "Movie Title",
  "originalTitle": "...",
  "originalLanguage": "en",
  "tagline": "...",
  "overview": "...",
  "genres": ["Action", "Drama"],
  "releaseDate": "2023-06-15T00:00:00.000",
  "runtime": 120,
  "voteAverage": 7.8,
  "voteCount": 3200,
  "tmdbStatus": "Released",
  "tmdbPosterPath": "/remote/path.jpg",
  "tmdbBackdropPath": "/remote/backdrop.jpg",
  "posterPath": "poster.jpg",
  "backdropPath": "backdrop.jpg",
  "fileStatus": "ready",
  "videoPath": "Movie-Title.mp4"
}
```

**Schema (series)** — same header fields, plus:

```json
{
  "totalSeasons": 3,
  "totalEpisodes": 36,
  "episodes": [
    {
      "season": 1,
      "episode": 1,
      "title": "Pilot",
      "overview": "...",
      "airDate": "2021-01-10T00:00:00.000",
      "runtime": 45,
      "videoPath": "Season_01/Series-Title_S01E01.mkv",
      "fileStatus": "ready"
    }
  ]
}
```

> **Note:** `videoPath` inside episodes is stored as a **relative path** from the pod folder. When `MetadataService.read()` reconstructs Episode objects, it joins the relative path with the pod's absolute path to produce the full absolute path used at runtime.

> **Note:** `tmdbPosterPath` / `tmdbBackdropPath` retain the original TMDB remote paths so artwork can be re-downloaded at any time. The local `posterPath` / `backdropPath` are always the standardised filenames `poster.jpg` and `backdrop.jpg`.

---

## Database Schema

Stored in the OS app-data directory (`getDatabasesPath()`). Acts as a **read cache** — the filesystem is authoritative.

### `content` table

| Column              | Type           | Notes                                             |
| ------------------- | -------------- | ------------------------------------------------- |
| `id`                | INTEGER PK     | Auto-incremented local ID                         |
| `tmdbId`            | INTEGER UNIQUE | TMDB identifier, used to look up and de-duplicate |
| `contentType`       | TEXT           | `'movie'` or `'series'`                           |
| `title`             | TEXT           |                                                   |
| `genres`            | TEXT           | JSON-encoded string array                         |
| `releaseDate`       | TEXT           | ISO 8601                                          |
| `runtime`           | INTEGER        | Minutes. For series: average episode runtime      |
| `totalSeasons`      | INTEGER        | Series only                                       |
| `totalEpisodes`     | INTEGER        | Series only                                       |
| `tmdbPosterPath`    | TEXT           | Remote TMDB path, kept for re-download            |
| `tmdbBackdropPath`  | TEXT           | Remote TMDB path                                  |
| `localPosterPath`   | TEXT           | Absolute path to `poster.jpg` in pod              |
| `localBackdropPath` | TEXT           | Absolute path to `backdrop.jpg` in pod            |
| `podPath`           | TEXT           | Absolute path to the pod directory                |
| `isFavorite`        | INTEGER        | 0 or 1                                            |
| `fileStatus`        | TEXT           | `'ready'` or `'missing'`                          |

### `episodes` table

| Column          | Type       | Notes                                        |
| --------------- | ---------- | -------------------------------------------- |
| `id`            | INTEGER PK |                                              |
| `contentId`     | INTEGER FK | References `content(id)` with CASCADE delete |
| `seasonNumber`  | INTEGER    | `NULL` for movies                            |
| `episodeNumber` | INTEGER    | `NULL` for movies                            |
| `title`         | TEXT       | Episode name from TMDB                       |
| `runtime`       | INTEGER    | Minutes                                      |
| `videoPath`     | TEXT       | Absolute path to video file on disk          |
| `fileStatus`    | TEXT       | `'ready'` or `'missing'`                     |

### `subtitles` table

Managed by `SubtitleRepository`. One episode can have multiple subtitle files.

| Column      | Type       | Notes                                                       |
| ----------- | ---------- | ----------------------------------------------------------- |
| `id`        | INTEGER PK |                                                             |
| `episodeId` | INTEGER FK | References `episodes(id)` with CASCADE delete               |
| `path`      | TEXT       | Absolute path to the subtitle file (`.vtt`, `.srt`, `.ass`) |
| `name`      | TEXT       | Display name (usually the filename)                         |

> Movies get a single episode row with `seasonNumber = NULL`, `episodeNumber = NULL`. This unifies playback logic across both content types.

### `watch_progress` table

One row per episode. Upserted every time the player saves position.

| Column          | Type              | Notes                                           |
| --------------- | ----------------- | ----------------------------------------------- |
| `episodeId`     | INTEGER UNIQUE FK |                                                 |
| `contentId`     | INTEGER FK        | Denormalized for fast `getInProgress` queries   |
| `positionMs`    | INTEGER           | Playback position in milliseconds               |
| `durationMs`    | INTEGER           | Total duration in milliseconds                  |
| `isFinished`    | INTEGER           | 1 if position ≥ 90% of duration                 |
| `lastWatchedAt` | TEXT              | ISO 8601, used for "Continue Watching" ordering |

### `watch_history` table

Append-only log. One row inserted per viewing session when the player closes.

| Column              | Type       | Notes                                      |
| ------------------- | ---------- | ------------------------------------------ |
| `contentId`         | INTEGER FK |                                            |
| `episodeId`         | INTEGER FK |                                            |
| `startedAt`         | TEXT       | Session start time                         |
| `finishedAt`        | TEXT       | Session end time                           |
| `durationWatchedMs` | INTEGER    | Total milliseconds watched in that session |

---

## Import Flow: Scouting & Linking

The import pipeline is split into two explicit phases — **Scouting** (requires internet) and **Linking** (offline-capable).

### Phase 1: Scouting (Search & Preview)

**Screen:** `SearchImportScreen` → `MediaDetailsImportScreen`

1. **User searches** for a movie or TV series by name. `TMDBService.searchMulti()` queries the TMDB `search/multi` endpoint and returns a combined list of movies and TV shows.
2. **User taps a result.** The app navigates to `MediaDetailsImportScreen`, passing the `tmdbId` and `ContentType`.
3. `MediaDetailsImportScreen.initState()` immediately calls `TMDBService.getMovieDetails()` or `TMDBService.getSeriesDetails()` and builds a temporary `Content` object from the raw TMDB response using `Content.fromTmdbMovie()` / `Content.fromTmdbSeries()`.
4. The screen renders a preview card: poster (loaded from TMDB CDN), title, year, type, and overview.

---

### Phase 2a: Movie Import

**Screens:** `MediaDetailsImportScreen`

1. User taps **"Pick Media"** or **"Pick Subtitles"** on `MediaDetailsImportScreen`.
2. `FileUtils.pickFiles()` is called.
   - **On Android**: Uses a `MethodChannel` to trigger a native intent. This bypasses the default `file_picker` caching mechanism, returning direct UIDs/Paths and improving performance for massive 4GB+ files.
   - **Other Platforms**: Falls back to the community `file_picker` plugin.
3. The selected files are displayed in the staging area. Subtitles can be selected independently of the video file.
4. User taps **"Import Movie"**. The screen calls `ImportJobsNotifier.importMovie()`, which runs `ImportService.scoutMovie()` as a non-blocking background job.
5. The screen immediately pops back to Home (`Navigator.popUntil(isFirst)`).

**`ImportService.scoutMovie()` steps:**

```
[1] StorageService.ensurePodDir()     → creates <vault>/movies/Title_Year_ID/
[2] StorageService.movieFilePath()    → computes dest path: <pod>/Movie-Title.ext
[3] _moveFile(src, dest)              → tries rename() first; falls back to
                                         chunk-copy + delete (for cross-volume moves)
[4] ArtworkService.downloadArtwork() → downloads poster.jpg + backdrop.jpg into pod
[5] ContentRepository.getByTmdbId()  → checks if already in DB (re-import scenario)
    - if found: ContentRepository.update()
    - if new:   ContentRepository.insert()
[6] EpisodeRepository.insert()        → creates the single movie Episode row
[7] MetadataService.scribe()          → writes .metadata.json to pod
[8] Job status → ImportJobStatus.done → triggers library refresh via Riverpod invalidation
```

Progress is reported from 0.0 → 1.0 via `OnJobUpdate` callback, displayed in a persistent overlay managed by `ImportJobsNotifier`.

---

### Phase 2b: Series Import

**Screens:** `MediaDetailsImportScreen` → `SeriesEpisodePickerScreen`

1. On `MediaDetailsImportScreen`, tapping **"Select Episodes"** navigates to `SeriesEpisodePickerScreen` (passing `tmdbId`).
2. `SeriesEpisodePickerScreen.initState()` loads the series from the local DB (if it exists) or TMDB, then fetches all season details from TMDB (`TMDBService.getSeasonDetails()` per season) to build the full episode list.
3. Episodes are displayed grouped by season in collapsible `ExpansionTile` sections. The first season is expanded by default.
4. User taps a **file icon** on any episode row. `FilePicker` opens for that specific episode, a `BusyOverlay` shows during picker access, and the selected path is stored in a local `Map<String, String>` keyed as `"S{season}E{episode}"`.
5. A **Refresh** button in the AppBar can re-sync the episode list from TMDB without clearing selected files.
6. Once files are selected, a **"Import N Episodes"** button appears at the bottom.
7. Tapping **Import** calls `ImportJobsNotifier.importSeries()`, pops to Home, and runs in the background.

**`ImportService.scoutSeries()` steps:**

```
[1]  StorageService.ensurePodDir()          → creates <vault>/series/Title_Year_ID/
[2]  ArtworkService.downloadArtwork()       → downloads poster.jpg + backdrop.jpg
[3]  ContentRepository.upsert()             → insert or update Content row in DB
[4]  For each season (1..totalSeasons):
         TMDBService.getSeasonDetails()     → fetches full episode list from TMDB
         For each episode in TMDB list:
             EpisodeRepository.upsert()     → inserts/updates Episode row in DB
                                              (preserves existing videoPath & fileStatus)
[5]  For each user-selected file:
         StorageService.episodeFilePath()   → computes dest: <pod>/Season_NN/Title_SxxExx.ext
         _moveFile(src, dest)               → move/copy file into vault
         EpisodeRepository.update()         → sets videoPath + fileStatus = 'ready'
[6]  _syncContentStatus()                   → sets Content.fileStatus to 'ready'
                                              if at least one episode has a file
[7]  MetadataService.scribe()               → writes full .metadata.json (all episodes)
[8]  Job → done → library providers invalidated
```

---

### Phase 3: Linking & Replacing (Manage Mode)

**Screens:** `MediaManagementScreen` → `SeriesEpisodePickerScreen` / `FilePicker`

After a series is already scouted (metadata exists, artwork downloaded), the user can link individual episode files or replace existing ones from the **Media Management** screen.

1. **Manage Mode**: View all episodes and their file status.
2. **Link Mode**: Select multiple "missing" episodes and pick their files in batch.
3. **Delete Mode**: Select multiple "ready" episodes to delete their video files from disk while preserving metadata.

**`ImportService.linkEpisodes()` steps:**

```
[1] For each { episodeId → filePath } pair:
        EpisodeRepository.getById(episodeId)    → fetch Episode from DB
        StorageService.episodeFilePath()         → compute destination path
        _moveFile(src, dest)                     → move file into vault
        EpisodeRepository.update()               → set videoPath + fileStatus = 'ready'
[2] _syncContentStatus()                         → update Content.fileStatus
[3] MetadataService.scribe()                     → rewrite .metadata.json
```

**Re-linking a single episode** (`ImportService.relinkEpisode()`):

- Moves the new file into the vault at the same target path.
- Updates the episode's `videoPath` in the DB.
- Deletes the old file if the path changed.
- Calls `_syncContentStatus()` and `MetadataService.scribe()`.

---

## Deletion Flow

### Delete a Content Entry (entire movie or series)

`ImportService.deleteContent(content, deleteFiles: bool)`:

- If `deleteFiles = true`: deletes the entire pod directory recursively.
- Calls `ContentRepository.delete(contentId)`.
- Due to `ON DELETE CASCADE` in the DB schema, all related `episodes`, `watch_progress`, and `watch_history` rows are automatically removed.

### Delete a Single Episode File

`ImportService.deleteEpisodeFile(content, episode)`:

1. Deletes the physical file from disk (if it exists).
2. `EpisodeRepository.update()` — sets `videoPath = null`, `fileStatus = 'missing'`.
3. `_syncContentStatus()` — re-evaluates Content's `fileStatus`.
4. `MetadataService.scribe()` — rewrites `.metadata.json` with updated state.

### Batch Delete Episode Files

`ImportService.deleteEpisodesBatch(content, episodes)`:

- Iterates the episode list, deleting each video file and **all physically linked subtitle files** from disk.
- Clears the DB records (`videoPath = null`, `subtitles = []`) to prevent false alerts.
- One final `_syncContentStatus()` + `MetadataService.scribe()` call after all deletions.

---

## Scanner / Reconciliation Flow

**Service:** `VaultSyncService`

Triggered manually by the user via "Sync Vault" or automatically during startup via `scout()`. This system keeps the physical filesystem and the SQLite database perfectly aligned.

### Automatic Scouting (`scout()`)
Runs on app startup to cleanly detect discrepancies without doing a heavy resync:
1. Compares disk directories (`Movies`, `Series`) against `dbTrackedIds`. Identifies entirely new untracked content dumped by the user.
2. Checks all DB items. If a `ready` episode or movie is missing its video file or subtitle, it flags a sync.
3. Deep-scans tracked pod directories for newly dropped `.mp4`/`.mkv` or `.srt` files that the DB does not know about.
*If `scout()` returns true, the UI prompts the user to run a full Vault Sync.*

### Full Sync (`sync()`)

```
[1] Walk <vault>/movies/ and <vault>/series/ to collect all pod directories
[2] For each pod directory:
        Check for .metadata.json — skip if missing
        MetadataService.read()         → reconstruct Content + Episode from JSON
        Link / Reconcile Subtitles     → Scans pod for existing/new subtitle files
        ContentRepository.upsert()     → preserve isFavorite & createdAt; update rest
        EpisodeRepository.upsert()     → update episodes preserving local status
[3] Compare all Content.tmdbId in DB against found tmdbIds on disk
        Any DB entry not found on disk → flagged as missing (ghost)
```

**Ghost Records:** A content item whose pod directory no longer exists on disk. Its `fileStatus` is `'missing'` and the UI handles this via dynamic corner badges (checkmarks or error-blocks) representing file availability.

---

## Playback & Watch Progress Flow

**Screen:** `PlayerScreen` (wraps `awesome_video_player` / BetterPlayer-based engine)

### Launching Playback

- From `MediaDetailsScreen`, the **Play** / **Continue Watching** button uses `resumeEpisodeProvider` to resolve which episode to play.
- `WatchProgressService.getResumeEpisode(contentId)` determines the best episode using this priority:
  1. Most recently watched in-progress (unfinished) episode with `fileStatus = ready`.
  2. Next episode after the most recently finished one.
  3. First `ready` episode in the content.

### Saving Progress

- The player periodically calls `WatchProgressService.saveProgress()`.
- `WatchProgress` is upserted to the `watch_progress` table (one row per episode, keyed by `episodeId`).
- An episode is marked `isFinished = true` when `position / duration ≥ 0.9` (90% watched).
- After saving, Riverpod invalidates `continueWatchingProvider`, `resumeEpisodeProvider`, and `watchProgressProvider` so the Home screen and details screens reflect the latest progress immediately.

### Continue Watching

- `continueWatchingProvider` queries `WatchProgressRepository.getInProgressContent()` — returns `Content` items with at least one in-progress episode, ordered by `lastWatchedAt` descending.

---

## Storage Setup Flow

On first launch (or if the vault root is missing/unavailable), the app shows `StorageSetupScreen` instead of the main shell.

`StorageService.checkIntegrity()` is called via `vaultStatusProvider` at startup and returns one of:

- `VaultStatus.ok` — root exists, write access confirmed, vault structure intact.
- `VaultStatus.rootMissing` — no root configured or directory was deleted.
- `VaultStatus.noPermission` — Android storage permission not granted.

On Android, the app checks for both `Permission.storage` and `Permission.manageExternalStorage` (Android 11+ all-files access).

---

## `fileStatus` State Machine

Both `content` and `episodes` rows carry a `fileStatus` field:

```
missing ──► ready     (after link/import)
ready   ──► missing   (after file deletion or manual removal)
```

`_syncContentStatus()` is the internal method that keeps the parent `Content.fileStatus` in sync with its episodes:

- If **at least one** episode is `ready` → Content is `ready`.
- If **all** episodes are `missing` → Content is `missing` (ghost).

---

## Key Services Reference

| Service                | Responsibility                                                                                 |
| ---------------------- | ---------------------------------------------------------------------------------------------- |
| `ImportService`        | Orchestrates scout, link, relink, delete operations. Writes DB + metadata.                     |
| `MetadataService`      | Reads and writes `.metadata.json` for each pod.                                                |
| `StorageService`       | Manages the vault root, pod/season directory creation, and file path conventions.              |
| `ArtworkService`       | Downloads poster and backdrop from TMDB CDN into the pod.                                      |
| `TMDBService`          | Wraps TMDB REST API: `searchMulti`, `getMovieDetails`, `getSeriesDetails`, `getSeasonDetails`. |
| `VaultSyncService`     | Reconciles filesystem against DB by reading `.metadata.json` files.                            |
| `WatchProgressService` | Determines resume episode; saves/upserts watch progress; invalidates Riverpod providers.       |
