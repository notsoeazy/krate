# Krate

**Krate** is a local media vault and player built with Flutter. It lets you manage and watch your personal collection of movies and TV series directly from your device's storage. Metadata, artwork, and episode data are sourced from TMDB — all stored offline in a self-contained folder structure alongside your media files.

---

## Implemented Features

### 📥 Import Pipeline
- **TMDB Search** — Search movies and TV series by name and preview metadata before importing.
- **Movie Import** — Pick a local video file; Krate moves it into the vault, downloads artwork, records metadata to the database, and writes a `.metadata.json` file — all in the background.
- **Series Scouting** — Fetches full episode lists from TMDB for all seasons. Registers every episode in the database with metadata even before files are linked.
- **Series Episode Picker** — Browse seasons and episodes in a collapsible list; pick individual video files per episode. Starts a background import for all selected files at once.
- **Linking** — Link local files to already-scouted series episodes at any time, without needing internet.
- **Re-link / Replace** — Swap out a movie or episode file while preserving metadata and watch progress.
- **Background Import Overlay** — Real-time import progress (0–100%) displayed in a persistent overlay across all screens. A toast notification confirms completion or failure.

### 📂 Vault & File Management
- **Self-Scribed Pods** — Each title gets its own folder (`Title_Year_TMDBID/`) containing the video, `poster.jpg`, `backdrop.jpg`, and `.metadata.json`.
- **Structured Layout** — Movies under `krate_vault/movies/`, series under `krate_vault/series/`, episodes inside `Season_NN/` subdirectories.
- **Episode File Deletion** — Delete individual episode files (or in batch) from Media Management. DB and `.metadata.json` are updated immediately.
- **Content Deletion** — Remove a title from the library, optionally deleting the entire pod directory.
- **File Status Tracking** — Every content and episode tracks `fileStatus` (`ready` / `missing`) so the UI can surface ghost entries when files are gone.

### 🔄 Scanner / Vault Sync
- **One-Pass Scan** — Walks the vault directory, reads each `.metadata.json`, and reconciles with the database — preserving user data (favorites, etc.).
- **Ghost Detection** — Database entries whose pod directories are no longer found on disk are identified as ghost records.
- **TMDB Rescan** — Refresh metadata for an already-imported series from TMDB without unlinking existing episode files.

### 🎬 Playback
- **Video Player** — Powered by `awesome_video_player` (BetterPlayer-based) with hardware acceleration.
- **Auto-Resume** — The player picks up from the last saved position automatically.
- **Smart Resume Logic** — "Continue Watching" / "Play" resolves the best episode to start: most recently in-progress unfinished episode → next after last-finished → first available.
- **Progress Saving** — Position is periodically saved to the database. Episodes are marked finished at ≥ 90% watched.
- **Continue Watching** — Home screen section showing in-progress content ordered by most recently watched.

### 🏠 Home & Library
- **Dashboard (Home)** — Continue Watching row, Recently Added Movies and Series sections.
- **Library** — Tabbed view of all Movies and Series in the vault. Displays poster, title, and file status.
- **Media Details Screen** — Full metadata view with poster, backdrop, tagline, description, genres, rating, and season/episode list for series. Play button resolves the best resume episode.
- **Series Episode List** — Per-season tabs with episode cards showing title, air date, runtime, and watch progress indicators.

### 🗄️ Data Layer
- **SQLite Database** (`sqflite`) — 4 tables: `content`, `episodes`, `watch_progress`, `watch_history`. Foreign keys with `ON DELETE CASCADE`.
- **`.metadata.json`** — Written to each pod after every import, link, delete, or rescan. Acts as the persistent source of truth; the DB can be fully rebuilt from these files.
- **Artwork** — Downloaded from TMDB CDN as `poster.jpg` and `backdrop.jpg` into each pod. Available offline.

### ⚙️ Storage Setup
- User selects a storage root on first launch. The app verifies write access and creates the `krate_vault/` structure.
- Android permission handling for `MANAGE_EXTERNAL_STORAGE` (Android 11+).
- Vault integrity is checked on every app launch.

---

## Planned Features

### 🔴 High Priority
- **History Tab** — Chronological list of watched movies and episodes pulled from `watch_history`.
- **Subtitle Support** — Auto-detect `.srt`/`.ass` files alongside the video; manual subtitle file picker in the player; subtitle delay adjustment.
- **Delete from Library** — Full content deletion flow accessible directly from the Library/Details screen.
- **Series Player Navigation** — "Next Episode" and "Previous Episode" buttons within the player.
- **Auto-Play** — Automatically start the next episode when the current one ends.
- **Media Management Refinements** — Full delete + link flow from the Manage Episodes screen; handle edge cases (importing and deleting simultaneously).
- **Vault Sync Improvements** — Import content just by scanning `.metadata.json` (no TMDB re-fetch needed); auto-detect new episode files added manually to the vault.

### 🟡 Medium Priority
- **Library Search** — Search bar to quickly find content by title.
- **Genre Filters** — Filter the Library by genre.
- **Settings Screen** — Change vault root directory; toggle theme; clear cache.
- **Watch Statistics** — Total watch time, movie count, episode count; "Completed" content view.
- **Granular Storage Management** — Delete only the video file while keeping the library entry and metadata intact.

### 🟢 Low Priority
- **Custom Collections** — Group content into user-defined playlists.
- **Multi-Audio Track Support** — Switch between audio tracks (e.g., dub vs. sub) in the player.
- **Cast & Crew** — Actor profiles and filmography on the details screen.
- **Recommendations** — "Similar Titles" suggestions based on current content.
- **Backup & Restore** — Export database and artwork to a zip file for migration.
- **External Player** — Option to open a video file in VLC, MX Player, or another installed player.
