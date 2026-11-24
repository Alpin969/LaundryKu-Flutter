import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Satu baris "label - nilai" pada kartu informasi.
///
/// Dipakai di seluruh halaman detail supaya susunan informasinya seragam dan
/// tidak ada halaman yang menyusun datanya dengan cara sendiri.
class BarisDetail extends StatelessWidget {
  const BarisDetail({
    super.key,
    required this.label,
    required this.nilai,
    this.tebal = false,
    this.warnaLatar,
  });

  final String label;
  final String nilai;

  /// Dipakai untuk baris yang paling penting, mis. total biaya.
  final bool tebal;

  /// Latar belakang berbeda untuk menandai baris penekanan.
  final Color? warnaLatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: warnaLatar,
      padding: EdgeInsets.symmetric(
        horizontal: warnaLatar == null ? 0 : Jarak.md,
        vertical: warnaLatar == null ? 2 : Jarak.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: tebal ? FontWeight.w600 : FontWeight.w400,
                color: Warna.teksKedua,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: Jarak.md),
          Expanded(
            flex: 6,
            child: Text(
              nilai,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: tebal ? 16 : 13.5,
                fontWeight: tebal ? FontWeight.w800 : FontWeight.w600,
                color: tebal ? Warna.primary : Warna.teksUtama,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu dengan judul kecil di atas isinya.
///
/// Judul memakai huruf besar berspasi sempit supaya terbaca sebagai label
/// bagian, bukan sebagai judul halaman kedua.
class KartuBagian extends StatelessWidget {
  const KartuBagian({
    super.key,
    required this.judul,
    required this.anak,
    this.aksi,
  });

  final String judul;
  final Widget anak;

  /// Tombol kecil di kanan judul, mis. "Ubah".
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        border: Border.all(color: Warna.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Jarak.lg,
              Jarak.lg,
              Jarak.md,
              Jarak.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    judul.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Warna.teksSamar,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ?aksi,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Jarak.lg,
              0,
              Jarak.lg,
              Jarak.lg,
            ),
            child: anak,
          ),
        ],
      ),
    );
  }
}
