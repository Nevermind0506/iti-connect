import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iti_connect/features/admin/screens/edit_room_screen.dart';
import 'add_room_screen.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  String _selectedBuilding = "Semua";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Control Panel Ruangan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, size: 28, color: Colors.blue),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddRoomScreen()),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // 1. DASHBOARD HEADER & SEARCH
          _buildAdminHeader(),

          // 2. FILTER GEDUNG
          _buildBuildingFilter(),

          // 3. LIST RUANGAN
          Expanded(child: _buildRoomList()),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) =>
                setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Cari ID atau Nama Ruangan...",
              prefixIcon: const Icon(Icons.search, color: Colors.blue),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('master_rooms')
                .snapshots(),
            builder: (context, snapshot) {
              int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
              int available = snapshot.hasData
                  ? snapshot.data!.docs
                        .where((d) => d['roomStatus'] == 'Tersedia')
                        .length
                  : 0;
              return Row(
                children: [
                  _buildHeaderStat("Total", "$total", Colors.blue),
                  const SizedBox(width: 10),
                  _buildHeaderStat("Ready", "$available", Colors.green),
                  const SizedBox(width: 10),
                  _buildHeaderStat("Gedung", _selectedBuilding, Colors.orange),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingFilter() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('master_data')
          .doc('gedung')
          .snapshots(),
      builder: (context, snapshot) {
        List<String> items = ["Semua"];
        if (snapshot.hasData && snapshot.data!.exists) {
          items.addAll(List<String>.from(snapshot.data!['items'] ?? []));
        }
        return SizedBox(
          height: 55,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedBuilding == items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(items[index]),
                  selected: isSelected,
                  selectedColor: Colors.blue[900],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.blue[900],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.blue[900]!.withOpacity(0.2)),
                  ),
                  onSelected: (val) =>
                      setState(() => _selectedBuilding = items[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRoomList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('master_rooms')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          bool matchBuilding =
              _selectedBuilding == "Semua" ||
              data['buildingName'] == _selectedBuilding;
          bool matchSearch = data['roomName'].toString().toLowerCase().contains(
            _searchQuery,
          );
          return matchBuilding && matchSearch;
        }).toList();

        if (docs.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return _buildRoomCard(context, docs[index].id, data);
          },
        );
      },
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    bool isAvailable = data['roomStatus'] == 'Tersedia';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FOTO
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: data['roomImage'] != null
                      ? Image.memory(
                          base64Decode(data['roomImage']),
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          cacheWidth: 180,
                        )
                      : Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.meeting_room,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 15),
                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['roomName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        data['buildingName'],
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // BADGES FASILITAS
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildBadge(
                            Icons.people,
                            "${data['capacity']} Kursi",
                            Colors.grey[700]!,
                          ),
                          if (data['facilities']?['ac'] == true)
                            _buildBadge(Icons.ac_unit, "AC", Colors.blue),
                          if (data['facilities']?['projector'] == true)
                            _buildBadge(
                              Icons.videocam,
                              "Proyektor",
                              Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // STATUS PIN
                _buildReservationStatus(isAvailable),
              ],
            ),
          ),
          const Divider(height: 1),
          // TOMBOL AKSI MODERN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditRoomScreen(docId: id, roomData: data),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.blue,
                    ),
                    label: const Text(
                      "Edit Data",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 20, color: Colors.grey[200]),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () =>
                        _confirmDelete(context, id, data['roomName']),
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.red,
                    ),
                    label: const Text(
                      "Hapus",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationStatus(bool isAvailable) {
    return Column(
      children: [
        Icon(
          isAvailable ? Icons.check_circle : Icons.do_not_disturb_on,
          color: isAvailable ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          isAvailable ? "Available" : "Closed",
          style: TextStyle(
            fontSize: 10,
            color: isAvailable ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Peringatan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Hapus Ruangan?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                "Anda akan menghapus '$name'. Data yang dihapus tidak dapat dipulihkan kembali oleh sistem.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "BATAL",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('master_rooms')
                            .doc(id)
                            .delete();
                        if (context.mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Ruangan telah dihapus permanen"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        "HAPUS",
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            "Tidak ada ruangan yang cocok.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
