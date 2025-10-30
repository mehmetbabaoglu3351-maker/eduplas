// lib/cekirdek/konum/konum_servisi.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Basit konum tespiti DTO'su.
class LocationFix {
  final double lat;
  final double lng;
  final double? accuracyM;
  final String source;
  final DateTime at;

  LocationFix({
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.source = 'device',
    DateTime? at,
  }) : at = at ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'accuracyM': accuracyM,
        'source': source,
        'at': at.toIso8601String(),
      };
}

/// Konum servisi (singleton)
class KonumServisi {
  KonumServisi._internal();
  static final KonumServisi instance = KonumServisi._internal();

  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    distanceFilter: 0,
  );

  Future<void> _izinleriVeServisiDogrula() async {
    final servisAcik = await Geolocator.isLocationServiceEnabled();
    if (!servisAcik) {
      throw const LocationServiceDisabledException();
    }

    LocationPermission izin = await Geolocator.checkPermission();

    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
      if (izin == LocationPermission.denied) {
        throw const PermissionDeniedException('Konum izni reddedildi.');
      }
    }

    if (izin == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Konum izni kalıcı olarak reddedildi. Ayarlardan açmanız gerekir.',
      );
    }
  }

  Future<LocationFix> getCurrentFix() async {
    await _izinleriVeServisiDogrula();

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      ).timeout(const Duration(seconds: 15));

      return LocationFix(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracyM: pos.accuracy,
        source: 'device',
      );
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LocationFix(
          lat: last.latitude,
          lng: last.longitude,
          accuracyM: last.accuracy,
          source: 'lastKnown',
        );
      }
      rethrow;
    } on PermissionDefinitionsNotFoundException {
      rethrow;
    } on PermissionDeniedException {
      rethrow;
    } on LocationServiceDisabledException {
      rethrow;
    } catch (e) {
      throw StateError('Konum alınamadı: $e');
    }
  }

  Stream<LocationFix> watchPosition({
    LocationSettings settings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    ),
  }) async* {
    await _izinleriVeServisiDogrula();
    yield* Geolocator.getPositionStream(locationSettings: settings).map(
      (pos) => LocationFix(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracyM: pos.accuracy,
        source: 'device',
      ),
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}


