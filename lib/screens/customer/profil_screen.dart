import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../utils/format.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/baris_detail.dart';
import '../../widgets/pesan_ui.dart';
import 'ubah_profil_screen.dart';

/// Halaman profil, dipakai pelanggan maupun admin.
///
/// Isinya data akun dari `GET /api/auth/me`, tombol ubah data akun, dan
/// tombol keluar.
///
/// [muatUlang] dipanggil penyegar otomatis di kerangka navigasi; halaman ini
/// tidak lagi punya tombol muat ulang sendiri.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => ProfilScreenState();
}

class ProfilScreenState extends State<ProfilScreen> {
  Future<void> muatUlang() async {
    await AuthService.instance.segarkanAkun();
    if (mounted) setState(() {});
  }

  Future<void> _bukaUbahProfil() async {
    final bool? berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const UbahProfilScreen()),
    );

    if (!mounted || berhasil != true) return;

    // Data akun sudah diperbarui di AuthService, jadi halaman ini cukup
    // digambar ulang untuk menampilkan nama yang baru.
    setState(() {});
    tampilkanPesan(
      context,
      'Data akun berhasil diperbarui.',
      jenis: JenisPesan.sukses,
    );
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
      onRefresh: muatUlang,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Jarak.xl,
          Jarak.lg,
          Jarak.xl,
          Jarak.xxl,
        ),
        children: <Widget>[
          _kepala(pengguna),
          const SizedBox(height: Jarak.lg),

          FilledButton(
            onPressed: _bukaUbahProfil,
            child: const Text('Ubah Profil'),
          ),

          const SizedBox(height: Jarak.xl),

          KartuBagian(
            judul: 'Informasi akun',
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
                  label: 'Jenis akun',
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

          const SizedBox(height: Jarak.lg),

          KartuBagian(
            judul: 'Tentang aplikasi',
            anak: Column(
              children: <Widget>[
                const BarisDetail(
                  label: 'Aplikasi',
                  nilai: NamaAplikasi.nama,
                ),
                const SizedBox(height: Jarak.sm),
                const BarisDetail(
                  label: 'Jenis',
                  nilai: NamaAplikasi.deskripsi,
                ),
                const SizedBox(height: Jarak.sm),
                const BarisDetail(
                  label: 'Tagline',
                  nilai: NamaAplikasi.slogan,
                ),
                const SizedBox(height: Jarak.sm),
                const BarisDetail(label: 'Versi', nilai: '1.0.0'),
              ],
            ),
          ),

          const SizedBox(height: Jarak.xl),

          OutlinedButton(
            onPressed: _keluar,
            style: OutlinedButton.styleFrom(foregroundColor: Warna.bahaya),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.logout_rounded, size: 18),
                SizedBox(width: Jarak.sm),
                Text('Keluar'),
              ],
            ),
          ),

          const SizedBox(height: Jarak.lg),
        ],
      ),
    );
  }

  Widget _kepala(User? pengguna) {
    return Container(
      width: double.infinity,
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
            decoration: BoxDecoration(
              color: Warna.aksen,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA5F3FC), width: 2),
            ),
            child: Text(
              pengguna?.inisial ?? '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                      fontWeight: FontWeight.w700,
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
