# ADR-002 — deviceHash stratejisi
## Karar
Cihaz parmak izi `sha256(baseString)` ile üretilir; salt/pepper.
## Gerekçe
Gizlilik ve bütünlük için bazı alanlar karıştırılır.
## Sonuçlar
Yerel depolama + claim aktarımı.
