/// Utility for sanitizing filenames so they are safe across
/// Windows, Linux, macOS, and Android filesystems.
class TitleCleaner {
  /// Converts a string into a filesystem-safe filename.
  static String clean(String name) {
    String cleaned = name
        // Remove illegal filesystem characters
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        // Replace whitespace with underscore
        .replaceAll(RegExp(r'\s+'), '_')
        // Remove leading/trailing spaces
        .trim();

    // Prevent extremely long filenames
    const maxLength = 80;
    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength);
    }

    return cleaned;
  }
}
