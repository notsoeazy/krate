// Handy Dart extensions used throughout Krate.
library;

// Converts a title string into a safe filesystem-friendly text.
extension StringX on String {
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
