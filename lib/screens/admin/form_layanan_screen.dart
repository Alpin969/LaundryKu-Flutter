import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../utils/validasi.dart';

/// Form tambah dan ubah layanan untuk admin.
///
/// Satu halaman dipakai untuk dua keperluan:
///   - [layanan] null  -> tambah layanan baru (POST /api/services)
///   - [layanan] terisi -> ubah layanan (PUT /api/services/:id)
///
/// Halaman ini hanya mengumpulkan data dan mengembalikannya lewat
/// Navigator.pop. Pengirimannya ke server dilakukan halaman daftar layanan,
/// supaya penanganan berhasil/gagal hanya ditulis di satu tempat.
class FormLayananScreen extends StatefulWidget {
  const FormLayananScreen({super.key, this.layanan});

  final Layanan? layanan;

  @override
  State<FormLayananScreen> createState() => _FormLayananScreenState();
}

class _FormLayananScreenState extends State<FormLayananScreen> {
  final GlobalKey<FormState> _kunciForm = GlobalKey<FormState>();

  late final TextEditingController _nama;
  late final TextEditingController _deskripsi;
  late final TextEditingController _harga;
  late final TextEditingController _durasi;

  AutovalidateMode _modeValidasi = AutovalidateMode.disabled;

  bool get _modeUbah => widget.layanan != null;

  @override
  void initState() {
    super.initState();

    final Layanan? layanan = widget.layanan;

    _nama = TextEditingController(text: layanan?.nama ?? '');
    _deskripsi = TextEditingController(text: layanan?.deskripsi ?? '');
    _durasi = TextEditingController(text: layanan?.durasi ?? '');

    // Harga ditampilkan tanpa desimal bila memang bilangan bulat, supaya
    // admin tidak melihat "7500.00" seperti data mentah.
    _harga = TextEditingController(
      text: layanan == null
          ? ''
          : (layanan.hargaPerKg == layanan.hargaPerKg.roundToDouble()
                ? layanan.hargaPerKg.toStringAsFixed(0)
                : layanan.hargaPerKg.toString()),
    );
  }

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    _harga.dispose();
    _durasi.dispose();
    super.dispose();
  }

  void _simpan() {
    FocusScope.of(context).unfocus();

    if (!(_kunciForm.currentState?.validate() ?? false)) {
      setState(() => _modeValidasi = AutovalidateMode.onUserInteraction);
      return;
    }

    final String deskripsi = _deskripsi.text.trim();

    // description dikirim null (bukan string kosong) ketika dikosongkan,
    // sesuai yang diterima backend.
    final Layanan hasil = Layanan(
      id: widget.layanan?.id ?? 0,
      nama: _nama.text.trim(),
      deskripsi: deskripsi.isEmpty ? null : deskripsi,
      hargaPerKg: double.parse(_harga.text.trim().replaceAll(',', '.')),
      durasi: _durasi.text.trim(),
    );

    Navigator.of(context).pop(hasil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modeUbah ? 'Ubah Layanan' : 'Tambah Layanan'),
      ),
      body: Form(
        key: _kunciForm,
        autovalidateMode: _modeValidasi,
        child: ListView(
          padding: const EdgeInsets.all(Jarak.xl),
          children: <Widget>[
            if (_modeUbah)
              Container(
                padding: const EdgeInsets.all(Jarak.md),
                decoration: BoxDecoration(
                  color: Warna.aksenLembut,
                  borderRadius: BorderRadius.circular(Sudut.kolomIsian),
                ),
                child: Text(
                  'Mengubah layanan #${widget.layanan!.id}. Perubahan harga '
                  'hanya berlaku untuk pesanan baru; pesanan lama tetap '
                  'memakai harga saat pesanan itu dibuat.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Warna.primaryGelap,
                    height: 1.55,
                  ),
                ),
              ),
            if (_modeUbah) const SizedBox(height: Jarak.xl),

            TextFormField(
              controller: _nama,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama layanan',
                hintText: 'Contoh: Cuci Kering Setrika',
              ),
              validator: Validasi.namaLayanan,
            ),

            const SizedBox(height: Jarak.lg),

            TextFormField(
              controller: _harga,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Harga per kg',
                hintText: 'Contoh: 7500',
                prefixText: 'Rp ',
              ),
              validator: Validasi.hargaPerKg,
            ),

            const SizedBox(height: Jarak.lg),

            TextFormField(
              controller: _durasi,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Estimasi pengerjaan',
                hintText: 'Contoh: 3 hari',
                helperText: 'Ditulis bebas, mis. "2 hari" atau "6 jam".',
              ),
              validator: Validasi.durasiLayanan,
            ),

            const SizedBox(height: Jarak.lg),

            TextFormField(
              controller: _deskripsi,
              maxLines: 4,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                hintText: 'Jelaskan apa saja yang termasuk dalam layanan ini.',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: Jarak.md),

            FilledButton(
              onPressed: _simpan,
              child: Text(_modeUbah ? 'Simpan Perubahan' : 'Tambah Layanan'),
            ),

            const SizedBox(height: Jarak.md),

            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),

            const SizedBox(height: Jarak.lg),
          ],
        ),
      ),
    );
  }
}
