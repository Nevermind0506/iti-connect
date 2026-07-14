# ITI Connect - Smart Campus Application 📱✨

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Scrum](https://img.shields.io/badge/Methodology-Scrum-orange?style=for-the-badge)](#)

**ITI Connect** adalah aplikasi _Smart Campus_ berbasis mobile yang dirancang khusus untuk digitalisasi layanan operasional di lingkungan **Institut Teknologi Indonesia (ITI)**. Aplikasi ini mempermudah civitas akademika dalam berinteraksi dengan fasilitas kampus secara efisien, transparan, dan aman.

Saat ini, proyek telah mencapai **progres pengembangan 90%** dengan penyelesaian penuh pada **Modul Pelaporan Masalah (Problem Reporting)** dan **Modul Reservasi (Room Reservation)**.

---

## 🛠️ Stack Teknologi

- **Frontend Framework:** Flutter (Dart) - _Cross-platform mobile application_
- **Backend & Database:** Firebase Suite
  - Firebase Authentication (Manajemen Sesi Pengguna)
  - Cloud Firestore (Database NoSQL untuk Data Laporan & Reservasi)
  - Cloud Storage (Penyimpanan Media Gambar Bukti Kerusakan)
- **Manajemen Proyek:** Trello (Scrum Board)
- **Perancangan Antarmuka:** Figma (Design System & Prototyping)

---

## 🔒 Penerapan Software Security Engineering (SSE) - STRIDE Model

Kami mengintegrasikan aspek keamanan sejak fase perancangan menggunakan pemodelan ancaman **STRIDE** pada lapisan antarmuka pengguna (_Secure Form Design_) dan backend:

1.  **Tampering (Manipulasi Data):**
    - _Mitigasi UI:_ Mengubah input lokasi bebas (_free-text_) menjadi _Dropdown Menu_ terikat (Gedung dan Ruangan) untuk mengunci validitas koordinat fisik.
    - _Mitigasi Backend:_ Menerapkan _Firebase Security Rules_ agar data laporan yang sudah terkirim tidak dapat diubah (`update`) oleh pengguna biasa.
2.  **Denial of Service (DoS):**
    - _Mitigasi UI:_ Menerapkan _Conditional State_ di mana tombol "Kirim Laporan" otomatis bertransisi menjadi _Disabled_ (Abu-abu) dan memicu _Loading Spinner_ setelah penekanan pertama guna mencegah _human spamming/double-click_.
3.  **Information Disclosure (Kebocoran Informasi):**
    - _Mitigasi UI & Backend:_ Arsitektur informasi dirancang terisolasi. Halaman dasbor mahasiswa hanya diizinkan memuat riwayat pengaduan milik _user_ itu sendiri (`request.auth.uid == resource.data.userId`).

---

## 📐 Penjaminan Kualitas Perangkat Lunak (SQA)

- **Figma Style Guide:** Kami menyusun _Color Tokens_ (termasuk _semantic colors_ untuk indikator eror) dan _Typography Scale_ yang baku untuk menjamin konsistensi visual di setiap halaman.
- **Usability Focus:** Alur navigasi dirancang linear dan _straightforward_ agar mahasiswa dapat menyelesaikan pengaduan hanya dalam 2 kali ketukan dari menu utama.

---

## 🚀 Petunjuk Instalasi (Lokal Pengembangan)

### Prasyarat:

- Flutter SDK (Versi terbaru)
- Android Studio / VS Code
- Perangkat Android/iOS atau Emulator yang terhubung

### Langkah-langkah:

1. Clone repositori ini ke komputer lokal Anda:
   ```bash
   git clone [https://github.com/Nevermind0506/iti-connect.git](https://github.com/Nevermind0506/iti-connect.git)
   ```
