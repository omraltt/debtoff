import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt.dart';
import '../models/payment_log.dart';
import '../models/profile.dart';

class DatabaseService {
  static const String _debtsBoxName = 'debts_box';
  static const String _journalBoxName = 'journal_box';
  static const String _profileBoxName = 'profile_box';

  static Future<void> init() async {
    await Hive.initFlutter();
  }

  // Clear profile only once to force onboarding screen on next run
  static Future<void> clearProfileOnce() async {
    final box = await Hive.openBox(_profileBoxName);
    if (box.get('forced_reset_v2') != true) {
      await box.delete('user_profile');
      await box.put('forced_reset_v2', true);
    }
  }

  // Retrieve user profile
  static Future<UserProfile?> getProfile() async {
    final box = await Hive.openBox(_profileBoxName);
    final data = box.get('user_profile');
    if (data == null) return null;
    return UserProfile.fromMap(Map<dynamic, dynamic>.from(data as Map));
  }

  // Save user profile
  static Future<void> saveProfile(UserProfile profile) async {
    final box = await Hive.openBox(_profileBoxName);
    await box.put('user_profile', profile.toMap());
  }

  // Seed default debts if user loads demo
  static List<Debt> get _defaultDebts => [
        Debt(
          id: 'akbank-ep',
          bank: 'Akbank',
          type: 'Ek Para',
          initial: 22652,
          current: 22652,
          rate: 4.0,
          theme: 'akbank',
          colorHex: '#ef4444', // Akbank Red
        ),
        Debt(
          id: 'qnb-ep',
          bank: 'QNB',
          type: 'Ek Para',
          initial: 64305,
          current: 64305,
          rate: 4.0,
          theme: 'qnb',
          colorHex: '#a855f7', // QNB Purple
        ),
        Debt(
          id: 'enpara-ep',
          bank: 'Enpara',
          type: 'Ek Para',
          initial: 72961,
          current: 72961,
          rate: 4.0,
          theme: 'enpara',
          colorHex: '#f97316', // Enpara Orange
        ),
        Debt(
          id: 'qnb-kk',
          bank: 'QNB',
          type: 'Kredi Kartı',
          initial: 5000,
          current: 5000,
          rate: 3.5,
          theme: 'qnb',
          colorHex: '#a855f7',
        ),
        Debt(
          id: 'garanti-kk',
          bank: 'Garanti',
          type: 'Kredi Kartı',
          initial: 11000,
          current: 11000,
          rate: 3.5,
          theme: 'garanti',
          colorHex: '#10b981', // Garanti Green
        ),
        Debt(
          id: 'yapikredi-kk',
          bank: 'Yapı Kredi',
          type: 'Kredi Kartı',
          initial: 16974,
          current: 16974,
          rate: 3.5,
          theme: 'yapikredi',
          colorHex: '#3b82f6', // Yapı Kredi Blue
          customMinPayment: 3376, // confirmed by user
        ),
        Debt(
          id: 'akbank-kk',
          bank: 'Akbank',
          type: 'Kredi Kartı',
          initial: 21381,
          current: 21381,
          rate: 3.5,
          theme: 'akbank',
          colorHex: '#ef4444',
        ),
        Debt(
          id: 'enpara-kk',
          bank: 'Enpara',
          type: 'Kredi Kartı',
          initial: 43621,
          current: 43621,
          rate: 3.5,
          theme: 'enpara',
          colorHex: '#f97316',
        ),
      ];

  // Seed demo data (called manually from settings)
  static Future<List<Debt>> loadDemoDebts() async {
    final debtsBox = await Hive.openBox(_debtsBoxName);
    await debtsBox.clear();
    final defaults = _defaultDebts;
    for (final debt in defaults) {
      await debtsBox.put(debt.id, debt.toMap());
    }

    final journalBox = await Hive.openBox(_journalBoxName);
    await journalBox.clear();
    final List<PaymentLog> demoLogs = [
      PaymentLog(
        id: 'log-demo-1',
        debtId: 'yapikredi-kk',
        bank: 'Yapı Kredi',
        type: 'Kredi Kartı',
        amount: 3376,
        date: DateTime.now().subtract(const Duration(days: 12)),
        action: 'payment',
        note: 'Yapı Kredi asgari ödemesi yapıldı.',
      ),
      PaymentLog(
        id: 'log-demo-2',
        debtId: 'akbank-kk',
        bank: 'Akbank',
        type: 'Kredi Kartı',
        amount: 1500,
        date: DateTime.now().subtract(const Duration(days: 5)),
        action: 'payment',
        note: 'Akbank Kredi Kartı ara ödeme yapıldı.',
      )
    ];
    for (final log in demoLogs) {
      await journalBox.put(log.id, log.toMap());
    }

    return defaults;
  }

  // Retrieve all debts (empty by default if not seeded)
  static Future<List<Debt>> getDebts() async {
    final box = await Hive.openBox(_debtsBoxName);
    return box.values
        .map((value) => Debt.fromMap(value as Map<dynamic, dynamic>))
        .toList();
  }

  // Save single/multiple debts
  static Future<void> saveDebts(List<Debt> debts) async {
    final box = await Hive.openBox(_debtsBoxName);
    for (final debt in debts) {
      await box.put(debt.id, debt.toMap());
    }
  }

  // Clear and reseed all debts
  static Future<void> resetAll() async {
    final debtsBox = await Hive.openBox(_debtsBoxName);
    await debtsBox.clear();
    
    final journalBox = await Hive.openBox(_journalBoxName);
    await journalBox.clear();

    final profileBox = await Hive.openBox(_profileBoxName);
    await profileBox.clear();
  }

  // Retrieve journal payment logs
  static Future<List<PaymentLog>> getJournal() async {
    final box = await Hive.openBox(_journalBoxName);
    final list = box.values
        .map((value) => PaymentLog.fromMap(value as Map<dynamic, dynamic>))
        .toList();
    // Sort with most recent logs first
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // Add journal entry
  static Future<void> addJournalEntry(PaymentLog log) async {
    final box = await Hive.openBox(_journalBoxName);
    await box.put(log.id, log.toMap());
  }

  // Delete journal entry
  static Future<void> deleteJournalEntry(String logId) async {
    final box = await Hive.openBox(_journalBoxName);
    await box.delete(logId);
  }

  // JSON Data Backup Export
  static Future<String> exportData() async {
    final debtsBox = await Hive.openBox(_debtsBoxName);
    final journalBox = await Hive.openBox(_journalBoxName);
    final profileBox = await Hive.openBox(_profileBoxName);

    final List<Map<String, dynamic>> debtsList = debtsBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final List<Map<String, dynamic>> journalList = journalBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    
    final profileData = profileBox.get('user_profile');
    final Map<String, dynamic>? profileMap = profileData != null 
        ? Map<String, dynamic>.from(profileData as Map) 
        : null;

    final data = {
      'debts': debtsList,
      'journal': journalList,
      'profile': profileMap,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    return jsonEncode(data);
  }

  // JSON Data Backup Import
  static Future<void> importData(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;

    final debtsBox = await Hive.openBox(_debtsBoxName);
    final journalBox = await Hive.openBox(_journalBoxName);
    final profileBox = await Hive.openBox(_profileBoxName);

    await debtsBox.clear();
    await journalBox.clear();
    await profileBox.clear();

    if (data.containsKey('debts')) {
      final List debts = data['debts'] as List;
      for (final d in debts) {
        final map = Map<String, dynamic>.from(d as Map);
        await debtsBox.put(map['id'], map);
      }
    }

    if (data.containsKey('journal')) {
      final List journal = data['journal'] as List;
      for (final j in journal) {
        final map = Map<String, dynamic>.from(j as Map);
        await journalBox.put(map['id'], map);
      }
    }

    if (data.containsKey('profile') && data['profile'] != null) {
      final profileMap = Map<String, dynamic>.from(data['profile'] as Map);
      await profileBox.put('user_profile', profileMap);
    }
  }
}
