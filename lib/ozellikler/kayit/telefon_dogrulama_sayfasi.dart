// lib/ozellikler/kayit/telefon_dogrulama_sayfasi.dart
// Gerçek Firebase PhoneAuth akışı (mobil + web), resend, geri sayım, tek atış navigasyon.
// DEV BYPASS (000000/111111/123456) girildiğinde anonim oturum dener;
// admin kısıtında uyarı gösterir VE yine de /rol_sec'e geçer (devBypass=true).
// OTP doğrulanınca RouteNames.rolSec'e gider ve argümanları korur.

import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:eduplas/router/route_names.dart';

class TelefonDogrulamaSayfasi extends StatefulWidget {
  static const route = RouteNames.otp;
  const TelefonDogrulamaSayfasi({super.key});

  @override
  State<TelefonDogrulamaSayfasi> createState() => _TelefonDogrulamaSayfasiState();
}

class _TelefonDogrulamaSayfasiState extends State<TelefonDogrulamaSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();

  bool _islem = false;
  String? _hata;
  String? _bilgi;

  // Sayaç
  int _kalanSn = 60;
  Timer? _timer;

  // Tek atış navigasyon koruması
  bool _navigated = false;

  // PhoneAuth durumları
  String? _verificationId; // mobil
  int? _resendToken; // mobil için
  ConfirmationResult? _webConfirm; // web

  // Args (giriş ekranından taşıdıklarımız)
  Map<String, dynamic> get _args {
    final data = ModalRoute.of(context)?.settings.arguments;
    if (data is Map<String, dynamic>) return data;
    return const <String, dynamic>{};
  }

  String get _phone {
    final v = _args['phone'];
    return v is String ? v : '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOtpFlow();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    super.dispose();
  }

  void _startCountdown([int from = 60]) {
    _timer?.cancel();
    setState(() => _kalanSn = from);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _kalanSn = (_kalanSn > 0) ? _kalanSn - 1 : 0;
      });
      if (_kalanSn == 0) t.cancel();
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _startOtpFlow() async {
    if (_navigated) return;
    if (_phone.isEmpty) {
      setState(() {
        _hata = 'Telefon numarası alınamadı.';
        _bilgi = null;
      });
      return;
    }

    setState(() {
      _hata = null;
      _bilgi = 'Kod gönderiliyor...';
      _islem = true;
    });

    try {
      if (kIsWeb) {
        debugPrint('[OTP] Web signInWithPhoneNumber -> $_phone');
        _webConfirm = await FirebaseAuth.instance.signInWithPhoneNumber(_phone);
        setState(() {
          _bilgi = 'Kod gönderildi. Gelen kodu girin.';
        });
      } else {
        debugPrint('[OTP] Mobile verifyPhoneNumber -> $_phone');
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: _phone,
          timeout: const Duration(seconds: 60),
          forceResendingToken: _resendToken,
          verificationCompleted: (PhoneAuthCredential cred) async {
            debugPrint('[OTP] verificationCompleted (auto)');
            await _applyCredentialAndProceed(cred, auto: true);
          },
          verificationFailed: (FirebaseAuthException e) {
            debugPrint('[OTP] verificationFailed: ${e.code} ${e.message}');
            if (!mounted) return;
            setState(() {
              _hata = 'Doğrulama başarısız: ${e.code}';
              _bilgi = null;
            });
          },
          codeSent: (String verificationId, int? resendToken) {
            debugPrint('[OTP] codeSent. verificationId set. resendToken=$resendToken');
            _verificationId = verificationId;
            _resendToken = resendToken;
            if (!mounted) return;
            setState(() {
              _bilgi = 'Kod gönderildi. Gelen kodu girin.';
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            debugPrint('[OTP] autoRetrievalTimeout');
            _verificationId = verificationId;
          },
        );
      }
      _startCountdown(60);
    } catch (e) {
      debugPrint('[OTP] startOtpFlow error: $e');
      setState(() {
        _hata = 'Kod gönderilemedi: $e';
        _bilgi = null;
      });
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  Future<void> _resend() async {
    if (_kalanSn > 0) return;
    if (_islem || _navigated) return;
    _snack('Kod yeniden gönderiliyor...');
    await _startOtpFlow();
  }

  Future<void> _onSubmit() async {
    if (_islem || _navigated) return;
    if (!_formKey.currentState!.validate()) return;

    final code = _otp.text.trim();

    // ==== DEV BYPASS ====
    if (kDebugMode && (code == '000000' || code == '111111' || code == '123456')) {
      debugPrint('[OTP] DEV BYPASS used.');
      try {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
        }
        await _goNext(); // gerçek anon olursa
        return;
      } on FirebaseAuthException catch (e) {
        debugPrint('[OTP] DEV BYPASS auth error: ${e.code} ${e.message}');
        if (e.code == 'admin-restricted-operation') {
          if (mounted) {
            _snack('DEV: Anonymous kapalı veya kısıtlı → yine de devam ediyorum.');
          }
          await _goNext(devBypass: true);
          return;
        }
        if (mounted) {
          _snack('DEV geçiş başarısız: ${e.code}');
        }
        return;
      } catch (e) {
        if (mounted) {
          _snack('DEV geçiş sırasında beklenmeyen hata.');
        }
        return;
      }
    }

    // ==== Normal OTP doğrulama ====
    setState(() {
      _islem = true;
      _hata = null;
      _bilgi = 'Doğrulanıyor...';
    });

    try {
      if (kIsWeb) {
        if (_webConfirm == null) {
          throw StateError('Web onayı hazır değil. Lütfen yeniden kod isteyin.');
        }
        final credUserCred = await _webConfirm!.confirm(code);
        debugPrint('[OTP] Web confirm OK. uid=${credUserCred.user?.uid}');
      } else {
        if (_verificationId == null) {
          throw StateError('Doğrulama ID hazır değil. Lütfen yeniden kod isteyin.');
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: code,
        );
        await _applyCredentialAndProceed(credential);
      }
      await _goNext();
    } on FirebaseAuthException catch (e) {
      debugPrint('[OTP] FirebaseAuthException: ${e.code} ${e.message}');
      setState(() {
        _hata = 'Kod doğrulanamadı: ${e.code}';
        _bilgi = null;
      });
    } catch (e) {
      debugPrint('[OTP] Verify error: $e');
      setState(() {
        _hata = 'Hata: $e';
        _bilgi = null;
      });
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  Future<void> _applyCredentialAndProceed(PhoneAuthCredential cred, {bool auto = false}) async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;

    try {
      if (current != null && current.isAnonymous) {
        debugPrint('[OTP] Linking anonymous -> phone credential');
        await current.linkWithCredential(cred);
      } else {
        debugPrint('[OTP] Signing in with credential');
        await auth.signInWithCredential(cred);
      }
      if (auto) {
        _snack('Telefon otomatik doğrulandı');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' || e.code == 'provider-already-linked') {
        debugPrint('[OTP] Link failed (${e.code}), trying signInWithCredential');
        await auth.signInWithCredential(cred);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _goNext({bool devBypass = false}) async {
    if (_navigated) return;
    _navigated = true;

    final nextArgs = {
      ..._args,
      if (devBypass) 'devBypass': true,
    };

    debugPrint('[OTP] Navigation -> ${RouteNames.rolSec} (devBypass=$devBypass)');
    _timer?.cancel();
    await Navigator.pushReplacementNamed(
      context,
      RouteNames.rolSec,
      arguments: nextArgs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = _phone;
    final digits = _otp.text.replaceAll(RegExp(r'[^0-9]'), '');
    final visibleDigits = List<String>.generate(6, (i) => i < digits.length ? digits[i] : '');

    return Scaffold(
      appBar: AppBar(title: const Text('Telefon Doğrulama')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 8),
                    Text('Numaraya gönderilen kodu girin:', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_android_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(phone, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otp,
                      decoration: const InputDecoration(
                        labelText: '6 haneli kod',
                        hintText: '123456',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 8,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.length != 6) return '6 haneli kod gerekli';
                        return null;
                      },
                      onFieldSubmitted: (_) => _onSubmit(),
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Text(
                            visibleDigits[i],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (_bilgi != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16),
                          const SizedBox(width: 6),
                          Flexible(child: Text(_bilgi!, style: const TextStyle(color: Colors.black87))),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_hata != null) ...[
                      Text(_hata!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_islem || _navigated) ? null : _onSubmit,
                        child: _islem
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Doğrula'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: (_kalanSn == 0 && !_islem && !_navigated) ? _resend : null,
                          child: Text(_kalanSn == 0 ? 'Kodu yeniden gönder' : 'Yeniden gönder (${_kalanSn}s)'),
                        ),
                        TextButton(
                          onPressed: _islem ? null : () => Navigator.pop(context),
                          child: const Text('Geri'),
                        ),
                      ],
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
}
