class ExpenseLog {
  final String id;
  final String debtId;
  final double amount;
  final DateTime date;
  final String description;
  final String category;

  ExpenseLog({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    required this.description,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'category': category,
    };
  }

  factory ExpenseLog.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseLog(
      id: map['id'] as String? ?? '',
      debtId: map['debtId'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0.0).toDouble(),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
    );
  }
}
