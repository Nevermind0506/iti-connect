import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iti_connect/features/admin/screens/add_admin_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white, // Latar belakang bersih
        appBar: AppBar(
          title: const Text(
            "Manajemen Pengguna",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[900],
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.blue[900],
            indicatorWeight: 3,
            labelColor: Colors.blue[900],
            unselectedLabelColor: Colors.grey[400],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Mahasiswa"),
              Tab(text: "Admin & Staff"),
            ],
          ),
        ),
        body: Column(
          children: [
            // SEARCH BAR DENGAN DESAIN MODERN
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Cari nama...",
                  prefixIcon: Icon(Icons.search, color: Colors.blue[900]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildUserList("mahasiswa"),
                  _buildUserList("admin"),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAdminScreen()),
            );
          },
          backgroundColor: Colors.blue[900],
          icon: const Icon(Icons.add_moderator_rounded, color: Colors.white),
          label: const Text(
            "Admin Baru",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(String roleFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs.where((doc) {
          String role = (doc['role'] ?? "mahasiswa").toString().toLowerCase();
          String name = (doc['nama'] ?? "").toString().toLowerCase();

          bool matchRole = roleFilter == "admin"
              ? (role == "admin" || role == "superadmin")
              : (role == "mahasiswa");

          return matchRole && name.contains(_searchQuery);
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
                Text(
                  "Tidak ditemukan",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            var userData = users[index].data() as Map<String, dynamic>;
            String role = userData['role'] ?? "mahasiswa";

            // Palet Warna Harmonis
            Color themeColor = role == "superadmin"
                ? const Color(0xFFE53935) // Deep Red
                : (role == "admin"
                      ? const Color(0xFFFFB300)
                      : const Color(0xFF1E88E5));

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundColor: themeColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person_rounded,
                    color: themeColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  userData['nama'] ?? "User",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  userData['nim'] ?? "Tanpa NIM",
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => _showUserDetail(context, userData, themeColor),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetail(
    BuildContext context,
    Map<String, dynamic> userData,
    Color themeColor,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: themeColor.withOpacity(0.1),
              child: Icon(Icons.person, color: themeColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              userData['nama'] ?? "-",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            Text(
              userData['email'] ?? "-",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildDetailTile(Icons.badge_outlined, "NIM / ID", userData['nim']),
            _buildDetailTile(
              Icons.admin_panel_settings_outlined,
              "Role",
              userData['role'],
            ),
            _buildDetailTile(
              Icons.verified_user_outlined,
              "Level Akses",
              userData['level'],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Tutup",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                value ?? "-",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
