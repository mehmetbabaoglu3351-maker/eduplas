// lib/ozellikler/kullanici/kullanici_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:eduplas/router/route_names.dart';

class KullaniciSayfasi extends StatefulWidget {
  static const route = RouteNames.user;
  const KullaniciSayfasi({super.key});

  @override
  State<KullaniciSayfasi> createState() => _KullaniciSayfasiState();
}

class _KullaniciSayfasiState extends State<KullaniciSayfasi> {
  // ---- Mock Profil Durumu (MVP görseli için) ----
  String role = 'ogrenci'; // ogrenci | ogretmen | koordinator | il_admin | ilce_admin | destekci | bas_admin
  String fullName = 'Ad Soyad';
  String nick = 'takma.ad';
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _nickCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();

  String phone = '+905xxxxxxxxx';
  String bio = '';

  // Gamification
  int level = 7;
  int xp = 1240;
  int nextLevelXp = 1600;
  int rp = 1420; // derece puanı
  int coins = 350; // altın
  int streak = 5;

  // Sosyal
  int friendsCount = 12;
  int tasksActive = 3;
  String groupName = 'Robotik Kulübü';
  String sinif = '10/A';

  // İlgi alanları
  final Set<String> interests = {'Kodlama', 'Müzik', 'Spor'};
  final List<String> interestPool = const [
    'Kodlama',
    'Müzik',
    'Spor',
    'Robotik',
    'Matematik',
    'Fen',
    'Sanat',
    'Yabancı Dil',
  ];

  // Konum (mock)
  String country = 'TR';
  String admin1 = 'Adana';
  String admin2 = 'Seyhan';
  String locality = 'Ziyapaşa';
  String sublocality = '—';

  // Kapak/Avatar mock (renk değiştirerek “değiştir” simülasyonu)
  final List<Color> _coverColors = const [
    Color(0xFF00BFA5),
    Color(0xFF26A69A),
    Color(0xFF1DE9B6),
    Color(0xFF80DEEA),
  ];
  int _coverIndex = 0;
  final List<Color> _avatarColors = const [
    Color(0xFF009688),
    Color(0xFF4DB6AC),
    Color(0xFF26C6DA),
    Color(0xFF00838F),
  ];
  int _avatarIndex = 0;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl.text = fullName;
    _nickCtrl.text = nick;
    _bioCtrl.text = bio;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _nickCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  bool get isStudent => role == 'ogrenci';
  bool get isTeacher => role == 'ogretmen';
  bool get isCoord => role == 'koordinator';
  bool get isIlAdmin => role == 'il_admin';
  bool get isIlceAdmin => role == 'ilce_admin';
  bool get isSupporter => role == 'destekci';
  bool get isBasAdmin => role == 'bas_admin';

  String get roleLabel {
    switch (role) {
      case 'ogrenci':
        return 'Öğrenci';
      case 'ogretmen':
        return 'Öğretmen';
      case 'koordinator':
        return 'Koordinatör';
      case 'il_admin':
        return 'İl Admini';
      case 'ilce_admin':
        return 'İlçe Admini';
      case 'destekci':
        return 'Destekçi';
      case 'bas_admin':
        return 'Baş Admin';
      default:
        return 'Kullanıcı';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _savePersonal() {
    setState(() {
      fullName = _fullNameCtrl.text.trim();
      nick = _normalizeNick(_nickCtrl.text);
      _nickCtrl.text = nick;
      bio = _bioCtrl.text.trim();
    });
    _snack('Kişisel bilgiler güncellendi.');
  }

  void _saveInterests() {
    _snack('İlgi alanları güncellendi: ${interests.length} etiket');
  }

  void _saveLocation() {
    _snack('Konum güncellendi: $country > $admin1 > $admin2 > $locality');
  }

  String _normalizeNick(String input) {
    var s = input.trim().toLowerCase();
    s = s
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
    s = s.replaceAll(RegExp(r'\s+'), '.');
    s = s.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    s = s.replaceAll(RegExp(r'\.{2,}'), '.');
    s = s.replaceAll(RegExp(r'^\.'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    if (s.isEmpty) s = 'kullanici';
    if (s.length < 3) s = '${s}___'.substring(0, 3);
    return s;
  }

  void _completeTask(int xpGain, int coinGain, {int rpGain = 0}) {
    setState(() {
      xp += xpGain;
      coins += coinGain;
      rp += rpGain;
      while (xp >= nextLevelXp) {
        xp -= nextLevelXp;
        level += 1;
        // Basit artan seviye eşiği (mock)
        nextLevelXp = (nextLevelXp * 1.15).round();
        _snack('Seviye atladın! Yeni seviye: $level');
      }
    });
  }

  void _changeCover() {
    setState(() => _coverIndex = (_coverIndex + 1) % _coverColors.length);
  }

  void _changeAvatar() {
    setState(() => _avatarIndex = (_avatarIndex + 1) % _avatarColors.length);
  }

  Future<void> _pickLocationManual() async {
    // Basit bir bottom sheet ile mock seçim
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        String tmpAdmin1 = admin1;
        String tmpAdmin2 = admin2;
        String tmpLocality = locality;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Elle Konum Seç', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tmpAdmin1,
                items: const [
                  DropdownMenuItem(value: 'Adana', child: Text('Adana')),
                  DropdownMenuItem(value: 'Ankara', child: Text('Ankara')),
                  DropdownMenuItem(value: 'İstanbul', child: Text('İstanbul')),
                ],
                onChanged: (v) => tmpAdmin1 = v ?? tmpAdmin1,
                decoration: const InputDecoration(labelText: 'İl (Admin1)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: tmpAdmin2,
                items: const [
                  DropdownMenuItem(value: 'Seyhan', child: Text('Seyhan')),
                  DropdownMenuItem(value: 'Çankaya', child: Text('Çankaya')),
                  DropdownMenuItem(value: 'Kadıköy', child: Text('Kadıköy')),
                ],
                onChanged: (v) => tmpAdmin2 = v ?? tmpAdmin2,
                decoration: const InputDecoration(labelText: 'İlçe (Admin2)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: tmpLocality,
                decoration: const InputDecoration(labelText: 'Mahalle/Locality'),
                onChanged: (v) => tmpLocality = v,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      admin1 = tmpAdmin1;
                      admin2 = tmpAdmin2;
                      locality = tmpLocality.isEmpty ? locality : tmpLocality;
                    });
                    Navigator.pop(ctx);
                    _snack('Konum seçildi.');
                  },
                  child: const Text('Uygula'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (xp / nextLevelXp).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => role = v),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'ogrenci', child: Text('Rol: Öğrenci')),
              PopupMenuItem(value: 'ogretmen', child: Text('Rol: Öğretmen')),
              PopupMenuItem(value: 'koordinator', child: Text('Rol: Koordinatör')),
              PopupMenuItem(value: 'ilce_admin', child: Text('Rol: İlçe Admini')),
              PopupMenuItem(value: 'il_admin', child: Text('Rol: İl Admini')),
              PopupMenuItem(value: 'destekci', child: Text('Rol: Destekçi')),
              PopupMenuItem(value: 'bas_admin', child: Text('Rol: Baş Admin')),
            ],
            tooltip: 'Rol değiştir (mock)',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _heroHeader(theme, progress),
          const SizedBox(height: 12),
          _quickChips(),
          const SizedBox(height: 12),
          _cardKisiselBilgiler(),
          const SizedBox(height: 12),
          _cardIlgiAlanlari(),
          const SizedBox(height: 12),
          _cardKonum(),
          const SizedBox(height: 12),
          _cardGorevler(),
          const SizedBox(height: 12),
          _cardIlerlemeRozet(),
          const SizedBox(height: 12),
          _cardSosyal(),
          const SizedBox(height: 12),
          if (isStudent) _cardOgrenciOzel(),
          if (isTeacher || isCoord) _cardOgretmenKoordinatorOzel(),
          if (isIlAdmin || isIlceAdmin || isBasAdmin) _cardAdminOzel(),
          if (isSupporter) _cardDestekciOzel(),
        ],
      ),
    );
  }

  // ---------- Bölüm: Hero ----------
  Widget _heroHeader(ThemeData theme, double progress) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Kapak
          Container(
            height: 120,
            color: _coverColors[_coverIndex],
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: 'Kapağı değiştir (mock)',
              onPressed: _changeCover,
              icon: const Icon(Icons.image_outlined, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Avatar ve isim
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: _avatarColors[_avatarIndex],
                            child: Text(
                              _initials(fullName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: IconButton.filledTonal(
                              onPressed: _changeAvatar,
                              icon: const Icon(Icons.camera_alt_outlined, size: 18),
                              tooltip: 'Avatarı değiştir (mock)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text('@$nick', style: theme.textTheme.bodySmall),
                                  const SizedBox(width: 8),
                                  _roleChip(roleLabel),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // XP Bar + istatistikler
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          LinearProgressIndicator(value: progress, minHeight: 8),
                          const SizedBox(height: 6),
                          Text('Seviye $level  —  $xp / $nextLevelXp XP',
                              style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _stat('RP', '$rp', icon: Icons.star_rate_rounded),
                    _stat('Altın', '$coins', icon: Icons.monetization_on_outlined),
                    _stat('Seri', '$streak🔥', icon: Icons.local_fire_department_outlined),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String label) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.verified_user, size: 18),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _stat(String title, String value, {IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 18),
        if (icon != null) const SizedBox(width: 6),
        Text('$title: $value'),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first.characters.first : 'A';
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  // ---------- Bölüm: Hızlı Durum Çipleri ----------
  Widget _quickChips() {
    final chips = <Widget>[
      _quickChip(Icons.group_outlined, 'Arkadaşlar', '$friendsCount'),
      _quickChip(Icons.checklist_outlined, 'Görevler', '$tasksActive aktif'),
      _quickChip(Icons.class_outlined, 'Sınıfım', sinif),
      _quickChip(Icons.groups_2_outlined, 'Grubum', groupName),
      if (isSupporter) _quickChip(Icons.volunteer_activism_outlined, 'Destekçi', 'Evet'),
      if (isTeacher) _quickChip(Icons.menu_book_outlined, 'Rol', 'Öğretmen'),
    ];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      ),
    );
  }

  Widget _quickChip(IconData icon, String label, String value) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }

  // ---------- Kart: Kişisel ----------
  Widget _cardKisiselBilgiler() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardTitle(icon: Icons.person_outline, title: 'Kişisel Bilgiler'),
            const SizedBox(height: 12),
            TextField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nickCtrl,
              decoration: const InputDecoration(prefixText: '@', labelText: 'Takma ad'),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Telefon',
                hintText: phone,
                suffixIcon: IconButton(
                  onPressed: () => _snack('Telefon değiştirme akışı MVP dışında'),
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Değiştirme akışı daha sonra',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioCtrl,
              decoration: const InputDecoration(labelText: 'Bio (opsiyonel)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _savePersonal,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Kart: İlgi ----------
  Widget _cardIlgiAlanlari() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardTitle(icon: Icons.interests_outlined, title: 'İlgi Alanları'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in interestPool)
                  FilterChip(
                    label: Text(tag),
                    selected: interests.contains(tag),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          interests.add(tag);
                        } else {
                          interests.remove(tag);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saveInterests,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Kart: Konum ----------
  Widget _cardKonum() {
    final locationText = '$country > $admin1 > $admin2 > $locality';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardTitle(icon: Icons.place_outlined, title: 'Konum'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Şu an: $locationText')),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Mock: cihazdan konum yerine hazır değer
                    setState(() {
                      country = 'TR';
                      admin1 = 'İstanbul';
                      admin2 = 'Kadıköy';
                      locality = 'Moda';
                      sublocality = '—';
                    });
                    _snack('Cihaz konumu (mock) alındı.');
                  },
                  icon: const Icon(Icons.my_location_outlined),
                  label: const Text('Konum Al'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickLocationManual,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Elle Seç'),
                ),
                FilledButton.icon(
                  onPressed: _saveLocation,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Kart: Görevler ----------
  Widget _cardGorevler() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardTitle(icon: Icons.check_circle_outlined, title: 'Görevlerim'),
            const SizedBox(height: 8),
            _taskTile(
              title: 'Bugün uygulamaya gir',
              reward: '+10 XP  +5 Altın',
              onTap: () => _completeTask(10, 5),
            ),
            const Divider(height: 16),
            _taskTile(
              title: '1 içerik oku',
              reward: '+15 XP',
              onTap: () => _completeTask(15, 0),
              cta: 'Devam Et',
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskTile({
    required String title,
    required String reward,
    required VoidCallback onTap,
    String cta = 'Tamamla',
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text('Ödül: $reward'),
      trailing: FilledButton(onPressed: onTap, child: Text(cta)),
    );
  }

  // ---------- Kart: İlerleme & Rozet ----------
  Widget _cardIlerlemeRozet() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardTitle(icon: Icons.emoji_events_outlined, title: 'İlerleme & Rozetler'),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(icon: Icons.military_tech_outlined, label: 'İlk Giriş'),
                _Badge(icon: Icons.shield_outlined, label: 'Hafta Serisi 3'),
                _Badge(icon: Icons.center_focus_strong_outlined, label: 'Hedef Ustası'),
                _Badge(icon: Icons.local_fire_department_outlined, label: 'Ateşli'),
                _Badge(icon: Icons.lock_outline, label: 'Kilitli'),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text('Lig: Bronz')),
                SizedBox(width: 8),
                Chip(label: Text('Sonraki: Gümüş')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Kart: Sosyal ----------
  Widget _cardSosyal() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardTitle(icon: Icons.people_alt_outlined, title: 'Sosyal'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(6, (i) {
                return const CircleAvatar(radius: 18, child: Text('A'));
              }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _snack('Arkadaş ekle (mock)'),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Arkadaş Ekle'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _snack('Davet gönder (mock)'),
                  icon: const Icon(Icons.qr_code_2_outlined),
                  label: const Text('Davet Gönder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Rol'e Özel Kartlar ----------
  Widget _cardOgrenciOzel() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const ListTile(
        leading: Icon(Icons.menu_book_outlined),
        title: Text('Ödevlerim & Katıldığım Sınıflar'),
        subtitle: Text('Ödevlerin ve sınıf listesi burada görünecek.'),
      ),
    );
  }

  Widget _cardOgretmenKoordinatorOzel() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const ListTile(
        leading: Icon(Icons.school_outlined),
        title: Text('Sınıflarım & Ders Yönetimi'),
        subtitle: Text('Sınıf listeleri, ders planı ve görev atama kısayolları.'),
      ),
    );
  }

  Widget _cardAdminOzel() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const ListTile(
        leading: Icon(Icons.admin_panel_settings_outlined),
        title: Text('Onay Kuyruğu & Bölge Panosu'),
        subtitle: Text('Bölgeye göre bekleyen başvurular ve özet metrikler.'),
      ),
    );
  }

  Widget _cardDestekciOzel() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const ListTile(
        leading: Icon(Icons.volunteer_activism_outlined),
        title: Text('Katkılarım'),
        subtitle: Text('Bağışlar, etkinlik katılımları ve rozetler.'),
      ),
    );
  }
}

// ---------- Küçük Bileşenler ----------
class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}


