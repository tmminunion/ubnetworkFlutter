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
  final GlobalKey<ScaffoldMessengerState> _messengerKey = GlobalKey<ScaffoldMessengerState>();
  UbAuthUser? _user;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    AuthService.instance.onUnauthorized = _handleSessionExpired;
    _restoreSession();
  }

  @override
  void dispose() {
    if (AuthService.instance.onUnauthorized == _handleSessionExpired) {
      AuthService.instance.onUnauthorized = null;
    }
    super.dispose();
  }

  void _handleSessionExpired() {
    if (!mounted) return;
    final hadUser = _user != null;
    setState(() {
      _user = null;
      _restoring = false;
    });
    if (hadUser) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Sesi login kedaluwarsa (401). Silakan masuk kembali untuk terhubung ke server.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _restoreSession() async {
    final user = await AuthService.instance.loadSavedUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _restoring = false;
    });
    if (user != null) {
      await AuthService.instance.verifySessionOnline();
    }
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
      scaffoldMessengerKey: _messengerKey,
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
