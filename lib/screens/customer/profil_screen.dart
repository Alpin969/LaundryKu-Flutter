import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../utils/format.dart';
import '../../widgets/baris_detail.dart';
import '../../widgets/pesan_ui.dart';

/// Halaman profil, dipakai pelanggan maupun admin.
///
/// Isinya data akun dari `GET /api/auth/me`, ditambah tombol keluar. Tidak ada
/// form ubah profil karena backend belum menyediakan endpoint-nya; menampilkan
/// kolom yang tidak bisa disimpan hanya akan menyesatkan.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  bool _sedangMuatUlang = false;

  Future<void> _muatUlang() async {
    setState(() => _sedangMuatUlang = true);
    await AuthService.instance.segarkanAkun();
    if (mounted) setState(() => _sedangMuatUlang = false);
  }

  Future<void> _keluar() async {
    final bool setuju = await konfirmasi(
      context,
      judul: 'Keluar dari akun?',
      pesan:
          'Anda perlu memasukkan email dan kata sandi lagi untuk masuk '
          'kembali.',
      labelLanjut: 'Keluar',
      berbahaya: true,
    );

    if (!setuju) return;

    // Token dihapus dari penyimpanan aman, lalu gerbang aplikasi otomatis
    // menampilkan halaman login.
    await AuthService.instance.keluar();
  }

  @override
  Widget build(BuildContext context) {
    final User? pengguna = AuthService.instance.pengguna;

    return RefreshIndicator(
      onRefresh: _muatUlang,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Jarak.xl, Jarak.lg, Jarak.xl, Jarak.xxl),
        children: <Widget>[
          _kepala(pengguna),
          const SizedBox(height: Jarak.xl),

          KartuBagian(
            judul: 'Informasi Akun',
            ikon: Icons.badge_outlined,
            aksi: IconButton(
              onPressed: _sedangMuatUlang ? null : _muatUlang,
              tooltip: 'Muat ulang data akun',
              icon: _sedangMuatUlang
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
            ),
            anak: Column(
              children: <Widget>[
                BarisDetail(
                  label: 'Nama',
                  nilai: pengguna?.nama.isNotEmpty == true
                      ? pengguna!.nama
                      : 'Tidak tercatat',
                ),
                const SizedBox(height: Jarak.sm),
                BarisDetail(
                  label: 'Email',
                  nilai: pengguna?.email.isNotEmpty == true
                      ? pengguna!.email
                      : 'Tidak tercatat',
                ),
                const SizedBox(height: Jarak.sm),
                BarisDetail(
                  label: 'Role',
                  nilai: pengguna?.peran.label ?? '-',
                ),
                const SizedBox(height: Jarak.sm),
                BarisDetail(
                  label: 'Terdaftar sejak',
                  nilai: formatTanggalSingkat(pengguna?.dibuatPada),
                ),
              ],
            ),
          ),

          const SizedBox(height: Jarak.xl),

          KartuBagian(
            judul: 'Tentang Aplikasi',
            ikon: Icons.info_outline_rounded,
            anak: Column(
              children: <Widget>[
                const BarisDetail(label: 'Aplikasi', nilai: 'LaundryKu'),
                const SizedBox(height: Jarak.sm),
                const BarisDetail(
                  label: 'Slogan',
                  nilai: 'Bersih, Praktis, Terpercaya',
                ),
                const SizedBox(height: Jarak.sm),
                BarisDetail(
                  label: 'Alamat server',
                  nilai: ApiConfig.baseUrl,
                ),
              ],
            ),
          ),

          const SizedBox(height: Jarak.xl),

          OutlinedButton.icon(
            onPressed: _keluar,
            style: OutlinedButton.styleFrom(foregroundColor: Warna.bahaya),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Keluar'),
          ),

          const SizedBox(height: Jarak.lg),
        ],
      ),
    );
  }

  Widget _kepala(User? pengguna) {
    return Container(
      padding: const EdgeInsets.all(Jarak.lg),
      decoration: BoxDecoration(
        color: Warna.permukaan,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        border: Border.all(color: Warna.garis),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Warna.aksen,
              shape: BoxShape.circle,
            ),
            child: Text(
              pengguna?.inisial ?? '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Warna.primary,
              ),
            ),
          ),
          const SizedBox(width: Jarak.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pengguna?.nama.isNotEmpty == true
                      ? pengguna!.nama
                      : 'Pengguna',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Warna.teksUtama,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pengguna?.email ?? '-',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Warna.teksKedua,
                  ),
                ),
                const SizedBox(height: Jarak.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Jarak.sm + 2,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: pengguna?.adalahAdmin == true
                        ? Warna.peringatanMuda
                        : Warna.aksen,
                    borderRadius: BorderRadius.circular(Sudut.pil),
                  ),
                  child: Text(
                    pengguna?.peran.label ?? '-',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: pengguna?.adalahAdmin == true
                          ? Warna.peringatan
                          : Warna.primary,
                    ),
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
