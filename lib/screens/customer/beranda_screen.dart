import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../services/api_client.dart';
import '../../services/keranjang_service.dart';
import '../../services/layanan_service.dart';
import '../../widgets/kartu_layanan.dart';
import '../../widgets/tampilan_status.dart';
import 'detail_layanan_screen.dart';
import 'keranjang_screen.dart';

/// Sapaan sesuai waktu di perangkat pengguna.
String sapaanSekarang() {
  final int jam = DateTime.now().hour;
  if (jam < 11) return 'Selamat pagi';
  if (jam < 15) return 'Selamat siang';
  if (jam < 19) return 'Selamat sore';
  return 'Selamat malam';
}

/// Beranda pelanggan.
///
/// Isinya sapaan, pintu masuk keranjang di pojok kanan atas, dan daftar
/// layanan laundry beserta harganya. Pesanan yang sudah dibuat tidak
/// ditampilkan di sini karena sudah punya tabnya sendiri (Pesanan dan
/// Riwayat).
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key, required this.namaPengguna});

  final String namaPengguna;

  @override
  State<BerandaScreen> createState() => BerandaScreenState();
}

class BerandaScreenState extends State<BerandaScreen> {
  final LayananService _layananService = const LayananService();

  List<Layanan> _layanan = <Layanan>[];
  bool _memuat = true;
  String? _galatLayanan;

  @override
  void initState() {
    super.initState();
    muatUlang();
  }

  /// Dipanggil penyegar otomatis saat tab ini aktif.
  ///
  /// [senyap] dipakai penyegaran latar: penanda memuat tidak ditampilkan dan
  /// data lama tetap di layar sampai data baru siap, supaya isi tab tidak
  /// berkedip setiap kali disegarkan.
  Future<void> muatUlang({bool senyap = false}) async {
    if (mounted && !senyap) setState(() => _memuat = true);

    try {
      final List<Layanan> layanan = await _layananService.daftarSemua();
      if (!mounted) return;
      setState(() {
        _layanan = layanan;
        _galatLayanan = null;
      });
    } on ApiException catch (kesalahan) {
      if (!mounted) return;

      // Satu permintaan latar yang gagal tidak perlu mengganti layanan yang
      // sudah tampil dengan layar galat.
      if (senyap && _layanan.isNotEmpty) return;

      setState(() {
        _layanan = <Layanan>[];
        _galatLayanan = kesalahan.pesan;
      });
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: muatUlang,
      child: CustomScrollView(
        // Selalu bisa digulir supaya tarik-untuk-menyegarkan tetap bekerja
        // walaupun isinya masih pendek.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(child: _kepala()),
          SliverToBoxAdapter(child: _judulLayanan()),
          SliverToBoxAdapter(child: _isiLayanan()),
          const SliverToBoxAdapter(child: SizedBox(height: Jarak.xxl)),
        ],
      ),
    );
  }

  /// Kepala beranda: sapaan di kiri, pintu masuk keranjang di kanan.
  Widget _kepala() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.md, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${sapaanSekarang()},',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Warna.teksKedua,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.namaPengguna.isEmpty
                      ? 'Pelanggan'
                      : widget.namaPengguna,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Warna.teksUtama,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          _tombolKeranjang(),
        ],
      ),
    );
  }

  /// Pintu masuk keranjang di pojok kanan atas.
  ///
  /// Jumlah layanan yang menunggu dibayar ditampilkan sebagai angka pada
  /// lencana, bukan sebagai kalimat, supaya kepala beranda tetap ringkas.
  Widget _tombolKeranjang() {
    return ListenableBuilder(
      listenable: KeranjangService.instance,
      builder: (BuildContext context, Widget? _) {
        final int jumlah = KeranjangService.instance.jumlah;

        return IconButton(
          onPressed: _bukaKeranjang,
          tooltip: 'Keranjang',
          icon: Badge(
            isLabelVisible: jumlah > 0,
            label: Text('$jumlah'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }

  Future<void> _bukaKeranjang() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const KeranjangScreen()),
    );
  }

  /// Layanan ditampilkan langsung di beranda supaya pelanggan bisa melihat
  /// harga tanpa harus membuka halaman lain lebih dulu.
  ///
  /// Backend belum menyediakan urutan berdasarkan jumlah pemesanan, jadi
  /// urutan di sini bukan peringkat popularitas.
  Widget _judulLayanan() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(Jarak.xl, Jarak.xl, Jarak.xl, Jarak.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Layanan Laundry',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Warna.teksUtama,
            ),
          ),
          SizedBox(height: Jarak.xs),
          Text(
            'Harga per kilogram dan estimasi pengerjaan yang berlaku '
            'di LaundryKu.',
            style: TextStyle(
              fontSize: 13,
              color: Warna.teksKedua,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _isiLayanan() {
    if (_galatLayanan != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Jarak.xl),
        child: TampilanGagal(
          pesan: _galatLayanan!,
          judul: 'Daftar layanan tidak bisa dimuat',
          onCobaLagi: muatUlang,
          ringkas: true,
        ),
      );
    }

    if (_memuat && _layanan.isEmpty) {
      return const TampilanMemuat(
        keterangan: 'Memuat layanan...',
        ringkas: true,
      );
    }

    if (_layanan.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Jarak.xl),
        child: Container(
          padding: const EdgeInsets.all(Jarak.lg),
          decoration: BoxDecoration(
            color: Warna.permukaan,
            borderRadius: BorderRadius.circular(Sudut.kartu),
            border: Border.all(color: Warna.garis),
          ),
          child: const Text(
            'Belum ada layanan yang bisa dipesan. Admin belum menambahkan '
            'layanan laundry.',
            style: TextStyle(fontSize: 13.5, color: Warna.teksKedua),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final Layanan layanan in _layanan)
          Padding(
            padding: const EdgeInsets.fromLTRB(Jarak.xl, 0, Jarak.xl, Jarak.md),
            child: KartuLayanan(
              layanan: layanan,
              onTap: () => _bukaDetailLayanan(layanan),
            ),
          ),
      ],
    );
  }

  Future<void> _bukaDetailLayanan(Layanan layanan) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailLayananScreen(layanan: layanan),
      ),
    );
  }
}
