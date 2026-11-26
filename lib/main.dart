import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/hub/hub_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UbnetworkApp());
}

class UbnetworkApp extends StatefulWidget {
  const UbnetworkApp({super.key});

  @override
  State<UbnetworkApp> createState() => _UbnetworkAppState();
}

class _UbnetworkAppState extends State<UbnetworkApp> {
  UbAuthUser? _user;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await AuthService.instance.loadSavedUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _restoring = false;
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UBnetwork',
      debugShowCheckedModeBanner: false,
      theme: buildUbTheme(),
      home: _restoring
          ? const Scaffold(
              backgroundColor: Color(0xFF020617),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
              ),
            )
          : _user == null
              ? LoginScreen(
                  onAuthenticated: (u) => setState(() => _user = u),
                )
              : HubScreen(
                  authUser: _user,
                  onLogout: _handleLogout,
                ),
    );
  }
}
