import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Import Screens
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/pelaporan/screens/add_report_screen.dart';
import 'main_wrapper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase sebelum menjalankan aplikasi
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Handler notifikasi background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Ambil status onboarding dari memori lokal HP
  final prefs = await SharedPreferences.getInstance();
  final bool showOnboarding = prefs.getBool('showOnboarding') ?? true;

  runApp(ITIConnectApp(showOnboarding: showOnboarding));
}

class ITIConnectApp extends StatelessWidget {
  final bool showOnboarding;
  const ITIConnectApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITI Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Tambahkan font atau konfigurasi tema global di sini
      ),

      // LOGIKA NAVIGASI UTAMA
      // Jika baru pertama kali (onboarding true), tampilkan OnboardingScreen
      // Jika sudah pernah buka, jalankan AuthGate untuk cek login
      home: showOnboarding ? const OnboardingScreen() : const AuthGate(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/add-report': (context) => const AddReportScreen(),
        '/dashboard': (context) => const MainWrapper(),
      },
    );
  }
}

/// Widget pembantu untuk memantau status login secara real-time
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Tampilkan SplashScreen hanya saat Firebase sedang loading data user
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Jika user ditemukan (sudah login sebelumnya)
        if (snapshot.hasData && snapshot.data != null) {
          return const MainWrapper();
        }

        // Jika tidak ada user (belum login atau sudah logout)
        return const LoginScreen();
      },
    );
  }
}
