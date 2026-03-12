// Krate-specific exception hierarchy.
library;

// Base class for all Krate application errors.
sealed class KrateException implements Exception {
  const KrateException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

// The vault root directory selected by the user no longer exists.
class VaultRootMissingException extends KrateException {
  const VaultRootMissingException(String path)
    : super('Vault root directory does not exist: $path');
}

// Krate cannot write to the selected directory.
class VaultPermissionException extends KrateException {
  const VaultPermissionException(String path)
    : super('No write permission for directory: $path');
}

// The source media file was not found at the expected path.
class SourceFileMissingException extends KrateException {
  const SourceFileMissingException(String path)
    : super('Source file not found: $path');
}

// A TMDB ID is required for the import operation but was not provided.
class TmdbIdRequiredException extends KrateException {
  const TmdbIdRequiredException()
    : super('A TMDB ID is required to import this content.');
}

// A TMDB API request failed.
class TmdbApiException extends KrateException {
  const TmdbApiException(String details)
    : super('TMDB API request failed: $details');
}

// The .metadata.json file could not be read or parsed.
class MetadataParseException extends KrateException {
  const MetadataParseException(String path)
    : super('Failed to parse metadata file: $path');
}

// No internet connection — the operation requires network access.
class NoInternetException extends KrateException {
  const NoInternetException()
    : super('No internet connection. Please check your network and try again.');
}

// File picking operations failed or were invalid.
class FilePickingException extends KrateException {
  const FilePickingException(String details)
    : super('File selection invalid: $details');
}

// A video file is mandatory for this specific operation.
class VideoRequiredException extends KrateException {
  const VideoRequiredException()
    : super('No video file selected. Please provide a video file first.');
}
