import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../services/api_client.dart';
import '../../services/layanan_service.dart';
import '../../utils/format.dart';
import '../../utils/validasi.dart';
import '../../widgets/pemilih_foto.dart';
import '../../widgets/pesan_ui.dart';
import '../../widgets/tampilan_status.dart';
import 'konfirmasi_pesanan_screen.dart';

/// Form pembuatan pesanan baru.
///
/// Urutannya: pilih layanan, isi berat perkiraan, lampirkan foto (opsional),
/// lalu lanjut ke halaman konfirmasi. Pesanan belum dikirim ke server di
/// halaman ini.
///
/// Catatan tambahan tidak disediakan karena tabel `orders` di backend tidak
/// punya kolomnya. Menyediakan kolom yang tidak pernah terkirim hanya akan
/// membuat pelanggan mengira catatannya sampai ke admin.
class FormPemesananScreen extends StatefulWidget {
  const FormPemesananScreen({super.key, this.layananAwal});

  /// Layanan yang sudah dipilih sebelumnya, mis. dari halaman detail layanan.
  final Layanan? layananAwal;

  @override
  State<FormPemesananScreen> createState() => _FormPemesananScreenState();
}

class _FormPemesananScreenState extends State<FormPemesananScreen> {
  final GlobalKey<FormState> _kunciForm = GlobalKey<FormState>();
  final LayananService _layananService = const LayananService();
  final TextEditingController _berat = TextEditingController();

  List<Layanan> _daftarLayanan = <Layanan>[];
  Layanan? _layananDipilih;
  XFile? _foto;

  bool _memuatLayanan = true;
  String? _galatLayanan;
  AutovalidateMode _modeValidasi = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _layananDipilih = widget.layananAwal;
    _muatLayanan();
  }

  @override
  void dispose() {
    _berat.dispose();
    super.dispose();
  }

  Future<void> _muatLayanan() async {
    try {
      final List<Layanan> hasil = await _layananService.daftarSemua();
      if (!mounted) return;

      setState(() {
        _daftarLayanan = hasil;
        _galatLayanan = null;

        // Layanan awal dipakai hanya bila masih ada di daftar terbaru,
        // supaya tidak ada pilihan yang menunjuk layanan yang sudah dihapus.
        if (_layananDipilih != null) {
          final int idAwal = _layananDipilih!.id;
          _layananDipilih = hasil
              .where((Layanan l) => l.id == idAwal)
              .cast<Layanan?>()
              .firstWhere((Layanan? l) => true, orElse: () => null);
        }

        // Kalau hanya ada satu layanan, langsung dipilih supaya pelanggan
        // tidak perlu memilih yang sudah jelas.
        _layananDipilih ??= hasil.length == 1 ? hasil.first : null;
      });
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() => _galatLayanan = kesalahan.pesan);
    } finally {
      if (mounted) setState(() => _memuatLayanan = false);
    }
  }

  Future<void> _pilihFoto() async {
    final XFile? berkas = await ambilFoto(context);
    if (berkas == null || !mounted) return;
    setState(() => _foto = berkas);
  }

  void _lanjut() {
    FocusScope.of(context).unfocus();

    if (_layananDipilih == null) {
      tampilkanPesan(
        context,
        'Pilih layanan laundry terlebih dahulu.',
        jenis: JenisPesan.gagal,
      );
      return;
    }

    if (!(_kunciForm.currentState?.validate() ?? false)) {
      setState(() => _modeValidasi = AutovalidateMode.onUserInteraction);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KonfirmasiPesananScreen(
          layanan: _layananDipilih!,
          beratPerkiraan: double.parse(_berat.text.trim().replaceAll(',', '.')),
          foto: _foto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan Laundry')),
      body: _memuatLayanan
          ? const TampilanMemuat(keterangan: 'Memuat daftar layanan...')
          : _galatLayanan != null
          ? TampilanGagal(
              pesan: _galatLayanan!,
              judul: 'Daftar layanan gagal dimuat',
              onCobaLagi: () {
                setState(() {
                  _memuatLayanan = true;
                  _galatLayanan = null;
                });
                _muatLayanan();
              },
            )
          : Form(
              key: _kunciForm,
              autovalidateMode: _modeValidasi,
              child: ListView(
                padding: const EdgeInsets.all(Jarak.xl),
                children: <Widget>[
                  _langkahNomor('1', 'Pilih layanan'),
                  const SizedBox(height: Jarak.md),

                  if (_daftarLayanan.isEmpty)
                    _kotakPesan(
                      'Belum ada layanan yang bisa dipesan. Hubungi admin '
                      'untuk menambahkan layanan terlebih dahulu.',
                    )
                  else
                    DropdownButtonFormField<Layanan>(
                      // initialValue, bukan value: parameter `value` sudah
                      // ditandai usang pada Flutter versi ini.
                      initialValue: _layananDipilih,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Layanan',
                        prefixIcon: Icon(Icons.local_laundry_service_rounded),
                      ),
                      // Kolom tertutup hanya menampilkan nama layanan. Kalau
                      // harga ikut ditulis di sini, nama layanan yang panjang
                      // terpotong elipsis pada layar sempit — harga sudah
                      // tertera pada ringkasan di bawah dan pada daftar
                      // pilihannya.
                      selectedItemBuilder: (BuildContext context) =>
                          _daftarLayanan
                              .map(
                                (Layanan l) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    l.nama,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      items: _daftarLayanan
                          .map(
                            (Layanan l) => DropdownMenuItem<Layanan>(
                              value: l,
                              child: Text(
                                '${l.nama} - ${formatRupiah(l.hargaPerKg)}/kg',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (Layanan? nilai) {
                        setState(() => _layananDipilih = nilai);
                      },
                    ),

                  if (_layananDipilih != null) ...<Widget>[
                    const SizedBox(height: Jarak.md),
                    _ringkasLayanan(_layananDipilih!),
                  ],

                  const SizedBox(height: Jarak.xl),
                  _langkahNomor('2', 'Isi berat perkiraan'),
                  const SizedBox(height: Jarak.md),

                  TextFormField(
                    controller: _berat,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Berat perkiraan',
                      hintText: 'Contoh: 3.5',
                      suffixText: 'kg',
                      prefixIcon: Icon(Icons.scale_rounded),
                      helperText:
                          'Perkiraan saja. Admin akan menimbang berat '
                          'sebenarnya saat pakaian diterima.',
                    ),
                    validator: Validasi.beratPerkiraan,
                  ),

                  const SizedBox(height: Jarak.xl),
                  _langkahNomor('3', 'Foto pakaian (opsional)'),
                  const SizedBox(height: Jarak.sm),
                  Text(
                    keteranganBatasFoto(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Warna.teksKedua,
                    ),
                  ),
                  const SizedBox(height: Jarak.md),

                  PemilihFoto(
                    fotoTerpilih: _foto,
                    onPilih: _pilihFoto,
                    onHapus: () => setState(() => _foto = null),
                  ),

                  const SizedBox(height: Jarak.xl),
                  _perkiraanBiaya(),

                  const SizedBox(height: Jarak.xl),

                  FilledButton.icon(
                    onPressed: _daftarLayanan.isEmpty ? null : _lanjut,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: const Text('Lanjut ke Konfirmasi'),
                  ),

                  const SizedBox(height: Jarak.lg),
                ],
              ),
            ),
    );
  }

  Widget _langkahNomor(String nomor, String judul) {
    return Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Warna.aksen,
            shape: BoxShape.circle,
          ),
          child: Text(
            nomor,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Warna.primary,
            ),
          ),
        ),
        const SizedBox(width: Jarak.md),
        Text(
          judul,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Warna.teksUtama,
          ),
        ),
      ],
    );
  }

  Widget _ringkasLayanan(Layanan layanan) {
    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: Warna.aksenLembut,
        borderRadius: BorderRadius.circular(Sudut.kolomIsian),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${formatRupiah(layanan.hargaPerKg)} per kg \u2022 '
              'estimasi ${layanan.durasi}',
              style: const TextStyle(
                fontSize: 12.5,
                color: Warna.primaryGelap,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Perkiraan biaya dari berat yang diketik.
  ///
  /// Angka ini hanya bantuan sementara bagi pelanggan. Harga yang benar-benar
  /// dipakai adalah hasil hitungan backend setelah admin mengisi berat asli,
  /// dan itulah yang ditulis di keterangan.
  Widget _perkiraanBiaya() {
    final double? berat = double.tryParse(
      _berat.text.trim().replaceAll(',', '.'),
    );
    final Layanan? layanan = _layananDipilih;

    if (berat == null || berat <= 0 || layanan == null) {
      return const SizedBox.shrink();
    }

    final double perkiraan = berat * layanan.hargaPerKg;

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
            'Perkiraan biaya',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Warna.teksUtama,
            ),
          ),
          const SizedBox(height: Jarak.xs),
          Text(
            formatRupiah(perkiraan),
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Warna.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: Jarak.sm),
          const Text(
            'Ini baru perkiraan dari berat yang Anda isi. Total biaya yang '
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

  Widget _kotakPesan(String pesan) {
    return Container(
      padding: const EdgeInsets.all(Jarak.lg),
      decoration: BoxDecoration(
        color: Warna.peringatanMuda,
        borderRadius: BorderRadius.circular(Sudut.kartu),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Warna.peringatan,
          ),
          const SizedBox(width: Jarak.md),
          Expanded(
            child: Text(
              pesan,
              style: const TextStyle(
                fontSize: 13,
                color: Warna.peringatan,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
