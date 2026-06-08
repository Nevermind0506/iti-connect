import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'report_detail_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  String _selectedCategory = "Semua";

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. COMPACT APPBAR - RATA KIRI
          SliverAppBar(
            expandedHeight:
                110.0, // Diperkecil agar tidak terlalu memakan layar
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.blue[900],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false, // PAKSA RATA KIRI
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                "Laporan Saya",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[900]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // 2. SUMMARY STATS SECTION
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('uid', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int total = snapshot.data?.docs.length ?? 0;
                int pending =
                    snapshot.data?.docs
                        .where((d) => d['status'] == 'Pending')
                        .length ??
                    0;
                int selesai =
                    snapshot.data?.docs
                        .where((d) => d['status'] == 'Selesai')
                        .length ??
                    0;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      _buildStatItem("Total", total.toString(), Colors.blue),
                      const SizedBox(width: 10),
                      _buildStatItem(
                        "Proses",
                        pending.toString(),
                        Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      _buildStatItem(
                        "Selesai",
                        selesai.toString(),
                        Colors.green,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. CATEGORY FILTER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('master_data')
                    .doc('kategori')
                    .snapshots(),
                builder: (context, snapshot) {
                  List<String> categories = ["Semua"];
                  if (snapshot.hasData && snapshot.data!.exists) {
                    categories.addAll(
                      List<String>.from(snapshot.data!['items'] ?? []),
                    );
                  }

                  return SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        bool isSelected =
                            _selectedCategory == categories[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(categories[index]),
                            selected: isSelected,
                            onSelected: (v) => setState(
                              () => _selectedCategory = categories[index],
                            ),
                            selectedColor: Colors.blue[900],
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blue[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.blue[900]!
                                    : Colors.blue[900]!.withOpacity(0.1),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. REPORT LIST
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredStream(user?.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return _buildEmptyState();

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    data['id'] = docs[index].id;
                    return _buildModernReportCard(context, data);
                  }, childCount: docs.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-report'),
        backgroundColor: Colors.blue[900],
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Buat Laporan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredStream(String? uid) {
    var base = FirebaseFirestore.instance
        .collection('reports')
        .where('uid', isEqualTo: uid);
    if (_selectedCategory != "Semua") {
      base = base.where('category', isEqualTo: _selectedCategory);
    }
    return base.snapshots();
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernReportCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    Color priorityColor = data['priority'] == "Tinggi"
        ? Colors.red
        : (data['priority'] == "Sedang" ? Colors.orange : Colors.blue);
    String status = data['status'] ?? 'Pending';
    Color statusColor = status == 'Selesai'
        ? Colors.green
        : (status == 'Diproses' ? Colors.blue : Colors.orange);

    return Container(
      height: 130, // Tinggi proporsional
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(reportData: data),
          ),
        ),
        child: Row(
          children: [
            // IMAGE SECTION
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: SizedBox(
                width: 100,
                height: 130,
                child: data['imageUrl'] != null
                    ? Image.memory(
                        base64Decode(data['imageUrl']),
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            // CONTENT SECTION
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['ticketId'] ?? "#REF",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900]!.withOpacity(0.4),
                          ),
                        ),
                        _buildStatusBadge(status, statusColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['title'] ?? "Judul Laporan",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: Colors.blue[900],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${data['gedung'] ?? 'ITI'} • ${data['ruangan'] ?? '-'}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            data['priority'] ?? "!",
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
      child: Center(
        child: Text(
          "Belum Ada Laporan",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }
}
