// tools/ureticiler/yerler_olustur.js
// Gereksinim: Node 18+
// Çalıştırma: node tools/ureticiler/yerler_olustur.js

import fs from 'node:fs';
import path from 'node:path';
import https from 'node:https';

const OUT_DIR = path.resolve('assets/veri/yerler');
const IL_DIR = path.join(OUT_DIR, 'il');
fs.mkdirSync(IL_DIR, { recursive: true });

// Kaynak: muratgozel/turkey-neighbourhoods (MIT)
// JSON formatı: cities -> districts -> neighborhoods (+post code)
// RAW URL (stabil dal): https://raw.githubusercontent.com/muratgozel/turkey-neighbourhoods/master/dist/neighbourhoods.json
const SRC_URL = 'https://raw.githubusercontent.com/muratgozel/turkey-neighbourhoods/master/dist/neighbourhoods.json';

function slugTR(s) {
  return s
    .toLowerCase()
    .replaceAll('ç', 'c').replaceAll('ğ', 'g').replaceAll('ı', 'i')
    .replaceAll('ö', 'o').replaceAll('ş', 's').replaceAll('ü', 'u')
    .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

function downloadJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode !== 200) return reject(new Error(`HTTP ${res.statusCode}`));
      let data = '';
      res.setEncoding('utf8');
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

function writeJSON(fp, obj) {
  fs.writeFileSync(fp, JSON.stringify(obj, null, 2), 'utf8');
}

console.log('İndiriliyor:', SRC_URL);
const data = await downloadJson(SRC_URL);

// Beklenen kaba yapı (örnekle):
// [{ city:"Adana", plate:"01", districts:[{ name:"Seyhan", neighbourhoods:[{name:"...", postCode:"..."}] }]}]

const iller = [];
for (const city of data) {
  const ilAd = city.city?.trim();
  if (!ilAd) continue;
  const ilSlug = slugTR(ilAd);
  const ilKod = city.plate?.toString().padStart(2, '0') ?? ilSlug;

  // İlçeleri derle
  const ilceler = [];
  for (const d of city.districts ?? []) {
    const ilceAd = d.name?.trim();
    if (!ilceAd) continue;
    const ilceSlug = slugTR(ilceAd);
    const ilceKod = ilSlug + '-' + ilceSlug;

    const mahalleler = [];
    for (const n of d.neighbourhoods ?? []) {
      const mAd = (n.name ?? '').trim();
      if (!mAd) continue;
      const mSlug = slugTR(mAd);
      const posta = n.postCode?.toString() ?? '';
      mahalleler.push({
        ad: mAd,
        slug: mSlug,
        kod: posta || `${ilceKod}-${mSlug}`,
      });
    }

    ilceler.push({
      ad: ilceAd,
      slug: ilceSlug,
      kod: ilceKod,
      mahalleler,
    });
  }

  // İl shard'ını yaz
  const ilOut = {
    il: { ad: ilAd, slug: ilSlug, kod: ilKod },
    ilceler,
  };
  writeJSON(path.join(IL_DIR, `${ilSlug}.json`), ilOut);

  // Index'e eklenecek alanlar (yalnızca il düzeyi)
  iller.push({ ad: ilAd, slug: ilSlug, kod: ilKod });
}

// Index yaz
iller.sort((a, b) => a.ad.localeCompare(b.ad, 'tr'));
writeJSON(path.join(OUT_DIR, 'index.json'), { iller });

console.log('Bitti ✓');
