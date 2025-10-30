// test/route_gate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplas/cekirdek/akis/route_gate.dart';

void main() {
  setUp(() {
    // Her test öncesi bayrakları sıfırla
    RouteGate.otpOk = false;
    RouteGate.rolIntentOk = false;
    RouteGate.ilgiOk = false;
    RouteGate.legalOk = false;
  });

  test('Başlangıçta yalnız /giris serbest, zincir kontrolü sıkı', () {
    expect(RouteGate.allow(targetRoute: '/rol_sec'), false);
    expect(RouteGate.allow(targetRoute: '/ilgi_sec'), false);
    expect(RouteGate.allow(targetRoute: '/sozlesme_kabul'), false);
    expect(RouteGate.allow(targetRoute: '/user'), false);
  });

  test('OTP -> Rol -> İlgi -> Legal sırası', () {
    RouteGate.otpOk = true;
    expect(RouteGate.allow(targetRoute: '/rol_sec'), true);
    expect(RouteGate.allow(targetRoute: '/ilgi_sec'), false);

    RouteGate.rolIntentOk = true;
    expect(RouteGate.allow(targetRoute: '/ilgi_sec'), true);
    expect(RouteGate.allow(targetRoute: '/sozlesme_kabul'), false);

    RouteGate.ilgiOk = true;
    expect(RouteGate.allow(targetRoute: '/sozlesme_kabul'), true);
    expect(RouteGate.allow(targetRoute: '/user'), false);

    RouteGate.legalOk = true;
    expect(RouteGate.allow(targetRoute: '/user'), true);
  });
}
