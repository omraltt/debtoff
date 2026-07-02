import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/debt_provider.dart';
import '../models/payment_log.dart';

class JournalTab extends StatefulWidget {
  const JournalTab({super.key});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  String _filterType = 'all'; // 'all', 'month', 'range'
  String? _selectedMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        final journal = provider.journal;
        final String currency = provider.profile?.currency ?? '₺';
        final bool isTr = provider.languageCode == 'tr';

        // 1. Extract dynamic months present in the journal logs
        final List<String> availableMonths = journal.map((log) {
          return DateFormat('MMMM y', isTr ? 'tr_TR' : 'en_US').format(log.date);
        }).toSet().toList();

        // Auto-select first month if selectedMonth is not in available list
        if (_selectedMonth != null && !availableMonths.contains(_selectedMonth)) {
          _selectedMonth = null;
        }

        // 2. Filter journal logs based on selected filter
        List<PaymentLog> filteredJournal = journal;
        if (_filterType == 'month' && _selectedMonth != null) {
          filteredJournal = journal.where((log) {
            final logMonthStr = DateFormat('MMMM y', isTr ? 'tr_TR' : 'en_US').format(log.date);
            return logMonthStr == _selectedMonth;
          }).toList();
        } else if (_filterType == 'range' && _startDate != null && _endDate != null) {
          filteredJournal = journal.where((log) {
            // Normalise log date to compare purely by day
            final logDate = DateTime(log.date.year, log.date.month, log.date.day);
            final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
            return (logDate.isAtSameMomentAs(start) || logDate.isAfter(start)) &&
                (logDate.isAtSameMomentAs(end) || logDate.isBefore(end));
          }).toList();
        }

        // 3. Group filtered logs by Month
        final Map<String, List<PaymentLog>> groupedLogs = {};
        for (final log in filteredJournal) {
          final String monthKey = DateFormat('MMMM y', isTr ? 'tr_TR' : 'en_US').format(log.date);
          if (!groupedLogs.containsKey(monthKey)) {
            groupedLogs[monthKey] = [];
          }
          groupedLogs[monthKey]!.add(log);
        }

        final List<String> monthKeys = groupedLogs.keys.toList();

        return Column(
          children: [
            // Filter Controls Header Card
            _buildFilterHeader(context, provider, availableMonths, isTr),

            // Content List
            Expanded(
              child: filteredJournal.isEmpty
                  ? _buildEmptyState(provider)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: monthKeys.length,
                      itemBuilder: (context, groupIndex) {
                        final String monthKey = monthKeys[groupIndex];
                        final List<PaymentLog> logs = groupedLogs[monthKey]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Month Section Divider Title
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 14,
                                    color: Color(0xffa855f7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    monthKey.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xffa855f7),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Log items for this month
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                final isLast = index == logs.length - 1;

                                return Dismissible(
                                  key: Key(log.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffef4444),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.centerRight,
                                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await _showConfirmDeleteDialog(context, log, provider);
                                  },
                                  onDismissed: (direction) async {
                                    await provider.deleteJournalEntry(log.id);
                                  },
                                  child: _buildJournalItem(
                                    context,
                                    log,
                                    provider,
                                    currency,
                                    isLast,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // Filter UI Layout
  Widget _buildFilterHeader(BuildContext context, DebtProvider provider, List<String> availableMonths, bool isTr) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        color: Color(0xff0f0f26),
        border: Border(bottom: BorderSide(color: Color(0xff1a1a3a), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.translate('filter_title'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xff8888aa),
                  letterSpacing: 0.5,
                ),
              ),
              if (_filterType != 'all')
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _filterType = 'all';
                      _selectedMonth = null;
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: Text(
                    provider.translate('clear_filter'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffef4444),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter selection pills
          Row(
            children: [
              _buildFilterPill('all', provider.translate('all_filter')),
              const SizedBox(width: 8),
              _buildFilterPill('month', provider.translate('select_month')),
              const SizedBox(width: 8),
              _buildFilterPill('range', provider.translate('date_range')),
            ],
          ),

          // Secondary Filter Inputs
          if (_filterType == 'month') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xff12122a),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xff2a2a55), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  hint: Text(
                    isTr ? 'Bir Ay Seçin' : 'Select a Month',
                    style: GoogleFonts.inter(color: const Color(0xff555577), fontSize: 13),
                  ),
                  dropdownColor: const Color(0xff12122a),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xff3b82f6)),
                  isExpanded: true,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  items: availableMonths.map((m) {
                    return DropdownMenuItem<String>(
                      value: m,
                      child: Text(m),
                    );
                  }).toList(),
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedMonth = val;
                    });
                  },
                ),
              ),
            ),
          ],

          if (_filterType == 'range') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDatePickerButton(
                    context,
                    _startDate,
                    provider.translate('start_date'),
                    (date) => setState(() => _startDate = date),
                    isTr,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDatePickerButton(
                    context,
                    _endDate,
                    provider.translate('end_date'),
                    (date) => setState(() => _endDate = date),
                    isTr,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Filter Pill Button Component
  Widget _buildFilterPill(String type, String label) {
    final bool active = _filterType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _filterType = type;
          });
        },
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xff3b82f6) : const Color(0xff12122a),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? const Color(0xff3b82f6) : const Color(0xff2a2a55),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active ? const Color(0xff080815) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Date Range Picker Button
  Widget _buildDatePickerButton(
      BuildContext context, DateTime? selectedDate, String placeholder, Function(DateTime) onPicked, bool isTr) {
    final formatted = selectedDate != null
        ? DateFormat('dd.MM.yyyy').format(selectedDate)
        : placeholder;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xff3b82f6),
                  onPrimary: Color(0xff080815),
                  surface: Color(0xff12122a),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          HapticFeedback.selectionClick();
          onPicked(picked);
        }
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xff12122a),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xff2a2a55), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatted,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: selectedDate != null ? Colors.white : const Color(0xff555577),
                fontWeight: selectedDate != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Icon(Icons.calendar_month, color: Color(0xff3b82f6), size: 16),
          ],
        ),
      ),
    );
  }

  // Empty Search/History State
  Widget _buildEmptyState(DebtProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_toggle_off,
            color: Color(0xff555577),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            provider.translate('no_journal_logs'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xff8888aa),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.translate('journal_sub'),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xff555577),
            ),
          ),
        ],
      ),
    );
  }

  // Transaction Item Widget Card
  Widget _buildJournalItem(
      BuildContext context, PaymentLog log, DebtProvider provider, String currency, bool isLast) {
    final bool isPayment = log.action == 'payment';
    final Color accentColor = isPayment ? const Color(0xff10b981) : const Color(0xffeab308);
    final bool isTr = provider.languageCode == 'tr';
    final String formattedDate = DateFormat('d MMMM y', isTr ? 'tr_TR' : 'en_US').format(log.date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Timeline connector lines
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xff080815), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xff2a2a55),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content Box
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xff12122a),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xff2a2a55), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${log.bank} - ${log.type}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${isPayment ? '-' : ''}${_formatMoney(log.amount)} $currency',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    log.note,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xff94a3b8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xff555577), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xff555577),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final confirm = await _showConfirmDeleteDialog(context, log, provider);
                          if (confirm == true) {
                            await provider.deleteJournalEntry(log.id);
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Color(0xffef4444), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              provider.translate('delete_record'),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xffef4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Confirm delete dialog
  Future<bool?> _showConfirmDeleteDialog(BuildContext context, PaymentLog log, DebtProvider provider) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff12122a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xffef4444), size: 24),
              const SizedBox(width: 12),
              Text(
                provider.translate('delete_record_title'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Text(
            provider.translate('delete_record_sub'),
            style: GoogleFonts.inter(color: const Color(0xff94a3b8), fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                provider.translate('cancel'),
                style: GoogleFonts.inter(color: const Color(0xff94a3b8)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                provider.translate('yes_delete'),
                style: GoogleFonts.inter(color: const Color(0xffef4444), fontWeight: FontWeight.bold),
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
