import '../utils/format.dart';

/// Peran akun.
///
/// Backend hanya mengirim "ADMIN" atau "CUSTOMER" (dijaga oleh constraint
/// `chk_users_role` di database). Nilai lain tetap diterima dan diperlakukan
/// sebagai customer: kalau data tidak terduga, aplikasi sebaiknya memberi
/// hak paling sedikit, bukan paling banyak.
enum PeranPengguna {
  admin('ADMIN', 'Admin'),
  customer('CUSTOMER', 'Pelanggan');

  const PeranPengguna(this.kode, this.label);

  /// Nilai yang dipakai backend.
  final String kode;

  /// Sebutan yang ditampilkan ke pengguna.
  final String label;

  static PeranPengguna dariKode(String? kode) {
    final String dicari = (kode ?? '').toUpperCase();
    for (final PeranPengguna peran in values) {
      if (peran.kode == dicari) return peran;
    }
    return PeranPengguna.customer;
  }
}

/// Akun pengguna RENOVA.
///
/// `password_hash` tidak pernah ada di sini karena backend tidak pernah
/// mengirimkannya.
class User {
  const User({
    required this.id,
    required this.nama,
    required this.email,
    required this.peran,
    this.dibuatPada,
  });

  final int id;
  final String nama;
  final String email;
  final PeranPengguna peran;
  final DateTime? dibuatPada;

  bool get adalahAdmin => peran == PeranPengguna.admin;

  factory User.dariJson(Map<String, dynamic> json) {
    final String? dibuat = json['created_at'] as String?;

    return User(
      id: bulatDariJson(json['id']) ?? 0,
      nama: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      peran: PeranPengguna.dariKode(json['role'] as String?),
      dibuatPada: dibuat == null ? null : DateTime.tryParse(dibuat),
    );
  }

  /// Inisial nama untuk ditampilkan di avatar, mis. "Alvin Pratama" -> "AP".
  String get inisial {
    final List<String> bagian = nama
        .split(' ')
        .where((String b) => b.isNotEmpty)
        .toList();

    if (bagian.isEmpty) return '?';
    if (bagian.length == 1) return bagian.first.characters();
    return '${bagian.first.characters()}${bagian.last.characters()}';
  }
}

extension on String {
  /// Huruf pertama, huruf besar.
  String characters() => isEmpty ? '' : substring(0, 1).toUpperCase();
}
