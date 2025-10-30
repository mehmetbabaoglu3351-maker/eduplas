# M2 — Konum A1

## Veri Sözlüğü (Özet)
- `Country -> Admin1 -> Admin2 -> Locality -> Sublocality` (genel model)
- TR için: İl -> İlçe -> Mahalle uyarlanır (geçici; hedef küresel hiyerarşi)

## Servisler
- `KonumServisi`: cihaz konumu (Geolocator), izin yönetimi
- `YerVeriServisi`: yer json tohumu, lazy load, cache
- `YerModel`: normalize adlar + slug üretimi

## Kurallar
- UI, **konum varsa** adres seçim alanlarını **gizleyebilir** (A/B yapılandırma).
- Slug: ASCII, küçük harf, `-` ayraç.
