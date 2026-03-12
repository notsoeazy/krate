# Krate - Project Roadmap & Tasks

## Phase 1: Core Localization & Stabilization 🛠️

_Goal: Ensure the library is robust, portable, and correctly captures all metadata._

- [x] **Native Android Picker**: Optimized file selection and bypass caching.
- [x] **Subtitle Support**: Manual picker and auto-detection for `.srt` and `.vtt` files.
- [x] **Movie Import Fix**: Restrict file selection to media types only.
- [x] **Multi-File Batch Import**: Support importing media along with multiple subtitles.
- [x] **Search Marking**: Mark TMDB search results that are already in the library.
- [x] **Pod automation**: Auto-discovery of existing pod folders in vault.
- [ ] **Delete Media**: Full deletion (metadata + files) from Library/Details screen.

## Phase 2: Enhanced Playback & UX 🎬

_Goal: Improve usability and make playback feel seamless._

- [ ] **Subtitle Delay**: Real-time adjustment in the player.
- [ ] **Gesture Controls**: Vertical swipes for Volume/Brightness; tap to pause.
- [ ] **Player Screen Lock**: Prevent accidental touches during playback.
- [ ] **Series Navigation**: "Next Episode" and "Previous Episode" buttons in player.
- [ ] **Auto-Play**: Automatically start the next episode.
- [ ] **Continue Watching Redesign**: Improved logic and UI for resuming content.
- [ ] **Search Library**: Quickly find content within the Library tab.

## Phase 3: Advanced Features & Polish ✨

_Goal: Add power-user features and final UI consistency._

- [ ] **Genre Filters**: Filter library by TMDB genres.
- [ ] **Settings Menu**: Root directory selection, theming, and cache management.
- [ ] **Watch Statistics**: Total watch time and content counters.
- [ ] **Granular Storage**: Delete video files only while keeping metadata entries.
- [ ] **Backup & Restore**: Export library data to a portable archive.
- [ ] **UI Consistency**: Final polish to ensure all screens follow `ui-design.md`.
- [ ] **External Player**: Option to open files in VLC/MX Player.
- [ ] **Custom Collections**: User-defined playlists/groups.

## Phase 4: Cross-Platform Expansion 🛸

_Goal: Bringing Krate to the Desktop._

- [ ] **Linux Support**: Porting storage and file pickers for desktop environments.
- [ ] **Windows Support**: Ensuring compatibility with Windows file systems and pickers.
- [ ] **Adaptive UI**: Refined layouts for large screens and mouse input.

## Completed ✅

- [x] Initial UI Dashboard & Library
- [x] TMDB API Integration (Search & Metadata)
- [x] Robust Move/Copy Import logic
- [x] Media Management (Batch Link/Delete/Replace)
- [x] Vault Sync (Service & Metadata Recovery)
- [x] History & Completed Items tabs
- [x] Premium Player (Controls, Progress, Resume)
- [x] Metadata Stabilization (`.metadata.json` source of truth)
