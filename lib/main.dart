import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/remory_app.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: const RemoryApp(),
    ),
  );
}

