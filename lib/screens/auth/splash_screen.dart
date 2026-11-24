import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/tampilan_status.dart';

/// Halaman pembuka RENOVA.
///
/// Ditampilkan selama aplikasi memeriksa token yang tersimpan. Hasilnya
/// menentukan apakah pengguna langsung masuk atau harus login lebih dulu.
///
/// Halaman ini sengaja tidak punya tombol besar "Coba Lagi": bila pemeriksaan
/// gagal, aplikasi langsung berpindah ke halaman login yang menjelaskan
/// penyebabnya. Tautan kecil "Periksa ulang" tetap ada untuk jaringan yang
/// lambat tersambung.
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
                  const AppLogo(ukuran: 104),
                  const SizedBox(height: Jarak.xl),
                  const NamaAplikasi(
                    ukuranJudul: 30,
                    rataTengah: true,
                    tampilkanSlogan: false,
                  ),
                  const SizedBox(height: Jarak.sm),
                  const Text(
                    NamaAplikasi.deskripsi,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Warna.teksKedua,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Jarak.md),
                  // Garis cyan sebagai penanda brand, bukan dekorasi acak.
                  Container(
                    width: 44,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Warna.primaryCerah,
                      borderRadius: BorderRadius.circular(Sudut.pil),
                    ),
                  ),
                  const SizedBox(height: Jarak.md),
                  const Text(
                    NamaAplikasi.slogan,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Warna.teksSamar,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: Jarak.xxl + Jarak.sm),
                  const TampilanMemuat(
                    keterangan: 'Memeriksa sesi Anda...',
                    ringkas: true,
                  ),
                  const SizedBox(height: Jarak.sm),
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
