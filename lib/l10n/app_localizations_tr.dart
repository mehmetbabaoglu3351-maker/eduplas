// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'EduPlas';

  @override
  String get changeLanguage => 'Dili değiştir';

  @override
  String get registerTitle => 'Kayıt';

  @override
  String get fieldNickname => 'Takma ad';

  @override
  String fieldNicknameHelper(String nick) {
    return 'Kullanılacak ad: $nick';
  }

  @override
  String get fieldPassword => 'Şifre';

  @override
  String get fieldPasswordRepeat => 'Şifre tekrarı';

  @override
  String get fieldFullName => 'Ad Soyad';

  @override
  String get fieldPhone => 'Telefon';

  @override
  String get btnSaveAndVerify => 'Kaydet ve Telefonu Doğrula';

  @override
  String get valRequired => 'Bu alan zorunludur';

  @override
  String get valPasswordShort => 'En az 6 karakter olmalı';

  @override
  String get valPasswordMismatch => 'Şifreler uyuşmuyor';

  @override
  String get valFullnameInvalid => 'Geçerli bir ad soyad girin';

  @override
  String get valPhoneInvalid => 'Telefon formatı geçersiz';

  @override
  String get uiShowPassword => 'Şifreyi göster';

  @override
  String get uiHidePassword => 'Şifreyi gizle';

  @override
  String activeLanguageLabel(String code) {
    return 'Aktif dil: $code';
  }
}
