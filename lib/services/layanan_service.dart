import '../models/layanan.dart';
import 'api_client.dart';

/// Layanan laundry: membaca daftar, dan (khusus admin) menambah,
/// mengubah, serta menghapus.
///
/// Endpoint:
///   GET    /api/services        - terbuka, tanpa login
///   GET    /api/services/:id    - terbuka, tanpa login
///   POST   /api/services        - ADMIN
///   PUT    /api/services/:id    - ADMIN
///   DELETE /api/services/:id    - ADMIN
class LayananService {
  const LayananService();

  Future<List<Layanan>> daftarSemua({String? cari}) async {
    final dynamic data = await ApiClient.instance.get(
      '/api/services',
      query: <String, dynamic>{'search': cari},
    );

    return _ubahKeDaftarLayanan(data);
  }

  Future<Layanan> detail(int id) async {
    final dynamic data = await ApiClient.instance.get('/api/services/$id');
    return Layanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Layanan> tambah(Layanan layanan) async {
    final dynamic data = await ApiClient.instance.post(
      '/api/services',
      body: layanan.keJson(),
    );
    return Layanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Layanan> ubah(Layanan layanan) async {
    final dynamic data = await ApiClient.instance.put(
      '/api/services/${layanan.id}',
      body: layanan.keJson(),
    );
    return Layanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  /// Menghapus layanan.
  ///
  /// Layanan yang masih dipakai pada pesanan tidak bisa dihapus; backend
  /// menolaknya dengan HTTP 409 dan pesan yang menjelaskan sebabnya. Pesan itu
  /// diteruskan apa adanya lewat ApiException.
  Future<void> hapus(int id) async {
    try {
      await ApiClient.instance.delete('/api/services/$id');
    } on ApiException catch (kesalahan) {
      // Selama cacat backend 23001 belum diperbaiki (lihat catatan pada
      // pengujian integrasi), penolakan karena layanan masih dipakai datang
      // sebagai 500 generik. Pesan generik tidak memberi admin langkah
      // berikutnya, jadi di sini diperjelas. Bila backend sudah menjawab 409,
      // pesannya sudah jelas dan diteruskan apa adanya.
      if (kesalahan.statusCode == 500) {
        throw ApiException(
          'Layanan gagal dihapus. Kemungkinan layanan ini masih dipakai pada '
          'pesanan, sehingga belum bisa dihapus. Selesaikan atau batalkan '
          'pesanan tersebut lebih dahulu, lalu coba lagi.',
          kode: kesalahan.kode,
          statusCode: kesalahan.statusCode,
        );
      }

      rethrow;
    }
  }

  List<Layanan> _ubahKeDaftarLayanan(dynamic data) {
    if (data is! List) return const <Layanan>[];

    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) =>
              Layanan.dariJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
