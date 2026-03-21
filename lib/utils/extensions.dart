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

  String toBackupFormat() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final y = year;
    final m = months[month - 1];
    final d = day;
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$h:$min • $m $d, $y';
  }

  String toHistoryFormat() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final y = year;
    final m = months[month - 1];
    final d = day;
    return '$m $d, $y';
  }
}
