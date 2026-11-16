import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/pesanan.dart';
import '../../services/api_client.dart';
import '../../services/pesanan_service.dart';
import '../../utils/format.dart';
import '../../utils/validasi.dart';
import '../../widgets/baris_detail.dart';
import '../../widgets/pesan_ui.dart';

/// Halaman pengisian berat aktual oleh admin.
///
/// Harga akhir TIDAK dihitung di sini. Angka yang ditampilkan setelah
/// penyimpanan berasal dari `total_price` yang dikirim backend, karena backend
/// yang menghitungnya di dalam SQL memakai harga per kg milik pesanan itu.
class IsiBeratScreen extends StatefulWidget {
  const IsiBeratScreen({super.key, required this.pesanan});

  final Pesanan pesanan;

  @override
  State<IsiBeratScreen> createState() => _IsiBeratScreenState();
}

class _IsiBeratScreenState extends State<IsiBeratScreen> {
  final GlobalKey<FormState> _kunciForm = GlobalKey<FormState>();
  final PesananService _pesananService = const PesananService();

  late final TextEditingController _berat;
  bool _sedangKirim = false;
  AutovalidateMode _modeValidasi = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _berat = TextEditingController(
      text: _teksAwal(widget.pesanan.beratAktual),
    );
  }

  String _teksAwal(double? nilai) {
    if (nilai == null) return '';
    return nilai == nilai.roundToDouble()
        ? nilai.toStringAsFixed(0)
        : nilai.toString();
  }

  @override
  void dispose() {
    _berat.dispose();
    super.dispose();
  }

  double? get _beratTerbaca =>
      double.tryParse(_berat.text.trim().replaceAll(',', '.'));

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();

    if (!(_kunciForm.currentState?.validate() ?? false)) {
      setState(() => _modeValidasi = AutovalidateMode.onUserInteraction);
      return;
    }

    final double? berat = _beratTerbaca;
    if (berat == null) return;

    setState(() => _sedangKirim = true);

    try {
      final Pesanan hasil = await _pesananService.isiBeratAsli(
        orderId: widget.pesanan.id,
        actualWeight: berat,
      );

      if (!mounted) return;
      setState(() => _sedangKirim = false);

      await _tampilkanHasil(hasil);
      if (!mounted) return;
      // true memberi tahu halaman detail bahwa datanya perlu dimuat ulang.
      Navigator.of(context).pop(true);
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() => _sedangKirim = false);
      tampilkanPesan(context, kesalahan.pesan, jenis: JenisPesan.gagal);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sedangKirim = false);
      tampilkanPesan(
        context,
        'Berat gagal disimpan. Periksa koneksi lalu coba lagi.',
        jenis: JenisPesan.gagal,
      );
    }
  }

  /// Menampilkan total biaya hasil hitungan backend.
  Future<void> _tampilkanHasil(Pesanan hasil) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Berat tersimpan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Berat aktual pesanan #${hasil.id} disimpan sebagai '
                '${formatBerat(hasil.beratAktual)}.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Warna.teksKedua,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: Jarak.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Jarak.md),
                decoration: BoxDecoration(
                  color: Warna.aksenLembut,
                  borderRadius: BorderRadius.circular(Sudut.kolomIsian),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Total biaya dihitung server',
                      style: TextStyle(
                        fontSize: 12,
                        color: Warna.teksKedua,
                      ),
                    ),
                    const SizedBox(height: Jarak.xs),
                    Text(
                      formatRupiah(hasil.totalHarga),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Warna.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: Jarak.xs),
                    Text(
                      '${formatBerat(hasil.beratAktual)} \u00d7 '
                      '${formatRupiah(hasil.hargaPerKg)} per kg',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Warna.teksSamar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: Jarak.lg),
              ),
              child: const Text('Selesai'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Pesanan pesanan = widget.pesanan;

    return Scaffold(
      appBar: AppBar(title: const Text('Isi Berat Aktual')),
      body: Form(
        key: _kunciForm,
        autovalidateMode: _modeValidasi,
        child: ListView(
          padding: const EdgeInsets.all(Jarak.xl),
          children: <Widget>[
            KartuBagian(
              judul: 'Pesanan #${pesanan.id}',
              ikon: Icons.receipt_long_rounded,
              anak: Column(
                children: <Widget>[
                  BarisDetail(label: 'Pelanggan', nilai: pesanan.namaPelanggan),
                  const SizedBox(height: Jarak.sm),
                  BarisDetail(label: 'Layanan', nilai: pesanan.namaLayanan),
                  const SizedBox(height: Jarak.sm),
                  BarisDetail(
                    label: 'Harga per kg',
                    nilai: formatRupiah(pesanan.hargaPerKg),
                  ),
                  const SizedBox(height: Jarak.sm),
                  BarisDetail(
                    label: 'Berat perkiraan pelanggan',
                    nilai: formatBerat(pesanan.beratPerkiraan),
                  ),
                  if (pesanan.beratAktual != null) ...<Widget>[
                    const SizedBox(height: Jarak.sm),
                    BarisDetail(
                      label: 'Berat aktual tersimpan',
                      nilai: formatBerat(pesanan.beratAktual),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: Jarak.xl),

            TextFormField(
              controller: _berat,
              autofocus: true,
              enabled: !_sedangKirim,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Berat aktual',
                hintText: 'Contoh: 3.7',
                suffixText: 'kg',
                prefixIcon: Icon(Icons.scale_rounded),
                helperText:
                    'Berat hasil penimbangan pakaian. Total biaya akan '
                    'dihitung server.',
              ),
              validator: Validasi.beratAktual,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _simpan(),
            ),

            const SizedBox(height: Jarak.lg),

            _perkiraanSebelumSimpan(),

            const SizedBox(height: Jarak.xl),

            FilledButton.icon(
              onPressed: _sedangKirim ? null : _simpan,
              icon: _sedangKirim
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(_sedangKirim ? 'Menyimpan...' : 'Simpan Berat'),
            ),

            const SizedBox(height: Jarak.md),

            OutlinedButton(
              onPressed: _sedangKirim
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),

            const SizedBox(height: Jarak.lg),
          ],
        ),
      ),
    );
  }

  /// Perkiraan sementara sebelum disimpan.
  ///
  /// Diberi keterangan jelas bahwa angka ini hitungan aplikasi, dan angka yang
  /// sah adalah hasil dari server setelah disimpan.
  Widget _perkiraanSebelumSimpan() {
    final double? berat = _beratTerbaca;
    if (berat == null || berat <= 0) return const SizedBox.shrink();

    final double perkiraan = berat * widget.pesanan.hargaPerKg;

    return Container(
      padding: const EdgeInsets.all(Jarak.lg),
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        border: Border.all(color: Warna.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Perkiraan total (belum disimpan)',
            style: TextStyle(fontSize: 12.5, color: Warna.teksKedua),
          ),
          const SizedBox(height: Jarak.xs),
          Text(
            formatRupiah(perkiraan),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Warna.teksUtama,
              height: 1.2,
            ),
          ),
          const SizedBox(height: Jarak.sm),
          const Text(
            'Angka sah adalah total biaya yang dihitung server setelah berat '
            'disimpan.',
            style: TextStyle(
              fontSize: 12,
              color: Warna.teksSamar,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
