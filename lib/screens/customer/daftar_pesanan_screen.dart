import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/pesanan.dart';
import '../../models/status_pesanan.dart';
import '../../services/api_client.dart';
import '../../services/pesanan_service.dart';
import '../../widgets/judul_tab.dart';
import '../../widgets/kartu_pesanan.dart';
import '../../widgets/tampilan_status.dart';
import 'detail_pesanan_screen.dart';

/// Daftar pesanan dengan penyaring status.
///
/// Dipakai pelanggan maupun admin; [tampilkanPelanggan] menentukan apakah nama
/// pemesan ikut ditampilkan. Tanpa penyaring, yang dimuat adalah pesanan aktif
/// (lima status sekaligus) supaya yang perlu dikerjakan langsung terlihat.
///
/// Tidak memakai Scaffold sendiri karena selalu dipasang di dalam kerangka
/// navigasi.
class DaftarPesananScreen extends StatefulWidget {
  const DaftarPesananScreen({
    super.key,
    this.tampilkanPelanggan = false,
    this.saringAwal,
  });

  final bool tampilkanPelanggan;

  /// Penyaring yang langsung aktif saat tab dibuka, mis. dari dashboard admin.
  final StatusPesanan? saringAwal;

  @override
  State<DaftarPesananScreen> createState() => DaftarPesananScreenState();
}

class DaftarPesananScreenState extends State<DaftarPesananScreen> {
  final PesananService _pesananService = const PesananService();

  List<Pesanan> _pesanan = <Pesanan>[];
  StatusPesanan? _saring;
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _saring = widget.saringAwal;
    muatUlang();
  }

  /// Dipakai kerangka navigasi untuk menerapkan penyaring dari luar, mis.
  /// ketika admin menekan salah satu kotak status di dashboard.
  void terapkanSaring(StatusPesanan? status) {
    setState(() => _saring = status);
    muatUlang();
  }

  /// [senyap] dipakai penyegaran latar: tanpa penanda memuat dan tanpa
  /// mengganti daftar yang sudah tampil bila permintaannya gagal.
  Future<void> muatUlang({bool senyap = false}) async {
    if (mounted && !senyap) setState(() => _memuat = true);

    try {
      final List<Pesanan> hasil = _saring == null
          ? await _pesananService.daftarBanyakStatus(StatusPesanan.semuaAktif)
          : await _pesananService.daftar(status: _saring, limit: 100);

      if (!mounted) return;
      setState(() {
        _pesanan = hasil;
        _galat = null;
      });
    } on ApiException catch (kesalahan) {
      if (!mounted) return;

      if (senyap && _pesanan.isNotEmpty) return;

      setState(() => _galat = kesalahan.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        JudulTab(
          judul: _saring == null ? 'Pesanan Aktif' : _saring!.label,
          keterangan: _saring == null
              ? 'Pesanan yang masih berjalan, dari menunggu konfirmasi sampai '
                    'siap diambil.'
              : _saring!.keterangan,
        ),
        _penyaring(),
        Expanded(child: _isi()),
      ],
    );
  }

  Widget _penyaring() {
    // "Aktif" memakai lima status sekaligus, sedangkan pilihan lain menyaring
    // satu status saja.
    final List<({StatusPesanan? nilai, String label})> pilihan =
        <({StatusPesanan? nilai, String label})>[
          (nilai: null, label: 'Aktif'),
          for (final StatusPesanan status in StatusPesanan.values)
            (nilai: status, label: status.label),
        ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Jarak.xl,
          vertical: Jarak.sm,
        ),
        itemCount: pilihan.length,
        separatorBuilder: (_, _) => const SizedBox(width: Jarak.sm),
        itemBuilder: (BuildContext context, int index) {
          final ({StatusPesanan? nilai, String label}) item = pilihan[index];
          final bool terpilih = _saring == item.nilai;

          return ChoiceChip(
            label: Text(item.label),
            selected: terpilih,
            showCheckmark: false,
            selectedColor: Warna.primary,
            backgroundColor: Warna.permukaan,
            side: BorderSide(
              color: terpilih ? Warna.primary : Warna.garis,
            ),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: terpilih ? FontWeight.w700 : FontWeight.w500,
              color: terpilih ? Colors.white : Warna.teksKedua,
            ),
            onSelected: (_) => terapkanSaring(item.nilai),
          );
        },
      ),
    );
  }

  Widget _isi() {
    if (_memuat && _pesanan.isEmpty) {
      return const TampilanMemuat(keterangan: 'Memuat pesanan...');
    }

    if (_galat != null) {
      return TampilanGagal(
        pesan: _galat!,
        judul: 'Pesanan gagal dimuat',
        onCobaLagi: muatUlang,
      );
    }

    if (_pesanan.isEmpty) {
      return TampilanKosong(
        judul: _saring == null
            ? 'Tidak ada pesanan aktif'
            : 'Tidak ada pesanan ${_saring!.label.toLowerCase()}',
        pesan: _saring == null
            ? 'Pesanan yang masih berjalan akan muncul di sini. Buat pesanan '
                  'baru lewat tombol Pesan di beranda.'
            : 'Belum ada pesanan dengan status ini. Coba pilih penyaring lain.',
        labelTombol: _saring == null ? null : 'Lihat pesanan aktif',
        onTombol: _saring == null ? null : () => terapkanSaring(null),
      );
    }

    return RefreshIndicator(
      onRefresh: muatUlang,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Jarak.xl,
          Jarak.sm,
          Jarak.xl,
          Jarak.xxl,
        ),
        itemCount: _pesanan.length,
        separatorBuilder: (_, _) => const SizedBox(height: Jarak.md),
        itemBuilder: (BuildContext context, int index) {
          final Pesanan pesanan = _pesanan[index];

          return KartuPesanan(
            pesanan: pesanan,
            tampilkanPelanggan: widget.tampilkanPelanggan,
            onTap: () =>
                bukaDetailPesanan(context, pesanan.id).then((_) => muatUlang()),
          );
        },
      ),
    );
  }
}
