import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iti_connect/services/fcm_controller.dart';

class AdminReservationDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> reservationData;

  const AdminReservationDetailScreen({
    super.key,
    required this.docId,
    required this.reservationData,
  });

  @override
  State<AdminReservationDetailScreen> createState() =>
      _AdminReservationDetailScreenState();
}

class _AdminReservationDetailScreenState
    extends State<AdminReservationDetailScreen> {
  bool _isProcessing = false;
  bool _isSuperAdmin = false;
  String _currentAdminName = "";

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  Future<void> _checkAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          String role = (doc.data()?['role'] ?? '').toString().toLowerCase();
          String level = (doc.data()?['level'] ?? '').toString().toLowerCase();
          _isSuperAdmin = (role == 'superadmin' || level == 'superadmin');
          _currentAdminName =
              doc.data()?['nama'] ?? doc.data()?['name'] ?? "Admin ITI";
        });
      }
    }
  }

  Future<bool> _checkConflict() async {
    final data = widget.reservationData;
    final query = await FirebaseFirestore.instance
        .collection('reservations')
        .where('roomId', isEqualTo: data['roomId'])
        .where('date', isEqualTo: data['date'])
        .where('status', isEqualTo: 'Disetujui')
        .get();

    for (var doc in query.docs) {
      if (doc.id == widget.docId) continue;
      String existStart = doc['startTime'];
      String existEnd = doc['endTime'];
      if (data['startTime'].compareTo(existEnd) < 0 &&
          data['endTime'].compareTo(existStart) > 0) {
        return true;
      }
    }
    return false;
  }

  void _handleUpdateStatus(String newStatus) async {
    if (_isSuperAdmin) return;

    String? note;
    if (newStatus == 'Ditolak') {
      note = await _showEnhancedRejectDialog();
      if (note == null) return;
    }

    setState(() => _isProcessing = true);

    if (newStatus == 'Disetujui') {
      if (await _checkConflict()) {
        if (mounted) {
          _showSnackBar(
            "BENTROK! Ruangan sudah dipesan di jam ini.",
            Colors.red,
          );
          setState(() => _isProcessing = false);
          return;
        }
      }
    }

    final user = FirebaseAuth.instance.currentUser;

    // 1. Jalankan Update ke Firestore
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(widget.docId)
        .update({
          'status': newStatus,
          'adminNote': note,
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': _currentAdminName,
          'adminUid': user?.uid,
        });

    // 2. LOGIKA PENGIRIMAN NOTIFIKASI
    try {
      // Ambil UID mahasiswa dari data reservasi (widget.reservationData)
      String mahasiswaUid = widget.reservationData['uid'];

      // Ambil dokumen user mahasiswa untuk mendapatkan deviceToken
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(mahasiswaUid)
          .get();

      if (userDoc.exists) {
        String? token = userDoc.get('deviceToken');

        if (token != null && token.isNotEmpty) {
          // Tentukan pesan berdasarkan status baru
          String title = newStatus == 'Disetujui'
              ? "Reservasi Disetujui! 🏛️"
              : "Reservasi Ditolak ❌";

          String body = newStatus == 'Disetujui'
              ? "Peminjaman ruangan ${widget.reservationData['roomName']} telah diizinkan."
              : "Mohon maaf, reservasi ruangan Anda ditolak. Alasan: ${note ?? '-'}";

          // Kirim via FCMController
          await FCMController.sendPushNotification(
            token: token,
            receiverUid: mahasiswaUid, // TAMBAHKAN BARIS INI JUGA
            title: title,
            body: body,
          );
        }
      }
    } catch (e) {
      print("Gagal mengirim notifikasi: $e");
      // Kita tidak menghentikan proses utama jika hanya notifikasi yang gagal
    }

    if (mounted) {
      // Tutup halaman setelah semua proses (termasuk notif) selesai
      Navigator.pop(context);
      _showSnackBar("Reservasi berhasil di-$newStatus", Colors.green);
    }
  }

  // DIALOG TOLAK YANG DIPERBAGUS
  Future<String?> _showEnhancedRejectDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.red[50],
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Alasan Penolakan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                "Berikan alasan agar pemesan dapat memahami penolakan ini.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      "Contoh: Ruangan digunakan untuk acara mendadak rektorat...",
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "BATAL",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "KONFIRMASI",
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

  @override
  Widget build(BuildContext context) {
    var data = widget.reservationData;
    DateTime date = (data['date'] as Timestamp).toDate();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Detail Perizinan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. HEADER DATA PEMESAN
            _buildSectionCard(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['uid'])
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  var userData = snapshot.data?.data() as Map<String, dynamic>?;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blue[900],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData?['nama'] ?? "User ITI",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            "NIM: ${userData?['nim'] ?? '-'}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 2. RINCIAN RESERVASI
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(
                    Icons.meeting_room,
                    "Ruangan",
                    data['roomName'],
                  ),
                  _buildDetailItem(
                    Icons.business,
                    "Gedung",
                    data['buildingName'],
                  ),
                  _buildDetailItem(
                    Icons.calendar_today,
                    "Tanggal",
                    DateFormat('EEEE, dd MMM yyyy').format(date),
                  ),
                  _buildDetailItem(
                    Icons.access_time,
                    "Waktu",
                    "${data['startTime']} - ${data['endTime']}",
                  ),
                  const Divider(height: 30),
                  const Text(
                    "Tujuan Penggunaan:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['purpose'] ?? "-",
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. LAMPIRAN DOKUMEN
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lampiran Surat Izin",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildImageAttachment(data['permitImage']),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 4. ACTION BUTTONS / AUDIT LOG
            if (data['status'] == 'Pending')
              _isSuperAdmin ? _buildSuperAdminNotice() : _buildActionButtons()
            else
              _buildAuditLog(data),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue[900]),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isProcessing) return const Center(child: CircularProgressIndicator());
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _handleUpdateStatus('Ditolak'),
            child: const Text(
              "TOLAK",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.blue[900]!.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => _handleUpdateStatus('Disetujui'),
            child: const Text(
              "IZINKAN",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLog(Map<String, dynamic> data) {
    Color color = data['status'] == 'Disetujui' ? Colors.green : Colors.red;
    return _buildSectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: color),
              const SizedBox(width: 10),
              Text(
                "Audit Log Perizinan",
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const Divider(height: 30),
          _buildDetailItem(
            Icons.person_pin,
            "Admin",
            data['processedBy'] ?? "Sistem",
          ),
          _buildDetailItem(
            Icons.history,
            "Diproses",
            data['processedAt'] != null
                ? DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format((data['processedAt'] as Timestamp).toDate())
                : "-",
          ),
          if (data['adminNote'] != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                "Catatan: ${data['adminNote']}",
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageAttachment(String? base64) {
    if (base64 == null)
      return const Text(
        "Tidak ada dokumen",
        style: TextStyle(color: Colors.grey),
      );
    return InkWell(
      onTap: () => _showFullImage(base64),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.memory(
              base64Decode(base64),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black26, height: 180),
            const Icon(Icons.zoom_in, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperAdminNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Superadmin hanya diizinkan untuk memantau data tanpa mengubah status.",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String base64) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, _, __) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(child: Image.memory(base64Decode(base64))),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
