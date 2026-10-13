import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/monthly_budget_model.dart';

class BudgetApiService {
  static const String baseUrl =
      'http://money_tracker_api.test/api';

  /// Get budgets for a specific user and month.
  Future<List<MonthlyBudgetModel>> getBudgets({
    required int userId,
    required String budgetMonth,
  }) async {
    final uri = Uri.parse('$baseUrl/monthly-budgets').replace(
      queryParameters: {
        'user_id': userId.toString(),
        'budget_month': budgetMonth,
      },
    );

    final response = await http.get(uri);
    final body = _decodeResponse(response);

    _checkResponse(response, body);

    final data = body['data'];

    if (data is! List) {
      throw Exception('Invalid budgets response from API.');
    }

    return data.map((item) {
      return MonthlyBudgetModel.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
    }).toList();
  }

  /// Create a budget, or update the existing category/month budget.
  Future<void> saveBudget(MonthlyBudgetModel budget) async {
    final response = await http.post(
      Uri.parse('$baseUrl/monthly-budgets'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(budget.toJson()),
    );

    final body = _decodeResponse(response);
    _checkResponse(response, body);
  }

  /// Update a budget using its ID.
  Future<void> updateBudget(MonthlyBudgetModel budget) async {
    if (budget.id == null) {
      throw Exception('A budget ID is required to update a budget.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/monthly-budgets/${budget.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(budget.toJson()),
    );

    final body = _decodeResponse(response);
    _checkResponse(response, body);
  }

  /// Delete a budget.
  Future<void> deleteBudget({
    required int budgetId,
    required int userId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/monthly-budgets/$budgetId',
    ).replace(
      queryParameters: {
        'user_id': userId.toString(),
      },
    );

    final response = await http.delete(uri);
    final body = _decodeResponse(response);

    _checkResponse(response, body);
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

  void _checkResponse(
    http.Response response,
    Map<String, dynamic> body,
  ) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body['status'] != false) {
      return;
    }

    throw Exception(
      body['message'] ??
          'Budget API request failed (${response.statusCode}).',
    );
  }
}