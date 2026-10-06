import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/items/domain/entities/uom.dart';
import 'package:ecuisine_mess/features/items/domain/repositories/item_repository.dart';
import 'package:equatable/equatable.dart';

class GetUoms extends UseCase<List<Uom>, GetUomsParams> {
  GetUoms(this._repository);

  final ItemRepository _repository;

  @override
  Future<List<Uom>> call(GetUomsParams params) {
    return _repository.getUoms(includeInactive: params.includeInactive);
  }
}

class GetUomsParams extends Equatable {
  const GetUomsParams({this.includeInactive = false});

  final bool includeInactive;

  @override
  List<Object?> get props => [includeInactive];
}
