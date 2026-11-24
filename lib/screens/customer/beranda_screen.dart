import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/keranjang_service.dart';
import '../../services/layanan_service.dart';
import '../../widgets/app_logo.dart';
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
/// Susunannya dari atas ke bawah: kepala brand dengan pintu masuk keranjang,
/// kartu sambutan, lalu daftar layanan laundry beserta harganya. Pesanan yang
/// sudah dibuat tidak ditampilkan di sini karena sudah punya tabnya sendiri
/// (Pesanan dan Riwayat).
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
          SliverToBoxAdapter(child: _kartuSambutan()),
          SliverToBoxAdapter(child: _judulLayanan()),
          SliverToBoxAdapter(child: _isiLayanan()),
          const SliverToBoxAdapter(child: SizedBox(height: Jarak.xxl)),
        ],
      ),
    );
  }

  /// Kepala beranda: merek di kiri, pintu masuk keranjang di kanan.
  Widget _kepala() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.md, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const AppLogo(ukuran: 36),
          const SizedBox(width: Jarak.sm),
          const Expanded(
            child: Text(
              NamaAplikasi.nama,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Warna.teksUtama,
                letterSpacing: 1.6,
              ),
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
          style: IconButton.styleFrom(
            backgroundColor: jumlah > 0 ? Warna.aksenLembut : null,
          ),
          icon: Badge(
            isLabelVisible: jumlah > 0,
            backgroundColor: Warna.primary,
            label: Text('$jumlah'),
            child: const Icon(Icons.shopping_bag_outlined),
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

  /// Kartu sambutan: nama pelanggan dan janji singkat layanan.
  Widget _kartuSambutan() {
    final String nama = AuthService.instance.pengguna?.nama ?? '';
    final String panggilan = widget.namaPengguna.isNotEmpty
        ? widget.namaPengguna
        : (nama.isNotEmpty ? nama : 'Pelanggan');

    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.xl, 0),
      child: Container(
        padding: const EdgeInsets.all(Jarak.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Warna.primary, Warna.primaryGelap],
          ),
          borderRadius: BorderRadius.circular(Sudut.kartu),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              sapaanSekarang(),
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              panggilan,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.25,
              ),
            ),
            const SizedBox(height: Jarak.md),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            const SizedBox(height: Jarak.md),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.eco_outlined,
                  size: 16,
                  color: Warna.aksen,
                ),
                const SizedBox(width: Jarak.sm),
                Expanded(
                  child: Text(
                    NamaAplikasi.slogan,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
              fontWeight: FontWeight.w700,
              color: Warna.teksUtama,
            ),
          ),
          SizedBox(height: Jarak.xs),
          Text(
            'Harga per kilogram dan estimasi pengerjaan yang berlaku di '
            'RENOVA.',
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
