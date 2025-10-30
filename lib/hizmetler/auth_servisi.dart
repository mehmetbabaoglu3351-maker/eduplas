// lib/hizmetler/auth_servisi.dart
import 'package:firebase_auth/firebase_auth.dart';

/// Email/şifre tabanlı kimlik servisi.
/// Kural: Uygulama genelinde tek e-posta kuralı kullanılır.
/// Biçim: temizlenmis_takma_ad@edu.plas
class AuthServisi {
  AuthServisi({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Geçerli kullanıcı (yoksa null).
  User? get aktifKullanici => _auth.currentUser;

  /// Kimlik durumu akışı.
  Stream<User?> durumAkisi() => _auth.authStateChanges();

  /// Takma adı ASCII ve güvenli karakterlere dönüştürür.
  /// Boşlukları ve Türkçe karakterleri sadeleştirir.
  static String temizTakmaAd(String input) {
    var s = input.trim().toLowerCase();

    // Türkçe karakter sadeleştirme
    s = s
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i') // birleşik noktalı i varyantı
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');

    // Harf, rakam ve alt çizgi/tire dışındakileri ayıkla
    final buf = StringBuffer();
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      if (_isAsciiLetterOrDigit(c) || c == '_' || c == '-') {
        buf.write(c);
      }
    }

    final out = buf.toString();
    return out.isEmpty ? 'kullanici' : out;
  }

  /// Tek e-posta kuralına göre e-posta üretir.
  String _emailFromTakma(String takmaAd) {
    final temiz = temizTakmaAd(takmaAd);
    return '$temiz@edu.plas';
  }

  /// Kayıt olur. E-posta, takma addan türetilir.
  /// Aynı takma ad zaten kayıtlıysa create çağrısından `email-already-in-use` döner.
  Future<UserCredential> kayitOl({
    required String takmaAd,
    required String sifre,
    String? telefon,
  }) async {
    final email = _emailFromTakma(takmaAd);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: sifre,
      );
      await cred.user?.updateDisplayName(takmaAd);
      return cred;
    } on FirebaseAuthException catch (e) {
      // Doğrudan create sonucunu işle (enumeration riskine girme).
      if (e.code == 'email-already-in-use') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Bu takma ad zaten kayıtlı.',
        );
      }
      rethrow;
    }
  }

  /// Giriş yapar. E-posta, takma addan türetilir.
  Future<UserCredential> girisYap({
    required String takmaAd,
    required String sifre,
  }) async {
    final email = _emailFromTakma(takmaAd);
    return _auth.signInWithEmailAndPassword(email: email, password: sifre);
  }

  /// Oturumu kapatır.
  Future<void> cikisYap() => _auth.signOut();

  /// Şifre sıfırlama e-postası gönderir.
  Future<void> sifreSifirla({required String takmaAd}) async {
    final email = _emailFromTakma(takmaAd);
    await _auth.sendPasswordResetEmail(email: email);
  }

  // --- Yardımcılar ---

  static bool _isAsciiLetterOrDigit(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    final isDigit = code >= 48 && code <= 57; // 0-9
    final isUpper = code >= 65 && code <= 90; // A-Z
    final isLower = code >= 97 && code <= 122; // a-z
    return isDigit || isUpper || isLower;
  }
}


