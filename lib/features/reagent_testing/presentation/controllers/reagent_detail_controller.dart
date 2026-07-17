import 'package:flutter_riverpod/flutter_riverpod.dart';

final reagentDetailControllerProvider =
    StateNotifierProvider.autoDispose<ReagentDetailController, bool>((ref) {
      return ReagentDetailController();
    });

class ReagentDetailController extends StateNotifier<bool> {
  ReagentDetailController() : super(false);

  void setSafetyAcknowledgment(bool value) {
    state = value;
  }
}
