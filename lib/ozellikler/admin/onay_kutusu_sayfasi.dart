// lib/ozellikler/admin/onay_kutusu_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// OnayKutusuSayfasi:
/// - status == "pending" olan kullanıcıları listeler
/// - Her kayıt için Onayla (approved) / Reddet (rejected) işlemleri sunar
/// - İşlem yapan admin bilgisini ve zaman damgasını kaydeder
///
/// Firestore şema varsayımı (users/{uid}):
/// {
///   uid: string,
///   nickname: string,
///   role: "ogrenci" | "ogretmen" | "sinif_baskani" | "koordinator" | "admin_ilce" | "admin_il" | "bas_admin" | "destekci",
///   status: "pending" | "approved" | "rejected",
///   phone: string?,   // varsa
///   createdAt: Timestamp? // kayıt zamanı
///   // Aşağıdakiler işlem sonrası eklenecek:
///   approvedAt / rejectedAt: Timestamp?,
///   approvedBy / rejectedBy: string (admin uid),
/// }
class OnayKutusuSayfasi extends StatefulWidget {
  static const String route = '/admin/onay-kutusu';

  const OnayKutusuSayfasi({super.key});

  @override
  State<OnayKutusuSayfasi> createState() => _OnayKutusuSayfasiState();
}

class _OnayKutusuSayfasiState extends State<OnayKutusuSayfasi> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _updateStatus({
    required String targetUid,
    required String newStatus,
  }) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oturum bulunamadı. Lütfen tekrar giriş yapın.')),
        );
      }
      return;
    }

    final now = FieldValue.serverTimestamp();
    final doc = _db.collection('users').doc(targetUid);

    // Hangi alanları yazacağımızı status’e göre belirleyelim
    final Map<String, dynamic> patch;
    if (newStatus == 'approved') {
      patch = {
        'status': 'approved',
        'approvedAt': now,
        'approvedBy': adminUid,
        // Önceki red bilgisi varsa temizle (opsiyonel)
        'rejectedAt': FieldValue.delete(),
        'rejectedBy': FieldValue.delete(),
      };
    } else if (newStatus == 'rejected') {
      patch = {
        'status': 'rejected',
        'rejectedAt': now,
        'rejectedBy': adminUid,
        // Önceki onay bilgisi varsa temizle (opsiyonel)
        'approvedAt': FieldValue.delete(),
        'approvedBy': FieldValue.delete(),
      };
    } else {
      throw ArgumentError('Bilinmeyen durum: $newStatus');
    }

    await doc.update(patch);
  }

  Future<void> _confirmAndApply({
    required String targetUid,
    required String nickname,
    required String action, // 'approve' | 'reject'
  }) async {
    final isApprove = action == 'approve';
    final yeniDurum = isApprove ? 'approved' : 'rejected';

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isApprove ? 'Onay verilsin mi?' : 'Red verilsin mi?'),
          content: Text(
            '"$nickname" için "${isApprove ? "approved" : "rejected"}" durumuna geçilecek.',
            textAlign: TextAlign.start,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(isApprove ? 'Onayla' : 'Reddet'),
            ),
          ],
        );
      },
    );

    if (onay != true) return;

    try {
      await _updateStatus(targetUid: targetUid, newStatus: yeniDurum);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApprove
                  ? '"$nickname" onaylandı.'
                  : '"$nickname" reddedildi.',
            ),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beklenmeyen bir hata oluştu.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingQuery = _db
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bekleyen Başvurular'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pendingQuery.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Hata: ${snap.error}'),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _BosEkran(
              baslik: 'Bekleyen başvuru yok',
              aciklama:
                  'Şu anda onay bekleyen bir kullanıcı bulunmuyor. Yeni kayıtlar geldiğinde burada görünecek.',
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final d = docs[index].data();
              final uid = docs[index].id;
              final nickname = (d['nickname'] as String?) ?? '(takma ad yok)';
              final role = (d['role'] as String?) ?? '(rol yok)';
              final phone = (d['phone'] as String?) ?? '';
              final createdAt = d['createdAt'];
              String zaman = '';
              if (createdAt is Timestamp) {
                final dt = createdAt.toDate();
                zaman =
                    '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Rol: $role'
                  '${phone.isNotEmpty ? ' • Tel: $phone' : ''}'
                  '${zaman.isNotEmpty ? ' • Kayıt: $zaman' : ''}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _confirmAndApply(
                        targetUid: uid,
                        nickname: nickname,
                        action: 'reject',
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reddet'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _confirmAndApply(
                        targetUid: uid,
                        nickname: nickname,
                        action: 'approve',
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Onayla'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BosEkran extends StatelessWidget {
  final String baslik;
  final String aciklama;

  const _BosEkran({required this.baslik, required this.aciklama});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 64),
            const SizedBox(height: 12),
            Text(
              baslik,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              aciklama,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


