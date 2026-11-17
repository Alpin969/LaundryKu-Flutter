import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Penanda "sedang memuat".
///
/// Selalu disertai keterangan apa yang sedang dimuat, supaya pengguna tahu
/// aplikasi bekerja dan bukan sekadar diam.
class TampilanMemuat extends StatelessWidget {
  const TampilanMemuat({
    super.key,
    this.keterangan = 'Memuat data...',
    this.ringkas = false,
  });

  final String keterangan;

  /// Versi ringkas untuk ditempel di dalam kartu, tanpa memenuhi layar.
  final bool ringkas;

  @override
  Widget build(BuildContext context) {
    final Widget isi = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(height: Jarak.md),
        Text(
          keterangan,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Warna.teksKedua),
        ),
      ],
    );

    if (ringkas) {
      return Padding(
        padding: const EdgeInsets.all(Jarak.xl),
        child: Center(child: isi),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Jarak.xl),
        child: isi,
      ),
    );
  }
}

/// Penanda kegagalan memuat data.
///
/// Menyebutkan apa yang gagal dan langkah berikutnya, bukan sekadar
/// "Terjadi kesalahan".
class TampilanGagal extends StatelessWidget {
  const TampilanGagal({
    super.key,
    required this.pesan,
    this.judul = 'Data gagal dimuat',
    this.onCobaLagi,
    this.ringkas = false,
  });

  final String pesan;
  final String judul;
  final VoidCallback? onCobaLagi;
  final bool ringkas;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Jarak.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                judul,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Warna.teksUtama,
                ),
              ),
              const SizedBox(height: Jarak.sm),
              Text(
                pesan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Warna.teksKedua,
                  height: 1.6,
                ),
              ),
              if (onCobaLagi != null) ...<Widget>[
                const SizedBox(height: Jarak.xl),
                SizedBox(
                  width: 200,
                  child: FilledButton(
                    onPressed: onCobaLagi,
                    child: const Text('Coba Lagi'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Penanda tidak ada data.
///
/// Menjelaskan sebab kosongnya dan tindakan yang bisa dilakukan, karena
/// "Tidak ada data" saja tidak menuntun siapa pun.
class TampilanKosong extends StatelessWidget {
  const TampilanKosong({
    super.key,
    required this.judul,
    required this.pesan,
    this.labelTombol,
    this.onTombol,
  });

  final String judul;
  final String pesan;
  final String? labelTombol;
  final VoidCallback? onTombol;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Jarak.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                judul,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Warna.teksUtama,
                ),
              ),
              const SizedBox(height: Jarak.sm),
              Text(
                pesan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Warna.teksKedua,
                  height: 1.6,
                ),
              ),
              if (labelTombol != null && onTombol != null) ...<Widget>[
                const SizedBox(height: Jarak.xl),
                SizedBox(
                  width: 220,
                  child: FilledButton(
                    onPressed: onTombol,
                    child: Text(labelTombol!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
