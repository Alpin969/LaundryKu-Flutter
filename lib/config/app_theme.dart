import 'package:flutter/material.dart';

/// Palet dan gaya visual LaundryKu.
///
/// Nilai di bawah disamakan dengan token yang sudah dipakai website admin
/// (`web-admin/assets/css/style.css`) supaya aplikasi mobile dan website admin
/// terlihat sebagai satu produk yang sama, bukan dua aplikasi berbeda.
///
/// Dipusatkan di satu berkas supaya seluruh halaman memakai warna yang sama.
class Warna {
  const Warna._();

  /// Biru utama LaundryKu (--biru-700 pada website admin).
  static const Color primary = Color(0xFF1B4F9C);
  static const Color primaryGelap = Color(0xFF123A75);
  static const Color primaryTua = Color(0xFF0D2A55);

  /// Biru muda sebagai aksen, untuk lencana dan latar terpilih.
  static const Color aksen = Color(0xFFDCE9FA);
  static const Color aksenLembut = Color(0xFFF1F6FD);

  static const Color permukaan = Color(0xFFFFFFFF);
  static const Color latar = Color(0xFFF5F7FA);

  /// Navy gelap untuk teks utama.
  static const Color teksUtama = Color(0xFF14213D);
  static const Color teksKedua = Color(0xFF5B6B83);
  static const Color teksSamar = Color(0xFF64748B);

  /// Garis tipis untuk pemisah dan tepi kartu.
  static const Color garis = Color(0xFFDEE6F1);

  static const Color sukses = Color(0xFF14663A);
  static const Color suksesMuda = Color(0xFFE2F3E9);

  static const Color peringatan = Color(0xFF8A5200);
  static const Color peringatanMuda = Color(0xFFFDF0D9);

  static const Color bahaya = Color(0xFFA32318);
  static const Color bahayaMuda = Color(0xFFFCE8E6);
}

/// Skala jarak. Semua padding dan margin di aplikasi memakai salah satu dari
/// nilai ini supaya irama antar halaman seragam.
class Jarak {
  const Jarak._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Skala sudut membulat. Dipakai berbeda sesuai peran elemen, bukan satu nilai
/// untuk semua: kolom isian lebih kecil dari kartu, dan hanya lencana status
/// yang berbentuk pil.
class Sudut {
  const Sudut._();

  static const double kolomIsian = 12;
  static const double tombol = 12;
  static const double kartu = 16;
  static const double dialog = 20;
  static const double pil = 999;
}

/// Bayangan tipis untuk elemen yang memang perlu terangkat dari latar.
/// Sebagian besar kartu memakai garis saja, bukan bayangan.
const List<BoxShadow> bayanganKartu = <BoxShadow>[
  BoxShadow(color: Color(0x140D2A55), blurRadius: 14, offset: Offset(0, 4)),
];

/// Tema aplikasi.
///
/// Font Poppins disertakan sebagai aset (lihat bagian `fonts` di pubspec.yaml),
/// jadi tidak perlu diunduh saat aplikasi berjalan.
class AppTheme {
  const AppTheme._();

  static const String _font = 'Poppins';

  static ThemeData terang() {
    final ColorScheme skema = ColorScheme.fromSeed(
      seedColor: Warna.primary,
      primary: Warna.primary,
      surface: Warna.permukaan,
      error: Warna.bahaya,
    );

    return ThemeData(
      colorScheme: skema,
      useMaterial3: true,
      scaffoldBackgroundColor: Warna.latar,
      fontFamily: _font,
      textTheme: _teksDasar().apply(
        bodyColor: Warna.teksUtama,
        displayColor: Warna.teksUtama,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Warna.permukaan,
        foregroundColor: Warna.teksUtama,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _gaya(
          ukuran: 18,
          berat: FontWeight.w600,
          warna: Warna.teksUtama,
        ),
      ),

      cardTheme: const CardThemeData(
        color: Warna.permukaan,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Sudut.kartu)),
          side: BorderSide(color: Warna.garis),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Warna.permukaan,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Jarak.lg,
          vertical: Jarak.lg,
        ),
        hintStyle: _gaya(ukuran: 14, warna: Warna.teksSamar),
        labelStyle: _gaya(ukuran: 14, warna: Warna.teksKedua),
        floatingLabelStyle: _gaya(ukuran: 14, warna: Warna.primary),
        errorStyle: _gaya(ukuran: 12.5, warna: Warna.bahaya),
        helperStyle: _gaya(ukuran: 12.5, warna: Warna.teksKedua),
        prefixIconColor: Warna.teksKedua,
        suffixIconColor: Warna.teksKedua,
        border: _garisKolom(Warna.garis),
        enabledBorder: _garisKolom(Warna.garis),
        focusedBorder: _garisKolom(Warna.primary, lebar: 1.5),
        errorBorder: _garisKolom(Warna.bahaya),
        focusedErrorBorder: _garisKolom(Warna.bahaya, lebar: 1.5),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Warna.primary,
          foregroundColor: Colors.white,
          // 52 px: nyaman disentuh jempol dan di atas batas minimum 44 px.
          minimumSize: const Size.fromHeight(52),
          textStyle: _gaya(ukuran: 15, berat: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sudut.tombol),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Warna.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: Warna.garis),
          textStyle: _gaya(ukuran: 15, berat: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sudut.tombol),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Warna.primary,
          minimumSize: const Size(0, 44),
          textStyle: _gaya(ukuran: 14, berat: FontWeight.w600),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Warna.teksKedua,
          minimumSize: const Size(44, 44),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Warna.permukaan,
        indicatorColor: Warna.aksen,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          final bool terpilih = states.contains(WidgetState.selected);
          return _gaya(
            ukuran: 11.5,
            berat: terpilih ? FontWeight.w600 : FontWeight.w500,
            warna: terpilih ? Warna.primary : Warna.teksKedua,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool terpilih = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: terpilih ? Warna.primary : Warna.teksKedua,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Warna.permukaan,
        selectedColor: Warna.aksen,
        side: const BorderSide(color: Warna.garis),
        labelStyle: _gaya(ukuran: 13, berat: FontWeight.w500),
        padding: const EdgeInsets.symmetric(
          horizontal: Jarak.md,
          vertical: Jarak.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sudut.pil),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Warna.permukaan,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sudut.dialog),
        ),
        titleTextStyle: _gaya(ukuran: 17, berat: FontWeight.w600),
        contentTextStyle: _gaya(
          ukuran: 14,
          warna: Warna.teksKedua,
          tinggi: 1.6,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Warna.teksUtama,
        contentTextStyle: _gaya(ukuran: 14, warna: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sudut.kolomIsian),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Warna.garis,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Warna.primary,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Warna.permukaan,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Sudut.dialog),
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: Warna.teksKedua,
        textColor: Warna.teksUtama,
      ),
    );
  }

  /// Tiga tingkat ukuran teks sudah cukup untuk hampir seluruh halaman:
  /// 12,5-13 untuk keterangan, 14-15 untuk isi, 17-22 untuk judul.
  static TextTheme _teksDasar() {
    return TextTheme(
      displaySmall: _gaya(ukuran: 30, berat: FontWeight.w700, tinggi: 1.2),
      headlineMedium: _gaya(ukuran: 24, berat: FontWeight.w700, tinggi: 1.25),
      headlineSmall: _gaya(ukuran: 20, berat: FontWeight.w600, tinggi: 1.3),
      titleLarge: _gaya(ukuran: 18, berat: FontWeight.w600, tinggi: 1.35),
      titleMedium: _gaya(ukuran: 15.5, berat: FontWeight.w600, tinggi: 1.4),
      titleSmall: _gaya(ukuran: 14, berat: FontWeight.w600, tinggi: 1.4),
      bodyLarge: _gaya(ukuran: 15, tinggi: 1.6),
      bodyMedium: _gaya(ukuran: 14, tinggi: 1.6),
      bodySmall: _gaya(ukuran: 12.5, warna: Warna.teksKedua, tinggi: 1.55),
      labelLarge: _gaya(ukuran: 14, berat: FontWeight.w600),
      labelMedium: _gaya(ukuran: 12.5, berat: FontWeight.w500),
      labelSmall: _gaya(ukuran: 11.5, berat: FontWeight.w500),
    );
  }

  static TextStyle _gaya({
    double ukuran = 14,
    FontWeight berat = FontWeight.w400,
    Color warna = Warna.teksUtama,
    double? tinggi,
  }) {
    return TextStyle(
      fontFamily: _font,
      fontSize: ukuran,
      fontWeight: berat,
      color: warna,
      height: tinggi,
    );
  }

  static OutlineInputBorder _garisKolom(Color warna, {double lebar = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sudut.kolomIsian),
      borderSide: BorderSide(color: warna, width: lebar),
    );
  }
}
