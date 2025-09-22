import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/remory_app.dart';
import 'package:remory/service/notification_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.I.init();

  runApp(
    const ProviderScope(
      child: const RemoryApp(),
    ),
  );
}

