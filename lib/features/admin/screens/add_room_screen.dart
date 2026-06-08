import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _nameController = TextEditingController();
  final _capController = TextEditingController();
  String? _selectedBuilding;
  String? _imageBase64;
  bool _hasAC = false;
  bool _hasProjector = false;
  String _status = 'Tersedia'; // Default status
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 25, // Kompresi agar ringan di database
    );

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() => _imageBase64 = base64Encode(bytes));
    }
  }

  Future<void> _saveRoom() async {
    // Validasi Sederhana
    if (_nameController.text.isEmpty ||
        _selectedBuilding == null ||
        _imageBase64 == null) {
      _showSnackBar("Harap lengkapi Foto, Nama, dan Gedung!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('master_rooms').add({
        'roomName': _nameController.text.trim(),
        'buildingName': _selectedBuilding,
        'capacity': int.tryParse(_capController.text) ?? 0,
        'roomImage': _imageBase64,
        'facilities': {'ac': _hasAC, 'projector': _hasProjector},
        'roomStatus': _status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar("Ruangan berhasil ditambahkan!", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Gagal menyimpan: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Tambah Ruangan Baru",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. IMAGE PICKER SECTION
                _buildSectionTitle("Foto Ruangan"),
                _buildImagePickerArea(),
                const SizedBox(height: 25),

                // 2. MAIN INFO SECTION
                _buildSectionTitle("Informasi Detail"),
                _buildCardContainer([
                  _buildTextField(
                    _nameController,
                    "Nama Ruangan",
                    Icons.meeting_room_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildBuildingDropdown(),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _capController,
                    "Kapasitas Maksimal (Kursi)",
                    Icons.people_outline,
                    isNumber: true,
                  ),
                ]),
                const SizedBox(height: 25),

                // 3. STATUS & FACILITIES SECTION
                _buildSectionTitle("Konfigurasi & Fasilitas"),
                _buildCardContainer([
                  _buildStatusDropdown(),
                  const SizedBox(height: 20),
                  const Text(
                    "Fasilitas Tersedia:",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFacilityToggle(
                        "AC",
                        _hasAC,
                        Icons.ac_unit,
                        Colors.blue,
                        (v) => setState(() => _hasAC = v),
                      ),
                      const SizedBox(width: 12),
                      _buildFacilityToggle(
                        "Proyektor",
                        _hasProjector,
                        Icons.videocam_outlined,
                        Colors.orange,
                        (v) => setState(() => _hasProjector = v),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: 40),

                // 4. SUBMIT BUTTON
                ElevatedButton(
                  onPressed: _saveRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: Colors.blue[900]!.withOpacity(0.3),
                  ),
                  child: const Text(
                    "DAFTARKAN RUANGAN",
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
    );
  }

  // --- REUSABLE WIDGETS (SAMA DENGAN EDIT SCREEN) ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blue[900],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildImagePickerArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue[900]!.withOpacity(0.1),
            width: 2,
          ),
          image: _imageBase64 != null
              ? DecorationImage(
                  image: Image.memory(base64Decode(_imageBase64!)).image,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _imageBase64 == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: Colors.blue[900],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Klik untuk Ambil Foto",
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    "Gunakan kamera HP untuk hasil terbaik",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    right: 12,
                    top: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue[900],
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.blue[900]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blue[900]!.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildBuildingDropdown() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('master_data')
          .doc('gedung')
          .snapshots(),
      builder: (context, snapshot) {
        List<String> items = snapshot.hasData
            ? List<String>.from(snapshot.data!['items'] ?? [])
            : [];
        return DropdownButtonFormField<String>(
          value: _selectedBuilding,
          decoration: InputDecoration(
            labelText: "Pilih Gedung Kampus",
            prefixIcon: Icon(
              Icons.business_outlined,
              size: 20,
              color: Colors.blue[900],
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => _selectedBuilding = v),
        );
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: InputDecoration(
        labelText: "Status Ruangan",
        prefixIcon: Icon(Icons.info_outline, size: 20, color: Colors.blue[900]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      items: ['Tersedia', 'Perbaikan', 'Non-Aktif'].map((s) {
        return DropdownMenuItem(
          value: s,
          child: Row(
            children: [
              CircleAvatar(
                radius: 4,
                backgroundColor: s == 'Tersedia' ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              Text(s),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _status = v!),
    );
  }

  Widget _buildFacilityToggle(
    String label,
    bool isSelected,
    IconData icon,
    Color color,
    Function(bool) onChanged,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(!isSelected),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? color : Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[700],
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
