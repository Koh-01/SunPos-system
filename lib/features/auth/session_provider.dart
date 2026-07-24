import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_service.dart';

class SessionNotifier extends StateNotifier<AsyncValue<String?>> {
  SessionNotifier() : super(const AsyncValue.loading()) {
    _restore();
  }

  Future<void> _restore() async {
    final name = await SessionService.getCashierName();
    state = AsyncValue.data(name);
  }

  Future<void> logIn(String cashierName) async {
    await SessionService.logIn(cashierName);
    state = AsyncValue.data(cashierName);
  }

  Future<void> logOut() async {
    await SessionService.logOut();
    state = const AsyncValue.data(null);
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<String?>>(
        (ref) => SessionNotifier());
