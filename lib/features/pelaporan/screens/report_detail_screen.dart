import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:iti_connect/services/fcm_controller.dart'; // Import FCM Controller

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailScreen({super.key, required this.reportData});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Map<String, dynamic> currentData;

  @override
  void initState() {
    super.initState();
    currentData = widget.reportData;
  }

  // --- FUNGSI HAPUS LAPORAN (MAHASISWA) ---
  void _deleteReport(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
            SizedBox(height: 15),
            Text("Hapus Laporan?", textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          "Tindakan ini akan menghapus laporan secara permanen dari sistem ITI Connect.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('reports')
                  .doc(currentData['id'])
                  .delete();
              if (!context.mounted) return;
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Laporan berhasil dihapus"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              "Ya, Hapus",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI EDIT LAPORAN (MAHASISWA) ---
  void _showEditSheet(BuildContext context) {
    final titleEdit = TextEditingController(text: currentData['title']);
    final descEdit = TextEditingController(text: currentData['description']);
    String? editGedung = currentData['gedung'];
    String? editRuangan = currentData['ruangan'];
    String? editCategory = currentData['category'];
    String editPriority = currentData['priority'] ?? "Sedang";
    String? editImageBase64 = currentData['imageUrl'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 15,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Edit Detail Laporan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),

                // Edit Foto
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 50,
                      );
                      if (pickedFile != null) {
                        final bytes = await File(pickedFile.path).readAsBytes();
                        setModalState(
                          () => editImageBase64 = base64Encode(bytes),
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: editImageBase64 != null
                              ? Image.memory(
                                  base64Decode(editImageBase64!),
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 150,
                                  width: double.infinity,
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.camera_alt, size: 40),
                                ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.blue[900],
                            radius: 18,
                            child: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildEditField(titleEdit, "Judul Laporan", Icons.title),
                const SizedBox(height: 15),

                _buildLabel("Kategori"),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('master_data')
                      .doc('kategori')
                      .snapshots(),
                  builder: (context, snapshot) {
                    List<String> cats = snapshot.hasData
                        ? List<String>.from(snapshot.data!['items'] ?? [])
                        : [];
                    return _buildEditDropdown(
                      editCategory,
                      cats,
                      (val) => setModalState(() => editCategory = val),
                    );
                  },
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Gedung"),
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('master_data')
                                .doc('gedung')
                                .snapshots(),
                            builder: (context, snapshot) {
                              List<String> builds = snapshot.hasData
                                  ? List<String>.from(
                                      snapshot.data!['items'] ?? [],
                                    )
                                  : [];
                              return _buildEditDropdown(editGedung, builds, (
                                val,
                              ) {
                                setModalState(() {
                                  editGedung = val;
                                  editRuangan = null;
                                });
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Ruangan"),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('master_rooms')
                                .where('buildingName', isEqualTo: editGedung)
                                .snapshots(),
                            builder: (context, snapshot) {
                              List<String> rooms = snapshot.hasData
                                  ? snapshot.data!.docs
                                        .map((d) => d['roomName'].toString())
                                        .toList()
                                  : [];
                              return _buildEditDropdown(
                                editRuangan,
                                rooms,
                                (val) => setModalState(() => editRuangan = val),
                                hint: "Pilih Ruang",
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                _buildEditField(
                  descEdit,
                  "Deskripsi",
                  Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('reports')
                        .doc(currentData['id'])
                        .update({
                          'title': titleEdit.text.trim(),
                          'description': descEdit.text.trim(),
                          'gedung': editGedung,
                          'ruangan': editRuangan,
                          'category': editCategory,
                          'priority': editPriority,
                          'imageUrl': editImageBase64,
                        });
                    setState(() {
                      currentData['title'] = titleEdit.text.trim();
                      currentData['description'] = descEdit.text.trim();
                      currentData['gedung'] = editGedung;
                      currentData['ruangan'] = editRuangan;
                      currentData['category'] = editCategory;
                      currentData['imageUrl'] = editImageBase64;
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Laporan berhasil diperbarui"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(55),
                    backgroundColor: Colors.blue[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "SIMPAN PERUBAHAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FUNGSI ADMIN (UPDATE STATUS + PUSH NOTIFIKASI) ---
  void _updateStatusAndAddResponse(
    BuildContext context,
    String newStatus,
    String responseText,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      String adminName = adminDoc.data()?['nama'] ?? "Admin ITI";

      // 1. Jalankan update data ke Firestore
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(currentData['id'])
          .update({
            'status': newStatus,
            'responses': FieldValue.arrayUnion([
              {
                'text': responseText,
                'adminName': adminName,
                'timestamp': DateTime.now().toIso8601String(),
              },
            ]),
          });

      // 2. Kirim Notifikasi ke Mahasiswa Pelapor
      try {
        String mahasiswaUid = currentData['uid'];
        DocumentSnapshot mahasisaDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(mahasiswaUid)
            .get();

        if (mahasisaDoc.exists) {
          String? token = mahasisaDoc.get('deviceToken');
          if (token != null && token.isNotEmpty) {
            await FCMController.sendPushNotification(
              token: token,
              receiverUid: mahasiswaUid, // TAMBAHKAN BARIS INI
              title: "Update Laporan: $newStatus 🦉",
              body: "Admin: $responseText",
            );
          }
        }
      } catch (fcmError) {
        debugPrint("Gagal kirim notifikasi: $fcmError");
      }

      if (!context.mounted) return;
      Navigator.pop(context); // Tutup sheet
      Navigator.pop(context); // Kembali ke list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Laporan berhasil diperbarui ke: $newStatus"),
          backgroundColor: Colors.blue[900],
        ),
      );
    } catch (e) {
      debugPrint("Error update: $e");
    }
  }

  void _showAdminActionSheet(BuildContext context) {
    final TextEditingController responseController = TextEditingController();
    String selectedStatus = currentData['status'] ?? 'Pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Update Progress",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: ['Pending', 'Diproses', 'Selesai'].contains(selectedStatus)
                  ? selectedStatus
                  : 'Pending',
              decoration: const InputDecoration(
                labelText: "Status Laporan",
                border: OutlineInputBorder(),
              ),
              items: [
                'Pending',
                'Diproses',
                'Selesai',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => selectedStatus = val!,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: responseController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Tanggapan admin...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _updateStatusAndAddResponse(
                context,
                selectedStatus,
                responseController.text,
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue[900],
              ),
              child: const Text(
                "KIRIM UPDATE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isOwner = currentData['uid'] == user?.uid;
    bool isPending = currentData['status'] == 'Pending';

    String formattedDate = "";
    if (currentData['createdAt'] != null) {
      DateTime dt = (currentData['createdAt'] as Timestamp).toDate();
      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    }

    Color priorityColor = currentData['priority'] == "Tinggi"
        ? Colors.red
        : (currentData['priority'] == "Sedang" ? Colors.orange : Colors.blue);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          currentData['ticketId'] ?? 'Detail Laporan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (isOwner && isPending)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteReport(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (currentData['imageUrl'] != null)
                  Image.memory(
                    base64Decode(currentData['imageUrl']),
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: _buildBadge(
                    currentData['priority'] ?? 'Sedang',
                    priorityColor,
                    isFilled: true,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge(
                        currentData['category'] ?? 'Fasilitas',
                        Colors.blue[900]!,
                      ),
                      _buildBadge(
                        currentData['status'] ?? 'Pending',
                        currentData['status'] == 'Selesai'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentData['title'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Divider(height: 40),

                  _buildSectionTitle("Lokasi"),
                  _buildLocationCard(
                    currentData['gedung'],
                    currentData['ruangan'],
                  ),
                  const SizedBox(height: 25),

                  _buildSectionTitle("Deskripsi"),
                  Text(
                    currentData['description'] ?? 'Tidak ada deskripsi.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),

                  const Divider(height: 40),

                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      var userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      String role = userData['role'] ?? 'mahasiswa';
                      bool isAdmin = (role == 'admin' || role == 'superadmin');

                      return Column(
                        children: [
                          _buildResponseLog(currentData['responses'] ?? []),
                          const SizedBox(height: 20),

                          if (isOwner && isPending)
                            ElevatedButton.icon(
                              onPressed: () => _showEditSheet(context),
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit Laporan"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),

                          if (isAdmin)
                            ElevatedButton.icon(
                              onPressed: () => _showAdminActionSheet(context),
                              icon: const Icon(Icons.add_comment_rounded),
                              label: const Text("Update Tanggapan Admin"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[900],
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(String? gedung, String? ruangan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: Colors.blue[900]),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gedung ?? 'Gedung ITI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              Text(
                "Ruangan: ${ruangan ?? '-'}",
                style: TextStyle(color: Colors.blue[700], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildResponseLog(List<dynamic> responses) {
    if (responses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Riwayat Perbaikan"),
        ...responses.reversed.map((res) {
          DateTime time = DateTime.parse(res['timestamp']);
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      res['adminName'] ?? "Admin",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(time),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  res['text'] ?? "",
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBadge(String text, Color color, {bool isFilled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isFilled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isFilled ? null : Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: isFilled ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  // Widget Helper UI untuk Edit
  Widget _buildEditField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.blue[900]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  Widget _buildEditDropdown(
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    String hint = "Pilih",
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue[900],
        ),
      ),
    );
  }
}
