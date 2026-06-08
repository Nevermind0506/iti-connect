import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iti_connect/features/admin/screens/master_data_screen.dart';
import 'package:iti_connect/features/admin/screens/user_management_screen.dart';
import '../../pelaporan/screens/report_detail_screen.dart';

class AdminReportListScreen extends StatefulWidget {
  const AdminReportListScreen({super.key});

  @override
  State<AdminReportListScreen> createState() => _AdminReportListScreenState();
}

class _AdminReportListScreenState extends State<AdminReportListScreen>
    with SingleTickerProviderStateMixin {
  String _userRole = 'mahasiswa';
  String _userLevel = 'user';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserContext();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = (doc.data()?['role'] ?? 'mahasiswa')
              .toString()
              .toLowerCase();
          _userLevel = (doc.data()?['level'] ?? 'user')
              .toString()
              .toLowerCase();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSuperAdmin =
        (_userLevel == 'superadmin' || _userRole == 'superadmin');

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Terjadi kesalahan data"));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final allDocs = snapshot.data!.docs;
          int total = allDocs.length;
          int selesai = allDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['status'] == 'Selesai';
          }).length;
          double progress = total == 0 ? 0 : selesai / total;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 240.0,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.blue[900],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(total, progress, isSuperAdmin),
                  collapseMode: CollapseMode.pin,
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: Colors.blue[900],
                    child: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      controller: _tabController,
                      indicatorColor: Colors.greenAccent,
                      indicatorWeight: 4,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: "Semua"),
                        Tab(text: "Antrean"),
                        Tab(text: "Proses"),
                        Tab(text: "Selesai"),
                      ],
                    ),
                  ),
                ),
              ),
              if (isSuperAdmin)
                SliverToBoxAdapter(child: _buildQuickActions(context)),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildReportList(allDocs),
                _buildReportList(
                  allDocs
                      .where(
                        (d) =>
                            (d.data() as Map<String, dynamic>)['status'] ==
                                'Pending' ||
                            (d.data() as Map<String, dynamic>)['status'] ==
                                'Antrean',
                      )
                      .toList(),
                ),
                _buildReportList(
                  allDocs
                      .where(
                        (d) =>
                            (d.data() as Map<String, dynamic>)['status'] ==
                            'Diproses',
                      )
                      .toList(),
                ),
                _buildReportList(
                  allDocs
                      .where(
                        (d) =>
                            (d.data() as Map<String, dynamic>)['status'] ==
                            'Selesai',
                      )
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int total, double progress, bool isSuper) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuper ? "Superuser Command" : "Staff Monitoring",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Text(
              "Dashboard Laporan",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeaderStat("Total Masuk", "$total"),
                _buildHeaderStat(
                  "Penyelesaian",
                  "${(progress * 100).toInt()}%",
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Management",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionCard(
                context,
                "Pengguna",
                Icons.badge_outlined,
                Colors.blue,
                const UserManagementScreen(),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                context,
                "Master Data",
                Icons.storage_rounded,
                Colors.purple,
                const MasterDataScreen(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportList(List<DocumentSnapshot> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Text(
          "Tidak ada laporan di kategori ini",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final data = reports[index].data() as Map<String, dynamic>;
        data['id'] = reports[index].id;
        return _buildReportItem(context, data);
      },
    );
  }

  Widget _buildReportItem(BuildContext context, Map<String, dynamic> data) {
    Color priorityColor = data['priority'] == "Tinggi"
        ? Colors.red
        : (data['priority'] == "Sedang" ? Colors.orange : Colors.blue);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportDetailScreen(reportData: data),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        data['imageUrl'] != null &&
                            data['imageUrl'].toString().isNotEmpty
                        ? (data['imageUrl'].toString().startsWith('http')
                              ? Image.network(
                                  data['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Image.memory(
                                  base64Decode(data['imageUrl']),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ))
                        : Container(
                            color: Colors.grey[100],
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.image_outlined),
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['ticketId'] ?? "ID-UNK",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          data['title'] ?? "No Title",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(data['status'] ?? 'Pending'),
                ],
              ),
              const Divider(height: 25),
              Row(
                children: [
                  _buildLocationChip(Icons.business, data['gedung'] ?? 'ITI'),
                  const SizedBox(width: 8),
                  _buildLocationChip(
                    Icons.meeting_room,
                    data['ruangan'] ?? 'Ruang Umum',
                  ),
                  const Spacer(),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data['priority'] ?? "Normal",
                    style: TextStyle(
                      fontSize: 12,
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pelapor: ${data['namaPelapor'] ?? 'Anonim'}",
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.blue[900]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue[900],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'Selesai'
        ? Colors.green
        : (status == 'Diproses' ? Colors.blue : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
