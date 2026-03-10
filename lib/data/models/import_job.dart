import 'package:krate/utils/constants.dart';

/// Represents a single in-flight or recently completed import operation.
///
/// Managed by [ImportJobsNotifier] in the providers layer.
class ImportJob {
  final String id; // UUID
  final String title;
  final ContentType contentType;
  final ImportJobStatus status;
  final double progress; // 0.0 – 1.0
  final String? currentStep; // Human-readable step description for the UI
  final String? error;
  final DateTime startedAt;

  const ImportJob({
    required this.id,
    required this.title,
    required this.contentType,
    this.status = ImportJobStatus.queued,
    this.progress = 0.0,
    this.currentStep,
    this.error,
    required this.startedAt,
  });

  bool get isActive =>
      status == ImportJobStatus.queued || status == ImportJobStatus.running;
  bool get isDone => status == ImportJobStatus.done;
  bool get hasFailed => status == ImportJobStatus.error;

  ImportJob copyWith({
    String? id,
    String? title,
    ContentType? contentType,
    ImportJobStatus? status,
    double? progress,
    String? currentStep,
    String? error,
    DateTime? startedAt,
  }) {
    return ImportJob(
      id: id ?? this.id,
      title: title ?? this.title,
      contentType: contentType ?? this.contentType,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}
