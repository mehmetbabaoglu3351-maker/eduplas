# EDUPLAS PLAYBOOK

## Amaç
Bu belge, geliştirme süreçlerimizi standartlaştırır ve kaliteyi sürdürülebilir kılar.

## Çalışma Disiplini
- **Tam dosya** kuralı: Güncelleme -> dosyanın TAM sürümü teslim edilir.
- **Dosya yapıştır yöntemi:** Geliştirici mevcut dosyayı olduğu gibi yapıştırır; gözden geçirilen tam dosya geri verilir.
- **Uyarı yok**: IDE'de **mavi dalga/uyarı** kalmamalı; `dart analyze` sıfır uyarı.
- Türkçe ASCII dosya/klasör isimleri, anlamlı ve kısa adlar.
- Branch disiplini: `main` korumalı, feature branch + PR.
- ADR zorunlu: Mimarî değişikliklerde ADR yaz.

## CI / Kalite Kontrolleri
- `flutter pub get`
- `dart format --fix .`
- `dart analyze`
- `flutter test` (varsa)
- Gerektiğinde: `flutter pub outdated` rapor takibi

## Dizin Anlaşması
- `lib/ozellikler/...` rol/tür odaklı segmentler
- `lib/cekirdek/...` çekirdek servisler (konum, veri, kimlik, arayüz ortak)
- Varlık isimleri: `PascalCase` sınıf, `lower_snake_case` dosya

## Sürümleme
- SemVer + Milestone etiketi (M1..M10). Dokümanlar `Sürüm Notları` sürer.
