import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/layanan.dart';
import '../../services/auth_service.dart';
import '../../utils/format.dart';
import 'form_pemesanan_screen.dart';

/// Detail satu layanan.
///
/// Dari sini pelanggan memilih dua jalan: "Bayar Langsung" untuk membayar
/// layanan ini saja, atau "Tambah ke Keranjang" untuk menggabungkannya dengan
/// layanan lain sebelum membayar.
class DetailLayananScreen extends StatelessWidget {
  const DetailLayananScreen({super.key, required this.layanan});

  final Layanan layanan;

  @override
  Widget build(BuildContext context) {
    final bool sudahMasuk = AuthService.instance.status == SesiStatus.masuk;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Layanan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Jarak.xl,
          Jarak.sm,
          Jarak.xl,
          Jarak.xl,
        ),
        children: <Widget>[
          // Kepala: nama layanan dan harga, dengan bidang cyan sebagai
          // penanda brand. Harga adalah informasi pertama yang dicari.
          Container(
            padding: const EdgeInsets.all(Jarak.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Warna.primary, Warna.primaryGelap],
              ),
              borderRadius: BorderRadius.circular(Sudut.kartu),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Jarak.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(Sudut.pil),
                  ),
                  child: Text(
                    'Estimasi ${layanan.durasi}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: Jarak.md),
                Text(
                  layanan.nama,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
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
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
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

          if (layanan.adaDeskripsi) ...<Widget>[
            const SizedBox(height: Jarak.xl),
            const Text(
              'Tentang layanan ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
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

          const SizedBox(height: Jarak.lg),
          _barisInfo(
            ikon: Icons.scale_outlined,
            judul: 'Dihitung per kilogram',
            isi: 'Harga berlaku untuk setiap kilogram berat pakaian.',
          ),
          const SizedBox(height: Jarak.md),
          _barisInfo(
            ikon: Icons.receipt_long_outlined,
            judul: 'Harga akhir setelah ditimbang',
            isi:
                'Admin menimbang pakaian saat diterima, lalu total biaya '
                'dihitung dari berat sebenarnya.',
          ),

          const SizedBox(height: Jarak.xl),

          if (!sudahMasuk)
            Container(
              padding: const EdgeInsets.all(Jarak.lg),
              decoration: BoxDecoration(
                color: Warna.aksenLembut,
                borderRadius: BorderRadius.circular(Sudut.kartu),
                border: Border.all(color: const Color(0xFFA5F3FC)),
              ),
              child: const Text(
                'Masuk sebagai pelanggan dulu untuk bisa memesan layanan ini.',
                style: TextStyle(
                  fontSize: 13,
                  color: Warna.primaryGelap,
                  height: 1.5,
                ),
              ),
            )
          else ...<Widget>[
            FilledButton(
              onPressed: () => _bukaForm(context, langsungBayar: true),
              child: const Text('Bayar Langsung'),
            ),
            const SizedBox(height: Jarak.md),
            OutlinedButton(
              onPressed: () => _bukaForm(context, langsungBayar: false),
              child: const Text('Tambah ke Keranjang'),
            ),
          ],

          const SizedBox(height: Jarak.lg),
        ],
      ),
    );
  }

  void _bukaForm(BuildContext context, {required bool langsungBayar}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FormPemesananScreen(
          layananAwal: layanan,
          langsungBayar: langsungBayar,
        ),
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
          Icon(ikon, size: 19, color: Warna.primary),
          const SizedBox(width: Jarak.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
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
