import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/menu_item.dart';
import '../../core/repositories/menu_repository.dart';

final menuRepositoryProvider = Provider((ref) => MenuRepository());

class MenuNotifier extends StateNotifier<AsyncValue<List<MenuItem>>> {
  MenuNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final MenuRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.getAll());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(MenuItem item) async {
    await _repo.create(item);
    await load();
  }

  Future<void> updateItem(MenuItem item) async {
    await _repo.update(item);
    await load();
  }

  Future<void> deleteItem(int id) async {
    await _repo.delete(id);
    await load();
  }

  Future<void> toggleAvailability(MenuItem item) async {
    await _repo.setAvailability(item.id!, !item.isAvailable);
    await load();
  }
}

final menuProvider =
    StateNotifierProvider<MenuNotifier, AsyncValue<List<MenuItem>>>(
        (ref) => MenuNotifier(ref.read(menuRepositoryProvider)));

/// null = "All" category tab
final categoryFilterProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');
