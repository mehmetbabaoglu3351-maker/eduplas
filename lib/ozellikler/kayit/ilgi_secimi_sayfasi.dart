// lib/ozellikler/kayit/ilgi_secimi_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduplas/router/route_names.dart';

/// EduPlas A3 – İlgi Alanı Seçimi (Sade 8’li model)
/// Amaç: Kayıt sırasında kullanıcıyı YORMADAN ana kategori seçtirmek.
/// Detaylı alt kategoriler daha sonra profil ekranında açılacak.
class IlgiSecimiSayfasi extends StatefulWidget {
  static const route = RouteNames.ilgiSec;
  const IlgiSecimiSayfasi({super.key});

  @override
  State<IlgiSecimiSayfasi> createState() => _IlgiSecimiSayfasiState();
}

class _IlgiSecimiSayfasiState extends State<IlgiSecimiSayfasi> {
  // 8 ANA BAŞLIK
  final List<_IlgiKategori> _anaKategoriler = const [
    _IlgiKategori(
      id: 'akademik',
      ad: 'Akademik Dersler',
      aciklama: 'Matematik, Fen, Türkçe, Sosyal, Yabancı Dil…',
      ikon: Icons.school,
    ),
    _IlgiKategori(
      id: 'bilim_tek',
      ad: 'Bilim & Teknoloji',
      aciklama: 'Kodlama, Robotik, Yapay Zekâ, Mühendislik…',
      ikon: Icons.science,
    ),
    _IlgiKategori(
      id: 'sanat',
      ad: 'Sanat & Yaratıcılık',
      aciklama: 'Müzik, Şiir, Resim, Tiyatro, Tasarım…',
      ikon: Icons.palette,
    ),
    _IlgiKategori(
      id: 'spor',
      ad: 'Spor & Sağlık',
      aciklama: 'Sporlar, hareket, sağlıklı yaşam…',
      ikon: Icons.fitness_center,
    ),
    _IlgiKategori(
      id: 'dil_iletisim',
      ad: 'Dil & İletişim',
      aciklama: 'Dil öğrenimi, yazarlık, sunum…',
      ikon: Icons.translate,
    ),
    _IlgiKategori(
      id: 'meslek',
      ad: 'Meslek & Girişimcilik',
      aciklama: 'Ticaret, esnaflık, finans, inovasyon…',
      ikon: Icons.work,
    ),
    _IlgiKategori(
      id: 'sosyal',
      ad: 'Sosyal Sorumluluk & Toplum',
      aciklama: 'Çevre, gönüllülük, bağış, yardımlaşma…',
      ikon: Icons.volunteer_activism,
    ),
    _IlgiKategori(
      id: 'kultur',
      ad: 'Kültür & Yaşam',
      aciklama: 'Tarih, seyahat, yemek, moda…',
      ikon: Icons.public,
    ),
  ];

  final Set<String> _secili = <String>{};
  bool _kaydediyor = false;
  String? _hata;

  bool get _enAzBirSecildi => _secili.isNotEmpty;

  Future<void> _devamEt() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _hata = 'Oturum bulunamadı.');
      return;
    }

    setState(() {
      _kaydediyor = true;
      _hata = null;
    });

    try {
      // İleride alt kategorilere genişleyebilmek için
      // "anaIlgiler": ['akademik', 'sanat', ...] şeklinde kaydediyoruz
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'anaIlgiler': _secili.toList(),
          'ilgiKayitZamani': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(RouteNames.sozlesmeKabul);
    } catch (e) {
      setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _kaydediyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlgi Alanlarını Seç'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Seni en çok anlatan alanları seç.\nSonra profilden detaylandırabilirsin.',
              style: tema.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: _anaKategoriler.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 x 4 = 8 şık görünür
                  childAspectRatio: 1.35,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final k = _anaKategoriler[index];
                  final secili = _secili.contains(k.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (secili) {
                          _secili.remove(k.id);
                        } else {
                          _secili.add(k.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: secili
                            ? tema.colorScheme.primaryContainer
                            : tema.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: secili
                              ? tema.colorScheme.primary
                              : tema.colorScheme.outlineVariant,
                        ),
                        boxShadow: [
                          if (secili)
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: tema.colorScheme.primary.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: secili
                                ? tema.colorScheme.primary
                                // ignore: deprecated_member_use
                                : tema.colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              k.ikon,
                              color: secili
                                  ? tema.colorScheme.onPrimary
                                  : tema.colorScheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            k.ad,
                            style: tema.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              k.aciklama,
                              style: tema.textTheme.bodySmall?.copyWith(
                                // ignore: deprecated_member_use
                                color: tema.colorScheme.onSurface.withOpacity(0.55),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (secili)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Icon(
                                Icons.check_circle,
                                size: 20,
                                color: tema.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_hata != null) ...[
              const SizedBox(height: 8),
              Text(_hata!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_enAzBirSecildi || _kaydediyor ? null : _devamEt,
                child: _kaydediyor
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Devam'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IlgiKategori {
  final String id;
  final String ad;
  final String aciklama;
  final IconData ikon;

  const _IlgiKategori({
    required this.id,
    required this.ad,
    required this.aciklama,
    required this.ikon,
  });
}
