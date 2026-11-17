import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../models/pesanan.dart';
import '../../models/status_pesanan.dart';
import '../../services/api_client.dart';
import '../../services/layanan_service.dart';
import '../../services/pesanan_service.dart';
import '../../widgets/kartu_layanan.dart';
import '../../widgets/kartu_pesanan.dart';
import '../../widgets/tampilan_status.dart';
import 'daftar_layanan_screen.dart';
import 'detail_layanan_screen.dart';
import 'detail_pesanan_screen.dart';
import 'form_pemesanan_screen.dart';

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
/// Isinya diarahkan pada satu pertanyaan: apa yang perlu saya lakukan
/// sekarang? Karena itu pesanan yang sedang berjalan ditaruh paling atas dan
/// tombol memesan selalu tersedia.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key, required this.namaPengguna});

  final String namaPengguna;

  @override
  State<BerandaScreen> createState() => BerandaScreenState();
}

class BerandaScreenState extends State<BerandaScreen> {
  final PesananService _pesananService = const PesananService();
  final LayananService _layananService = const LayananService();

  List<Pesanan> _pesananAktif = <Pesanan>[];
  List<Layanan> _layanan = <Layanan>[];
  bool _memuat = true;
  String? _galat;
  String? _galatLayanan;

  @override
  void initState() {
    super.initState();
    muatUlang();
  }

  /// Dipanggil kerangka navigasi ketika tab ini perlu menampilkan data
  /// terbaru, mis. setelah pelanggan membuat pesanan baru.
  Future<void> muatUlang() async {
    if (mounted) setState(() => _memuat = true);

    try {
      final List<Pesanan> hasil = await _pesananService.daftarBanyakStatus(
        StatusPesanan.semuaAktif,
      );
      if (!mounted) return;
      setState(() {
        _pesananAktif = hasil;
        _galat = null;
      });
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() => _galat = kesalahan.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }

    // Layanan dimuat terpisah dari pesanan: kegagalannya tidak boleh
    // menyembunyikan pesanan aktif yang sudah berhasil ditampilkan.
    try {
      final List<Layanan> layanan = await _layananService.daftarSemua();
      if (!mounted) return;
      setState(() {
        _layanan = layanan;
        _galatLayanan = null;
      });
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() {
        _layanan = <Layanan>[];
        _galatLayanan = kesalahan.pesan;
      });
    }
  }

  int _jumlah(StatusPesanan status) =>
      _pesananAktif.where((Pesanan p) => p.status == status).length;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: muatUlang,
      child: CustomScrollView(
        // Selalu bisa digulir supaya tarik-untuk-menyegarkan tetap bekerja
        // walaupun isinya masih pendek.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(child: _sapaan()),
          SliverToBoxAdapter(child: _ringkasan()),
          SliverToBoxAdapter(child: _aksiCepat()),
          SliverToBoxAdapter(child: _judulLayanan()),
          SliverToBoxAdapter(child: _isiLayanan()),
          SliverToBoxAdapter(child: _judulPesananAktif()),
          ..._isiPesananAktif(),
          SliverToBoxAdapter(child: _judulStatus()),
          SliverToBoxAdapter(child: _daftarStatus()),
          const SliverToBoxAdapter(child: SizedBox(height: Jarak.xxl)),
        ],
      ),
    );
  }

  Widget _sapaan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${sapaanSekarang()},',
            style: const TextStyle(fontSize: 13.5, color: Warna.teksKedua),
          ),
          const SizedBox(height: 2),
          Text(
            widget.namaPengguna.isEmpty ? 'Pelanggan' : widget.namaPengguna,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Warna.teksUtama,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ringkasan() {
    if (_galat != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Jarak.xl,
          Jarak.lg,
          Jarak.xl,
          0,
        ),
        child: TampilanGagal(
          pesan: _galat!,
          judul: 'Pesanan tidak bisa dimuat',
          onCobaLagi: muatUlang,
          ringkas: true,
        ),
      );
    }

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
            Row(
              children: <Widget>[
                const Icon(
                  Icons.local_laundry_service_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: Jarak.sm),
                Text(
                  _memuat
                      ? 'Memuat pesanan...'
                      : '${_pesananAktif.length} pesanan aktif',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (!_memuat && _pesananAktif.isNotEmpty) ...<Widget>[
              const SizedBox(height: Jarak.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _kotakStatistik(
                      'Menunggu',
                      _jumlah(StatusPesanan.menungguKonfirmasi),
                    ),
                  ),
                  Expanded(
                    child: _kotakStatistik(
                      'Diproses',
                      _jumlah(StatusPesanan.dikonfirmasi) +
                          _jumlah(StatusPesanan.sedangDicuci),
                    ),
                  ),
                  Expanded(
                    child: _kotakStatistik(
                      'Siap Diambil',
                      _jumlah(StatusPesanan.siapDiambil),
                    ),
                  ),
                ],
              ),
            ] else if (!_memuat) ...<Widget>[
              const SizedBox(height: Jarak.sm),
              Text(
                'Belum ada pesanan yang sedang berjalan. Tekan tombol Pesan '
                'Laundry untuk membuat pesanan pertama Anda.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.55,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kotakStatistik(String label, int jumlah) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$jumlah',
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

  /// Dua tindakan utama: memesan, dan melihat daftar layanan beserta harganya.
  Widget _aksiCepat() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.xl, 0),
      child: Column(
        children: <Widget>[
          FilledButton.icon(
            onPressed: _pesanLaundry,
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
            label: const Text('Pesan Laundry'),
          ),
          const SizedBox(height: Jarak.md),
          OutlinedButton.icon(
            onPressed: _lihatLayanan,
            icon: const Icon(Icons.list_alt_rounded, size: 20),
            label: const Text('Lihat Daftar Layanan'),
          ),
        ],
      ),
    );
  }

  Future<void> _pesanLaundry() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FormPemesananScreen()),
    );
    await muatUlang();
  }

  Future<void> _lihatLayanan() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DaftarLayananScreen(memilihLayanan: true),
      ),
    );
    await muatUlang();
  }

  /// Layanan ditampilkan langsung di beranda supaya pelanggan bisa melihat
  /// harga tanpa harus membuka halaman lain lebih dulu.
  ///
  /// Backend belum menyediakan data layanan mana yang paling banyak dipesan,
  /// jadi urutan di sini bukan peringkat popularitas.
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
          child: const Row(
            children: <Widget>[
              Icon(
                Icons.local_laundry_service_outlined,
                size: 22,
                color: Warna.teksSamar,
              ),
              SizedBox(width: Jarak.md),
              Expanded(
                child: Text(
                  'Belum ada layanan yang bisa dipesan. Coba muat ulang '
                  'sebentar lagi.',
                  style: TextStyle(fontSize: 13.5, color: Warna.teksKedua),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Dua layanan saja di beranda; daftar lengkapnya ada di halaman layanan.
    final List<Layanan> tampil = _layanan.take(2).toList();

    return Column(
      children: <Widget>[
        for (final Layanan layanan in tampil)
          Padding(
            padding: const EdgeInsets.fromLTRB(Jarak.xl, 0, Jarak.xl, Jarak.md),
            child: KartuLayanan(
              layanan: layanan,
              onTap: () => _bukaDetailLayanan(layanan),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Jarak.xl),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _lihatLayanan,
              icon: const Icon(Icons.list_alt_rounded, size: 20),
              label: Text(
                _layanan.length > tampil.length
                    ? 'Lihat semua layanan (${_layanan.length})'
                    : 'Lihat halaman layanan',
              ),
            ),
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

  Widget _judulPesananAktif() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.xl, Jarak.xl, Jarak.md),
      child: const Text(
        'Pesanan Aktif',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Warna.teksUtama,
        ),
      ),
    );
  }

  Widget _judulStatus() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(Jarak.xl, Jarak.xl, Jarak.xl, Jarak.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Status Pesanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Warna.teksUtama,
            ),
          ),
          SizedBox(height: Jarak.xs),
          Text(
            'Enam tahapan yang dilalui pesanan Anda di LaundryKu.',
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

  List<Widget> _isiPesananAktif() {
    if (_memuat && _pesananAktif.isEmpty) {
      return <Widget>[
        const SliverToBoxAdapter(
          child: TampilanMemuat(keterangan: 'Memuat pesanan...', ringkas: true),
        ),
      ];
    }

    // Galat sudah ditampilkan pada ringkasan di atas, tidak perlu diulang.
    if (_galat != null) return const <Widget>[];

    if (_pesananAktif.isEmpty) {
      return <Widget>[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Jarak.xl),
            child: _KotakKosongPesanan(),
          ),
        ),
      ];
    }

    // Hanya tiga pesanan terbaru di beranda; sisanya ada di tab Pesanan.
    final List<Pesanan> tampil = _pesananAktif.take(3).toList();

    return <Widget>[
      SliverList(
        delegate: SliverChildBuilderDelegate((
          BuildContext context,
          int index,
        ) {
          final Pesanan pesanan = tampil[index];

          return Padding(
            padding: const EdgeInsets.fromLTRB(Jarak.xl, 0, Jarak.xl, Jarak.md),
            child: KartuPesanan(
              pesanan: pesanan,
              onTap: () => bukaDetailPesanan(
                context,
                pesanan.id,
              ).then((_) => muatUlang()),
            ),
          );
        }, childCount: tampil.length),
      ),
    ];
  }

  Widget _daftarStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Jarak.xl),
      child: Container(
        decoration: BoxDecoration(
          color: Warna.permukaan,
          borderRadius: BorderRadius.circular(Sudut.kartu),
          border: Border.all(color: Warna.garis),
        ),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < StatusPesanan.values.length; i++) ...<Widget>[
              _barisStatus(StatusPesanan.values[i]),
              if (i < StatusPesanan.values.length - 1)
                const Divider(height: 1, color: Warna.garis),
            ],
          ],
        ),
      ),
    );
  }

  Widget _barisStatus(StatusPesanan status) {
    return Padding(
      padding: const EdgeInsets.all(Jarak.lg),
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
                  status.label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Warna.teksUtama,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.keterangan,
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
    );
  }
}

class _KotakKosongPesanan extends StatelessWidget {
  const _KotakKosongPesanan();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Jarak.lg),
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        border: Border.all(color: Warna.garis),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.inbox_rounded, size: 22, color: Warna.teksSamar),
          SizedBox(width: Jarak.md),
          Expanded(
            child: Text(
              'Tidak ada pesanan aktif saat ini.',
              style: TextStyle(fontSize: 13.5, color: Warna.teksKedua),
            ),
          ),
        ],
      ),
    );
  }
}
