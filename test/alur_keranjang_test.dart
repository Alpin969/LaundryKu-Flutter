// Pengujian alur keranjang: dari isi keranjang sampai "Pesan & Bayar", juga
// jalan pintas "Bayar Langsung" dari halaman detail layanan.
//
// Yang diperiksa di sini adalah hal yang tidak terlihat oleh pengujian lain:
// setiap layanan di keranjang harus menjadi SATU pesanan, dan metode
// pembayaran yang dipilih pelanggan harus benar-benar ikut terkirim ke
// backend. Tanpa itu, pesanan tunai akan tercatat lunas, atau sebaliknya.
//
// Backend tidak dipakai: seluruh permintaan dilayani klien HTTP buatan lewat
// ApiClient.klienUji, sehingga berkas ini berjalan pada `flutter test` biasa
// tanpa jaringan dan tanpa server.
//
// CATATAN pengujian widget: pengujian memakai pump berulang (bukan
// pumpAndSettle), karena penanda "sedang mengirim" berputar terus selama
// proses berjalan sehingga layar tidak pernah benar-benar tenang.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laundryku/config/app_theme.dart';
import 'package:laundryku/models/layanan.dart';
import 'package:laundryku/screens/customer/form_pemesanan_screen.dart';
import 'package:laundryku/screens/customer/keranjang_screen.dart';
import 'package:laundryku/services/api_client.dart';
import 'package:laundryku/services/keranjang_service.dart';

/// Layanan yang dipakai mengisi keranjang.
const Layanan _cuciKering = Layanan(
  id: 17,
  nama: 'Cuci Kering Setrika',
  deskripsi: 'Pakaian dicuci, dikeringkan, disetrika, lalu dilipat rapi.',
  hargaPerKg: 7000,
  durasi: '2 hari',
);

const Layanan _bedCover = Layanan(
  id: 21,
  nama: 'Bed Cover dan Selimut',
  deskripsi: 'Khusus bed cover, selimut, dan kain tebal.',
  hargaPerKg: 15000,
  durasi: '3 hari',
);

void main() {
  setUpAll(() async {
    // Halaman keranjang memformat rupiah dengan aturan Indonesia.
    await initializeDateFormatting('id_ID');

    // Font asli dimuat supaya lebar teks sama dengan di perangkat. Tanpa itu,
    // flutter_test memakai font bawaan yang setiap hurufnya selebar satu em,
    // sehingga muncul laporan luapan yang tidak nyata.
    await _muatFontPoppins();
  });

  setUp(() {
    ApiClient.instance.klienUji = _klienPalsu();
    KeranjangService.instance.kosongkan();
  });

  tearDown(() {
    ApiClient.instance.klienUji = null;
    KeranjangService.instance.kosongkan();
  });

  testWidgets('satu layanan di keranjang menjadi satu pesanan', (
    WidgetTester tester,
  ) async {
    final List<Map<String, dynamic>> permintaan = <Map<String, dynamic>>[];

    ApiClient.instance.klienUji = _klienPalsu(catatanPermintaan: permintaan);

    KeranjangService.instance.tambah(
      layanan: _cuciKering,
      beratPerkiraan: 3.5,
    );

    await _pasangKeranjang(tester);
    await _pesanDanBayar(tester);

    final List<Map<String, dynamic>> pembuatan = permintaan
        .where((Map<String, dynamic> p) => p['jalur'] == '/api/orders')
        .toList();

    expect(
      pembuatan.length,
      1,
      reason: 'Satu layanan di keranjang harus menjadi tepat satu pesanan.',
    );
    expect(pembuatan.first['service_id'], 17);
    expect(pembuatan.first['estimated_weight'], 3.5);

    expect(
      KeranjangService.instance.kosong,
      isTrue,
      reason: 'Keranjang harus kosong setelah pesanannya dibuat.',
    );

    await _selesaikanPesan(tester);
  });

  testWidgets('dua layanan menjadi dua pesanan yang dibayar sekali', (
    WidgetTester tester,
  ) async {
    final List<Map<String, dynamic>> permintaan = <Map<String, dynamic>>[];

    ApiClient.instance.klienUji = _klienPalsu(catatanPermintaan: permintaan);

    KeranjangService.instance.tambah(layanan: _cuciKering, beratPerkiraan: 3.5);
    KeranjangService.instance.tambah(layanan: _bedCover, beratPerkiraan: 2);

    await _pasangKeranjang(tester);
    await _pesanDanBayar(tester);

    final List<Map<String, dynamic>> pembuatan = permintaan
        .where((Map<String, dynamic> p) => p['jalur'] == '/api/orders')
        .toList();

    expect(pembuatan.length, 2);
    expect(
      pembuatan.map((Map<String, dynamic> p) => p['service_id']).toSet(),
      <int>{17, 21},
    );

    // Keduanya harus memakai metode pembayaran yang sama, sebesar apa pun
    // isi keranjangnya.
    expect(
      pembuatan
          .map((Map<String, dynamic> p) => p['payment_method'])
          .toSet()
          .length,
      1,
      reason: 'Seluruh pesanan dari satu keranjang dibayar dengan satu metode.',
    );

    await _selesaikanPesan(tester);
  });

  testWidgets('pilihan tunai terkirim sebagai CASH tanpa menandai lunas', (
    WidgetTester tester,
  ) async {
    final List<Map<String, dynamic>> permintaan = <Map<String, dynamic>>[];

    ApiClient.instance.klienUji = _klienPalsu(catatanPermintaan: permintaan);

    KeranjangService.instance.tambah(layanan: _bedCover, beratPerkiraan: 2);

    await _pasangKeranjang(tester);

    // Tunai sudah terpilih sejak awal, jadi membayarnya tanpa mengubah
    // pilihan harus tetap mengirim CASH.
    await tester.tap(find.widgetWithText(FilledButton, 'Pesan & Bayar'));
    await _tenang(tester);

    final Map<String, dynamic> pembuatan = permintaan.firstWhere(
      (Map<String, dynamic> p) => p['jalur'] == '/api/orders',
    );

    expect(pembuatan['payment_method'], 'CASH');

    // Pesan hasilnya menyebut pembayaran tunai dikonfirmasi admin, bukan
    // diklaim sudah lunas.
    expect(find.textContaining('admin mengonfirmasi'), findsOneWidget);

    await _selesaikanPesan(tester);
  });

  testWidgets('pilihan QRIS terkirim sebagai QRIS dan langsung lunas', (
    WidgetTester tester,
  ) async {
    final List<Map<String, dynamic>> permintaan = <Map<String, dynamic>>[];

    ApiClient.instance.klienUji = _klienPalsu(catatanPermintaan: permintaan);

    KeranjangService.instance.tambah(layanan: _cuciKering, beratPerkiraan: 4);

    await _pasangKeranjang(tester);

    await tester.tap(find.text('QRIS'));
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Pesan & Bayar'));
    await _tenang(tester);

    final Map<String, dynamic> pembuatan = permintaan.firstWhere(
      (Map<String, dynamic> p) => p['jalur'] == '/api/orders',
    );

    expect(pembuatan['payment_method'], 'QRIS');
    expect(find.textContaining('sudah ditandai lunas'), findsOneWidget);

    await _selesaikanPesan(tester);
  });

  testWidgets('keranjang kosong tidak menawarkan pembayaran', (
    WidgetTester tester,
  ) async {
    await _pasangKeranjang(tester);

    expect(find.text('Keranjang masih kosong'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Pesan & Bayar'),
      findsNothing,
      reason:
          'Tanpa isi keranjang, tidak ada yang bisa dibayar dan tombolnya '
          'tidak boleh muncul.',
    );
    expect(find.text('Metode pembayaran'), findsNothing);
  });

  testWidgets('bayar langsung membawa isi form ke halaman pembayaran', (
    WidgetTester tester,
  ) async {
    await _pasangForm(tester);

    expect(
      find.widgetWithText(FilledButton, 'Lanjut ke Pembayaran'),
      findsOneWidget,
      reason:
          'Form yang dibuka dari tombol Bayar Langsung harus menawarkan '
          'lanjut ke pembayaran, bukan sekadar simpan ke keranjang.',
    );

    await tester.enterText(find.byType(TextFormField), '3.5');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut ke Pembayaran'));
    await _tenang(tester);

    expect(
      find.byType(KeranjangScreen),
      findsOneWidget,
      reason:
          'Setelah form disimpan, pelanggan harus sudah berada di halaman '
          'pembayaran tanpa membuka keranjang sendiri.',
    );
    expect(KeranjangService.instance.jumlah, 1);
    expect(KeranjangService.instance.item.single.beratPerkiraan, 3.5);

    await _selesaikanPesan(tester);
  });
}

/// Memasang halaman keranjang pada layar tinggi, supaya ringkasan dan tombol
/// bayarnya ikut berada di dalam layar.
Future<void> _pasangKeranjang(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.terang(),
      home: const KeranjangScreen(),
    ),
  );

  await _tenang(tester);
}

/// Memasang form pemesanan seperti dibuka dari tombol "Bayar Langsung".
Future<void> _pasangForm(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.terang(),
      home: const FormPemesananScreen(
        layananAwal: _cuciKering,
        langsungBayar: true,
      ),
    ),
  );

  await _tenang(tester);
}

/// Menekan "Pesan & Bayar" dengan metode pembayaran yang sedang terpilih.
Future<void> _pesanDanBayar(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Pesan & Bayar'));
  await _tenang(tester);
}

/// Memajukan waktu beberapa kali tanpa menuntut layar benar-benar tenang.
Future<void> _tenang(WidgetTester tester, {int langkah = 12}) async {
  for (int i = 0; i < langkah; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Menghabiskan masa tampil pesan hasil, supaya tidak ada pewaktu yang masih
/// berjalan saat pengujian selesai.
Future<void> _selesaikanPesan(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Klien HTTP buatan: menjawab seperti backend LaundryKu, tanpa jaringan.
///
/// Bila [catatanPermintaan] diisi, setiap permintaan yang masuk dicatat pada
/// daftar itu supaya pengujian bisa memeriksa isi body yang benar-benar
/// dikirim aplikasi.
MockClient _klienPalsu({List<Map<String, dynamic>>? catatanPermintaan}) {
  int idBerikutnya = 1;

  return MockClient((http.Request permintaan) async {
    final String jalur = permintaan.url.path;

    // Pesanan baru selalu dimulai dari menunggu konfirmasi, dengan status
    // pembayaran sesuai metode yang dikirim seperti di backend.
    Map<String, dynamic>? body;

    if (permintaan.method == 'POST' && jalur == '/api/orders') {
      body = Map<String, dynamic>.from(
        jsonDecode(permintaan.body) as Map<String, dynamic>,
      );

      final String? metode = body['payment_method'] as String?;
      catatanPermintaan?.add(<String, dynamic>{
        'jalur': jalur,
        'service_id': body['service_id'],
        'estimated_weight': body['estimated_weight'],
        'payment_method': metode,
      });

      return _balas(201, _pesananUji(
        id: idBerikutnya++,
        serviceId: body['service_id'] as int? ?? 0,
        beratPerkiraan: (body['estimated_weight'] as num).toDouble(),
        metode: metode,
      ));
    }

    if (permintaan.method == 'GET' && jalur.startsWith('/api/orders/')) {
      // Pengambilan susulan setelah pesanan dibuat; isinya sama saja.
      final int id = int.tryParse(jalur.split('/').last) ?? 1;

      return _balas(
        200,
        _pesananUji(
          id: id,
          serviceId: _cuciKering.id,
          beratPerkiraan: 3.5,
          metode: null,
        ),
      );
    }

    if (permintaan.method == 'GET' && jalur == '/api/services') {
      return _balas(200, <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 17,
          'name': 'Cuci Kering Setrika',
          'description':
              'Pakaian dicuci, dikeringkan, disetrika, lalu dilipat rapi.',
          'price_per_kg': '7000.00',
          'duration': '2 hari',
        },
        <String, dynamic>{
          'id': 21,
          'name': 'Bed Cover dan Selimut',
          'description': 'Khusus bed cover, selimut, dan kain tebal.',
          'price_per_kg': '15000.00',
          'duration': '3 hari',
        },
      ]);
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

/// Bentuk satu pesanan seperti yang dikirim backend.
Map<String, dynamic> _pesananUji({
  required int id,
  required int serviceId,
  required double beratPerkiraan,
  required String? metode,
}) {
  final bool tunai = metode == 'CASH';
  final bool adaMetode = metode != null;

  return <String, dynamic>{
    'id': id,
    'user_id': 7,
    'customer_name': 'Pelanggan Uji',
    'customer_email': 'pelanggan@laundryku.test',
    'service_id': serviceId,
    'service_name': 'Cuci Kering Setrika',
    'service_duration': '2 hari',
    'estimated_weight': beratPerkiraan.toString(),
    'actual_weight': null,
    'price_per_kg': '7000.00',
    'total_price': null,
    'status': 'PENDING_CONFIRMATION',
    'photo_url': null,
    'payment_method': metode,
    'payment_status': adaMetode ? (tunai ? 'UNPAID' : 'PAID') : null,
    'paid_at': adaMetode && !tunai ? '2026-11-17T16:20:50.318Z' : null,
    'created_at': '2026-11-17T16:20:50.000Z',
  };
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
