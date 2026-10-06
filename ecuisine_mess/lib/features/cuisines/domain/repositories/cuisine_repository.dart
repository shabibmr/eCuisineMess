import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_delete_result.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping_input.dart';

abstract class CuisineRepository {
  Future<List<Cuisine>> getCuisines({bool includeInactive = false});

  Future<Cuisine> getCuisine(String id);

  Future<String> saveCuisine({
    String? id,
    required String cuisineName,
    String? description,
    required bool isActive,
    required List<CuisineItemMappingInput> items,
  });

  Future<int> copyMapping({
    required String targetCuisineId,
    required String sourceCuisineId,
  });

  Future<CuisineDeleteResult> deleteCuisine(String id);
}
