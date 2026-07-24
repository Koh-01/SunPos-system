import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/session_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/menu/menu_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/payment/payment_screen.dart';
import 'features/receipt/receipt_screen.dart';
import 'features/history/order_history_screen.dart';
import 'features/history/order_detail_screen.dart';
import 'features/menu_management/menu_management_screen.dart';
import 'features/printer/printer_settings_screen.dart';
import 'shared/theme/app_theme.dart';

final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

class PosApp extends ConsumerStatefulWidget {
  const PosApp({super.key});

  @override
  ConsumerState<PosApp> createState() => _PosAppState();
}

class _PosAppState extends ConsumerState<PosApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      refreshListenable: ref.read(_routerNotifierProvider),
      initialLocation: '/login',
      redirect: (context, state) {
        final session = ref.read(sessionProvider);
        if (session.isLoading) return null;
        final loggedIn = session.value != null;
        final isLoggingIn = state.matchedLocation == '/login';
        if (!loggedIn) return isLoggingIn ? null : '/login';
        if (isLoggingIn) return '/menu';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/menu', builder: (_, _) => const MenuScreen()),
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
        GoRoute(path: '/payment', builder: (_, _) => const PaymentScreen()),
        GoRoute(
          path: '/receipt/:orderId',
          builder: (_, s) => ReceiptScreen(
              orderId: int.parse(s.pathParameters['orderId']!)),
        ),
        GoRoute(
          path: '/history',
          builder: (_, _) => const OrderHistoryScreen(),
          routes: [
            GoRoute(
              path: ':orderId',
              builder: (_, s) => OrderDetailScreen(
                  orderId: int.parse(s.pathParameters['orderId']!)),
            ),
          ],
        ),
        GoRoute(
          path: '/menu-management',
          builder: (_, _) => const MenuManagementScreen(),
        ),
        GoRoute(
          path: '/printer-settings',
          builder: (_, _) => const PrinterSettingsScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SunPos',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(sessionProvider, (_, _) => notifyListeners());
  }
}
