import 'package:flutter/foundation.dart';
import '../models/debt.dart';
import '../models/payment_log.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../services/localization_service.dart';

class DebtProvider extends ChangeNotifier {
  List<Debt> _debts = [];
  List<PaymentLog> _journal = [];
  UserProfile? _profile;
  bool _isLoading = false;

  List<Debt> get debts => _debts;
  List<PaymentLog> get journal => _journal;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  bool _showConfetti = false;
  bool get showConfetti => _showConfetti;

  void triggerConfetti() {
    _showConfetti = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _showConfetti = false;
      notifyListeners();
    });
  }

  String get languageCode => _profile?.languageCode ?? 'tr';
  bool get isPremium => _profile?.isPremium ?? false;

  String translate(String key) {
    return LocalizationService.translate(languageCode, key);
  }

  Future<void> setLanguage(String langCode) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(languageCode: langCode);
      await DatabaseService.saveProfile(_profile!);
      notifyListeners();
    }
  }

  Future<void> setPremium(bool val) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(isPremium: val);
      await DatabaseService.saveProfile(_profile!);
      notifyListeners();
    }
  }

  double get totalDebt => _debts.fold(0.0, (sum, d) => sum + d.current);
  double get totalInitialDebt => _debts.fold(0.0, (sum, d) => sum + d.initial);
  double get totalPaid => _journal
      .where((log) => log.action == 'payment')
      .fold(0.0, (sum, log) => sum + log.amount);

  double get progressPercentage {
    if (totalInitialDebt == 0) return 0.0;
    final progress = ((totalInitialDebt - totalDebt) / totalInitialDebt) * 100;
    return progress < 0 ? 0.0 : progress;
  }

  // Load debts, logs, and profile from Hive
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _debts = await DatabaseService.getDebts();
      _journal = await DatabaseService.getJournal();
      _profile = await DatabaseService.getProfile();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save/Update user profile
  Future<void> saveProfile(UserProfile newProfile) async {
    _profile = newProfile;
    await DatabaseService.saveProfile(newProfile);
    notifyListeners();
  }

  // Seed demo data manually
  Future<void> loadDemoData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _debts = await DatabaseService.loadDemoDebts();
      _journal = await DatabaseService.getJournal();
      
      // Keep profile name if it exists, otherwise set a default
      if (_profile == null) {
        _profile = UserProfile(
          name: 'Demo Kullanıcı',
          hasCompletedOnboarding: true,
          createdAt: DateTime.now(),
        );
        await DatabaseService.saveProfile(_profile!);
      } else {
        _profile = _profile!.copyWith(hasCompletedOnboarding: true);
        await DatabaseService.saveProfile(_profile!);
      }
    } catch (e) {
      debugPrint('Error loading demo data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Backup data
  Future<String> exportBackup() async {
    return await DatabaseService.exportData();
  }

  // Restore data
  Future<void> importBackup(String jsonString) async {
    _isLoading = true;
    notifyListeners();
    try {
      await DatabaseService.importData(jsonString);
      await loadData();
    } catch (e) {
      debugPrint('Error importing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate dynamic checklist based on actual user debts
  List<Map<String, dynamic>> getChecklistForMonth(String monthName) {
    final List<Map<String, dynamic>> tasks = [];

    // 1. Credit Card Legal Minimum Payments (High Priority)
    final activeCards = _debts.where((d) => d.type == 'Kredi Kartı' && d.current > 0).toList();
    for (final card in activeCards) {
      final double ratio = card.initial > 0 ? (card.current / card.initial) : 1.0;
      final double scaledMin = card.minPayment * ratio;
      final double minVal = (scaledMin > card.current) ? card.current : scaledMin;

      if (minVal > 0) {
        tasks.add({
          'id': card.id,
          'amount': minVal,
          'labelKey': 'card_min_payment_task',
          'isMin': true,
        });
      }
    }

    // 2. Clear highest-interest overdraft accounts (KMH/Ek Para)
    final overdrafts = _debts.where((d) => d.type == 'Ek Para' && d.current > 0).toList();
    if (overdrafts.isNotEmpty) {
      overdrafts.sort((a, b) => b.rate.compareTo(a.rate));
      final target = overdrafts.first;
      tasks.add({
        'id': target.id,
        'amount': target.current,
        'labelKey': 'overdraft_clear_task',
        'isMin': false,
      });
    }

    // 3. If there are no debts, show a success task
    if (tasks.isEmpty && _debts.isNotEmpty) {
      tasks.add({
        'id': 'free',
        'amount': 0.0,
        'labelKey': 'free_tasks_done',
        'isMin': false,
      });
    }

    return tasks;
  }

  // Log a payment
  Future<void> addPayment(String debtId, double amount, DateTime date, String note) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1) return;

    final debt = _debts[index];
    final actualPaid = amount > debt.current ? debt.current : amount;

    if (actualPaid <= 0) return;

    // Update debt object
    final updatedDebt = debt.copyWith(current: debt.current - actualPaid);
    _debts[index] = updatedDebt;

    // Log transaction
    final log = PaymentLog(
      id: 'log-${DateTime.now().microsecondsSinceEpoch}',
      debtId: debtId,
      bank: debt.bank,
      type: debt.type,
      amount: actualPaid,
      date: date,
      action: 'payment',
      note: note.isEmpty ? '${debt.bank} ${debt.type} borcuna ödeme' : note,
    );

    _journal.insert(0, log);

    // Persist
    await DatabaseService.saveDebts(_debts);
    await DatabaseService.addJournalEntry(log);

    notifyListeners();
  }

  // Edit / adjust balance directly
  Future<void> adjustBalance(String debtId, double newBalance, DateTime date, String note) async {
    final index = _debts.indexWhere((d) => d.id == debtId);
    if (index == -1) return;

    final debt = _debts[index];
    final oldBalance = debt.current;
    final diff = newBalance - oldBalance;

    if (diff == 0) return;

    // Update debt
    final updatedDebt = debt.copyWith(current: newBalance);
    _debts[index] = updatedDebt;

    final actionText = diff > 0 ? 'Eklenme (+)' : 'Düşürülme (-)';
    final log = PaymentLog(
      id: 'log-${DateTime.now().microsecondsSinceEpoch}',
      debtId: debtId,
      bank: debt.bank,
      type: debt.type,
      amount: diff.abs(),
      date: date,
      action: 'adjustment',
      note: note.isEmpty
          ? 'Bakiye düzeltildi. Eski: ${oldBalance.toStringAsFixed(0)} ₺ → Yeni: ${newBalance.toStringAsFixed(0)} ₺ ($actionText)'
          : note,
    );

    _journal.insert(0, log);

    // Persist
    await DatabaseService.saveDebts(_debts);
    await DatabaseService.addJournalEntry(log);

    notifyListeners();
  }

  // Revert/Delete timeline journal entry
  Future<void> deleteJournalEntry(String logId) async {
    final index = _journal.indexWhere((log) => log.id == logId);
    if (index == -1) return;

    final log = _journal[index];
    
    // If it was a payment, revert the balance back (add it back to current)
    if (log.action == 'payment') {
      final debtIndex = _debts.indexWhere((d) => d.id == log.debtId);
      if (debtIndex != -1) {
        final debt = _debts[debtIndex];
        _debts[debtIndex] = debt.copyWith(current: debt.current + log.amount);
        await DatabaseService.saveDebts(_debts);
      }
    }

    _journal.removeAt(index);
    await DatabaseService.deleteJournalEntry(logId);

    notifyListeners();
  }

  // Add a new debt manually
  Future<void> addDebt(Debt debt) async {
    _debts.add(debt);
    await DatabaseService.saveDebts(_debts);
    notifyListeners();
  }

  // Reset database back to default state
  Future<void> resetData() async {
    _isLoading = true;
    notifyListeners();

    await DatabaseService.resetAll();
    _debts = [];
    _journal = [];
    _profile = null;
    
    _isLoading = false;
    notifyListeners();
  }

  // AI ÖDEME BÖLÜCÜ ALGORİTMASI (Auto-Splitting algorithm)
  // Splits monthly budget logically:
  // 1. Cover all legal minimum payments for credit cards first.
  // 2. Distribute remaining budget to debts based on method (avalanche/snowball).
  Map<String, double> calculateOptimalSplitting(double budget, String method) {
    final Map<String, double> distribution = {};
    
    // Initialize allocations to 0
    for (final d in _debts) {
      distribution[d.id] = 0.0;
    }

    if (budget <= 0) return distribution;

    double remainingBudget = budget;

    // Step 1: Collect and allocate legal minimum payments for Kredi Kartı accounts
    // (KMH/Ek Para doesn't have 20% legal minimum payment constraints, they just accrue interest)
    final activeCards = _debts.where((d) => d.type == 'Kredi Kartı' && d.current > 0).toList();
    
    // Sort cards to pay the smaller minimum payments first, in case budget is extremely tight
    activeCards.sort((a, b) => a.minPayment.compareTo(b.minPayment));

    for (final card in activeCards) {
      final minReq = card.minPayment;
      if (minReq > 0) {
        if (remainingBudget >= minReq) {
          distribution[card.id] = minReq;
          remainingBudget -= minReq;
        } else {
          // If the budget is not even enough to pay the minimum of this card, put all the remaining budget
          distribution[card.id] = remainingBudget;
          remainingBudget = 0.0;
          break;
        }
      }
    }

    if (remainingBudget <= 0) {
      return distribution;
    }

    // Step 2: Distribute remaining budget among remaining balances
    // Create temporary balance tracking list
    final List<Map<String, dynamic>> tempDebts = _debts
        .where((d) => d.current > 0)
        .map((d) => {
              'id': d.id,
              'rate': d.rate,
              'initialBalance': d.current,
              // Kalan borç = Toplam Borç - Asgari olarak ayrılan tutar
              'remainingBalance': d.current - (distribution[d.id] ?? 0.0),
            })
        .where((temp) => (temp['remainingBalance'] as double) > 0.0)
        .toList();

    if (tempDebts.isEmpty) {
      return distribution;
    }

    // Sort according to preferred method
    if (method == 'avalanche') {
      // Avalanche (Çığ): Sort by interest rate descending, then by remaining balance descending
      tempDebts.sort((a, b) {
        final rateCompare = (b['rate'] as double).compareTo(a['rate'] as double);
        if (rateCompare != 0) return rateCompare;
        return (b['remainingBalance'] as double).compareTo(a['remainingBalance'] as double);
      });
    } else {
      // Snowball (Kartopu): Sort by remaining balance ascending (kill smaller debts first)
      tempDebts.sort((a, b) => (a['remainingBalance'] as double).compareTo(b['remainingBalance'] as double));
    }

    // Distribute remaining budget
    for (final temp in tempDebts) {
      if (remainingBudget <= 0) break;

      final id = temp['id'] as String;
      final remBal = temp['remainingBalance'] as double;

      if (remainingBudget >= remBal) {
        // We can pay off this entire remaining balance
        distribution[id] = (distribution[id] ?? 0.0) + remBal;
        remainingBudget -= remBal;
      } else {
        // Pay as much as we have left
        distribution[id] = (distribution[id] ?? 0.0) + remainingBudget;
        remainingBudget = 0.0;
        break;
      }
    }

    return distribution;
  }

  // Apply simulated split payments to database in bulk
  Future<void> applyOptimalSplitting(Map<String, double> distribution, DateTime date, String monthName) async {
    for (final entry in distribution.entries) {
      final debtId = entry.key;
      final amount = entry.value;
      
      if (amount > 0) {
        final debt = _debts.firstWhere((d) => d.id == debtId);
        final note = '[AI Ödeme Bölücü] $monthName ayı otomatik dağıtımla ödendi.';
        
        final index = _debts.indexWhere((d) => d.id == debtId);
        if (index == -1) continue;

        // Apply payment
        final actualPaid = amount > debt.current ? debt.current : amount;
        _debts[index] = debt.copyWith(current: debt.current - actualPaid);

        // Add log
        final log = PaymentLog(
          id: 'log-${DateTime.now().microsecondsSinceEpoch}-${debtId}',
          debtId: debtId,
          bank: debt.bank,
          type: debt.type,
          amount: actualPaid,
          date: date,
          action: 'payment',
          note: note,
        );
        
        _journal.insert(0, log);
        await DatabaseService.addJournalEntry(log);
      }
    }

    await DatabaseService.saveDebts(_debts);
    notifyListeners();
  }
}
