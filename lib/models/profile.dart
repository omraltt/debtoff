class UserProfile {
  final String name;
  final String? pinCode;
  final bool isPasscodeEnabled;
  final String currency;
  final bool hasCompletedOnboarding;
  final DateTime createdAt;
  final bool isPremium;
  final String? recoveryKey;
  final String languageCode;

  UserProfile({
    required this.name,
    this.pinCode,
    this.isPasscodeEnabled = false,
    this.currency = '₺',
    this.hasCompletedOnboarding = false,
    required this.createdAt,
    this.isPremium = false,
    this.recoveryKey,
    this.languageCode = 'tr',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pinCode': pinCode,
      'isPasscodeEnabled': isPasscodeEnabled,
      'currency': currency,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'createdAt': createdAt.toIso8601String(),
      'isPremium': isPremium,
      'recoveryKey': recoveryKey,
      'languageCode': languageCode,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? '',
      pinCode: map['pinCode'] as String?,
      isPasscodeEnabled: map['isPasscodeEnabled'] as bool? ?? false,
      currency: map['currency'] as String? ?? '₺',
      hasCompletedOnboarding: map['hasCompletedOnboarding'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      isPremium: map['isPremium'] as bool? ?? false,
      recoveryKey: map['recoveryKey'] as String?,
      languageCode: map['languageCode'] as String? ?? 'tr',
    );
  }

  UserProfile copyWith({
    String? name,
    String? pinCode,
    bool? isPasscodeEnabled,
    String? currency,
    bool? hasCompletedOnboarding,
    bool? isPremium,
    String? recoveryKey,
    String? languageCode,
  }) {
    return UserProfile(
      name: name ?? this.name,
      pinCode: pinCode ?? this.pinCode,
      isPasscodeEnabled: isPasscodeEnabled ?? this.isPasscodeEnabled,
      currency: currency ?? this.currency,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      createdAt: this.createdAt,
      isPremium: isPremium ?? this.isPremium,
      recoveryKey: recoveryKey ?? this.recoveryKey,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
