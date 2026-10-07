import 'package:equatable/equatable.dart';

/// Result status returned after an email dispatch attempt.
class EmailSendResult extends Equatable {
  const EmailSendResult({
    required this.success,
    this.messageId,
    this.errorMessage,
  });

  final bool success;
  final String? messageId;
  final String? errorMessage;

  factory EmailSendResult.success({String? messageId}) => EmailSendResult(
        success: true,
        messageId: messageId,
      );

  factory EmailSendResult.failure(String errorMessage) => EmailSendResult(
        success: false,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [success, messageId, errorMessage];
}
