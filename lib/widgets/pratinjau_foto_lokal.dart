import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_theme.dart';

/// Pratinjau foto yang masih ada di perangkat pengguna.
///
/// Isinya dibaca lewat `XFile.readAsBytes()`, yang sudah bekerja di Android,
/// iOS, dan web. Cara ini dipilih daripada memuat alamat berkasnya, karena
/// alamat berkas lokal berbeda bentuk di setiap platform: di Android dan iOS
/// berupa jalur berkas, sedangkan di web berupa alamat blob.
class PratinjauFotoLokal extends StatefulWidget {
  const PratinjauFotoLokal({
    super.key,
    required this.foto,
    this.tinggi = 220,
    this.keteranganGagal = 'Foto tidak bisa ditampilkan.',
  });

  final XFile foto;
  final double tinggi;
  final String keteranganGagal;

  @override
  State<PratinjauFotoLokal> createState() => _PratinjauFotoLokalState();
}

class _PratinjauFotoLokalState extends State<PratinjauFotoLokal> {
  late Future<Uint8List> _isi;

  @override
  void initState() {
    super.initState();
    _isi = widget.foto.readAsBytes();
  }

  @override
  void didUpdateWidget(PratinjauFotoLokal lama) {
    super.didUpdateWidget(lama);
    // Berkas diganti lewat tombol "Ganti", jadi isinya perlu dibaca ulang.
    if (lama.foto.path != widget.foto.path) {
      _isi = widget.foto.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.tinggi,
      width: double.infinity,
      child: FutureBuilder<Uint8List>(
        future: _isi,
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _GagalTampil(keterangan: widget.keteranganGagal);
          }

          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _GagalTampil(keterangan: widget.keteranganGagal),
          );
        },
      ),
    );
  }
}

class _GagalTampil extends StatelessWidget {
  const _GagalTampil({required this.keterangan});

  final String keterangan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              keterangan,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: Warna.teksKedua,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto pesanan yang sudah tersimpan.
///
/// Terpisah dari [PratinjauFotoLokal] karena sumbernya berbeda: yang ini
/// diambil dari alamat HTTP milik RENOVA, bukan dari berkas di perangkat.
class FotoDariServer extends StatelessWidget {
  const FotoDariServer({
    super.key,
    required this.alamat,
    this.tinggi = 220,
    this.bisaDibukaPenuh = false,
  });

  final String alamat;
  final double tinggi;
  final bool bisaDibukaPenuh;

  @override
  Widget build(BuildContext context) {
    final Widget gambar = Image.network(
      alamat,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder:
          (BuildContext context, Widget child, ImageChunkEvent? progres) {
            if (progres == null) return child;
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          },
      errorBuilder: (_, _, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(Jarak.lg),
          child: Text(
            'Foto ini tidak bisa ditampilkan. Coba muat ulang halaman; '
            'bila tetap gagal, foto sudah tidak tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Warna.teksKedua),
          ),
        ),
      ),
    );

    if (!bisaDibukaPenuh) {
      return SizedBox(height: tinggi, child: gambar);
    }

    return SizedBox(
      height: tinggi,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          gambar,
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _bukaPenuh(context),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(Jarak.sm),
                  padding: const EdgeInsets.all(Jarak.sm),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(Jarak.sm),
                  ),
                  child: const Icon(
                    Icons.zoom_out_map_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bukaPenuh(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Foto Pakaian'),
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 5,
              child: Image.network(
                alamat,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Text(
                  'Foto tidak bisa ditampilkan.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
