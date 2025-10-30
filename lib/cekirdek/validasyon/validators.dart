// lib/cekirdek/validasyon/validators.dart
// Tek noktadan yönetilen form doğrulama kuralları (TR odaklı) — intl bağımlılığı yok.

class EduValidators {
  /// Boş kontrolü (etiketli)
  static String? required(String? v, {String field = 'Bu alan'}) {
    if (v == null || v.trim().isEmpty) return '$field zorunludur';
    return null;
  }

  /// Takma ad: 3–24 karakter, harf/sayı/altçizgi, harfle başlamalı
  static String? nickname(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'Takma ad zorunludur';
    final re = RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,23}$');
    if (!re.hasMatch(val)) {
      return 'Takma ad 3–24, harfle başlasın, harf/sayı/_ içerebilir';
    }
    return null;
  }

  /// Şifre: min 6 karakter
  static String? password(String? v) {
    final val = v ?? '';
    if (val.isEmpty) return 'Şifre zorunludur';
    if (val.length < 6) return 'Şifre en az 6 karakter olmalı';
    return null;
  }

  /// Telefon: TR 10 hane (başında 0 olmadan)
  static String? phoneTr(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Telefon zorunludur';
    if (digits.length != 10) return 'Telefon 10 hane olmalı (5xx…)';
    return null;
  }

  /// İl / İlçe / Okul gibi metin alanları için basit kontrol
  static String? shortText(String? v, {String field = 'Bu alan', int min = 2, int max = 50}) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return '$field zorunludur';
    if (val.length < min) return '$field en az $min karakter olmalı';
    if (val.length > max) return '$field en fazla $max karakter olabilir';
    return null;
  }

  /// Doğum tarihi: dd.MM.yyyy (opsiyonel)
  /// intl kullanmadan kontrol eder.
  static String? optionalDateTr(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return null;

    final re = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$');
    final m = re.firstMatch(val);
    if (m == null) {
      return 'Tarih biçimi dd.MM.yyyy olmalı (örn: 05.09.2004)';
    }
    final day = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    final year = int.tryParse(m.group(3)!);

    if (day == null || month == null || year == null) {
      return 'Geçersiz tarih';
    }
    if (month < 1 || month > 12) return 'Geçersiz ay';
    if (day < 1 || day > 31) return 'Geçersiz gün';

    // Geçerli gerçek tarih mi? (31 Şubat gibi durumları ele)
    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) {
      return 'Geçersiz tarih';
    }
    return null;
  }
}


