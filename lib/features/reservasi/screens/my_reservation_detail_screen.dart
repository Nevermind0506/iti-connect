import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyReservationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const MyReservationDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    DateTime date = (data['date'] as Timestamp).toDate();
    String status = data['status'] ?? 'Pending';
    Color statusColor = status == 'Disetujui'
        ? Colors.green
        : (status == 'Ditolak' ? Colors.red : Colors.orange);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Bukti Perizinan Digital",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. TICKET HEADER (STATUS)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            // 2. TICKET BODY
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Nama Ruangan", data['roomName'] ?? "-"),
                  _buildInfoRow("Gedung / Lokasi", data['buildingName'] ?? "-"),
                  const Divider(height: 30),
                  _buildInfoRow(
                    "Tanggal Penggunaan",
                    DateFormat('EEEE, dd MMMM yyyy').format(date),
                  ),
                  _buildInfoRow(
                    "Waktu / Jam",
                    "${data['startTime']} - ${data['endTime']}",
                  ),
                  const Divider(height: 30),
                  _buildInfoRow(
                    "Tujuan Kegiatan",
                    data['purpose'] ?? "-",
                    isLongText: true,
                  ),

                  if (status != 'Pending') ...[
                    const Divider(height: 30),
                    const Text(
                      "DIVERIFIKASI OLEH:",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 15,
                          child: Icon(Icons.admin_panel_settings, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Admin Sarpras ITI",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              data['processedAt'] != null
                                  ? "Pada: ${DateFormat('dd/MM/yy HH:mm').format((data['processedAt'] as Timestamp).toDate())}"
                                  : "",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FOOTER INFO
            const Text(
              "Tunjukkan halaman ini kepada petugas keamanan gedung jika diperlukan. Perizinan ini sah secara digital melalui sistem ITI Connect.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isLongText ? FontWeight.normal : FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
