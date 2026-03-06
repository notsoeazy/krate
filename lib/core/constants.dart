/// Core enums and application-level constants for Krate.
library;

// ---------------------------------------------------------------------------
// Content & File Status Enums
// ---------------------------------------------------------------------------

/// The type of media content.
enum ContentType { movie, series }

/// The file availability status of a content item or episode.
enum FileStatus {
  /// The media file is present and playable.
  ready,

  /// The media file is missing from disk (but the pod/record exists).
  missing,

  /// The media file is currently being imported.
  importing,
}

/// Status of an in-flight import job.
enum ImportJobStatus { queued, running, done, error }

// ---------------------------------------------------------------------------
// Vault File & Folder Name Constants
// ---------------------------------------------------------------------------

/// The top-level folder created inside the user's chosen storage root.
const kVaultFolderName = 'krate_vault';

/// Sub-directory for movies inside the vault.
const kMoviesDirName = 'movies';

/// Sub-directory for series inside the vault.
const kSeriesDirName = 'series';

/// The hidden metadata file placed inside every pod folder.
const kMetadataFileName = '.metadata.json';

/// Local poster image file name stored in each pod folder.
const kPosterFileName = '.poster.jpg';

/// Local backdrop image file name stored in each pod folder.
const kBackdropFileName = '.backdrop.jpg';

// ---------------------------------------------------------------------------
// TMDB Image Base URLs
// ---------------------------------------------------------------------------

const kTmdbImageBase = 'https://image.tmdb.org/t/p';
const kTmdbPosterSize = 'w500';
const kTmdbBackdropSize = 'w780';

// ---------------------------------------------------------------------------
// Metadata Schema
// ---------------------------------------------------------------------------

const kMetadataSchemaVersion = 2;

// ---------------------------------------------------------------------------
// Playback
// ---------------------------------------------------------------------------

/// Fraction of total video duration after which we consider the video "finished".
const kFinishedThreshold = 0.92;
