import 'package:bloc_test/bloc_test.dart';
import 'package:ecuisine_mess/features/email/domain/entities/email_attachment.dart';
import 'package:ecuisine_mess/features/email/domain/entities/email_send_result.dart';
import 'package:ecuisine_mess/features/email/domain/services/email_service.dart';
import 'package:ecuisine_mess/features/email/presentation/bloc/email_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmailService extends Mock implements EmailService {}

void main() {
  group('EmailAttachment', () {
    test('creates in-memory byte attachment correctly', () {
      final bytes = [10, 20, 30, 40];
      final att = EmailAttachment.fromBytes(
        fileName: 'report.csv',
        bytes: bytes,
        mimeType: 'text/csv',
      );

      expect(att.fileName, 'report.csv');
      expect(att.bytes, bytes);
      expect(att.filePath, isNull);
      expect(att.mimeType, 'text/csv');
    });

    test('creates file path attachment correctly', () {
      final att = EmailAttachment.fromPath(
        fileName: 'report.csv',
        filePath: '/tmp/report.csv',
        mimeType: 'text/csv',
      );

      expect(att.fileName, 'report.csv');
      expect(att.bytes, isNull);
      expect(att.filePath, '/tmp/report.csv');
    });
  });

  group('EmailSendResult', () {
    test('success factory returns true with messageId', () {
      final result = EmailSendResult.success(messageId: 'MSG-1234');
      expect(result.success, isTrue);
      expect(result.messageId, 'MSG-1234');
      expect(result.errorMessage, isNull);
    });

    test('failure factory returns false with errorMessage', () {
      final result = EmailSendResult.failure('Authentication failed');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Authentication failed');
      expect(result.messageId, isNull);
    });
  });

  group('EmailService.current global accessor', () {
    test('allows setting and retrieving global instance', () {
      final mock = MockEmailService();
      EmailService.current = mock;
      expect(EmailService.current, equals(mock));
    });
  });

  group('EmailBloc', () {
    late MockEmailService mockEmailService;

    setUp(() {
      mockEmailService = MockEmailService();
    });

    blocTest<EmailBloc, EmailState>(
      'emits [sending, success] when general email sends successfully',
      build: () {
        when(() => mockEmailService.sendEmail(
              recipients: any(named: 'recipients'),
              cc: any(named: 'cc'),
              bcc: any(named: 'bcc'),
              subject: any(named: 'subject'),
              bodyText: any(named: 'bodyText'),
              bodyHtml: any(named: 'bodyHtml'),
              attachments: any(named: 'attachments'),
            )).thenAnswer(
          (_) async => EmailSendResult.success(messageId: 'OK'),
        );
        return EmailBloc(emailService: mockEmailService);
      },
      act: (bloc) => bloc.add(const SendGeneralEmailEvent(
        recipients: ['test@example.com'],
        subject: 'Test Subject',
        bodyText: 'Hello World',
      )),
      expect: () => [
        const EmailState(status: EmailStatus.sending),
        EmailState(
          status: EmailStatus.success,
          result: EmailSendResult.success(messageId: 'OK'),
        ),
      ],
    );

    blocTest<EmailBloc, EmailState>(
      'emits [sending, failure] when email fails',
      build: () {
        when(() => mockEmailService.sendEmail(
              recipients: any(named: 'recipients'),
              cc: any(named: 'cc'),
              bcc: any(named: 'bcc'),
              subject: any(named: 'subject'),
              bodyText: any(named: 'bodyText'),
              bodyHtml: any(named: 'bodyHtml'),
              attachments: any(named: 'attachments'),
            )).thenAnswer(
          (_) async => EmailSendResult.failure('Connection refused'),
        );
        return EmailBloc(emailService: mockEmailService);
      },
      act: (bloc) => bloc.add(const SendGeneralEmailEvent(
        recipients: ['test@example.com'],
        subject: 'Test Subject',
      )),
      expect: () => [
        const EmailState(status: EmailStatus.sending),
        EmailState(
          status: EmailStatus.failure,
          result: EmailSendResult.failure('Connection refused'),
          errorMessage: 'Connection refused',
        ),
      ],
    );

    blocTest<EmailBloc, EmailState>(
      'emits [sending, success] when report email sends successfully',
      build: () {
        when(() => mockEmailService.sendReportEmail(
              recipients: any(named: 'recipients'),
              reportTitle: any(named: 'reportTitle'),
              periodDescription: any(named: 'periodDescription'),
              attachments: any(named: 'attachments'),
              customNotes: any(named: 'customNotes'),
            )).thenAnswer(
          (_) async => EmailSendResult.success(messageId: 'REP-01'),
        );
        return EmailBloc(emailService: mockEmailService);
      },
      act: (bloc) => bloc.add(SendReportEmailEvent(
        recipients: const ['supervisor@example.com'],
        reportTitle: 'Attendance',
        periodDescription: 'Today',
        attachments: [
          EmailAttachment.fromBytes(fileName: 'a.csv', bytes: const [1, 2]),
        ],
      )),
      expect: () => [
        const EmailState(status: EmailStatus.sending),
        EmailState(
          status: EmailStatus.success,
          result: EmailSendResult.success(messageId: 'REP-01'),
        ),
      ],
    );
  });
}
