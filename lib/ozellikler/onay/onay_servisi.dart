// lib/ozellikler/onay/onay_servisi.dart
// Sprint-1 MOCK Onay Servisi (Firebase yok)
// - In-memory saklama + yayın
// - Baş Admin yalnız bootstrap'ta oto-onay
// - Tekil "location" haritası esas; eski il/ilçe/mahalle yalnız okuma için çözümlenir.
// - + Hukuk modülü için ayrı onay listesi eklendi (H1-H4 ...)

import 'dart:async';

/// Başvuru modeli (rol / yetki başvuruları için)
class Basvuru {
  final String uid; // başvuran uid
  final String takmaAd;
  final String telefon;
  final String requestedRole; // ham rol adı
  final Map<String, dynamic>? location; // { admin1, admin2, locality, ... }
  final String okul;

  final String? approverUid; // atanan onaycı (varsa)
  final DateTime? createdAt;

  final String status; // pending | approved | rejected
  final String? profilAdSoyad; // opsiyonel
  final DateTime? updatedAt;

  const Basvuru({
    required this.uid,
    required this.takmaAd,
    required this.telefon,
    required this.requestedRole,
    required this.okul,
    required this.status,
    this.location,
    this.approverUid,
    this.createdAt,
    this.updatedAt,
    this.profilAdSoyad,
  });

  Basvuru copyWith({
    String? uid,
    String? takmaAd,
    String? telefon,
    String? requestedRole,
    Map<String, dynamic>? location,
    String? okul,
    String? status,
    String? approverUid,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilAdSoyad,
  }) {
    return Basvuru(
      uid: uid ?? this.uid,
      takmaAd: takmaAd ?? this.takmaAd,
      telefon: telefon ?? this.telefon,
      requestedRole: requestedRole ?? this.requestedRole,
      location: location ?? this.location,
      okul: okul ?? this.okul,
      status: status ?? this.status,
      approverUid: approverUid ?? this.approverUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilAdSoyad: profilAdSoyad ?? this.profilAdSoyad,
    );
  }

  ({String il, String ilce, String mahalle}) get konum3 {
    final k = OnayServisi.cozKonum(location);
    return (il: k.il, ilce: k.ilce, mahalle: k.mahalle);
  }
}

/// Hukuki onay kaydı (H1, H2, H3, H4 ...)
class HukukiOnay {
  final String uid;
  final String belgeKod; // H1, H2...
  final String versiyon; // v1.0
  final DateTime tarih;

  const HukukiOnay({
    required this.uid,
    required this.belgeKod,
    required this.versiyon,
    required this.tarih,
  });
}

/// MOCK Onay Servisi (Singleton)
class OnayServisi {
  OnayServisi._();
  static final OnayServisi _i = OnayServisi._();
  factory OnayServisi() => _i;
  static OnayServisi get instance => _i;

  // uid -> rol (normalize)
  final Map<String, String> _roller = <String, String>{};

  // uid -> kapsam üçlüsü
  final Map<String, ({String il, String ilce, String mahalle})> _kapsam =
      <String, ({String il, String ilce, String mahalle})>{};

  // uid -> görünen ad
  final Map<String, String> _gorunenAd = <String, String>{};

  // registrations (uid -> başvuru)
  final Map<String, Basvuru> _kayitlar = <String, Basvuru>{};

  // hukuk onayları (uid -> liste)
  final Map<String, List<HukukiOnay>> _hukukiOnaylar =
      <String, List<HukukiOnay>>{};

  final StreamController<List<Basvuru>> _yayinci =
      StreamController<List<Basvuru>>.broadcast();

  // ------------------- Bootstrap / seed -------------------

  void seedKullanici({
    required String uid,
    required String rol,
    required Map<String, dynamic> location,
    required String adSoyad,
  }) {
    _roller[uid] = _normalizeRole(rol);
    final k = cozKonum(location);
    _kapsam[uid] = (il: k.il, ilce: k.ilce, mahalle: k.mahalle);
    _gorunenAd[uid] = adSoyad;
  }

  // ------------------- Basit getter'lar -------------------

  String? rol(String uid) => _roller[uid];
  String ad(String uid) => _gorunenAd[uid] ?? uid;

  // ------------------- Başvuru ekleme / güncelleme -------------------

  void kayitEkleVeyaGuncelle(Basvuru b) {
    final mevcut = _kayitlar[b.uid];
    final created = b.createdAt ?? mevcut?.createdAt ?? DateTime.now();
    final status = b.status.isEmpty ? 'pending' : b.status;
    final guncel = b.copyWith(
      createdAt: created,
      updatedAt: DateTime.now(),
      status: status,
    );
    _kayitlar[b.uid] = guncel;
    _yayinla();
  }

  /// kayıt oluştuğunda uygun onaycıyı ata ya da oto-onayla
  Future<void> kaydaOnaylayiciAtaVeyaOtoOnayla({
    required String registrationUid,
  }) async {
    final b = _kayitlar[registrationUid];
    if (b == null || b.status != 'pending') return;

    final hedefRol = _hedefOnaylayiciRol(b.requestedRole);
    if (hedefRol == null) {
      // Baş Admin oto-onay (bootstrap)
      final onayli = b.copyWith(
        status: 'approved',
        approverUid: 'system',
        updatedAt: DateTime.now(),
      );
      _kayitlar[registrationUid] = onayli;
      _yayinla();
      return;
    }

    final k = cozKonum(b.location);
    final approverUid = _uygunOnaylayiciBul(
      hedefRol: hedefRol,
      il: k.il,
      ilce: k.ilce,
      mahalle: k.mahalle,
    );

    final guncel = b.copyWith(
      approverUid: approverUid,
      updatedAt: DateTime.now(),
    );
    _kayitlar[registrationUid] = guncel;
    _yayinla();
  }

  // ------------------- Listeleme / stream -------------------

  Stream<List<Basvuru>> bekleyenBasvurulariDinle({
    required String currentUid,
    required String currentUserRole,
    required String il,
    required String ilce,
    required String mahalle,
  }) {
    final curRole = _normalizeRole(currentUserRole);
    final i = il.trim().toLowerCase();
    final ic = ilce.trim().toLowerCase();
    final m = mahalle.trim().toLowerCase();

    return _yayinci.stream.map((liste) {
      // doğrudan atanmışlar
      final directly = liste
          .where((b) =>
              b.status == 'pending' &&
              (b.approverUid != null && b.approverUid == currentUid))
          .toList();
      if (directly.isNotEmpty) return directly;

      // yedek: rol + kapsam eşleşmesi
      return liste.where((b) {
        if (b.status != 'pending') return false;
        final hedefRol = _hedefOnaylayiciRol(b.requestedRole);
        if (hedefRol == null) return false;
        if (_normalizeRole(hedefRol) != curRole) return false;
        final k = cozKonum(b.location);
        return _konumEslesir(
          il1: i,
          ilce1: ic,
          mahalle1: m,
          il2: k.il,
          ilce2: k.ilce,
          mahalle2: k.mahalle,
        );
      }).toList();
    });
  }

  // ------------------- Başvuru onay / ret -------------------

  Future<void> onayla({
    required Basvuru b,
    required String onaylayanUid,
  }) async {
    final kayit = _kayitlar[b.uid];
    if (kayit == null || kayit.status != 'pending') return;
    if (kayit.approverUid != null && kayit.approverUid != onaylayanUid) return;

    final g = kayit.copyWith(
      status: 'approved',
      updatedAt: DateTime.now(),
      approverUid: onaylayanUid,
    );
    _kayitlar[b.uid] = g;
    _yayinla();
  }

  Future<void> reddet({
    required Basvuru b,
    required String reddedenUid,
    String? sebep,
  }) async {
    final kayit = _kayitlar[b.uid];
    if (kayit == null || kayit.status != 'pending') return;
    if (kayit.approverUid != null && kayit.approverUid != reddedenUid) return;

    final g = kayit.copyWith(
      status: 'rejected',
      updatedAt: DateTime.now(),
      approverUid: reddedenUid,
    );
    _kayitlar[b.uid] = g;
    _yayinla();
  }

  // ------------------- Hukuk onayları (yeni) -------------------

  /// Kullanıcı bir hukuki belgeyi (H1-H4) onayladığında buraya yazılır.
  /// Kayıt sihirbazı bu metodu çağıracak.
  Future<void> hukukOnayEkle({
    required String uid,
    required String belgeKod,
    required String versiyon,
  }) async {
    final liste = _hukukiOnaylar.putIfAbsent(uid, () => <HukukiOnay>[]);
    // Aynı belge + versiyon tekrar eklenmesin
    final already = liste.any(
      (e) => e.belgeKod == belgeKod && e.versiyon == versiyon,
    );
    if (!already) {
      liste.add(
        HukukiOnay(
          uid: uid,
          belgeKod: belgeKod,
          versiyon: versiyon,
          tarih: DateTime.now(),
        ),
      );
    }
  }

  /// Kullanıcının o ana kadar verdiği tüm hukuk onaylarını getirir.
  List<HukukiOnay> kullanicininHukukOnaylari(String uid) {
    return List<HukukiOnay>.unmodifiable(
      _hukukiOnaylar[uid] ?? const <HukukiOnay>[],
    );
  }

  /// Belirli bir sözleşmeyi onaylamış mı?
  bool kullaniciBelgeyiOnaylamisMi({
    required String uid,
    required String belgeKod,
  }) {
    final liste = _hukukiOnaylar[uid];
    if (liste == null) return false;
    return liste.any((e) => e.belgeKod == belgeKod);
  }

  /// Zorunlu olanların hepsi bu kullanıcıda var mı?
  bool kullaniciZorunluHukuklariTamMi({
    required String uid,
    required List<dynamic> dokumanlar,
  }) {
    final liste = _hukukiOnaylar[uid];
    if (liste == null) return false;
    // dokumanlar: LegalVersiyonlar.dokumanlar
    final zorunlu = dokumanlar.where((d) => d.zorunlu).toList();
    for (final z in zorunlu) {
      final ok = liste.any((e) => e.belgeKod == z.id);
      if (!ok) return false;
    }
    return true;
  }

  // ------------------- Yardımcılar -------------------

  void _yayinla() {
    _yayinci.add(
      _kayitlar.values.toList()
        ..sort(
          (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                  a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        ),
    );
  }

  /// Onaylayacak hedef rol
  String? _hedefOnaylayiciRol(String requestedRoleRaw) {
    final r = _normalizeRole(requestedRoleRaw);
    switch (r) {
      // Admin ailesi
      case 'bas_admin':
        return null; // oto-onay
      case 'admin':
        return 'bas_admin';
      case 'ulke_admin':
        return 'admin';
      case 'il_admin':
        return 'ulke_admin';

      // Alt zincir
      case 'koordinator':
        return 'il_admin';
      case 'ogretmen':
        return 'koordinator';
      case 'ogrenci':
        return 'ogretmen';
      case 'destekci':
        return 'koordinator';
      case 'isyeri':
        return 'koordinator'; // Üye işyeri

      default:
        return 'koordinator';
    }
  }

  String? _uygunOnaylayiciBul({
    required String hedefRol,
    required String il,
    required String ilce,
    required String mahalle,
  }) {
    final target = _normalizeRole(hedefRol);
    final i = il.trim().toLowerCase();
    final ic = ilce.trim().toLowerCase();
    final m = mahalle.trim().toLowerCase();

    // mahalle
    if (m.isNotEmpty) {
      final k = _roller.entries.firstWhere(
        (e) =>
            e.value == target &&
            _kapsam[e.key]?.il.toLowerCase() == i &&
            _kapsam[e.key]?.ilce.toLowerCase() == ic &&
            _kapsam[e.key]?.mahalle.toLowerCase() == m,
        orElse: () => const MapEntry<String, String>('', ''),
      );
      if (k.key.isNotEmpty) return k.key;
    }
    // ilçe
    if (ic.isNotEmpty) {
      final k = _roller.entries.firstWhere(
        (e) =>
            e.value == target &&
            _kapsam[e.key]?.il.toLowerCase() == i &&
            _kapsam[e.key]?.ilce.toLowerCase() == ic,
        orElse: () => const MapEntry<String, String>('', ''),
      );
      if (k.key.isNotEmpty) return k.key;
    }
    // il
    if (i.isNotEmpty) {
      final k = _roller.entries.firstWhere(
        (e) => e.value == target && _kapsam[e.key]?.il.toLowerCase() == i,
        orElse: () => const MapEntry<String, String>('', ''),
      );
      if (k.key.isNotEmpty) return k.key;
    }
    return null;
  }

  bool _konumEslesir({
    required String il1,
    required String ilce1,
    required String mahalle1,
    required String il2,
    required String ilce2,
    required String mahalle2,
  }) {
    final m1 = mahalle1.trim().toLowerCase();
    final m2 = mahalle2.trim().toLowerCase();
    final i1 = il1.trim().toLowerCase();
    final i2 = il2.trim().toLowerCase();
    final ic1 = ilce1.trim().toLowerCase();
    final ic2 = ilce2.trim().toLowerCase();

    if (m2.isNotEmpty) return (m1 == m2 && ic1 == ic2 && i1 == i2);
    if (ic2.isNotEmpty) return (ic1 == ic2 && i1 == i2);
    if (i2.isNotEmpty) return (i1 == i2);
    return false;
  }

  /// Normalize (TR varyantlar dâhil)
  String _normalizeRole(String r) {
    final s = r.trim().toLowerCase();
    switch (s) {
      case 'baş admin':
      case 'bas admin':
      case 'baş_admin':
      case 'bas_admin':
      case 'başadmin':
      case 'basadmin':
        return 'bas_admin';

      case 'admin':
      case 'yönetici':
      case 'yonetici':
        return 'admin';

      case 'ülke admini':
      case 'ulke admini':
      case 'ülke_admini':
      case 'ulke_admini':
      case 'ülke yöneticisi':
      case 'ulke yoneticisi':
        return 'ulke_admin';

      case 'il admini':
      case 'il admin':
      case 'il_admini':
      case 'il_admin':
      case 'il yoneticisi':
        return 'il_admin';

      case 'koordinatör':
      case 'koordinator':
        return 'koordinator';

      case 'öğretmen':
      case 'ogretmen':
        return 'ogretmen';

      case 'öğrenci':
      case 'ogrenci':
        return 'ogrenci';

      case 'destekçi':
      case 'destekci':
        return 'destekci';

      // İşyeri = Üye İş Yeri (ayrı rol)
      case 'işyeri':
      case 'isyeri':
      case 'üye işyeri':
      case 'uye isyeri':
      case 'üye_işyeri':
      case 'uye_isyeri':
      case 'iş ortağı':
      case 'is ortagi':
      case 'iş_ortağı':
      case 'is_ortagi':
        return 'isyeri';

      default:
        return s;
    }
  }

  /// location -> (il, ilce, mahalle)
  static ({String il, String ilce, String mahalle}) cozKonum(
    Map<String, dynamic>? location, {
    String il = '',
    String ilce = '',
    String mahalle = '',
  }) {
    if (location != null && location.isNotEmpty) {
      final admin1 = (location['admin1'] ?? '').toString();
      final admin2 = (location['admin2'] ?? '').toString();
      final loc = (location['locality'] ?? '').toString();
      return (il: admin1, ilce: admin2, mahalle: loc);
    }
    return (il: il, ilce: ilce, mahalle: mahalle);
  }
}
