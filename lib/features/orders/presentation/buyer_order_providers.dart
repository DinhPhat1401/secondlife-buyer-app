import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/buyer_order_repository.dart';
import '../domain/order_models.dart';

final buyerOrderRepositoryProvider = Provider<BuyerOrderRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return BuyerOrderRepository(client);
});

class BuyerOrdersState {
  final bool isLoading;
  final String? errorMessage;
  final List<BuyerOrderModel> orders;
  final OrderStatus? filterStatus;

  const BuyerOrdersState({
    this.isLoading = false,
    this.errorMessage,
    this.orders = const [],
    this.filterStatus,
  });

  BuyerOrdersState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<BuyerOrderModel>? orders,
    OrderStatus? filterStatus,
    bool clearFilter = false,
  }) {
    return BuyerOrdersState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      orders: orders ?? this.orders,
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
    );
  }

  List<BuyerOrderModel> get filteredOrders {
    if (filterStatus == null) return orders;
    return orders.where((o) => o.status == filterStatus).toList();
  }
}

final buyerOrdersNotifierProvider =
    NotifierProvider<BuyerOrdersNotifier, BuyerOrdersState>(BuyerOrdersNotifier.new);

class BuyerOrdersNotifier extends Notifier<BuyerOrdersState> {
  @override
  BuyerOrdersState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => fetchOrders());
      return const BuyerOrdersState(isLoading: true);
    }
    return const BuyerOrdersState();
  }

  BuyerOrderRepository get _repo => ref.read(buyerOrderRepositoryProvider);

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getBuyerOrders();
      state = state.copyWith(isLoading: false, orders: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(OrderStatus? status) {
    if (status == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
  }

  Future<bool> confirmDelivery(String orderId) async {
    try {
      final updated = await _repo.confirmDelivery(orderId);
      final updatedList = state.orders.map((o) => o.id == orderId ? updated : o).toList();
      state = state.copyWith(orders: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final updated = await _repo.cancelOrder(orderId, reason: reason);
      final updatedList = state.orders.map((o) => o.id == orderId ? updated : o).toList();
      state = state.copyWith(orders: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}
