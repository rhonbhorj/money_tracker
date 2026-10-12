
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/transaction_model.dart';

class ApiService {
  static const String baseUrl = 'http://money_tracker_api.test/api';

  Future<List<TransactionModel>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/'),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200 || body['status'] == false) {
      throw Exception(body['message'] ?? 'Failed to load transactions');
    }

    final data = body['data'];

    if (data is! List) {
      throw Exception('Invalid transactions response from API');
    }

    return data
        .map(
          (item) => TransactionModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transaction.toJson()),
    );

    _ensureSuccess(response, 'Failed to save transaction');
  }

  Future<void> updateTransaction(
    TransactionModel transaction,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/${transaction.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(transaction.toJson()),
    );

    _ensureSuccess(response, 'Failed to update transaction');
  }

  Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
    );

    _ensureSuccess(response, 'Failed to delete transaction');
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  void _ensureSuccess(http.Response response, String message) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final body = _decodeResponse(response);

      if (body['status'] == false) {
        throw Exception(body['message'] ?? message);
      }

      return;
    }

    final body = _decodeResponse(response);
    throw Exception(body['message'] ?? '$message (${response.statusCode})');
  }
}
