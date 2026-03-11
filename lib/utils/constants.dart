/// Core enums and application-level constants for Krate.
library;

/// The type of media content.
enum ContentType { movie, series }

/// The file availability status of a content item or episode.
enum FileStatus {
  ready, // Media file is present and playable
  missing, // Media file is missing/not exist
  importing, // Media file is being imported
}

/// Status of an in-flight import job.
enum ImportJobStatus { queued, running, done, error }

// Vault File & Folder Name Constants
const kVaultFolderName = 'krate_vault';
const kMoviesDirName = 'movies';
const kSeriesDirName = 'series';
const kEpisodeDirPrefix = 'Episode_';
const kMetadataFileName = '.metadata.json';
const kPosterFileName = '.poster.jpg';
const kBackdropFileName = '.backdrop.jpg';

// TMDB Image Base URLs
const kTmdbImageBase = 'https://image.tmdb.org/t/p';
const kTmdbPosterSize = 'w500';
const kTmdbBackdropSize = 'w780';

// Metadata Schema
const kMetadataSchemaVersion = 2;

// Playback
const kFinishedThreshold = 0.92;

// Typography — Google Fonts family names
/// Font used for body text, labels, and captions.
const kBodyFont = 'Inter';

/// Font used for display text, headings, and titles.
const kDisplayFont = 'Inter';
