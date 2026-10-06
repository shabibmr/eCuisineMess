import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/members/domain/entities/rfid_availability.dart';
import 'package:ecuisine_mess/features/members/domain/repositories/member_repository.dart';
import 'package:equatable/equatable.dart';

class CheckRfidAvailable
    extends UseCase<RfidAvailability, CheckRfidAvailableParams> {
  CheckRfidAvailable(this._repository);

  final MemberRepository _repository;

  @override
  Future<RfidAvailability> call(CheckRfidAvailableParams params) {
    return _repository.checkRfidAvailable(
      tag: params.tag,
      excludeMemberId: params.excludeMemberId,
    );
  }
}

class CheckRfidAvailableParams extends Equatable {
  const CheckRfidAvailableParams({
    required this.tag,
    this.excludeMemberId,
  });

  final String tag;
  final String? excludeMemberId;

  @override
  List<Object?> get props => [tag, excludeMemberId];
}
