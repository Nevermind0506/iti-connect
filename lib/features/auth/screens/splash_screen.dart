import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Animasi Fade-In untuk Logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // 2. Logika Perpindahan Halaman
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    // Cek apakah is_first_run ada? Jika tidak ada (null), berarti ini pertama kali (true)
    bool isFirstRun = prefs.getBool('is_first_run') ?? true;

    User? user = FirebaseAuth.instance.currentUser;

    if (isFirstRun) {
      // Jika baru pertama kali instal, ke Onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else if (user != null) {
      // Jika sudah pernah buka & sudah login, ke Main
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      // Jika sudah pernah buka tapi belum login, ke Login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.blue[800]!,
              Colors.blue[900]!,
              const Color(0xFF001A3D),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO DENGAN ANIMASI FADE-IN
            FadeTransition(
              opacity: _animation,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo_iticonnect_rmbg.png',
                  height: 120,
                  width: 120,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Teks ITI Connect
            const Text(
              "ITI CONNECT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            // Loading Indicator Kecil yang Elegan
            SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withOpacity(0.2),
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
