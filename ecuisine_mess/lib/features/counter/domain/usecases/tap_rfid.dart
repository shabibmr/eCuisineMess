import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/counter_tap_result.dart';
import 'package:ecuisine_mess/features/counter/domain/repositories/counter_repository.dart';
import 'package:equatable/equatable.dart';

class TapRfid extends UseCase<CounterTapResult, TapRfidParams> {
  TapRfid(this._repository);

  final CounterRepository _repository;

  @override
  Future<CounterTapResult> call(TapRfidParams params) {
    return _repository.tapRfid(params.rfidTag);
  }
}

class TapRfidParams extends Equatable {
  const TapRfidParams(this.rfidTag);

  final String rfidTag;

  @override
  List<Object?> get props => [rfidTag];
}
