// lib/cekirdek/kimlik/device_hash.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Gizli pepper uygulamada tutulmaz.
/// Sunucudan oturumda/header ile gelir veya ortam konfigürasyonundan alınır.
typedef PepperProvider = Future<String> Function();

/// UI katmanına bağımlı alanları dışarıdan alabilmek için sağlayıcılar
typedef SimpleStringProvider = Future<String> Function();

class DeviceHash {
  final PepperProvider pepperProvider;
  final String env; // "prod" | "staging" | "dev"
  final String version; // "v1"

  // Opsiyonel zayıf sinyal sağlayıcıları (UI bağımlılığını kesmek için)
  final SimpleStringProvider? screenBucketProvider; // ör. "1080p"
  final SimpleStringProvider? localeBundleProvider; // ör. "tr-TR"
  final SimpleStringProvider? timezoneKeyProvider;  // ör. "Europe/Istanbul"

  DeviceHash({
    required this.pepperProvider,
    this.env = 'prod',
    this.version = 'v1',
    this.screenBucketProvider,
    this.localeBundleProvider,
    this.timezoneKeyProvider,
  });

  /// Uygulama ilk açılışta üretilip secure storage'ta saklanması gereken rastgele kimlik.
  /// Burada loader/saver dışarıdan verilir; yoksa geçici üretir.
  Future<String> obtainAppInstallId({
    Future<String> Function()? loader,
    Future<void> Function(String)? saver,
  }) async {
    if (loader != null) {
      final existing = await loader();
      if (existing.isNotEmpty) return existing;
    }
    final rnd = _randomBase32(20);
    if (saver != null) {
      await saver(rnd);
    }
    return rnd;
  }

  Future<String> compute({
    required Future<String> Function() loadAppInstallId,
    required Future<void> Function(String) saveAppInstallId,
  }) async {
    var pepper = (await pepperProvider()).trim();
    if (pepper.isEmpty) {
      // Emniyet: boş pepper gelirse düşük entropili de olsa kullanıcıyı bloklamayalım.
      pepper = 'pepper_fallback_do_not_use_in_prod';
    }

    final appInstallId = await obtainAppInstallId(
      loader: loadAppInstallId,
      saver: saveAppInstallId,
    );

    final payload = await _buildCanonicalPayload(appInstallId);
    final raw = _hmacSha256(pepper, payload);
    final base32 = _base32NoPad(raw);

    final hash = base32.substring(0, 52); // ~260 bit gösterim
    return '$env.$version.$hash';
  }

  /// MINIMAL SÜRÜM: Harici paket yok. Platform/device bilgisi toplanmıyor.
  /// Bu alanları daha sonra "Full" sürümde dolduracağız.
  Future<String> _buildCanonicalPayload(String appInstallId) async {
    final screenBucket = screenBucketProvider != null
        ? await screenBucketProvider!().catchError((_) => '')
        : '';
    final localeBundle = localeBundleProvider != null
        ? await localeBundleProvider!().catchError((_) => '')
        : '';
    final timezoneKey = timezoneKeyProvider != null
        ? await timezoneKeyProvider!().catchError((_) => '')
        : '';

    final map = <String, String>{
      'appInstallId': appInstallId,
      'platform': 'unknown',      // Full sürümde doldurulacak
      'osMajorMinor': '',         // Full sürümde doldurulacak
      'deviceClass': 'phone',     // Full sürümde heuristik ile
      'localeBundle': localeBundle,
      'timezoneKey': timezoneKey,
      'screenBucket': screenBucket,
      'vendorBucket': '',         // Full sürümde doldurulacak
      'appVersionMajor': '1',     // Full sürümde doldurulacak
      'secureHardwareHint': '',   // Full sürümde doldurulacak
    };

    final keys = map.keys.toList()..sort();
    final canonical = <String, String>{
      for (final k in keys) k: map[k] ?? '',
    };

    return jsonEncode(canonical);
  }

  Uint8List _hmacSha256(String key, String data) {
    final h = Hmac(sha256, utf8.encode(key));
    final digest = h.convert(utf8.encode(data));
    return Uint8List.fromList(digest.bytes);
  }

  /// RFC4648 tabanlı, padding'siz Base32.
  String _base32NoPad(Uint8List bytes) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final out = StringBuffer();
    var current = 0;
    var bits = 0;

    for (final b in bytes) {
      current = (current << 8) | (b & 0xff);
      bits += 8;
      while (bits >= 5) {
        final idx = (current >> (bits - 5)) & 31;
        bits -= 5;
        out.write(alphabet[idx]);
      }
    }
    if (bits > 0) {
      final idx = (current << (5 - bits)) & 31;
      out.write(alphabet[idx]);
    }
    return out.toString();
  }

  String _randomBase32(int len) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rnd = Random.secure();
    final sb = StringBuffer();
    for (var i = 0; i < len; i++) {
      sb.write(alphabet[rnd.nextInt(alphabet.length)]);
    }
    return sb.toString();
  }
}


