import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../providers/debt_provider.dart';
import 'home_screen.dart';

class PasscodeScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback? onUnlocked;
  const PasscodeScreen({super.key, required this.profile, this.onUnlocked});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> with SingleTickerProviderStateMixin {
  String _enteredCode = '';
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 15.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reverse();
        }
      });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_enteredCode.length >= 4) return;

    setState(() {
      _isError = false;
      _enteredCode += digit;
    });

    HapticFeedback.lightImpact();

    if (_enteredCode.length == 4) {
      _verifyCode();
    }
  }

  void _onBackspace() {
    if (_enteredCode.isEmpty) return;
    setState(() {
      _isError = false;
      _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
    });
    HapticFeedback.lightImpact();
  }

  void _verifyCode() {
    if (_enteredCode == widget.profile.pinCode) {
      HapticFeedback.mediumImpact();
      if (widget.onUnlocked != null) {
        widget.onUnlocked!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward();
      setState(() {
        _isError = true;
        _enteredCode = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff080815),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // Header Logo & Greeting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff12122a),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x11ffffff), width: 1.5),
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Color(0xff3b82f6),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tekrar Hoş Geldin, ${widget.profile.name}',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isError ? 'Hatalı şifre! Tekrar deneyin.' : 'Lütfen 4 haneli giriş şifrenizi girin.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _isError ? const Color(0xffef4444) : const Color(0xff8888aa),
                fontWeight: _isError ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            
            const SizedBox(height: 32),

            // PIN Indicators
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value * (1 - _shakeController.value), 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _enteredCode.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _isError 
                          ? const Color(0xffef4444) 
                          : (filled ? const Color(0xff3b82f6) : Colors.transparent),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isError 
                            ? const Color(0xffef4444) 
                            : (filled ? const Color(0xff3b82f6) : const Color(0xff334155)),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // Keyboard Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['1', '2', '3'].map((d) => _buildKey(d)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['4', '5', '6'].map((d) => _buildKey(d)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['7', '8', '9'].map((d) => _buildKey(d)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 64, height: 64), // Empty space
                      _buildKey('0'),
                      _buildBackspaceKey(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (widget.profile.recoveryKey != null)
              TextButton(
                onPressed: () => _showRecoveryDialog(context),
                child: Text(
                  widget.profile.languageCode == 'tr' ? 'Şifremi Unuttum / Kurtar' : 'Forgot PIN / Recover',
                  style: GoogleFonts.inter(
                    color: const Color(0xff8888aa),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showRecoveryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isTr = widget.profile.languageCode == 'tr';
        return AlertDialog(
          backgroundColor: const Color(0xff12122a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isTr ? 'Şifre Kurtarma' : 'PIN Recovery',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTr
                    ? 'Kaydolurken size verilen 6 haneli Kurtarma Anahtarını girin:'
                    : 'Enter the 6-character Recovery Key shown during onboarding:',
                style: GoogleFonts.inter(color: const Color(0xff8888aa), fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: isTr ? 'Kurtarma Anahtarı' : 'Recovery Key',
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isTr ? 'Vazgeç' : 'Cancel', style: GoogleFonts.inter(color: const Color(0xff8888aa))),
            ),
            TextButton(
              onPressed: () async {
                final key = controller.text.trim().toUpperCase();
                if (key == widget.profile.recoveryKey) {
                  Navigator.pop(dialogContext); // close recovery input
                  _showResetPinDialog(context); // open reset PIN dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xffef4444),
                      content: Text(
                        isTr ? 'Geçersiz Kurtarma Anahtarı!' : 'Invalid Recovery Key!',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              },
              child: Text(isTr ? 'Doğrula' : 'Verify', style: GoogleFonts.inter(color: const Color(0xff3b82f6), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showResetPinDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final isTr = widget.profile.languageCode == 'tr';
        return AlertDialog(
          backgroundColor: const Color(0xff12122a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isTr ? 'Yeni PIN Belirleyin' : 'Set New PIN',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTr
                    ? 'Lütfen 4 haneli yeni giriş şifrenizi belirleyin:'
                    : 'Please enter your new 4-digit passcode PIN:',
                style: GoogleFonts.inter(color: const Color(0xff8888aa), fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: isTr ? 'Yeni PIN' : 'New PIN',
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final pin = controller.text.trim();
                if (pin.length == 4) {
                  final provider = Provider.of<DebtProvider>(context, listen: false);
                  final updated = widget.profile.copyWith(pinCode: pin, isPasscodeEnabled: true);
                  await provider.saveProfile(updated);
                  Navigator.pop(dialogContext); // close reset PIN dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xff10b981),
                      content: Text(
                        isTr ? 'Şifre başarıyla güncellendi!' : 'PIN successfully updated!',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              },
              child: Text(isTr ? 'Kaydet' : 'Save', style: GoogleFonts.inter(color: const Color(0xff10b981), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKey(String digit) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xff12122a),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x0affffff), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        child: const Icon(
          Icons.backspace_outlined,
          color: const Color(0xff8888aa),
          size: 22,
        ),
      ),
    );
  }
}
