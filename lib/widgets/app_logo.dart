import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Logo RENOVA.
///
/// Bentuknya sesuai referensi brand: tetesan air dengan ikon kaos di tengah
/// dan garis cyan mengikuti tepinya. Digambar sendiri sebagai vektor supaya
/// tetap tajam di segala ukuran dan tidak bergantung pada berkas gambar.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.ukuran = 72, this.warnaLatar, this.warnaGaris});

  /// Sisi kotak logo dalam piksel.
  final double ukuran;

  /// Warna isi tetesan. Bila null, memakai warna utama RENOVA.
  final Color? warnaLatar;

  /// Warna garis tepi tetesan.
  final Color? warnaGaris;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ukuran,
      height: ukuran,
      child: CustomPaint(
        painter: _TetesAirPainter(
          isi: warnaLatar ?? Warna.primary,
          garis: warnaGaris ?? Warna.primaryCerah,
        ),
        child: Align(
          // Ikon kaos diletakkan sedikit di bawah titik tetes, tempat
          // tetesan sudah cukup lebar untuk menampungnya.
          alignment: const Alignment(0, 0.18),
          child: Icon(
            Icons.checkroom_rounded,
            size: ukuran * 0.40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TetesAirPainter extends CustomPainter {
  const _TetesAirPainter({required this.isi, required this.garis});

  final Color isi;
  final Color garis;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Titik tetes di atas, badan membulat di bawah. Sisi kiri dan kanan
    // dibuat simetris supaya bentuknya tetap seimbang di ukuran kecil.
    final Path tetes = Path()
      ..moveTo(w * 0.5, h * 0.03)
      ..cubicTo(w * 0.5, h * 0.03, w * 0.09, h * 0.34, w * 0.09, h * 0.60)
      ..cubicTo(w * 0.09, h * 1.00, w * 0.91, h * 1.00, w * 0.91, h * 0.60)
      ..cubicTo(w * 0.91, h * 0.34, w * 0.5, h * 0.03, w * 0.5, h * 0.03)
      ..close();

    canvas.drawPath(tetes, Paint()..color = isi);

    // Garis cyan sedikit di dalam tepi, supaya tidak terpotong di sisi kotak.
    final Path garisTepi = Path()
      ..moveTo(w * 0.5, h * 0.13)
      ..cubicTo(w * 0.5, h * 0.13, w * 0.17, h * 0.38, w * 0.17, h * 0.60)
      ..cubicTo(w * 0.17, h * 0.90, w * 0.83, h * 0.90, w * 0.83, h * 0.60)
      ..cubicTo(w * 0.83, h * 0.38, w * 0.5, h * 0.13, w * 0.5, h * 0.13);

    canvas.drawPath(
      garisTepi,
      Paint()
        ..color = garis
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TetesAirPainter lama) =>
      lama.isi != isi || lama.garis != garis;
}

/// Nama aplikasi beserta tagline, dipakai di halaman splash dan login.
class NamaAplikasi extends StatelessWidget {
  const NamaAplikasi({
    super.key,
    this.ukuranJudul = 26,
    this.tampilkanSlogan = true,
    this.warnaJudul,
    this.warnaSlogan,
    this.rataTengah = false,
  });

  final double ukuranJudul;
  final bool tampilkanSlogan;
  final Color? warnaJudul;
  final Color? warnaSlogan;
  final bool rataTengah;

  static const String nama = 'RENOVA';
  static const String deskripsi = 'Laundry Management Platform';
  static const String slogan = 'Fresh Clothes. Smarter Service.';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: rataTengah
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          nama,
          textAlign: rataTengah ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: ukuranJudul,
            fontWeight: FontWeight.w800,
            color: warnaJudul ?? Warna.teksUtama,
            // Huruf renggang membuat wordmark terbaca sebagai logo, bukan
            // sebagai judul biasa.
            letterSpacing: ukuranJudul * 0.12,
          ),
        ),
        if (tampilkanSlogan) ...<Widget>[
          const SizedBox(height: Jarak.xs),
          Text(
            slogan,
            textAlign: rataTengah ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: 13,
              color: warnaSlogan ?? Warna.teksKedua,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
