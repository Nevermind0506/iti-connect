import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // 1. FUNGSI PENDAFTARAN (NIM MIN 10 DIGIT & PASSWORD MIN 8 CHAR)
  void _register() async {
    final nama = _namaController.text.trim();
    final email = _emailController.text.trim();
    final nim = _nimController.text.trim();
    final password = _passwordController.text.trim();

    if (nama.isEmpty || email.isEmpty || nim.isEmpty || password.isEmpty) {
      _showCustomSnackBar(
        "Peringatan",
        "Mohon lengkapi semua kolom pendaftaran.",
        const Icon(Icons.warning_amber_rounded, color: Colors.white),
        Colors.orange[800]!,
      );
      return;
    }

    // UPDATE: VALIDASI NIM MINIMAL 10 DIGIT
    if (nim.length < 10) {
      _showCustomSnackBar(
        "NIM Kurang Lengkap",
        "Nomor Induk Mahasiswa (NIM) minimal harus 10 digit.",
        const Icon(Icons.badge_rounded, color: Colors.white),
        Colors.orange[900]!,
      );
      return;
    }

    if (!email.contains('@')) {
      _showCustomSnackBar(
        "Email Tidak Valid",
        "Gunakan alamat email institusi yang benar.",
        const Icon(Icons.mail_outline, color: Colors.white),
        Colors.redAccent,
      );
      return;
    }

    if (password.length < 8) {
      _showCustomSnackBar(
        "Password Terlalu Pendek",
        "Demi keamanan, gunakan minimal 8 karakter password.",
        const Icon(Icons.security_rounded, color: Colors.white),
        Colors.orange[900]!,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'nama': nama,
            'email': email,
            'nim': nim,
            'role': 'mahasiswa',
            'level': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });

      _showCustomSnackBar(
        "Berhasil",
        "Akun Anda telah berhasil dibuat. Silakan masuk.",
        const Icon(Icons.check_circle_outline, color: Colors.white),
        Colors.green[700]!,
      );

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = "Pendaftaran Gagal.";
      if (e.code == 'email-already-in-use') msg = "Email sudah terdaftar.";

      _showCustomSnackBar(
        "Kesalahan",
        msg,
        const Icon(Icons.error_outline, color: Colors.white),
        Colors.redAccent,
      );
    } catch (e) {
      _showCustomSnackBar(
        "Sistem Error",
        "Terjadi kesalahan sistem.",
        const Icon(Icons.bug_report),
        Colors.black87,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomSnackBar(
    String title,
    String message,
    Widget icon,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER SECTION
            Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.32,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.blue[800]!,
                        Colors.blue[900]!,
                        const Color(0xFF001A3D),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(80),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          "Buat Akun",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Daftar untuk menikmati akses cerdas\nlayanan kampus ITI Connect.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            // FORM PENDAFTARAN
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
              child: Column(
                children: [
                  _buildInput(
                    controller: _namaController,
                    label: "Nama Lengkap",
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),

                  _buildInput(
                    controller: _nimController,
                    label: "NIM (Min. 10 Digit)",
                    icon: Icons.badge_outlined,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  _buildInput(
                    controller: _emailController,
                    label: "Email Institusi",
                    icon: Icons.alternate_email_rounded,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  _buildInput(
                    controller: _passwordController,
                    label: "Password (Min. 8 Karakter)",
                    icon: Icons.lock_open_rounded,
                    isPass: true,
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.blue[900]!.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "DAFTAR SEKARANG",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Sudah memiliki akun? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          "Masuk di sini",
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPass = false,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: isPass ? !_isPasswordVisible : false,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.blue[900], size: 20),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          // Menghilangkan border default agar terlihat melayang (Clean)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 15,
          ),
        ),
      ),
    );
  }
}
