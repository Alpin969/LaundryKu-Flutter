import '../config/api_config.dart';
import '../utils/format.dart';
import 'metode_pembayaran.dart';
import 'status_pesanan.dart';

/// Pesanan laundry.
///
/// Bentuk data mengikuti response pesanan dari backend, yang sudah digabung
/// dengan nama layanan dan nama pemesan supaya aplikasi tidak perlu meminta
/// dua kali:
/// `{ id, user_id, customer_name, customer_email, service_id, service_name,
///    service_duration, estimated_weight, actual_weight, price_per_kg,
///    total_price, status, photo_url, payment_method, payment_status, paid_at,
///    created_at }`
///
/// `actual_weight` dan `total_price` bernilai null selama admin belum mengisi
/// berat asli, karena harga akhir memang belum diketahui saat itu.
///
/// Ketiga kolom pembayaran juga boleh null: pesanan yang dibuat sebelum
/// pembayaran dicatat tidak punya metodenya.
class Pesanan {
  const Pesanan({
    required this.id,
    required this.userId,
    required this.namaPelanggan,
    required this.emailPelanggan,
    required this.serviceId,
    required this.namaLayanan,
    required this.durasiLayanan,
    required this.beratPerkiraan,
    required this.beratAktual,
    required this.hargaPerKg,
    required this.totalHarga,
    required this.status,
    required this.photoUrl,
    required this.dibuatPada,
    this.metodePembayaran,
    this.statusPembayaran,
    this.dibayarPada,
  });

  final int id;
  final int userId;
  final String namaPelanggan;
  final String emailPelanggan;
  final int serviceId;
  final String namaLayanan;
  final String durasiLayanan;

  final double beratPerkiraan;
  final double? beratAktual;

  final double hargaPerKg;

  /// Harga akhir. Null selama berat asli belum diisi admin.
  final double? totalHarga;

  final StatusPesanan status;

  /// Path foto relatif dari backend, mis. "/uploads/1699-abc.jpg".
  final String? photoUrl;

  final DateTime? dibuatPada;

  /// Metode pembayaran yang dipilih pelanggan saat memesan.
  ///
  /// Null untuk pesanan yang dibuat sebelum aplikasi mencatat pembayaran.
  final MetodePembayaran? metodePembayaran;

  /// Status pembayaran menurut backend, bukan hitungan aplikasi.
  final StatusPembayaran? statusPembayaran;

  /// Waktu pembayaran diterima, diisi backend saat pesanannya menjadi lunas.
  final DateTime? dibayarPada;

  bool get adaFoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Alamat foto yang siap dimuat, atau null bila pesanan tanpa foto.
  String? get alamatFoto => ApiConfig.alamatFoto(photoUrl);

  /// Harga akhir sudah dihitung backend.
  bool get hargaSudahFinal => totalHarga != null;

  factory Pesanan.dariJson(Map<String, dynamic> json) {
    final String? dibuat = json['created_at'] as String?;
    final String? foto = json['photo_url'] as String?;

    return Pesanan(
      id: bulatDariJson(json['id']) ?? 0,
      userId: bulatDariJson(json['user_id']) ?? 0,
      namaPelanggan: (json['customer_name'] as String?)?.trim() ?? '',
      emailPelanggan: (json['customer_email'] as String?)?.trim() ?? '',
      serviceId: bulatDariJson(json['service_id']) ?? 0,
      namaLayanan: (json['service_name'] as String?)?.trim() ?? '',
      durasiLayanan: (json['service_duration'] as String?)?.trim() ?? '-',
      beratPerkiraan: angkaDariJson(json['estimated_weight']) ?? 0,
      beratAktual: angkaDariJson(json['actual_weight']),
      hargaPerKg: angkaDariJson(json['price_per_kg']) ?? 0,
      totalHarga: angkaDariJson(json['total_price']),
      status: StatusPesanan.dariKode(json['status'] as String?),
      photoUrl: (foto == null || foto.trim().isEmpty) ? null : foto.trim(),
      dibuatPada: dibuat == null ? null : DateTime.tryParse(dibuat),
      metodePembayaran: MetodePembayaran.dariKode(
        json['payment_method'] as String?,
      ),
      statusPembayaran: StatusPembayaran.dariKode(
        json['payment_status'] as String?,
      ),
      dibayarPada: _waktuDariJson(json['paid_at']),
    );
  }

  static DateTime? _waktuDariJson(Object? nilai) {
    if (nilai is! String || nilai.trim().isEmpty) return null;
    return DateTime.tryParse(nilai);
  }
}
