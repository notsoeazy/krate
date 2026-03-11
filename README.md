<h1 align="center">
 Krate - Local Media Vault
</h1>

<p align="center">
  <img src="assets/krate-icon.svg" width="128" height="128" alt="Krate Logo">
</p>

<p align="center">Krate is an offline-first, local media vault and player designed to manage and watch your personal collection of movies and TV series directly from your device storage.</p>

---

<h2 align="center">✦ Table of Contents ✦</h2>

- [Description](#description)
- [What's Included](#whats-included)
- [Installation](#installation)
- [Status](#status)
- [Creators](#creators)
- [Thanks](#thanks)

---

<h2 align="center">✦ Description ✦</h2>

Krate provides a seamless way to organize your local media. It automatically fetches metadata and artwork from TMDB and stores them alongside your files in self-contained "pods." This ensures your library remains portable, resilient, and fully functional even without an internet connection.

The application is built for portability, allowing you to plug in media "pods" and sync your library entirely offline with zero friction.

---

<h2 align="center">✦ What's Included ✦</h2>

- **Metadata Management**: Automatic TMDB integration for movies and series.
- **Local Vault**: Self-contained folder structure for portability.
- **Smart Playback**: Auto-resume, progress saving, and "Continue Watching" support.
- **Media Management**: Tools to link, replace, and delete media files.
- **Vault Sync**: Reconcile your library with the filesystem in one tap.
- **History & Progress**: Track your viewing history and completed titles.

---

<h2 align="center">✦ Installation ✦</h2>

To run Krate locally, ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.

1. Clone the repository.
2. Create a `.env` file in the root directory and add your TMDB API key:
   ```env
   TMDB_API_KEY=your_api_key_here
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```
   > You can get a TMDB API key from [here](https://www.themoviedb.org/settings/api).

---

<h2 align="center">✦ Status ✦</h2>

> **Current Version:** v0.2.0-alpha  
> Krate is currently in active development. Core features for library management and playback are implemented, with further refinements planned for the beta release.

---

<h2 align="center">✦ Creators ✦</h2>

Maintained and developed with ❤️ for local media enthusiasts by [notsoeazy](https://github.com/notsoeazy).

---

<h2 align="center">✦ Thanks ✦</h2>

<table border="0">
  <tr>
    <td><img src="assets/tmdb.svg" width="100" alt="TMDB Logo"></td>
    <td>This product uses the TMDB API but is not endorsed or certified by TMDB.</td>
  </tr>
</table>
