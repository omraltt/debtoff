class PaymentLog {
  final String id;
  final String debtId;
  final String bank;
  final String type;
  final double amount;
  final DateTime date;
  final String action; // 'payment' or 'adjustment'
  final String note;

  PaymentLog({
    required this.id,
    required this.debtId,
    required this.bank,
    required this.type,
    required this.amount,
    required this.date,
    required this.action,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'bank': bank,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'action': action,
      'note': note,
    };
  }

  factory PaymentLog.fromMap(Map<dynamic, dynamic> map) {
    return PaymentLog(
      id: map['id'] as String,
      debtId: map['debtId'] as String,
      bank: map['bank'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      action: map['action'] as String,
      note: map['note'] as String,
    );
  }
}
