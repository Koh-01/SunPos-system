import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/menu_item.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/menu_item_thumbnail.dart';
import '../auth/session_provider.dart';
import '../cart/cart_provider.dart';
import 'menu_provider.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final cartSubtotal = ref.watch(cartSubtotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Order History',
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Menu Management',
            onPressed: () => context.push('/menu-management'),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Printer Settings',
            onPressed: () => context.push('/printer-settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => ref.read(sessionProvider.notifier).logOut(),
          ),
        ],
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final available = items.where((i) => i.isAvailable).toList();
          final categories = available.map((i) => i.category).toSet().toList()
            ..sort();
          final query = searchQuery.trim().toLowerCase();
          final filtered = available.where((i) {
            final matchesCategory =
                selectedCategory == null || i.category == selectedCategory;
            final matchesQuery =
                query.isEmpty || i.name.toLowerCase().contains(query);
            return matchesCategory && matchesQuery;
          }).toList();

          if (available.isEmpty) {
            return const EmptyState(
              icon: Icons.restaurant_menu,
              message: 'No menu items available.\nAdd some in Menu Management.',
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search menu...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          ),
                  ),
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: selectedCategory == null,
                      onTap: () =>
                          ref.read(categoryFilterProvider.notifier).state = null,
                    ),
                    for (final c in categories)
                      _CategoryChip(
                        label: c,
                        selected: selectedCategory == c,
                        onTap: () =>
                            ref.read(categoryFilterProvider.notifier).state = c,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        message: 'No items match your search.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _MenuItemCard(
                            item: item,
                            onTap: () =>
                                ref.read(cartProvider.notifier).addItem(item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: cartCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: () => context.push('/cart'),
                  style: AppTheme.accentButtonStyle,
                  child: Text(
                    'View Cart ($cartCount) — ${formatRM(cartSubtotal)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const _MenuItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      MenuItemThumbnail(imagePath: item.imagePath, size: 44),
                    ],
                  ),
                ),
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(formatRM(item.price),
                    style: const TextStyle(color: AppTheme.primary)),
              ],
            ),
          ),
        ),
      );
}
