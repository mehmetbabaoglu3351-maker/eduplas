// lib/ozellikler/kayit/sms_kurtarma_sayfasi.dart
//
// Düzeltilmiş sürüm:
// - await_only_futures hatası giderildi
// - deprecated olan gonderKurtarmaKodu artık çağrılmıyor
// - Sadece gonderKod(...) kullanılıyor
// - Geri kalan akış aynı

import 'package:flutter/material.dart';
import 'package:eduplas/cekirdek/arayuz/app_logo.dart';
import 'package:eduplas/router/route_names.dart';
import '../../hizmetler/mock_sms_servisi.dart';

class SmsKurtarmaSayfasi extends StatefulWidget {
  static const route = '/sms_kurtarma';
  const SmsKurtarmaSayfasi({super.key});

  @override
  State<SmsKurtarmaSayfasi> createState() => _SmsKurtarmaSayfasiState();
}

class _SmsKurtarmaSayfasiState extends State<SmsKurtarmaSayfasi> {
  final _telCtrl = TextEditingController();
  final _kodCtrl = TextEditingController();
  final _servis = MockSmsServisi();

  String? _hata;
  bool _kodGonderildi = false;
  bool _islem = false;

  @override
  void dispose() {
    _telCtrl.dispose();
    _kodCtrl.dispose();
    super.dispose();
  }

  Future<void> _kodGonder() async {
    final tel = _telCtrl.text.trim();
    if (tel.isEmpty) {
      setState(() => _hata = 'Telefon alanı zorunlu.');
      return;
    }

    setState(() {
      _hata = null;
      _islem = true;
    });

    try {
      // DÜZELTİLEN KISIM: artık await edilen fonksiyon gerçek Future döndürüyor
      await _servis.gonderKod(tel);

      if (!mounted) return;
      setState(() {
        _kodGonderildi = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kurtarma kodu gönderildi (maket).')),
      );
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _islem = false);
    }
  }

  Future<void> _dogrula() async {
    final tel = _telCtrl.text.trim();
    final kod = _kodCtrl.text.trim();

    if (tel.isEmpty || kod.isEmpty) {
      setState(() => _hata = 'Telefon ve kod zorunludur.');
      return;
    }

    final ok = _servis.dogrula(tel, kod);
    if (!ok) {
      setState(() => _hata = 'Kod hatalı veya süresi dolmuş.');
      return;
    }

    // Kod doğru → yeni şifre verelim (simülasyon)
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) {
        final newPassCtrl = TextEditingController(text: 'Eduplas123!');
        return AlertDialog(
          title: const Text('Kurtarma Başarılı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Bu bir simülasyondur. Gerçek sistemde burada kullanıcı şifresi güncellenir.'),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                // Burada gerçek FirebaseAuth updatePassword çağrısı yapılacak.
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Yeni şifre kaydedildi (maket): ${newPassCtrl.text}'),
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    // Giriş ekranına gönder
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RouteNames.giris);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMS ile Kurtarma')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(daire: true, compactHint: true),
                    const SizedBox(height: 4),
                    Text(
                      'EduPlas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF00BFA5),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Öğren, kazan; Öğret, kazandır.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _telCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        hintText: '+905xxxxxxxxx',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _islem ? null : _kodGonder,
                        child: _islem
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kurtarma kodu gönder'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_kodGonderildi) ...[
                      TextField(
                        controller: _kodCtrl,
                        decoration: const InputDecoration(
                          labelText: 'SMS Kodu (6 hane)',
                          counterText: '',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _dogrula,
                          child: const Text('Doğrula ve devam et'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (_hata != null)
                      Text(
                        _hata!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Not: SMS gönderimi simüle edilir; kod servis içinde üretilir.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
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
