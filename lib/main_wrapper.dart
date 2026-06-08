import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iti_connect/features/admin/screens/admin_reservation_manage.dart';
import 'package:iti_connect/services/notification_service.dart';
import 'features/admin/screens/admin_report_list_screen.dart';
import 'features/pelaporan/screens/report_list_screen.dart';
import 'features/auth/screens/profile_screen.dart';

// IMPORT MODUL RESERVASI
import 'features/reservasi/screens/room_list_screen.dart';
// import 'features/admin/screens/admin_reservation_manage.dart'; // Aktifkan jika sudah buat dashboard admin reservasi

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  String _userRole = 'mahasiswa';
  String _userLevel = 'user';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserContext();
    // Cukup satu kali inisialisasi yang lengkap
    NotificationService nService = NotificationService();

    // 1. Minta izin & sinkronkan token ke Firestore
    nService.initializeNotification();

    // 2. Aktifkan pendengar notifikasi saat aplikasi terbuka
    nService.listenToForegroundMessages();
  }

  void _fetchUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            _userRole = (doc.data()?['role'] ?? 'mahasiswa')
                .toString()
                .toLowerCase();
            _userLevel = (doc.data()?['level'] ?? 'user')
                .toString()
                .toLowerCase();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool hasAdminAccess =
        _userRole == 'admin' ||
        _userRole == 'superadmin' ||
        _userLevel == 'superadmin';

    // PERBAIKAN: Hubungkan ke halaman yang benar
    final List<Widget> pages = [
      // Index 0: Pelaporan
      hasAdminAccess ? const AdminReportListScreen() : const ReportListScreen(),

      // Index 1: Reservasi
      // Untuk saat ini kita arahkan ke RoomListScreen agar bisa testing peminjaman
      // Jika nanti dashboard admin reservasi sudah jadi, bisa pakai hasAdminAccess ? AdminReservationScreen() : RoomListScreen()
      // Jika admin, tampilkan manajemen reservasi. Jika user, tampilkan list ruangan.
      hasAdminAccess ? const AdminReservationManage() : const RoomListScreen(),

      // Index 2: Profil
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue[900],
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    _selectedIndex == 0
                        ? Icons.assignment_rounded
                        : Icons.assignment_outlined,
                  ),
                  label: hasAdminAccess ? 'Monitoring' : 'Laporan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    _selectedIndex == 1
                        ? Icons.meeting_room_rounded
                        : Icons.meeting_room_outlined,
                  ),
                  label: 'Reservasi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    _selectedIndex == 2
                        ? Icons.person_rounded
                        : Icons.person_outline_rounded,
                  ),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
