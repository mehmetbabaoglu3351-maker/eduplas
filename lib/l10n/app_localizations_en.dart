// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EduPlas';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get registerTitle => 'Register';

  @override
  String get fieldNickname => 'Nickname';

  @override
  String fieldNicknameHelper(String nick) {
    return 'Will be used as: $nick';
  }

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordRepeat => 'Repeat password';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldPhone => 'Phone';

  @override
  String get btnSaveAndVerify => 'Save and verify phone';

  @override
  String get valRequired => 'This field is required';

  @override
  String get valPasswordShort => 'Must be at least 6 characters';

  @override
  String get valPasswordMismatch => 'Passwords do not match';

  @override
  String get valFullnameInvalid => 'Please enter a valid full name';

  @override
  String get valPhoneInvalid => 'Phone number is invalid';

  @override
  String get uiShowPassword => 'Show password';

  @override
  String get uiHidePassword => 'Hide password';

  @override
  String activeLanguageLabel(String code) {
    return 'Active language: $code';
  }
}
