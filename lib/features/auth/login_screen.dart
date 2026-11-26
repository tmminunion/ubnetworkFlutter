import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';

enum _LoginMode { roster, otp, password }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onAuthenticated,
  });

  final ValueChanged<UbAuthUser> onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _LoginMode _mode = _LoginMode.roster;

  // Live WIB Clock
  late Timer _clockTimer;
  String _timeStr = '--:--:--';
  String _dateStr = '';

  // Mode 1: Roster (Noreg + 6 Digit Terakhir No. Telp/WA)
  final _rosterNoregCtrl = TextEditingController();
  final _wa6Ctrl = TextEditingController();

  // Mode 2: OTP WhatsApp (Noreg -> 6 Kotak Angka OTP)
  final _otpNoregCtrl = TextEditingController();
  final _otpCodeCtrl = TextEditingController();
  final _otpFocus = FocusNode();
  bool _otpSent = false;
  String? _otpInfo;
  int _otpCooldown = 0;
  Timer? _cooldownTimer;

  // Mode 3: Login Sistem (Password Shift / Admin)
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  bool _busy = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _otpFocus.addListener(_onOtpFocusChange);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _cooldownTimer?.cancel();
    _otpFocus.removeListener(_onOtpFocusChange);
    _rosterNoregCtrl.dispose();
    _wa6Ctrl.dispose();
    _otpNoregCtrl.dispose();
    _otpCodeCtrl.dispose();
    _otpFocus.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onOtpFocusChange() {
    if (mounted) setState(() {});
  }

  void _updateClock() {
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final hh = wib.hour.toString().padLeft(2, '0');
    final mm = wib.minute.toString().padLeft(2, '0');
    final ss = wib.second.toString().padLeft(2, '0');
    final dName = days[wib.weekday - 1];
    final mName = months[wib.month - 1];
    if (mounted) {
      setState(() {
        _timeStr = '$hh:$mm:$ss';
        _dateStr = '$dName, ${wib.day} $mName ${wib.year}';
      });
    }
  }

  void _startOtpCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _otpCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_otpCooldown <= 1) {
        t.cancel();
        setState(() => _otpCooldown = 0);
      } else {
        setState(() => _otpCooldown -= 1);
      }
    });
  }

  Future<void> _submitRoster() async {
    final noreg = _rosterNoregCtrl.text.trim();
    final wa6 = _wa6Ctrl.text.replaceAll(RegExp(r'\D'), '');
    if (noreg.isEmpty || wa6.length != 6) {
      setState(() => _errorText = 'Masukkan NOREG dan 6 digit terakhir nomor HP/WA.');
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final res = await AuthService.instance.loginWithRoster(noreg: noreg, wa6: wa6);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok && res.user != null) {
      widget.onAuthenticated(res.user!);
    } else {
      setState(() => _errorText = res.message ?? 'NOREG atau 6 digit terakhir nomor HP tidak cocok.');
    }
  }

  Future<void> _requestOtp() async {
    final noreg = _otpNoregCtrl.text.trim();
    if (noreg.isEmpty) {
      setState(() => _errorText = 'Masukkan NOREG terlebih dahulu.');
      return;
    }
    if (_busy || _otpCooldown > 0) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final res = await AuthService.instance.requestOtp(noreg: noreg);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      _otpCodeCtrl.clear();
      setState(() {
        _otpSent = true;
        _otpInfo = res.message ?? 'Kode OTP 6 digit telah dikirim ke WhatsApp terdaftar.';
      });
      _startOtpCooldown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocus.requestFocus();
      });
    } else {
      setState(() => _errorText = res.message ?? 'Gagal mengirim OTP.');
    }
  }

  Future<void> _verifyOtp([String? forced]) async {
    if (_busy) return;
    final noreg = _otpNoregCtrl.text.trim();
    final code = (forced ?? _otpCodeCtrl.text).replaceAll(RegExp(r'\D'), '');
    if (noreg.isEmpty || code.length != 6) {
      setState(() => _errorText = 'Masukkan 6 digit kode OTP.');
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final res = await AuthService.instance.verifyOtp(noreg: noreg, otp: code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok && res.user != null) {
      widget.onAuthenticated(res.user!);
    } else {
      _otpCodeCtrl.clear();
      setState(() => _errorText = res.message ?? 'Kode OTP salah atau sudah kedaluwarsa.');
    }
  }

  Future<void> _submitPassword() async {
    final pw = _passwordCtrl.text.trim();
    if (pw.isEmpty) {
      setState(() => _errorText = 'Masukkan password sistem / shift.');
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    final res = await AuthService.instance.loginWithPassword(password: pw);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok && res.user != null) {
      widget.onAuthenticated(res.user!);
    } else {
      setState(() => _errorText = res.message ?? 'Password salah.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF020617),
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 13, color: Color(0xFF38BDF8)),
                            SizedBox(width: 6),
                            Text(
                              'UNDERBODY ASSY • UBNETWORK',
                              style: TextStyle(
                                color: Color(0xFFBAE6FD),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _dateStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeStr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                                  ),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'UB',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Masuk UBnetwork',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'Wajib online untuk sinkronisasi shift & checksheet',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 3 Tab Mode 1:1 Next.js: Roster | OTP WA | Sistem
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF020617),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                _modeTab(_LoginMode.roster, 'Noreg & Telp', Icons.badge_outlined),
                                _modeTab(_LoginMode.otp, 'OTP WA', Icons.chat_bubble_outline_rounded),
                                _modeTab(_LoginMode.password, 'Sistem', Icons.key_rounded),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_mode == _LoginMode.roster) _buildRosterForm(),
                          if (_mode == _LoginMode.otp) _buildOtpForm(),
                          if (_mode == _LoginMode.password) _buildPasswordForm(),
                          if (_errorText != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7F1D1D).withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeTab(_LoginMode m, String label, IconData icon) {
    final active = _mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: _busy
            ? null
            : () {
                setState(() {
                  _mode = m;
                  _errorText = null;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0284C7) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _darkInputDec({
    required String label,
    required String hintText,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF020617).withValues(alpha: 0.75),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.6),
      ),
    );
  }

  Widget _buildRosterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _rosterNoregCtrl,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: _darkInputDec(
            label: 'NOREG',
            hintText: 'Contoh: 00123456',
            icon: Icons.badge_outlined,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _wa6Ctrl,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 2),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onSubmitted: (_) => _submitRoster(),
          decoration: _darkInputDec(
            label: '6 Digit Terakhir No. Telp / WA',
            hintText: '••••••',
            icon: Icons.phone_android_rounded,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submitRoster,
          style: FilledButton.styleFrom(
            backgroundColor: UbColors.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : const Text(
                  'Masuk dengan Noreg & Telp',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
        ),
      ],
    );
  }

  Widget _buildOtpForm() {
    final code = _otpCodeCtrl.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _otpNoregCtrl,
          enabled: !_busy,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _otpSent ? null : _requestOtp(),
          decoration: _darkInputDec(
            label: 'NOREG Anggota',
            hintText: 'Contoh: 00123456',
            icon: Icons.badge_outlined,
          ),
        ),
        if (!_otpSent) ...[
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : _requestOtp,
            style: FilledButton.styleFrom(
              backgroundColor: UbColors.emerald,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text(
                    'Kirim Kode OTP ke WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
          ),
        ] else ...[
          const SizedBox(height: 14),
          if (_otpInfo != null)
            Text(
              _otpInfo!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6EE7B7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 14),
          // 6 Kotak Angka OTP
          GestureDetector(
            onTap: () => _otpFocus.requestFocus(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 52,
                  child: Opacity(
                    opacity: 0.01,
                    child: TextField(
                      controller: _otpCodeCtrl,
                      focusNode: _otpFocus,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (v) {
                        setState(() => _errorText = null);
                        if (v.length == 6) _verifyOtp(v);
                      },
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (idx) {
                      final hasDigit = idx < code.length;
                      final isActive = _otpFocus.hasFocus &&
                          (idx == code.length || (code.length == 6 && idx == 5));
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 44,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: hasDigit
                              ? const Color(0xFF0C4A6E).withValues(alpha: 0.55)
                              : const Color(0xFF020617),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF38BDF8)
                                : hasDigit
                                    ? const Color(0xFF0EA5E9)
                                    : Colors.white.withValues(alpha: 0.16),
                            width: isActive ? 2 : 1.3,
                          ),
                        ),
                        child: Text(
                          hasDigit ? code[idx] : '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_busy || code.length != 6) ? null : () => _verifyOtp(),
            style: FilledButton.styleFrom(
              backgroundColor: UbColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text(
                    'Verifikasi OTP & Masuk',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _otpSent = false;
                          _otpCodeCtrl.clear();
                          _errorText = null;
                        }),
                child: const Text(
                  'Ganti Noreg',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: (_busy || _otpCooldown > 0) ? null : _requestOtp,
                child: Text(
                  _otpCooldown > 0 ? 'Kirim ulang ($_otpCooldown dtk)' : 'Kirim Ulang OTP',
                  style: TextStyle(
                    color: _otpCooldown > 0 ? const Color(0xFF64748B) : const Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitPassword(),
          decoration: _darkInputDec(
            label: 'Password Sistem / Shift',
            hintText: 'Masukkan password gerbang',
            icon: Icons.lock_outline_rounded,
            suffix: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submitPassword,
          style: FilledButton.styleFrom(
            backgroundColor: UbColors.indigo,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
              : const Text(
                  'Masuk Sistem',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
        ),
      ],
    );
  }
}
