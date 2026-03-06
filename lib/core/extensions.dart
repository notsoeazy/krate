/// Handy Dart extensions used throughout Krate.
library;

extension StringX on String {
  /// Converts a title string into a safe filesystem-friendly slug.
  /// Example: "The Dark Knight (2008)" → "The_Dark_Knight_2008"
  String toSlug() {
    return replaceAll(
      RegExp(r"[^\w\s]"),
      '',
    ).trim().replaceAll(RegExp(r'\s+'), '_');
  }
}

extension DateTimeX on DateTime {
  int get year4 => year;
}
