// ignore_for_file: public_member_api_docs
import 'dart:math';
import 'onay_modeller.dart';

/// Uygulama içi (process içi) tekil depo.
/// Prod'da yerine Firestore/Functions gelir; arayüz değişmeden kalır.
class OnayMockDepo {
  OnayMockDepo._();
  static final OnayMockDepo _i = OnayMockDepo._();
  factory OnayMockDepo() => _i;

  final _rand = Random();

  // In-memory tablolar
  final List<OnayIstek> _istekler = <OnayIstek>[];
  final List<Bildirim> _bildirimler = <Bildirim>[];

  // Basit “kullanıcı” ve “rol” görünümü
  // Not: Sprint-1'de roller DB'ye yazılmıyor; UI kontrol amaçlı burada tutulur.
  final Map<String, String> _roller = <String, String>{}; // uid -> role
  final Map<String, String> _adSoyad = <String, String>{}; // uid -> görünen ad

  // Kayıt/okuma yardımcıları
  void seedKullanici({
    required String uid,
    required String role,
    required String adSoyad,
  }) {
    _roller[uid] = role;
    _adSoyad[uid] = adSoyad;
  }

  String? rol(String uid) => _roller[uid];
  String ad(String uid) => _adSoyad[uid] ?? uid;

  List<String> uygunOnayciRolleri(String requestedRole) {
    switch (requestedRole) {
      case 'ogrenci':
        return ['ogretmen', 'koordinator', 'ilce_admin', 'il_admin', 'bas_admin'];
      case 'ogretmen':
        return ['koordinator', 'ilce_admin', 'il_admin', 'bas_admin'];
      case 'koordinator':
        return ['ilce_admin', 'il_admin', 'bas_admin'];
      case 'ilce_admin':
        return ['il_admin', 'bas_admin'];
      case 'il_admin':
        return ['bas_admin'];
      default:
        return <String>[];
    }
  }

  // Onaycı adayları (rol eşleşmesine göre, konum filtresi Sprint-1'de opsiyonel tutuluyor)
  List<String> adayOnaycilar(String requestedRole) {
    final hedefRoller = uygunOnayciRolleri(requestedRole);
    return _roller.entries
        .where((e) => hedefRoller.contains(e.value))
        .map((e) => e.key)
        .toList();
  }

  // İstek oluştur
  OnayIstek olusturIstek({
    required String requesterUid,
    required String requestedRole,
    required String approverUid,
    String? reason,
  }) {
    if (requesterUid == approverUid) {
      throw StateError('Kendi kendine onay yapılamaz.');
    }
    final approverRole = _roller[approverUid];
    final izinli = uygunOnayciRolleri(requestedRole).contains(approverRole);
    if (!izinli) {
      throw StateError('Seçilen onaylayıcı bu rol için yetkili değil.');
    }

    final now = DateTime.now();
    final istek = OnayIstek(
      id: _id(),
      requesterUid: requesterUid,
      requestedRole: requestedRole,
      approverUid: approverUid,
      createdAt: now,
      status: 'pending',
      reason: reason,
    );
    _istekler.add(istek);

    // Onaycıya bildirim
    _bildirimler.add(
      Bildirim(
        id: _id(),
        userUid: approverUid,
        title: 'Onay Talebi',
        message:
            '${ad(requesterUid)} ${requestedRole.toUpperCase()} talebi gönderdi. İncele.',
        createdAt: now,
      ),
    );
    return istek;
  }

  // Onaycının bekleyenleri
  List<OnayIstek> bekleyenler(String approverUid) =>
      _istekler.where((i) => i.approverUid == approverUid && i.status == 'pending').toList();

  // Karar
  void kararVer({
    required String approverUid,
    required String requestId,
    required String status, // "approved" | "rejected"
    String? reason,
  }) {
    final i = _istekler.indexWhere((e) => e.id == requestId);
    if (i < 0) throw StateError('İstek bulunamadı');
    final istek = _istekler[i];
    if (istek.approverUid != approverUid) {
      throw StateError('Bu isteği yalnızca ilgili onaylayıcı sonuçlandırabilir.');
    }
    if (istek.status != 'pending') return;

    istek.status = status;
    istek.reason = reason;

    // Başvuran kişiye bilgi notu
    _bildirimler.add(
      Bildirim(
        id: _id(),
        userUid: istek.requesterUid,
        title: status == 'approved' ? 'Onaylandı' : 'Reddedildi',
        message: status == 'approved'
            ? 'Talebin onaylandı. Rolün: ${istek.requestedRole}.'
            : 'Talebin reddedildi. ${reason ?? ''}',
        createdAt: DateTime.now(),
      ),
    );
  }

  List<Bildirim> bildirimKutusu(String uid) =>
      _bildirimler.where((b) => b.userUid == uid).toList();

  String _id() => (_rand.nextInt(1 << 31)).toRadixString(16) + DateTime.now().millisecondsSinceEpoch.toString();
}


