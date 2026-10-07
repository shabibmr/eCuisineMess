import 'package:equatable/equatable.dart';

/// Configuration entity for SMTP mail server and report dispatch recipients.
class SmtpSettings extends Equatable {
  const SmtpSettings({
    this.host = '',
    this.port = 587,
    this.username = '',
    this.password = '',
    this.fromEmail = '',
    this.fromName = 'eCuisine Mess System',
    this.useTls = true,
    this.useSsl = false,
    this.supervisorEmails = const [],
    this.firebaseProjectId = '',
    this.updatedAt,
  });

  final String host;
  final int port;
  final String username;
  final String password;
  final String fromEmail;
  final String fromName;
  final bool useTls;
  final bool useSsl;
  final List<String> supervisorEmails;
  final String firebaseProjectId;
  final DateTime? updatedAt;

  /// Returns true if minimal required fields to attempt connection are present.
  bool get isConfigured =>
      host.trim().isNotEmpty && fromEmail.trim().isNotEmpty;

  SmtpSettings copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    String? fromEmail,
    String? fromName,
    bool? useTls,
    bool? useSsl,
    List<String>? supervisorEmails,
    String? firebaseProjectId,
    DateTime? updatedAt,
  }) {
    return SmtpSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      fromEmail: fromEmail ?? this.fromEmail,
      fromName: fromName ?? this.fromName,
      useTls: useTls ?? this.useTls,
      useSsl: useSsl ?? this.useSsl,
      supervisorEmails: supervisorEmails ?? this.supervisorEmails,
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    host,
    port,
    username,
    password,
    fromEmail,
    fromName,
    useTls,
    useSsl,
    supervisorEmails,
    firebaseProjectId,
    updatedAt,
  ];
}
