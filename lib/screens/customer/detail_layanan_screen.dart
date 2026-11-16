import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../services/auth_service.dart';
import '../../utils/format.dart';
import 'form_pemesanan_screen.dart';

/// Detail satu layanan, dengan tombol untuk langsung memesan.
class DetailLayananScreen extends StatelessWidget {
  const DetailLayananScreen({super.key, required this.layanan});

  final Layanan layanan;

  @override
  Widget build(BuildContext context) {
    final bool sudahMasuk =
        AuthService.instance.status == SesiStatus.masuk;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Layanan')),
      body: ListView(
        padding: const EdgeInsets.all(Jarak.xl),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(Jarak.xl),
            decoration: BoxDecoration(
              color: Warna.primary,
              borderRadius: BorderRadius.circular(Sudut.kartu),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(Jarak.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(Sudut.kolomIsian),
                  ),
                  child: const Icon(
                    Icons.local_laundry_service_rounded,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: Jarak.lg),
                Text(
                  layanan.nama,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: Jarak.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      formatRupiah(layanan.hargaPerKg),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: Jarak.xs),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '/ kg',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: Jarak.xl),

          _barisInfo(
            ikon: Icons.schedule_rounded,
            judul: 'Estimasi pengerjaan',
            isi: layanan.durasi,
          ),
          const SizedBox(height: Jarak.md),
          _barisInfo(
            ikon: Icons.scale_rounded,
            judul: 'Satuan harga',
            isi: 'Dihitung per kilogram berat pakaian',
          ),
          const SizedBox(height: Jarak.md),
          _barisInfo(
            ikon: Icons.receipt_long_rounded,
            judul: 'Harga akhir',
            isi:
                'Dihitung admin setelah pakaian ditimbang, memakai berat '
                'sebenarnya.',
          ),

          if (layanan.adaDeskripsi) ...<Widget>[
            const SizedBox(height: Jarak.xl),
            const Text(
              'Deskripsi Layanan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Warna.teksUtama,
              ),
            ),
            const SizedBox(height: Jarak.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Jarak.lg),
              decoration: BoxDecoration(
                color: Warna.permukaan,
                borderRadius: BorderRadius.circular(Sudut.kartu),
                border: Border.all(color: Warna.garis),
              ),
              child: Text(
                layanan.deskripsi!,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Warna.teksKedua,
                  height: 1.65,
                ),
              ),
            ),
          ],

          const SizedBox(height: Jarak.xl),

          if (!sudahMasuk)
            Container(
              padding: const EdgeInsets.all(Jarak.lg),
              decoration: BoxDecoration(
                color: Warna.aksenLembut,
                borderRadius: BorderRadius.circular(Sudut.kartu),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Warna.primary,
                  ),
                  SizedBox(width: Jarak.md),
                  Expanded(
                    child: Text(
                      'Masuk sebagai pelanggan dulu untuk bisa memesan '
                      'layanan ini.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Warna.primaryGelap,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            FilledButton.icon(
              onPressed: () => _pesan(context),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
              label: const Text('Pesan Layanan Ini'),
            ),

          const SizedBox(height: Jarak.lg),
        ],
      ),
    );
  }

  void _pesan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FormPemesananScreen(layananAwal: layanan),
      ),
    );
  }

  Widget _barisInfo({
    required IconData ikon,
    required String judul,
    required String isi,
  }) {
    return Container(
      padding: const EdgeInsets.all(Jarak.lg),
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        border: Border.all(color: Warna.garis),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(ikon, size: 20, color: Warna.primary),
          const SizedBox(width: Jarak.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Warna.teksUtama,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isi,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Warna.teksKedua,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
