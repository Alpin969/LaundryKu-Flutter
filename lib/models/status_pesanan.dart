import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Enam status pesanan RENOVA, sesuai kolom `status` di database dan
/// `TRANSISI` di backend.
///
/// Aturan perpindahan status disalin dari backend ke sini hanya untuk
/// MENENTUKAN TOMBOL MANA YANG DITAMPILKAN. Keputusan sebenarnya tetap di
/// backend: kalau aplikasi salah menampilkan tombol, backend tetap menolak
/// perpindahan yang tidak sah dengan HTTP 409.
enum StatusPesanan {
  menungguKonfirmasi(
    kode: 'PENDING_CONFIRMATION',
    label: 'Menunggu Konfirmasi',
    keterangan: 'Pesanan sudah masuk dan sedang menunggu diperiksa admin.',
    warnaTeks: Warna.peringatan,
    warnaLatar: Warna.peringatanMuda,
  ),
  dikonfirmasi(
    kode: 'CONFIRMED',
    label: 'Dikonfirmasi',
    keterangan: 'Pesanan diterima admin dan segera masuk proses pencucian.',
    warnaTeks: Warna.primaryGelap,
    warnaLatar: Warna.aksen,
  ),
  sedangDicuci(
    kode: 'WASHING',
    label: 'Sedang Dicuci',
    keterangan: 'Pakaian sedang melalui proses pencucian.',
    warnaTeks: Warna.primary,
    warnaLatar: Warna.aksenLembut,
  ),
  siapDiambil(
    kode: 'READY_FOR_PICKUP',
    label: 'Siap Diambil',
    keterangan: 'Pakaian sudah selesai dan bisa diambil di outlet.',
    warnaTeks: Warna.sukses,
    warnaLatar: Warna.suksesMuda,
  ),
  selesai(
    kode: 'COMPLETED',
    label: 'Selesai',
    keterangan: 'Pesanan sudah diambil pelanggan dan dinyatakan selesai.',
    warnaTeks: Warna.sukses,
    warnaLatar: Warna.suksesMuda,
  ),
  dibatalkan(
    kode: 'CANCELLED',
    label: 'Dibatalkan',
    keterangan: 'Pesanan dibatalkan dan tidak akan diproses.',
    warnaTeks: Warna.bahaya,
    warnaLatar: Warna.bahayaMuda,
  );

  const StatusPesanan({
    required this.kode,
    required this.label,
    required this.keterangan,
    required this.warnaTeks,
    required this.warnaLatar,
  });

  /// Nilai yang dipakai backend.
  final String kode;

  /// Sebutan yang ditampilkan ke pengguna.
  final String label;

  /// Penjelasan singkat arti status ini.
  final String keterangan;

  final Color warnaTeks;
  final Color warnaLatar;

  /// Status yang mungkin menjadi tujuan berikutnya (meniru `TRANSISI` backend).
  List<StatusPesanan> get berikutnya {
    switch (this) {
      case StatusPesanan.menungguKonfirmasi:
        return const <StatusPesanan>[
          StatusPesanan.dikonfirmasi,
          StatusPesanan.dibatalkan,
        ];
      case StatusPesanan.dikonfirmasi:
        return const <StatusPesanan>[
          StatusPesanan.sedangDicuci,
          StatusPesanan.dibatalkan,
        ];
      case StatusPesanan.sedangDicuci:
        return const <StatusPesanan>[
          StatusPesanan.siapDiambil,
          StatusPesanan.dibatalkan,
        ];
      case StatusPesanan.siapDiambil:
        return const <StatusPesanan>[
          StatusPesanan.selesai,
          StatusPesanan.dibatalkan,
        ];
      case StatusPesanan.selesai:
      case StatusPesanan.dibatalkan:
        return const <StatusPesanan>[];
    }
  }

  /// Status akhir tidak bisa diubah lagi.
  bool get sudahFinal =>
      this == StatusPesanan.selesai || this == StatusPesanan.dibatalkan;

  /// Pesanan yang masih berjalan (belum selesai dan belum dibatalkan).
  bool get masihAktif => !sudahFinal;

  /// Customer hanya boleh membatalkan pesanannya sebelum pencucian dimulai.
  /// Aturannya sama dengan `bolehDibatalkanCustomer` di backend.
  bool get bolehDibatalkanCustomer =>
      this == StatusPesanan.menungguKonfirmasi ||
      this == StatusPesanan.dikonfirmasi;

  /// Perlu diingatkan ke admin: pesanan tidak bisa diselesaikan sebelum
  /// berat aslinya diisi, karena harga akhirnya belum diketahui.
  bool get butuhBeratAsli =>
      this == StatusPesanan.siapDiambil;

  /// Status yang dianggap masih berjalan.
  static const List<StatusPesanan> semuaAktif = <StatusPesanan>[
    StatusPesanan.menungguKonfirmasi,
    StatusPesanan.dikonfirmasi,
    StatusPesanan.sedangDicuci,
    StatusPesanan.siapDiambil,
  ];

  static StatusPesanan dariKode(String? kode) {
    final String dicari = (kode ?? '').toUpperCase();
    for (final StatusPesanan status in values) {
      if (status.kode == dicari) return status;
    }

    // Status tak dikenal diperlakukan sebagai "menunggu konfirmasi": masih
    // aktif, jadi pesanan tidak salah dianggap selesai atau dibatalkan.
    return StatusPesanan.menungguKonfirmasi;
  }
}
