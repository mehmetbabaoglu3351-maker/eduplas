// lib/ayarlar/dil_degistirici.dart
import 'package:flutter/material.dart';
import 'package:eduplas/main.dart'; // EduPlasApp.of(...) için
import 'package:eduplas/l10n/supported_locales.dart'; // kSupportedLocales
import 'package:eduplas/cekirdek/dil/dil_yoneticisi.dart'; // <<< EKLENDİ

/// Uygulama genelinde 60+ dilden hızlı seçim yapmak için FAB.
/// Kullanım: Scaffold(floatingActionButton: const DilDegistiriciFab(), ...)
class DilDegistiriciFab extends StatelessWidget {
  const DilDegistiriciFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'lang_fab',
      icon: const Icon(Icons.translate),
      label: const Text('Dil'),
      onPressed: () async {
        final nav = Navigator.of(context);
        final secilen = await showModalBottomSheet<Locale>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) {
            const tumDiller = kSupportedLocales;
            final current = Localizations.localeOf(ctx);

            return SafeArea(
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.7,
                minChildSize: 0.4,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Dil Seçimi',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: tumDiller.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final l = tumDiller[i];
                            final aktif = l.languageCode == current.languageCode;
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  l.languageCode.toUpperCase(),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              title: Text(_labelFor(l)),
                              trailing: aktif ? const Icon(Icons.check, color: Colors.teal) : null,
                              onTap: () => Navigator.pop(ctx, l),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );

        if (!nav.mounted || secilen == null) return;

        // 1) Seçilen dili MaterialApp'e uygula
        EduPlasApp.of(nav.context)?.setLocale(secilen);

        // 2) Çekirdek dili de güncelle (hukuk, onay, servisler)
        DilYoneticisi.instance.dilAyarla(secilen.languageCode);
      },
    );
  }

  /// Basit etiket üretici: yaygın diller için ana dilinde ad, diğerleri için kod.
  String _labelFor(Locale l) {
    switch (l.languageCode) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'ru':
        return 'Русский';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'it':
        return 'Italiano';
      case 'nl':
        return 'Nederlands';
      case 'sv':
        return 'Svenska';
      case 'no':
        return 'Norsk';
      case 'da':
        return 'Dansk';
      case 'fi':
        return 'Suomi';
      case 'pl':
        return 'Polski';
      case 'cs':
        return 'Čeština';
      case 'hu':
        return 'Magyar';
      case 'ro':
        return 'Română';
      case 'el':
        return 'Ελληνικά';
      case 'bg':
        return 'Български';
      case 'uk':
        return 'Українська';
      case 'sr':
        return 'Српски / Srpski';
      case 'hr':
        return 'Hrvatski';
      case 'sk':
        return 'Slovenčina';
      case 'sl':
        return 'Slovenščina';
      case 'lt':
        return 'Lietuvių';
      case 'lv':
        return 'Latviešu';
      case 'et':
        return 'Eesti';
      case 'hi':
        return 'हिन्दी';
      case 'bn':
        return 'বাংলা';
      case 'ur':
        return 'اردو';
      case 'fa':
        return 'فارسی';
      case 'he':
        return 'עברית';
      case 'th':
        return 'ไทย';
      case 'vi':
        return 'Tiếng Việt';
      case 'id':
        return 'Indonesia';
      case 'ms':
        return 'Melayu';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'ml':
        return 'മലയാളം';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'gu':
        return 'ગુજરાતી';
      case 'mr':
        return 'मराठी';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      case 'si':
        return 'සිංහල';
      case 'km':
        return 'ខ្មែរ';
      case 'lo':
        return 'ລາວ';
      case 'my':
        return 'မြန်မာ';
      case 'am':
        return 'አማርኛ';
      case 'sw':
        return 'Kiswahili';
      case 'zu':
        return 'isiZulu';
      case 'af':
        return 'Afrikaans';
      case 'ka':
        return 'ქართული';
      case 'az':
        return 'Azərbaycan';
      case 'kk':
        return 'Қазақ';
      case 'uz':
        return 'O‘zbek';
      case 'ne':
        return 'नेपाली';
      case 'mn':
        return 'Монгол';
      case 'tg':
        return 'Тоҷикӣ';
      case 'tk':
        return 'Türkmen';
      default:
        return l.languageCode.toUpperCase();
    }
  }
}
