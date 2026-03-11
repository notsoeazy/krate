# Krate - Project Roadmap & Tasks

## Phase 1: Core Localization & Stabilization 🛠️
*Goal: Ensure the library is robust, portable, and correctly captures all metadata.*

- [ ] **Subtitle Support**: Manual picker and auto-detection of `.srt`/`.ass` files.
- [ ] **Movie Import Fix**: Restrict file selection to media types only.
- [ ] **Multi-File Batch Import**: Support importing media along with multiple subtitles.
- [ ] **Search Marking**: Mark TMDB search results that are already in the library.
- [ ] **Pod automation**: Auto-discovery of existing pod folders in vault.
- [ ] **Delete Media**: Full deletion (metadata + files) from Library/Details screen.

## Phase 2: Enhanced Playback & UX 🎬
*Goal: Improve usability and make playback feel seamless.*

- [ ] **Subtitle Delay**: Real-time adjustment in the player.
- [ ] **Gesture Controls**: Vertical swipes for Volume/Brightness; tap to pause.
- [ ] **Player Screen Lock**: Prevent accidental touches during playback.
- [ ] **Series Navigation**: "Next Episode" and "Previous Episode" buttons in player.
- [ ] **Auto-Play**: Automatically start the next episode.
- [ ] **Continue Watching Redesign**: Improved logic and UI for resuming content.
- [ ] **Search Library**: Quickly find content within the Library tab.

## Phase 3: Advanced Features & Polish ✨
*Goal: Add power-user features and final UI consistency.*

- [ ] **Genre Filters**: Filter library by TMDB genres.
- [ ] **Settings Menu**: Root directory selection, theming, and cache management.
- [ ] **Watch Statistics**: Total watch time and content counters.
- [ ] **Granular Storage**: Delete video files only while keeping metadata entries.
- [ ] **Backup & Restore**: Export library data to a portable archive.
- [ ] **UI Consistency**: Final polish to ensure all screens follow `ui-design.md`.
- [ ] **External Player**: Option to open files in VLC/MX Player.
- [ ] **Custom Collections**: User-defined playlists/groups.

## Completed ✅
- [x] Initial UI Dashboard & Library
- [x] TMDB API Integration (Search & Metadata)
- [x] Robust Move/Copy Import logic
- [x] Media Management (Batch Link/Delete/Replace)
- [x] Vault Sync (Service & Metadata Recovery)
- [x] History & Completed Items tabs
- [x] Premium Player (Controls, Progress, Resume)
- [x] Metadata Stabilization (`.metadata.json` source of truth)
