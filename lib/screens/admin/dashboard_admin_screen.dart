import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/pesanan.dart';
import '../../models/status_pesanan.dart';
import '../../services/api_client.dart';
import '../../services/pesanan_service.dart';
import '../../widgets/judul_tab.dart';
import '../../widgets/kartu_pesanan.dart';
import '../../widgets/tampilan_status.dart';
import '../customer/detail_pesanan_screen.dart';

/// Dashboard admin.
///
/// Dibuat untuk menjawab satu pertanyaan: pesanan mana yang perlu saya
/// kerjakan sekarang? Karena itu urutan status mengikuti alur kerja, dan yang
/// paling mendesak (menunggu konfirmasi) ditaruh paling depan dan bisa
/// langsung diklik untuk disaring.
class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({
    super.key,
    required this.namaPengguna,
    required this.onBukaSemuaPesanan,
  });

  final String namaPengguna;

  /// Pindah ke tab Pesanan, dengan penyaring tertentu bila diisi.
  final void Function(StatusPesanan? saring) onBukaSemuaPesanan;

  @override
  State<DashboardAdminScreen> createState() => DashboardAdminScreenState();
}

class DashboardAdminScreenState extends State<DashboardAdminScreen> {
  final PesananService _pesananService = const PesananService();

  List<Pesanan> _semua = <Pesanan>[];
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    muatUlang();
  }

  /// [senyap] dipakai penyegaran latar: tanpa penanda memuat dan tanpa
  /// mengganti ringkasan yang sudah tampil bila permintaannya gagal.
  Future<void> muatUlang({bool senyap = false}) async {
    if (mounted && !senyap) setState(() => _memuat = true);

    try {
      // Admin melihat semua pesanan; 100 baris pertama sudah cukup untuk
      // hitungan ringkasan di dashboard.
      final List<Pesanan> hasil = await _pesananService.daftar(limit: 100);
      if (!mounted) return;
      setState(() {
        _semua = hasil;
        _galat = null;
      });
    } on ApiException catch (kesalahan) {
      if (!mounted) return;

      if (senyap && _semua.isNotEmpty) return;

      setState(() => _galat = kesalahan.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  int _jumlah(StatusPesanan status) =>
      _semua.where((Pesanan p) => p.status == status).length;

  /// Pesanan yang paling perlu ditangani lebih dulu.
  List<Pesanan> get _perluDikerjakan {
    return _semua
        .where(
          (Pesanan p) =>
              p.status == StatusPesanan.menungguKonfirmasi ||
              p.status == StatusPesanan.siapDiambil,
        )
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: muatUlang,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: JudulTab(
              judul: 'Panel Admin',
              keterangan: widget.namaPengguna.isEmpty
                  ? 'Ringkasan seluruh pesanan LaundryKu.'
                  : 'Halo, ${widget.namaPengguna}. Berikut ringkasan seluruh '
                        'pesanan LaundryKu.',
            ),
          ),
          SliverToBoxAdapter(child: _ringkasanTotal()),
          SliverToBoxAdapter(child: _judul('Pesanan per Status')),
          SliverToBoxAdapter(child: _daftarStatus()),
          SliverToBoxAdapter(child: _judul('Perlu Dikerjakan')),
          ..._isiPerluDikerjakan(),
          const SliverToBoxAdapter(child: SizedBox(height: Jarak.xxl)),
        ],
      ),
    );
  }

  Widget _ringkasanTotal() {
    if (_galat != null) {
      return Padding(
        padding: const EdgeInsets.all(Jarak.xl),
        child: TampilanGagal(
          pesan: _galat!,
          judul: 'Data pesanan tidak bisa dimuat',
          onCobaLagi: muatUlang,
          ringkas: true,
        ),
      );
    }

    final int aktif = _semua.where((Pesanan p) => p.status.masihAktif).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.xl, 0),
      child: Container(
        padding: const EdgeInsets.all(Jarak.lg),
        decoration: BoxDecoration(
          color: Warna.primary,
          borderRadius: BorderRadius.circular(Sudut.kartu),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _memuat ? 'Memuat data...' : 'Ringkasan pesanan',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: Jarak.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: _angkaBesar('${_semua.length}', 'Total pesanan'),
                ),
                Expanded(child: _angkaBesar('$aktif', 'Masih berjalan')),
                Expanded(
                  child: _angkaBesar(
                    '${_jumlah(StatusPesanan.selesai)}',
                    'Selesai',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _angkaBesar(String angka, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          angka,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
      ],
    );
  }

  Widget _judul(String teks) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.xl, Jarak.xl, Jarak.md),
      child: Text(
        teks,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Warna.teksUtama,
        ),
      ),
    );
  }

  Widget _daftarStatus() {
    // Enam status ditampilkan berpasangan supaya tidak jadi kolom panjang,
    // dan masing-masing bisa diklik untuk membuka daftar tersaring.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Jarak.xl),
      child: Wrap(
        spacing: Jarak.md,
        runSpacing: Jarak.md,
        children: <Widget>[
          for (final StatusPesanan status in StatusPesanan.values)
            _kotakStatus(status),
        ],
      ),
    );
  }

  Widget _kotakStatus(StatusPesanan status) {
    return InkWell(
      onTap: () => widget.onBukaSemuaPesanan(status),
      borderRadius: BorderRadius.circular(Sudut.kartu),
      child: Container(
        // Lebar dihitung agar dua kotak muat dalam satu baris, dan tetap rapi
        // di layar sempit maupun lebar.
        width: (MediaQuery.sizeOf(context).width - Jarak.xl * 2 - Jarak.md) / 2,
        padding: const EdgeInsets.all(Jarak.lg),
        decoration: BoxDecoration(
          color: Warna.permukaan,
          borderRadius: BorderRadius.circular(Sudut.kartu),
          border: Border.all(color: Warna.garis),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${_jumlah(status)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Warna.teksUtama,
                height: 1.1,
              ),
            ),
            const SizedBox(height: Jarak.md),
            Text(
              status.label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Warna.teksUtama,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _isiPerluDikerjakan() {
    if (_memuat && _semua.isEmpty) {
      return <Widget>[
        const SliverToBoxAdapter(
          child: TampilanMemuat(keterangan: 'Memuat pesanan...', ringkas: true),
        ),
      ];
    }

    if (_galat != null) {
      return const <Widget>[];
    }

    final List<Pesanan> daftar = _perluDikerjakan;

    if (daftar.isEmpty) {
      return <Widget>[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Jarak.xl),
            child: _KotakBersih(),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverList(
        delegate: SliverChildBuilderDelegate((
          BuildContext context,
          int index,
        ) {
          final Pesanan pesanan = daftar[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(Jarak.xl, 0, Jarak.xl, Jarak.md),
            child: KartuPesanan(
              pesanan: pesanan,
              tampilkanPelanggan: true,
              onTap: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DetailPesananScreen(pesananId: pesanan.id),
                    ),
                  )
                  .then((_) => muatUlang()),
            ),
          );
        }, childCount: daftar.length),
      ),
    ];
  }
}

class _KotakBersih extends StatelessWidget {
  const _KotakBersih();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.lg),
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        border: Border.all(color: Warna.garis),
      ),
      child: const Text(
        'Tidak ada pesanan yang menunggu konfirmasi atau siap diambil '
        'saat ini.',
        style: TextStyle(
          fontSize: 13.5,
          color: Warna.teksKedua,
          height: 1.55,
        ),
      ),
    );
  }
}
