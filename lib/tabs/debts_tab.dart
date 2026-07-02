import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../models/debt.dart';
import '../services/database_service.dart';
import '../screens/premium_screen.dart';
import '../utils/color_utils.dart';

class DebtsTab extends StatefulWidget {
  const DebtsTab({super.key});

  @override
  State<DebtsTab> createState() => _DebtsTabState();
}

class _DebtsTabState extends State<DebtsTab> {
  final _payAmountController = TextEditingController();
  final _payNoteController = TextEditingController();

  final _adjustBalanceController = TextEditingController();
  final _adjustNoteController = TextEditingController();

  final _newBankController = TextEditingController();
  final _newInitialController = TextEditingController();
  final _newRateController = TextEditingController();
  final _newMinPaymentController = TextEditingController();
  String _newType = 'Kredi Kartı';

  @override
  void dispose() {
    _payAmountController.dispose();
    _payNoteController.dispose();
    _adjustBalanceController.dispose();
    _adjustNoteController.dispose();
    _newBankController.dispose();
    _newInitialController.dispose();
    _newRateController.dispose();
    _newMinPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (provider.debts.length >= 2 && !provider.isPremium) {
                _showLimitReachedDialog(context, provider);
              } else {
                _showAddDebtModal(context, provider);
              }
            },
            backgroundColor: const Color(0xff3b82f6),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.debts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.credit_card_off_outlined,
                              color: Color(0xff555577),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Borç Listeniz Boş',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Takip edilecek kart veya artı para hesabı bulunamadı.\nİlk borcunuzu eklemek için sağ alttaki "+" butonuna tıklayın.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: const Color(0xff8888aa),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: provider.debts.length,
                      itemBuilder: (context, index) {
                        final debt = provider.debts[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, animValue, child) {
                            return Transform.translate(
                              offset: Offset(0.0, 20.0 * (1.0 - animValue)),
                              child: Opacity(
                                opacity: animValue,
                                child: child,
                              ),
                            );
                          },
                          child: _buildDebtCard(context, debt, provider),
                        );
                      },
                    ),
        );
      },
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt, DebtProvider provider) {
    final Color cardColor = getBankBrandColor(debt.bank, _parseHexColor(debt.colorHex));
    final double paid = debt.initial - debt.current;
    final double pct = debt.initial > 0 ? (paid / debt.initial) * 100 : 0.0;
    final bool isClosed = debt.isClosed;
    final String currency = provider.profile?.currency ?? '₺';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xff12122a),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClosed ? const Color(0x3310b981) : const Color(0x11ffffff),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isClosed ? const Color(0x0510b981) : Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Color pill top highlight
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(color: cardColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            debt.type == 'Kredi Kartı'
                                ? Icons.credit_card
                                : Icons.account_balance_wallet,
                            color: cardColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debt.bank,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              debt.type,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xff8888aa),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isClosed
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x2210b981),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xaa10b981), width: 0.5),
                            ),
                            child: Text(
                              'KAPANDI',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xff10b981),
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x11ffffff),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Faiz: %${debt.rate.toStringAsFixed(1)}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff94a3b8),
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 16),

                // Middle Row: Values
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Güncel Borç',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xff64748b),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isClosed ? '0 $currency' : '${_formatMoney(debt.current)} $currency',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isClosed ? const Color(0xff10b981) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Başlangıç: ${_formatMoney(debt.initial)} $currency',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xff555577),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        if (debt.type == 'Kredi Kartı' && !isClosed)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Min. Ödeme: ${_formatMoney(debt.minPayment)} $currency',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xffeab308),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 6,
                        backgroundColor: const Color(0xff1a1a38),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isClosed ? const Color(0xff10b981) : cardColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '%${pct.toStringAsFixed(0)} ödendi',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xff64748b),
                          ),
                        ),
                        Text(
                          'Kalan: ${_formatMoney(debt.current)} $currency',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xff64748b),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bottom Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isClosed)
                      TextButton.icon(
                        onPressed: () => _showPayModal(context, debt, provider),
                        icon: const Icon(Icons.payment, size: 16, color: Color(0xff3b82f6)),
                        label: Text(
                          'Ödeme Ekle',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff3b82f6),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _showAdjustModal(context, debt, provider),
                      icon: const Icon(Icons.edit_note, size: 16, color: Color(0xff94a3b8)),
                      label: Text(
                        'Bakiyeyi Eşitle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff94a3b8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Pay bottom sheet
  void _showPayModal(BuildContext context, Debt debt, DebtProvider provider) {
    _payAmountController.clear();
    _payNoteController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0f0f26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final String currency = provider.profile?.currency ?? '₺';
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${debt.bank} Ödemesi Kaydet',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _payAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Ödeme Tutarı ($currency)',
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
              const SizedBox(height: 12),
              TextField(
                controller: _payNoteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Açıklama / Not',
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(_payAmountController.text);
                  if (amt == null || amt <= 0) return;

                  HapticFeedback.lightImpact();
                  provider.addPayment(
                    debt.id,
                    amt,
                    DateTime.now(),
                    _payNoteController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3b82f6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Ödemeyi Günlüğe İşle',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // Adjust Balance bottom sheet
  void _showAdjustModal(BuildContext context, Debt debt, DebtProvider provider) {
    _adjustBalanceController.text = debt.current.round().toString();
    _adjustNoteController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0f0f26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final String currency = provider.profile?.currency ?? '₺';
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${debt.bank} Bakiyesini Eşitle',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ekstrenizdeki güncel faiz veya harcama tutarına göre borç bakiyesini doğrudan senkronize edin.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xff8888aa), height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _adjustBalanceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Güncel Ekstre Borcu ($currency)',
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
              const SizedBox(height: 12),
              TextField(
                controller: _adjustNoteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Düzeltme Nedeni (Örn: Faiz yansıdı)',
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(_adjustBalanceController.text);
                  if (amt == null || amt < 0) return;

                  HapticFeedback.lightImpact();
                  provider.adjustBalance(
                    debt.id,
                    amt,
                    DateTime.now(),
                    _adjustNoteController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffa855f7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Bakiyeyi Eşitle ve Günlüğe Yaz',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // Add Custom Debt bottom sheet
  void _showAddDebtModal(BuildContext context, DebtProvider provider) {
    final String currency = provider.profile?.currency ?? '₺';
    _newBankController.clear();
    _newInitialController.clear();
    _newRateController.text = '3.5';
    _newMinPaymentController.clear();
    _newType = 'Kredi Kartı';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0f0f26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Yeni Borç Hesabı Ekle',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Debt Type Selector
                  DropdownButtonFormField<String>(
                    value: _newType,
                    dropdownColor: const Color(0xff0f0f26),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Borç Türü',
                      labelStyle: const TextStyle(color: Color(0xff8888aa)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0x22ffffff)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['Kredi Kartı', 'Ek Para', 'Kredi'].map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          _newType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _newBankController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Banka Adı (Örn: Akbank)',
                      labelStyle: const TextStyle(color: Color(0xff8888aa)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0x22ffffff)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newInitialController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Toplam Borç ($currency)',
                            labelStyle: const TextStyle(color: Color(0xff8888aa)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0x22ffffff)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _newRateController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Aylık Faiz Oranı (%)',
                            labelStyle: const TextStyle(color: Color(0xff8888aa)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0x22ffffff)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_newType == 'Kredi Kartı')
                    TextField(
                      controller: _newMinPaymentController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Asgari Ödeme (İsteğe Bağlı - $currency)',
                        labelStyle: const TextStyle(color: Color(0xff8888aa)),
                        helperText: 'Belirtmezseniz otomatik %20 hesaplanır.',
                        helperStyle: const TextStyle(color: Color(0xff555577)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0x22ffffff)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final bank = _newBankController.text.trim();
                      final initial = double.tryParse(_newInitialController.text);
                      final rate = double.tryParse(_newRateController.text) ?? 3.5;
                      final customMin = double.tryParse(_newMinPaymentController.text);

                      if (bank.isEmpty || initial == null || initial <= 0) {
                        return;
                      }

                      // Deduce colors
                      String colorHex = '#64748b'; // default grey
                      final lowerBank = bank.toLowerCase();
                      if (lowerBank.contains('akbank')) {
                        colorHex = '#ef4444';
                      } else if (lowerBank.contains('qnb')) {
                        colorHex = '#a855f7';
                      } else if (lowerBank.contains('enpara')) {
                        colorHex = '#f97316';
                      } else if (lowerBank.contains('garanti')) {
                        colorHex = '#10b981';
                      } else if (lowerBank.contains('yapı') || lowerBank.contains('yapi')) {
                        colorHex = '#3b82f6';
                      }

                      final newDebt = Debt(
                        id: 'debt-${DateTime.now().microsecondsSinceEpoch}',
                        bank: bank,
                        type: _newType,
                        initial: initial,
                        current: initial,
                        rate: rate,
                        theme: lowerBank,
                        colorHex: colorHex,
                        customMinPayment: _newType == 'Kredi Kartı' ? customMin : null,
                      );

                      provider.debts.add(newDebt);
                      DatabaseService.saveDebts(provider.debts);
                      provider.loadData(); // reload UI
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff3b82f6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Borç Hesabını Kaydet',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xff64748b);
    }
  }

  void _showLimitReachedDialog(BuildContext context, DebtProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff12122a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xffeab308), size: 24),
              const SizedBox(width: 12),
              Text(
                provider.translate('limit_reached_title'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Text(
            provider.translate('limit_reached_sub'),
            style: GoogleFonts.inter(color: const Color(0xff94a3b8), fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                provider.translate('cancel'),
                style: GoogleFonts.inter(color: const Color(0xff94a3b8)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PremiumScreen()),
                );
              },
              child: Text(
                provider.translate('upgrade_premium'),
                style: GoogleFonts.inter(color: const Color(0xffeab308), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatMoney(double num) {
    return num.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
