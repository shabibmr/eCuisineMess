import 'package:equatable/equatable.dart';

class ItemDeleteResult extends Equatable {
  const ItemDeleteResult({
    required this.action,
    required this.message,
  });

  /// `deleted` or `deactivated`
  final String action;
  final String message;

  bool get wasDeactivated => action == 'deactivated';

  @override
  List<Object?> get props => [action, message];
}
