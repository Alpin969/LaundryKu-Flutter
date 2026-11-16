import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../services/api_client.dart';
import '../../services/layanan_service.dart';
import '../../widgets/kartu_layanan.dart';
import '../../widgets/tampilan_status.dart';
import 'detail_layanan_screen.dart';

/// Daftar layanan laundry.
///
/// Halaman ini bisa dibuka tanpa login (endpoint layanan memang terbuka),
/// tetapi di dalam aplikasi selalu terbuka dari tab pelanggan maupun admin.
///
/// [memilihLayanan] membedakan dua pemakaian:
///   - true  : dipakai sebagai langkah pertama pemesanan, judul menyebut
///             "pilih layanan".
///   - false : dipakai untuk melihat daftar layanan saja.
class DaftarLayananScreen extends StatefulWidget {
  const DaftarLayananScreen({super.key, this.memilihLayanan = false});

  final bool memilihLayanan;

  @override
  State<DaftarLayananScreen> createState() => _DaftarLayananScreenState();
}

class _DaftarLayananScreenState extends State<DaftarLayananScreen> {
  final LayananService _layananService = const LayananService();
  final TextEditingController _pencarian = TextEditingController();

  List<Layanan> _layanan = <Layanan>[];
  bool _memuat = true;
  String? _galat;

  @override
  void initState() {
    super.initState();
    muatUlang();
    _pencarian.addListener(_saring);
  }

  @override
  void dispose() {
    _pencarian.removeListener(_saring);
    _pencarian.dispose();
    super.dispose();
  }

  /// Pencarian dilakukan di sisi aplikasi supaya daftar tidak berkedip setiap
  /// kali pengguna mengetik. Backend tetap menyediakan `?search=`.
  void _saring() => setState(() {});

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

  List<Layanan> get _layananTersaring {
    final String kataKunci = _pencarian.text.trim().toLowerCase();
    if (kataKunci.isEmpty) return _layanan;

    return _layanan
        .where(
          (Layanan l) =>
              l.nama.toLowerCase().contains(kataKunci) ||
              (l.deskripsi ?? '').toLowerCase().contains(kataKunci),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.memilihLayanan ? 'Pilih Layanan' : 'Daftar Layanan',
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.xl, 0),
            child: TextField(
              controller: _pencarian,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari layanan...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _pencarian.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => _pencarian.clear(),
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(child: _isi()),
        ],
      ),
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

    if (_layanan.isEmpty) {
      return const TampilanKosong(
        judul: 'Belum ada layanan',
        pesan:
            'Admin belum menambahkan layanan laundry. Coba lagi beberapa saat '
            'lagi.',
        ikon: Icons.local_laundry_service_rounded,
      );
    }

    final List<Layanan> tampil = _layananTersaring;

    if (tampil.isEmpty) {
      return TampilanKosong(
        judul: 'Layanan tidak ditemukan',
        pesan:
            'Tidak ada layanan yang cocok dengan "${_pencarian.text.trim()}". '
            'Coba kata kunci lain.',
        ikon: Icons.search_off_rounded,
        labelTombol: 'Hapus pencarian',
        onTombol: () => _pencarian.clear(),
      );
    }

    return RefreshIndicator(
      onRefresh: muatUlang,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Jarak.xl),
        itemCount: tampil.length,
        separatorBuilder: (_, _) => const SizedBox(height: Jarak.md),
        itemBuilder: (BuildContext context, int index) {
          final Layanan layanan = tampil[index];

          return KartuLayanan(
            layanan: layanan,
            onTap: () => Navigator.of(context)
                .push(
                  MaterialPageRoute<void>(
                    builder: (_) => DetailLayananScreen(layanan: layanan),
                  ),
                )
                .then((_) => muatUlang()),
          );
        },
      ),
    );
  }
}
