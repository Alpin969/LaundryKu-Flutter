import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/layanan.dart';
import '../utils/format.dart';

/// Kartu layanan laundry pada daftar layanan.
///
/// Menampilkan harga per kilogram dan estimasi pengerjaan, karena dua hal itu
/// yang paling sering dicari pelanggan sebelum memesan. Ikon di kiri memberi
/// pemisah visual yang cepat dikenali antar kartu.
class KartuLayanan extends StatelessWidget {
  const KartuLayanan({
    super.key,
    required this.layanan,
    this.onTap,
    this.aksi,
  });

  final Layanan layanan;
  final VoidCallback? onTap;

  /// Tombol tambahan di bawah kartu, mis. Edit dan Hapus untuk admin.
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        child: Padding(
          padding: const EdgeInsets.all(Jarak.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Warna.aksenLembut,
                      borderRadius: BorderRadius.circular(Sudut.kolomIsian),
                      border: Border.all(color: const Color(0xFFA5F3FC)),
                    ),
                    child: const Icon(
                      Icons.local_laundry_service_outlined,
                      size: 22,
                      color: Warna.primary,
                    ),
                  ),
                  const SizedBox(width: Jarak.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          layanan.nama,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Warna.teksUtama,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Estimasi ${layanan.durasi}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Warna.teksKedua,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Padding(
                      padding: EdgeInsets.only(left: Jarak.sm, top: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Warna.teksSamar,
                      ),
                    ),
                ],
              ),

              if (layanan.adaDeskripsi) ...<Widget>[
                const SizedBox(height: Jarak.md),
                Text(
                  layanan.deskripsi!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Warna.teksKedua,
                    height: 1.55,
                  ),
                ),
              ],

              const SizedBox(height: Jarak.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Jarak.md,
                  vertical: Jarak.sm,
                ),
                decoration: BoxDecoration(
                  color: Warna.latar,
                  borderRadius: BorderRadius.circular(Sudut.kolomIsian),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      formatRupiah(layanan.hargaPerKg),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Warna.primary,
                      ),
                    ),
                    const SizedBox(width: Jarak.xs),
                    const Text(
                      'per kg',
                      style: TextStyle(fontSize: 12, color: Warna.teksKedua),
                    ),
                  ],
                ),
              ),

              if (aksi != null) ...<Widget>[
                const SizedBox(height: Jarak.md),
                const Divider(height: 1, color: Warna.garis),
                const SizedBox(height: Jarak.md),
                aksi!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
