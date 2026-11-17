import 'package:flutter/foundation.dart';

/// Alamat REST API LaundryKu.
///
/// Alamat diambil dari --dart-define supaya satu kode yang sama bisa dipakai
/// untuk backend lokal maupun backend yang sudah online:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
///
/// Tidak ada kredensial (DB_PASSWORD, JWT_SECRET, atau sertifikat Aiven) yang
/// disimpan di aplikasi ini. Aplikasi hanya bicara lewat REST API.
class ApiConfig {
  const ApiConfig._();

  static const String _dariDartDefine = String.fromEnvironment('API_BASE_URL');

  /// Alamat dasar API, tanpa garis miring di akhir.
  static String get baseUrl {
    // --dart-define selalu menang bila diisi.
    if (_dariDartDefine.isNotEmpty) return _hapusGarisMiring(_dariDartDefine);

    // Nilai cadangan dipilih per platform: "localhost" di dalam emulator
    // Android menunjuk ke emulator itu sendiri, bukan ke komputer yang
    // menjalankan backend. Komputer host harus dipanggil lewat 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String _hapusGarisMiring(String nilai) {
    return nilai.endsWith('/') ? nilai.substring(0, nilai.length - 1) : nilai;
  }

  /// Mengubah photo_url dari backend menjadi alamat yang bisa dimuat.
  ///
  /// Backend menyimpan foto sebagai path relatif ("/uploads/nama.jpg"), jadi
  /// alamatnya perlu disambung dengan base URL lebih dulu.
  static String? alamatFoto(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }
    return '$baseUrl$photoUrl';
  }
}
