import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/tampilan_status.dart';

/// Halaman pembuka.
///
/// Ditampilkan selama aplikasi memeriksa token yang tersimpan. Hasilnya
/// menentukan apakah pengguna langsung masuk atau harus login lebih dulu.
///
/// Halaman ini sengaja tidak punya tombol "Coba Lagi": bila pemeriksaan gagal
/// karena server tidak bisa dihubungi, aplikasi langsung berpindah ke halaman
/// login yang menyebutkan alamat server dan penyebabnya. Menahan pengguna di
/// halaman pembuka hanya membuat mereka menunggu tanpa bisa berbuat apa-apa.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Jarak.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const AppLogo(ukuran: 92),
                  const SizedBox(height: Jarak.xl),
                  const NamaAplikasi(
                    ukuranJudul: 28,
                    rataTengah: true,
                    tampilkanSlogan: false,
                  ),
                  const SizedBox(height: Jarak.sm),
                  const Text(
                    NamaAplikasi.slogan,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Warna.teksKedua,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: Jarak.xxl + Jarak.sm),
                  const TampilanMemuat(
                    keterangan: 'Memeriksa sesi Anda...',
                    ringkas: true,
                  ),
                  const SizedBox(height: Jarak.md),
                  TextButton(
                    onPressed: () => AuthService.instance.periksaSesi(),
                    child: const Text('Periksa ulang'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
