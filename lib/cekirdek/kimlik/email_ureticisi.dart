// lib/cekirdek/kimlik/email_ureticisi.dart
/// Takma addan güvenli, geçerli ve deterministik bir "fake" e-posta üretir.
/// Ör: "Mehmet Babaoğlu" -> "mehmet.babaoglu@eduplas.fake"
class EmailUreticisi {
  static const String _domain = 'eduplas.fake';

  /// 1) Trim + lowercase  
  /// 2) Türkçe karakterleri ASCII'ye çevir (ç->c, ğ->g, ı/İ->i, ö->o, ş->s, ü->u)  
  /// 3) Boşlukları '.' yap  
  /// 4) Geçersiz karakterleri temizle (yalnızca [a-z0-9._-] kalsın)  
  /// 5) Birden fazla noktayı tek noktaya indir  
  /// 6) Baştaki/sondaki '.' karakterlerini sil  
  /// 7) En az 3 karakter olacak şekilde "kullanici" ile doldur  
  /// 8) Son olarak "@eduplas.fake" ekle
  static String fakeEmailFromNickname(String nickname) {
    var s = nickname.trim().toLowerCase();

    // Türkçe karakterleri sadeleştir
    s = s
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i') // olası birleşik form
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');

    // Boşluklar -> nokta
    s = s.replaceAll(RegExp(r'\s+'), '.');

    // Geçersiz karakterleri temizle (sadece [a-z0-9._-] kalsın)
    s = s.replaceAll(RegExp(r'[^a-z0-9._-]'), '');

    // Arka arkaya nokta -> tek nokta
    s = s.replaceAll(RegExp(r'\.{2,}'), '.');

    // Baş/son noktayı kırp
    s = s.replaceAll(RegExp(r'^\.'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');

    // Çok kısaysa doldur
    if (s.isEmpty) s = 'kullanici';
    if (s.length < 3) s = '${s}___'.substring(0, 3);

    return '$s@$_domain';
  }

  /// Basit e-posta biçim doğrulama (Firebase kadar katı değil ama yeterli)
  static bool isValidEmailFormat(String email) {
    final re = RegExp(r'^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$');
    return re.hasMatch(email);
  }
}


