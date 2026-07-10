import 'package:flutter/material.dart';
import 'package:grabitt/app_State/cart.dart';
import 'package:grabitt/app_State/locale_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:grabitt/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CartService.instance.loadFromStorage();
  await LocaleProvider.instance.load();
  // Initialize notification service and background worker
  await NotificationService.instance.init();
  await NotificationService.instance.checkAndNotify();
  Workmanager().initialize(callbackDispatcher);
  try {
    Workmanager().registerPeriodicTask(
      'grabitt_check_notifications',
      'checkNotifications',
      frequency: const Duration(minutes: 5),
      constraints: Constraints(networkType: NetworkType.connected),
    );
    Workmanager().registerOneOffTask(
      'grabitt_check_notifications_immediate',
      'checkNotifications',
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (_) {}

  runApp(const MyApp());
}
  