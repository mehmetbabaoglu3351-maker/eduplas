import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _telCtrl.dispose();
    _kodCtrl.dispose();
    super.dispose();
  }

  void _kodGonder() {
    setState(() {
      _hata = null;
      _kodGonderildi = true;
    });
    _servis.gonderKurtarmaKodu(_telCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kurtarma kodu gönderildi (maket).')),
    );
  }

  void _dogrula() {
    final tel = _telCtrl.text.trim();
    final kod = _kodCtrl.text.trim();
    final ok = _servis.dogrula(tel, kod);
    if (!ok) {
      setState(() => _hata = 'Kod hatalı veya süresi dolmuş.');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kurtarma Başarılı (Maket)'),
        content: const Text('Bu bir simülasyondur. Gerçek sistemde burada parola sıfırlama işlemi yapılır.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SMS ile Kurtarma (Maket)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: _telCtrl,
                  decoration: const InputDecoration(labelText: 'Telefon'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _kodGonder,
                    child: const Text('Kurtarma kodu gönder'),
                  ),
                ),
                const SizedBox(height: 12),
                if (_kodGonderildi) ...[
                  TextField(
                    controller: _kodCtrl,
                    decoration: const InputDecoration(labelText: 'SMS Kodu (6 hane)'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  if (_hata != null) ...[
                    const SizedBox(height: 8),
                    Text(_hata!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _dogrula,
                      child: const Text('Doğrula (maket)'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Not: SMS gönderimi simüle edilir; kod konsola yazılır.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}


