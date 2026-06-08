import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Inisialisasi Izin dan Token
  Future<void> initializeNotification() async {
    // Minta izin (khusus iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Ambil Token Perangkat
      String? token = await _fcm.getToken();
      if (token != null) {
        _saveTokenToFirestore(token);
      }
    }
  }

  // Simpan token ke database agar Admin bisa kirim notif ke HP ini
  void _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'deviceToken': token},
      );
    }
  }

  // Mendengarkan pesan saat aplikasi sedang dibuka (Foreground)
  void listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Pesan diterima: ${message.notification?.title}');
      }
      // Di sini David bisa menambahkan local notification pop-up jika perlu
    });
  }
}
