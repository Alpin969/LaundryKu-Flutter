import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';

/// Kesalahan yang berasal dari API LaundryKu, sudah dalam bentuk pesan yang
/// bisa dibaca pengguna.
///
/// `message` diambil dari response backend apa adanya, jadi penjelasan seperti
/// "Berat asli tidak bisa diubah karena pesanan sudah berstatus COMPLETED"
/// ikut tersampaikan tanpa perlu ditulis ulang di aplikasi.
class ApiException implements Exception {
  ApiException(this.pesan, {this.kode, this.statusCode});

  final String pesan;
  final String? kode;
  final int? statusCode;

  /// Sesi tidak lagi berlaku (token hilang, tidak sah, atau kedaluwarsa).
  bool get sesiBermasalah {
    if (statusCode != 401) return false;
    const Set<String> kodeSesi = <String>{
      'TOKEN_MISSING',
      'TOKEN_INVALID',
      'TOKEN_EXPIRED',
      'ACCOUNT_NOT_FOUND',
      'UNAUTHORIZED',
    };
    return kodeSesi.contains(kode);
  }

  @override
  String toString() => pesan;
}

/// Satu-satunya pintu keluar aplikasi menuju REST API LaundryKu.
///
/// Semua permintaan memakai kelas ini supaya penanganan token, status HTTP,
/// dan kegagalan koneksi hanya ditulis satu kali.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  /// Dipanggil saat backend menolak token. Diisi oleh AuthService untuk
  /// mengembalikan pengguna ke halaman login.
  void Function()? saatSesiBerakhir;

  /// Token JWT yang sedang dipakai. Diisi AuthService setelah login berhasil.
  ///
  /// Field ini sengaja dibiarkan publik karena hanya dibaca dan ditulis oleh
  /// AuthService, bukan bagian dari antarmuka halaman.
  String? token;

  /// Klien HTTP pengganti yang hanya dipakai pengujian.
  ///
  /// Aplikasi selalu membiarkannya kosong dan memakai klien bawaan package
  /// http. Pengujian mengisinya dengan klien buatan supaya alur halaman
  /// (mis. daftar lalu masuk ke beranda) bisa diperiksa tanpa jaringan
  /// sungguhan dan tanpa backend yang sedang berjalan.
  @visibleForTesting
  http.Client? klienUji;

  static const Duration _batasWaktu = Duration(seconds: 25);

  Uri _uri(String path, Map<String, dynamic>? query) {
    final Uri dasar = Uri.parse('${ApiConfig.baseUrl}$path');

    if (query == null || query.isEmpty) return dasar;

    // Nilai null dibuang supaya parameter opsional tidak terkirim sebagai
    // teks "null" ke backend.
    final Map<String, String> bersih = <String, String>{};
    query.forEach((String kunci, dynamic nilai) {
      if (nilai != null && nilai.toString().isNotEmpty) {
        bersih[kunci] = nilai.toString();
      }
    });

    if (bersih.isEmpty) return dasar;
    return dasar.replace(queryParameters: bersih);
  }

  Map<String, String> _header({bool json = true}) {
    return <String, String>{
      if (json) 'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Setiap permintaan memakai klienUji bila ada, dan klien bawaan package http
  // bila tidak. Aplikasi sendiri tidak pernah mengisi klienUji.

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    final Uri uri = _uri(path, query);
    return _kirim(
      () =>
          klienUji?.get(uri, headers: _header()) ??
          http.get(uri, headers: _header()),
    );
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    final Uri uri = _uri(path, null);
    final String isi = jsonEncode(body ?? <String, dynamic>{});
    return _kirim(
      () =>
          klienUji?.post(uri, headers: _header(), body: isi) ??
          http.post(uri, headers: _header(), body: isi),
    );
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) {
    final Uri uri = _uri(path, null);
    final String isi = jsonEncode(body ?? <String, dynamic>{});
    return _kirim(
      () =>
          klienUji?.put(uri, headers: _header(), body: isi) ??
          http.put(uri, headers: _header(), body: isi),
    );
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) {
    final Uri uri = _uri(path, null);
    final String isi = jsonEncode(body ?? <String, dynamic>{});
    return _kirim(
      () =>
          klienUji?.patch(uri, headers: _header(), body: isi) ??
          http.patch(uri, headers: _header(), body: isi),
    );
  }

  Future<dynamic> delete(String path) {
    final Uri uri = _uri(path, null);
    return _kirim(
      () =>
          klienUji?.delete(uri, headers: _header()) ??
          http.delete(uri, headers: _header()),
    );
  }

  /// Mengunggah satu foto pesanan sebagai `multipart/form-data`
  /// dengan nama field `photo`, sesuai yang diterima backend.
  ///
  /// [namaField] sengaja tetap bisa diubah agar jelas bahwa nama field harus
  /// sama dengan `unggahFoto.single('photo')` di backend.
  ///
  /// [tipeMime] diisi bila pemanggil sudah menentukan tipe berkasnya sendiri
  /// (lihat `PesananService.unggahFoto`). Bila dibiarkan kosong, tipe ditebak
  /// dari ekstensi nama berkas.
  Future<dynamic> unggahFoto({
    required String path,
    required List<int> byte,
    required String namaBerkas,
    String namaField = 'photo',
    String? tipeMime,
  }) {
    return _kirim(() async {
      final http.MultipartRequest permintaan = http.MultipartRequest(
        'PATCH',
        _uri(path, null),
      );

      // header() dipanggil tanpa Content-Type: untuk multipart, Content-Type
      // beserta boundary-nya diisi sendiri oleh MultipartRequest. Kalau ikut
      // ditimpa menjadi application/json, backend gagal mengurai berkasnya.
      permintaan.headers.addAll(_header(json: false));

      permintaan.files.add(
        http.MultipartFile.fromBytes(
          namaField,
          byte,
          filename: namaBerkas,
          // Backend hanya menerima image/jpeg, image/png, dan image/webp.
          // Tanpa contentType, package http mengirim application/octet-stream
          // dan berkasnya ditolak dengan INVALID_FILE_TYPE.
          contentType: MediaType.parse(tipeMime ?? _tipeMime(namaBerkas)),
        ),
      );

      final http.Client? klien = klienUji;
      final http.StreamedResponse aliran = klien == null
          ? await permintaan.send()
          : await klien.send(permintaan);
      return http.Response.fromStream(aliran);
    });
  }

  static String _tipeMime(String namaBerkas) {
    final String nama = namaBerkas.toLowerCase();
    if (nama.endsWith('.png')) return 'image/png';
    if (nama.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Menjalankan permintaan, lalu menerjemahkan hasilnya.
  ///
  /// Seluruh kegagalan jaringan diubah menjadi ApiException dengan pesan
  /// berbahasa Indonesia, supaya halaman tidak perlu tahu soal SocketException
  /// dan sejenisnya.
  Future<dynamic> _kirim(Future<http.Response> Function() jalankan) async {
    late final http.Response respons;

    try {
      respons = await jalankan().timeout(_batasWaktu);
    } on TimeoutException {
      throw ApiException(
        'LaundryKu tidak merespons dalam ${_batasWaktu.inSeconds} detik. '
        'Periksa koneksi internet lalu coba lagi.',
        kode: 'TIMEOUT',
      );
    } on http.ClientException {
      // Kegagalan jaringan paling umum muncul sebagai ClientException, baik di
      // web maupun di Android/iOS (package http membungkus SocketException
      // menjadi ClientException). Karena itu tidak perlu dart:io di sini, dan
      // aplikasi ini tetap bisa dibangun untuk web.
      //
      // Pesannya sengaja tidak menyebut alamat API: yang perlu diketahui
      // pengguna hanya bahwa koneksinya bermasalah dan apa yang bisa dicoba.
      throw ApiException(
        'Tidak bisa terhubung ke LaundryKu. Periksa koneksi internet Anda, '
        'lalu coba lagi.',
        kode: 'KONEKSI_GAGAL',
      );
    } on FormatException {
      throw ApiException(
        'Aplikasi tidak bisa menghubungi layanan LaundryKu. '
        'Coba lagi sebentar lagi.',
        kode: 'ALAMAT_TIDAK_SAH',
      );
    }

    dynamic isi;
    try {
      // bodyBytes dipakai, bukan body, supaya huruf beraksen dan karakter
      // non-ASCII pada pesan backend tidak rusak.
      isi = jsonDecode(utf8.decode(respons.bodyBytes));
    } on FormatException {
      throw ApiException(
        'Jawaban LaundryKu tidak dapat dibaca (HTTP ${respons.statusCode}). '
        'Coba lagi sebentar lagi.',
        kode: 'JAWABAN_TIDAK_SAH',
        statusCode: respons.statusCode,
      );
    }

    if (respons.statusCode >= 200 && respons.statusCode < 300) {
      return isi is Map<String, dynamic> ? isi['data'] : isi;
    }

    final String pesan = _pesanKesalahan(isi, respons.statusCode);
    final String? kode = isi is Map<String, dynamic>
        ? isi['error'] as String?
        : null;

    final ApiException kesalahan = ApiException(
      pesan,
      kode: kode,
      statusCode: respons.statusCode,
    );

    // Token ditolak backend: sesi diakhiri supaya pengguna diminta login lagi,
    // bukan dibiarkan menatap halaman yang terus gagal memuat.
    if (kesalahan.sesiBermasalah) {
      saatSesiBerakhir?.call();
    }

    throw kesalahan;
  }

  String _pesanKesalahan(dynamic isi, int statusCode) {
    if (isi is Map<String, dynamic>) {
      final dynamic pesan = isi['message'];
      if (pesan is String && pesan.trim().isNotEmpty) return pesan.trim();
    }

    switch (statusCode) {
      case 400:
        return 'Data yang dikirim belum sesuai ketentuan.';
      case 401:
        return 'Sesi Anda sudah berakhir. Silakan login kembali.';
      case 403:
        return 'Akun Anda tidak punya hak untuk tindakan ini.';
      case 404:
        return 'Data yang diminta tidak ditemukan.';
      case 409:
        return 'Data ini bertentangan dengan keadaan terbaru. '
            'Muat ulang lalu coba lagi.';
      case 413:
        return 'Berkas yang dikirim terlalu besar.';
      case 429:
        return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
      case 500:
        return 'Terjadi kesalahan pada LaundryKu. Coba lagi beberapa saat lagi.';
      case 503:
        return 'LaundryKu sedang tidak bisa melayani permintaan. '
            'Coba lagi beberapa saat lagi.';
      default:
        return 'Permintaan gagal dengan kode HTTP $statusCode.';
    }
  }
}
