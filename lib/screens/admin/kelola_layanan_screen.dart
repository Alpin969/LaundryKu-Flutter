import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../services/api_client.dart';
import '../../services/layanan_service.dart';
import '../../widgets/judul_tab.dart';
import '../../widgets/kartu_layanan.dart';
import '../../widgets/pesan_ui.dart';
import '../../widgets/tampilan_status.dart';
import 'form_layanan_screen.dart';

/// Kelola layanan: daftar, tambah, ubah, dan hapus.
///
/// Layanan yang masih dipakai pada pesanan tidak bisa dihapus. Backend
/// menolaknya dengan pesan yang menjelaskan sebabnya, dan pesan itu
/// ditampilkan apa adanya supaya admin tahu langkah berikutnya.
class KelolaLayananScreen extends StatefulWidget {
  const KelolaLayananScreen({super.key});

  @override
  State<KelolaLayananScreen> createState() => KelolaLayananScreenState();
}

class KelolaLayananScreenState extends State<KelolaLayananScreen> {
  final LayananService _layananService = const LayananService();

  List<Layanan> _layanan = <Layanan>[];
  bool _memuat = true;
  String? _galat;

  /// Menandai layanan yang sedang diproses supaya tombolnya tidak ditekan dua
  /// kali saat menunggu balasan server.
  int? _idSedangDikerjakan;

  @override
  void initState() {
    super.initState();
    muatUlang();
  }

  Future<void> muatUlang() async {
    if (mounted) setState(() => _memuat = true);

    try {
      final List<Layanan> hasil = await _layananService.daftarSemua();
      if (!mounted) return;
      setState(() {
        _layanan = hasil;
        _galat = null;
      });
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() => _galat = kesalahan.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _tambah() async {
    final Layanan? hasil = await Navigator.of(context).push<Layanan>(
      MaterialPageRoute<Layanan>(builder: (_) => const FormLayananScreen()),
    );

    if (hasil == null || !mounted) return;

    setState(() => _idSedangDikerjakan = -1);

    try {
      await _layananService.tambah(hasil);
      if (!mounted) return;
      tampilkanPesan(
        context,
        'Layanan "${hasil.nama}" berhasil ditambahkan.',
        jenis: JenisPesan.sukses,
      );
      await muatUlang();
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      tampilkanPesan(context, kesalahan.pesan, jenis: JenisPesan.gagal);
    } finally {
      if (mounted) setState(() => _idSedangDikerjakan = null);
    }
  }

  Future<void> _ubah(Layanan layanan) async {
    final Layanan? hasil = await Navigator.of(context).push<Layanan>(
      MaterialPageRoute<Layanan>(
        builder: (_) => FormLayananScreen(layanan: layanan),
      ),
    );

    if (hasil == null || !mounted) return;

    setState(() => _idSedangDikerjakan = layanan.id);

    try {
      await _layananService.ubah(hasil);
      if (!mounted) return;
      tampilkanPesan(
        context,
        'Layanan "${hasil.nama}" berhasil diperbarui.',
        jenis: JenisPesan.sukses,
      );
      await muatUlang();
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      tampilkanPesan(context, kesalahan.pesan, jenis: JenisPesan.gagal);
    } finally {
      if (mounted) setState(() => _idSedangDikerjakan = null);
    }
  }

  Future<void> _hapus(Layanan layanan) async {
    final bool setuju = await konfirmasi(
      context,
      judul: 'Hapus layanan?',
      pesan:
          'Layanan "${layanan.nama}" akan dihapus permanen. Layanan yang masih '
          'dipakai pada sebuah pesanan tidak bisa dihapus.',
      labelLanjut: 'Hapus',
      berbahaya: true,
    );

    if (!setuju || !mounted) return;

    setState(() => _idSedangDikerjakan = layanan.id);

    try {
      await _layananService.hapus(layanan.id);
      if (!mounted) return;
      tampilkanPesan(
        context,
        'Layanan "${layanan.nama}" berhasil dihapus.',
        jenis: JenisPesan.sukses,
      );
      await muatUlang();
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      tampilkanPesan(context, kesalahan.pesan, jenis: JenisPesan.gagal);
    } finally {
      if (mounted) setState(() => _idSedangDikerjakan = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        JudulTab(
          judul: 'Kelola Layanan',
          keterangan:
              'Layanan yang tampil di aplikasi pelanggan. Mengubah harga hanya '
              'berlaku untuk pesanan baru.',
          onMuatUlang: muatUlang,
          sedangMemuat: _memuat,
        ),
        Expanded(child: _isi()),
      ],
    );
  }

  Widget _isi() {
    if (_memuat && _layanan.isEmpty) {
      return const TampilanMemuat(keterangan: 'Memuat daftar layanan...');
    }

    if (_galat != null) {
      return TampilanGagal(
        pesan: _galat!,
        judul: 'Daftar layanan gagal dimuat',
        onCobaLagi: muatUlang,
      );
    }

    return RefreshIndicator(
      onRefresh: muatUlang,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(child: _tombolTambah()),
          if (_layanan.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: TampilanKosong(
                judul: 'Belum ada layanan',
                pesan:
                    'Tambahkan layanan pertama supaya pelanggan bisa memesan. '
                    'Isi nama, harga per kg, dan estimasi pengerjaannya.',
                ikon: Icons.local_laundry_service_rounded,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final Layanan layanan = _layanan[index];
                final bool sedangDikerjakan =
                    _idSedangDikerjakan == layanan.id;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Jarak.xl,
                    0,
                    Jarak.xl,
                    Jarak.md,
                  ),
                  child: KartuLayanan(
                    layanan: layanan,
                    aksi: Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _idSedangDikerjakan != null
                                ? null
                                : () => _ubah(layanan),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: Jarak.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _idSedangDikerjakan != null
                                ? null
                                : () => _hapus(layanan),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Warna.bahaya,
                            ),
                            icon: sedangDikerjakan
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                            label: const Text('Hapus'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: _layanan.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: Jarak.xxl)),
        ],
      ),
    );
  }

  Widget _tombolTambah() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, 0, Jarak.xl, Jarak.lg),
      child: FilledButton.icon(
        onPressed: _idSedangDikerjakan != null ? null : _tambah,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Tambah Layanan'),
      ),
    );
  }
}
