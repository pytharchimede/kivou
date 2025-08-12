import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'api_client.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref.read(apiClientProvider));
});

class PushService {
  final ApiClient _api;
  PushService(this._api);

  static final _fln = FlutterLocalNotificationsPlugin();
  static Future<void> Function()? _onTokenRefresh;
  static void Function(Map<String, dynamic> data)? _onNotificationTap;
  static void setOnTokenRefresh(Future<void> Function() cb) {
    _onTokenRefresh = cb;
  }

  static void setOnNotificationTap(
      void Function(Map<String, dynamic> data) cb) {
    _onNotificationTap = cb;
  }

  static Future<void> initializeLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _fln.initialize(const InitializationSettings(
      android: android,
      iOS: ios,
    ));
  }

  static Future<void> showLocal(String title, String body) async {
    const android = AndroidNotificationDetails(
      'kivou_default',
      'Kivou Notifications',
      importance: Importance.high,
      priority: Priority.high,
      channelDescription: 'Notifications KIVOU',
    );
    const ios = DarwinNotificationDetails();
    await _fln.show(
        0, title, body, const NotificationDetails(android: android, iOS: ios));
  }

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    await initializeLocal();
    final fm = FirebaseMessaging.instance;
    // iOS permissions
    await fm.requestPermission(alert: true, badge: true, sound: true);
    // Android 13+ notifications permission via local notifications plugin
    final androidImpl = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidImpl?.requestNotificationsPermission();
    } catch (_) {}
    FirebaseMessaging.onMessage.listen((msg) {
      final title = msg.notification?.title ?? msg.data['title'] ?? 'KIVOU';
      final body = msg.notification?.body ?? msg.data['body'] ?? '';
      showLocal(title, body);
    });
    // Notification tap when app in background
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final cb = _onNotificationTap;
      if (cb != null) cb(msg.data);
    });
    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      try {
        // Ask app to re-register token server-side
        final cb = _onTokenRefresh;
        if (cb != null) await cb();
      } catch (_) {}
    });
  }

  Future<void> registerFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await _api.postJson('/api/push/register_token.php', {
      'token': token,
      'platform': Platform.isAndroid ? 'android' : 'ios',
    });
  }
}
