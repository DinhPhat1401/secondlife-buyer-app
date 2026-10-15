import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_models.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return WalletRepository(client: client);
});

class SellerWalletState {
  final SellerWalletModel? wallet;
  final List<WalletTransactionModel> transactions;
  final List<WalletWithdrawalModel> withdrawals;
  final bool isLoading;
  final bool isSubmittingWithdrawal;
  final String? errorMessage;
  final String? successMessage;

  const SellerWalletState({
    this.wallet,
    this.transactions = const [],
    this.withdrawals = const [],
    this.isLoading = false,
    this.isSubmittingWithdrawal = false,
    this.errorMessage,
    this.successMessage,
  });

  SellerWalletState copyWith({
    SellerWalletModel? wallet,
    List<WalletTransactionModel>? transactions,
    List<WalletWithdrawalModel>? withdrawals,
    bool? isLoading,
    bool? isSubmittingWithdrawal,
    String? errorMessage,
    String? successMessage,
  }) {
    return SellerWalletState(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      withdrawals: withdrawals ?? this.withdrawals,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingWithdrawal: isSubmittingWithdrawal ?? this.isSubmittingWithdrawal,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class SellerWalletNotifier extends Notifier<SellerWalletState> {
  @override
  SellerWalletState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => loadWalletData());
      return const SellerWalletState(isLoading: true);
    }
    return const SellerWalletState();
  }

  WalletRepository get _repository => ref.read(walletRepositoryProvider);

  Future<void> loadWalletData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final wallet = await _repository.getMyWallet();
      final txs = await _repository.getTransactions();
      final wds = await _repository.getWithdrawals();
      state = state.copyWith(
        wallet: wallet,
        transactions: txs,
        withdrawals: wds,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'KhÃ´ng thá»ƒ táº£i dá»¯ liá»‡u vÃ­. Vui lÃ²ng thá»­ láº¡i.',
      );
    }
  }

  Future<bool> requestWithdrawal({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    if (state.wallet != null && amount > state.wallet!.balance) {
      state = state.copyWith(errorMessage: 'Sá»‘ dÆ° kháº£ dá»¥ng trong vÃ­ khÃ´ng Ä‘á»§ Ä‘á»ƒ rÃºt sá»‘ tiá»n nÃ y.');
      return false;
    }

    state = state.copyWith(isSubmittingWithdrawal: true, errorMessage: null);
    try {
      final newWd = await _repository.requestWithdrawal(
        amount: amount,
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
      );

      // Optimistically update wallet balance and withdrawal list
      final currentBal = state.wallet?.balance ?? 0.0;
      final updatedWallet = state.wallet != null
          ? SellerWalletModel(
              id: state.wallet!.id,
              userId: state.wallet!.userId,
              balance: (currentBal - amount).clamp(0.0, double.infinity),
              pendingBalance: state.wallet!.pendingBalance,
              totalWithdrawn: state.wallet!.totalWithdrawn + amount,
              updatedAt: DateTime.now(),
            )
          : null;

      state = state.copyWith(
        isSubmittingWithdrawal: false,
        wallet: updatedWallet,
        withdrawals: [newWd, ...state.withdrawals],
        successMessage: 'ÄÃ£ gá»­i yÃªu cáº§u rÃºt tiá»n thÃ nh cÃ´ng! Tiá»n sáº½ vá» tÃ i khoáº£n sau 1-2 giá» lÃ m viá»‡c.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmittingWithdrawal: false,
        errorMessage: 'Gá»­i yÃªu cáº§u rÃºt tiá»n tháº¥t báº¡i: ${e.toString()}',
      );
      return false;
    }
  }
}

final sellerWalletNotifierProvider =
    NotifierProvider<SellerWalletNotifier, SellerWalletState>(
  SellerWalletNotifier.new,
);

class HideWalletBalanceNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final hideWalletBalanceProvider =
    NotifierProvider<HideWalletBalanceNotifier, bool>(
  HideWalletBalanceNotifier.new,
);
