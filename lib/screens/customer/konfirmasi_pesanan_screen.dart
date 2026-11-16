import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../models/pesanan.dart';
import '../../services/api_client.dart';
import '../../services/pesanan_service.dart';import '../../utils/format.dart';
import '../../widgets/pesan_ui.dart';
import '../../widgets/pratinjau_foto_lokal.dart';
import 'detail_pesanan_screen.dart';
/// Konfirmasi sebelum pesanan benar-benar dikirim ke server.
///
/// Di sinilah satu-satunya permintaan pembuatan pesanan dilakukan
/// (`POST /api/orders`). Bila pelanggan melampirkan foto, foto itu langsung
/// diunggah ke pesanan yang baru dibuat.
class KonfirmasiPesananScreen extends StatefulWidget {
  const KonfirmasiPesananScreen({
    super.key,
    required this.layanan,
    required this.beratPerkiraan,
    this.foto,
  });

  final Layanan layanan;
  final double beratPerkiraan;
  final XFile? foto;

  @override
  State<KonfirmasiPesananScreen> createState() => _KonfirmasiPesananScreenState();
}

class _KonfirmasiPesananScreenState extends State<KonfirmasiPesananScreen> {
  final PesananService _pesananService = const PesananService();

  bool _sedangKirim = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(Jarak.xl),
        children: <Widget>[
          const Text(
            'Periksa kembali pesanan Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Warna.teksUtama,
            ),
          ),
          const SizedBox(height: Jarak.xs),
          const Text(
            'Setelah dikirim, pesanan akan menunggu konfirmasi admin.',
            style: TextStyle(
              fontSize: 13.5,
              color: Warna.teksKedua,
              height: 1.55,
            ),
          ),

          const SizedBox(height: Jarak.xl),

          _kartuRingkasan(),

          if (widget.foto != null) ...<Widget>[
            const SizedBox(height: Jarak.xl),
            const Text(
              'Foto yang dilampirkan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Warna.teksUtama,
              ),
            ),
            const SizedBox(height: Jarak.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(Sudut.kartu),
              child: Container(
                color: Warna.aksenLembut,
                width: double.infinity,
                child: PratinjauFotoLokal(
                  foto: widget.foto!,
                  tinggi: 190,
                  keteranganGagal: 'Foto sudah dipilih, siap dikirim.',
                ),
              ),
            ),
            const SizedBox(height: Jarak.sm),
            const Text(
              'Foto akan diunggah setelah pesanan berhasil dibuat.',
              style: TextStyle(fontSize: 12, color: Warna.teksSamar),
            ),
          ],

          const SizedBox(height: Jarak.xl),

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
                    'Total biaya final dihitung admin setelah pakaian '
                    'ditimbang, memakai berat sebenarnya. Pesanan bisa '
                    'dibatalkan selama masih menunggu konfirmasi atau sudah '
                    'dikonfirmasi.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Warna.primaryGelap,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Jarak.xl),

          FilledButton.icon(
            onPressed: _sedangKirim ? null : _kirim,
            icon: _sedangKirim
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(_sedangKirim ? 'Mengirim pesanan...' : 'Buat Pesanan'),
          ),

          const SizedBox(height: Jarak.md),

          OutlinedButton(
            onPressed: _sedangKirim ? null : () => Navigator.of(context).pop(),
            child: const Text('Ubah Pesanan'),
          ),

          const SizedBox(height: Jarak.lg),
        ],
      ),
    );
  }

  Widget _kartuRingkasan() {
    final double perkiraan = widget.beratPerkiraan * widget.layanan.hargaPerKg;

    return Container(
      padding: const EdgeInsets.all(Jarak.lg),
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        border: Border.all(color: Warna.garis),
      ),
      child: Column(
        children: <Widget>[
          _baris('Layanan', widget.layanan.nama),
          const Divider(height: Jarak.xl, color: Warna.garis),
          _baris('Harga per kg', formatRupiah(widget.layanan.hargaPerKg)),
          const Divider(height: Jarak.xl, color: Warna.garis),
          _baris('Estimasi pengerjaan', widget.layanan.durasi),
          const Divider(height: Jarak.xl, color: Warna.garis),
          _baris('Berat perkiraan', formatBerat(widget.beratPerkiraan)),
          const Divider(height: Jarak.xl, color: Warna.garis),
          _baris(
            'Perkiraan biaya',
            formatRupiah(perkiraan),
            tebal: true,
          ),
        ],
      ),
    );
  }

  Widget _baris(String label, String nilai, {bool tebal = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Warna.teksKedua),
          ),
        ),
        const SizedBox(width: Jarak.md),
        Expanded(
          flex: 6,
          child: Text(
            nilai,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: tebal ? 15 : 13.5,
              fontWeight: tebal ? FontWeight.w700 : FontWeight.w600,
              color: tebal ? Warna.primary : Warna.teksUtama,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _kirim() async {
    FocusScope.of(context).unfocus();
    setState(() => _sedangKirim = true);

    // Navigator dan ScaffoldMessenger ditangkap lebih dulu: setelah pesanan
    // dibuat, halaman ini ditutup sehingga context miliknya tidak berlaku lagi.
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    Pesanan pesananBaru;
    String? galatFoto;

    try {
      // Langkah 1: buat pesanannya. Harga tidak ikut dikirim; backend yang
      // mengambilnya dari tabel services.
      pesananBaru = await _pesananService.buat(
        serviceId: widget.layanan.id,
        estimatedWeight: widget.beratPerkiraan,
      );
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() => _sedangKirim = false);
      tampilkanPesan(context, kesalahan.pesan, jenis: JenisPesan.gagal);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _sedangKirim = false);
      tampilkanPesan(
        context,
        'Pesanan gagal dikirim. Periksa koneksi lalu coba lagi.',
        jenis: JenisPesan.gagal,
      );
      return;
    }

    // Langkah 2: unggah foto ke pesanan yang baru dibuat. Kalau langkah ini
    // gagal, pesanannya TIDAK dibatalkan: pesanan sudah sah dibuat, dan foto
    // hanya pelengkap. Pelanggan diberi tahu bahwa fotonya belum terkirim.
    if (widget.foto != null) {
      try {
        pesananBaru = await _pesananService.unggahFoto(
          orderId: pesananBaru.id,
          foto: widget.foto!,
        );
      } on ApiException catch (kesalahan) {
        galatFoto = kesalahan.pesan;
      } catch (_) {
        galatFoto = 'foto gagal dikirim';
      }
    }

    if (mounted) setState(() => _sedangKirim = false);

    // Halaman form dan konfirmasi ditutup, lalu detail pesanan dibuka supaya
    // pelanggan langsung melihat hasilnya.
    navigator.popUntil((Route<dynamic> rute) => rute.isFirst);
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => DetailPesananScreen(pesananId: pesananBaru.id),
      ),
    );

    tampilkanPesanLewat(
      messenger,
      galatFoto == null
          ? 'Pesanan #${pesananBaru.id} berhasil dibuat.'
          : 'Pesanan #${pesananBaru.id} berhasil dibuat, tetapi $galatFoto. '
                'Buka detail pesanan untuk mencoba mengunggah ulang.',
      jenis: galatFoto == null ? JenisPesan.sukses : JenisPesan.info,
    );
  }
}
