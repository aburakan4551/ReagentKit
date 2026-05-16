import '../entities/reagent_entity.dart';

abstract class ReagentTestingRepository {
  Future<List<ReagentEntity>> getAllReagents();
  Future<ReagentEntity?> getReagentByName(String reagentName);
  Future<List<ReagentEntity>> searchReagents(String query);
  Future<List<ReagentEntity>> getReagentsBySafetyLevel(String safetyLevel);
}
