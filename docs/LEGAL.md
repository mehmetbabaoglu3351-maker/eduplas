# Hukuk / Uyum — Sürüm Etiketleri ve İzlek

## Sürüm Etiketleri (örnek alan adları)
- `_vSozlesme` — Sözleşme metni sürümü (örn. `1.0.0`)
- `_vRiza` — Açık rıza metni sürümü
- `_vAyd` — Aydınlatma metni sürümü
- `_vGiz` — Gizlilik metni sürümü

## UX ilkeleri
- Kullanıcı, metnin sonuna kadar scroll yapmadan kabul butonları aktif olmaz.
- Kabul zaman damgası, `deviceHash`, `locale`, `ip (varsa)` audit alanlarına yazılır.

## Audit Örnekleri
- `audit/bootstrap_claims`: bootstrap aşamasında üretilen claimler
- `audit/legal_accepts`: kullanıcı hukuk onay kayıtları (sürüm + zaman)
