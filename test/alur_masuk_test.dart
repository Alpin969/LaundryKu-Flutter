// Pengujian alur halaman: dari halaman masuk sampai beranda.
//
// Yang diuji di sini adalah bug yang tidak terlihat oleh pengujian lain:
// halaman daftar dibuka lewat Navigator.push di atas halaman masuk. Setelah
// pendaftaran berhasil, gerbang aplikasi hanya mengganti RUTE PERTAMA, jadi
// formulir pendaftaran tetap menutupi beranda dan pengguna merasa
// pendaftarannya tidak berhasil. Pengujian ini menuntut halaman daftar benar
// benar sudah tertutup saat beranda muncul.
//
// Backend tidak dipakai: seluruh permintaan dilayani klien HTTP buatan lewat
// ApiClient.klienUji, sehingga berkas ini berjalan pada `flutter test` biasa
// tanpa jaringan dan tanpa server.
//
// CATATAN pengujian widget: setiap Future di sini selesai pada giliran
// berikutnya, jadi pengujian memakai pump berulang (bukan pumpAndSettle) agar
// tidak bergantung pada animasi yang mungkin tidak pernah tenang.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:renova/main.dart';
import 'package:renova/screens/auth/login_screen.dart';
import 'package:renova/screens/auth/register_screen.dart';
import 'package:renova/screens/shells/shell_pelanggan.dart';
import 'package:renova/services/api_client.dart';
import 'package:renova/services/auth_service.dart';

/// Akun yang dikembalikan klien buatan, bentuknya sama dengan backend.
const Map<String, dynamic> _akun = <String, dynamic>{
  'id': 7,
  'name': 'Pelanggan Uji',
  'email': 'pelanggan@renova.test',
  'role': 'CUSTOMER',
  'created_at': '2026-11-16T10:00:00.000Z',
};

void main() {
  setUpAll(() async {
    // Beranda memformat rupiah dan tanggal dengan aturan Indonesia.
    await initializeDateFormatting('id_ID');

    // Font asli dimuat supaya lebar teks sama dengan di perangkat. Tanpa itu,
    // flutter_test memakai font bawaan yang setiap hurufnya selebar satu em,
    // sehingga muncul laporan luapan yang tidak nyata.
    await _muatFontPoppins();
  });

  setUp(() async {
    // flutter_secure_storage tidak punya sisi platform di dalam pengujian, dan
    // panggilan kanalnya tidak pernah selesai di sana. Pengganti resmi dari
    // plugin ini dipakai supaya penyimpanan token berjalan seperti biasa.
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    ApiClient.instance.klienUji = _klienPalsu();
    // Keadaan awal setiap pengujian: belum masuk.
    await AuthService.instance.keluar();
  });

  tearDown(() {
    ApiClient.instance.klienUji = null;
  });

  testWidgets('masuk berhasil langsung menampilkan beranda pelanggan', (
    WidgetTester tester,
  ) async {
    await _pasangAplikasi(tester);

    expect(find.byType(LoginScreen), findsOneWidget);

    final Finder bidang = _bidangDi(LoginScreen);
    await tester.enterText(bidang.at(0), 'pelanggan@renova.test');
    await tester.enterText(bidang.at(1), 'rahasia123');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await _tenang(tester);

    expect(
      find.byType(LoginScreen),
      findsNothing,
      reason: 'Halaman masuk harus sudah diganti beranda.',
    );
    expect(find.byType(ShellPelanggan), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);

    await _selesaikanPesan(tester);
  });

  testWidgets('daftar berhasil langsung menampilkan beranda pelanggan', (
    WidgetTester tester,
  ) async {
    await _pasangAplikasi(tester);

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Daftar di sini'));
    await _tenang(tester);

    expect(find.byType(RegisterScreen), findsOneWidget);

    final Finder bidang = _bidangDi(RegisterScreen);
    await tester.enterText(bidang.at(0), 'Pelanggan Uji');
    await tester.enterText(bidang.at(1), 'pelanggan@renova.test');
    await tester.enterText(bidang.at(2), 'rahasia123');
    await tester.enterText(bidang.at(3), 'rahasia123');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await _tenang(tester);

    expect(
      find.byType(RegisterScreen),
      findsNothing,
      reason:
          'Halaman daftar dibuka lewat Navigator.push, sehingga harus menutup '
          'dirinya sendiri. Tanpa itu formulir tetap menutupi beranda.',
    );
    expect(find.byType(ShellPelanggan), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);

    await _selesaikanPesan(tester);
  });
}

/// Memasang aplikasi sungguhan (gerbang sesi ikut diuji) pada layar tinggi,
/// supaya seluruh kolom formulir dan tombolnya berada di dalam layar.
Future<void> _pasangAplikasi(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const AplikasiRenova());
  await _tenang(tester);
}

/// Bidang isian milik satu halaman saja.
///
/// Halaman di bawahnya masih ada di dalam pohon widget (rute sebelumnya),
/// jadi pencarian dibatasi ke halaman yang sedang diuji.
Finder _bidangDi(Type halaman) {
  return find.descendant(
    of: find.byType(halaman),
    matching: find.byType(TextFormField),
  );
}

/// Memajukan waktu beberapa kali tanpa menuntut layar benar-benar tenang.
Future<void> _tenang(WidgetTester tester, {int langkah = 12}) async {
  for (int i = 0; i < langkah; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Menghabiskan masa tampil pesan berhasil, supaya tidak ada pewaktu yang
/// masih berjalan saat pengujian selesai.
Future<void> _selesaikanPesan(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Klien HTTP buatan: menjawab seperti backend RENOVA, tanpa jaringan.
MockClient _klienPalsu() {
  return MockClient((http.Request permintaan) async {
    final String jalur = permintaan.url.path;

    if (jalur == '/api/auth/login' || jalur == '/api/auth/register') {
      return _balas(200, <String, dynamic>{
        'user': _akun,
        'token': 'token-uji-palsu',
      });
    }

    if (jalur == '/api/auth/me') {
      return _balas(200, <String, dynamic>{'user': _akun});
    }

    if (jalur == '/api/services') {
      return _balas(200, <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 1,
          'name': 'Cuci Kering Setrika',
          'description': 'Dicuci, dikeringkan, disetrika, lalu dilipat.',
          'price_per_kg': '7000.00',
          'duration': '3 hari',
        },
      ]);
    }

    if (jalur == '/api/orders') {
      return _balas(200, <dynamic>[]);
    }

    return http.Response(
      jsonEncode(<String, dynamic>{
        'success': false,
        'message': 'Jalur $jalur tidak ada di klien uji.',
        'error': 'NOT_FOUND',
      }),
      404,
      headers: _header,
    );
  });
}

const Map<String, String> _header = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

http.Response _balas(int kode, Object isi) {
  return http.Response(
    jsonEncode(<String, dynamic>{
      'success': true,
      'message': 'ok',
      'data': isi,
    }),
    kode,
    headers: _header,
  );
}

/// Memuat font asli ke dalam pengujian.
///
/// Sama seperti yang dilakukan `tata_letak_test.dart`: pengukuran teks dengan
/// font bawaan flutter_test tidak mewakili tampilan sebenarnya.
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
