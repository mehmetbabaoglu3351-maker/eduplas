// lib/ozellikler/giris/giris_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/cekirdek/arayuz/app_logo.dart';
import 'package:eduplas/ayarlar/dil_degistirici.dart';
import 'package:eduplas/router/route_names.dart';
import 'package:eduplas/cekirdek/dil/dil_yoneticisi.dart';

/// EduPlas A1 – Güvenli Giriş ve Kurtarma Akışı
/// Bu ekran artık TELEFON ZORUNLU + DOĞUM TARİHİ ZORUNLU.
/// Akış:
/// - Giriş: Telefon + Şifre + Doğum Tarihi → OTP (mode: login)
/// - "Hesabım yok mu? Kaydol" → RouteNames.kayit
/// - "Hesabımı Kurtar" → OTP (mode: recovery)
class GirisSayfasi extends StatefulWidget {
  static const route = RouteNames.giris;
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _formKey = GlobalKey<FormState>();

  // Alanlar
  final _telefon = TextEditingController();
  final _sifre = TextEditingController();
  final _dogumTarihiCtrl = TextEditingController();

  DateTime? _seciliDogumTarihi;

  bool _islem = false;
  bool _obscure = true;
  String? _hata;

  String _aktifDil = 'tr';

  @override
  void initState() {
    super.initState();
    _telefon.addListener(_onAlanChanged);

    _aktifDil = DilYoneticisi.instance.aktifDil;
    DilYoneticisi.instance.addListener(_onDilChanged);
  }

  @override
  void dispose() {
    _telefon
      ..removeListener(_onAlanChanged)
      ..dispose();
    _sifre.dispose();
    _dogumTarihiCtrl.dispose();
    DilYoneticisi.instance.removeListener(_onDilChanged);
    super.dispose();
  }

  void _onDilChanged() {
    if (!mounted) return;
    setState(() {
      _aktifDil = DilYoneticisi.instance.aktifDil;
    });
  }

  void _onAlanChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String _sadeceRakamlar(String input) => input.replaceAll(RegExp(r'[^0-9+]'), '');

  bool _girdiTelefonMu(String input) {
    final tel = _sadeceRakamlar(input);
    final digits = tel.replaceAll('+', '');
    return digits.length >= 10 && digits.length <= 15;
  }

  Future<void> _tarihSec(_T t) async {
    // 100 yıl geriye gidebilsin
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 100, now.month, now.day);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _seciliDogumTarihi ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: t.dateHelp,
    );

    if (picked != null) {
      setState(() {
        _seciliDogumTarihi = picked;
        _dogumTarihiCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year.toString()}';
      });
    }
  }

  Future<void> _girisYap(_T t) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _islem = true;
      _hata = null;
    });

    try {
      final tel = _sadeceRakamlar(_telefon.text.trim());
      final sifre = _sifre.text.trim();
      final dogum = _seciliDogumTarihi?.toIso8601String();

      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        RouteNames.otp,
        arguments: <String, dynamic>{
          'nick': '', // artık girişte nick almıyoruz
          'phone': tel,
          'password': sifre,
          'birthdate': dogum,
          'mode': 'login',
        },
      );
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  Future<void> _yeniKayit(_T t) async {
    if (!mounted) return;
    Navigator.pushNamed(context, RouteNames.kayit);
  }

  Future<void> _hesabimiKurtar(_T t) async {
    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      RouteNames.otp,
      arguments: <String, dynamic>{
        'mode': 'recovery',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _T.of(_aktifDil);
    final girisDegeri = _telefon.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.loginTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
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
                      t.slogan,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.activeLanguageLabel(_aktifDil),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black45,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Telefon (zorunlu)
                    TextFormField(
                      controller: _telefon,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: t.fieldPhone,
                        helperText: t.fieldPhoneHelper,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t.valRequired;
                        }
                        if (!_girdiTelefonMu(v.trim())) {
                          return t.valPhoneInvalid;
                        }
                        return null;
                      },
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),

                    // Doğum tarihi (zorunlu)
                    TextFormField(
                      controller: _dogumTarihiCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: t.fieldBirthdate,
                        helperText: t.fieldBirthdateHelper,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _tarihSec(t),
                        ),
                      ),
                      onTap: () => _tarihSec(t),
                      validator: (v) {
                        if (_seciliDogumTarihi == null) {
                          return t.valBirthdateRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Şifre
                    TextFormField(
                      controller: _sifre,
                      decoration: InputDecoration(
                        labelText: t.fieldPassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                          tooltip: _obscure ? t.uiShowPassword : t.uiHidePassword,
                        ),
                      ),
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _girisYap(t),
                      validator: (v) =>
                          (v == null || v.length < 6) ? t.valPasswordShort : null,
                    ),
                    const SizedBox(height: 16),

                    if (_hata != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_hata!, style: const TextStyle(color: Colors.red)),
                      ),

                    // Giriş yap
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _islem ? null : () => _girisYap(t),
                        child: _islem
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(t.btnLogin),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Hesabımı Kurtar
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _islem ? null : () => _hesabimiKurtar(t),
                        child: Text(t.btnRecovery),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Yeni kayıt bağlantısı
                    TextButton(
                      onPressed: _islem ? null : () => _yeniKayit(t),
                      child: Text(t.btnRegisterNow),
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

// Küçük geçici çeviri katmanı
class _T {
  final bool tr;
  _T(this.tr);

  static _T of(String code) {
    return _T(code.toLowerCase().startsWith('tr'));
  }

  String get loginTitle => tr ? 'Giriş' : 'Sign in';
  String get fieldPhone => tr ? 'Telefon' : 'Phone';
  String get fieldPhoneHelper =>
      tr ? 'Telefon formatı: +90 5xx ... Zorunlu.' : 'Phone in intl format. Required.';
  String get fieldPassword => tr ? 'Şifre' : 'Password';
  String get fieldBirthdate => tr ? 'Doğum Tarihi' : 'Birthdate';
  String get fieldBirthdateHelper =>
      tr ? 'Doğum tarihinizi seçin (100 yıl geriye gidebilir).' : 'Select your birthdate.';
  String get valRequired => tr ? 'Bu alan zorunludur' : 'This field is required';
  String get valPhoneInvalid =>
      tr ? 'Geçerli bir telefon numarası girin' : 'Enter a valid phone number';
  String get valBirthdateRequired =>
      tr ? 'Doğum tarihi seçilmelidir' : 'Birthdate is required';
  String get valPasswordShort => tr ? 'En az 6 karakter olmalı' : 'Must be at least 6 characters';
  String get uiShowPassword => tr ? 'Şifreyi göster' : 'Show password';
  String get uiHidePassword => tr ? 'Şifreyi gizle' : 'Hide password';
  String get btnLogin => tr ? 'Giriş Yap' : 'Sign in';
  String get btnRecovery => tr ? 'Hesabımı Kurtar' : 'Recover account';
  String get btnRegisterNow => tr ? 'Hesabın yok mu? Kaydol' : 'No account? Register';

  String get slogan =>
      tr ? 'Öğren, kazan; Öğret, kazandır.' : 'Learn and earn; Teach and empower.';

  String activeLanguageLabel(String code) =>
      tr ? 'Aktif dil: $code' : 'Active language: $code';

  String get dateHelp => tr ? 'Doğum tarihinizi seçin' : 'Select your birthdate';
}
