import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iti_connect/features/admin/screens/master_data_screen.dart';
import 'package:iti_connect/features/auth/screens/notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Profil Pengguna",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data tidak ditemukan."));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String role = (userData['role'] ?? 'mahasiswa')
              .toString()
              .toLowerCase();
          String level = (userData['level'] ?? 'user').toString().toLowerCase();
          bool isSuperAdmin = (level == 'superadmin' || role == 'superadmin');
          bool isAdminAny =
              (role == 'admin' ||
              role == 'superadmin' ||
              level == 'superadmin');

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildProfileHeader(userData, isAdminAny, isSuperAdmin),
                const SizedBox(height: 30),

                _buildSectionTitle("Pusat Pesan"),
                _buildCardContainer([
                  _buildMenuTile(
                    context,
                    Icons.notifications_active_outlined,
                    "Kotak Masuk",
                    "Lihat riwayat tanggapan admin",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 25),

                _buildSectionTitle("Informasi Personal"),
                _buildCardContainer([
                  _buildProfileRow(
                    Icons.email_outlined,
                    "Email",
                    userData['email'] ?? '-',
                    Colors.blue,
                  ),
                  const Divider(),
                  if (!isAdminAny)
                    _buildProfileRow(
                      Icons.badge_outlined,
                      "NIM",
                      userData['nim'] ?? '-',
                      Colors.orange,
                    ),
                  if (isAdminAny)
                    _buildProfileRow(
                      Icons.security_outlined,
                      "Level Akses",
                      isSuperAdmin ? "Otoritas Penuh" : "Staff Operasional",
                      Colors.red,
                    ),
                  const Divider(),
                  _buildProfileRow(
                    Icons.location_city_outlined,
                    "Institusi",
                    "Institut Teknologi Indonesia",
                    Colors.blue,
                  ),
                ]),

                const SizedBox(height: 25),

                if (isAdminAny) ...[
                  _buildSectionTitle("Manajemen Sistem"),
                  _buildCardContainer([
                    _buildMenuTile(
                      context,
                      Icons.settings_suggest_outlined,
                      "Pengaturan Master Data",
                      "Kelola gedung, kategori, dan ruangan",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MasterDataScreen(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 25),
                ],

                _buildSectionTitle("Akun"),
                _buildCardContainer([
                  _buildMenuTile(
                    context,
                    Icons.logout_rounded,
                    "Keluar Aplikasi",
                    "Sesi akan diakhiri dari perangkat ini",
                    () => _showLogoutDialog(context),
                    isDestructive: true,
                  ),
                ]),
                const SizedBox(height: 40),

                Text(
                  "ITI Connect v2.0.12\n© 2026 IC Dev Team",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildProfileHeader(
    Map<String, dynamic> userData,
    bool isAdmin,
    bool isSuper,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: isAdmin ? Colors.red[900] : Colors.blue[900],
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            if (isAdmin)
              CircleAvatar(
                radius: 18,
                backgroundColor: isSuper ? Colors.amber : Colors.blueAccent,
                child: Icon(
                  isSuper ? Icons.stars : Icons.verified_user,
                  size: 18,
                  color: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userData['nama'] ?? 'User ITI',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isAdmin ? Colors.red[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isSuper
                ? "SUPER ADMIN"
                : (isAdmin ? "ADMIN STAFF" : "MAHASISWA ITI"),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isAdmin ? Colors.red[900] : Colors.blue[900],
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.blue[900],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    Color color = isDestructive ? Colors.red : Colors.blue[900]!;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
    );
  }

  // --- PERBAIKAN DI SINI ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.red[50],
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red[600],
                  size: 35,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Konfirmasi Logout",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "Apakah anda yakin ingin keluar dari ITI Connect?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "BATAL",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // 1. Eksekusi Sign Out
                        await FirebaseAuth.instance.signOut();

                        if (!context.mounted) return;

                        // 2. Navigasi Paksa ke Halaman Login dan Hapus Semua Stack
                        // Kita gunakan '/login' yang sudah didaftarkan di main.dart
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "KELUAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
