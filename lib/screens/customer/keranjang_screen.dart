import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../models/metode_pembayaran.dart';
import '../../models/pesanan.dart';
import '../../services/api_client.dart';
import '../../services/keranjang_service.dart';
import '../../services/pesanan_service.dart';
import '../../utils/format.dart';
import '../../utils/validasi.dart';
import '../../widgets/baris_detail.dart';
import '../../widgets/pemilih_foto.dart';
import '../../widgets/pesan_ui.dart';
import '../../widgets/tampilan_status.dart';
import 'daftar_layanan_screen.dart';

/// Keranjang pelanggan: tempat memeriksa pilihan layanan, memilih metode
/// pembayaran, lalu membuat seluruh pesanannya sekaligus.
///
/// Satu layanan di keranjang menjadi satu pesanan. Seluruh pesanan dari
/// keranjang ini memakai satu metode pembayaran yang sama.
class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  final PesananService _pesananService = const PesananService();

  // Tunai dipilih lebih dulu karena metode itu tidak langsung menandai pesanan
  // lunas tanpa diketahui pelanggan.
  MetodePembayaran _metode = MetodePembayaran.tunai;

  bool _sedangKirim = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: ListenableBuilder(
        listenable: KeranjangService.instance,
        builder: (BuildContext context, Widget? _) {
          final KeranjangService keranjang = KeranjangService.instance;

          if (keranjang.kosong) return _keranjangKosong();

          return ListView(
            padding: const EdgeInsets.all(Jarak.xl),
            children: <Widget>[
              Text(
                '${keranjang.jumlah} layanan siap dipesan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Warna.teksUtama,
                ),
              ),
              const SizedBox(height: Jarak.xs),
              const Text(
                'Periksa berat dan fotonya sebelum membayar.',
                style: TextStyle(
                  fontSize: 13,
                  color: Warna.teksKedua,
                  height: 1.55,
                ),
              ),

              const SizedBox(height: Jarak.lg),

              for (final ItemKeranjang item in keranjang.item) ...<Widget>[
                _kartuItem(item),
                const SizedBox(height: Jarak.md),
              ],

              const SizedBox(height: Jarak.sm),
              _judulBagian('Metode pembayaran'),
              const SizedBox(height: Jarak.md),
              _pilihMetode(),
              const SizedBox(height: Jarak.md),
              _catatanMetode(),

              const SizedBox(height: Jarak.xl),
              _ringkasan(keranjang),

              const SizedBox(height: Jarak.xl),

              FilledButton(
                onPressed: _sedangKirim ? null : _pesanDanBayar,
                child: _sedangKirim
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Pesan & Bayar'),
              ),

              const SizedBox(height: Jarak.lg),
            ],
          );
        },
      ),
    );
  }

  Widget _keranjangKosong() {
    return TampilanKosong(
      judul: 'Keranjang masih kosong',
      pesan:
          'Pilih layanan laundry di beranda, isi berat perkiraannya, lalu '
          'simpan ke keranjang. Pesanannya baru dibuat setelah Anda menekan '
          'Pesan & Bayar di halaman ini.',
      labelTombol: 'Lihat Layanan',
      onTombol: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DaftarLayananScreen()),
      ),
    );
  }

  Widget _kartuItem(ItemKeranjang item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.layanan.nama,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Warna.teksUtama,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: Jarak.xs),
                      Text(
                        '${formatRupiah(item.layanan.hargaPerKg)} per kg '
                        '\u2022 estimasi ${item.layanan.durasi}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Warna.teksKedua,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _sedangKirim ? null : () => _keluarkan(item),
                  style: TextButton.styleFrom(foregroundColor: Warna.bahaya),
                  child: const Text('Keluarkan'),
                ),
              ],
            ),

            const Divider(height: Jarak.xl, color: Warna.garis),

            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Berat perkiraan',
                    style: TextStyle(fontSize: 13, color: Warna.teksKedua),
                  ),
                ),
                Text(
                  formatBerat(item.beratPerkiraan),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Warna.teksUtama,
                  ),
                ),
                const SizedBox(width: Jarak.sm),
                TextButton(
                  onPressed: _sedangKirim ? null : () => _ubahBerat(item),
                  child: const Text('Ubah'),
                ),
              ],
            ),

            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Perkiraan biaya',
                    style: TextStyle(fontSize: 13, color: Warna.teksKedua),
                  ),
                ),
                Text(
                  formatRupiah(item.perkiraanBiaya),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Warna.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: Jarak.md),

            PemilihFoto(
              fotoTerpilih: item.foto,
              onPilih: () => _pilihFoto(item),
              onHapus: () => KeranjangService.instance.ubahFoto(item.id, null),
              nonaktif: _sedangKirim,
              tinggiPratinjau: 140,
            ),
          ],
        ),
      ),
    );
  }

  Widget _judulBagian(String judul) {
    return Text(
      judul,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Warna.teksUtama,
      ),
    );
  }

  Widget _pilihMetode() {
    return Container(
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        border: Border.all(color: Warna.garis),
      ),
      child: Column(
        children: <Widget>[
          for (
            int i = 0;
            i < MetodePembayaran.values.length;
            i++
          ) ...<Widget>[
            _barisMetode(MetodePembayaran.values[i]),
            if (i < MetodePembayaran.values.length - 1)
              const Divider(height: 1, color: Warna.garis),
          ],
        ],
      ),
    );
  }

  Widget _barisMetode(MetodePembayaran metode) {
    final bool terpilih = _metode == metode;

    return InkWell(
      onTap: _sedangKirim
          ? null
          : () => setState(() => _metode = metode),
      child: Padding(
        padding: const EdgeInsets.all(Jarak.lg),
        child: Row(
          children: <Widget>[
            // Penanda pilihan, bukan hiasan: bentuknya berubah mengikuti
            // metode yang sedang dipakai.
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: terpilih ? Warna.primary : Warna.permukaan,
                shape: BoxShape.circle,
                border: Border.all(
                  color: terpilih ? Warna.primary : Warna.garis,
                  width: 2,
                ),
              ),
              child: terpilih
                  ? const Center(
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: Jarak.md),
            Expanded(
              child: Text(
                metode.label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: terpilih ? FontWeight.w600 : FontWeight.w500,
                  color: Warna.teksUtama,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catatanMetode() {
    return Container(
      padding: const EdgeInsets.all(Jarak.lg),
      decoration: BoxDecoration(
        color: Warna.aksenLembut,
        borderRadius: BorderRadius.circular(Sudut.kartu),
      ),
      child: Text(
        _metode.keterangan,
        style: const TextStyle(
          fontSize: 12.5,
          color: Warna.primaryGelap,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _ringkasan(KeranjangService keranjang) {
    return KartuBagian(
      judul: 'Ringkasan',
      anak: Column(
        children: <Widget>[
          BarisDetail(label: 'Jumlah layanan', nilai: '${keranjang.jumlah}'),
          const SizedBox(height: Jarak.sm),
          BarisDetail(
            label: 'Perkiraan total',
            nilai: formatRupiah(keranjang.perkiraanTotal),
            tebal: true,
            warnaLatar: Warna.aksenLembut,
          ),
          const SizedBox(height: Jarak.md),
          const Text(
            'Perkiraan ini dihitung dari berat yang Anda isi. Total biaya yang '
            'berlaku dihitung admin setelah pakaian ditimbang.',
            style: TextStyle(
              fontSize: 12,
              color: Warna.teksSamar,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _ubahBerat(ItemKeranjang item) async {
    final double? berat = await showDialog<double>(
      context: context,
      builder: (_) => _DialogUbahBerat(
        namaLayanan: item.layanan.nama,
        beratAwal: item.beratPerkiraan,
      ),
    );

    if (berat == null) return;
    KeranjangService.instance.ubahBerat(item.id, berat);
  }

  Future<void> _pilihFoto(ItemKeranjang item) async {
    final XFile? berkas = await ambilFoto(context);
    if (berkas == null) return;

    KeranjangService.instance.ubahFoto(item.id, berkas);
  }

  Future<void> _keluarkan(ItemKeranjang item) async {
    final bool setuju = await konfirmasi(
      context,
      judul: 'Keluarkan dari keranjang?',
      pesan:
          '${item.layanan.nama} akan dikeluarkan dari keranjang. '
          'Layanan ini tidak jadi dipesan.',
      labelLanjut: 'Keluarkan',
      berbahaya: true,
    );

    if (!setuju) return;
    KeranjangService.instance.hapus(item.id);
  }

  Future<void> _pesanDanBayar() async {
    FocusScope.of(context).unfocus();
    setState(() => _sedangKirim = true);

    // Navigator dan ScaffoldMessenger ditangkap lebih dulu: halaman ini ditutup
    // setelah seluruh pesanan dibuat, sehingga context miliknya tidak berlaku.
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final KeranjangService keranjang = KeranjangService.instance;

    // Disalin dulu karena isi keranjang berubah selama proses berjalan.
    final List<ItemKeranjang> antrean = keranjang.item;

    final List<String> gagal = <String>[];
    int berhasil = 0;
    bool adaFotoGagal = false;

    for (final ItemKeranjang item in antrean) {
      try {
        final Pesanan pesanan = await _pesananService.buat(
          serviceId: item.layanan.id,
          estimatedWeight: item.beratPerkiraan,
          metode: _metode,
        );

        // Pesanan sudah sah dibuat. Kegagalan mengirim foto tidak membatalkan
        // pesanannya, dan pelanggan bisa mengunggah ulang dari detail pesanan.
        if (item.foto != null) {
          try {
            await _pesananService.unggahFoto(
              orderId: pesanan.id,
              foto: item.foto!,
            );
          } on ApiException {
            adaFotoGagal = true;
          }
        }

        // Hanya item yang pesanannya benar-benar dibuat yang dikeluarkan,
        // supaya sisa yang gagal masih bisa dicoba lagi.
        keranjang.hapus(item.id);
        berhasil++;
      } on ApiException catch (kesalahan) {
        gagal.add('${item.layanan.nama}: ${kesalahan.pesan}');
      } catch (_) {
        gagal.add(
          '${item.layanan.nama}: tidak bisa dikirim, periksa koneksi lalu '
          'coba lagi.',
        );
      }
    }

    if (!mounted) return;
    setState(() => _sedangKirim = false);

    if (berhasil == 0) {
      await _tampilkanGagal(gagal);
      return;
    }

    navigator.popUntil((Route<dynamic> rute) => rute.isFirst);
    tampilkanPesanLewat(
      messenger,
      _pesanHasil(
        berhasil: berhasil,
        total: antrean.length,
        sisaGagal: gagal.length,
        adaFotoGagal: adaFotoGagal,
      ),
      jenis: gagal.isEmpty ? JenisPesan.sukses : JenisPesan.info,
    );
  }

  /// Seluruh pesanan gagal: pelanggan tetap di halaman ini supaya bisa
  /// mencoba lagi tanpa menyusun ulang keranjangnya.
  Future<void> _tampilkanGagal(List<String> gagal) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Pesanan gagal dibuat'),
        content: Text(
          gagal.isEmpty
              ? 'Tidak ada pesanan yang bisa dibuat. Coba lagi.'
              : '${gagal.join('\n\n')}\n\nIsi keranjang Anda belum berubah.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _pesanHasil({
    required int berhasil,
    required int total,
    required int sisaGagal,
    required bool adaFotoGagal,
  }) {
    final StringBuffer pesan = StringBuffer();

    if (sisaGagal == 0) {
      pesan.write('$berhasil pesanan berhasil dibuat. ');
      pesan.write(
        _metode.perluKonfirmasiAdmin
            ? 'Bayar tunai saat pakaian diambil, admin mengonfirmasi '
                  'pembayarannya.'
            : 'Pembayarannya sudah ditandai lunas.',
      );
    } else {
      pesan.write('$berhasil dari $total pesanan berhasil dibuat. ');
      pesan.write(
        'Sisa $sisaGagal layanan masih ada di keranjang untuk dicoba lagi.',
      );
    }

    if (adaFotoGagal) {
      pesan.write(' Sebagian foto belum terkirim.');
    }

    return pesan.toString();
  }
}

/// Dialog pengubahan berat perkiraan satu item keranjang.
class _DialogUbahBerat extends StatefulWidget {
  const _DialogUbahBerat({required this.namaLayanan, required this.beratAwal});

  final String namaLayanan;
  final double beratAwal;

  @override
  State<_DialogUbahBerat> createState() => _DialogUbahBeratState();
}

class _DialogUbahBeratState extends State<_DialogUbahBerat> {
  final GlobalKey<FormState> _kunciForm = GlobalKey<FormState>();
  late final TextEditingController _berat = TextEditingController(
    text: widget.beratAwal.toString(),
  );

  @override
  void dispose() {
    _berat.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!(_kunciForm.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      double.parse(_berat.text.trim().replaceAll(',', '.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah berat perkiraan'),
      content: Form(
        key: _kunciForm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.namaLayanan,
              style: const TextStyle(fontSize: 13.5, color: Warna.teksKedua),
            ),
            const SizedBox(height: Jarak.lg),
            TextFormField(
              controller: _berat,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Berat perkiraan',
                hintText: 'Contoh: 3.5',
                suffixText: 'kg',
              ),
              validator: Validasi.beratPerkiraan,
              onFieldSubmitted: (_) => _simpan(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: Warna.teksKedua),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _simpan,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: Jarak.lg),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
