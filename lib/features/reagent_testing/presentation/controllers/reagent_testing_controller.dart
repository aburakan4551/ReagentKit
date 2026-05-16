import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/reagent_entity.dart';
import '../../domain/repositories/reagent_testing_repository.dart';
import '../states/reagent_testing_state.dart';

class ReagentTestingController extends StateNotifier<ReagentTestingState> {
  final ReagentTestingRepository _repository;
  List<ReagentEntity> _allReagents = [];

  ReagentTestingController(this._repository)
    : super(const ReagentTestingInitial()) {
    loadAllReagents();
  }

  // Load all reagents from repository
  Future<void> loadAllReagents() async {
    state = const ReagentTestingLoading();
    try {
      _allReagents = await _repository.getAllReagents();
      if (_allReagents.isEmpty) {
        state = const ReagentTestingEmpty('No reagents found');
      } else {
        state = ReagentTestingLoaded(reagents: _allReagents);
      }
    } catch (e) {
      state = ReagentTestingError('Failed to load reagents: $e');
    }
  }

  // Search reagents by query
  Future<void> searchReagents(String query) async {
    if (query.trim().isEmpty) {
      // If search is empty, show all reagents
      state = ReagentTestingLoaded(reagents: _allReagents);
      return;
    }

    state = const ReagentTestingLoading();
    try {
      final searchResults = await _repository.searchReagents(query);
      if (searchResults.isEmpty) {
        state = ReagentTestingEmpty('No reagents found for "$query"');
      } else {
        state = ReagentTestingLoaded(
          reagents: searchResults,
          searchQuery: query,
        );
      }
    } catch (e) {
      state = ReagentTestingError('Failed to search reagents: $e');
    }
  }

  // Filter reagents by safety level
  Future<void> filterBySafetyLevel(String? safetyLevel) async {
    if (safetyLevel == null || safetyLevel.isEmpty) {
      // If no safety level selected, show all reagents
      state = ReagentTestingLoaded(reagents: _allReagents);
      return;
    }

    state = const ReagentTestingLoading();
    try {
      final filteredReagents = await _repository.getReagentsBySafetyLevel(
        safetyLevel,
      );
      if (filteredReagents.isEmpty) {
        state = ReagentTestingEmpty(
          'No reagents found with safety level "$safetyLevel"',
        );
      } else {
        state = ReagentTestingLoaded(
          reagents: filteredReagents,
          selectedSafetyLevel: safetyLevel,
        );
      }
    } catch (e) {
      state = ReagentTestingError('Failed to filter reagents: $e');
    }
  }

  // Get a specific reagent by name
  Future<ReagentEntity?> getReagentByName(String reagentName) async {
    try {
      return await _repository.getReagentByName(reagentName);
    } catch (e) {
      state = ReagentTestingError('Failed to get reagent: $e');
      return null;
    }
  }

  // Clear search and filters
  void clearFilters() {
    state = ReagentTestingLoaded(reagents: _allReagents);
  }

  // Refresh data
  Future<void> refresh() async {
    await loadAllReagents();
  }

  // Get current reagents list
  List<ReagentEntity> get currentReagents {
    final currentState = state;
    if (currentState is ReagentTestingLoaded) {
      return currentState.reagents;
    }
    return [];
  }

  // Check if currently searching
  bool get isSearching {
    final currentState = state;
    if (currentState is ReagentTestingLoaded) {
      return currentState.searchQuery != null &&
          currentState.searchQuery!.isNotEmpty;
    }
    return false;
  }

  // Check if currently filtering
  bool get isFiltering {
    final currentState = state;
    if (currentState is ReagentTestingLoaded) {
      return currentState.selectedSafetyLevel != null &&
          currentState.selectedSafetyLevel!.isNotEmpty;
    }
    return false;
  }
}
