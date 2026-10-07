import 'package:ecuisine_mess/features/email/domain/entities/email_attachment.dart';
import 'package:ecuisine_mess/features/email/domain/entities/email_send_result.dart';
import 'package:ecuisine_mess/features/email/domain/services/email_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Events ---

abstract class EmailEvent extends Equatable {
  const EmailEvent();
  @override
  List<Object?> get props => [];
}

class SendGeneralEmailEvent extends EmailEvent {
  const SendGeneralEmailEvent({
    required this.recipients,
    this.cc,
    this.bcc,
    required this.subject,
    this.bodyText,
    this.bodyHtml,
    this.attachments,
  });

  final List<String> recipients;
  final List<String>? cc;
  final List<String>? bcc;
  final String subject;
  final String? bodyText;
  final String? bodyHtml;
  final List<EmailAttachment>? attachments;

  @override
  List<Object?> get props => [
        recipients,
        cc,
        bcc,
        subject,
        bodyText,
        bodyHtml,
        attachments,
      ];
}

class SendReportEmailEvent extends EmailEvent {
  const SendReportEmailEvent({
    required this.recipients,
    required this.reportTitle,
    required this.periodDescription,
    required this.attachments,
    this.customNotes,
  });

  final List<String> recipients;
  final String reportTitle;
  final String periodDescription;
  final List<EmailAttachment> attachments;
  final String? customNotes;

  @override
  List<Object?> get props => [
        recipients,
        reportTitle,
        periodDescription,
        attachments,
        customNotes,
      ];
}

class ResetEmailStatusEvent extends EmailEvent {
  const ResetEmailStatusEvent();
}

// --- States ---

enum EmailStatus { initial, sending, success, failure }

class EmailState extends Equatable {
  const EmailState({
    this.status = EmailStatus.initial,
    this.result,
    this.errorMessage,
  });

  final EmailStatus status;
  final EmailSendResult? result;
  final String? errorMessage;

  EmailState copyWith({
    EmailStatus? status,
    EmailSendResult? result,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmailState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, result, errorMessage];
}

// --- BLoC ---

class EmailBloc extends Bloc<EmailEvent, EmailState> {
  EmailBloc({required EmailService emailService})
      : _emailService = emailService,
        super(const EmailState()) {
    on<SendGeneralEmailEvent>(_onSendGeneralEmail);
    on<SendReportEmailEvent>(_onSendReportEmail);
    on<ResetEmailStatusEvent>(_onResetEmailStatus);
  }

  final EmailService _emailService;

  Future<void> _onSendGeneralEmail(
    SendGeneralEmailEvent event,
    Emitter<EmailState> emit,
  ) async {
    emit(state.copyWith(status: EmailStatus.sending, clearError: true));
    final result = await _emailService.sendEmail(
      recipients: event.recipients,
      cc: event.cc,
      bcc: event.bcc,
      subject: event.subject,
      bodyText: event.bodyText,
      bodyHtml: event.bodyHtml,
      attachments: event.attachments,
    );

    if (result.success) {
      emit(state.copyWith(status: EmailStatus.success, result: result));
    } else {
      emit(state.copyWith(
        status: EmailStatus.failure,
        result: result,
        errorMessage: result.errorMessage ?? 'Failed to send email',
      ));
    }
  }

  Future<void> _onSendReportEmail(
    SendReportEmailEvent event,
    Emitter<EmailState> emit,
  ) async {
    emit(state.copyWith(status: EmailStatus.sending, clearError: true));
    final result = await _emailService.sendReportEmail(
      recipients: event.recipients,
      reportTitle: event.reportTitle,
      periodDescription: event.periodDescription,
      attachments: event.attachments,
      customNotes: event.customNotes,
    );

    if (result.success) {
      emit(state.copyWith(status: EmailStatus.success, result: result));
    } else {
      emit(state.copyWith(
        status: EmailStatus.failure,
        result: result,
        errorMessage: result.errorMessage ?? 'Failed to send report email',
      ));
    }
  }

  void _onResetEmailStatus(
    ResetEmailStatusEvent event,
    Emitter<EmailState> emit,
  ) {
    emit(const EmailState());
  }
}
