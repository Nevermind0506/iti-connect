import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data Slide Onboarding
  final List<Map<String, dynamic>> _onboardingData = [
    {
      "isLogo": true,
      "title": "ITI CONNECT",
      "subtitle": "Smart Campus Ecosystem",
      "desc":
          "Solusi cerdas terintegrasi untuk kemudahan akses aktivitas akademik di Institut Teknologi Indonesia.",
      "colors": [const Color(0xFF001A3D), const Color(0xFF0D47A1)],
    },
    {
      "isLogo": false,
      "title": "Reservasi Ruangan",
      "subtitle": "Real-time Booking",
      "desc":
          "Cek ketersediaan dan pesan ruang kelas atau laboratorium hanya dalam hitungan detik.",
      "icon": Icons.meeting_room_rounded,
      "colors": [const Color(0xFF0D47A1), const Color(0xFF1976D2)],
    },
    {
      "title": "Sistem Pelaporan",
      "isLogo": false,
      "subtitle": "Quick Response",
      "desc":
          "Laporkan kendala fasilitas kampus dengan mudah dan pantau progres perbaikannya secara transparan.",
      "icon": Icons.report_problem_rounded,
      "colors": [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
    },
  ];

  // Fungsi untuk menyelesaikan Onboarding
  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // Set status agar tidak tampil lagi di masa mendatang
    await prefs.setBool('showOnboarding', false);

    if (!mounted) return;

    // Bersihkan stack navigasi dan pindah ke login
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Animasi
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: _onboardingData[_currentPage]["colors"],
              ),
            ),
          ),

          // Aksen Lingkaran Dekoratif
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Tombol Lewati
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        "Lewati",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // Konten Slide (PageView)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (value) =>
                        setState(() => _currentPage = value),
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) => _buildPage(index),
                  ),
                ),

                // Footer: Indikator & Tombol Navigasi
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 50),
                  child: Column(
                    children: [
                      // Indikator Titik
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingData.length,
                          (index) => _buildDot(index),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Tombol Lanjutkan / Mulai
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _onboardingData.length - 1) {
                              _finishOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutQuart,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                _onboardingData[_currentPage]["colors"][0],
                            elevation: 8,
                            shadowColor: Colors.black45,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            _currentPage == _onboardingData.length - 1
                                ? "MULAI SEKARANG"
                                : "LANJUTKAN",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    final data = _onboardingData[index];
    bool isLogo = data["isLogo"] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Container Ikon / Logo
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: isLogo
                ? Image.asset(
                    'assets/images/logo_iticonnect_wrmbg.png',
                    height: 180,
                    width: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance_rounded,
                      size: 150,
                      color: Colors.white,
                    ),
                  )
                : Icon(data["icon"], size: 150, color: Colors.white),
          ),
          const SizedBox(height: 60),

          // Judul
          Text(
            data["title"],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Subtitle
          Text(
            data["subtitle"],
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Deskripsi
          Text(
            data["desc"],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 10),
      height: 10,
      width: _currentPage == index ? 35 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
