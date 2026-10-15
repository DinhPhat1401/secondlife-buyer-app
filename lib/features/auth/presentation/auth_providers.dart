import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

export '../domain/auth_state.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = ApiClient(storageService: storage);
  ref.onDispose(client.dispose);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(client: client, storage: storage);
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Listen to session expiry from client
    final client = ref.watch(apiClientProvider);
    final sub = client.onSessionExpired.listen((_) {
      handleSessionExpired();
    });
    ref.onDispose(sub.cancel);

    // Initial session check
    Future.microtask(() => checkAuth());
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        );
      }
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      );
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.login(email: email, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> sendEmailOtp(String email) async {
    await _repository.sendEmailVerification(email);
  }

  Future<bool> verifyEmailOtp(String email, String otp) async {
    try {
      await _repository.confirmEmailVerification(email: email, otp: otp);
      await checkAuth();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void handleSessionExpired() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.',
    );
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
