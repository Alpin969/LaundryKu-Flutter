// Pengujian integrasi terhadap REST API RENOVA yang benar-benar berjalan.
//
// Berbeda dari logika_test.dart yang berjalan sendiri, berkas ini memanggil
// backend sungguhan, jadi backend harus hidup lebih dulu:
//
//   cd backend && npm run dev
//
// Jalankan dengan:
//
//   flutter test test/api_integration_test.dart \
//     --dart-define=UJI_API=true \
//     --dart-define=API_BASE_URL=http://localhost:3000 \
//     --dart-define=ADMIN_EMAIL=<email admin> \
//     --dart-define=ADMIN_PASSWORD=<kata sandi admin>
//
// Bagian khusus admin dilewati bila ADMIN_EMAIL tidak diisi, sehingga berkas
// ini tetap berguna untuk memeriksa bagian pelanggan saja.
//
// Tanpa --dart-define=UJI_API=true, berkas ini hanya melaporkan satu pengujian
// yang dilewati dan tidak memanggil backend sama sekali. Dengan begitu
// `flutter test` biasa tetap hijau di mesin yang tidak menjalankan backend.
//
// AKUN: satu pelanggan uji dan satu admin uji dibuat sekali di awal, lalu
// tokennya dipakai ulang oleh seluruh grup. Ini disengaja: backend membatasi
// 20 permintaan register/login per 15 menit per alamat IP
// (lihat backend/src/routes/auth.routes.js), jadi login berulang per grup
// akan membuat pengujian gagal karena 429. Karena batas itu, berkas ini aman
// dijalankan sekitar dua kali dalam 15 menit, tidak lebih.
//
// Data uji dibuat memakai awalan "[UJI MOBILE]" dan surel berakhiran
// "@renova.test" supaya mudah dikenali dan dibersihkan.
//
// WAJIB dibersihkan setelah selesai, karena layanan uji ikut tampil di pilihan
// layanan aplikasi bila dibiarkan di database:
//
//   cd backend
//   npm run bersihkan-data-uji -- --lihat    (melihat saja)
//   npm run bersihkan-data-uji               (menghapus)

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:image_picker/image_picker.dart';
import 'package:renova/config/api_config.dart';
import 'package:renova/models/layanan.dart';
import 'package:renova/models/pesanan.dart';
import 'package:renova/models/status_pesanan.dart';
import 'package:renova/models/user.dart';
import 'package:renova/services/api_client.dart';
import 'package:renova/services/auth_service.dart';
import 'package:renova/services/layanan_service.dart';
import 'package:renova/services/pesanan_service.dart';

const String _adminEmail = String.fromEnvironment('ADMIN_EMAIL');
const String _adminPassword = String.fromEnvironment('ADMIN_PASSWORD');

/// Penanda bahwa pengujian integrasi memang diminta berjalan.
///
/// Diisi lewat `--dart-define=UJI_API=true`. Tanpa penanda ini, seluruh berkas
/// dilewati supaya `flutter test` biasa tidak gagal hanya karena backend tidak
/// sedang berjalan di mesin yang memakainya.
const bool _ujiApiDiaktifkan = bool.fromEnvironment('UJI_API');

bool get _adaAdmin => _adminEmail.isNotEmpty && _adminPassword.isNotEmpty;
Object? get _lewatiAdmin =>
    _adaAdmin ? false : 'ADMIN_EMAIL dan ADMIN_PASSWORD tidak diisi.';

/// Penanda unik per jalannya pengujian, supaya data uji tidak bertabrakan.
final String _tanda = DateTime.now().millisecondsSinceEpoch.toString();

/// Akun pelanggan yang didaftarkan sendiri oleh pengujian ini.
final String _emailPelanggan = 'uji-mobile-$_tanda@renova.test';
const String _sandiPelanggan = 'UjiMobile2026!';

const LayananService _layananService = LayananService();
const PesananService _pesananService = PesananService();

// Token dan id kedua akun uji, diambil sekali di awal.
String? _tokenPelanggan;
String? _tokenAdmin;
int _idPelanggan = 0;
int _idAdmin = 0;

/// Memakai token pelanggan uji.
void pakaiPelanggan() => ApiClient.instance.token = _tokenPelanggan;

/// Memakai token admin uji.
void pakaiAdmin() => ApiClient.instance.token = _tokenAdmin;

/// Mencari layanan uji yang dibuat grup admin, atau layanan apa pun yang ada.
Future<Layanan> _layananUntukPesanan() async {
  final List<Layanan> daftar = await _layananService.daftarSemua();
  expect(daftar, isNotEmpty, reason: 'Butuh minimal satu layanan.');

  return daftar.firstWhere(
    (Layanan l) => l.nama.startsWith('[UJI MOBILE]'),
    orElse: () => daftar.first,
  );
}

/// Menjalankan aksi yang seharusnya gagal, lalu mengembalikan kesalahannya.
Future<ApiException> _harusGagal(Future<void> Function() aksi) async {
  try {
    await aksi();
  } on ApiException catch (kesalahan) {
    return kesalahan;
  } catch (kesalahan) {
    fail('Seharusnya ApiException, tetapi mendapat: $kesalahan');
  }
  fail('Aksi seharusnya gagal, tetapi berhasil.');
}

void main() {
  if (!_ujiApiDiaktifkan) {
    test(
      'Uji integrasi API',
      () {},
      skip:
          'Butuh backend berjalan. Jalankan berkas ini dengan '
          '--dart-define=UJI_API=true, alamat API, dan akun admin.',
    );
    return;
  }

  setUpAll(() async {
    // Alamat API ditampilkan sekali supaya kesalahan konfigurasi langsung
    // terlihat pada keluaran pengujian.
    // ignore: avoid_print
    print('Menguji API di: ${ApiConfig.baseUrl}');

    // Pelanggan uji didaftarkan lewat AuthService, sekaligus membuktikan alur
    // registrasi aplikasi bekerja dari ujung ke ujung.
    final User pelanggan = await AuthService.instance.daftar(
      nama: 'Uji Mobile',
      email: _emailPelanggan,
      password: _sandiPelanggan,
    );
    _idPelanggan = pelanggan.id;
    _tokenPelanggan = ApiClient.instance.token;

    if (_adaAdmin) {
      final User admin = await AuthService.instance.masuk(
        email: _adminEmail,
        password: _adminPassword,
      );
      _idAdmin = admin.id;
      _tokenAdmin = ApiClient.instance.token;
    }

    pakaiPelanggan();
  });

  group('A. Kesehatan API', () {
    test('server menjawab dan database tersambung', () async {
      final dynamic data = await ApiClient.instance.get('/api/health/db');
      expect(data['database'], isNotEmpty);
    });
  });

  group('B. Registrasi, login, dan token', () {
    setUp(pakaiPelanggan);

    test('role tidak bisa ditentukan dari aplikasi', () async {
      // Backend harus mengabaikan role yang dikirim dari luar. Kalau tidak,
      // siapa pun bisa mendaftarkan dirinya sebagai admin.
      final dynamic data = await ApiClient.instance.post(
        '/api/auth/register',
        body: <String, dynamic>{
          'name': 'Uji Peran',
          'email': 'uji-peran-$_tanda@renova.test',
          'password': _sandiPelanggan,
          'role': 'ADMIN',
        },
      );

      final User pengguna = User.dariJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );

      expect(
        pengguna.peran,
        PeranPengguna.customer,
        reason: 'Permintaan role ADMIN dari aplikasi harus diabaikan backend.',
      );
      expect(pengguna.adalahAdmin, isFalse);

      // Token dari registrasi itu tidak dipakai lagi; kembalikan ke pelanggan.
      pakaiPelanggan();
    });

    test('akun pelanggan uji aktif dan /api/auth/me mengembalikannya', () async {
      final dynamic data = await ApiClient.instance.get('/api/auth/me');
      final User pengguna = User.dariJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );

      expect(pengguna.email, _emailPelanggan);
      expect(pengguna.peran, PeranPengguna.customer);
      expect(pengguna.id, _idPelanggan);
    });

    test('email yang sudah dipakai ditolak', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await ApiClient.instance.post(
          '/api/auth/register',
          body: <String, dynamic>{
            'name': 'Uji Ganda',
            'email': _emailPelanggan,
            'password': _sandiPelanggan,
          },
        );
      });

      expect(kesalahan.statusCode, 409);
    });

    test('kata sandi terlalu pendek ditolak backend', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await ApiClient.instance.post(
          '/api/auth/register',
          body: <String, dynamic>{
            'name': 'Uji Pendek',
            'email': 'uji-pendek-$_tanda@renova.test',
            'password': 'pendek',
          },
        );
      });

      expect(kesalahan.statusCode, 400);
    });

    test('kata sandi salah ditolak dengan pesan yang jelas', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await ApiClient.instance.post(
          '/api/auth/login',
          body: <String, dynamic>{
            'email': _emailPelanggan,
            'password': 'kata-sandi-salah',
          },
        );
      });

      expect(kesalahan.statusCode, 401);
      expect(kesalahan.kode, 'INVALID_CREDENTIALS');
      expect(kesalahan.pesan, contains('salah'));
    });

    test('token asal-asalan ditolak dan dianggap sesi bermasalah', () async {
      ApiClient.instance.token = 'token-palsu-yang-tidak-pernah-dibuat';

      final ApiException kesalahan = await _harusGagal(() async {
        await ApiClient.instance.get('/api/auth/me');
      });

      expect(kesalahan.statusCode, 401);
      expect(kesalahan.sesiBermasalah, isTrue);

      pakaiPelanggan();
    });
  });

  group('C. Layanan tanpa login', () {
    setUp(() => ApiClient.instance.token = null);

    test('daftar layanan bisa dibaca tanpa login', () async {
      final List<Layanan> daftar = await _layananService.daftarSemua();
      expect(daftar, isNotEmpty);

      // Harga harus terbaca sebagai angka, bukan teks dari kolom NUMERIC.
      expect(daftar.first.hargaPerKg, greaterThan(0));
      expect(daftar.first.durasi, isNotEmpty);
    });

    test('detail layanan sama dengan yang ada di daftar', () async {
      final List<Layanan> daftar = await _layananService.daftarSemua();
      final Layanan detail = await _layananService.detail(daftar.first.id);

      expect(detail.id, daftar.first.id);
      expect(detail.nama, daftar.first.nama);
      expect(detail.hargaPerKg, daftar.first.hargaPerKg);
    });

    test('layanan yang tidak ada menghasilkan 404, bukan data kosong', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _layananService.detail(999999999);
      });

      expect(kesalahan.statusCode, 404);
      expect(kesalahan.kode, 'NOT_FOUND');
    });
  });

  group('D. Hak akses pelanggan', () {
    late int pesananId;

    setUpAll(() async {
      pakaiPelanggan();
      final Layanan layanan = await _layananUntukPesanan();
      final Pesanan pesanan = await _pesananService.buat(
        serviceId: layanan.id,
        estimatedWeight: 2,
      );
      pesananId = pesanan.id;
    });

    setUp(pakaiPelanggan);

    test('pelanggan tidak boleh menambah layanan', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _layananService.tambah(
          const Layanan(
            id: 0,
            nama: 'Layanan Tidak Boleh Dibuat',
            deskripsi: null,
            hargaPerKg: 1000,
            durasi: '1 hari',
          ),
        );
      });

      expect(kesalahan.statusCode, 403);
      expect(kesalahan.kode, 'ROLE_NOT_ALLOWED');
      // Sesinya tetap sah: tidak boleh memaksa pengguna login ulang.
      expect(kesalahan.sesiBermasalah, isFalse);
    });

    test('pelanggan tidak boleh mengubah status pesanan', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.ubahStatus(
          orderId: pesananId,
          status: StatusPesanan.dikonfirmasi,
        );
      });

      expect(kesalahan.statusCode, 403);
    });

    test('pelanggan tidak boleh mengisi berat aktual', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.isiBeratAsli(
          orderId: pesananId,
          actualWeight: 4,
        );
      });

      expect(kesalahan.statusCode, 403);
    });

    test('pelanggan tidak boleh menghapus layanan', () async {
      final Layanan layanan = await _layananUntukPesanan();

      final ApiException kesalahan = await _harusGagal(() async {
        await _layananService.hapus(layanan.id);
      });

      expect(kesalahan.statusCode, 403);
    });
  });

  group('E. Admin: kelola layanan', () {
    late Layanan layananUji;

    setUpAll(() async {
      pakaiAdmin();
      return;
    });

    setUp(pakaiAdmin);

    test('admin bisa menambah layanan', () async {
      layananUji = await _layananService.tambah(
        Layanan(
          id: 0,
          nama: '[UJI MOBILE] Cuci Express',
          deskripsi: 'Layanan uji integrasi aplikasi Flutter.',
          hargaPerKg: 9000,
          durasi: '6 jam',
        ),
      );

      expect(layananUji.id, greaterThan(0));
      expect(layananUji.hargaPerKg, 9000);
      expect(layananUji.durasi, '6 jam');
      expect(layananUji.deskripsi, contains('uji integrasi'));
    });

    test('admin bisa mengubah layanan', () async {
      final Layanan diubah = await _layananService.ubah(
        Layanan(
          id: layananUji.id,
          nama: layananUji.nama,
          deskripsi: 'Harga sudah diperbarui oleh pengujian.',
          hargaPerKg: 9500,
          durasi: '5 jam',
        ),
      );

      expect(diubah.hargaPerKg, 9500);
      expect(diubah.durasi, '5 jam');
      expect(diubah.deskripsi, contains('diperbarui'));
    });

    test('admin bisa menghapus layanan yang belum dipakai', () async {
      final Layanan buang = await _layananService.tambah(
        Layanan(
          id: 0,
          nama: '[UJI MOBILE] Layanan Sementara',
          deskripsi: null,
          hargaPerKg: 1000,
          durasi: '1 hari',
        ),
      );

      await _layananService.hapus(buang.id);

      final ApiException kesalahan = await _harusGagal(() async {
        await _layananService.detail(buang.id);
      });
      expect(kesalahan.statusCode, 404);
    });

    test('layanan tidak sah ditolak backend', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _layananService.tambah(
          const Layanan(
            id: 0,
            nama: '',
            deskripsi: null,
            hargaPerKg: 5000,
            durasi: '1 hari',
          ),
        );
      });

      expect(kesalahan.statusCode, 400);
    });

    test('harga negatif ditolak backend', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _layananService.tambah(
          const Layanan(
            id: 0,
            nama: '[UJI MOBILE] Harga Minus',
            deskripsi: null,
            hargaPerKg: -5000,
            durasi: '1 hari',
          ),
        );
      });

      expect(kesalahan.statusCode, 400);
    });
  }, skip: _lewatiAdmin);

  group('F. Pelanggan: pesanan dan foto', () {
    late Pesanan pesanan;
    late Layanan layanan;

    setUpAll(() async {
      pakaiPelanggan();
      layanan = await _layananUntukPesanan();
    });

    setUp(pakaiPelanggan);

    test('pesanan berhasil dibuat dengan harga dari server', () async {
      pesanan = await _pesananService.buat(
        serviceId: layanan.id,
        estimatedWeight: 3.5,
      );

      expect(pesanan.id, greaterThan(0));
      expect(pesanan.status, StatusPesanan.menungguKonfirmasi);
      expect(pesanan.beratPerkiraan, 3.5);

      // Harga per kg disalin backend dari tabel services, bukan dikirim
      // aplikasi. Inilah yang membuat harga tidak bisa dipalsukan dari klien.
      expect(pesanan.hargaPerKg, layanan.hargaPerKg);
      expect(pesanan.namaLayanan, layanan.nama);

      // Belum ada harga akhir sebelum admin menimbang.
      expect(pesanan.beratAktual, isNull);
      expect(pesanan.totalHarga, isNull);
      expect(pesanan.hargaSudahFinal, isFalse);
      expect(pesanan.adaFoto, isFalse);
    });

    test('berat perkiraan yang tidak masuk akal ditolak', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.buat(serviceId: layanan.id, estimatedWeight: 0);
      });

      expect(kesalahan.statusCode, 400);
    });

    test('layanan yang tidak ada tidak bisa dipesan', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.buat(serviceId: 999999999, estimatedWeight: 2);
      });

      expect(kesalahan.statusCode, 404);
    });

    test('foto berhasil diunggah dengan field "photo"', () async {
      final Pesanan setelah = await _pesananService.unggahFoto(
        orderId: pesanan.id,
        foto: XFile.fromData(
          _pngSatuPiksel(),
          name: 'uji-mobile.png',
          mimeType: 'image/png',
        ),
      );

      expect(setelah.adaFoto, isTrue);
      expect(setelah.photoUrl, startsWith('/uploads/'));
      expect(setelah.alamatFoto, startsWith(ApiConfig.baseUrl));

      pesanan = setelah;
    });

    test('foto yang diunggah benar-benar tersimpan di server', () async {
      // Membuktikan berkasnya bisa disajikan server, bukan hanya path-nya
      // tercatat di database.
      final Pesanan detail = await _pesananService.detail(pesanan.id);
      expect(detail.alamatFoto, isNotNull);

      // Endpoint /uploads mengembalikan berkas gambar, bukan JSON, jadi
      // permintaan ini tidak lewat ApiClient.
      final http.Response balasan = await http.get(
        Uri.parse(detail.alamatFoto!),
      );

      expect(balasan.statusCode, 200);
      expect(balasan.headers['content-type'], contains('image'));
      expect(balasan.bodyBytes, isNotEmpty);
    });

    test('mengunggah foto baru menggantikan foto lama', () async {
      final Pesanan kedua = await _pesananService.unggahFoto(
        orderId: pesanan.id,
        foto: XFile.fromData(
          _pngSatuPiksel(),
          name: 'kedua.png',
          mimeType: 'image/png',
        ),
      );

      // Nama berkas dibuat acak oleh server, jadi foto kedua harus berbeda.
      expect(kedua.photoUrl, isNot(pesanan.photoUrl));
      pesanan = kedua;
    });

    test('format berkas di luar JPEG/PNG/WebP ditolak aplikasi', () async {
      // Berkas yang jelas bukan gambar ditolak sebelum dikirim, supaya
      // pengguna tidak menunggu unggahan yang pasti gagal.
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.unggahFoto(
          orderId: pesanan.id,
          foto: XFile.fromData(
            Uint8List.fromList(<int>[1, 2, 3, 4]),
            name: 'dokumen.pdf',
            mimeType: 'application/pdf',
          ),
        );
      });

      expect(kesalahan.kode, 'TIPE_FOTO_SALAH');
      // Tidak dikirim ke server, jadi tidak ada kode HTTP.
      expect(kesalahan.statusCode, isNull);
    });

    test('server juga menolak sendiri berkas yang bukan gambar', () async {
      // Penyaringan di aplikasi bisa dilewati (mis. pemanggil langsung),
      // jadi server harus tetap menolak. Permintaan ini sengaja dibuat tanpa
      // lewat PesananService supaya berkasnya benar-benar terkirim.
      final http.MultipartRequest permintaan = http.MultipartRequest(
        'PATCH',
        Uri.parse('${ApiConfig.baseUrl}/api/orders/${pesanan.id}/foto'),
      );
      permintaan.headers['Authorization'] =
          'Bearer ${ApiClient.instance.token}';
      permintaan.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          Uint8List.fromList(<int>[1, 2, 3, 4]),
          filename: 'dokumen.pdf',
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final http.StreamedResponse aliran = await permintaan.send();
      final http.Response balasan = await http.Response.fromStream(aliran);

      expect(balasan.statusCode, 400);
      expect(balasan.body, contains('INVALID_FILE_TYPE'));
    });

    test('foto lebih dari 2 MB ditolak aplikasi sebelum dikirim', () async {
      // Penyaringan di sisi aplikasi menghemat kuota pengguna: berkas yang
      // pasti ditolak server tidak perlu dikirim sampai habis.
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.unggahFoto(
          orderId: pesanan.id,
          foto: XFile.fromData(
            Uint8List(3 * 1024 * 1024),
            name: 'terlalu-besar.jpg',
            mimeType: 'image/jpeg',
          ),
        );
      });

      expect(kesalahan.kode, 'FILE_TERLALU_BESAR');
      expect(kesalahan.statusCode, isNull);
    });

    test('pesanan yang tidak ada tidak bisa diunggahi foto', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.unggahFoto(
          orderId: 999999999,
          foto: XFile.fromData(
            _pngSatuPiksel(),
            name: 'hantu.png',
            mimeType: 'image/png',
          ),
        );
      });

      expect(kesalahan.statusCode, 404);
    });

    test('detail pesanan berisi data yang tersimpan', () async {
      final Pesanan detail = await _pesananService.detail(pesanan.id);

      expect(detail.id, pesanan.id);
      expect(detail.beratPerkiraan, 3.5);
      expect(detail.status, StatusPesanan.menungguKonfirmasi);
      expect(detail.adaFoto, isTrue);
      expect(detail.namaPelanggan, isNotEmpty);
      expect(detail.namaLayanan, isNotEmpty);
      expect(detail.namaPelanggan, contains('Uji Mobile'));
    });

    test('pelanggan hanya melihat pesanannya sendiri', () async {
      final List<Pesanan> daftar = await _pesananService.daftar(limit: 100);

      expect(daftar.any((Pesanan p) => p.id == pesanan.id), isTrue);

      // Semua pesanan yang terlihat harus milik akun yang sedang masuk.
      for (final Pesanan p in daftar) {
        expect(
          p.userId,
          _idPelanggan,
          reason: 'Pelanggan tidak boleh melihat pesanan milik akun lain.',
        );
      }
    });

    test('pelanggan bisa membatalkan pesanannya sendiri', () async {
      final Pesanan dibatalkan = await _pesananService.batalkan(pesanan.id);

      expect(dibatalkan.status, StatusPesanan.dibatalkan);
      expect(dibatalkan.status.sudahFinal, isTrue);
    });

    test('pesanan yang sudah dibatalkan tidak bisa dibatalkan lagi', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.batalkan(pesanan.id);
      });

      expect(kesalahan.statusCode, 409);
      expect(kesalahan.kode, 'ORDER_FINAL');
    });

    test('pesanan yang sudah dibatalkan tidak bisa diubah lagi', () async {
      pakaiAdmin();

      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.ubahStatus(
          orderId: pesanan.id,
          status: StatusPesanan.dikonfirmasi,
        );
      });

      // Backend menjawab INVALID_STATUS_TRANSITION, bukan ORDER_FINAL:
      // pemeriksaan transisi dijalankan lebih dulu, dan daftar lanjutan untuk
      // status CANCELLED memang kosong. Kode ORDER_FINAL dipakai endpoint
      // berat-asli dan batal.
      expect(kesalahan.statusCode, 409);
      expect(kesalahan.kode, 'INVALID_STATUS_TRANSITION');
      expect(kesalahan.pesan, contains('final'));
    });
  });

  group('G. Admin: berat dan status', () {
    late Pesanan pesanan;
    late Layanan layanan;

    setUpAll(() async {
      pakaiPelanggan();
      layanan = await _layananUntukPesanan();
      pesanan = await _pesananService.buat(
        serviceId: layanan.id,
        estimatedWeight: 2,
      );

      // Berat asli sengaja belum diisi, supaya aturan ACTUAL_WEIGHT_REQUIRED
      // bisa diuji.
      pakaiAdmin();
    });

    setUp(pakaiAdmin);

    test('admin bisa mengisi berat aktual, harga dihitung server', () async {
      final Pesanan hasil = await _pesananService.isiBeratAsli(
        orderId: pesanan.id,
        actualWeight: 4.25,
      );

      expect(hasil.beratAktual, 4.25);
      expect(hasil.hargaSudahFinal, isTrue);

      // Harga akhir = berat aktual x harga per kg milik pesanan itu sendiri.
      // Perhitungannya dilakukan backend; nilai di sini hanya membandingkan
      // hasilnya, bukan menggantikannya.
      final double diharapkan = 4.25 * hasil.hargaPerKg;
      expect(hasil.totalHarga, closeTo(diharapkan, 0.01));

      pesanan = hasil;
    });

    test('berat aktual di luar akal ditolak backend', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.isiBeratAsli(orderId: pesanan.id, actualWeight: 0);
      });

      expect(kesalahan.statusCode, 400);
    });

    test('perpindahan status yang melompat ditolak', () async {
      // Dari PENDING_CONFIRMATION langsung ke WASHING, melompati CONFIRMED.
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.ubahStatus(
          orderId: pesanan.id,
          status: StatusPesanan.sedangDicuci,
        );
      });

      expect(kesalahan.statusCode, 409);
      expect(kesalahan.kode, 'INVALID_STATUS_TRANSITION');
      // Pesan backend harus tersampaikan apa adanya, bukan diganti pesan
      // generik, supaya admin tahu langkah yang benar.
      expect(kesalahan.pesan, contains('CONFIRMED'));
    });

    test('status maju satu per satu sampai siap diambil', () async {
      for (final StatusPesanan tujuan in <StatusPesanan>[
        StatusPesanan.dikonfirmasi,
        StatusPesanan.sedangDicuci,
        StatusPesanan.siapDiambil,
      ]) {
        pesanan = await _pesananService.ubahStatus(
          orderId: pesanan.id,
          status: tujuan,
        );
        expect(pesanan.status, tujuan);
      }
    });

    test('menyimpan status yang sama ditolak', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.ubahStatus(
          orderId: pesanan.id,
          status: StatusPesanan.siapDiambil,
        );
      });

      expect(kesalahan.statusCode, 409);
      expect(kesalahan.kode, 'STATUS_SAMA');
    });

    test('pesanan bisa diselesaikan setelah berat asli terisi', () async {
      final Pesanan selesai = await _pesananService.ubahStatus(
        orderId: pesanan.id,
        status: StatusPesanan.selesai,
      );

      expect(selesai.status, StatusPesanan.selesai);
      expect(selesai.status.sudahFinal, isTrue);
    });

    test('berat asli tidak bisa diubah pada pesanan yang sudah selesai', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.isiBeratAsli(orderId: pesanan.id, actualWeight: 9);
      });

      expect(kesalahan.statusCode, 409);
      expect(kesalahan.kode, 'ORDER_FINAL');
    });

    test('pesanan tidak bisa selesai sebelum berat asli diisi', () async {
      pakaiPelanggan();
      final Pesanan kedua = await _pesananService.buat(
        serviceId: layanan.id,
        estimatedWeight: 1,
      );
      pakaiAdmin();

      Pesanan sekarang = kedua;
      for (final StatusPesanan tujuan in <StatusPesanan>[
        StatusPesanan.dikonfirmasi,
        StatusPesanan.sedangDicuci,
        StatusPesanan.siapDiambil,
      ]) {
        sekarang = await _pesananService.ubahStatus(
          orderId: kedua.id,
          status: tujuan,
        );
      }

      expect(sekarang.beratAktual, isNull);
      expect(sekarang.status, StatusPesanan.siapDiambil);

      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.ubahStatus(
          orderId: kedua.id,
          status: StatusPesanan.selesai,
        );
      });

      expect(kesalahan.statusCode, 409);
      expect(kesalahan.kode, 'ACTUAL_WEIGHT_REQUIRED');

      // Setelah berat diisi, barulah boleh diselesaikan.
      final Pesanan ditimbang = await _pesananService.isiBeratAsli(
        orderId: kedua.id,
        actualWeight: 1.4,
      );
      expect(ditimbang.totalHarga, isNotNull);
      expect(ditimbang.totalHarga, greaterThan(0));

      final Pesanan akhir = await _pesananService.ubahStatus(
        orderId: kedua.id,
        status: StatusPesanan.selesai,
      );
      expect(akhir.status, StatusPesanan.selesai);
    });

    test('layanan yang dipakai pesanan tidak bisa dihapus', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _layananService.hapus(layanan.id);
      });

      // foreign key orders.service_id memakai ON DELETE RESTRICT, dan
      // PostgreSQL melaporkannya dengan kode 23001 (restrict_violation).
      // Backend menerjemahkannya menjadi 409 SERVICE_IN_USE, sehingga admin
      // mendapat penjelasan dan langkah berikutnya, bukan "terjadi kesalahan".
      expect(kesalahan.statusCode, 409);
      expect(kesalahan.kode, 'SERVICE_IN_USE');
      expect(kesalahan.pesan, contains('masih dipakai'));
      expect(kesalahan.pesan, contains('batalkan'));
    });

    test('penyaring status di backend bekerja', () async {
      final List<Pesanan> selesai = await _pesananService.daftar(
        status: StatusPesanan.selesai,
        limit: 100,
      );

      expect(selesai, isNotEmpty);
      for (final Pesanan p in selesai) {
        expect(p.status, StatusPesanan.selesai);
      }
    });

    test('riwayat menggabungkan pesanan selesai dan dibatalkan', () async {
      final List<Pesanan> riwayat = await _pesananService.daftarBanyakStatus(
        const <StatusPesanan>[StatusPesanan.selesai, StatusPesanan.dibatalkan],
      );

      expect(riwayat, isNotEmpty);
      for (final Pesanan p in riwayat) {
        expect(p.status.sudahFinal, isTrue);
      }

      // Hasil gabungan harus terurut dari yang terbaru.
      for (int i = 1; i < riwayat.length; i++) {
        final DateTime? sebelumnya = riwayat[i - 1].dibuatPada;
        final DateTime? sekarang = riwayat[i].dibuatPada;
        if (sebelumnya != null && sekarang != null) {
          expect(sebelumnya.isBefore(sekarang), isFalse);
        }
      }
    });

    test('admin melihat pesanan milik lebih dari satu akun', () async {
      final List<Pesanan> semua = await _pesananService.daftar(limit: 100);
      expect(semua, isNotEmpty);

      // Bukti bahwa penyaringan "hanya milik sendiri" berlaku untuk pelanggan
      // dan tidak berlaku bagi admin.
      final bool adaMilikOrangLain = semua.any(
        (Pesanan p) => p.userId != _idAdmin,
      );
      expect(
        adaMilikOrangLain,
        isTrue,
        reason: 'Admin harus melihat pesanan pelanggan, bukan hanya miliknya.',
      );
    });
  }, skip: _lewatiAdmin);

  group('H. Keluar', () {
    setUp(pakaiPelanggan);

    test('keluar menghapus token, lalu bisa masuk lagi', () async {
      // AuthService masih memegang sesi pelanggan uji dari awal.
      expect(AuthService.instance.status, SesiStatus.masuk);

      await AuthService.instance.keluar();

      expect(AuthService.instance.status, SesiStatus.belumMasuk);
      expect(AuthService.instance.pengguna, isNull);
      expect(ApiClient.instance.token, isNull);

      // Token yang tersimpan sendiri sudah dihapus dari penyimpanan aman.
      expect(await AuthService.instance.bacaTokenUji(), isNull);

      // Login ulang memakai akun yang sama.
      final User lagi = await AuthService.instance.masuk(
        email: _emailPelanggan,
        password: _sandiPelanggan,
      );

      expect(lagi.id, _idPelanggan);
      expect(AuthService.instance.status, SesiStatus.masuk);
      expect(ApiClient.instance.token, isNotNull);

      _tokenPelanggan = ApiClient.instance.token;
    });

    test('setelah keluar, endpoint privat menolak permintaan', () async {
      await AuthService.instance.keluar();

      expect(ApiClient.instance.token, isNull);

      final ApiException kesalahan = await _harusGagal(() async {
        await ApiClient.instance.get('/api/orders');
      });

      expect(kesalahan.statusCode, 401);
      expect(kesalahan.sesiBermasalah, isTrue);

      // Pulihkan sesi pelanggan untuk kemungkinan pemeriksaan lanjutan.
      await AuthService.instance.masuk(
        email: _emailPelanggan,
        password: _sandiPelanggan,
      );
      _tokenPelanggan = ApiClient.instance.token;
    });
  });
  group('I. Hapus foto pesanan', () {
    late Pesanan pesanan;

    setUpAll(() async {
      pakaiPelanggan();
      final Layanan layanan = await _layananUntukPesanan();
      final Pesanan baru = await _pesananService.buat(
        serviceId: layanan.id,
        estimatedWeight: 2,
      );

      pesanan = await _pesananService.unggahFoto(
        orderId: baru.id,
        foto: XFile.fromData(
          _pngSatuPiksel(),
          name: 'akan-dihapus.png',
          mimeType: 'image/png',
        ),
      );
    });

    setUp(pakaiPelanggan);

    test('admin bisa menghapus foto pesanan pelanggan', () async {
      pakaiAdmin();

      final Pesanan kosong = await _pesananService.hapusFoto(pesanan.id);

      expect(kosong.adaFoto, isFalse);
      expect(kosong.photoUrl, isNull);
      expect(kosong.alamatFoto, isNull);

      pesanan = kosong;
    }, skip: _lewatiAdmin);

    test('foto yang sudah dihapus benar-benar hilang dari detail', () async {
      final Pesanan detail = await _pesananService.detail(pesanan.id);
      expect(detail.adaFoto, isFalse);
    }, skip: _lewatiAdmin);

    test('menghapus foto yang tidak ada dijawab 404', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.hapusFoto(pesanan.id);
      });

      expect(kesalahan.statusCode, 404);
      expect(kesalahan.kode, 'FILE_NOT_FOUND');
    }, skip: _lewatiAdmin);

    test('setelah foto dihapus, foto baru bisa diunggah lagi', () async {
      final Pesanan lagi = await _pesananService.unggahFoto(
        orderId: pesanan.id,
        foto: XFile.fromData(
          _pngSatuPiksel(),
          name: 'pengganti.png',
          mimeType: 'image/png',
        ),
      );

      expect(lagi.adaFoto, isTrue);

      // Pesanan yang tidak ada dijawab 404, bukan 403, supaya keberadaan
      // pesanan milik akun lain tidak ikut terbocor.
      final ApiException kesalahan = await _harusGagal(() async {
        await _pesananService.hapusFoto(999999999);
      });
      expect(kesalahan.statusCode, 404);
    }, skip: _lewatiAdmin);
  });

  group('J. Ubah profil akun', () {
    setUp(pakaiPelanggan);

    test('nama akun bisa diubah dan langsung berlaku', () async {
      final User akun = await AuthService.instance.ubahProfil(
        nama: 'Uji Mobile Baru',
      );

      expect(akun.nama, 'Uji Mobile Baru');
      expect(AuthService.instance.pengguna?.nama, 'Uji Mobile Baru');

      // Backend benar-benar menyimpannya, bukan hanya di aplikasi.
      final dynamic data = await ApiClient.instance.get('/api/auth/me');
      expect((data['user'] as Map<String, dynamic>)['name'], 'Uji Mobile Baru');
    });

    test('ganti kata sandi tanpa kata sandi lama ditolak', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await AuthService.instance.ubahProfil(
          nama: 'Uji Mobile Baru',
          sandiBaru: 'SandiGanti2026!',
        );
      });

      expect(kesalahan.statusCode, 400);
      expect(kesalahan.kode, 'CURRENT_PASSWORD_REQUIRED');
    });

    test('kata sandi lama yang salah ditolak', () async {
      final ApiException kesalahan = await _harusGagal(() async {
        await AuthService.instance.ubahProfil(
          nama: 'Uji Mobile Baru',
          sandiLama: 'jelas-salah-sekali',
          sandiBaru: 'SandiGanti2026!',
        );
      });

      expect(kesalahan.statusCode, 401);
      expect(kesalahan.kode, 'INVALID_CURRENT_PASSWORD');
    });

    test('kata sandi benar-benar berganti setelah diubah', () async {
      await AuthService.instance.ubahProfil(
        nama: 'Uji Mobile Baru',
        sandiLama: _sandiPelanggan,
        sandiBaru: 'SandiGanti2026!',
      );

      // Sesi yang sedang berjalan tidak terganggu.
      expect(AuthService.instance.pengguna?.nama, 'Uji Mobile Baru');

      // Kata sandi baru diterima, kata sandi lama sudah tidak berlaku.
      final User lagi = await AuthService.instance.masuk(
        email: _emailPelanggan,
        password: 'SandiGanti2026!',
      );
      expect(lagi.id, _idPelanggan);

      final ApiException kesalahan = await _harusGagal(() async {
        await ApiClient.instance.post(
          '/api/auth/login',
          body: <String, dynamic>{
            'email': _emailPelanggan,
            'password': _sandiPelanggan,
          },
        );
      });
      expect(kesalahan.statusCode, 401);

      _tokenPelanggan = ApiClient.instance.token;
    });
  });
}
Uint8List _pngSatuPiksel() {
  return base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/'
    'q842iQAAAABJRU5ErkJggg==',
  );
}
