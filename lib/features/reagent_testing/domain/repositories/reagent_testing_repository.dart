import '../entities/reagent_entity.dart';
import '../../data/services/unified_data_service.dart';

abstract class ReagentTestingRepository {
  Future<List<ReagentEntity>> getAllReagents();
  Future<ReagentEntity?> getReagentByName(String reagentName);
  Future<List<ReagentEntity>> searchReagents(String query);
  Future<List<ReagentEntity>> getReagentsBySafetyLevel(String safetyLevel);
  String? get warningMessage;
  WarningSeverity get warningSeverity;
  DatasetLifecycleState get lifecycleState;
  Future<void> forceReload(
      {bool clearCache = false, bool forceAssetReload = true});
}
