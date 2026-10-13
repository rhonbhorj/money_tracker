
class MonthlyBudgetModel {
  final int? id;
  final int userId;
  final String category;
  final double budgetAmount;
  final String budgetMonth;

  const MonthlyBudgetModel({
    this.id,
    required this.userId,
    required this.category,
    required this.budgetAmount,
    required this.budgetMonth,
  });

  factory MonthlyBudgetModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MonthlyBudgetModel(
      id: json['id'] == null
          ? null
          : int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      category: json['category'].toString(),
      budgetAmount: double.parse(
        json['budget_amount'].toString(),
      ),
      budgetMonth: json['budget_month'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category': category,
      'budget_amount': budgetAmount,
      'budget_month': budgetMonth,
    };
  }
}
