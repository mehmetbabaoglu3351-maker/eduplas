# M1 — Bootstrap & Claims

## M1-01: Başlangıç ve Akış
- Uygulama açılışı -> Geçit -> Giriş -> OTP -> Sözleşme -> Kullanıcı ana
- Loglama: ekran geçişleri ve aksiyonlar

## M1-02: deviceHash
- Kaynaklar: `device_info_plus`, `package_info_plus`
- Hash girdileri: cihaz modeli, sürüm, app id, kullanıcıya ait **olmayan** sabitler
- Çıktı: `sha256(baseString)`, salt/pepper ile güçlendirilir
- Depolama: local + claim

## M1-03: Başlangıç claim seti
- `deviceHash`, `locale`, `tz`, `appVersion`
- Yönlendirme: Baş Admin -> admin panel; diğerleri -> kayıt sihirbazı

## M1-04: Env & Audit
- `.env` / `--dart-define` ile hassas bayraklar
- `audit/` koleksiyonlarında minimal PII, çok-amaçlı log yok

## M1-05: Tablo — bootstrap_claims
| Alan              | Tip      | Açıklama                         |
|-------------------|----------|----------------------------------|
| deviceHash        | string   | Cihaz parmak izi                 |
| appVersion        | string   | App sürümü                       |
| locale            | string   | tr_TR/en_US                      |
| tz                | string   | Europe/Istanbul                  |
| at                | datetime | ISO 8601                         |
