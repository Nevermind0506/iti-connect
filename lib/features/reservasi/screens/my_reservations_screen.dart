import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'my_reservation_detail_screen.dart'; // Halaman bukti perizinan // Digunakan untuk fungsi edit

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          Colors.grey[50], // Ubah ke abu-abu muda agar card lebih pop-up
      appBar: AppBar(
        title: const Text(
          "Riwayat Reservasi Saya",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('uid', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          // Urutkan manual (Terbaru di atas)
          final sortedDocs = docs.toList()
            ..sort((a, b) {
              Timestamp t1 = a['createdAt'] ?? Timestamp.now();
              Timestamp t2 = b['createdAt'] ?? Timestamp.now();
              return t2.compareTo(t1);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;
              data['id'] =
                  sortedDocs[index].id; // Masukkan ID dokumen ke Map data
              return _buildReservationCard(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    String status = data['status'] ?? 'Pending';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Disetujui':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'Ditolak':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions_rounded;
    }

    DateTime date = (data['date'] as Timestamp).toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // --- MENUJU HALAMAN BUKTI PERIZINAN ---
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyReservationDetailScreen(data: data),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Text(
                    data['roomName'] ?? "Ruangan",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "${data['buildingName']} • ${DateFormat('dd MMM yyyy').format(date)}",
                      ),
                      Text(
                        "Jam: ${data['startTime']} - ${data['endTime']}",
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),

                // Status Bar Kecil di Bawah Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  color: statusColor.withOpacity(0.05),
                  child: Row(
                    children: [
                      Text(
                        "STATUS: ${status.toUpperCase()}",
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // TOMBOL AKSI (Hanya jika PENDING)
                if (status == 'Pending')
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _confirmCancel(context, data['id']),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text(
                              "Batalkan",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Logika Edit (Bisa menggunakan AddReservationScreen dengan parameter tambahan)
                              _showSnackBar(
                                context,
                                "Gunakan fitur Edit pada detail bukti.",
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text(
                              "Edit",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Alasan Penolakan
                if (status == 'Ditolak' && data['adminNote'] != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red[50],
                    child: Text(
                      "Catatan Admin: ${data['adminNote']}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, String resId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Batalkan Reservasi?"),
        content: const Text(
          "Data pengajuan anda akan dihapus permanen dari sistem.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("TIDAK"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('reservations')
                  .doc(resId)
                  .delete();
              if (context.mounted) Navigator.pop(context);
              _showSnackBar(context, "Reservasi berhasil dibatalkan");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "YA, HAPUS",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          const Text(
            "Belum ada reservasi dibuat",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
