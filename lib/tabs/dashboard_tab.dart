import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../utils/color_utils.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _activeMonth = 'July 2026';

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        final totalDebt = provider.totalDebt;
        final totalPaid = provider.totalPaid;
        final progressPct = provider.progressPercentage;
        final remainingDebts = provider.debts.where((d) => d.current > 0).length;
        final currency = provider.profile?.currency ?? '₺';

        // Localized Month Map
        final monthLabels = provider.languageCode == 'tr'
            ? {
                'July 2026': 'Temmuz 2026',
                'August 2026': 'Ağustos 2026',
                'September 2026': 'Eylül 2026',
              }
            : {
                'July 2026': 'July 2026',
                'August 2026': 'August 2026',
                'September 2026': 'September 2026',
              };

        // Get dynamic tasks based on user debts
        final tasks = provider.getChecklistForMonth(_activeMonth);

        final lossData = provider.calculatePreviousMonthLoss();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (lossData['hasLoss'] == true) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffef4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffef4444).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xffef4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.translate('interest_loss_warning'),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xffef4444),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.translate('loss_calculator_msg')
                                  .replaceAll('{month}', lossData['monthName'] as String)
                                  .replaceAll('{amount}', (lossData['interestLoss'] as double).toStringAsFixed(0))
                                  .replaceAll('{curr}', currency),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xfffca5a5),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${provider.languageCode == 'tr' ? 'Gecikmeye Düşenler' : 'Missed Accounts'}: ${((lossData['debtNames'] as List<String>).join(', '))}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xfff87171),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Summary Cards Grid
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
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
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _buildStatCard(
                      title: provider.translate('total_debt'),
                      value: '${_formatMoney(totalDebt)} $currency',
                      desc: provider.translate('latest_stat'),
                      accentColor: const Color(0xffef4444),
                      cardIcon: Icons.account_balance,
                    ),
                    _buildStatCard(
                      title: provider.translate('total_paid'),
                      value: '${_formatMoney(totalPaid)} $currency',
                      desc: provider.translate('system_record'),
                      accentColor: const Color(0xff10b981),
                      cardIcon: Icons.check_circle_outline,
                    ),
                    _buildStatCard(
                      title: provider.translate('debt_free_ratio'),
                      value: '%${progressPct.toStringAsFixed(1)}',
                      desc: provider.translate('freedom_pct'),
                      accentColor: const Color(0xff3b82f6),
                      cardIcon: Icons.trending_down,
                    ),
                    _buildStatCard(
                      title: provider.translate('active_cards_count'),
                      value: '$remainingDebts / ${provider.debts.length}',
                      desc: provider.translate('remaining_debts_desc'),
                      accentColor: const Color(0xffa855f7),
                      cardIcon: Icons.credit_card,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Circular Progress Widget
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) {
                  return Transform.translate(
                    offset: Offset(0.0, 25.0 * (1.0 - animValue)),
                    child: Opacity(
                      opacity: animValue,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff12122a),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x11ffffff), width: 1),
                  ),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: progressPct / 100),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeInOutCubic,
                        builder: (context, progressVal, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 90,
                                width: 90,
                                child: CircularProgressIndicator(
                                  value: progressVal,
                                  strokeWidth: 8,
                                  backgroundColor: const Color(0xff1e1e3f),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    provider.isPremium ? const Color(0xffeab308) : const Color(0xff10b981),
                                  ),
                                ),
                              ),
                              Text(
                                '%${(progressVal * 100).toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.translate('towards_debt_free'),
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              provider.debts.isEmpty
                                  ? provider.translate('no_debts_yet')
                                  : provider.translate('cleared_so_far_msg')
                                      .replaceAll('{paid}', _formatMoney(provider.totalInitialDebt - totalDebt))
                                      .replaceAll('{curr}', currency),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xff94a3b8),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Checklist Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.translate('monthly_tasks'),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _activeMonth,
                      dropdownColor: const Color(0xff12122a),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff94a3b8)),
                      items: monthLabels.keys.map((String monthKey) {
                        return DropdownMenuItem<String>(
                          value: monthKey,
                          child: Text(
                            monthLabels[monthKey]!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff3b82f6),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() {
                            _activeMonth = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildChecklist(provider, tasks, currency),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String desc,
    required Color accentColor,
    required IconData cardIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff12122a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x11ffffff), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff8888aa),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(cardIcon, color: accentColor.withOpacity(0.8), size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xff555577),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist(DebtProvider provider, List<Map<String, dynamic>> tasks, String currency) {
    final monthLabels = provider.languageCode == 'tr'
        ? {
            'July 2026': 'Temmuz 2026',
            'August 2026': 'Ağustos 2026',
            'September 2026': 'Eylül 2026',
          }
        : {
            'July 2026': 'July 2026',
            'August 2026': 'August 2026',
            'September 2026': 'September 2026',
          };

    if (provider.debts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xff12122a),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x11ffffff), width: 1),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xff10b981), size: 48),
            const SizedBox(height: 16),
            Text(
              provider.translate('no_debts_title'),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              provider.translate('no_debts_sub'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xff8888aa), fontSize: 12, height: 1.4),
            ),
          ],
        ),
      );
    }

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text(
          provider.translate('no_tasks_month'),
          style: GoogleFonts.inter(color: const Color(0xff555577)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final String debtId = task['id'];
        final double amount = task['amount'];

        String labelText = '';
        if (debtId == 'free') {
          labelText = task['labelKey'] != null
              ? provider.translate(task['labelKey'])
              : (task['label'] ?? '');
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1110b981),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x3310b981)),
            ),
            child: Text(
              labelText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xff10b981),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );
        }

        final debt = provider.debts.firstWhere((d) => d.id == debtId);
        final Color bankColor = getBankBrandColor(debt.bank);
        labelText = task['labelKey'] != null
            ? provider.translate(task['labelKey']).replaceAll('{bank}', debt.bank)
            : (task['label'] ?? '');

        final bool isAlreadyClosed = debt.current <= 0;
        final bool isTaskDone = isAlreadyClosed || provider.journal.any((log) =>
            log.debtId == debtId &&
            log.note.contains('[Görev Listesi]') &&
            log.note.contains(_activeMonth)
        ) || provider.journal.any((log) =>
            log.debtId == debtId &&
            log.note.contains('[Task List]') &&
            log.note.contains(_activeMonth)
        );

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Transform.translate(
              offset: Offset(0.0, 15.0 * (1.0 - animValue)),
              child: Opacity(
                opacity: animValue,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isTaskDone ? const Color(0x0c10b981) : const Color(0xff12122a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTaskDone ? const Color(0x2210b981) : const Color(0x11ffffff),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    color: isTaskDone ? const Color(0xff10b981) : bankColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (isTaskDone) {
                            final confirm = await _showUndoTaskDialog(context, provider, debt, _activeMonth);
                            if (confirm == true) {
                              HapticFeedback.mediumImpact();
                              final logIndex = provider.journal.indexWhere((log) =>
                                  log.debtId == debtId &&
                                  (log.note.contains('[Görev Listesi]') || log.note.contains('[Task List]')) &&
                                  log.note.contains(_activeMonth)
                              );
                              if (logIndex != -1) {
                                final logId = provider.journal[logIndex].id;
                                await provider.deleteJournalEntry(logId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xffef4444),
                                      content: Text(
                                        provider.languageCode == 'tr'
                                            ? '${debt.bank} ödemesi geri alındı, bakiye eklendi.'
                                            : '${debt.bank} payment undone, balance restored.',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          } else {
                            HapticFeedback.mediumImpact();
                            final note = provider.languageCode == 'tr'
                                ? '[Görev Listesi] $_activeMonth ayı checklist ödemesi.'
                                : '[Task List] $_activeMonth checklist payment.';
                            
                            provider.addPayment(
                              debtId,
                              amount,
                              DateTime.now(),
                              note,
                            );
                            provider.triggerConfetti();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xff10b981),
                                content: Text(
                                  provider.languageCode == 'tr'
                                      ? '${debt.bank} hesabına ${_formatMoney(amount)} $currency ödeme yapıldı! 🎉'
                                      : 'Paid ${_formatMoney(amount)} $currency to ${debt.bank} account! 🎉',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                            color: isTaskDone ? const Color(0xff10b981) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isTaskDone ? const Color(0xff10b981) : const Color(0xff555577),
                              width: 2,
                            ),
                          ),
                          child: isTaskDone
                              ? const Icon(Icons.check, size: 16, color: Color(0xff080815))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${debt.bank} - ${debt.type}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isTaskDone ? const Color(0xff94a3b8) : Colors.white,
                                decoration: isTaskDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$labelText - ${monthLabels[_activeMonth]}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xff64748b),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_formatMoney(amount)} $currency',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isTaskDone ? const Color(0xff10b981) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  Future<bool?> _showUndoTaskDialog(BuildContext context, DebtProvider provider, dynamic debt, String monthName) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff12122a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.undo, color: Color(0xffeab308), size: 24),
              const SizedBox(width: 12),
              Text(
                provider.languageCode == 'tr' ? 'Görevi Geri Al?' : 'Undo Task?',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Text(
            provider.languageCode == 'tr'
                ? '${debt.bank} ödemesini iptal edip görevi tamamlanmamış olarak işaretlemek istiyor musunuz?'
                : 'Do you want to cancel the payment for ${debt.bank} and mark this task as incomplete?',
            style: GoogleFonts.inter(color: const Color(0xff94a3b8), fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                provider.languageCode == 'tr' ? 'Vazgeç' : 'Cancel',
                style: GoogleFonts.inter(color: const Color(0xff94a3b8)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                provider.languageCode == 'tr' ? 'Evet, Geri Al' : 'Yes, Undo',
                style: GoogleFonts.inter(color: const Color(0xffef4444), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
