import 'package:secondlife_app_buyer/core/network/api_client.dart';
import 'package:secondlife_app_buyer/core/network/api_endpoints.dart';
import 'package:secondlife_app_buyer/core/network/error_handler.dart';
import '../domain/wallet_models.dart';

class WalletRepository {
  final ApiClient client;

  WalletRepository({required this.client});

  Future<SellerWalletModel> getMyWallet() async {
    final response = await client.get<Map<String, dynamic>>(ApiEndpoints.walletMe);
    final data = response.data;
    if (data == null) {
      throw AppException(message: 'KhÃ´ng nháº­n Ä‘Æ°á»£c dá»¯ liá»‡u vÃ­ tá»« mÃ¡y chá»§');
    }
    final payload = data['data'] ?? data;
    return SellerWalletModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<List<WalletTransactionModel>> getTransactions({int page = 0, int size = 20}) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.walletTransactions,
      queryParameters: {
        'page': page,
        'size': size,
        'sort': 'createdAt,desc',
      },
    );
    final data = response.data;
    List<dynamic> list = [];
    if (data != null) {
      if (data['content'] is List) {
        list = data['content'] as List;
      } else if (data['data'] is List) {
        list = data['data'] as List;
      } else if (data['items'] is List) {
        list = data['items'] as List;
      }
    }
    final items = list
        .map((item) => WalletTransactionModel.fromJson(item as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<List<WalletWithdrawalModel>> getWithdrawals({int page = 0, int size = 20}) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.walletWithdrawals,
      queryParameters: {
        'page': page,
        'size': size,
        'sort': 'createdAt,desc',
      },
    );
    final data = response.data;
    List<dynamic> list = [];
    if (data != null) {
      if (data['content'] is List) {
        list = data['content'] as List;
      } else if (data['data'] is List) {
        list = data['data'] as List;
      } else if (data['items'] is List) {
        list = data['items'] as List;
      }
    }
    final items = list
        .map((item) => WalletWithdrawalModel.fromJson(item as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<WalletWithdrawalModel> requestWithdrawal({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.walletWithdrawals,
      data: {
        'amount': amount,
        'bankCode': bankCode,
        'accountNumber': accountNumber,
        'accountHolderName': accountHolderName.toUpperCase().trim(),
      },
    );
    final data = response.data;
    if (data == null) {
      throw AppException(message: 'Táº¡o yÃªu cáº§u rÃºt tiá»n tháº¥t báº¡i');
    }
    final payload = data['data'] ?? data;
    return WalletWithdrawalModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createDepositRequest(double amount) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.walletDepositRequest,
      data: {'amount': amount.toInt()},
    );
    final data = response.data;
    if (data == null) {
      throw AppException(message: 'Táº¡o yÃªu cáº§u náº¡p tiá»n tháº¥t báº¡i');
    }
    final payload = data['data'] ?? data;
    return payload as Map<String, dynamic>;
  }
}
