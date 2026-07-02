import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../services/purchase_service.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, _) {
        final isTr = provider.languageCode == 'tr';
        final title = provider.translate('premium_title');
        final desc = provider.translate('premium_desc');
        final featuresTitle = provider.translate('premium_features');
        final purchaseBtnText = provider.translate('buy_premium_btn');

        return Scaffold(
          backgroundColor: const Color(0xff080815),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gold Crown Header Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e1a0f),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x33eab308), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffeab308).withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Color(0xffeab308),
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Header Texts
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xff8888aa),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Features Glass Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xff12122a),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x11ffffff), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          featuresTitle,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xffeab308),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureRow(provider.translate('feat_unlimited_debts')),
                        const SizedBox(height: 12),
                        _buildFeatureRow(provider.translate('feat_advanced_ai')),
                        const SizedBox(height: 12),
                        _buildFeatureRow(provider.translate('feat_premium_badge')),
                        const SizedBox(height: 12),
                        _buildFeatureRow(provider.translate('feat_offline_backup')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // In-App Purchase Button
                  ElevatedButton(
                    onPressed: () async {
                      // Trigger Apple App Store Billing sheet
                      final purchaseService = PurchaseService();
                      final success = await purchaseService.buyPremium(provider);
                      if (!context.mounted) return;
                      
                      if (success) {
                        // Purchase sheet was presented — actual unlock happens via stream listener
                        // Don't close yet; the stream listener in PurchaseService will call setPremium(true)
                      } else {
                        // Show localized error message
                        final errorKey = purchaseService.lastError ?? 'iap_error';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xffef4444),
                            content: Text(
                              provider.translate(errorKey),
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xffeab308), Color(0xffca8a04)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xffeab308).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Text(
                          purchaseBtnText,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xff080815),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Restore Purchases Button
                  TextButton(
                    onPressed: () async {
                      await PurchaseService().restorePurchases();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xff12122a),
                            content: Text(
                              isTr
                                  ? 'Satın alımlar Apple App Store ile sorgulanıyor...'
                                  : 'Querying past purchases with the App Store...',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      isTr ? 'Satın Alımları Geri Yükle' : 'Restore Purchases',
                      style: GoogleFonts.inter(
                        color: const Color(0xff8888aa),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xff10b981), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
