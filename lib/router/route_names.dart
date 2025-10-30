// lib/router/route_names.dart
class RouteNames {
  // KÖK
  static const root = '/';

  // Giriş / kayıt akışı
  static const giris = '/giris';
  static const otp = '/otp';
  static const sozlesmeKabul = '/sozlesme_kabul';

  // Kayıt sihirbazı adımları
  static const rolSec = '/kayit/rol_sec';
  static const ilgiSec = '/kayit/ilgi_sec';

  // Kullanıcı ana ekranı
  static const user = '/kullanici';

  // Ayarlar
  static const dilAyar = '/settings/language';

  // Rol ana sayfaları (ilerisi için)
  static const ogrenciAna = '/rol/ogrenci';
  static const ogretmenAna = '/rol/ogretmen';
  static const koordinatorAna = '/rol/koordinator';
  static const ilceAdminAna = '/rol/ilce_admin';
  static const ilAdminAna = '/rol/il_admin';
  static const basAdminAna = '/rol/bas_admin';
  static const destekciAna = '/rol/destekci';
  static const isyeriAna = '/rol/isyeri';
}
