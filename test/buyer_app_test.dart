import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_buyer/features/catalog/presentation/catalog_providers.dart';
import 'package:secondlife_app_buyer/features/checkout/domain/checkout_models.dart';
import 'package:secondlife_app_buyer/features/dashboard/presentation/buyer_main_screen.dart';
import 'package:secondlife_app_buyer/features/marketplace/domain/marketplace_models.dart';
import 'package:secondlife_app_buyer/features/marketplace/presentation/marketplace_providers.dart';
import 'package:secondlife_app_buyer/features/notifications/presentation/notification_providers.dart';
import 'package:secondlife_app_buyer/features/orders/domain/order_models.dart';
import 'package:secondlife_app_buyer/features/orders/presentation/buyer_order_providers.dart';
import 'package:secondlife_app_buyer/features/wallet/domain/wallet_models.dart';
import 'package:secondlife_app_buyer/features/wallet/presentation/wallet_providers.dart';

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
  group('Buyer Marketplace Models Tests', () {
    test('Parses MarketplaceProductModel from JSON correctly', () {
      final json = {
        'id': 'post-101',
        'postId': 'post-101',
        'sellerId': 'seller-202',
        'sellerName': 'Trần Văn An',
        'sellerAddress': 'Đống Đa, Hà Nội',
        'title': 'Nồi cơm điện tử Cuckoo 1.8L',
        'description': 'Nồi cơm còn rất mới, nấu cơm dẻo và giữ nhiệt 24h.',
        'itemCondition': 'LIKE_NEW',
        'price': 1200000,
        'status': 'ACTIVE',
        'imageUrls': [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ],
        'publishedAt': '2026-10-15T08:00:00Z',
      };

      final product = MarketplaceProductModel.fromJson(json);

      expect(product.id, 'post-101');
      expect(product.sellerName, 'Trần Văn An');
      expect(product.price, 1200000);
      expect(product.conditionLabel, 'Như mới (99%)');
      expect(product.primaryImage, 'https://example.com/img1.jpg');
      expect(product.formattedPrice, contains('1.200.000'));
    });

    test('MarketplaceFilterModel copyWith updates criteria properly', () {
      const filter = MarketplaceFilterModel(categoryId: 'cat-1');
      final updated = filter.copyWith(minPrice: 500000, maxPrice: 2000000);

      expect(updated.categoryId, 'cat-1');
      expect(updated.minPrice, 500000);
      expect(updated.maxPrice, 2000000);
    });
  });

  group('Buyer Checkout Models Tests', () {
    test('Parses ShippingQuoteModel and calculates formatted amounts', () {
      final json = {
        'quoteId': 'quote-777',
        'shippingFee': 45000,
        'productPrice': 1200000,
        'totalPayable': 1245000,
        'provider': 'Lalamove',
        'serviceType': 'MOTORCYCLE',
      };

      final quote = ShippingQuoteModel.fromJson(json);

      expect(quote.quoteId, 'quote-777');
      expect(quote.shippingFee, 45000);
      expect(quote.productPrice, 1200000);
      expect(quote.totalPayable, 1245000);
      expect(quote.provider, 'Lalamove');
      expect(quote.formattedTotalPayable, contains('1.245.000'));
    });

    test('CreateOrderRequestModel converts to JSON with requestId', () {
      final req = CreateOrderRequestModel(
        postId: 'post-101',
        shippingQuoteId: 'quote-777',
        requestId: 'req-uuid-1234',
        negotiationId: 'neg-555',
      );

      final json = req.toJson();

      expect(json['postId'], 'post-101');
      expect(json['shippingQuoteId'], 'quote-777');
      expect(json['requestId'], 'req-uuid-1234');
      expect(json['negotiationId'], 'neg-555');
    });
  });

  group('Buyer Orders Models Tests', () {
    test('Maps OrderStatus and determines buyer actions', () {
      final orderShipping = BuyerOrderModel(
        id: 'ord-1',
        postTitle: 'Tủ lạnh mini',
        sellerId: 's-1',
        sellerName: 'Shop A',
        deliveryAddress: 'Hà Nội',
        itemPrice: 1500000,
        shippingFee: 50000,
        totalAmount: 1550000,
        status: OrderStatus.shipping,
      );

      expect(orderShipping.canConfirmDelivered, isTrue);
      expect(orderShipping.canCancel, isFalse);

      final orderPending = BuyerOrderModel(
        id: 'ord-2',
        postTitle: 'Quạt đứng',
        sellerId: 's-1',
        sellerName: 'Shop A',
        deliveryAddress: 'Hà Nội',
        itemPrice: 300000,
        totalAmount: 330000,
        status: OrderStatus.pending,
      );

      expect(orderPending.canCancel, isTrue);
      expect(orderPending.canConfirmDelivered, isFalse);
    });
  });

  group('Buyer UI Smoke Tests', () {
    testWidgets('Renders BuyerMainScreen with all 4 navigation tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketplacePostsProvider.overrideWith((ref) => Future.value([])),
            categoriesProvider.overrideWith((ref) => Future.value([])),
            buyerOrdersNotifierProvider.overrideWith(MockBuyerOrdersNotifier.new),
            sellerWalletNotifierProvider.overrideWith(MockSellerWalletNotifier.new),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
          ],
          child: const MaterialApp(
            home: BuyerMainScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.text('Tìm kiếm'), findsOneWidget);
      expect(find.text('Đơn mua'), findsOneWidget);
      expect(find.text('Tài khoản'), findsOneWidget);
    });
  });
}
