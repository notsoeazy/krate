# Krate — The Self-Scribed Media Vault

Krate is a private, offline-first media manager and player designed for users who want complete control over their local film and series collections. Unlike traditional players that rely on a central, fragile database, Krate treats your filesystem as the source of truth, "scribing" metadata directly into your media folders.

---

## 🚀 Key Features

- **Self-Scribed Library**: Metadata and artwork are stored alongside your media files, making your library portable and resilient.
- **Background Imports**: High-performance, non-blocking media imports with real-time progress tracking.
- **Smart Scanning**: Bidirectional reconciliation detects new additions and identifies "Ghost Records" (missing physical files).
- **Universal Playback**: Powered by `media_kit`, supporting a vast range of codecs, hardware acceleration, and subtitle formats.
- **Continue Watching**: Automatically tracks your progress across movies and series episodes.
- **Privacy First**: Zero trackers. No account required. All data stays on your device.

---

## 🛠 How It Works

### 1. The "Scribe" Import Flow
When you import media, Krate performs a multi-step "Scribe" process:
1. **Match**: Fetches high-quality metadata and artwork from TMDB.
2. **Move**: Moves and renames the physical file into a clean, structured "Pod" folder.
3. **Scribe**: Creates a hidden `.metadata.json` file inside the folder containing the item's "DNA".
4. **Cache**: Indices the metadata into a local SQLite database for lightning-fast browsing.

### 2. Managing Files
Krate allows for deep integration with your filesystem:
- **Edit/Replace**: Easily swap out a movie or episode file while preserving its metadata and watch progress.
- **Smart Deletion**: Choose to remove just the library record or permanently wipe the files from your disk.
- **Reconciliation**: If you manually move or delete folders on your drive, Krate recognizes the change and marks the item's status accordingly.

### 3. File Structure
Krate organizes your media into a predictable, portable hierarchy:

```text
/krate_vault/
├── movies/
│   └── Movie_Title_Year_TMDBID/
│       ├── movie_file.mp4
│       ├── .metadata.json    <-- The Source of Truth
│       ├── poster.jpg
│       └── backdrop.jpg
└── series/
    └── Series_Title_Year_TMDBID/
        ├── .metadata.json
        ├── poster.jpg
        ├── backdrop.jpg
        └── Season_01/        <-- Subfolders for clean organization
            └── S01E01_Title.mp4
```

### 4. Data Storage
- **Filesystem**: The absolute source of truth. Metadata and local image paths are stored in `.metadata.json`.
- **Database (SQLite)**: Acts as a high-performance cache. If the database is ever lost, the entire library can be rebuilt in seconds by scanning the `.metadata.json` files.
- **Artwork**: Stored as standard JPG files within each media pod, ensuring posters are always available even if TMDB is offline.

---

## 🏗 Architecture

Krate is built with a focus on modularity and performance:

- **Frontend**: Flutter (3.x) with a custom Material 3 "Dark-First" design system.
- **State Management**: `Provider` for reactive UI updates and dependency injection.
- **Video Engine**: `media-kit` (FFmpeg-based), providing the best possible compatibility on Linux and Android.
- **Database**: `sqflite` for fast querying, filtering, and "Continue Watching" logic.
- **Services**:
  - `ScannerService`: The heartbeat that reconciles the filesystem and DB.
  - `ImportService`: Manages background file operations and metadata scribing.
  - `TMDBService`: Handles all interaction with the TMDB metadata API.
  - `StorageService`: Manages the user-defined vault location and permissions.
