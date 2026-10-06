import 'package:equatable/equatable.dart';

class MemberDeleteResult extends Equatable {
  const MemberDeleteResult({
    required this.action,
    required this.message,
  });

  /// `deleted` or `suspended`
  final String action;
  final String message;

  @override
  List<Object?> get props => [action, message];
}
