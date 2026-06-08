import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategory;
  String? _selectedGedung;
  String? _selectedRuangan; // Menggantikan roomController
  String? _imageBase64;
  bool _isLoading = false;
  String _selectedPriority = "Sedang";

  final List<String> _priorityList = ["Rendah", "Sedang", "Tinggi"];

  String _generateTicketId() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final uniqueStr = now.microsecondsSinceEpoch.toString().substring(10);
    return "ITI-$dateStr-$uniqueStr";
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  void _submitReport() async {
    // Validasi data
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _imageBase64 == null ||
        _selectedGedung == null ||
        _selectedRuangan == null) {
      _showSnackBar(
        "Harap lengkapi semua data, lokasi gedung/ruangan, dan foto bukti",
        Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    final ticketId = _generateTicketId();

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      String namaPelapor = userDoc.data()?['nama'] ?? "Anonim";

      await FirebaseFirestore.instance.collection('reports').add({
        'ticketId': ticketId,
        'uid': user?.uid,
        'namaPelapor': namaPelapor,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'gedung': _selectedGedung,
        'ruangan':
            _selectedRuangan, // Sekarang menyimpan nama ruangan dari Master Data
        'priority': _selectedPriority,
        'imageUrl': _imageBase64,
        'status': 'Pending',
        'responses': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar("Laporan Berhasil Dikirim! ID: $ticketId", Colors.green);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Gagal mengirim laporan: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Buat Laporan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Detail Masalah",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Pilih lokasi yang spesifik agar petugas ITI mudah menemukan kendala.",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 25),

            _buildLabel("Judul Laporan"),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration("Contoh: Lampu Kelas Mati"),
            ),
            const SizedBox(height: 20),

            _buildLabel("Kategori"),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),

            // SECTION LOKASI
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildLabel("Gedung"), _buildGedungDropdown()],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildLabel("Ruangan"), _buildRuanganDropdown()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel("Tingkat Prioritas"),
            _buildPrioritySelection(),
            const SizedBox(height: 25),

            _buildLabel("Deskripsi Masalah"),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: _inputDecoration(
                "Jelaskan detail kendala secara lengkap...",
              ),
            ),
            const SizedBox(height: 25),

            _buildLabel("Foto Bukti"),
            _buildImagePicker(),
            const SizedBox(height: 40),

            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildCategoryDropdown() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('master_data')
          .doc('kategori')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        List<dynamic> items = snapshot.data!['items'] ?? [];
        if (_selectedCategory == null && items.isNotEmpty)
          _selectedCategory = items.first;
        return _styledDropdown(
          value: _selectedCategory,
          items: items.map((cat) => cat.toString()).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        );
      },
    );
  }

  Widget _buildGedungDropdown() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('master_data')
          .doc('gedung')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 20);
        List<dynamic> items = snapshot.data!['items'] ?? [];
        return _styledDropdown(
          value: _selectedGedung,
          items: items.map((g) => g.toString()).toList(),
          hint: "Pilih Gedung",
          onChanged: (val) {
            setState(() {
              _selectedGedung = val;
              _selectedRuangan = null; // Reset ruangan saat gedung ganti
            });
          },
        );
      },
    );
  }

  Widget _buildRuanganDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('master_rooms')
          .where('buildingName', isEqualTo: _selectedGedung)
          .snapshots(),
      builder: (context, snapshot) {
        if (_selectedGedung == null) return _disabledField("Pilih Gedung");
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final rooms = snapshot.data!.docs
            .map((doc) => doc['roomName'].toString())
            .toList();

        return _styledDropdown(
          value: _selectedRuangan,
          items: rooms,
          hint: "Pilih Ruangan",
          onChanged: (val) => setState(() => _selectedRuangan = val),
        );
      },
    );
  }

  Widget _styledDropdown({
    String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint ?? ""),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _disabledField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        hint,
        style: TextStyle(color: Colors.grey[400], fontSize: 13),
      ),
    );
  }

  Widget _buildPrioritySelection() {
    return Row(
      children: _priorityList.map((p) {
        bool isSelected = _selectedPriority == p;
        Color pColor = p == "Tinggi"
            ? Colors.red
            : (p == "Sedang" ? Colors.orange : Colors.blue);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Center(
                child: Text(
                  p,
                  style: TextStyle(
                    color: isSelected ? Colors.white : pColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              selected: isSelected,
              selectedColor: pColor,
              backgroundColor: Colors.white,
              side: BorderSide(color: pColor),
              onSelected: (val) => setState(() => _selectedPriority = p),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue[100]!, width: 2),
        ),
        child: _imageBase64 == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 40,
                    color: Color(0xFF0D47A1),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Ambil Foto Bukti",
                    style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  base64Decode(_imageBase64!),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "KIRIM LAPORAN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.blue[900]!, width: 2),
      ),
    );
  }
}
