import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_buyer/features/catalog/presentation/catalog_providers.dart';
import 'package:secondlife_app_buyer/features/marketplace/presentation/marketplace_providers.dart';
import 'package:secondlife_app_buyer/features/notifications/presentation/notification_providers.dart';
import 'package:secondlife_app_buyer/features/orders/presentation/buyer_order_providers.dart';
import 'package:secondlife_app_buyer/features/wallet/domain/wallet_models.dart';
import 'package:secondlife_app_buyer/features/wallet/presentation/wallet_providers.dart';
import 'package:secondlife_app_buyer/main.dart';

class MockBuyerOrdersNotifier extends BuyerOrdersNotifier {
  @override
  BuyerOrdersState build() => const BuyerOrdersState(isLoading: false, orders: []);
}

class MockSellerWalletNotifier extends SellerWalletNotifier {
  @override
  SellerWalletState build() => SellerWalletState(
        isLoading: false,
        wallet: SellerWalletModel(
          id: 'w-1',
          userId: 'u-1',
          balance: 2500000,
          updatedAt: DateTime.now(),
        ),
      );
}

void main() {
  testWidgets('Buyer App launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketplacePostsProvider.overrideWith((ref) => Future.value([])),
          categoriesProvider.overrideWith((ref) => Future.value([])),
          buyerOrdersNotifierProvider.overrideWith(MockBuyerOrdersNotifier.new),
          sellerWalletNotifierProvider.overrideWith(MockSellerWalletNotifier.new),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
        ],
        child: const SecondLifeBuyerApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(SecondLifeBuyerApp), findsOneWidget);
  });
}
