import 'package:equatable/equatable.dart';

/// Represents an email attachment, supporting either raw in-memory bytes
/// (such as freshly generated CSV reports or PDFs) or a file path on disk.
class EmailAttachment extends Equatable {
  const EmailAttachment({
    required this.fileName,
    this.bytes,
    this.filePath,
    this.mimeType,
  }) : assert(
         bytes != null || filePath != null,
         'Either bytes or filePath must be provided',
       );

  /// Display name of the file shown in email clients (e.g. "attendance_report.csv")
  final String fileName;

  /// In-memory binary contents. Preferred for generated reports without disk writes.
  final List<int>? bytes;

  /// Absolute file path on disk.
  final String? filePath;

  /// MIME content type, e.g. 'text/csv' or 'application/pdf'.
  final String? mimeType;

  factory EmailAttachment.fromBytes({
    required String fileName,
    required List<int> bytes,
    String? mimeType,
  }) {
    return EmailAttachment(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  factory EmailAttachment.fromPath({
    required String fileName,
    required String filePath,
    String? mimeType,
  }) {
    return EmailAttachment(
      fileName: fileName,
      filePath: filePath,
      mimeType: mimeType,
    );
  }

  @override
  List<Object?> get props => [fileName, bytes?.length, filePath, mimeType];
}
