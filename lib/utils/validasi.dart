/// Aturan validasi form di sisi aplikasi.
///
/// Tujuannya bukan menggantikan pemeriksaan backend, melainkan memberi tahu
/// pengguna lebih cepat sebelum permintaan dikirim. Backend tetap memeriksa
/// ulang semuanya.
///
/// Batas yang dipakai di sini disamakan dengan `validate.js` di backend:
///   - name      : 1 - 100 karakter
///   - password  : 8 - 72 karakter (bcrypt hanya memakai 72 byte pertama)
///   - duration  : 1 - 50 karakter
class Validasi {
  const Validasi._();

  static const int panjangPasswordMin = 8;
  static const int panjangPasswordMax = 72;

  /// Sederhana dan sengaja tidak terlalu ketat: pola ini hanya menolak isian
  /// yang jelas bukan email, dan backend tetap memakai pemeriksaan sendiri.
  static final RegExp _polaEmail = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$',
  );

  static String? namaLengkap(String? nilai) {
    final String teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Nama lengkap wajib diisi.';
    if (teks.length < 3) return 'Nama minimal 3 karakter.';
    if (teks.length > 100) return 'Nama maksimal 100 karakter.';
    return null;
  }

  static String? email(String? nilai) {
    final String teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Email wajib diisi.';
    if (!_polaEmail.hasMatch(teks)) {
      return 'Format email belum benar, contoh: nama@email.com.';
    }
    if (teks.length > 100) return 'Email maksimal 100 karakter.';
    return null;
  }

  static String? password(String? nilai) {
    final String teks = nilai ?? '';
    if (teks.isEmpty) return 'Kata sandi wajib diisi.';
    if (teks.length < panjangPasswordMin) {
      return 'Kata sandi minimal $panjangPasswordMin karakter.';
    }
    if (teks.length > panjangPasswordMax) {
      return 'Kata sandi maksimal $panjangPasswordMax karakter.';
    }
    return null;
  }

  /// Login tidak memberi batas panjang minimum: batas itu urusan pendaftaran.
  /// Yang penting kolomnya tidak kosong, supaya pengguna lama tidak tertahan
  /// hanya karena aturan baru.
  static String? passwordMasuk(String? nilai) {
    if ((nilai ?? '').isEmpty) return 'Kata sandi wajib diisi.';
    return null;
  }

  static String? konfirmasiPassword(String? nilai, String password) {
    if ((nilai ?? '').isEmpty) return 'Konfirmasi kata sandi wajib diisi.';
    if (nilai != password) return 'Konfirmasi kata sandi belum sama.';
    return null;
  }

  /// Berat perkiraan pesanan. Batasnya sama dengan backend: 0.01 sampai 999999.
  static String? beratPerkiraan(String? nilai) {
    final String teks = (nilai ?? '').trim().replaceAll(',', '.');
    if (teks.isEmpty) return 'Berat perkiraan wajib diisi.';

    final double? angka = double.tryParse(teks);
    if (angka == null) return 'Berat harus berupa angka, contoh: 3.5';
    if (angka <= 0) return 'Berat harus lebih dari 0 kg.';
    if (angka > 999999) return 'Berat terlalu besar.';
    return null;
  }

  static String? beratAktual(String? nilai) {
    final String teks = (nilai ?? '').trim().replaceAll(',', '.');
    if (teks.isEmpty) return 'Berat aktual wajib diisi.';

    final double? angka = double.tryParse(teks);
    if (angka == null) return 'Berat harus berupa angka, contoh: 3.5';
    if (angka <= 0) return 'Berat harus lebih dari 0 kg.';
    if (angka > 999999) return 'Berat terlalu besar.';
    return null;
  }

  static String? namaLayanan(String? nilai) {
    final String teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Nama layanan wajib diisi.';
    if (teks.length > 100) return 'Nama layanan maksimal 100 karakter.';
    return null;
  }

  static String? hargaPerKg(String? nilai) {
    final String teks = (nilai ?? '').trim().replaceAll(',', '.');
    if (teks.isEmpty) return 'Harga per kg wajib diisi.';

    final double? angka = double.tryParse(teks);
    if (angka == null) return 'Harga harus berupa angka, contoh: 7500';
    if (angka <= 0) return 'Harga harus lebih dari 0.';
    if (angka > 99999999) return 'Harga terlalu besar.';
    return null;
  }

  static String? durasiLayanan(String? nilai) {
    final String teks = (nilai ?? '').trim();
    if (teks.isEmpty) return 'Estimasi pengerjaan wajib diisi.';
    if (teks.length > 50) return 'Estimasi maksimal 50 karakter.';
    return null;
  }

  /// Catatan tambahan. Backend belum punya kolomnya, jadi kolom ini tidak
  /// dikirim ke server; validasi hanya sebatas panjang agar tidak keterlaluan.
  static String? catatan(String? nilai) {
    if ((nilai ?? '').trim().length > 500) {
      return 'Catatan maksimal 500 karakter.';
    }
    return null;
  }
}
