import '../utils/format.dart';

/// Layanan laundry.
///
/// Bentuk data mengikuti response `GET /api/services`:
/// `{ id, name, description, price_per_kg, duration, created_at }`.
/// `description` boleh null, dan `price_per_kg` datang sebagai teks.
class Layanan {
  const Layanan({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.hargaPerKg,
    required this.durasi,
  });

  final int id;
  final String nama;
  final String? deskripsi;
  final double hargaPerKg;

  /// Estimasi pengerjaan dalam bentuk teks bebas, mis. "3 hari".
  final String durasi;

  bool get adaDeskripsi => deskripsi != null && deskripsi!.trim().isNotEmpty;

  factory Layanan.dariJson(Map<String, dynamic> json) {
    final String? deskripsi = json['description'] as String?;

    return Layanan(
      id: bulatDariJson(json['id']) ?? 0,
      nama: (json['name'] as String?)?.trim() ?? '',
      deskripsi: (deskripsi == null || deskripsi.trim().isEmpty)
          ? null
          : deskripsi.trim(),
      hargaPerKg: angkaDariJson(json['price_per_kg']) ?? 0,
      durasi: (json['duration'] as String?)?.trim() ?? '-',
    );
  }

  /// Body untuk `POST /api/services` dan `PUT /api/services/:id`.
  Map<String, dynamic> keJson() {
    return <String, dynamic>{
      'name': nama,
      'description': deskripsi,
      'price_per_kg': hargaPerKg,
      'duration': durasi,
    };
  }
}
