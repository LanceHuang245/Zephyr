import 'package:flutter/material.dart';
import 'package:zephyr/app.dart';
import 'core/startup.dart';

// TODO: 极光推送、fcm接入
Future<void> main() async {
  await initAppSettings();

  runApp(const ZephyrApp());
}
