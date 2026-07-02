class Debt {
  final String id;
  final String bank;
  final String type; // 'Kredi Kartı', 'Ek Para', 'Kredi'
  final double initial;
  double current;
  final double rate; // Monthly interest rate (e.g., 4.0)
  final String theme; // Bank brand name for theme styling
  final String colorHex; // Custom bank brand hex color
  final double minPaymentRate; // Legal minimum payment rate (e.g. 0.20 or 0.40)
  final double? customMinPayment; // Specific asgari if override needed

  Debt({
    required this.id,
    required this.bank,
    required this.type,
    required this.initial,
    required this.current,
    required this.rate,
    required this.theme,
    required this.colorHex,
    this.minPaymentRate = 0.20,
    this.customMinPayment,
  });

  bool get isClosed => current <= 0;

  // Calculate the monthly legal minimum payment required
  double get minPayment {
    if (isClosed) return 0;
    if (type == 'Ek Para') {
      // Overdraft accounts (Ek Para/KMH) don't have a 20% legal minimum payment,
      // they just accrue monthly interest. We set minimum payment to 0 or estimated interest.
      return 0;
    }
    if (customMinPayment != null && customMinPayment! > 0) {
      return customMinPayment!;
    }
    return current * minPaymentRate;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bank': bank,
      'type': type,
      'initial': initial,
      'current': current,
      'rate': rate,
      'theme': theme,
      'colorHex': colorHex,
      'minPaymentRate': minPaymentRate,
      'customMinPayment': customMinPayment,
    };
  }

  factory Debt.fromMap(Map<dynamic, dynamic> map) {
    return Debt(
      id: map['id'] as String,
      bank: map['bank'] as String,
      type: map['type'] as String,
      initial: (map['initial'] as num).toDouble(),
      current: (map['current'] as num).toDouble(),
      rate: (map['rate'] as num).toDouble(),
      theme: map['theme'] as String,
      colorHex: map['colorHex'] as String,
      minPaymentRate: (map['minPaymentRate'] as num?)?.toDouble() ?? 0.20,
      customMinPayment: (map['customMinPayment'] as num?)?.toDouble(),
    );
  }

  Debt copyWith({
    double? current,
    double? customMinPayment,
  }) {
    return Debt(
      id: id,
      bank: bank,
      type: type,
      initial: initial,
      current: current ?? this.current,
      rate: rate,
      theme: theme,
      colorHex: colorHex,
      minPaymentRate: minPaymentRate,
      customMinPayment: customMinPayment ?? this.customMinPayment,
    );
  }
}
