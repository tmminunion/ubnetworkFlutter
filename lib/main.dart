import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/hub/hub_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UbnetworkApp());
}

class UbnetworkApp extends StatelessWidget {
  const UbnetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UBnetwork',
      debugShowCheckedModeBanner: false,
      theme: buildUbTheme(),
      home: const HubScreen(),
    );
  }
}
