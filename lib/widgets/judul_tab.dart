import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Kepala halaman untuk layar yang dipakai sebagai tab.
///
/// Tab tidak punya AppBar sendiri karena kerangka navigasi sudah menyediakan
/// tempatnya. Widget ini memberi judul, keterangan, dan tombol tambahan yang
/// seragam di semua tab.
///
/// Tombol muat ulang tidak lagi disediakan di sini: isi tab disegarkan sendiri
/// oleh `PenyegarOtomatis` di kerangka navigasi.
class JudulTab extends StatelessWidget {
  const JudulTab({
    super.key,
    required this.judul,
    this.keterangan,
    this.aksi,
  });

  final String judul;
  final String? keterangan;

  /// Tombol tambahan di kanan, mis. "Tambah Layanan".
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.xl, Jarak.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Warna.teksUtama,
                    height: 1.3,
                  ),
                ),
                if (keterangan != null) ...<Widget>[
                  const SizedBox(height: Jarak.xs),
                  Text(
                    keterangan!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Warna.teksKedua,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tombol aksi hanya ikut disusun bila memang diberikan.
          ?aksi,
        ],
      ),
    );
  }
}
