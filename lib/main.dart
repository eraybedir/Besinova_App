// main.dart
// Uygulamanın giriş noktası. Provider ile tema ve kullanıcı yönetimi sağlar.
// MaterialApp ile uygulamanın genel temasını ve rotalarını ayarlar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/optimization_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/auth_gate.dart';
import 'presentation/screens/signin_screen.dart';
import 'presentation/screens/signup_screen.dart';
import 'presentation/screens/optimization_test_screen.dart';
import 'data/services/optimization_service.dart';
import 'data/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Global Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };
  
  // Handle platform errors
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform Error: $error');
    print('Stack trace: $stack');
    return true;
  };

  try {
    // Initialize optimization service with gender mapping fix
  print("Initializing optimization service...");
  bool optimizationInitialized = await OptimizationService.initialize();
  if (optimizationInitialized) {
    print("SUCCESS: Optimization service initialized successfully");
  } else {
    print("WARNING: Optimization service initialized with fallback data");
    }
  } catch (e) {
    print("ERROR: Failed to initialize optimization service: $e");
    // Continue app startup even if optimization service fails
  }

  runApp(const BesinovaApp());
}

/// Main application widget
class BesinovaApp extends StatelessWidget {
  const BesinovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => UserProvider()..loadUserData(),
        ),
        ChangeNotifierProvider(create: (_) => OptimizationProvider()),
      ],
      child: const _BesinovaAppContent(),
    );
  }
}

/// Application content widget
class _BesinovaAppContent extends StatelessWidget {
  const _BesinovaAppContent();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Set up global error widget
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[300],
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Bir hata oluştu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lütfen uygulamayı yeniden başlatın',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  SystemNavigator.pop();
                },
                child: const Text('Uygulamayı Yeniden Başlat'),
              ),
            ],
          ),
        ),
      );
    };

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      scaffoldMessengerKey: NotificationService.messengerKey,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthGate(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/test': (context) => const OptimizationTestScreen(),
      },
    );
  }
}

// Basit çeviri fonksiyonu (ileride gerçek localization ile değiştirilebilir)
String t(String key) {
  // Placeholder for localization. In the future, use Intl or similar.
  return key;
}
