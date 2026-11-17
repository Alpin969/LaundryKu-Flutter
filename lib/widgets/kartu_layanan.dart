import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/layanan.dart';
import '../utils/format.dart';

/// Kartu layanan laundry pada daftar layanan.
///
/// Menampilkan harga per kilogram dan estimasi pengerjaan, karena dua hal itu
/// yang paling sering dicari pelanggan sebelum memesan.
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          layanan.nama,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: Warna.teksUtama,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: Jarak.xs),
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
              Row(
                children: <Widget>[
                  Text(
                    formatRupiah(layanan.hargaPerKg),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Warna.primary,
                    ),
                  ),
                  const SizedBox(width: Jarak.xs),
                  const Text(
                    '/ kg',
                    style: TextStyle(fontSize: 12.5, color: Warna.teksKedua),
                  ),
                ],
              ),

              if (aksi != null) ...<Widget>[
                const Divider(height: Jarak.xl, color: Warna.garis),
                aksi!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
