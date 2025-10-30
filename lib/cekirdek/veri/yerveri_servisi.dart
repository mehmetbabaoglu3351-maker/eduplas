// lib/cekirdek/veri/yerveri_servisi.dart
// Drop-in sürüm: Mevcut imzaları KIRMAZ.

import 'dart:convert';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'yer_model.dart';

class YerVeriServisi {
  static const String _assetPath = 'assets/veri/yerler/tr.json';

  bool _hazir = false;
  final List<Il> _iller = <Il>[];

  final Map<String, Il> _ilBySlug = <String, Il>{};
  final Map<String, Ilce> _ilceByKey = <String, Ilce>{}; // "ilSlug/ilceSlug"
  final Map<String, Mahalle> _mahalleByKey = <String, Mahalle>{}; // "ilSlug/ilceSlug/mahSlug"

  bool get hazir => _hazir;

  Future<void> hazirla({String? locale}) async {
    if (_hazir) {
      // zaten yüklüyse tekrar parse etmeyelim
      if (kDebugMode) debugPrint('[YerVeriServisi] hazirla(): zaten hazir, atlandi.');
      return;
    }

    _reset();
    try {
      final raw = await rootBundle.loadString(_assetPath);
      if (raw.trim().isEmpty) {
        if (kDebugMode) debugPrint('[YerVeriServisi] hazirla(): dosya BOS -> $_assetPath');
        return;
      }

      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic> || decoded['iller'] is! List) {
        if (kDebugMode) {
          debugPrint('[YerVeriServisi] hazirla(): "iller" listesi yok/yanlis tip -> $_assetPath');
        }
        return;
      }

      for (final e in (decoded['iller'] as List)) {
        if (e is Map<String, dynamic>) {
          final il = Il.fromJson(e);
          _iller.add(il);
        }
      }

      // indexler
      for (final il in _iller) {
        _ilBySlug[il.slug] = il;
        for (final ilce in il.ilceler) {
          _ilceByKey['${il.slug}/${ilce.slug}'] = ilce;
          for (final mah in ilce.mahalleler) {
            _mahalleByKey['${il.slug}/${ilce.slug}/${mah.slug}'] = mah;
          }
        }
      }

      _hazir = _iller.isNotEmpty;
      if (kDebugMode) {
        debugPrint('[YerVeriServisi] hazirla(): ${_iller.length} il yüklendi ($_assetPath)');
      }
    } catch (e) {
      _reset();
      if (kDebugMode) debugPrint('[YerVeriServisi] hazirla(): HATA -> $e');
    }
  }

  UnmodifiableListView<Il> get iller => UnmodifiableListView<Il>(_iller);
  List<Il> illeri({String? locale}) => _iller;

  List<Ilce> ilceleri(String ilSlug, {String? locale}) {
    final il = _byIlSlugOrName(ilSlug);
    return il?.ilceler ?? const <Ilce>[];
  }

  List<Mahalle> mahalleleri(String ilSlug, String ilceSlug, {String? locale}) {
    final il = _byIlSlugOrName(ilSlug);
    if (il == null) return const <Mahalle>[];
    final ilce = _byIlceSlugOrName(il, ilceSlug);
    return ilce?.mahalleler ?? const <Mahalle>[];
  }

  List<Il> araIl(String q, {int limit = 50}) {
    final s = _norm(q);
    if (s.isEmpty) return const <Il>[];
    final out = <Il>[];
    for (final il in _iller) {
      if (('${_norm(il.ad)} ${il.slug}').contains(s)) {
        out.add(il);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  List<Ilce> araIlce(String q, {int limit = 100}) {
    final s = _norm(q);
    if (s.isEmpty) return const <Ilce>[];
    final out = <Ilce>[];
    for (final il in _iller) {
      for (final ilce in il.ilceler) {
        if (('${_norm(ilce.ad)} ${ilce.slug} ${il.slug}').contains(s)) {
          out.add(ilce);
          if (out.length >= limit) return out;
        }
      }
    }
    return out;
  }

  List<Mahalle> araMahalle(String q, {int limit = 150}) {
    final s = _norm(q);
    if (s.isEmpty) return const <Mahalle>[];

    // Hızlı yol: index üzerinden lineer filtre (genelde daha hızlı)
    final out = <Mahalle>[];
    for (final entry in _mahalleByKey.entries) {
      final parts = entry.key.split('/');
      // parts: [ilSlug, ilceSlug, mahSlug]
      final mah = entry.value;
      if (('${_norm(mah.ad)} ${mah.slug} ${parts[1]} ${parts[0]}').contains(s)) {
        out.add(mah);
        if (out.length >= limit) return out;
      }
    }
    return out;
  }

  void _reset() {
    _hazir = false;
    _iller.clear();
    _ilBySlug.clear();
    _ilceByKey.clear();
    _mahalleByKey.clear();
  }

  Il? _byIlSlugOrName(String any) {
    // önce doğrudan slug ile
    final direct = _ilBySlug[any];
    if (direct != null) return direct;

    // sonra normalize isim/slug karşılaştır
    final s = _norm(any);
    for (final il in _iller) {
      if (_norm(il.ad) == s || _norm(il.slug) == s) return il;
    }
    return null;
  }

  Ilce? _byIlceSlugOrName(Il il, String any) {
    // önce doğrudan slug ile
    final direct = _ilceByKey['${il.slug}/$any'];
    if (direct != null) return direct;

    // sonra normalize isim/slug karşılaştır
    final s = _norm(any);
    for (final ilce in il.ilceler) {
      if (_norm(ilce.ad) == s || _norm(ilce.slug) == s) return ilce;
    }
    return null;
  }

  String _norm(String input) {
    var x = input.trim().toLowerCase();
    // birleşik noktalı i varyantlarını da tek tipe indir
    x = x
        .replaceAll('i̇', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    x = x.replaceAll(RegExp(r'\s+'), ' ');
    return x;
  }
}


