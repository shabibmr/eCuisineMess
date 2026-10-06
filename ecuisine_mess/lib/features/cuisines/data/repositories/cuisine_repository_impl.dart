import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/cuisines/data/datasources/cuisine_remote_datasource.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_delete_result.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping_input.dart';
import 'package:ecuisine_mess/features/cuisines/domain/repositories/cuisine_repository.dart';

class CuisineRepositoryImpl implements CuisineRepository {
  CuisineRepositoryImpl(this._remote);

  final CuisineRemoteDataSource _remote;

  @override
  Future<List<Cuisine>> getCuisines({bool includeInactive = false}) async {
    try {
      final list = await _remote.getCuisines(includeInactive: includeInactive);
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Cuisine> getCuisine(String id) async {
    try {
      final model = await _remote.getCuisine(id);
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<String> saveCuisine({
    String? id,
    required String cuisineName,
    String? description,
    required bool isActive,
    required List<CuisineItemMappingInput> items,
  }) async {
    try {
      if (id == null || id.isEmpty) {
        return await _remote.createCuisine(
          name: cuisineName,
          description: description,
          isActive: isActive,
          items: items,
        );
      } else {
        await _remote.updateCuisine(
          id: id,
          name: cuisineName,
          description: description,
          isActive: isActive,
          items: items,
        );
        return id;
      }
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<int> copyMapping({
    required String targetCuisineId,
    required String sourceCuisineId,
  }) async {
    try {
      return await _remote.copyMapping(
        targetCuisineId: targetCuisineId,
        sourceCuisineId: sourceCuisineId,
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<CuisineDeleteResult> deleteCuisine(String id) async {
    try {
      return await _remote.deleteCuisine(id);
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}
