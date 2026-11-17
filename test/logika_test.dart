import 'package:flutter_test/flutter_test.dart';
import 'package:laundryku/models/status_pesanan.dart';
import 'package:laundryku/models/user.dart';
import 'package:laundryku/services/api_client.dart';
import 'package:laundryku/utils/format.dart';
import 'package:laundryku/utils/validasi.dart';

/// Pengujian logika yang tidak memerlukan server.
///
/// Yang diperiksa di sini adalah aturan yang mudah salah dan tidak terlihat
/// dari tampilan: pembacaan angka dari backend, aturan perpindahan status, dan
/// validasi form.
void main() {
  group('Pembacaan angka dari JSON', () {
    test('menerima angka NUMERIC yang dikirim sebagai teks', () {
      // Kolom NUMERIC PostgreSQL dikirim driver pg sebagai teks, mis.
      // "7500.00". Kalau ini tidak ditangani, harga tampil sebagai 0.
      expect(angkaDariJson('7500.00'), 7500.0);
      expect(angkaDariJson('3.50'), 3.5);
    });

    test('menerima angka yang memang dikirim sebagai angka', () {
      expect(angkaDariJson(7500), 7500.0);
      expect(angkaDariJson(3.5), 3.5);
    });

    test('mengembalikan null untuk nilai kosong atau tidak masuk akal', () {
      // total_price memang null selama berat asli belum diisi admin.
      expect(angkaDariJson(null), isNull);
      expect(angkaDariJson(''), isNull);
      expect(angkaDariJson('bukan angka'), isNull);
    });

    test('membaca kolom INTEGER', () {
      expect(bulatDariJson(12), 12);
      expect(bulatDariJson('12'), 12);
      expect(bulatDariJson(null), isNull);
    });
  });

  group('Format tampilan', () {
    test('berat selalu disertai satuan kg', () {
      expect(formatBerat(3.5), '3,5 kg');
      expect(formatBerat(4), '4 kg');
    });

    test('nilai kosong ditampilkan sebagai tanda hubung, bukan nol', () {
      // Penting: menampilkan "Rp 0" akan membuat pelanggan mengira pesanannya
      // gratis, padahal harganya memang belum dihitung.
      expect(formatRupiah(null), '-');
      expect(formatBerat(null), '-');
    });

    test('rupiah memakai pemisah ribuan', () {
      expect(formatRupiah(7500), contains('7.500'));
    });
  });

  group('Aturan perpindahan status pesanan', () {
    test('alur maju berjalan satu arah', () {
      expect(
        StatusPesanan.menungguKonfirmasi.berikutnya,
        contains(StatusPesanan.dikonfirmasi),
      );
      expect(
        StatusPesanan.dikonfirmasi.berikutnya,
        contains(StatusPesanan.sedangDicuci),
      );
      expect(
        StatusPesanan.sedangDicuci.berikutnya,
        contains(StatusPesanan.siapDiambil),
      );
    });

    test('status akhir tidak bisa diubah lagi', () {
      expect(StatusPesanan.selesai.berikutnya, isEmpty);
      expect(StatusPesanan.dibatalkan.berikutnya, isEmpty);
      expect(StatusPesanan.selesai.sudahFinal, isTrue);
      expect(StatusPesanan.sedangDicuci.masihAktif, isTrue);
    });

    test('pelanggan hanya boleh membatalkan sebelum pencucian', () {
      expect(StatusPesanan.menungguKonfirmasi.bolehDibatalkanCustomer, isTrue);
      expect(StatusPesanan.dikonfirmasi.bolehDibatalkanCustomer, isTrue);
      // Sudah masuk mesin cuci -> tidak boleh dibatalkan sendiri.
      expect(StatusPesanan.sedangDicuci.bolehDibatalkanCustomer, isFalse);
      expect(StatusPesanan.siapDiambil.bolehDibatalkanCustomer, isFalse);
    });

    test('status tak dikenal diperlakukan sebagai masih aktif', () {
      // Salah kalau dianggap selesai atau dibatalkan: pesanannya bisa jadi
      // masih dikerjakan.
      expect(StatusPesanan.dariKode('STATUS_BARU'), StatusPesanan.menungguKonfirmasi);
      expect(StatusPesanan.dariKode(null).masihAktif, isTrue);
      expect(StatusPesanan.dariKode('washing'), StatusPesanan.sedangDicuci);
    });
  });

  group('Pembacaan role akun', () {
    test('role dikenali tanpa peduli besar-kecil huruf', () {
      expect(PeranPengguna.dariKode('ADMIN'), PeranPengguna.admin);
      expect(PeranPengguna.dariKode('admin'), PeranPengguna.admin);
    });

    test('role tak dikenal diperlakukan sebagai pelanggan', () {
      // Sengaja memberi hak paling sedikit, bukan paling banyak.
      expect(PeranPengguna.dariKode('SUPERUSER'), PeranPengguna.customer);
      expect(PeranPengguna.dariKode(null), PeranPengguna.customer);
    });

    test('inisial nama dipakai di avatar', () {
      final User pengguna = User.dariJson(<String, dynamic>{
        'id': 1,
        'name': 'Alvin Pratama',
        'email': 'alvin@contoh.com',
        'role': 'CUSTOMER',
      });

      expect(pengguna.inisial, 'AP');
      expect(pengguna.adalahAdmin, isFalse);
    });
  });

  group('Validasi form', () {
    test('email harus berbentuk alamat email', () {
      expect(Validasi.email(''), isNotNull);
      expect(Validasi.email('bukan-email'), isNotNull);
      expect(Validasi.email('nama@email'), isNotNull);
      expect(Validasi.email('nama@email.com'), isNull);
    });

    test('kata sandi mengikuti batas backend (8 sampai 72 karakter)', () {
      expect(Validasi.password('1234567'), isNotNull);
      expect(Validasi.password('12345678'), isNull);
      expect(Validasi.password('a' * 73), isNotNull);
    });

    test('konfirmasi kata sandi harus sama', () {
      expect(Validasi.konfirmasiPassword('sandi123', 'sandi123'), isNull);
      expect(Validasi.konfirmasiPassword('sandi123', 'sandi124'), isNotNull);
    });

    test('berat menerima koma maupun titik sebagai desimal', () {
      expect(Validasi.beratPerkiraan('3.5'), isNull);
      expect(Validasi.beratPerkiraan('3,5'), isNull);
      expect(Validasi.beratPerkiraan('0'), isNotNull);
      expect(Validasi.beratPerkiraan('tiga'), isNotNull);
    });
  });

  group('Kesalahan API', () {
    test('hanya token bermasalah yang mengakhiri sesi', () {
      // Kegagalan biasa (mis. data tidak ditemukan) tidak boleh memaksa
      // pengguna login ulang.
      expect(
        ApiException('Token tidak sah.', kode: 'TOKEN_INVALID', statusCode: 401)
            .sesiBermasalah,
        isTrue,
      );
      expect(
        ApiException('Kedaluwarsa.', kode: 'TOKEN_EXPIRED', statusCode: 401)
            .sesiBermasalah,
        isTrue,
      );
      expect(
        ApiException('Tidak ditemukan.', kode: 'NOT_FOUND', statusCode: 404)
            .sesiBermasalah,
        isFalse,
      );
      // 403 berarti sudah login tetapi tidak punya hak; sesinya tetap sah.
      expect(
        ApiException('Tidak boleh.', kode: 'ROLE_NOT_ALLOWED', statusCode: 403)
            .sesiBermasalah,
        isFalse,
      );
    });
  });
}
