// lib/ozellikler/giris/giris_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/cekirdek/arayuz/app_logo.dart';
import 'package:eduplas/ayarlar/dil_degistirici.dart';
import 'package:eduplas/router/route_names.dart';
import 'package:eduplas/cekirdek/dil/dil_yoneticisi.dart';

class GirisSayfasi extends StatefulWidget {
  static const route = RouteNames.giris;
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _formKey = GlobalKey<FormState>();

  // Alanlar
  final _nick = TextEditingController();
  final _adSoyad = TextEditingController();
  final _tel = TextEditingController();
  final _sifre = TextEditingController();
  final _sifre2 = TextEditingController();

  bool _islem = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _hata;

  String _aktifDil = 'tr';

  @override
  void initState() {
    super.initState();
    _nick.addListener(_onNickChanged);

    _aktifDil = DilYoneticisi.instance.aktifDil;
    DilYoneticisi.instance.addListener(_onDilChanged);
  }

  @override
  void dispose() {
    _nick
      ..removeListener(_onNickChanged)
      ..dispose();
    _adSoyad.dispose();
    _tel.dispose();
    _sifre.dispose();
    _sifre2.dispose();

    DilYoneticisi.instance.removeListener(_onDilChanged);
    super.dispose();
  }

  void _onDilChanged() {
    if (!mounted) return;
    setState(() {
      _aktifDil = DilYoneticisi.instance.aktifDil;
    });
  }

  void _onNickChanged() {
    setState(() {});
  }

  String _temizTakmaAd(String input) {
    var s = input.trim().toLowerCase();
    s = s
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    s = s.replaceAll(RegExp(r'\s+'), '.');
    s = s.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    s = s.replaceAll(RegExp(r'\.{2,}'), '.');
    s = s.replaceAll(RegExp(r'^\.'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    if (s.isEmpty) s = 'kullanici';
    if (s.length < 3) s = '${s}___'.substring(0, 3);
    return s;
  }

  String _sadeceRakamlar(String input) => input.replaceAll(RegExp(r'[^0-9+]'), '');

  String? _telHata(String? v, _T t) {
    if (v == null || v.trim().isEmpty) return t.valRequired;
    final tel = _sadeceRakamlar(v);
    final digits = tel.replaceAll('+', '');
    if (digits.length < 10 || digits.length > 15) {
      return t.valPhoneInvalid;
    }
    return null;
  }

  Future<void> _kaydetVeOtp(_T t) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _islem = true;
      _hata = null;
    });

    try {
      final temizNick = _temizTakmaAd(_nick.text);
      final adSoyad = _adSoyad.text.trim();
      final tel = _sadeceRakamlar(_tel.text);
      final sifre = _sifre.text;

      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        RouteNames.otp,
        arguments: <String, dynamic>{
          'nick': temizNick,
          'fullName': adSoyad,
          'phone': tel,
          'password': sifre,
        },
      );
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Küçük çeviri katmanı
    final t = _T.of(_aktifDil);
    final temizNick = _temizTakmaAd(_nick.text);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.registerTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // withOpacity depreceated uyarısını önlemek için basit renk
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _aktifDil.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 8),
                    const Center(child: AppLogo(daire: true, compactHint: true)),
                    Text(
                      'EduPlas',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF00BFA5),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.activeLanguageLabel(_aktifDil),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Takma ad
                    TextFormField(
                      controller: _nick,
                      decoration: InputDecoration(
                        labelText: t.fieldNickname,
                        helperText: t.fieldNicknameHelper(temizNick),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? t.valRequired : null,
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),

                    // Şifre
                    TextFormField(
                      controller: _sifre,
                      decoration: InputDecoration(
                        labelText: t.fieldPassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                          tooltip: _obscure1 ? t.uiShowPassword : t.uiHidePassword,
                        ),
                      ),
                      obscureText: _obscure1,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.length < 6) ? t.valPasswordShort : null,
                    ),
                    const SizedBox(height: 12),

                    // Şifre tekrarı
                    TextFormField(
                      controller: _sifre2,
                      decoration: InputDecoration(
                        labelText: t.fieldPasswordRepeat,
                        suffixIcon: IconButton(
                          icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                          tooltip: _obscure2 ? t.uiShowPassword : t.uiHidePassword,
                        ),
                      ),
                      obscureText: _obscure2,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return t.valRequired;
                        if (v != _sifre.text) return t.valPasswordMismatch;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Ad Soyad
                    TextFormField(
                      controller: _adSoyad,
                      decoration: InputDecoration(labelText: t.fieldFullName),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().length < 3) ? t.valFullnameInvalid : null,
                    ),
                    const SizedBox(height: 12),

                    // Telefon
                    TextFormField(
                      controller: _tel,
                      decoration: InputDecoration(
                        labelText: t.fieldPhone,
                        hintText: '+905xxxxxxxxx',
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      validator: (v) => _telHata(v, t),
                      onFieldSubmitted: (_) => _kaydetVeOtp(t),
                    ),
                    const SizedBox(height: 16),

                    if (_hata != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_hata!, style: const TextStyle(color: Colors.red)),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _islem ? null : () => _kaydetVeOtp(t),
                        child: _islem
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(t.btnSaveAndVerify),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: const DilDegistiriciFab(),
    );
  }
}

// Küçük geçici çeviri katmanı (ileride gerçek l10n ile değişeceğiz)
class _T {
  final bool tr;
  _T(this.tr);

  static _T of(String code) {
    return _T(code.toLowerCase().startsWith('tr'));
  }

  String get registerTitle => tr ? 'Kayıt' : 'Register';
  String get fieldNickname => tr ? 'Takma ad' : 'Nickname';
  String fieldNicknameHelper(String nick) =>
      tr ? 'Kullanılacak ad: $nick' : 'Will be used as: $nick';
  String get fieldPassword => tr ? 'Şifre' : 'Password';
  String get fieldPasswordRepeat => tr ? 'Şifre tekrarı' : 'Repeat password';
  String get fieldFullName => tr ? 'Ad Soyad' : 'Full name';
  String get fieldPhone => tr ? 'Telefon' : 'Phone';
  String get valRequired => tr ? 'Bu alan zorunludur' : 'This field is required';
  String get valPasswordShort =>
      tr ? 'En az 6 karakter olmalı' : 'Must be at least 6 characters';
  String get valPasswordMismatch =>
      tr ? 'Şifreler uyuşmuyor' : 'Passwords do not match';
  String get valFullnameInvalid =>
      tr ? 'Geçerli bir ad soyad girin' : 'Please enter a valid full name';
  String get valPhoneInvalid =>
      tr ? 'Telefon formatı geçersiz' : 'Phone number is invalid';
  String get uiShowPassword => tr ? 'Şifreyi göster' : 'Show password';
  String get uiHidePassword => tr ? 'Şifreyi gizle' : 'Hide password';
  String get btnSaveAndVerify =>
      tr ? 'Kaydet ve Telefonu Doğrula' : 'Save and verify phone';

  String activeLanguageLabel(String code) =>
      tr ? 'Aktif dil: $code' : 'Active language: $code';
}
