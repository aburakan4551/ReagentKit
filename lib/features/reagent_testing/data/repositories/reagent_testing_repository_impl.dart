import '../../domain/entities/reagent_entity.dart';
import '../../domain/repositories/reagent_testing_repository.dart';
import '../services/unified_data_service.dart';

class ReagentTestingRepositoryImpl implements ReagentTestingRepository {
  final UnifiedDataService _dataService;
  String? _warningMessage;
  WarningSeverity _warningSeverity = WarningSeverity.info;
  DatasetLifecycleState _lifecycleState = DatasetLifecycleState.idle;

  ReagentTestingRepositoryImpl(this._dataService);

  @override
  String? get warningMessage => _warningMessage;

  @override
  WarningSeverity get warningSeverity => _warningSeverity;

  @override
  DatasetLifecycleState get lifecycleState => _lifecycleState;

  @override
  Future<void> forceReload(
      {bool clearCache = false, bool forceAssetReload = true}) async {
    try {
      final snapshot = await _dataService.loadPipeline(
        clearCache: clearCache,
        forceAssetReload: forceAssetReload,
      );
      _warningMessage = snapshot.warningMessage;
      _warningSeverity = snapshot.warningSeverity;
      _lifecycleState = snapshot.lifecycleState;
    } catch (e) {
      throw Exception('Failed to force reload reagents: $e');
    }
  }

  @override
  Future<List<ReagentEntity>> getAllReagents() async {
    try {
      final snapshot = await _dataService.getAllData();
      _warningMessage = snapshot.warningMessage;
      _warningSeverity = snapshot.warningSeverity;
      _lifecycleState = snapshot.lifecycleState;
      return snapshot.reagents.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to load reagents: $e');
    }
  }

  @override
  Future<ReagentEntity?> getReagentByName(String reagentName) async {
    try {
      final reagentModel = await _dataService.getReagentByName(reagentName);
      return reagentModel?.toEntity();
    } catch (e) {
      throw Exception('Failed to load reagent $reagentName: $e');
    }
  }

  @override
  Future<List<ReagentEntity>> searchReagents(String query) async {
    try {
      final reagentModels = await _dataService.searchReagents(query);
      return reagentModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to search reagents: $e');
    }
  }

  @override
  Future<List<ReagentEntity>> getReagentsBySafetyLevel(
    String safetyLevel,
  ) async {
    try {
      final snapshot = await _dataService.getAllData();
      return snapshot.reagents
          .where((model) => model.safetyLevel == safetyLevel)
          .map((model) => model.toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to get reagents by safety level: $e');
    }
  }
}
