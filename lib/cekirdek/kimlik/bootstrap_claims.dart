// lib/cekirdek/kimlik/bootstrap_claims.dart
import 'dart:async';

/// Başlangıç claims seti ve yönlendirme kararları.
/// Bu katman framework bağımsız tutuldu.
class BootstrapClaims {
  final String status;            // pending_approval | approved
  final String requestedRole;     // student | teacher | ...
  final bool verifiedPhone;       // telefon doğrulandı mı
  final String locale;            // tr-TR
  final String countryCode;       // TR
  final String? locationHierarchy; // İl→İlçe→Mahalle gibi bir path veya id
  final bool agreedTos;           // sözleşme onayı

  const BootstrapClaims({
    required this.status,
    required this.requestedRole,
    required this.verifiedPhone,
    required this.locale,
    required this.countryCode,
    required this.locationHierarchy,
    required this.agreedTos,
  });

  static BootstrapClaims defaults({
    String locale = "tr-TR",
    String countryCode = "TR",
  }) {
    return BootstrapClaims(
      status: "pending_approval",
      requestedRole: "student",
      verifiedPhone: false,
      locale: locale,
      countryCode: countryCode,
      locationHierarchy: null,
      agreedTos: false,
    );
  }

  Map<String, Object?> toMap() => {
        "status": status,
        "requestedRole": requestedRole,
        "verifiedPhone": verifiedPhone,
        "locale": locale,
        "countryCode": countryCode,
        "locationHierarchy": locationHierarchy,
        "agreedTos": agreedTos,
      };
}

enum BootstrapStep {
  needAuth,            // giriş/kayıt
  needPhoneVerify,     // telefon doğrulama
  needTosConsent,      // sözleşme onayı
  needLocationSelect,  // konum seçimi
  needRoleSelect,      // rol seçimi
  pendingApproval,     // onay bekliyor
  goToRoleHome,        // rol ana sayfa
}

class BootstrapDecider {
  const BootstrapDecider();

  /// Kullanıcının mevcut durumuna göre bir sonraki adımı döndürür.
  BootstrapStep decide({
    required bool isSignedIn,
    required BootstrapClaims claims,
  }) {
    if (!isSignedIn) return BootstrapStep.needAuth;
    if (!claims.verifiedPhone) return BootstrapStep.needPhoneVerify;
    if (!claims.agreedTos) return BootstrapStep.needTosConsent;
    if ((claims.locationHierarchy ?? "").isEmpty) {
      return BootstrapStep.needLocationSelect;
    }
    if ((claims.requestedRole).isEmpty) {
      return BootstrapStep.needRoleSelect;
    }
    if (claims.status == "pending_approval") {
      return BootstrapStep.pendingApproval;
    }
    if (claims.status == "approved") {
      return BootstrapStep.goToRoleHome;
    }
    return BootstrapStep.pendingApproval;
  }
}


