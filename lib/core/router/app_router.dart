import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/dashboard/presentation/buyer_main_screen.dart';
import '../../features/marketplace/presentation/screens/product_detail_screen.dart';
import '../../features/marketplace/presentation/screens/search_filter_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/orders/presentation/screens/buyer_orders_screen.dart';
import '../../features/profile/presentation/screens/buyer_profile_screen.dart';
import '../../features/shipments/presentation/screens/shipment_tracking_screen.dart';
import '../../features/wallet/presentation/screens/buyer_wallet_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),

      // Main Navigation Tabs
      GoRoute(
        path: '/home',
        builder: (context, state) => const BuyerMainScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const BuyerMainScreen(initialIndex: 1),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const BuyerMainScreen(initialIndex: 2),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const BuyerMainScreen(initialIndex: 3),
      ),

      // Sub-screens
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(postId: id);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final postId = state.uri.queryParameters['postId'] ?? '';
          final negotiationId = state.uri.queryParameters['negotiationId'];
          return CheckoutScreen(postId: postId, negotiationId: negotiationId);
        },
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const BuyerWalletScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/shipments/tracking/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ShipmentTrackingScreen(shipmentId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/verify-email';

      // Public marketplace browsing is permitted
      final isPublicRoute = state.matchedLocation == '/home' ||
          state.matchedLocation == '/search' ||
          state.matchedLocation.startsWith('/products/');

      if (!isAuth && !isLoggingIn && !isPublicRoute) {
        return '/login';
      }

      if (isAuth && isLoggingIn) {
        return '/home';
      }

      return null;
    },
  );
});
