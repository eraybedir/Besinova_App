import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/storage_service.dart';
import 'home_screen.dart';
import 'signin_screen.dart';

/// Authentication gate that determines which screen to show based on Firebase auth state
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      await StorageService.init();
      
      // Check Firebase authentication state
      final user = FirebaseAuth.instance.currentUser;
      
      if (mounted) {
        setState(() {
          _isAuthenticated = user != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2C3E50),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFA3EBB1),
              ),
              SizedBox(height: 16),
              Text(
                'Yükleniyor...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if user is authenticated
    if (_isAuthenticated) {
      // User is authenticated, go to home screen
      return const HomeScreen();
    }

    // User is not authenticated, show sign in screen
    return const SignInScreen();
  }
}
