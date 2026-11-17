import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_client.dart';

/// Keadaan sesi login aplikasi.
///
/// Token disimpan di flutter_secure_storage (Keystore di Android, Keychain di
/// iOS), bukan di SharedPreferences biasa, karena token ini setara dengan
/// kunci akun.
///
/// Aturan yang dipegang di sini:
///   - Role hanya dipakai untuk MENENTUKAN HALAMAN, bukan sebagai penjaga
///     keamanan. Penjaga sebenarnya adalah backend, yang memeriksa role dari
///     token pada setiap permintaan.
///   - Setelah login, akun selalu diperiksa ulang lewat GET /api/auth/me
///     supaya role yang dipakai aplikasi benar-benar berasal dari server.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _kunciToken = 'laundryku_token';

  // v11 sudah memakai AES-GCM dengan pembungkusan kunci RSA secara bawaan
  // (lihat AndroidOptions.defaultOptions), termasuk resetOnError yang membuat
  // aplikasi tidak macet bila kunci KeyStore rusak. Jadi tidak ada opsi
  // tambahan yang perlu diisi di sini.
  static const FlutterSecureStorage _penyimpanan = FlutterSecureStorage();

  SesiStatus _status = SesiStatus.memeriksa;
  SesiStatus get status => _status;

  User? _pengguna;
  User? get pengguna => _pengguna;

  bool _sudahDiperiksa = false;
  bool get sudahDiperiksa => _sudahDiperiksa;

  /// Pesan yang perlu ditampilkan sekali di halaman login, mis. ketika token
  /// kedaluwarsa di tengah pemakaian atau server tidak bisa dihubungi.
  String? _pesanUntukLogin;
  String? ambilPesanUntukLogin() {
    final String? pesan = _pesanUntukLogin;
    _pesanUntukLogin = null;
    return pesan;
  }

  /// Dipanggil ketika sesi berakhir, dipakai aplikasi untuk menutup halaman
  /// yang sedang terbuka supaya pengguna benar-benar kembali ke halaman login.
  void Function()? saatSesiKembaliKeLogin;

  /// Dipanggil sekali saat aplikasi mulai: membaca token yang tersimpan, lalu
  /// memastikan tokennya masih berlaku ke backend.
  Future<void> periksaSesi() async {
    // Saat token ditolak backend di tengah pemakaian, sesi langsung diakhiri.
    ApiClient.instance.saatSesiBerakhir = _akhiriSesiKarenaToken;

    try {
      final String? token = await _bacaToken();

      if (token == null || token.isEmpty) {
        _ubahStatus(SesiStatus.belumMasuk);
        return;
      }

      ApiClient.instance.token = token;

      // Token tersimpan belum tentu masih sah (masa berlakunya 1 hari). Satu
      // permintaan ke /api/auth/me memastikan sekaligus mengambil data akun
      // terbaru langsung dari database.
      final dynamic data = await ApiClient.instance.get('/api/auth/me');
      _pengguna = User.dariJson(Map<String, dynamic>.from(data['user'] as Map));
      _ubahStatus(SesiStatus.masuk);
    } on ApiException catch (kesalahan) {
      if (kesalahan.sesiBermasalah) {
        await _hapusToken();
        ApiClient.instance.token = null;
        _pengguna = null;
        _ubahStatus(SesiStatus.belumMasuk);
      } else {
        // Backend tidak bisa dihubungi, tetapi token masih tersimpan. Sesi
        // dianggap belum masuk supaya pengguna tidak terjebak di halaman yang
        // datanya pasti gagal dimuat. Tokennya sendiri tidak dihapus.
        _pesanUntukLogin = kesalahan.pesan;
        _ubahStatus(SesiStatus.belumMasuk);
      }
    } catch (_) {
      // Kegagalan tak terduga saat memeriksa sesi tidak boleh membuat aplikasi
      // berhenti di splash. Pengguna diarahkan ke halaman login.
      _pesanUntukLogin = 'Sesi tidak bisa diperiksa. Silakan login kembali.';
      _ubahStatus(SesiStatus.belumMasuk);
    } finally {
      _sudahDiperiksa = true;
      notifyListeners();
    }
  }

  /// Login. Setelah token diterima, akun diperiksa lewat /api/auth/me.
  Future<User> masuk({required String email, required String password}) async {
    final dynamic data = await ApiClient.instance.post(
      '/api/auth/login',
      body: <String, dynamic>{'email': email.trim(), 'password': password},
    );

    final String? token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Proses masuk belum selesai. Coba lagi sebentar lagi.',
        kode: 'TOKEN_TIDAK_ADA',
      );
    }

    await _simpanToken(token);
    ApiClient.instance.token = token;

    return _ambilDanSimpanAkun(data['user']);
  }

  /// Pendaftaran akun baru.
  ///
  /// Role tidak pernah dikirim dari sini: backend selalu membuat akun baru
  /// sebagai CUSTOMER. Satu-satunya cara menjadi ADMIN adalah lewat skrip
  /// `npm run create-admin` di backend.
  Future<User> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    final dynamic data = await ApiClient.instance.post(
      '/api/auth/register',
      body: <String, dynamic>{
        'name': nama.trim(),
        'email': email.trim(),
        'password': password,
      },
    );

    final String? token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Pendaftaran berhasil, tetapi sesi Anda belum aktif. Silakan masuk.',
        kode: 'TOKEN_TIDAK_ADA',
      );
    }

    await _simpanToken(token);
    ApiClient.instance.token = token;

    return _ambilDanSimpanAkun(data['user']);
  }

  /// Mengambil data akun terbaru dari server berdasarkan token yang dipakai.
  Future<User> _ambilDanSimpanAkun(dynamic userDariLogin) async {
    // Data dari login/register dipakai lebih dulu sebagai tampilan awal, lalu
    // diganti hasil /api/auth/me yang dibaca langsung dari database.
    User akun = userDariLogin is Map
        ? User.dariJson(Map<String, dynamic>.from(userDariLogin))
        : (_pengguna ?? const User(
            id: 0,
            nama: '',
            email: '',
            peran: PeranPengguna.customer,
          ));

    try {
      final dynamic data = await ApiClient.instance.get('/api/auth/me');
      akun = User.dariJson(Map<String, dynamic>.from(data['user'] as Map));
    } on ApiException {
      // /api/auth/me gagal bukan alasan menggagalkan login; data dari langkah
      // sebelumnya sudah cukup untuk membuka aplikasi.
    }

    _pengguna = akun;
    _ubahStatus(SesiStatus.masuk);
    return akun;
  }

  /// Mengakhiri sesi: token dihapus, lalu aplikasi kembali ke halaman login.
  Future<void> keluar({String? pesan}) async {
    await _hapusToken();
    ApiClient.instance.token = null;
    _pengguna = null;
    _pesanUntukLogin = pesan;
    _ubahStatus(SesiStatus.belumMasuk);
  }

  /// Menyegarkan data akun, misalnya setelah data di backend berubah.
  Future<void> segarkanAkun() async {
    try {
      final dynamic data = await ApiClient.instance.get('/api/auth/me');
      _pengguna = User.dariJson(Map<String, dynamic>.from(data['user'] as Map));
      notifyListeners();
    } on ApiException {
      // Gagal menyegarkan tidak boleh mengganggu; data lama tetap dipakai.
    }
  }

  /// Mengubah nama akun, dan bila diisi sekaligus mengganti kata sandi.
  ///
  /// Penggantian kata sandi wajib menyertakan kata sandi lama; backend yang
  /// memeriksanya, sehingga token yang tercuri tidak cukup untuk mengunci
  /// pemilik akun dari luar.
  Future<User> ubahProfil({
    required String nama,
    String? sandiLama,
    String? sandiBaru,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{'name': nama.trim()};

    if (sandiBaru != null) {
      body['current_password'] = sandiLama;
      body['new_password'] = sandiBaru;
    }

    final dynamic data = await ApiClient.instance.patch(
      '/api/auth/me',
      body: body,
    );

    final User akun = User.dariJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );

    _pengguna = akun;
    notifyListeners();

    return akun;
  }

  Future<void> _akhiriSesiKarenaToken() async {
    if (_status == SesiStatus.belumMasuk) return;

    await _hapusToken();
    ApiClient.instance.token = null;
    _pengguna = null;
    _pesanUntukLogin =
        'Sesi Anda sudah berakhir. Silakan login kembali untuk melanjutkan.';
    _ubahStatus(SesiStatus.belumMasuk);
  }

  void _ubahStatus(SesiStatus baru) {
    if (_status == baru) return;

    final bool kembaliKeLogin =
        baru == SesiStatus.belumMasuk && _status == SesiStatus.masuk;

    _status = baru;
    notifyListeners();

    // Dijalankan setelah pemberitahuan supaya halaman login sudah siap
    // ditampilkan ketika halaman-halaman di atasnya ditutup.
    if (kembaliKeLogin) saatSesiKembaliKeLogin?.call();
  }

  // Penyimpanan token.
  //
  // flutter_secure_storage tidak tersedia di web. Di sana token disimpan di
  // memori saja, sehingga sesi hilang saat halaman dimuat ulang. Ini disengaja:
  // menaruh JWT di localStorage membuatnya bisa dibaca skrip lain di halaman
  // yang sama.
  //
  // Kegagalan penyimpanan aman di perangkat (mis. Keystore bermasalah) juga
  // tidak boleh membuat aplikasi berhenti; pengguna cukup login kembali.

  static String? _tokenDiMemori;

  Future<String?> _bacaToken() async {
    if (kIsWeb) return _tokenDiMemori;
    try {
      return await _penyimpanan.read(key: _kunciToken);
    } catch (_) {
      return _tokenDiMemori;
    }
  }

  Future<void> _simpanToken(String token) async {
    _tokenDiMemori = token;
    if (kIsWeb) return;
    try {
      await _penyimpanan.write(key: _kunciToken, value: token);
    } catch (_) {
      // Sudah tersimpan di memori, jadi sesi tetap berjalan sampai aplikasi
      // ditutup.
    }
  }

  Future<void> _hapusToken() async {
    _tokenDiMemori = null;
    if (kIsWeb) return;
    try {
      await _penyimpanan.delete(key: _kunciToken);
    } catch (_) {
      // Tidak ada yang bisa dilakukan; token di memori sudah dihapus.
    }
  }

  /// Dipakai pengujian untuk memastikan penyimpanan token berjalan.
  @visibleForTesting
  Future<void> simpanTokenUji(String token) => _simpanToken(token);

  @visibleForTesting
  Future<String?> bacaTokenUji() => _bacaToken();

  @visibleForTesting
  static String contohToken() => base64Encode(const <int>[1, 2, 3, 4, 5, 6]);
}

enum SesiStatus {
  /// Token sedang diperiksa saat aplikasi dibuka.
  memeriksa,

  /// Belum login, atau token sudah tidak berlaku.
  belumMasuk,

  /// Sudah login dan identitasnya sudah dipastikan backend.
  masuk,
}
