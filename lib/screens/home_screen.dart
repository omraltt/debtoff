import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../models/profile.dart';
import 'onboarding_screen.dart';
import 'premium_screen.dart';
import '../tabs/dashboard_tab.dart';
import '../tabs/debts_tab.dart';
import '../tabs/ai_splitter_tab.dart';
import '../tabs/journal_tab.dart';
import '../tabs/expenses_tab.dart';
import '../widgets/confetti_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const DebtsTab(),
    const AiSplitterTab(),
    const ExpensesTab(),
    const JournalTab(),
  ];


  @override
  void initState() {
    super.initState();
    // Load data from provider
    Future.microtask(() {
      context.read<DebtProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        final profile = provider.profile;
        final nameLabel = profile != null ? ' - ${profile.name}' : '';
        final titles = provider.languageCode == 'tr'
            ? ['Özet Paneli', 'Borçlarım', 'AI Dağıtıcı', 'Harcamalarım', 'Geçmiş']
            : ['Overview', 'My Debts', 'AI Splitter', 'Expenses', 'History'];

        return Scaffold(
          backgroundColor: const Color(0xff080815),
          appBar: AppBar(
            backgroundColor: const Color(0xff0f0f26),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: provider.isPremium
                        ? const LinearGradient(
                            colors: [Color(0xffeab308), Color(0xffca8a04)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xff3b82f6), Color(0xffa855f7)],
                          ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    provider.isPremium ? Icons.workspace_premium : Icons.account_balance_wallet,
                    color: provider.isPremium ? const Color(0xff080815) : Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.isPremium ? 'SIFIRLA PRO' : 'SIFIRLA',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: provider.isPremium ? const Color(0xffeab308) : Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 20,
                  color: const Color(0xff2a2a55),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${titles[_currentIndex]}$nameLabel',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff8888aa),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Color(0xff8888aa)),
                tooltip: 'Ayarlar',
                onPressed: () => _showSettingsSheet(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              _tabs[_currentIndex],
              ConfettiOverlay(visible: provider.showConfetti),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xff2a2a55), width: 0.5),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: const Color(0xff0f0f26),
              selectedItemColor: const Color(0xff3b82f6),
              unselectedItemColor: const Color(0xff555577),
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard_outlined),
                  activeIcon: const Icon(Icons.dashboard),
                  label: provider.languageCode == 'tr' ? 'Özet' : 'Summary',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.credit_card_outlined),
                  activeIcon: const Icon(Icons.credit_card),
                  label: provider.languageCode == 'tr' ? 'Borçlarım' : 'Debts',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.psychology_outlined),
                  activeIcon: const Icon(Icons.psychology),
                  label: provider.languageCode == 'tr' ? 'AI Dağıtıcı' : 'AI Splitter',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long_outlined),
                  activeIcon: const Icon(Icons.receipt_long),
                  label: provider.translate('expenses'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.history_outlined),
                  activeIcon: const Icon(Icons.history),
                  label: provider.languageCode == 'tr' ? 'Geçmiş' : 'History',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final provider = context.read<DebtProvider>();
    final profile = provider.profile;

    final nameController = TextEditingController(text: profile?.name ?? '');
    final pinController = TextEditingController(text: profile?.pinCode ?? '');
    String selectedCurrency = profile?.currency ?? '₺';
    bool isPasscodeEnabled = profile?.isPasscodeEnabled ?? false;
    String selectedLanguage = profile?.languageCode ?? 'tr';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff12122a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    Row(
                      children: [
                        const Icon(Icons.settings, color: Color(0xff3b82f6), size: 24),
                        const SizedBox(width: 12),
                        Text(
                          provider.translate('settings'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Premium Card Row
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: provider.isPremium
                            ? const LinearGradient(
                                colors: [Color(0xffeab308), Color(0xffca8a04)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xff1e1b4b), Color(0xff0f0f26)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: provider.isPremium ? const Color(0xffeab308) : const Color(0xff2a2a55),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                provider.isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                                color: provider.isPremium ? const Color(0xff080815) : Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                provider.isPremium
                                    ? provider.translate('premium_active') + ' ✨'
                                    : provider.translate('upgrade_premium'),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: provider.isPremium ? const Color(0xff080815) : Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (!provider.isPremium)
                            TextButton(
                              onPressed: () {
                                Navigator.pop(sheetContext); // Close settings sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PremiumScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xff3b82f6),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                selectedLanguage == 'tr' ? 'İncele' : 'View',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User name field
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: provider.translate('profile_name'),
                        labelStyle: const TextStyle(color: Color(0xff8888aa)),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xff3b82f6)),
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

                    // Currency Selector dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xff080815),
                        border: Border.all(color: const Color(0x22ffffff)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCurrency,
                          dropdownColor: const Color(0xff12122a),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff8888aa)),
                          items: ['₺', '\$', '€', '£'].map((String curr) {
                            return DropdownMenuItem<String>(
                              value: curr,
                              child: Text(
                                '${provider.translate('currency')}: $curr',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedCurrency = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Language Selector dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xff080815),
                        border: Border.all(color: const Color(0x22ffffff)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLanguage,
                          dropdownColor: const Color(0xff12122a),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff8888aa)),
                          items: const [
                            DropdownMenuItem<String>(
                              value: 'tr',
                              child: Text(
                                'Dil / Language: Türkçe (TR)',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: 'en',
                              child: Text(
                                'Dil / Language: English (EN)',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedLanguage = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Security / PIN Lock Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xff080815),
                        border: Border.all(color: const Color(0x22ffffff)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.security, color: Color(0xffa855f7), size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    provider.translate('passcode_active'),
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  ),
                                ],
                              ),
                              Switch(
                                value: isPasscodeEnabled,
                                activeColor: const Color(0xff3b82f6),
                                onChanged: (val) {
                                  setSheetState(() {
                                    isPasscodeEnabled = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (isPasscodeEnabled) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: pinController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: selectedLanguage == 'tr' ? 'Yeni Giriş Şifresi (4 Hane)' : 'New passcode PIN (4 Digits)', counterText: '',
                                labelStyle: const TextStyle(color: Color(0xff8888aa)),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xffa855f7)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0x22ffffff)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xffa855f7)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Profile Button
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        if (isPasscodeEnabled && pinController.text.length != 4) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xffef4444),
                              content: Text('PIN Kodu 4 hane olmalıdır!'),
                            ),
                          );
                          return;
                        }

                        final updated = profile?.copyWith(
                              name: name,
                              currency: selectedCurrency,
                              isPasscodeEnabled: isPasscodeEnabled,
                              pinCode: isPasscodeEnabled ? pinController.text : null,
                              languageCode: selectedLanguage,
                            ) ??
                            UserProfile(
                              name: name,
                              currency: selectedCurrency,
                              isPasscodeEnabled: isPasscodeEnabled,
                              pinCode: isPasscodeEnabled ? pinController.text : null,
                              hasCompletedOnboarding: true,
                              createdAt: DateTime.now(),
                              languageCode: selectedLanguage,
                            );

                        await provider.saveProfile(updated);
                        Navigator.pop(sheetContext);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xff10b981),
                            content: Text(
                              selectedLanguage == 'tr'
                                  ? 'Profil başarıyla güncellendi! 💾'
                                  : 'Profile successfully updated! 💾',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff3b82f6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        selectedLanguage == 'tr' ? 'Profil Ayarlarını Kaydet' : 'Save Profile Settings',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xff2a2a55)),
                    const SizedBox(height: 12),

                    // Backup & Restore
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final jsonStr = await provider.exportBackup();
                              await Clipboard.setData(ClipboardData(text: jsonStr));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xff10b981),
                                    content: Text(
                                      selectedLanguage == 'tr'
                                          ? 'Yedek verileriniz panoya kopyalandı! 📋'
                                          : 'Backup data copied to clipboard! 📋',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: Text(selectedLanguage == 'tr' ? 'Yedekle (Kopyala)' : 'Backup (Copy)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xff8888aa),
                              side: const BorderSide(color: Color(0xff2a2a55)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showImportDialog(context, provider),
                            icon: const Icon(Icons.paste, size: 16),
                            label: Text(selectedLanguage == 'tr' ? 'Yedekten Yükle' : 'Restore Backup'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xff8888aa),
                              side: const BorderSide(color: Color(0xff2a2a55)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Reset Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await _showConfirmWarning(
                          context,
                          provider,
                          provider.translate('reset_app_sub'),
                        );
                        if (confirm) {
                          await provider.resetData();
                          Navigator.pop(sheetContext);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_forever, size: 16, color: Color(0xffef4444)),
                      label: Text(provider.translate('reset_all')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffef4444),
                        side: const BorderSide(color: Color(0x33ef4444)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showImportDialog(BuildContext context, DebtProvider provider) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff12122a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            provider.translate('import_title'),
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.translate('import_desc'),
                style: GoogleFonts.inter(color: const Color(0xff94a3b8), fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                decoration: InputDecoration(
                  hintText: '{"debts": [...], "journal": [...]}',
                  hintStyle: const TextStyle(color: Color(0xff555577)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0x22ffffff)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xff3b82f6)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(provider.translate('import_cancel'), style: GoogleFonts.inter(color: const Color(0xff94a3b8))),
            ),
            TextButton(
              onPressed: () async {
                final txt = textController.text.trim();
                if (txt.isEmpty) return;
                try {
                  await provider.importBackup(txt);
                  Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xff10b981),
                        content: Text(provider.translate('import_success')),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xffef4444),
                        content: Text(provider.translate('import_error')),
                      ),
                    );
                  }
                }
              },
              child: Text(provider.translate('import_load'), style: GoogleFonts.inter(color: const Color(0xff3b82f6), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showConfirmWarning(BuildContext context, DebtProvider provider, String message) async {
    final result = await showDialog<bool>(
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
                provider.translate('confirm_title'),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(color: const Color(0xff94a3b8), fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(provider.translate('confirm_cancel'), style: GoogleFonts.inter(color: const Color(0xff94a3b8))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(provider.translate('confirm_yes'), style: GoogleFonts.inter(color: const Color(0xffef4444), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
