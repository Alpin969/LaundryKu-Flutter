import 'package:image_picker/image_picker.dart';

import '../models/metode_pembayaran.dart';
import '../models/pesanan.dart';
import '../models/status_pesanan.dart';
import 'api_client.dart';

/// Pesanan laundry untuk pelanggan maupun admin.
///
/// Endpoint:
///   POST   /api/orders                 - buat pesanan (CUSTOMER)
///   GET    /api/orders                 - daftar pesanan (?status= &limit= &offset=)
///   GET    /api/orders/:id             - detail pesanan
///   PATCH  /api/orders/:id/batal       - batalkan pesanan
///   PATCH  /api/orders/:id/foto        - unggah foto (multipart, field "photo")
///   DELETE /api/orders/:id/foto        - hapus foto pesanan
///   PATCH  /api/orders/:id/status      - ubah status (ADMIN)
///   PATCH  /api/orders/:id/berat-asli  - isi berat asli (ADMIN)
///   PATCH  /api/orders/:id/bayar       - konfirmasi pembayaran diterima (ADMIN)
class PesananService {
  const PesananService();

  /// Batas ukuran foto di backend (multer: fileSize 2 MB).
  static const int batasUkuranFotoByte = 2 * 1024 * 1024;

  /// Tipe berkas yang diterima backend (multer: fileFilter).
  static const List<String> tipeFotoDiizinkan = <String>[
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  /// Mendaftar pesanan.
  ///
  /// Pelanggan otomatis hanya menerima pesanannya sendiri; backend yang
  /// menyaringnya berdasarkan token, jadi aplikasi tidak perlu (dan tidak
  /// boleh) mengirim user_id.
  Future<List<Pesanan>> daftar({
    StatusPesanan? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final dynamic data = await ApiClient.instance.get(
      '/api/orders',
      query: <String, dynamic>{
        'status': status?.kode,
        'limit': limit,
        'offset': offset,
      },
    );

    return _ubahKeDaftarPesanan(data);
  }

  /// Mendaftar pesanan untuk beberapa status sekaligus.
  ///
  /// Backend hanya menerima satu nilai `status` per permintaan, jadi daftar
  /// aktif diambil dengan beberapa permintaan lalu digabung dan diurutkan
  /// ulang berdasarkan waktu pembuatan.
  Future<List<Pesanan>> daftarBanyakStatus(
    List<StatusPesanan> statusList, {
    int limitPerStatus = 50,
  }) async {
    final List<List<Pesanan>> hasil = await Future.wait(
      statusList.map(
        (StatusPesanan status) => daftar(status: status, limit: limitPerStatus),
      ),
    );

    final List<Pesanan> gabungan = hasil.expand((List<Pesanan> p) => p).toList();

    // Pesanan yang sama tidak akan muncul dua kali karena setiap permintaan
    // memakai satu status, tetapi pengurutan tetap dilakukan di sini.
    gabungan.sort((Pesanan a, Pesanan b) {
      final DateTime waktuA = a.dibuatPada ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime waktuB = b.dibuatPada ?? DateTime.fromMillisecondsSinceEpoch(0);
      return waktuB.compareTo(waktuA);
    });

    return gabungan;
  }

  Future<Pesanan> detail(int id) async {
    final dynamic data = await ApiClient.instance.get('/api/orders/$id');
    return Pesanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  /// Membuat pesanan baru.
  ///
  /// Harga TIDAK dikirim dari sini. Backend mengambil harga dari tabel
  /// `services` di dalam satu pernyataan SQL, sehingga harga tidak bisa
  /// dipalsukan lewat body permintaan.
  ///
  /// [metode] diisi dari halaman keranjang. Backend mencatat tunai sebagai
  /// belum dibayar (admin yang mengonfirmasi), sedangkan metode lain langsung
  /// dianggap lunas.
  ///
  /// Respons backend untuk endpoint ini hanya berisi baris `orders` apa
  /// adanya: nama layanan dan nama pemesan yang sudah digabung TIDAK ikut
  /// dikirim. Karena itu hasilnya dilengkapi lewat [detail] supaya pemanggil
  /// selalu menerima objek yang lengkap.
  Future<Pesanan> buat({
    required int serviceId,
    required double estimatedWeight,
    MetodePembayaran? metode,
  }) async {
    final dynamic data = await ApiClient.instance.post(
      '/api/orders',
      body: <String, dynamic>{
        'service_id': serviceId,
        'estimated_weight': estimatedWeight,
        'payment_method': metode?.kode,
      },
    );

    final Pesanan mentah = Pesanan.dariJson(
      Map<String, dynamic>.from(data as Map),
    );

    // Bila pengambilan susulan ini gagal, pesanan yang SUDAH SAH DIBUAT tetap
    // dikembalikan apa adanya. Melempar kesalahan di sini akan membuat
    // pelanggan mengira pesanannya belum masuk dan membuatnya dua kali.
    try {
      return await detail(mentah.id);
    } on ApiException {
      return mentah;
    }
  }

  /// Membatalkan pesanan.
  ///
  /// Pelanggan hanya boleh membatalkan pesanan yang masih menunggu konfirmasi
  /// atau sudah dikonfirmasi. Aturan itu ditegakkan backend; kalau dilanggar,
  /// backend menjawab HTTP 403 dengan alasan yang jelas.
  Future<Pesanan> batalkan(int id) async {
    final dynamic data = await ApiClient.instance.patch('/api/orders/$id/batal');
    return Pesanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  /// Mengunggah foto pesanan sebagai multipart/form-data dengan field `photo`.
  ///
  /// Tipe berkas diperiksa lebih dulu di sini. Backend hanya menerima JPEG,
  /// PNG, dan WebP; berkas yang jelas bukan salah satunya ditolak sebelum
  /// dikirim, supaya pengguna tidak menunggu unggahan yang pasti gagal.
  Future<Pesanan> unggahFoto({
    required int orderId,
    required XFile foto,
  }) async {
    final List<int> byte = await foto.readAsBytes();

    if (byte.length > batasUkuranFotoByte) {
      final double ukuranMb = byte.length / (1024 * 1024);
      throw ApiException(
        'Ukuran foto ${ukuranMb.toStringAsFixed(1)} MB melebihi batas '
        '${batasUkuranFotoByte ~/ (1024 * 1024)} MB. '
        'Pilih foto lain atau kecilkan ukurannya.',
        kode: 'FILE_TERLALU_BESAR',
      );
    }

    final String? tipe = _tipeFoto(foto);

    if (tipe == null) {
      throw ApiException(
        'Berkas "${foto.name}" bukan foto yang didukung. Pilih berkas '
        'berformat JPG, PNG, atau WebP.',
        kode: 'TIPE_FOTO_SALAH',
      );
    }

    final dynamic data = await ApiClient.instance.unggahFoto(
      path: '/api/orders/$orderId/foto',
      byte: byte,
      namaBerkas: foto.name.isEmpty ? 'foto.jpg' : foto.name,
      tipeMime: tipe,
    );

    return Pesanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  /// Menghapus foto pesanan.
  ///
  /// Pelanggan pemilik pesanan maupun admin boleh menghapusnya, sama seperti
  /// saat mengunggah. Setelah dihapus, pesanan kembali tanpa foto dan foto
  /// baru bisa diunggah lagi.
  Future<Pesanan> hapusFoto(int orderId) async {
    final dynamic data = await ApiClient.instance.delete(
      '/api/orders/$orderId/foto',
    );

    return Pesanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  /// Menentukan tipe MIME foto yang akan dikirim.
  ///
  /// Mengembalikan null hanya bila berkasnya jelas bukan gambar yang diterima
  /// backend. Berkas tanpa ekstensi yang dikenali dan tanpa keterangan tipe
  /// dari platform (mis. hasil kamera di sebagian perangkat) tetap diizinkan:
  /// yang memeriksa isi berkas sebenarnya adalah backend.
  static String? _tipeFoto(XFile foto) {
    // Keterangan tipe dari platform diperiksa lebih dulu. Bila platform
    // menyebut tipe yang tidak diterima backend, berkasnya ditolak walaupun
    // namanya berakhiran .png: nama berkas mudah dipalsukan, keterangan tipe
    // datang dari berkasnya sendiri.
    final String? dariPlatform = foto.mimeType?.toLowerCase().trim();

    if (dariPlatform != null && dariPlatform.isNotEmpty) {
      return tipeFotoDiizinkan.contains(dariPlatform) ? dariPlatform : null;
    }

    const Map<String, String> dariEkstensi = <String, String>{
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
    };

    final String nama = foto.name.toLowerCase();

    for (final MapEntry<String, String> pasangan in dariEkstensi.entries) {
      if (nama.endsWith(pasangan.key)) return pasangan.value;
    }

    // Tanpa keterangan tipe dan tanpa ekstensi yang dikenali, berkas
    // diteruskan sebagai JPEG: itulah bentuk paling umum dari foto kamera.
    // Yang benar-benar memeriksa isi berkas tetap backend.
    return nama.contains('.') ? null : 'image/jpeg';
  }

  /// Mengubah status pesanan (ADMIN).
  ///
  /// Perpindahan status yang sah ditentukan backend. Pesanan hanya bisa
  /// menjadi COMPLETED setelah berat asli diisi.
  Future<Pesanan> ubahStatus({
    required int orderId,
    required StatusPesanan status,
  }) async {
    final dynamic data = await ApiClient.instance.patch(
      '/api/orders/$orderId/status',
      body: <String, dynamic>{'status': status.kode},
    );

    return Pesanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  /// Mengisi berat asli (ADMIN).
  ///
  /// Harga akhir dihitung backend di dalam SQL memakai harga per kg milik
  /// pesanan itu sendiri. Aplikasi hanya menampilkan hasilnya, dan tidak
  /// pernah menghitung harga sendiri sebagai sumber kebenaran.
  Future<Pesanan> isiBeratAsli({
    required int orderId,
    required double actualWeight,
  }) async {
    final dynamic data = await ApiClient.instance.patch(
      '/api/orders/$orderId/berat-asli',
      body: <String, dynamic>{'actual_weight': actualWeight},
    );

    return Pesanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  /// Mengonfirmasi pembayaran pesanan sudah diterima (ADMIN).
  ///
  /// Dipakai untuk pembayaran tunai, yang uangnya baru benar-benar diterima
  /// saat pakaian diambil. Pesanan sudah lunas tidak bisa dikonfirmasi lagi;
  /// backend menjawab HTTP 409 dengan alasan yang jelas.
  Future<Pesanan> konfirmasiBayar(int orderId) async {
    final dynamic data = await ApiClient.instance.patch(
      '/api/orders/$orderId/bayar',
    );

    return Pesanan.dariJson(Map<String, dynamic>.from(data as Map));
  }

  List<Pesanan> _ubahKeDaftarPesanan(dynamic data) {
    if (data is! List) return const <Pesanan>[];

    return data
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) =>
              Pesanan.dariJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
