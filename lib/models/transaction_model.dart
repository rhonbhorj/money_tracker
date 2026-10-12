
class TransactionModel {
  final int id;
  final String type;
  final String category;
  final double amount;
  final String transactionDate;
  final String? note;

  TransactionModel({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.transactionDate,
    this.note,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: int.parse(json['id'].toString()),
      type: json['type'].toString(),
      category: json['category'].toString(),
      amount: double.parse(json['amount'].toString()),
      transactionDate: json['transaction_date'].toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'category': category,
      'amount': amount,
      'transaction_date': transactionDate,
      'note': note,
    };
  }
}
