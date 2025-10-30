// lib/router/route_names.dart
/// Uygulama içinde kullanılan rota adlarının tek kaynağı.
/// Akış (MVP):
/// /giris → /otp → /rol_sec → /ilgi_sec → /sozlesme_kabul → /user
class RouteNames {
  // Ana girişler
  static const String root = '/';
  static const String giris = '/giris';
  static const String otp = '/otp';

  // Hukuk / onay
  static const String legal = '/legal';
  static const String sozlesmeKabul = '/sozlesme_kabul';
  static const String onay = '/onay';

  // Kullanıcı
  static const String user = '/user';

  // Ayarlar
  static const String lang = '/settings/language';

  // Kayıt akışı (yeni)
  static const String rolSec = '/rol_sec';
  static const String ilgiSec = '/ilgi_sec';

  static Object? get kayit => null;
}
