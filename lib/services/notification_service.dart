import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grabitt/services/auth_service.dart';
import 'package:grabitt/services/order_history_api_service.dart';
import 'package:grabitt/pages/order_details_page.dart';
import 'package:permission_handler/permission_handler.dart';

const String _baseUrl = 'https://grabitt.in';
const String _lastShownKey = 'grabitt_last_shown_notification_order_id';
const String _shownNotificationOrderIdsKey =
    'grabitt_shown_notification_order_ids';

/// Top-level callback dispatcher used by Workmanager. Kept here so main.dart
/// can simply call Workmanager().initialize(callbackDispatcher,...).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService._backgroundInit();
    await NotificationService.instance.checkAndNotify();
    return Future.value(true);
  });
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    await _initializePlugin();
  }

  Future<void> _initializePlugin({bool handleLaunch = true}) async {
    if (_initialized) return;

    if (handleLaunch) {
      await _requestNotificationPermission();
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(
      android: android,
      iOS: const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationPayload(payload);
        }
      },
    );

    if (handleLaunch) {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        final payload = details!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleNotificationPayload(payload);
          });
        }
      }
    }

    _initialized = true;
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  static String _normalizeStatus(String? status) {
    final normalized = (status ?? '').toString().trim().toLowerCase();
    if (normalized == 'pick_up' || normalized == 'picked_up') {
      return 'picked_up';
    }
    return normalized;
  }

  static String _notificationIdentity(Map<String, dynamic> map) {
    final orderId = map['order_id']?.toString().trim() ?? '';
    if (orderId.isEmpty) return '';

    final orderStatus = _normalizeStatus(map['order_status']?.toString());
    if (orderStatus.isEmpty) {
      return orderId;
    }

    return '$orderId|$orderStatus';
  }

  static List<Map<String, dynamic>> filterNotificationsToShow(
    List<dynamic> entries,
    Set<String> alreadyShownOrderIds,
  ) {
    final filtered = <Map<String, dynamic>>[];

    for (final rawEntry in entries) {
      final map = rawEntry is String
          ? json.decode(rawEntry) as Map<String, dynamic>
          : Map<String, dynamic>.from(rawEntry as Map);

      final hasNotification = map['has_notification']?.toString().toLowerCase() ==
              'true' ||
          map['has_notification'] == true;
      if (!hasNotification) continue;

      final orderId = map['order_id']?.toString().trim() ?? '';
      final orderStatus = _normalizeStatus(map['order_status']?.toString());
      final notificationKey = _notificationIdentity(map);
      if (orderId.isEmpty || notificationKey.isEmpty) continue;
      if (alreadyShownOrderIds.contains(notificationKey)) continue;

      final legacyOrderSeen = alreadyShownOrderIds.contains(orderId);
      if (legacyOrderSeen && orderStatus == 'accepted') {
        continue;
      }

      filtered.add(map);
    }

    return filtered;
  }

  /// Initialization helper used inside the Workmanager background isolate.
  @pragma('vm:entry-point')
  static Future<void> _backgroundInit() async {
    await NotificationService.instance._initializePlugin(handleLaunch: false);
  }

  Future<void> checkAndNotify() async {
    final user = await AuthService.instance.getSavedUser();
    final userId = user?['ID']?.toString() ?? user?['UserID']?.toString() ?? '';
    if (userId.isEmpty) return;

    try {
      final uri = Uri.parse('$_baseUrl/Webservice.asmx/CheckCustomerNotification')
          .replace(queryParameters: {'UserID': userId});
      final response = await http.get(uri);
      if (response.statusCode != 200) return;
      final cleaned = response.body.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (cleaned.isEmpty || cleaned.toLowerCase() == 'fail') return;

      List<dynamic> entries = [];
      final stringMatches = RegExp(
        r'<string[^>]*>(.*?)</string>',
        dotAll: true,
      ).allMatches(response.body);

      if (stringMatches.isNotEmpty) {
        for (final match in stringMatches) {
          final rawValue = match.group(1)?.trim() ?? '';
          if (rawValue.isEmpty) continue;

          try {
            final decoded = json.decode(rawValue);
            if (decoded is List) {
              entries.addAll(decoded);
            } else if (decoded is Map || decoded is String) {
              entries.add(decoded);
            }
          } catch (_) {
            // Ignore malformed payloads silently.
          }
        }
      } else {
        try {
          final dec = json.decode(cleaned);
          if (dec is List) {
            entries = dec;
          } else if (dec is Map) {
            entries = [dec];
          } else if (dec is String) {
            entries = [json.decode(dec)];
          }
        } catch (_) {
          final firstJson = RegExp(r'\{.*\}').firstMatch(cleaned)?.group(0);
          if (firstJson != null) entries = [json.decode(firstJson)];
        }
      }

      if (entries.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final seenNotificationKeys = <String>{
        ...?(prefs.getStringList(_shownNotificationOrderIdsKey))
      };
      final legacyLastShown = prefs.getString(_lastShownKey) ?? '';
      if (legacyLastShown.isNotEmpty) {
        seenNotificationKeys.add(legacyLastShown);
      }

      final notificationsToShow = NotificationService.filterNotificationsToShow(
        entries,
        seenNotificationKeys,
      );

      for (final map in notificationsToShow) {
        final orderId = map['order_id']?.toString().trim() ?? '';
        final title = map['title']?.toString() ?? 'Notification';
        final message = map['message']?.toString() ?? '';

        await _showNotification(title, message, json.encode({'order_id': orderId}));

        if (orderId.isNotEmpty) {
          final notificationKey = NotificationService._notificationIdentity(map);
          if (notificationKey.isNotEmpty) {
            seenNotificationKeys.add(notificationKey);
          }
          seenNotificationKeys.add(orderId);
          final trimmedIds = seenNotificationKeys.take(100).toList();
          await prefs.setStringList(_shownNotificationOrderIdsKey, trimmedIds);
          await prefs.setString(_lastShownKey, orderId);
        }
      }
    } catch (_) {
      // ignore network errors silently in background
    }
  }

  Future<void> _showNotification(String title, String body, String payload) async {
    await _initializePlugin(handleLaunch: false);

    try {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
        return;
      }
    } catch (_) {
      // Permission handler may not work inside the background isolate.
      // Continue and let Android decide if the notification can be shown.
    }

    const androidDetails = AndroidNotificationDetails(
      'grabitt_channel_01',
      'Grabitt Notifications',
      channelDescription: 'Order updates from Grabitt',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platform = NotificationDetails(android: androidDetails);
    final notificationId = payload.hashCode.abs();
    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: platform,
      payload: payload,
    );
  }

  void _handleNotificationPayload(String payload) async {
    try {
      final map = json.decode(payload) as Map<String, dynamic>;
      final orderId = map['order_id']?.toString() ?? '';
      if (orderId.isEmpty) return;

      // Fetch order details and navigate to OrderDetailsPage
      final order = await getOrderDetails(orderId);
      if (order == null) return;

      final nav = navigatorKey.currentState;
      if (nav == null) return;

      nav.push(
        MaterialPageRoute(
          builder: (_) => OrderDetailsPage(
            order: order,
            fromNotification: true,
          ),
        ),
      );
    } catch (_) {
      // ignore
    }
  }
}
