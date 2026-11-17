import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/pesanan.dart';
import '../../models/status_pesanan.dart';
import '../../services/api_client.dart';
import '../../services/pesanan_service.dart';
import '../../utils/format.dart';
import '../../widgets/judul_tab.dart';
import '../../widgets/kartu_pesanan.dart';
import '../../widgets/tampilan_status.dart';
import 'detail_pesanan_screen.dart';

/// Riwayat pesanan: yang sudah selesai dan yang dibatalkan.
///
/// Dipisah dari daftar pesanan aktif supaya tetap ringkas walau pesanan sudah
/// menumpuk. Dikelompokkan per bulan agar mudah ditelusuri.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, this.tampilkanPelanggan = false});

  final bool tampilkanPelanggan;

  @override
  State<RiwayatScreen> createState() => RiwayatScreenState();
}

class RiwayatScreenState extends State<RiwayatScreen> {
  final PesananService _pesananService = const PesananService();

  List<Pesanan> _riwayat = <Pesanan>[];
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    muatUlang();
  }

  /// [senyap] dipakai penyegaran latar: tanpa penanda memuat dan tanpa
  /// mengganti riwayat yang sudah tampil bila permintaannya gagal.
  Future<void> muatUlang({bool senyap = false}) async {
    if (mounted && !senyap) setState(() => _memuat = true);

    try {
      // Riwayat hanya berisi dua status akhir, diambil per status lalu
      // digabung dan diurutkan dari yang terbaru oleh service.
      final List<Pesanan> hasil = await _pesananService.daftarBanyakStatus(
        const <StatusPesanan>[StatusPesanan.selesai, StatusPesanan.dibatalkan],
        limitPerStatus: 100,
      );

      if (!mounted) return;
      setState(() {
        _riwayat = hasil;
        _galat = null;
      });
    } on ApiException catch (kesalahan) {
      if (!mounted) return;

      if (senyap && _riwayat.isNotEmpty) return;

      setState(() => _galat = kesalahan.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  /// Mengelompokkan pesanan per bulan berdasarkan waktu pembuatannya.
  Map<String, List<Pesanan>> get _perBulan {
    final Map<String, List<Pesanan>> kelompok = <String, List<Pesanan>>{};

    for (final Pesanan pesanan in _riwayat) {
      final String kunci = pesanan.dibuatPada == null
          ? 'Tanggal tidak tercatat'
          : formatBulan(pesanan.dibuatPada!);

      kelompok.putIfAbsent(kunci, () => <Pesanan>[]).add(pesanan);
    }

    return kelompok;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        JudulTab(
          judul: 'Riwayat Pesanan',
          keterangan:
              'Pesanan yang sudah selesai atau dibatalkan, dikelompokkan per '
              'bulan.',
        ),
        Expanded(child: _isi()),
      ],
    );
  }

  Widget _isi() {
    if (_memuat && _riwayat.isEmpty) {
      return const TampilanMemuat(keterangan: 'Memuat riwayat pesanan...');
    }

    if (_galat != null) {
      return TampilanGagal(
        pesan: _galat!,
        judul: 'Riwayat gagal dimuat',
        onCobaLagi: muatUlang,
      );
    }

    if (_riwayat.isEmpty) {
      return const TampilanKosong(
        judul: 'Belum ada riwayat',
        pesan:
            'Pesanan yang sudah selesai atau dibatalkan akan tercatat di sini '
            'beserta rincian biayanya.',
      );
    }

    final Map<String, List<Pesanan>> kelompok = _perBulan;

    return RefreshIndicator(
      onRefresh: muatUlang,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Jarak.xl,
          Jarak.sm,
          Jarak.xl,
          Jarak.xxl,
        ),
        children: <Widget>[
          _ringkasanAtas(),
          for (final MapEntry<String, List<Pesanan>> entri in kelompok.entries)
            ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  top: Jarak.xl,
                  bottom: Jarak.md,
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      entri.key,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Warna.teksUtama,
                      ),
                    ),
                    const SizedBox(width: Jarak.sm),
                    Text(
                      '(${entri.value.length} pesanan)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Warna.teksSamar,
                      ),
                    ),
                  ],
                ),
              ),
              for (final Pesanan pesanan in entri.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: Jarak.md),
                  child: KartuPesanan(
                    pesanan: pesanan,
                    tampilkanPelanggan: widget.tampilkanPelanggan,
                    onTap: () => bukaDetailPesanan(
                      context,
                      pesanan.id,
                    ).then((_) => muatUlang()),
                  ),
                ),
            ],
        ],
      ),
    );
  }

  Widget _ringkasanAtas() {
    final int selesai = _riwayat
        .where((Pesanan p) => p.status == StatusPesanan.selesai)
        .length;
    final int dibatalkan = _riwayat
        .where((Pesanan p) => p.status == StatusPesanan.dibatalkan)
        .length;

    // Total hanya menjumlahkan pesanan selesai yang harga akhirnya sudah
    // dihitung server, supaya angkanya tidak mencampur pesanan tanpa harga.
    final double total = _riwayat
        .where(
          (Pesanan p) =>
              p.status == StatusPesanan.selesai && p.totalHarga != null,
        )
        .fold(0.0, (double jumlah, Pesanan p) => jumlah + p.totalHarga!);

    return Container(
      padding: const EdgeInsets.all(Jarak.lg),
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        border: Border.all(color: Warna.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _statistik('Selesai', '$selesai')),
              Expanded(child: _statistik('Dibatalkan', '$dibatalkan')),
            ],
          ),
          const SizedBox(height: Jarak.lg),
          const Divider(height: 1, color: Warna.garis),
          const SizedBox(height: Jarak.md),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Total biaya pesanan selesai',
                  style: TextStyle(fontSize: 12.5, color: Warna.teksKedua),
                ),
              ),
              Text(
                formatRupiah(total),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Warna.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statistik(String label, String nilai) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          nilai,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Warna.teksUtama,
            height: 1.15,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Warna.teksKedua),
        ),
      ],
    );
  }
}
