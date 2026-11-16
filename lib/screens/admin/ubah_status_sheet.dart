import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/pesanan.dart';
import '../../models/status_pesanan.dart';
/// Lembar pemilihan status berikutnya untuk admin.
///
/// Hanya status yang diizinkan backend yang ditawarkan, diambil dari
/// `StatusPesanan.berikutnya` yang meniru aturan `TRANSISI` di backend. Kalau
/// admin tetap memilih status yang tidak sah (mis. karena aturan backend
/// berubah), backend menolaknya dengan HTTP 409 dan pesannya ditampilkan apa
/// adanya.
///
/// Mengembalikan status yang dipilih, atau null bila dibatalkan.
class UbahStatusSheet extends StatelessWidget {
  const UbahStatusSheet({super.key, required this.pesanan});

  final Pesanan pesanan;

  @override
  Widget build(BuildContext context) {
    final List<StatusPesanan> pilihan = pesanan.status.berikutnya;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: Jarak.sm, bottom: Jarak.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: Jarak.lg),
                decoration: BoxDecoration(
                  color: Warna.garis,
                  borderRadius: BorderRadius.circular(Sudut.pil),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Jarak.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Ubah Status Pesanan',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      color: Warna.teksUtama,
                    ),
                  ),
                  const SizedBox(height: Jarak.xs),
                  Text(
                    'Pesanan #${pesanan.id} saat ini '
                    '${pesanan.status.label.toLowerCase()}.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Warna.teksKedua,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Jarak.lg),

            if (pilihan.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Jarak.xl),
                child: Text(
                  'Pesanan ini sudah berstatus akhir, jadi statusnya tidak '
                  'bisa diubah lagi.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Warna.teksKedua,
                    height: 1.55,
                  ),
                ),
              )
            else
              for (final StatusPesanan status in pilihan)
                _PilihanStatus(
                  status: status,
                  pesanan: pesanan,
                  onTap: () => Navigator.of(context).pop(status),
                ),

            const SizedBox(height: Jarak.md),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Jarak.xl),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PilihanStatus extends StatelessWidget {
  const _PilihanStatus({
    required this.status,
    required this.pesanan,
    required this.onTap,
  });

  final StatusPesanan status;
  final Pesanan pesanan;
  final VoidCallback onTap;

  /// Pesanan hanya bisa diselesaikan setelah berat aktual diisi, karena tanpa
  /// itu harga akhirnya belum diketahui. Aturan ini sama dengan backend.
  bool get _tertahan => status == StatusPesanan.selesai && !pesanan.hargaSudahFinal;

  @override
  Widget build(BuildContext context) {
    final bool berbahaya = status == StatusPesanan.dibatalkan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, 0, Jarak.xl, Jarak.md),
      child: InkWell(
        onTap: _tertahan ? null : onTap,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        child: Container(
          padding: const EdgeInsets.all(Jarak.lg),
          decoration: BoxDecoration(
            color: _tertahan ? Warna.latar : Warna.permukaan,
            borderRadius: BorderRadius.circular(Sudut.kartu),
            border: Border.all(color: Warna.garis),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(Jarak.sm),
                decoration: BoxDecoration(
                  color: status.warnaLatar,
                  borderRadius: BorderRadius.circular(Jarak.sm),
                ),
                child: Icon(status.ikon, size: 17, color: status.warnaTeks),
              ),
              const SizedBox(width: Jarak.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Ubah ke ${status.label}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _tertahan
                            ? Warna.teksSamar
                            : (berbahaya ? Warna.bahaya : Warna.teksUtama),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tertahan
                          ? 'Berat aktual pesanan ini belum diisi. Isi beratnya '
                                'lebih dulu sebelum menyelesaikan pesanan.'
                          : status.keterangan,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Warna.teksKedua,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
