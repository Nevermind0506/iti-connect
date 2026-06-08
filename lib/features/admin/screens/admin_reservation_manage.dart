import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iti_connect/features/admin/screens/admin_calendar_view.dart';
import 'admin_reservation_detail_screen.dart';

class AdminReservationManage extends StatefulWidget {
  const AdminReservationManage({super.key});

  @override
  State<AdminReservationManage> createState() => _AdminReservationManageState();
}

class _AdminReservationManageState extends State<AdminReservationManage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .snapshots(),
        builder: (context, snapshot) {
          // Hitung Statistik Real-time
          int total = 0;
          int pending = 0;
          int approved = 0;
          int rejected = 0;

          if (snapshot.hasData) {
            total = snapshot.data!.docs.length;
            pending = snapshot.data!.docs
                .where((d) => d['status'] == 'Pending')
                .length;
            approved = snapshot.data!.docs
                .where((d) => d['status'] == 'Disetujui')
                .length;
            rejected = snapshot.data!.docs
                .where((d) => d['status'] == 'Ditolak')
                .length;
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.blue[900],
                flexibleSpace: FlexibleSpaceBar(
                  // Menggunakan Stack untuk menumpuk ikon di atas background statistik
                  background: Stack(
                    children: [
                      // 1. Background Statistik Utama
                      _buildHeaderStats(total, pending, approved, rejected),

                      // 2. Ikon Kalender dengan Posisi Kustom (Hanya untuk Admin/Superadmin)
                      Positioned(
                        top:
                            70, // Posisi di antara Statistik dan Dashboard Kontrol
                        right: 20, // Jarak dari tepi kanan
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .get(),
                          builder: (context, userSnap) {
                            if (userSnap.hasData) {
                              // Mengambil role pengguna dari Firestore
                              String role =
                                  userSnap.data?.get('role') ?? 'user';

                              // Pengecekan level akses
                              if (role == 'admin' || role == 'superadmin') {
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      // Aksi menuju halaman kalender
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AdminCalendarView(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(
                                          0.15,
                                        ), // Efek glassmorphism
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_month_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.orangeAccent,
                  indicatorWeight: 4,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: "Antrean"),
                    Tab(text: "Disetujui"),
                    Tab(text: "Ditolak"),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildReservationList('Pending'),
                _buildReservationList('Disetujui'),
                _buildReservationList('Ditolak'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderStats(int total, int pending, int approved, int rejected) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Statistik Reservasi",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            "Dashboard Kontrol",
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
              _buildStatItem("Total", total.toString(), Icons.analytics),
              _buildStatItem(
                "Antrean",
                pending.toString(),
                Icons.timer_outlined,
              ),
              _buildStatItem(
                "Disetujui",
                approved.toString(),
                Icons.check_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 40), // Ruang ekstra untuk TabBar
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
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

  Widget _buildReservationList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState(status);

        final sortedDocs = docs.toList()
          ..sort((a, b) {
            Timestamp t1 = a['createdAt'] ?? Timestamp.now();
            Timestamp t2 = b['createdAt'] ?? Timestamp.now();
            return t2.compareTo(t1);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            var data = sortedDocs[index].data() as Map<String, dynamic>;
            String docId = sortedDocs[index].id;
            DateTime date = data['date'] is Timestamp
                ? (data['date'] as Timestamp).toDate()
                : DateTime.now();

            return _buildModernCard(context, data, docId, date);
          },
        );
      },
    );
  }

  Widget _buildModernCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    DateTime date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminReservationDetailScreen(
                docId: docId,
                reservationData: data,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "ID: ${docId.substring(0, 5).toUpperCase()}",
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${data['startTime']} - ${data['endTime']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  data['roomName'] ?? "Ruangan",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.business, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      data['buildingName'] ?? "-",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(date),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(height: 30),
                // INFO PEMESAN (Disederhanakan untuk list)
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(data['uid'])
                      .get(),
                  builder: (context, userSnap) {
                    String senderName = "...";
                    if (userSnap.hasData) {
                      senderName =
                          userSnap.data?.get('nama') ??
                          userSnap.data?.get('username') ??
                          "Anonim";
                    }
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue[900],
                          child: const Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Pemesan: $senderName",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[100]),
          const SizedBox(height: 10),
          Text(
            "Tidak ada reservasi $status",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
