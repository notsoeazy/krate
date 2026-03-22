# Krate - Project Roadmap & Tasks

## ⚡ Current Priorities

1.  **Import Rework**: Auto-search by filename and dedicated import screen.

## 🚀 Release & Versioning

- [x] Setup GitHub Actions for automated APK releases (with Secrets)
- [ ] Publish first alpha release (v0.4.0)

### How to Release:
1.  **Prep Secrets**: Ensure GitHub Secret `ENV_CONTENT` is set.
2.  **Bump Version**: Update `version` in `pubspec.yaml` (e.g., `0.4.0+1`).
3.  **Tag Release**: `git tag v0.4.0 && git push origin v0.4.0`.
4.  **Manual Trigger**: Go to Actions -> Release APK -> Run workflow -> Enter version.

## Phase 1: Core Localization & Stabilization 🛠️

_Goal: Ensure the library is robust, portable, and correctly captures all metadata._

- [x] **Native Android Picker**: Optimized file selection and bypass caching.
- [x] **Subtitle Support**: Manual picker and auto-detection for `.srt` and `.vtt` files.
- [x] **Movie Import Fix**: Restrict file selection to media types only.
- [x] **Multi-File Batch Import**: Support importing media along with multiple subtitles.
- [x] **Search Marking**: Mark TMDB search results that are already in the library.
- [x] **Pod automation**: Auto-discovery of existing pod folders in vault.
- [x] **Delete Media**: Full deletion (metadata + files) from Library/Details screen.

## Phase 2: Enhanced Playback & UX 🎬

_Goal: Improve usability and make playback feel seamless._

- [ ] **Subtitle Delay**: Real-time adjustment in the player.
- [ ] **Gesture Controls**: Vertical swipes for Volume/Brightness; tap to pause.
- [ ] **Player Screen Lock**: Prevent accidental touches during playback.
- [ ] **Series Navigation**: "Next Episode" and "Previous Episode" buttons in player.
- [ ] **Auto-Play**: Automatically start the next episode.
- [x] **Mark as Complete**: Manually toggle the "watched" status without playing the file.
- [x] **Continue Watching Redesign**: Improved logic and UI for resuming content.
- [x] **Search Library**: Quickly find content within the Library tab.

## Phase 3: Advanced Features & Polish ✨

_Goal: Add power-user features and final UI consistency._

- [ ] **Genre Filters**: Filter library by TMDB genres.
- [x] **Settings Menu**: Root directory selection, appearance customization, and cache management.
- [ ] **Watch Statistics**: Total watch time and content counters.
- [x] **New Theme Engine**: Multi-palette support (Midnight, Forest, Crimson, Sunset, Rose, Monochrome).
- [x] **UI Polish**: Material 3 scroll-under colors and transparent search bar transitions.
- [x] **Granular Storage**: Delete video files only while keeping metadata entries.
- [x] **JSON Backup & Export**: Export library data to a portable JSON archive for backup.
- [ ] **Reworked Import Screen**: Dedicated screen for importing media, accessible via FAB, Settings, or Top Bar.
- [ ] **Auto-Search Import**: Rework the import flow to automatically search based on filename for matching metadata.
- [ ] **External Player**: Option to open files in VLC/MX Player.
- [ ] **Custom Collections**: User-defined playlists/groups.

## Phase 4: Cross-Platform Expansion 🛸

_Goal: Bringing Krate to the Desktop._

- [ ] **Linux Support**: Porting storage and file pickers for desktop environments.
- [ ] **Windows Support**: Ensuring compatibility with Windows file systems and pickers.
- [x] **Adaptive UI**: Refined layouts for large screens (NavigationRail and ContentGrid adaptive columns).

## Completed ✅

- [x] Initial UI Dashboard & Library
- [x] TMDB API Integration (Search & Metadata)
- [x] Robust Move/Copy Import logic
- [x] Media Management (Batch Link/Delete/Replace)
- [x] Vault Sync (Service & Metadata Recovery)
- [x] History & Completed Items tabs
- [x] Premium Player (Controls, Progress, Resume)
- [x] Metadata Stabilization (`.metadata.json` source of truth)
- [x] Watch Status Toggle & Granular File Deletion
- [x] JSON Backup & Export
- [x] **Appearance Customization**: Theme mode, multi-color palettes, and UI polish.
- [x] **Lint Fixes**: General code quality audit and RadioGroup refactoring.
