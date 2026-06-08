class ReportModel {
  final String? id;
  final String uid; // ID unik mahasiswa dari Firebase Auth
  final String namaPelapor; // Nama mahasiswa dari Firestore
  final String title;
  final String description;
  final String category;
  final String status; // 'Pending', 'Diproses', atau 'Selesai'
  final DateTime createdAt;

  ReportModel({
    this.id,
    required this.uid,
    required this.namaPelapor,
    required this.title,
    required this.description,
    required this.category,
    this.status = 'Pending', // Status awal otomatis Pending
    required this.createdAt,
  });

  // Fungsi untuk konversi data ke format Map (untuk dikirim ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'namaPelapor': namaPelapor,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
