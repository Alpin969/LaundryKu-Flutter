import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../models/pesanan.dart';
import '../../models/status_pesanan.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/pesanan_service.dart';
import '../../utils/format.dart';
import '../../widgets/baris_detail.dart';
import '../../widgets/lencana_status.dart';
import '../../widgets/pemilih_foto.dart';
import '../../widgets/pesan_ui.dart';
import '../../widgets/tampilan_status.dart';
import '../admin/isi_berat_screen.dart';
import '../admin/ubah_status_sheet.dart';

/// Detail satu pesanan.
///
/// Halaman ini dipakai pelanggan dan admin. Perbedaannya:
///   - Pelanggan melihat info pesanannya sendiri dan boleh membatalkan
///     pesanannya pada tahap tertentu.
///   - Admin melihat data pelanggan, dan mendapat tombol untuk mengisi berat
///     asli serta mengubah status.
///
/// Yang sama di antara keduanya: harga akhir SELALU berasal dari backend.
class DetailPesananScreen extends StatefulWidget {
  const DetailPesananScreen({
    super.key,
    required this.pesananId,
    this.fotoBelumDiunggah,
  });

  final int pesananId;

  /// Foto yang baru dipilih dan belum terkirim ke server, mis. ketika
  /// pelanggan membuka detail langsung setelah memesan.
  final XFile? fotoBelumDiunggah;

  @override
  State<DetailPesananScreen> createState() => _DetailPesananScreenState();
}

class _DetailPesananScreenState extends State<DetailPesananScreen> {
  final PesananService _pesananService = const PesananService();

  Pesanan? _pesanan;
  XFile? _fotoBaru;
  bool _memuat = true;
  bool _sedangKerja = false;
  String? _galat;

  bool get _admin => AuthService.instance.pengguna?.adalahAdmin ?? false;

  @override
  void initState() {
    super.initState();
    _fotoBaru = widget.fotoBelumDiunggah;
    muatUlang();
  }

  Future<void> muatUlang() async {
    if (mounted) setState(() => _memuat = true);

    try {
      final Pesanan hasil = await _pesananService.detail(widget.pesananId);
      if (!mounted) return;
      setState(() {
        _pesanan = hasil;
        _galat = null;
      });
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() => _galat = kesalahan.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  /// Menjalankan satu tindakan yang mengubah data, lalu memuat ulang.
  ///
  /// Dipusatkan di satu tempat supaya semua tombol menangani keadaan sedang
  /// bekerja, keberhasilan, dan kegagalan dengan cara yang sama.
  Future<void> _kerjakan(
    Future<void> Function() aksi, {
    required String pesanSukses,
  }) async {
    setState(() => _sedangKerja = true);

    try {
      await aksi();
      if (!mounted) return;
      tampilkanPesan(context, pesanSukses, jenis: JenisPesan.sukses);
      await muatUlang();
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      // Pesan dari backend dipakai apa adanya: penjelasannya sudah spesifik,
      // mis. alasan sebuah perpindahan status tidak diizinkan.
      tampilkanPesan(context, kesalahan.pesan, jenis: JenisPesan.gagal);
    } catch (_) {
      if (!mounted) return;
      tampilkanPesan(
        context,
        'Tindakan gagal diproses. Coba lagi.',
        jenis: JenisPesan.gagal,
      );
    } finally {
      if (mounted) setState(() => _sedangKerja = false);
    }
  }

  Future<void> _pilihFoto() async {
    final XFile? berkas = await ambilFoto(context);
    if (berkas == null || !mounted) return;

    setState(() => _fotoBaru = berkas);

    final Pesanan? pesanan = _pesanan;
    if (pesanan == null) return;

    // Pesanan sudah ada, jadi foto bisa langsung dikirim. Bila pelanggan
    // sudah punya foto lama, backend akan menghapus berkas lamanya sendiri.
    await _kerjakan(
      () async {
        await _pesananService.unggahFoto(
          orderId: pesanan.id,
          foto: berkas,
        );
      },
      pesanSukses: 'Foto pesanan berhasil diunggah.',
    );

    if (mounted) setState(() => _fotoBaru = null);
  }

  Future<void> _batalkan() async {
    final Pesanan? pesanan = _pesanan;
    if (pesanan == null) return;

    final bool setuju = await konfirmasi(
      context,
      judul: 'Batalkan pesanan?',
      pesan:
          'Pesanan #${pesanan.id} akan dibatalkan dan tidak diproses lagi. '
          'Tindakan ini tidak bisa dibatalkan.',
      labelLanjut: 'Ya, Batalkan',
      berbahaya: true,
    );

    if (!setuju || !mounted) return;

    await _kerjakan(
      () async => _pesananService.batalkan(pesanan.id),
      pesanSukses: 'Pesanan berhasil dibatalkan.',
    );
  }

  Future<void> _bukaIsiBerat() async {
    final Pesanan? pesanan = _pesanan;
    if (pesanan == null) return;

    final bool? berubah = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => IsiBeratScreen(pesanan: pesanan),
      ),
    );

    if (berubah == true && mounted) await muatUlang();
  }

  Future<void> _bukaUbahStatus() async {
    final Pesanan? pesanan = _pesanan;
    if (pesanan == null) return;

    final StatusPesanan? tujuan = await showModalBottomSheet<StatusPesanan>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UbahStatusSheet(pesanan: pesanan),
    );

    if (tujuan == null || !mounted) return;

    await _kerjakan(
      () async => _pesananService.ubahStatus(
        orderId: pesanan.id,
        status: tujuan,
      ),
      pesanSukses: 'Status pesanan diubah menjadi ${tujuan.label}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pesanan == null
              ? 'Detail Pesanan'
              : 'Pesanan #${_pesanan!.id}',
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _memuat ? null : muatUlang,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isi(),
    );
  }

  Widget _isi() {
    if (_memuat && _pesanan == null) {
      return const TampilanMemuat(keterangan: 'Memuat detail pesanan...');
    }

    final Pesanan? pesanan = _pesanan;

    if (pesanan == null) {
      return TampilanGagal(
        pesan: _galat ?? 'Pesanan tidak ditemukan.',
        judul: 'Pesanan tidak bisa dibuka',
        onCobaLagi: muatUlang,
      );
    }

    return RefreshIndicator(
      onRefresh: muatUlang,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Jarak.xl),
        children: <Widget>[
          _kepalaStatus(pesanan),
          const SizedBox(height: Jarak.xl),

          _bagianStatus(pesanan),
          const SizedBox(height: Jarak.xl),

          _bagianFoto(pesanan),
          const SizedBox(height: Jarak.xl),

          _bagianPesanan(pesanan),
          const SizedBox(height: Jarak.xl),

          _bagianBiaya(pesanan),

          if (_admin) ...<Widget>[
            const SizedBox(height: Jarak.xl),
            _bagianPelanggan(pesanan),
          ],

          const SizedBox(height: Jarak.xl),
          _tindakan(pesanan),
          const SizedBox(height: Jarak.lg),
        ],
      ),
    );
  }

  Widget _kepalaStatus(Pesanan pesanan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pesanan.namaLayanan,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Warna.teksUtama,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: Jarak.xs),
              Text(
                'Dibuat ${formatTanggalLengkap(pesanan.dibuatPada)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Warna.teksKedua,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Jarak.md),
        LencanaStatus(status: pesanan.status),
      ],
    );
  }

  Widget _bagianStatus(Pesanan pesanan) {
    return KartuBagian(
      judul: 'Status Pesanan',
      ikon: Icons.timeline_rounded,
      anak: TahapanPesanan(status: pesanan.status),
    );
  }

  Widget _bagianFoto(Pesanan pesanan) {
    // Pesanan yang sudah selesai atau dibatalkan tidak perlu diubah fotonya.
    final bool bolehUbahFoto = !pesanan.status.sudahFinal;

    return KartuBagian(
      judul: 'Foto Pakaian',
      ikon: Icons.photo_camera_rounded,
      anak: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PemilihFoto(
            fotoTerpilih: _fotoBaru,
            alamatFotoTersimpan: pesanan.alamatFoto,
            nonaktif: _sedangKerja || !bolehUbahFoto,
            onPilih: _pilihFoto,
            onHapus: () => _hapusFoto(pesanan),
          ),
          if (!pesanan.adaFoto && _fotoBaru == null) ...<Widget>[
            const SizedBox(height: Jarak.md),
            Text(
              bolehUbahFoto
                  ? keteranganBatasFoto()
                  : 'Pesanan ini sudah selesai, jadi fotonya tidak bisa diubah '
                        'lagi.',
              style: const TextStyle(
                fontSize: 12,
                color: Warna.teksSamar,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _hapusFoto(Pesanan pesanan) async {
    // Foto yang baru dipilih dan belum terkirim cukup dibuang dari sini.
    if (_fotoBaru != null && !pesanan.adaFoto) {
      setState(() => _fotoBaru = null);
      tampilkanPesan(context, 'Pilihan foto dibatalkan.');
      return;
    }

    if (!pesanan.adaFoto) return;

    final bool setuju = await konfirmasi(
      context,
      judul: 'Hapus foto pesanan?',
      pesan:
          'Foto pakaian pada pesanan #${pesanan.id} akan dihapus. '
          'Anda tetap bisa mengunggah foto baru setelahnya.',
      labelLanjut: 'Hapus',
      berbahaya: true,
    );

    if (!setuju || !mounted) return;

    setState(() => _fotoBaru = null);

    await _kerjakan(
      () async {
        await _pesananService.hapusFoto(pesanan.id);
      },
      pesanSukses: 'Foto pesanan berhasil dihapus.',
    );
  }

  Widget _bagianPesanan(Pesanan pesanan) {
    return KartuBagian(
      judul: 'Rincian Pesanan',
      ikon: Icons.receipt_long_rounded,
      anak: Column(
        children: <Widget>[
          BarisDetail(label: 'ID Pesanan', nilai: '#${pesanan.id}'),
          const SizedBox(height: Jarak.sm),
          BarisDetail(label: 'Layanan', nilai: pesanan.namaLayanan),
          const SizedBox(height: Jarak.sm),
          BarisDetail(
            label: 'Estimasi pengerjaan',
            nilai: pesanan.durasiLayanan,
          ),
          const SizedBox(height: Jarak.sm),
          BarisDetail(
            label: 'Berat perkiraan',
            nilai: formatBerat(pesanan.beratPerkiraan),
          ),
          const SizedBox(height: Jarak.sm),
          BarisDetail(
            label: 'Berat aktual',
            nilai: pesanan.beratAktual == null
                ? 'Belum ditimbang'
                : formatBerat(pesanan.beratAktual),
          ),
        ],
      ),
    );
  }

  Widget _bagianBiaya(Pesanan pesanan) {
    return KartuBagian(
      judul: 'Biaya',
      ikon: Icons.payments_rounded,
      anak: Column(
        children: <Widget>[
          BarisDetail(
            label: 'Harga per kg',
            nilai: formatRupiah(pesanan.hargaPerKg),
          ),
          const SizedBox(height: Jarak.sm),
          BarisDetail(
            label: 'Total biaya',
            nilai: pesanan.hargaSudahFinal
                ? formatRupiah(pesanan.totalHarga)
                : 'Menunggu berat aktual',
            tebal: true,
            warnaLatar: pesanan.hargaSudahFinal ? Warna.aksenLembut : null,
          ),
          if (!pesanan.hargaSudahFinal) ...<Widget>[
            const SizedBox(height: Jarak.md),
            const Text(
              'Total biaya baru muncul setelah petugas menimbang pakaian '
              'Anda dan mengisi berat aktualnya.',
              style: TextStyle(
                fontSize: 12,
                color: Warna.teksSamar,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bagianPelanggan(Pesanan pesanan) {
    return KartuBagian(
      judul: 'Pelanggan',
      ikon: Icons.person_rounded,
      anak: Column(
        children: <Widget>[
          BarisDetail(label: 'Nama', nilai: pesanan.namaPelanggan),
          const SizedBox(height: Jarak.sm),
          BarisDetail(label: 'Email', nilai: pesanan.emailPelanggan),
        ],
      ),
    );
  }

  Widget _tindakan(Pesanan pesanan) {
    final List<Widget> tombol = <Widget>[];

    if (_admin) {
      // Admin: yang paling sering dibutuhkan adalah mengisi berat dan
      // memindahkan status.
      if (!pesanan.status.sudahFinal) {
        tombol.add(
          FilledButton.icon(
            onPressed: _sedangKerja ? null : _bukaIsiBerat,
            icon: const Icon(Icons.scale_rounded, size: 20),
            label: Text(
              pesanan.beratAktual == null
                  ? 'Isi Berat Aktual'
                  : 'Ubah Berat Aktual',
            ),
          ),
        );
      }

      if (pesanan.status.berikutnya.isNotEmpty) {
        if (tombol.isNotEmpty) tombol.add(const SizedBox(height: Jarak.md));
        tombol.add(
          OutlinedButton.icon(
            onPressed: _sedangKerja ? null : _bukaUbahStatus,
            icon: const Icon(Icons.sync_alt_rounded, size: 20),
            label: const Text('Ubah Status Pesanan'),
          ),
        );
      }
    } else {
      // Pelanggan: hanya boleh membatalkan, dan hanya pada tahap tertentu.
      if (pesanan.status.bolehDibatalkanCustomer) {
        tombol.add(
          OutlinedButton.icon(
            onPressed: _sedangKerja ? null : _batalkan,
            style: OutlinedButton.styleFrom(foregroundColor: Warna.bahaya),
            icon: const Icon(Icons.cancel_outlined, size: 20),
            label: const Text('Batalkan Pesanan'),
          ),
        );
      } else if (!pesanan.status.sudahFinal) {
        tombol.add(
          Container(
            padding: const EdgeInsets.all(Jarak.lg),
            decoration: BoxDecoration(
              color: Warna.aksenLembut,
              borderRadius: BorderRadius.circular(Sudut.kartu),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, size: 20, color: Warna.primary),
                SizedBox(width: Jarak.md),
                Expanded(
                  child: Text(
                    'Pesanan yang sudah masuk proses pencucian tidak bisa '
                    'dibatalkan sendiri. Hubungi admin bila perlu '
                    'dibatalkan.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Warna.primaryGelap,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (tombol.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(children: tombol);
  }
}

/// Membuka halaman detail pesanan.
///
/// [fotoBelumDiunggah] dipakai ketika pelanggan membuka detail langsung setelah
/// memesan, supaya foto yang baru dipilih ikut terlihat.
Future<void> bukaDetailPesanan(
  BuildContext context,
  int pesananId, {
  XFile? fotoBelumDiunggah,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DetailPesananScreen(
        pesananId: pesananId,
        fotoBelumDiunggah: fotoBelumDiunggah,
      ),
    ),
  );
}
