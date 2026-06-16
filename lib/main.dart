import 'package:flutter/material.dart';
import 'package:grabitt/app_State/cart.dart';
import 'package:grabitt/app_State/locale_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CartService.instance.loadFromStorage();
  await LocaleProvider.instance.load();
  runApp(const MyApp());
}
  