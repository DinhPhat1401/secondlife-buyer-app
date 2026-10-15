import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/negotiation_repository.dart';
import '../domain/negotiation_model.dart';

class NegotiationsState {
  final bool isLoading;
  final String? errorMessage;
  final List<NegotiationModel> negotiations;

  const NegotiationsState({
    this.isLoading = false,
    this.errorMessage,
    this.negotiations = const [],
  });

  NegotiationsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<NegotiationModel>? negotiations,
  }) {
    return NegotiationsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      negotiations: negotiations ?? this.negotiations,
    );
  }
}

final buyerNegotiationsNotifierProvider =
    NotifierProvider<BuyerNegotiationsNotifier, NegotiationsState>(BuyerNegotiationsNotifier.new);

class BuyerNegotiationsNotifier extends Notifier<NegotiationsState> {
  @override
  NegotiationsState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => fetchNegotiations());
      return const NegotiationsState(isLoading: true);
    }
    return const NegotiationsState();
  }

  NegotiationRepository get _repository => ref.read(negotiationRepositoryProvider);

  Future<void> fetchNegotiations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getBuyerNegotiations();
      state = state.copyWith(isLoading: false, negotiations: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<NegotiationModel?> submitOffer(String postId, double price) async {
    try {
      final created = await _repository.createNegotiation(postId: postId, offeredPrice: price);
      state = state.copyWith(negotiations: [created, ...state.negotiations]);
      return created;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> cancelOffer(String negotiationId) async {
    try {
      final cancelled = await _repository.cancelNegotiation(negotiationId);
      final updatedList =
          state.negotiations.map((item) => item.id == negotiationId ? cancelled : item).toList();
      state = state.copyWith(negotiations: updatedList);
      return true;
    } catch (e) {
      return false;
    }
  }
}
