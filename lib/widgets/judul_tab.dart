import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Kepala halaman untuk layar yang dipakai sebagai tab.
///
/// Tab tidak punya AppBar sendiri karena kerangka navigasi sudah menyediakan
/// tempatnya. Widget ini memberi judul dan tombol muat ulang yang seragam di
/// semua tab.
class JudulTab extends StatelessWidget {
  const JudulTab({
    super.key,
    required this.judul,
    this.keterangan,
    this.onMuatUlang,
    this.sedangMemuat = false,
    this.aksi,
  });

  final String judul;
  final String? keterangan;
  final VoidCallback? onMuatUlang;
  final bool sedangMemuat;

  /// Tombol tambahan di kanan, mis. "Tambah Layanan".
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.md, Jarak.sm),
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

          if (onMuatUlang != null)
            IconButton(
              onPressed: sedangMemuat ? null : onMuatUlang,
              tooltip: 'Muat ulang',
              icon: sedangMemuat
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}
