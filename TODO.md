# Krate - To-Do List & Roadmap

## MVP Features
- [ ] **Media Management**: Refine the manage media feature to allow user to manage media files in the library.
    - [ ] Delete media files.
    - [ ] Link (move/copy) media files.
    - [ ] Update UI & databse, handle missing flags when deleted.
    - [ ] handle edge cases such as importinga and deleting at the same time.
    
- [ ] **Syncing**: Refine the syncing feature to allow user to sync their library with the krate_vault directory which will scan metadata.json and check for media files in the directory.
    - [ ] Import content entry just by scanning the metadata.json file.
    - [ ] Update database from metadata.json file.
    - [ ] Automatically load episodes and show in the library.

- [ ] **History**: Implement history tab.


Below is the list of planned features, improvements, and fixes for the Krate media vault.

## Priority: High (Core Functionality)
- [ ] **Subtitle Support**: Implement automatic subtitle file detection and manual picker in the player.
- [ ] **Delete Media**: Add the ability to delete a movie or series directly from the library (including the file).
- [ ] **Series Navigation**: Add "Next Episode" and "Previous Episode" buttons in the player.
- [ ] **Auto-Play**: Automatically start the next episode after one finishes.

## Priority: Medium (UX & Polish)
- [ ] **Search Library**: Add a search bar to the "Library" tab to quickly find imported content.
- [ ] **Genre Filters**: Filter media by genres (Action, Comedy, etc.) fetched from TMDB.
- [ ] **Settings Menu**: 
    - [ ] Change storage root directory.
    - [ ] Toggle theme (Dark/Light).
    - [ ] Clear cache.
- [ ] **Watch History & Statistics**: 
    - [ ] Dedicated screen to see everything you've watched in chronological order.
    - [ ] User Statistics: Track total watch time, movie count, and series episode count.
    - [ ] "Completed" tab for finished series and movies.
- [ ] **Granular Storage Management**: 
    - [ ] Allow deleting only the video file (keeping the library entry and metadata) to save space.

## Priority: Low (Advanced Features)
- [ ] **Custom Collections**: Allow users to group content into custom "Playlists."
- [ ] **Multi-Audio Tracks**: Add a selector for audio tracks (e.g., switches between Japanese/English dubs).
- [ ] **Cast & Crew**: Show actor profiles and other movies they've been in on the details screen.
- [ ] **Recommendations**: Show "Similar Movies" based on the current selection.
- [ ] **Backup/Restore**: Export the database and artwork to a zip file for migration.
- [ ] **External Player**: Option to open the video file in an external app like VLC or MX Player.


## Finished / Completed ✅
- [x] Initial UI Dashboard & Library.
- [x] TMDB API Integration for search and metadata.
- [x] Robust Move/Copy import logic with Android permission handling.
- [x] Premium Player with reactive controls, skip buttons, and skip gestures.
- [x] Automatic watch progress saving and resume.

