import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../wallet/presentation/wallet_providers.dart';
import '../data/checkout_repository.dart';
import '../domain/checkout_models.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CheckoutRepository(client);
});

class SelectedDeliveryAddressNotifier extends Notifier<DeliveryAddressModel> {
  @override
  DeliveryAddressModel build() => DeliveryAddressModel(
        name: 'Người mua SecondLife',
        phone: '0988776655',
        latitude: 21.0285,
        longitude: 105.8542,
        address: 'Hoàn Kiếm, Hà Nội',
      );

  void setAddress(DeliveryAddressModel address) => state = address;
}

final selectedDeliveryAddressProvider =
    NotifierProvider<SelectedDeliveryAddressNotifier, DeliveryAddressModel>(
        SelectedDeliveryAddressNotifier.new);

final shippingQuoteProvider = FutureProvider.family<ShippingQuoteModel,
    ({String postId, String? negotiationId})>((ref, arg) async {
  final repo = ref.watch(checkoutRepositoryProvider);
  final address = ref.watch(selectedDeliveryAddressProvider);

  return repo.getShippingQuote(
    postId: arg.postId,
    address: address,
    negotiationId: arg.negotiationId,
  );
});

class CheckoutState {
  final bool isSubmitting;
  final String? errorMessage;
  final String? successOrderId;

  const CheckoutState({
    this.isSubmitting = false,
    this.errorMessage,
    this.successOrderId,
  });

  CheckoutState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    String? successOrderId,
  }) {
    return CheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successOrderId: successOrderId ?? this.successOrderId,
    );
  }
}

final checkoutNotifierProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  Future<String?> submitOrder({
    required String postId,
    required String shippingQuoteId,
    String? negotiationId,
    String paymentMethod = 'WALLET',
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final requestId = const Uuid().v4();

      final request = CreateOrderRequestModel(
        postId: postId,
        shippingQuoteId: shippingQuoteId,
        requestId: requestId,
        negotiationId: negotiationId,
        paymentMethod: paymentMethod,
      );

      final result = await repo.createOrder(request);
      final orderId = result['id']?.toString() ??
          result['orderId']?.toString() ??
          'order-created';

      // Refresh wallet balance after escrow payment deduction if wallet was used
      if (paymentMethod == 'WALLET') {
        ref.invalidate(sellerWalletNotifierProvider);
      }

      state = state.copyWith(isSubmitting: false, successOrderId: orderId);
      return orderId;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }
}

final orderBankPaymentProvider =
    FutureProvider.family<OrderBankPaymentResponse, String>((ref, orderId) async {
  final repo = ref.watch(checkoutRepositoryProvider);
  return repo.getOrderBankPayment(orderId);
});
