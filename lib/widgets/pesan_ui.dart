import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Menampilkan pesan singkat di bagian bawah layar.
///
/// Dipakai untuk memberi tahu hasil suatu tindakan: berhasil, gagal, atau
/// sekadar informasi.
void tampilkanPesan(
  BuildContext context,
  String pesan, {
  JenisPesan jenis = JenisPesan.info,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  // Pesan sebelumnya dibuang supaya tidak menumpuk saat pengguna menekan
  // tombol berkali-kali.
  messenger.hideCurrentSnackBar();
  _tampilkanLewat(messenger, pesan, jenis);
}

/// Sama seperti [tampilkanPesan], tetapi memakai [ScaffoldMessengerState] yang
/// sudah ditangkap lebih dulu.
///
/// Dibutuhkan halaman yang menutup dirinya sendiri sebelum menampilkan pesan
/// (mis. setelah pesanan dibuat): context halaman itu sudah tidak berlaku lagi,
/// sedangkan ScaffoldMessenger milik aplikasi tetap hidup.
void tampilkanPesanLewat(
  ScaffoldMessengerState messenger,
  String pesan, {
  JenisPesan jenis = JenisPesan.info,
}) {
  messenger.hideCurrentSnackBar();
  _tampilkanLewat(messenger, pesan, jenis);
}

void _tampilkanLewat(
  ScaffoldMessengerState messenger,
  String pesan,
  JenisPesan jenis,
) {
  final (Color warna, IconData ikon) = switch (jenis) {
    JenisPesan.sukses => (Warna.sukses, Icons.check_circle_rounded),
    JenisPesan.gagal => (Warna.bahaya, Icons.error_rounded),
    JenisPesan.info => (Warna.primary, Icons.info_rounded),
  };

  messenger.showSnackBar(
    SnackBar(
      backgroundColor: warna,
      duration: const Duration(seconds: 4),
      content: Row(
        children: <Widget>[
          Icon(ikon, size: 20, color: Colors.white),
          const SizedBox(width: Jarak.md),
          Expanded(child: Text(pesan)),
        ],
      ),
    ),
  );
}

enum JenisPesan { sukses, gagal, info }

/// Dialog konfirmasi untuk tindakan yang tidak bisa dibatalkan.
///
/// Mengembalikan true bila pengguna menekan tombol lanjut.
Future<bool> konfirmasi(
  BuildContext context, {
  required String judul,
  required String pesan,
  String labelLanjut = 'Lanjutkan',
  String labelBatal = 'Batal',
  bool berbahaya = false,
}) async {
  final bool? jawaban = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(judul),
        content: Text(pesan),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Warna.teksKedua,
            ),
            child: Text(labelBatal),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: berbahaya ? Warna.bahaya : Warna.primary,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: Jarak.lg),
            ),
            child: Text(labelLanjut),
          ),
        ],
      );
    },
  );

  return jawaban ?? false;
}

/// Lembar pilihan di bagian bawah layar.
///
/// Dipakai saat pengguna harus memilih satu dari beberapa tindakan, mis.
/// mengambil foto dari kamera atau dari galeri.
Future<T?> pilihDariLembar<T>(
  BuildContext context, {
  required String judul,
  required List<({T nilai, String label, IconData ikon, String? keterangan})>
  pilihan,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: Jarak.sm, bottom: Jarak.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Jarak.xl,
                  Jarak.md,
                  Jarak.xl,
                  Jarak.sm,
                ),
                child: Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Warna.teksUtama,
                  ),
                ),
              ),
              for (final ({
                    T nilai,
                    String label,
                    IconData ikon,
                    String? keterangan,
                  })
                  item
                  in pilihan)
                ListTile(
                  leading: Icon(item.ikon, color: Warna.primary),
                  title: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: item.keterangan == null
                      ? null
                      : Text(
                          item.keterangan!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Warna.teksKedua,
                          ),
                        ),
                  onTap: () => Navigator.of(sheetContext).pop(item.nilai),
                ),
            ],
          ),
        ),
      );
    },
  );
}
