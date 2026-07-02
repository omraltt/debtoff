import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/expense_log.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedDebtId;
  String _selectedCategory = 'Food';

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAddExpenseSheet(BuildContext context) {
    final provider = context.read<DebtProvider>();
    final debts = provider.debts;

    // Reset fields
    _amountController.clear();
    _descController.clear();
    _selectedCategory = 'Food';
    _selectedDebtId = debts.isNotEmpty ? debts.first.id : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff12122a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xff2a2a55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      provider.translate('add_expense'),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount input
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: provider.translate('expense_amount'),
                        labelStyle: const TextStyle(color: Color(0xff8888aa)),
                        prefixText: '${provider.profile?.currency ?? '₺'} ',
                        prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0x22ffffff)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xff3b82f6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Linked Card Selector Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDebtId,
                      dropdownColor: const Color(0xff12122a),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: provider.translate('select_debt'),
                        labelStyle: const TextStyle(color: Color(0xff8888aa)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0x22ffffff)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xff3b82f6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: debts.map((d) {
                        return DropdownMenuItem<String>(
                          value: d.id,
                          child: Text('${d.bank} ${d.type} (Borç: ${d.current.toStringAsFixed(0)} ${provider.profile?.currency})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          _selectedDebtId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: const Color(0xff12122a),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: provider.languageCode == 'tr' ? 'Kategori' : 'Category',
                        labelStyle: const TextStyle(color: Color(0xff8888aa)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0x22ffffff)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xff3b82f6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Food', child: Text(provider.translate('category_food'))),
                        DropdownMenuItem(value: 'Shopping', child: Text(provider.translate('category_shopping'))),
                        DropdownMenuItem(value: 'Cash', child: Text(provider.translate('category_cash'))),
                        DropdownMenuItem(value: 'Bills', child: Text(provider.translate('category_bills'))),
                        DropdownMenuItem(value: 'Other', child: Text(provider.translate('category_other'))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description input
                    TextField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: provider.translate('expense_desc'),
                        labelStyle: const TextStyle(color: Color(0xff8888aa)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0x22ffffff)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xff3b82f6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
                        if (amount <= 0 || _selectedDebtId == null) {
                          return;
                        }

                        final expense = ExpenseLog(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          debtId: _selectedDebtId!,
                          amount: amount,
                          date: DateTime.now(),
                          description: _descController.text.trim().isNotEmpty
                              ? _descController.text.trim()
                              : provider.translate('category_${_selectedCategory.toLowerCase()}'),
                          category: _selectedCategory,
                        );

                        provider.addExpense(expense);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xff10b981),
                            content: Text(
                              provider.translate('expense_added_success'),
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff3b82f6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        provider.languageCode == 'tr' ? 'Kaydet' : 'Save',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Cash':
        return Icons.atm;
      case 'Bills':
        return Icons.receipt;
      default:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xfff59e0b); // amber
      case 'Shopping':
        return const Color(0xffec4899); // pink
      case 'Cash':
        return const Color(0xff10b981); // emerald
      case 'Bills':
        return const Color(0xff3b82f6); // blue
      default:
        return const Color(0xff8b5cf6); // purple
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        // Calculate total spending this month
        final thisMonthExpenses = provider.expenses.where((e) {
          return e.date.month == now.month && e.date.year == now.year;
        }).toList();

        final totalThisMonth = thisMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
        final currency = provider.profile?.currency ?? '₺';

        return Scaffold(
          backgroundColor: const Color(0xff080815),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff1e1b4b), Color(0xff0f0f26)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xff2a2a55)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.languageCode == 'tr' ? 'BU AY YAPILAN HARCAMA' : 'SPENDING THIS MONTH',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff8888aa),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalThisMonth.toStringAsFixed(2)} $currency',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xffef4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  provider.languageCode == 'tr' ? 'Harcama Geçmişi' : 'Expense Log',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Expenses List
                Expanded(
                  child: provider.expenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xff2a2a55)),
                              const SizedBox(height: 16),
                              Text(
                                provider.languageCode == 'tr'
                                    ? 'Kayıtlı harcama bulunmuyor'
                                    : 'No expenses registered yet',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xff555577)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.languageCode == 'tr'
                                    ? 'Aşağıdaki + butonunu kullanarak kart harcaması ekleyin.'
                                    : 'Use the + button below to add an account transaction.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xff444466)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.expenses.length,
                          itemBuilder: (context, index) {
                            final e = provider.expenses[index];
                            // Find linked debt for bank name
                            final debt = provider.debts.firstWhere(
                              (d) => d.id == e.debtId,
                              orElse: () => Debt(
                                id: '',
                                bank: 'Bilinmeyen',
                                type: 'Hesap',
                                initial: 0,
                                current: 0,
                                rate: 0,
                                theme: 'default',
                                colorHex: '#8888aa',
                              ),
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xff12122a),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xff1f1f3a)),
                              ),
                              child: Row(
                                children: [
                                  // Category Icon Container
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(e.category).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(e.category),
                                      color: _getCategoryColor(e.category),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.description,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${debt.bank} ${debt.type}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xff8888aa),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Date & Amount & Delete Button
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '-${e.amount.toStringAsFixed(0)} $currency',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xffef4444),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${e.date.day}/${e.date.month}',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: const Color(0xff555577),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              // Show confirmation dialog before delete
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    backgroundColor: const Color(0xff12122a),
                                                    title: Text(
                                                      provider.translate('confirm_title'),
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                    content: Text(
                                                      provider.languageCode == 'tr'
                                                          ? 'Bu harcamayı silmek istiyor musunuz? İlgili kart borcu düşürülecektir.'
                                                          : 'Do you want to delete this expense? The linked balance will be reduced.',
                                                      style: const TextStyle(color: Color(0xff8888aa)),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: Text(provider.translate('confirm_cancel')),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          provider.deleteExpense(e.id);
                                                          Navigator.pop(context);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              backgroundColor: const Color(0xffef4444),
                                                              content: Text(
                                                                provider.translate('expense_deleted'),
                                                                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Text(
                                                          provider.translate('confirm_yes'),
                                                          style: const TextStyle(color: Colors.red),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: const Icon(
                                              Icons.delete_outline,
                                              color: Color(0xffef4444),
                                              size: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (provider.debts.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xffef4444),
                    content: Text(
                      provider.languageCode == 'tr'
                          ? 'Harcama eklemek için önce Borçlarım sekmesinden bir hesap eklemelisiniz.'
                          : 'You must add a debt account before registering expenses.',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
                return;
              }
              _showAddExpenseSheet(context);
            },
            backgroundColor: const Color(0xff3b82f6),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
