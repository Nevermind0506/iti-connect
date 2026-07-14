import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- FUNGSI REGISTER (Sudah kita buat tadi) ---
  Future<String?> signUp({
    required String email,
    required String password,
    required String nama,
    required String nim,
  }) async {
    try {
      // 1. Buat User di Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Simpan ke Firestore (Wajib pakai await!)
      // Gunakan result.user!.uid sebagai ID Dokumen agar sinkron dengan Auth
      await _firestore.collection('users').doc(result.user!.uid).set({
        'nama': nama,
        'nim': nim,
        'email': email,
        'role': 'mahasiswa',
        'createdAt': FieldValue.serverTimestamp(), // Gunakan waktu server
      });

      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // --- FUNGSI LOGIN ---
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      // Memberikan pesan error yang jelas (misal: password salah)
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
