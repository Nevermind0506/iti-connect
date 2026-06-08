import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddReservationScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String buildingName;

  const AddReservationScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.buildingName,
  });

  @override
  State<AddReservationScreen> createState() => _AddReservationScreenState();
}

class _AddReservationScreenState extends State<AddReservationScreen> {
  final _purposeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _permitImageBase64;
  bool _isTermsAgreed = false;
  bool _isLoading = false;

  // Validasi Jam 08:00 - 16:00
  bool _isValidTime(TimeOfDay time) {
    return time.hour >= 8 && time.hour < 16;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)), // Aturan H-1
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? const TimeOfDay(hour: 8, minute: 0)
          : const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      if (!_isValidTime(picked)) {
        _showSnackBar("Jam operasional kampus: 08:00 - 16:00", Colors.orange);
        return;
      }
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  Future<void> _pickPermitImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() => _permitImageBase64 = base64Encode(bytes));
    }
  }

  void _submitReservation() async {
    if (_selectedDate == null ||
        _startTime == null ||
        _endTime == null ||
        _purposeController.text.isEmpty) {
      _showSnackBar(
        "Harap lengkapi tanggal, waktu, dan keperluan.",
        Colors.orange,
      );
      return;
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (startMinutes >= endMinutes) {
      _showSnackBar("Jam selesai harus setelah jam mulai.", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('reservations').add({
        'uid': user?.uid,
        'roomId': widget.roomId,
        'roomName': widget.roomName,
        'buildingName': widget.buildingName,
        'date': Timestamp.fromDate(_selectedDate!),
        'startTime':
            "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}",
        'endTime':
            "${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}",
        'purpose': _purposeController.text.trim(),
        'permitImage': _permitImageBase64,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      _showSnackBar("Gagal mengirim reservasi: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('master_rooms')
          .doc(widget.roomId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        final roomData = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER IMAGE DENGAN BACK BUTTON
                Stack(
                  children: [
                    roomData['roomImage'] != null
                        ? Image.memory(
                            base64Decode(roomData['roomImage']),
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 250,
                            width: double.infinity,
                            color: Colors.blue[50],
                            child: const Icon(
                              Icons.meeting_room_rounded,
                              size: 80,
                              color: Colors.blue,
                            ),
                          ),
                    Positioned(
                      top: 40,
                      left: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. JUDUL DAN LOKASI
                      Text(
                        widget.roomName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.blue[900],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.buildingName,
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 3. SPESIFIKASI RUANGAN (CHIPS)
                      _buildSpecSection(roomData),
                      const Divider(height: 40),

                      // 4. FORM RESERVASI
                      _buildLabel("Tanggal Peminjaman"),
                      _buildSelector(
                        text: _selectedDate == null
                            ? "Pilih Tanggal"
                            : DateFormat(
                                'EEEE, dd MMMM yyyy',
                              ).format(_selectedDate!),
                        icon: Icons.calendar_month_rounded,
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Mulai"),
                                _buildSelector(
                                  text: _startTime?.format(context) ?? "08:00",
                                  icon: Icons.access_time_rounded,
                                  onTap: () => _selectTime(true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Selesai"),
                                _buildSelector(
                                  text: _endTime?.format(context) ?? "16:00",
                                  icon: Icons.access_time_filled_rounded,
                                  onTap: () => _selectTime(false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      _buildLabel("Keperluan / Nama Kegiatan"),
                      TextField(
                        controller: _purposeController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          "Jelaskan detail kegiatan anda...",
                        ),
                      ),
                      const SizedBox(height: 25),

                      _buildLabel("Surat Izin Kegiatan (Opsional)"),
                      _buildImagePicker(),
                      const SizedBox(height: 30),

                      // 5. TERMS & CONDITIONS
                      _buildTermsArea(),
                      const SizedBox(height: 30),

                      // 6. SUBMIT BUTTON
                      _buildSubmitButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildSpecSection(Map<String, dynamic> data) {
    return Row(
      children: [
        _buildSpecChip(Icons.people, "${data['capacity']} Kursi"),
        if (data['facilities']?['ac'] == true)
          _buildSpecChip(Icons.ac_unit, "AC"),
        if (data['facilities']?['projector'] == true)
          _buildSpecChip(Icons.videocam, "Proyektor"),
      ],
    );
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[900]),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue[900]),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickPermitImage,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.blue.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: _permitImageBase64 == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: Colors.blue[900],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Lampirkan Surat Izin (PNG/JPG)",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(
                  base64Decode(_permitImageBase64!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }

  Widget _buildTermsArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _isTermsAgreed,
            activeColor: Colors.orange[900],
            onChanged: (v) => setState(() => _isTermsAgreed = v!),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "Saya berkomitmen untuk menjaga fasilitas ITI, bertanggung jawab atas kebersihan, dan mematuhi jam operasional kampus.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.brown,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: (_isTermsAgreed && !_isLoading) ? _submitReservation : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "KONFIRMASI RESERVASI",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Reservasi Terkirim!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Admin ITI akan meninjau pengajuan anda. Silakan cek status di menu riwayat secara berkala.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pop(context); // Kembali ke list ruangan
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "MENGERTI",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
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
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
    );
  }
}
