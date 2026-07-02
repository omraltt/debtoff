import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/database_service.dart';
import 'providers/debt_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/passcode_screen.dart';
import 'screens/home_screen.dart';

import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive database
  await DatabaseService.init();

  // Initialize date formatting locales
  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('en_US', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DebtProvider()..loadData(),
      child: Consumer<DebtProvider>(
        builder: (context, provider, _) {
          PurchaseService().initialize(provider);
          return MaterialApp(
            title: 'Debtoff',
            debugShowCheckedModeBanner: false,
            locale: Locale(provider.languageCode),
            builder: (context, child) {
              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.translucent,
                child: child,
              );
            },
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xff080815),
              appBarTheme: const AppBarTheme(
                backgroundColor: const Color(0xff0f0f26),
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: const Color(0xff0f0f26),
                selectedItemColor: Color(0xff3b82f6),
                unselectedItemColor: Color(0xff555577),
              ),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xff3b82f6),
                secondary: Color(0xffa855f7),
                background: Color(0xff080815),
                surface: Color(0xff12122a),
                error: Color(0xffef4444),
              ),
              textTheme: GoogleFonts.interTextTheme(
                Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
              ),
            ),
            home: provider.isLoading
                ? const Scaffold(
                    backgroundColor: Color(0xff080815),
                    body: Center(
                      child: CircularProgressIndicator(color: Color(0xff3b82f6)),
                    ),
                  )
                : (provider.profile == null
                    ? const OnboardingScreen()
                    : (provider.profile!.isPasscodeEnabled && provider.profile!.pinCode != null
                        ? PasscodeLockWrapper(child: const HomeScreen())
                        : const HomeScreen())),
          );
        },
      ),
    );
  }
}

class PasscodeLockWrapper extends StatefulWidget {
  final Widget child;
  const PasscodeLockWrapper({super.key, required this.child});

  @override
  State<PasscodeLockWrapper> createState() => _PasscodeLockWrapperState();
}

class _PasscodeLockWrapperState extends State<PasscodeLockWrapper> with WidgetsBindingObserver {
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = context.read<DebtProvider>();
    final profile = provider.profile;
    _isLocked = profile != null && profile.isPasscodeEnabled && profile.pinCode != null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final provider = context.read<DebtProvider>();
      final profile = provider.profile;
      if (profile != null && profile.isPasscodeEnabled && profile.pinCode != null) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      final provider = context.watch<DebtProvider>();
      final profile = provider.profile;
      if (profile != null && profile.isPasscodeEnabled && profile.pinCode != null) {
        return PasscodeScreen(
          profile: profile,
          onUnlocked: () {
            setState(() {
              _isLocked = false;
            });
          },
        );
      }
    }
    return widget.child;
  }
}
