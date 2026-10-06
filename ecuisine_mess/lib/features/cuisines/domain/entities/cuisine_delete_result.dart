import 'package:equatable/equatable.dart';

class CuisineDeleteResult extends Equatable {
  const CuisineDeleteResult({
    required this.action,
    required this.message,
  });

  /// 'deleted' or 'deactivated'
  final String action;
  final String message;

  bool get wasDeactivated => action == 'deactivated';

  @override
  List<Object?> get props => [action, message];
}
