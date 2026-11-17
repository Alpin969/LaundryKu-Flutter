import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/status_pesanan.dart';

/// Lencana status pesanan.
///
/// Status dikenali dari tulisannya, bukan dari warnanya saja, jadi pengguna
/// yang sulit membedakan warna tetap bisa membacanya.
class LencanaStatus extends StatelessWidget {
  const LencanaStatus({super.key, required this.status, this.ringkas = false});

  final StatusPesanan status;

  /// Versi kecil untuk dipakai di dalam kartu yang sempit.
  final bool ringkas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ringkas ? Jarak.sm : Jarak.md,
        vertical: ringkas ? 3 : Jarak.xs + 1,
      ),
      decoration: BoxDecoration(
        color: status.warnaLatar,
        borderRadius: BorderRadius.circular(Sudut.pil),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            status.label,
            style: TextStyle(
              fontSize: ringkas ? 11.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: status.warnaTeks,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tahapan pesanan sebagai penunjuk kemajuan.
///
/// Menampilkan empat tahap utama, dari menunggu konfirmasi sampai selesai.
/// Untuk pesanan yang dibatalkan, penunjuk ini tidak ditampilkan karena
/// alurnya tidak lagi maju.
class TahapanPesanan extends StatelessWidget {
  const TahapanPesanan({super.key, required this.status});

  final StatusPesanan status;

  static const List<StatusPesanan> _tahapan = <StatusPesanan>[
    StatusPesanan.menungguKonfirmasi,
    StatusPesanan.dikonfirmasi,
    StatusPesanan.sedangDicuci,
    StatusPesanan.siapDiambil,
    StatusPesanan.selesai,
  ];

  @override
  Widget build(BuildContext context) {
    if (status == StatusPesanan.dibatalkan) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Jarak.lg),
        decoration: BoxDecoration(
          color: Warna.bahayaMuda,
          borderRadius: BorderRadius.circular(Sudut.kartu),
        ),
        child: const Text(
          'Pesanan ini dibatalkan, jadi prosesnya tidak dilanjutkan.',
          style: TextStyle(fontSize: 13, color: Warna.bahaya, height: 1.5),
        ),
      );
    }

    final int posisiSekarang = _tahapan.indexOf(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          status.keterangan,
          style: const TextStyle(
            fontSize: 13.5,
            color: Warna.teksKedua,
            height: 1.6,
          ),
        ),
        const SizedBox(height: Jarak.lg),
        for (int i = 0; i < _tahapan.length; i++)
          _BarisTahap(
            label: _tahapan[i].label,
            sudah: i < posisiSekarang,
            sedang: i == posisiSekarang,
            terakhir: i == _tahapan.length - 1,
          ),
      ],
    );
  }
}

class _BarisTahap extends StatelessWidget {
  const _BarisTahap({
    required this.label,
    required this.sudah,
    required this.sedang,
    required this.terakhir,
  });

  final String label;
  final bool sudah;
  final bool sedang;
  final bool terakhir;

  @override
  Widget build(BuildContext context) {
    // Tahap yang sudah dilewati ditandai centang, tahap yang sedang berjalan
    // ditandai lingkaran berisi, dan tahap berikutnya masih abu-abu.
    final Color warna = sedang
        ? Warna.primary
        : (sudah ? Warna.sukses : Warna.garis);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 24,
            child: Column(
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: sudah || sedang ? warna : Warna.permukaan,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sudah || sedang ? warna : Warna.garis,
                      width: 2,
                    ),
                  ),
                  child: sudah
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : (sedang
                            ? const Center(
                                child: SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              )
                            : null),
                ),
                if (!terakhir)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: sudah ? Warna.sukses : Warna.garis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Jarak.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1, bottom: terakhir ? 0 : Jarak.lg),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: sedang ? FontWeight.w600 : FontWeight.w500,
                  color: sedang || sudah ? Warna.teksUtama : Warna.teksSamar,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
