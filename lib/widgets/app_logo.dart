import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Logo LaundryKu.
///
/// Bentuknya sengaja disamakan dengan logo di website admin
/// (`web-admin/assets/images/logo.svg`): kotak biru bersudut membulat dengan
/// tetesan air putih di tengahnya, supaya kedua aplikasi terbaca sebagai satu
/// produk.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.ukuran = 72, this.warnaLatar, this.warnaIkon});

  /// Sisi kotak logo dalam piksel.
  final double ukuran;

  /// Warna kotak. Bila null, memakai biru utama LaundryKu.
  final Color? warnaLatar;

  /// Warna tetesan air.
  final Color? warnaIkon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: warnaLatar ?? Warna.primary,
        // Sudut 12 dari 48 px pada logo asli = 25% dari sisi kotak.
        borderRadius: BorderRadius.circular(ukuran * 0.25),
      ),
      child: Icon(
        Icons.water_drop_rounded,
        size: ukuran * 0.52,
        color: warnaIkon ?? Colors.white,
      ),
    );
  }
}

/// Nama aplikasi beserta slogan, dipakai di halaman splash dan login.
class NamaAplikasi extends StatelessWidget {
  const NamaAplikasi({
    super.key,
    this.ukuranJudul = 26,
    this.tampilkanSlogan = true,
    this.warnaJudul,
    this.warnaSlogan,
    this.rataTengah = false,
  });

  final double ukuranJudul;
  final bool tampilkanSlogan;
  final Color? warnaJudul;
  final Color? warnaSlogan;
  final bool rataTengah;

  static const String nama = 'LaundryKu';
  static const String slogan = 'Bersih, Praktis, Terpercaya';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: rataTengah
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          nama,
          textAlign: rataTengah ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: ukuranJudul,
            fontWeight: FontWeight.w700,
            color: warnaJudul ?? Warna.teksUtama,
            letterSpacing: -0.5,
          ),
        ),
        if (tampilkanSlogan) ...<Widget>[
          const SizedBox(height: Jarak.xs),
          Text(
            slogan,
            textAlign: rataTengah ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: 13,
              color: warnaSlogan ?? Warna.teksKedua,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
