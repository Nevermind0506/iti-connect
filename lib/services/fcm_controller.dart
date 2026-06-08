import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class FCMController {
  // GANTI ini dengan Server Key asli dari Firebase Console
  static const String _serverKey = 'AIzaSyAxdWfP4FZ_8qCHAnOEdoNX6A6iVl5KQyM';
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  static Future<void> sendPushNotification({
    required String token,
    required String receiverUid,
    required String title,
    required String body,
  }) async {
    try {
      // 1. Simpan ke History Firestore (Kotak Masuk) TERLEBIH DAHULU
      // Kita lakukan ini di awal agar meskipun pengiriman sinyal push gagal,
      // pesan tetap muncul di menu Kotak Masuk aplikasi.
      await _saveToHistory(receiverUid: receiverUid, title: title, body: body);

      // 2. Kirim Push Notification melalui HTTP Request ke FCM
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(<String, dynamic>{
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
            'body': body,
            'title': title,
          },
          'notification': <String, dynamic>{
            'title': title,
            'body': body,
            'android_channel_id': 'iti_connect_channel',
          },
          'to': token,
        }),
      );

      if (response.statusCode == 200) {
        print("Sinyal Push Notification berhasil dikirim ke Google!");
      } else {
        print(
          "Gagal mengirim Push (Spanduk), tapi data sudah masuk Kotak Masuk. Status: ${response.statusCode}",
        );
        print("Error detail: ${response.body}");
      }
    } catch (e) {
      print("Error sistem FCM: $e");
    }
  }

  // Fungsi Internal untuk mencatat riwayat ke database
  static Future<void> _saveToHistory({
    required String receiverUid,
    required String title,
    required String body,
  }) async {
    try {
      if (receiverUid.isEmpty) {
        print("Gagal simpan history: UID Penerima kosong.");
        return;
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverUid': receiverUid,
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(), // Untuk orderBy di UI
        'isRead': false,
      });
      print(
        "History notifikasi berhasil dicatat di Firestore untuk UID: $receiverUid",
      );
    } catch (e) {
      print("Gagal mencatat history ke database: $e");
    }
  }
}
