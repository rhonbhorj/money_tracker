
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';

class ApiService {
  // Android emulator: use 10.0.2.2 for your PC's localhost.
  // Physical phone: use your PC's LAN IP address.
  static const String baseUrl =
          'http://money_tracker_api.test/api';

  Future<List<TransactionModel>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['status'] != true) {
      throw Exception(body['message'] ?? 'Failed to load transactions');
    }

    final List<dynamic> data = body['data'] as List<dynamic>;

    return data
        .map((item) => TransactionModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transaction.toJson()),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to save transaction');
    }
  }
}
