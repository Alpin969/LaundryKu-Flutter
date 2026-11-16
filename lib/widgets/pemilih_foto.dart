import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_theme.dart';
import '../services/pesanan_service.dart';
import 'pesan_ui.dart';
import 'pratinjau_foto_lokal.dart';

/// Pemilih foto pakaian, dipakai pelanggan maupun admin.
///
/// Widget ini hanya mengurus pemilihan dan pratinjau berkas. Pengunggahan ke
/// server dilakukan pemanggilnya, karena butuh id pesanan dan hanya bisa
/// dilakukan setelah pesanan ada.
class PemilihFoto extends StatelessWidget {
  const PemilihFoto({
    super.key,
    required this.fotoTerpilih,
    required this.onPilih,
    required this.onHapus,
    this.alamatFotoTersimpan,
    this.nonaktif = false,
    this.tinggiPratinjau = 220,
  });

  /// Berkas yang baru dipilih pengguna dan belum diunggah.
  final XFile? fotoTerpilih;

  /// Alamat foto yang sudah tersimpan di server, bila ada.
  final String? alamatFotoTersimpan;

  final VoidCallback onPilih;
  final VoidCallback onHapus;
  final bool nonaktif;
  final double tinggiPratinjau;

  bool get _adaFotoTersimpan =>
      alamatFotoTersimpan != null && alamatFotoTersimpan!.isNotEmpty;

  bool get _adaFoto => fotoTerpilih != null || _adaFotoTersimpan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!_adaFoto)
          _KotakKosong(nonaktif: nonaktif, onPilih: onPilih)
        else ...<Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(Sudut.kartu),
            child: Container(
              width: double.infinity,
              height: tinggiPratinjau,
              color: Warna.aksenLembut,
              child: fotoTerpilih != null
                  // Berkas lokal dibaca sebagai byte, bukan dimuat lewat
                  // alamatnya: alamat berkas berbeda bentuk di tiap platform.
                  ? PratinjauFotoLokal(
                      foto: fotoTerpilih!,
                      tinggi: tinggiPratinjau,
                      keteranganGagal: 'Foto sudah dipilih, belum dikirim.',
                    )
                  : FotoDariServer(
                      alamat: alamatFotoTersimpan!,
                      tinggi: tinggiPratinjau,
                      bisaDibukaPenuh: true,
                    ),
            ),
          ),
          const SizedBox(height: Jarak.md),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: nonaktif ? null : onPilih,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 19),
                  label: const Text('Ganti'),
                ),
              ),
              const SizedBox(width: Jarak.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: nonaktif ? null : onHapus,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Warna.bahaya,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  label: const Text('Hapus'),
                ),
              ),
            ],
          ),
          if (fotoTerpilih != null) ...<Widget>[
            const SizedBox(height: Jarak.sm),
            const Text(
              'Foto ini masih di perangkat Anda dan belum terkirim ke server.',
              style: TextStyle(fontSize: 12, color: Warna.teksSamar),
            ),
          ],
        ],
      ],
    );
  }
}

class _KotakKosong extends StatelessWidget {
  const _KotakKosong({required this.nonaktif, required this.onPilih});

  final bool nonaktif;
  final VoidCallback onPilih;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: nonaktif ? null : onPilih,
      borderRadius: BorderRadius.circular(Sudut.kartu),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: Jarak.xl,
          horizontal: Jarak.lg,
        ),
        decoration: BoxDecoration(
          color: Warna.aksenLembut,
          borderRadius: BorderRadius.circular(Sudut.kartu),
          border: Border.all(color: Warna.garis),
        ),
        child: const Column(
          children: <Widget>[
            Icon(Icons.add_a_photo_outlined, size: 28, color: Warna.primary),
            SizedBox(height: Jarak.md),
            Text(
              'Tambah foto pakaian',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Warna.teksUtama,
              ),
            ),
            SizedBox(height: Jarak.xs),
            Text(
              'Opsional. Membantu admin mengenali pakaian Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Warna.teksKedua,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Meminta pengguna memilih sumber foto: kamera atau galeri.
///
/// Mengembalikan berkas yang dipilih, atau null bila pengguna membatalkan.
/// Kegagalan membuka kamera atau galeri diberitahukan ke pengguna, bukan
/// dibiarkan diam.
Future<XFile?> ambilFoto(BuildContext context) async {
  final ImageSource? sumber = await pilihDariLembar<ImageSource>(
    context,
    judul: 'Ambil foto dari',
    pilihan: <({
      ImageSource nilai,
      String label,
      IconData ikon,
      String? keterangan,
    })>[
      (
        nilai: ImageSource.camera,
        label: 'Kamera',
        ikon: Icons.photo_camera_outlined,
        keterangan: 'Foto pakaian sekarang',
      ),
      (
        nilai: ImageSource.gallery,
        label: 'Galeri',
        ikon: Icons.photo_library_outlined,
        keterangan: 'Pilih dari foto yang sudah ada',
      ),
    ],
  );

  if (sumber == null) return null;

  try {
    // Foto dikecilkan sebelum dikirim supaya tidak melewati batas ukuran
    // milik backend dan unggahan tetap cepat di jaringan seluler.
    return await ImagePicker().pickImage(
      source: sumber,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
  } catch (_) {
    if (context.mounted) {
      tampilkanPesan(
        context,
        'Tidak bisa membuka kamera atau galeri. Periksa izin aplikasi pada '
        'pengaturan perangkat.',
        jenis: JenisPesan.gagal,
      );
    }
    return null;
  }
}

/// Keterangan batas berkas foto, ditampilkan di dekat pemilih foto.
String keteranganBatasFoto() {
  final int batasMb = PesananService.batasUkuranFotoByte ~/ (1024 * 1024);
  return 'Format JPG, PNG, atau WebP. Maksimal $batasMb MB.';
}
