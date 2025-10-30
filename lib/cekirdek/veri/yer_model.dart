// lib/cekirdek/veri/yer_model.dart
/// Küresel Yerleşim Hiyerarşisi (A1)
/// Ulke → Il (Admin1) → Ilce (Admin2) → Mahalle (Locality) → Semt (Sublocality)
/// TR legacy alanlar korunur: ilKod, ilceKod, mahalleKod vb.
/// Çok dillilik: JSON'dan `name`, `name_tr`, `name_en`, `label`, `adi` vb. anahtarları okuyup
/// uygun locale için gösterim sağlayan yardımcılar vardır.
library yer_model;

/// -------------------- Ortak Yardımcılar --------------------

/// Verilen JSON nesnesinden, sıralı anahtar listesinde ilk bulunan metni okur.
String? _readString(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    if (v is num) return v.toString();
  }
  return null;
}

/// Verilen JSON nesnesinden, sıralı anahtar listesinde ilk bulunan listeyi okur.
List<dynamic>? _readList(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v is List) return v;
  }
  return null;
}

/// Aksan/işaret temizleme (slug/arama için sadeleştirme).
String aksanTemizle(String input) {
  var s = input.toLowerCase().trim();
  s = s
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('i̇', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll(RegExp(r'[^\w\s-]'), ' ') // harf/rakam/dash dışını boşluk yap
      .replaceAll(RegExp(r'\s+'), ' ') // çoklu boşlukları tek boşluk yap
      .trim();
  return s;
}

/// Basit slug üretici: aksanları temizler, boşlukları `-` yapar.
String slugify(String input) {
  final base = aksanTemizle(input);
  return base.replaceAll(' ', '-');
}

/// Çok dilli ad okuma: birden fazla muhtemel anahtardan dilleri çeker.
/// Dönüşte [tr], [en] ve [base] sağlar. `base` bulunamazsa [tr] veya [en] fallback olur.
class DilAd {
  final String base; // orijinal veya en iyi bulunan
  final String? tr;
  final String? en;

  const DilAd({required this.base, this.tr, this.en});

  factory DilAd.fromJson(Map<String, dynamic> j) {
    final tr = _readString(j, ['name_tr', 'ad_tr', 'adi_tr', 'label_tr', 'tr']);
    final en = _readString(j, ['name_en', 'ad_en', 'adi_en', 'label_en', 'en']);
    final base = _readString(j, ['name', 'ad', 'adi', 'label', 'title']) ??
        tr ??
        en ??
        '';
    return DilAd(base: base, tr: tr, en: en);
  }

  /// Verilen locale koduna göre en uygun adı verir. Örn: "tr", "tr-TR", "en", "en-US"
  String forLocale(String? locale) {
    if (locale == null || locale.isEmpty) return base;
    final l = locale.toLowerCase();
    if (l.startsWith('tr') && (tr != null && tr!.isNotEmpty)) return tr!;
    if (l.startsWith('en') && (en != null && en!.isNotEmpty)) return en!;
    return base;
  }

  Map<String, dynamic> toJson() => {
        'base': base,
        if (tr != null) 'tr': tr,
        if (en != null) 'en': en,
      };
}

/// -------------------- Modeller --------------------

class Semt {
  final String slug;
  final String ad; // base gösterim (çok dilliden seçilmiş ya da tekil alan)
  final String? kod; // optional legacy/code

  const Semt({
    required this.slug,
    required this.ad,
    this.kod,
  });

  factory Semt.fromJson(Map<String, dynamic> j, {String? locale}) {
    final dilAd = DilAd.fromJson(j);
    final ad = (dilAd.base.isNotEmpty ? dilAd.forLocale(locale) : '') //
        .ifEmpty(_readString(j, ['ad', 'adi', 'name', 'label']) ?? '');
    return Semt(
      slug: _readString(j, ['slug', 'id', 'key']) ??
          slugify(ad.isNotEmpty ? ad : 'semt'),
      ad: ad,
      kod: _readString(j, ['kod', 'code']),
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'ad': ad,
        if (kod != null) 'kod': kod,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Semt && slug == other.slug && ad == other.ad && kod == other.kod;

  @override
  int get hashCode => Object.hash(slug, ad, kod);
}

class Mahalle {
  final String slug;
  final String ad;
  final String? kod;
  final List<Semt> semtler; // Sublocality

  const Mahalle({
    required this.slug,
    required this.ad,
    this.kod,
    this.semtler = const [],
  });

  factory Mahalle.fromJson(Map<String, dynamic> j, {String? locale}) {
    final dilAd = DilAd.fromJson(j);
    final ad = (dilAd.base.isNotEmpty ? dilAd.forLocale(locale) : '') //
        .ifEmpty(_readString(j, ['ad', 'adi', 'name', 'label']) ?? '');

    final rawSemt =
        _readList(j, ['semt', 'semtler', 'sublocalities', 'items']);
    final semtler = (rawSemt ?? [])
        .whereType<Map<String, dynamic>>()
        .map((m) => Semt.fromJson(m, locale: locale))
        .toList(growable: false);

    return Mahalle(
      slug: _readString(j, ['slug', 'id', 'key']) ??
          slugify(ad.isNotEmpty ? ad : 'mahalle'),
      ad: ad,
      kod: _readString(j, ['kod', 'code', 'mahalleKodu', 'code_locality']),
      semtler: semtler,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'ad': ad,
        if (kod != null) 'kod': kod,
        if (semtler.isNotEmpty) 'semtler': semtler.map((e) => e.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mahalle &&
          slug == other.slug &&
          ad == other.ad &&
          kod == other.kod &&
          _listEq(semtler, other.semtler);

  @override
  int get hashCode => Object.hash(slug, ad, kod, Object.hashAll(semtler));
}

class Ilce {
  final String slug;
  final String ad;
  final String? kod; // TR legacy ilçe kodu
  final List<Mahalle> mahalleler;

  const Ilce({
    required this.slug,
    required this.ad,
    this.kod,
    required this.mahalleler,
  });

  factory Ilce.fromJson(Map<String, dynamic> j, {String? locale}) {
    final dilAd = DilAd.fromJson(j);
    final ad = (dilAd.base.isNotEmpty ? dilAd.forLocale(locale) : '') //
        .ifEmpty(_readString(j, ['ad', 'adi', 'name', 'label']) ?? '');

    final rawMahalle =
        _readList(j, ['mahalle', 'mahalleler', 'koyler', 'neighborhoods', 'items']);
    final mahalleler = (rawMahalle ?? [])
        .whereType<Map<String, dynamic>>()
        .map((m) => Mahalle.fromJson(m, locale: locale))
        .toList(growable: false);

    return Ilce(
      slug: _readString(j, ['slug', 'id', 'key']) ??
          slugify(ad.isNotEmpty ? ad : 'ilce'),
      ad: ad,
      kod: _readString(j, ['kod', 'code', 'ilceKodu', 'code_admin2']),
      mahalleler: mahalleler,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'ad': ad,
        if (kod != null) 'kod': kod,
        'mahalleler': mahalleler.map((e) => e.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ilce &&
          slug == other.slug &&
          ad == other.ad &&
          kod == other.kod &&
          _listEq(mahalleler, other.mahalleler);

  @override
  int get hashCode => Object.hash(slug, ad, kod, Object.hashAll(mahalleler));
}

class Il {
  final String slug;
  final String ad;
  final String? kod; // TR legacy il kodu (örn: "34")
  final List<Ilce> ilceler;

  const Il({
    required this.slug,
    required this.ad,
    this.kod,
    required this.ilceler,
  });

  factory Il.fromJson(Map<String, dynamic> j, {String? locale}) {
    final dilAd = DilAd.fromJson(j);
    final ad = (dilAd.base.isNotEmpty ? dilAd.forLocale(locale) : '') //
        .ifEmpty(_readString(j, ['ad', 'adi', 'name', 'label']) ?? '');

    final rawIlce = _readList(j, ['ilce', 'ilceler', 'districts', 'items']);
    final ilceler = (rawIlce ?? [])
        .whereType<Map<String, dynamic>>()
        .map((d) => Ilce.fromJson(d, locale: locale))
        .toList(growable: false);

    return Il(
      slug: _readString(j, ['slug', 'id', 'key']) ??
          slugify(ad.isNotEmpty ? ad : 'il'),
      ad: ad,
      kod: _readString(j, ['kod', 'code', 'ilKodu', 'code_admin1']),
      ilceler: ilceler,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'ad': ad,
        if (kod != null) 'kod': kod,
        'ilceler': ilceler.map((e) => e.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Il &&
          slug == other.slug &&
          ad == other.ad &&
          kod == other.kod &&
          _listEq(ilceler, other.ilceler);

  @override
  int get hashCode => Object.hash(slug, ad, kod, Object.hashAll(ilceler));
}

class Ulke {
  final String iso2; // TR, US, DE...
  final String? iso3; // TUR, USA...
  final String slug;
  final String ad;
  final List<Il> iller;

  const Ulke({
    required this.iso2,
    this.iso3,
    required this.slug,
    required this.ad,
    required this.iller,
  });

  factory Ulke.fromJson(Map<String, dynamic> j, {String? locale}) {
    final dilAd = DilAd.fromJson(j);
    final ad = (dilAd.base.isNotEmpty ? dilAd.forLocale(locale) : '') //
        .ifEmpty(_readString(j, ['ad', 'adi', 'name', 'label']) ?? '');
    final rawIl = _readList(j, ['iller', 'items', 'admin1', 'states', 'provinces']);
    final iller = (rawIl ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Il.fromJson(e, locale: locale))
        .toList(growable: false);
    return Ulke(
      iso2: _readString(j, ['iso2', 'iso', 'country_code', 'cc']) ?? '',
      iso3: _readString(j, ['iso3', 'country_code3']),
      slug: _readString(j, ['slug', 'id', 'key']) ??
          slugify(ad.isNotEmpty ? ad : 'ulke'),
      ad: ad,
      iller: iller,
    );
  }

  Map<String, dynamic> toJson() => {
        'iso2': iso2,
        if (iso3 != null) 'iso3': iso3,
        'slug': slug,
        'ad': ad,
        'iller': iller.map((e) => e.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ulke &&
          iso2 == other.iso2 &&
          iso3 == other.iso3 &&
          slug == other.slug &&
          ad == other.ad &&
          _listEq(iller, other.iller);

  @override
  int get hashCode => Object.hash(iso2, iso3, slug, ad, Object.hashAll(iller));
}

/// Firestore kaydı için konum kökü (legacy alanlar korunur).
class YerKoku {
  final String ilSlug;
  final String ilKod;
  final String? ilceSlug;
  final String? ilceKod;
  final String? mahalleSlug;
  final String? mahalleKod;
  final String? semtSlug; // yeni: sublocality
  final String? semtKod;

  const YerKoku({
    required this.ilSlug,
    required this.ilKod,
    this.ilceSlug,
    this.ilceKod,
    this.mahalleSlug,
    this.mahalleKod,
    this.semtSlug,
    this.semtKod,
  });

  Map<String, dynamic> toMap() => {
        'ilSlug': ilSlug,
        'ilKod': ilKod,
        'ilceSlug': ilceSlug,
        'ilceKod': ilceKod,
        'mahalleSlug': mahalleSlug,
        'mahalleKod': mahalleKod,
        'semtSlug': semtSlug,
        'semtKod': semtKod,
      };
}

/// UI ve servis entegrasyonu için seçimi taşıyan model.
class YerSecim {
  final Ulke? ulke;
  final Il? il;
  final Ilce? ilce;
  final Mahalle? mahalle;
  final Semt? semt;

  const YerSecim({
    this.ulke,
    this.il,
    this.ilce,
    this.mahalle,
    this.semt,
  });

  bool get tamamMi => il != null && ilce != null && mahalle != null;

  YerKoku? toYerKokuLegacy() {
    if (il == null) return null;
    return YerKoku(
      ilSlug: il!.slug,
      ilKod: il!.kod ?? '',
      ilceSlug: ilce?.slug,
      ilceKod: ilce?.kod,
      mahalleSlug: mahalle?.slug,
      mahalleKod: mahalle?.kod,
      semtSlug: semt?.slug,
      semtKod: semt?.kod,
    );
  }

  Map<String, dynamic> toMapFull() => {
        if (ulke != null) 'ulke': ulke!.toJson(),
        if (il != null) 'il': il!.toJson(),
        if (ilce != null) 'ilce': ilce!.toJson(),
        if (mahalle != null) 'mahalle': mahalle!.toJson(),
        if (semt != null) 'semt': semt!.toJson(),
        'legacy': toYerKokuLegacy()?.toMap(),
      };

  YerSecim copyWith({
    Ulke? ulke,
    Il? il,
    Ilce? ilce,
    Mahalle? mahalle,
    Semt? semt,
  }) {
    return YerSecim(
      ulke: ulke ?? this.ulke,
      il: il ?? this.il,
      ilce: ilce ?? this.ilce,
      mahalle: mahalle ?? this.mahalle,
      semt: semt ?? this.semt,
    );
  }
}

/// -------------------- İç Yardımcılar --------------------

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}


