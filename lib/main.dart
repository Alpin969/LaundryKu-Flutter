import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/shells/shell_pelanggan.dart';
import 'services/auth_service.dart';

/// Kunci navigator dipakai untuk menutup halaman yang sedang terbuka ketika
/// sesi berakhir (token kedaluwarsa atau pengguna keluar).
final GlobalKey<NavigatorState> kunciNavigator = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Data locale untuk intl, supaya format tanggal dan angka benar-benar
  // memakai aturan Indonesia (nama bulan Indonesia, pemisah ribuan titik).
  await initializeDateFormatting('id_ID');

  // Memeriksa token yang tersimpan dijalankan tanpa ditunggu, supaya halaman
  // splash tetap terlihat selama pemeriksaan berlangsung. Hasilnya dilaporkan
  // lewat notifikasi AuthService ke seluruh halaman.
  unawaited(AuthService.instance.periksaSesi());

  runApp(const AplikasiLaundryKu());
}

class AplikasiLaundryKu extends StatefulWidget {
  const AplikasiLaundryKu({super.key});

  @override
  State<AplikasiLaundryKu> createState() => _AplikasiLaundryKuState();
}

class _AplikasiLaundryKuState extends State<AplikasiLaundryKu> {
  @override
  void initState() {
    super.initState();

    // Saat sesi berakhir, seluruh halaman yang sedang terbuka ditutup supaya
    // pengguna benar-benar kembali ke halaman login. Tanpa ini, halaman detail
    // yang sudah dibuka akan tetap menutupi halaman login.
    AuthService.instance.saatSesiKembaliKeLogin = _tutupSemuaHalaman;
  }

  void _tutupSemuaHalaman() {
    kunciNavigator.currentState?.popUntil((Route<dynamic> rute) => rute.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaundryKu',
      debugShowCheckedModeBanner: false,
      navigatorKey: kunciNavigator,
      theme: AppTheme.terang(),

      // Nama bulan dan teks bawaan Flutter memakai Bahasa Indonesia.
      locale: const Locale('id', 'ID'),
      supportedLocales: const <Locale>[Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const GerbangSesi(),
    );
  }
}

/// Menentukan halaman yang tampil sesuai keadaan sesi.
///
/// Peran akun hanya menentukan halaman mana yang dibuka. Penjaga keamanan
/// sebenarnya adalah backend, yang memeriksa token pada setiap permintaan.
class GerbangSesi extends StatelessWidget {
  const GerbangSesi({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (BuildContext context, Widget? _) {
        final AuthService auth = AuthService.instance;

        switch (auth.status) {
          case SesiStatus.memeriksa:
            return const SplashScreen();

          case SesiStatus.belumMasuk:
            return const LoginScreen();

          case SesiStatus.masuk:
            final bool admin = auth.pengguna?.adalahAdmin ?? false;
            return admin ? const ShellAdmin() : const ShellPelanggan();
        }
      },
    );
  }
}
