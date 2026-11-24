import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:renova/config/app_theme.dart';
import 'package:renova/models/layanan.dart';
import 'package:renova/models/pesanan.dart';
import 'package:renova/models/status_pesanan.dart';
import 'package:renova/screens/auth/login_screen.dart';
import 'package:renova/screens/auth/register_screen.dart';
import 'package:renova/screens/auth/splash_screen.dart';
import 'package:renova/screens/customer/ubah_profil_screen.dart';
import 'package:renova/widgets/app_logo.dart';
import 'package:renova/widgets/baris_detail.dart';
import 'package:renova/widgets/kartu_layanan.dart';
import 'package:renova/widgets/kartu_pesanan.dart';
import 'package:renova/widgets/lencana_status.dart';
import 'package:renova/widgets/tampilan_status.dart';

/// Pengujian tata letak pada berbagai ukuran layar.
///
/// Flutter melaporkan isi layar yang tumpang tindih atau terpotong sebagai
/// kesalahan (RenderFlex overflow) saat pengujian, sehingga pengujian ini gagal
/// begitu ada bagian layar yang tidak muat. Ukuran yang dipakai mewakili ponsel
/// kecil, ponsel umum, ponsel besar, dan tablet.
///
/// Font Poppins asli dimuat lebih dulu di [setUpAll]. Tanpa itu, pengujian
/// memakai font bawaan flutter_test yang setiap hurufnya selebar satu em,
/// sehingga teks terlihat jauh lebih panjang daripada aslinya dan hasil
/// pengujiannya tidak bisa dipercaya.
void main() {
  setUpAll(() async {
    // Format tanggal dan mata uang memakai aturan Indonesia, dan data locale
    // itu harus dimuat lebih dulu — sama seperti yang dilakukan main.dart.
    await initializeDateFormatting('id_ID');
    await _muatFontPoppins();
  });

  const List<({String nama, Size ukuran})> ukuranLayar =
      <({String nama, Size ukuran})>[
        (nama: 'ponsel kecil 320x568', ukuran: Size(320, 568)),
        (nama: 'ponsel umum 360x640', ukuran: Size(360, 640)),
        (nama: 'ponsel besar 414x896', ukuran: Size(414, 896)),
        (nama: 'tablet 768x1024', ukuran: Size(768, 1024)),
      ];

  /// Memasang satu layar pada ukuran tertentu, lalu menggulirnya sampai bawah
  /// supaya bagian yang tadinya di luar layar juga ikut diperiksa.
  ///
  /// [adaAnimasiBerulang] dipakai halaman yang punya penanda "sedang memuat",
  /// karena animasinya tidak pernah berhenti sehingga pengujian tidak bisa
  /// menunggu layar tenang.
  Future<void> pasangLayar(
    WidgetTester tester,
    Widget layar,
    Size ukuran, {
    bool adaAnimasiBerulang = false,
  }) async {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.terang(), home: layar),
    );

    if (adaAnimasiBerulang) {
      await tester.pump(const Duration(milliseconds: 300));
    } else {
      await tester.pumpAndSettle();
    }

    final Finder dapatDigulir = find.byType(Scrollable);
    if (dapatDigulir.evaluate().isNotEmpty) {
      await tester.drag(dapatDigulir.first, const Offset(0, -600));
      await tester.pump(adaAnimasiBerulang
          ? const Duration(milliseconds: 300)
          : const Duration(seconds: 1));
    }
  }

  group('Tata letak halaman autentikasi', () {
    for (final ({String nama, Size ukuran}) layar in ukuranLayar) {
      testWidgets('halaman masuk muat di ${layar.nama}', (tester) async {
        await pasangLayar(tester, const LoginScreen(), layar.ukuran);
        expect(tester.takeException(), isNull);
      });

      testWidgets('halaman daftar muat di ${layar.nama}', (tester) async {
        await pasangLayar(tester, const RegisterScreen(), layar.ukuran);
        expect(tester.takeException(), isNull);
      });

      testWidgets('halaman splash muat di ${layar.nama}', (tester) async {
        await pasangLayar(
          tester,
          const SplashScreen(),
          layar.ukuran,
          adaAnimasiBerulang: true,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('halaman ubah profil muat di ${layar.nama}', (tester) async {
        await pasangLayar(tester, const UbahProfilScreen(), layar.ukuran);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Tata letak komponen pesanan', () {
    final Pesanan pesananPerkiraan = Pesanan(
      id: 123,
      userId: 9,
      namaPelanggan: 'Nama Pelanggan Yang Panjang Sekali',
      emailPelanggan: 'pelanggan-panjang@renova.test',
      serviceId: 4,
      namaLayanan: 'Cuci Kering Setrika Express',
      durasiLayanan: '3 hari',
      beratPerkiraan: 3.5,
      beratAktual: null,
      hargaPerKg: 7500,
      totalHarga: null,
      status: StatusPesanan.menungguKonfirmasi,
      photoUrl: null,
      dibuatPada: DateTime(2026, 1, 2, 9, 30),
    );

    final Pesanan pesananSelesai = Pesanan(
      id: 124,
      userId: 9,
      namaPelanggan: 'Nama Pelanggan Yang Panjang Sekali',
      emailPelanggan: 'pelanggan-panjang@renova.test',
      serviceId: 4,
      namaLayanan: 'Cuci Kering Setrika Express',
      durasiLayanan: '3 hari',
      beratPerkiraan: 3.5,
      beratAktual: 4.25,
      hargaPerKg: 7500,
      totalHarga: 31875,
      status: StatusPesanan.selesai,
      photoUrl: null,
      dibuatPada: DateTime(2026, 1, 2, 9, 30),
    );

    final Layanan layanan = Layanan(
      id: 1,
      nama: 'Cuci Kering Setrika Express',
      deskripsi:
          'Pakaian dicuci, dikeringkan, disetrika, lalu dilipat rapi sebelum '
          'diserahkan kembali kepada pelanggan.',
      hargaPerKg: 7500,
      durasi: '3 hari',
    );

    for (final ({String nama, Size ukuran}) layar in ukuranLayar) {
      testWidgets('kartu pesanan tanpa berat asli muat di ${layar.nama}', (
        tester,
      ) async {
        await pasangLayar(
          tester,
          Scaffold(
            body: ListView(
              children: <Widget>[
                KartuPesanan(
                  pesanan: pesananPerkiraan,
                  onTap: () {},
                  tampilkanPelanggan: true,
                ),
              ],
            ),
          ),
          layar.ukuran,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('kartu pesanan selesai muat di ${layar.nama}', (
        tester,
      ) async {
        await pasangLayar(
          tester,
          Scaffold(
            body: ListView(
              children: <Widget>[
                KartuPesanan(pesanan: pesananSelesai, onTap: () {}),
              ],
            ),
          ),
          layar.ukuran,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('kartu layanan muat di ${layar.nama}', (tester) async {
        await pasangLayar(
          tester,
          Scaffold(
            body: ListView(
              children: <Widget>[
                KartuLayanan(layanan: layanan, onTap: () {}),
              ],
            ),
          ),
          layar.ukuran,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Tata letak lencana dan tahapan status', () {
    // Layar sempit dipakai supaya lencana panjang seperti "Menunggu
    // Konfirmasi" benar-benar diuji di ruang yang paling sesak.
    const Size sempit = Size(320, 568);

    for (final StatusPesanan status in StatusPesanan.values) {
      testWidgets('lencana ${status.label} muat di layar sempit', (tester) async {
        await pasangLayar(
          tester,
          Scaffold(body: Center(child: LencanaStatus(status: status))),
          sempit,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('tahapan ${status.label} muat di layar sempit', (
        tester,
      ) async {
        await pasangLayar(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TahapanPesanan(status: status),
            ),
          ),
          sempit,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('lencana panjang pada kartu pesanan tetap muat', (tester) async {
      // Kartu pesanan menaruh lencana di samping foto, jadi ini ruang paling
      // sempit yang pernah ditempati lencana.
      await pasangLayar(
        tester,
        Scaffold(
          body: ListView(
            children: <Widget>[
              KartuPesanan(
                pesanan: Pesanan(
                  id: 7,
                  userId: 3,
                  namaPelanggan: 'Pelanggan',
                  emailPelanggan: 'p@renova.test',
                  serviceId: 1,
                  namaLayanan: 'Cuci Kering Setrika Express',
                  durasiLayanan: '3 hari',
                  beratPerkiraan: 2,
                  beratAktual: null,
                  hargaPerKg: 7500,
                  totalHarga: null,
                  status: StatusPesanan.menungguKonfirmasi,
                  photoUrl: null,
                  dibuatPada: DateTime(2026, 1, 2, 9, 30),
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
        sempit,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Tata letak penanda keadaan', () {
    const Size sempit = Size(320, 568);

    testWidgets('penanda memuat muat', (tester) async {
      await pasangLayar(
        tester,
        const Scaffold(
          body: TampilanMemuat(keterangan: 'Memuat detail pesanan...'),
        ),
        sempit,
        adaAnimasiBerulang: true,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('penanda gagal dengan pesan panjang tetap muat', (tester) async {
      await pasangLayar(
        tester,
        Scaffold(
          body: TampilanGagal(
            pesan:
                'Tidak bisa terhubung ke RENOVA. Periksa koneksi internet '
                'Anda, lalu coba lagi.',
            judul: 'Pesanan tidak bisa dimuat',
            onCobaLagi: () {},
          ),
        ),
        sempit,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('penanda kosong tetap muat', (tester) async {
      await pasangLayar(
        tester,
        Scaffold(
          body: TampilanKosong(
            judul: 'Belum ada pesanan',
            pesan:
                'Pesanan yang Anda buat akan muncul di sini. Tekan tombol '
                'Pesan Laundry untuk membuat pesanan pertama.',
            labelTombol: 'Pesan Laundry',
            onTombol: () {},
          ),
        ),
        sempit,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('baris detail dengan nilai panjang tetap muat', (tester) async {
      await pasangLayar(
        tester,
        const Scaffold(
          body: SingleChildScrollView(
            child: KartuBagian(
              judul: 'Rincian Pesanan',
              anak: Column(
                children: <Widget>[
                  BarisDetail(label: 'Layanan', nilai: 'Cuci Kering Setrika'),
                  BarisDetail(
                    label: 'Total Biaya',
                    nilai: 'Rp31.875,00',
                    tebal: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        sempit,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('logo dan nama aplikasi muat di layar sempit', (tester) async {
      await pasangLayar(
        tester,
        const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppLogo(),
                SizedBox(height: 16),
                NamaAplikasi(rataTengah: true),
              ],
            ),
          ),
        ),
        sempit,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

/// Memuat berkas font yang dipakai aplikasi ke dalam lingkungan pengujian,
/// supaya lebar teks yang diukur sama dengan lebar teks aslinya.
Future<void> _muatFontPoppins() async {
  const List<String> berkas = <String>[
    'assets/fonts/PlusJakartaSans-Regular.ttf',
    'assets/fonts/PlusJakartaSans-Medium.ttf',
    'assets/fonts/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/PlusJakartaSans-Bold.ttf',
    'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
  ];

  final FontLoader pemuat = FontLoader('PlusJakartaSans');

  for (final String jalur in berkas) {
    final Uint8List isi = await File(jalur).readAsBytes();
    pemuat.addFont(Future<ByteData>.value(ByteData.sublistView(isi)));
  }

  await pemuat.load();
}
