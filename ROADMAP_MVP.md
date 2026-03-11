# Krate MVP Roadmap (v0.1.0)

This roadmap outlines the path to a stable beta release (v0.1.0) for Krate. The focus is on core stabilization, enhancing the playback experience, and refining the library management logic.

## Phase 1: Core Localization & Metadata Stabilization (v0.1.0-alpha)
*Goal: Ensure the library is robust, portable, and correctly captures all metadata.*

### 🛠️ Metadata & Syncing
- [ ] **Fix Rescan/Rescout Metadata**: Resolve bugs in the rescan logic specifically for metadata-only syncing. Ensure the `.metadata.json` is always accurate and updated before attempting full file syncs.
- [ ] **Vault Sync Service**: Improve the `ScannerService` to reliably rebuild the library from metadata files when the database is cleared.
- [ ] **Pod structure automation**: Support plugging in vault folders ("Pods") into `krate_vault` and having the app automatically discover and add them via a scan.

### 📥 Import Improvements
- [ ] **Movie Import Fix**: Restrict movie file selection to media types only.
- [ ] **Multi-File Batch Import**: Allow importing a media file along with multiple subtitle files in a single operation.
- [ ] **Search Marking**: In TMDB search results, mark entries already present in the library (using TMDB ID). Selecting a marked entry redirects to the library entry instead of the import screen.

---

## Phase 2: Enhanced Playback & User Experience (v0.1.0-beta)
*Goal: Make the app feel premium and highly usable for daily media consumption.*

### 🎬 Player "Premium" Features
- [ ] **Gesture Controls**: Implement intuitive gestures for:
    - **Pause/Resume**: Simple tap or custom gesture.
    - **Volume & Brightness**: Vertical swipes on right/left sides of the screen.
- [ ] **Screen Lock**: Add a lock feature to prevent accidental touches during playback.
- [ ] **Subtitle Delay**: Add a control to adjust subtitle sync offset in real-time.
- [ ] **Theming**: Apply Krate’s custom Material 3 theme to the player UI and controls for a consistent "Premium" look.

### 🏠 Home & Discovery
- [ ] **Continue Watching Redesign**: Redesign the section to prioritize the most recently played episode and ensure playback restarts exactly where the user left off.
- [ ] **Watch History**: Implement the "History" tab to show a chronological log of watched content.
- [ ] **Completed Items**: Filter for fully watched movies and series.

---

## Phase 3: Subtitle & Library Polish
*Goal: Final touches for the beta test.*

- [ ] **Subtitle Support**: Allow manual import of subtitle files for existing library entries.
- [ ] **Subtitle Auto-detection**: Automatically detect `.srt` or `.ass` files in the pod directory for seamless playback.
- [ ] **Beta Readiness**: Final bug fixes, performance optimization, and UI consistency checks across all screen sizes.

---

## Technical Debt & Maintenance
- [ ] Ensure all new UI follows the `ui-design.md` (Material 3 components, consistent spacing).
- [ ] Refactor `ImportService` to reduce complexity and improve job reporting reliability.
