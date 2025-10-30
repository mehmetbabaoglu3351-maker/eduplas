// test/legal_versiyonlar_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplas/cekirdek/hukuk/legal_versiyonlar.dart';

void main() {
  test('Hukuk döküman sayısı 4', () {
    expect(LegalVersiyonlar.dokumanlar.length, 4);
  });

  test('Versiyon anahtarları mevcut', () {
    final keys = LegalVersiyonlar.dokumanlar.map((d) => d.versiyonKey).toSet();
    expect(keys.containsAll({'_vSozlesme', '_vRiza', '_vAyd', '_vGiz'}), true);
  });

  test('Asset yolları doğru klasörde', () {
    final allInAssets = LegalVersiyonlar.dokumanlar
        .every((d) => d.assetYolu.startsWith('assets/hukuk/'));
    expect(allInAssets, true);
  });
}
