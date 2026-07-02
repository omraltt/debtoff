import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/debt_provider.dart';
import '../services/localization_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form states
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  String _selectedCurrency = '₺';
  bool _enablePasscode = false;
  String _langCode = 'tr';
  late String _recoveryKey;

  @override
  void initState() {
    super.initState();
    _recoveryKey = _generateRecoveryKey();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String _generateRecoveryKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _finishOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xffef4444),
          content: Text(
            LocalizationService.translate(_langCode, 'enter_name_error'),
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    if (_enablePasscode && _pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xffef4444),
          content: Text(
            'PIN kodu 4 hane olmalıdır / PIN must be 4 digits',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    final profile = UserProfile(
      name: name,
      currency: _selectedCurrency,
      isPasscodeEnabled: _enablePasscode,
      pinCode: _enablePasscode ? _pinController.text : null,
      hasCompletedOnboarding: true,
      createdAt: DateTime.now(),
      isPremium: false,
      recoveryKey: _enablePasscode ? _recoveryKey : null,
      languageCode: _langCode,
    );

    // Save profile to database & notify provider
    await context.read<DebtProvider>().saveProfile(profile);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic features array based on language selected
    final List<Map<String, String>> features = [
      {
        'title': LocalizationService.translate(_langCode, 'feat1_title'),
        'desc': LocalizationService.translate(_langCode, 'feat1_sub'),
        'icon': 'credit_card',
      },
      {
        'title': LocalizationService.translate(_langCode, 'feat2_title'),
        'desc': LocalizationService.translate(_langCode, 'feat2_sub'),
        'icon': 'psychology',
      },
      {
        'title': LocalizationService.translate(_langCode, 'feat3_title'),
        'desc': LocalizationService.translate(_langCode, 'feat3_sub'),
        'icon': 'trending_down',
      }
    ];

    return Scaffold(
      backgroundColor: const Color(0xff080815),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Header & Language Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff2563eb), Color(0xff7c3aed)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SIFIRLA',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xff12122a),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x22ffffff)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _langCode,
                        dropdownColor: const Color(0xff12122a),
                        icon: const Icon(Icons.language, color: Color(0xff3b82f6), size: 16),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'tr', child: Text('TR  ')),
                          DropdownMenuItem(value: 'en', child: Text('EN  ')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _langCode = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Feature Slides & Registration Slide
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: features.length + 1,
                  itemBuilder: (context, index) {
                    if (index == features.length) {
                      // Profile setup form slide
                      return Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                LocalizationService.translate(_langCode, 'onboarding_finish_btn').replaceAll(' ve Başla', '').replaceAll(' & Get Started', ''),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _langCode == 'tr' 
                                  ? 'Uygulamayı kişiselleştirmek ve güvenliğini sağlamak için bilgilerinizi girin.'
                                  : 'Enter details to personalize and secure your local offline dashboard.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xff8888aa),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Name Input
                              TextField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: LocalizationService.translate(_langCode, 'profile_name'),
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

                              // Currency Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xff12122a),
                                  border: Border.all(color: const Color(0x22ffffff)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCurrency,
                                    dropdownColor: const Color(0xff12122a),
                                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff8888aa)),
                                    items: ['₺', '\$', '€', '£'].map((String curr) {
                                      return DropdownMenuItem<String>(
                                        value: curr,
                                        child: Text(
                                          '${LocalizationService.translate(_langCode, 'currency')}: $curr',
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedCurrency = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Passcode Toggle Card
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xff12122a),
                                  border: Border.all(color: const Color(0x22ffffff)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.security, color: Color(0xffa855f7), size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          LocalizationService.translate(_langCode, 'passcode_active'),
                                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: _enablePasscode,
                                      activeColor: const Color(0xff3b82f6),
                                      onChanged: (val) {
                                        setState(() {
                                          _enablePasscode = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              if (_enablePasscode) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _pinController,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'PIN (4 Hane / 4 Digits)',
                                    counterText: '',
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
                                const SizedBox(height: 16),
                                // Recovery key panel
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff18182b),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0x33eab308)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LocalizationService.translate(_langCode, 'recovery_key_title'),
                                        style: GoogleFonts.inter(color: const Color(0xffeab308), fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        LocalizationService.translate(_langCode, 'recovery_key_sub'),
                                        style: GoogleFonts.inter(color: const Color(0xff8888aa), fontSize: 11, height: 1.4),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          SelectableText(
                                            _recoveryKey,
                                            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy, color: Color(0xff3b82f6), size: 18),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: _recoveryKey));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(LocalizationService.translate(_langCode, 'recovery_copied')),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    final item = features[index];
                    IconData slideIcon = Icons.credit_card;
                    if (item['icon'] == 'psychology') {
                      slideIcon = Icons.psychology;
                    } else if (item['icon'] == 'trending_down') {
                      slideIcon = Icons.trending_down;
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Giant glowing icon
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xff12122a),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0x11ffffff),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0c3b82f6),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            slideIcon,
                            color: const Color(0xff3b82f6),
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            item['desc']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff94a3b8),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  features.length + 1,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xff3b82f6)
                          : const Color(0xff334155),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () {
                  if (_currentPage < features.length) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  } else {
                    _finishOnboarding();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: Colors.transparent,
                ).copyWith(
                  elevation: ButtonStyleButton.allOrNull(0.0),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff2563eb), Color(0xff7c3aed)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff7c3aed).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: Text(
                      _currentPage == features.length
                          ? LocalizationService.translate(_langCode, 'onboarding_finish_btn')
                          : LocalizationService.translate(_langCode, 'continue'),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
