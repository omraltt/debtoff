import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';

class AiSplitterTab extends StatefulWidget {
  const AiSplitterTab({super.key});

  @override
  State<AiSplitterTab> createState() => _AiSplitterTabState();
}

class _AiSplitterTabState extends State<AiSplitterTab> {
  final _budgetController = TextEditingController();
  String _method = 'avalanche'; // 'avalanche' or 'snowball'
  Map<String, double>? _simulationResult;
  bool _hasSimulated = false;
  bool _isCalculating = false;
  String _calculationStepText = '';

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        // Calculate the sum of current card minimums to show the user as a reference
        final double totalMinRequired = provider.debts
            .where((d) => d.type == 'Kredi Kartı' && d.current > 0)
            .fold(0.0, (sum, d) => sum + d.minPayment);

        final String currency = provider.profile?.currency ?? '₺';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AI Splitter Welcome Panel
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff1e1b4b), Color(0xff0f0f26)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x333b82f6), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: Color(0xff3b82f6), size: 28),
                        const SizedBox(width: 12),
                        Text(
                          provider.translate('ai_splitter'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.translate('ai_splitter_desc'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xff94a3b8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Inputs Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff12122a),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x11ffffff), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        ThousandSeparatorFormatter(),
                      ],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '${provider.translate('monthly_budget_label')} ($currency)',
                        labelStyle: const TextStyle(color: Color(0xff8888aa)),
                        suffixIcon: const Icon(Icons.wallet, color: Color(0xff3b82f6)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0x22ffffff)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xff3b82f6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (val) {
                        if (_hasSimulated) {
                          setState(() {
                            _hasSimulated = false;
                            _simulationResult = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Method Selector
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _method = 'avalanche';
                                if (_hasSimulated) _simulate(provider);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _method == 'avalanche'
                                    ? const Color(0x223b82f6)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _method == 'avalanche'
                                      ? const Color(0xff3b82f6)
                                      : const Color(0x22ffffff),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.flash_on, color: Color(0xff3b82f6), size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    provider.translate('avalanche_title'),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    provider.translate('avalanche_sub'),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: const Color(0xff8888aa),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _method = 'snowball';
                                if (_hasSimulated) _simulate(provider);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _method == 'snowball'
                                    ? const Color(0x22a855f7)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _method == 'snowball'
                                      ? const Color(0xffa855f7)
                                      : const Color(0x22ffffff),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.filter_hdr, color: Color(0xffa855f7), size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    provider.translate('snowball_title'),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    provider.translate('snowball_sub'),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: const Color(0xff8888aa),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () => _simulate(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff3b82f6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        provider.translate('calculate_btn'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isCalculating)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xff12122a),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x333b82f6), width: 1),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xff3b82f6)),
                      const SizedBox(height: 20),
                      Text(
                        provider.translate('simulate_calculating'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _calculationStepText,
                          key: ValueKey(_calculationStepText),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xff8888aa),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Simulation Results
              if (_hasSimulated && _simulationResult != null && !_isCalculating)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, animVal, child) {
                    return Transform.translate(
                      offset: Offset(0.0, 20.0 * (1.0 - animVal)),
                      child: Opacity(
                        opacity: animVal,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Warning Alert if budget doesn't cover legal card minimums
                      if (double.tryParse(_budgetController.text)! < totalMinRequired)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x22eab308),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xaaeab308), width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xffeab308), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.translate('insufficient_budget'),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xffeab308),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      provider.translate('insufficient_budget_sub')
                                          .replaceAll('{min}', _formatMoney(totalMinRequired))
                                          .replaceAll('{curr}', currency),
                                      style: GoogleFonts.inter(
                                        color: const Color(0xfffef08a),
                                        fontSize: 11,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      Text(
                        '📋 AI Dağıtım Planı Önizlemesi',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.debts.length,
                  itemBuilder: (context, index) {
                    final debt = provider.debts[index];
                    final double allocated = _simulationResult![debt.id] ?? 0.0;
                    if (allocated <= 0 && debt.current <= 0) return const SizedBox();

                    final Color themeColor = _parseHexColor(debt.colorHex);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xff12122a),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x11ffffff), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${debt.bank} - ${debt.type}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    debt.current <= 0
                                        ? 'Borç Kapanmış'
                                        : allocated >= debt.current
                                            ? 'Borç Tamamen Kapanıyor!'
                                            : 'Kalan: ${_formatMoney(debt.current - allocated)} $currency',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: allocated >= debt.current && debt.current > 0
                                          ? const Color(0xff10b981)
                                          : const Color(0xff64748b),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_formatMoney(allocated)} $currency',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: allocated > 0
                                      ? const Color(0xff10b981)
                                      : const Color(0xff555577),
                                ),
                              ),
                              if (allocated > 0 && debt.type == 'Kredi Kartı')
                                Text(
                                  allocated >= debt.minPayment ? 'Asgari Ödendi' : 'Asgari Eksik',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: allocated >= debt.minPayment
                                        ? const Color(0xff94a3b8)
                                        : const Color(0xffef4444),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Apply button
                ElevatedButton(
                  onPressed: () => _applyPayments(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff10b981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    provider.translate('apply_payments_btn'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  void _simulate(DebtProvider provider) async {
    final cleanText = _budgetController.text.replaceAll('.', '').replaceAll(',', '');
    final double? budget = double.tryParse(cleanText);
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xffef4444),
          content: Text(
            provider.translate('enter_budget_error'),
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _hasSimulated = false;
      _calculationStepText = provider.translate('simulate_avalanche');
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _calculationStepText = provider.translate('simulate_allocating');
    });

    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    setState(() {
      _calculationStepText = provider.translate('simulate_done');
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _isCalculating = false;
      _simulationResult = provider.calculateOptimalSplitting(budget, _method);
      _hasSimulated = true;
    });
  }

  void _applyPayments(BuildContext context, DebtProvider provider) {
    if (_simulationResult == null) return;

    HapticFeedback.heavyImpact();
    
    final currentMonthName = _getMonthName();

    provider.applyOptimalSplitting(
      _simulationResult!,
      DateTime.now(),
      currentMonthName,
    );
    provider.triggerConfetti();

    // Reset fields
    setState(() {
      _budgetController.clear();
      _hasSimulated = false;
      _simulationResult = null;
    });

    // Show satisfying dialog celebration
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xff12122a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.stars, color: Color(0xff10b981), size: 28),
              const SizedBox(width: 12),
              Text(
                provider.translate('congratulations'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          content: Text(
            provider.translate('payments_applied_msg'),
            style: GoogleFonts.inter(color: const Color(0xff94a3b8), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                provider.translate('continue'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xff3b82f6)),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getMonthName() {
    final now = DateTime.now();
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${months[now.month - 1]} ${now.year}';
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

  String _formatMoney(double num) {
    return num.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final String clean = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    final double? number = double.tryParse(clean);
    if (number == null) return oldValue;

    final String formatted = number.round().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
