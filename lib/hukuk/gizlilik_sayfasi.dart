// lib/hukuk/gizlilik_sayfasi.dart
import 'package:flutter/material.dart';

const String kGizlilikVersion = 'gizlilik_v1';

class GizlilikSayfasi extends StatelessWidget {
  static const routeName = '/hukuk/gizlilik';

  const GizlilikSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik Politikası')),
      body: const _HukukBody(
        children: [
          SelectableText(
            'EDUPLAS GİZLİLİK POLİTİKASI',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          SizedBox(height: 12),

          _Paragraf(
            'Bu politika; hangi verileri topladığımızı, nasıl kullandığımızı ve nasıl koruduğumuzu açıklar.',
          ),

          _Baslik('Toplanan Veriler'),
          _Paragraf(
            'Kimlik, iletişim, konum (seçim veya izinle cihaz), eğitim/rol, cihaz/teknik loglar, profil bilgisi, çerez verisi.',
          ),

          _Baslik('Amaçlar'),
          _Paragraf(
            'Üyelik/doğrulama, hizmet sunumu, güvenlik, geliştirme, yasal yükümlülükler.',
          ),

          _Baslik('Üçüncü Taraflar ve Aktarım'),
          _Paragraf(
            'Altyapı Google Firebase olup sunucu konumları nedeniyle yurt dışına veri aktarımı olabilir. '
            'Şifreleme, asgari veri ve erişim kontrolü uygulanır.',
          ),

          _Baslik('Güvenlik Önlemleri'),
          _Paragraf(
            'Şifreleme, Firebase Security Rules, yetkilendirme, log/audit, en az yetki ilkesi.',
          ),

          _Baslik('Çerezler ve Analitik'),
          _Paragraf(
            'Davranış analizi için anonim çerezler kullanılabilir. Hassas kimlik bilgileri çerezlerde tutulmaz.',
          ),

          _Baslik('Saklama'),
          _Paragraf(
            'Hesap aktif olduğu sürece; fesihte kanuni saklama süreleri haricinde silinir/anonimleştirilir.',
          ),

          _Baslik('Haklar'),
          _Paragraf('KVKK 11 kapsamındaki haklarınız için: kvkk@eduplas.com'),

          SizedBox(height: 16),
          Divider(),
          _FooterMeta(),
        ],
      ),
    );
  }
}

class _HukukBody extends StatelessWidget {
  final List<Widget> children;
  const _HukukBody({required this.children});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}

class _Baslik extends StatelessWidget {
  final String text;
  const _Baslik(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SelectableText(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Paragraf extends StatelessWidget {
  final String text;
  const _Paragraf(this.text);

  @override
  Widget build(BuildContext context) {
    return SelectableText(text);
  }
}

class _FooterMeta extends StatelessWidget {
  const _FooterMeta();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        SelectableText(
          'Sürüm: $kGizlilikVersion',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        SelectableText(
          'Son güncelleme: 2025-10-28',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
