// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Router
import 'package:eduplas/router/app_router.dart';
import 'package:eduplas/router/route_names.dart';

// L10n
import 'package:eduplas/l10n/supported_locales.dart';
import 'package:eduplas/l10n/app_localizations.dart';

// Çekirdek dil yöneticisi
import 'package:eduplas/cekirdek/dil/dil_yoneticisi.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('localeCode');
    final List<Locale> supported = List<Locale>.from(kSupportedLocales);

    Locale initialLocale;
    if (savedCode != null && savedCode.isNotEmpty) {
      final cand = Locale(savedCode);
      initialLocale = _matchSupported(cand, supported) ?? supported.first;
    } else {
      final device = WidgetsBinding.instance.platformDispatcher.locale;
      initialLocale = _matchSupported(device, supported) ?? const Locale('tr');
    }

    DilYoneticisi.instance.dilAyarla(initialLocale.languageCode);

    runApp(EduPlasApp(initialLocale: initialLocale));
  }, (error, stack) {
    print('UNCAUGHT ERROR: $error');
    print(stack);
  });
}

Locale? _matchSupported(Locale? want, List<Locale> supported) {
  if (want == null) return null;
  for (final l in supported) {
    if (l == want) return l;
  }
  for (final l in supported) {
    if (l.languageCode == want.languageCode) return l;
  }
  return null;
}

class EduPlasApp extends StatefulWidget {
  const EduPlasApp({super.key, required this.initialLocale});
  final Locale initialLocale;

  @override
  State<EduPlasApp> createState() => _EduPlasAppState();

  static _EduPlasAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_EduPlasAppState>();
}

class _EduPlasAppState extends State<EduPlasApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  Future<void> setLocale(Locale locale) async {
    final List<Locale> supported = List<Locale>.from(kSupportedLocales);
    final matched = _matchSupported(locale, supported) ?? supported.first;

    setState(() => _locale = matched);
    DilYoneticisi.instance.dilAyarla(matched.languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('localeCode', matched.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduPlas',
      debugShowCheckedModeBanner: false,
      initialRoute: RouteNames.giris,
      onGenerateRoute: appRouter, // ✅ DÜZELTİLDİ

      locale: _locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        final manual = _locale;
        final manualMatch =
            _matchSupported(manual, List<Locale>.from(supported));
        if (manualMatch != null) return manualMatch;
        return _matchSupported(deviceLocale, List<Locale>.from(supported)) ??
            supported.first;
      },

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00BFA5),
        brightness: Brightness.light,
      ),
    );
  }
}
