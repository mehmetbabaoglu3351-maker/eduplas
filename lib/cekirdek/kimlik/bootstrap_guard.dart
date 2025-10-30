// lib/ozellikler/gecit/bootstrap_guard.dart
import 'package:flutter/material.dart';
import '../../cekirdek/kimlik/bootstrap_claims.dart';

typedef RoutePusher = Future<void> Function(BuildContext context);

class BootstrapGuard extends StatelessWidget {
  final bool isSignedIn;
  final BootstrapClaims claims;

  // Sayfa yönlendirme callbackleri: mevcut ekranlarını burada ver.
  final RoutePusher goAuth;
  final RoutePusher goPhoneVerify;
  final RoutePusher goTosConsent;
  final RoutePusher goLocationSelect;
  final RoutePusher goRoleSelect;
  final RoutePusher goPending;
  final RoutePusher goRoleHome;

  const BootstrapGuard({
    super.key,
    required this.isSignedIn,
    required this.claims,
    required this.goAuth,
    required this.goPhoneVerify,
    required this.goTosConsent,
    required this.goLocationSelect,
    required this.goRoleSelect,
    required this.goPending,
    required this.goRoleHome,
  });

  @override
  Widget build(BuildContext context) {
   const decider = BootstrapDecider();
    final step = decider.decide(isSignedIn: isSignedIn, claims: claims);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      switch (step) {
        case BootstrapStep.needAuth:
          await goAuth(context);
          break;
        case BootstrapStep.needPhoneVerify:
          await goPhoneVerify(context);
          break;
        case BootstrapStep.needTosConsent:
          await goTosConsent(context);
          break;
        case BootstrapStep.needLocationSelect:
          await goLocationSelect(context);
          break;
        case BootstrapStep.needRoleSelect:
          await goRoleSelect(context);
          break;
        case BootstrapStep.pendingApproval:
          await goPending(context);
          break;
        case BootstrapStep.goToRoleHome:
          await goRoleHome(context);
          break;
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}


