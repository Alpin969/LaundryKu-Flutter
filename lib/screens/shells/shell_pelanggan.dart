import 'package:flutter/material.dart';

import '../../models/status_pesanan.dart';
import '../../services/auth_service.dart';
import '../../widgets/penyegar_otomatis.dart';
import '../admin/dashboard_admin_screen.dart';
import '../admin/kelola_layanan_screen.dart';
import '../customer/beranda_screen.dart';
import '../customer/daftar_layanan_screen.dart';
import '../customer/daftar_pesanan_screen.dart';
import '../customer/profil_screen.dart';
import '../customer/riwayat_screen.dart';

/// Satu tujuan di navigasi bawah.
class TujuanNavigasi {
  const TujuanNavigasi({
    required this.label,
    required this.ikon,
    required this.ikonTerpilih,
  });

  final String label;
  final IconData ikon;
  final IconData ikonTerpilih;
}

/// Kerangka halaman pelanggan.
///
/// Empat tujuan sesuai rancangan: Beranda, Pesanan, Riwayat, dan Profil.
/// Tab Pesanan menampilkan daftar layanan dari backend sebagai pintu masuk
/// pemesanan, bukan tabel pesanan: pada aplikasi ponsel pelanggan, membuka
/// pesanan hampir selalu berarti "saya mau pesan layanan yang mana". Pesanan
/// yang sudah dibuat tetap dijangkau dari beranda dan tab Riwayat.
///
/// Isi tiap tujuan disimpan dalam IndexedStack supaya posisi gulir dan data
/// yang sudah dimuat tidak hilang saat berpindah tab.
///
/// Isi tab disegarkan sendiri oleh [PenyegarOtomatis], bukan oleh tombol muat
/// ulang: tab yang sedang dilihat menyegarkan dirinya setiap beberapa detik,
/// dan tab yang baru dibuka langsung menyegarkan diri sekali.
class ShellPelanggan extends StatefulWidget {
  const ShellPelanggan({super.key});

  @override
  State<ShellPelanggan> createState() => ShellPelangganState();
}

class ShellPelangganState extends State<ShellPelanggan> {
  int _indeks = 0;

  // Kunci dipakai untuk meminta tab memuat ulang datanya dari penyegar
  // otomatis, dan untuk membuka tab tertentu dari luar kerangka.
  final GlobalKey<BerandaScreenState> _kunciBeranda =
      GlobalKey<BerandaScreenState>();
  final GlobalKey<DaftarPesananScreenState> _kunciPesanan =
      GlobalKey<DaftarPesananScreenState>();
  final GlobalKey<RiwayatScreenState> _kunciRiwayat =
      GlobalKey<RiwayatScreenState>();
  final GlobalKey<ProfilScreenState> _kunciProfil =
      GlobalKey<ProfilScreenState>();

  static const List<TujuanNavigasi> _tujuan = <TujuanNavigasi>[
    TujuanNavigasi(
      label: 'Beranda',
      ikon: Icons.home_outlined,
      ikonTerpilih: Icons.home_rounded,
    ),
    TujuanNavigasi(
      label: 'Pesanan',
      ikon: Icons.local_laundry_service_outlined,
      ikonTerpilih: Icons.local_laundry_service_rounded,
    ),
    TujuanNavigasi(
      label: 'Riwayat',
      ikon: Icons.history_outlined,
      ikonTerpilih: Icons.history_rounded,
    ),
    TujuanNavigasi(
      label: 'Profil',
      ikon: Icons.person_outline_rounded,
      ikonTerpilih: Icons.person_rounded,
    ),
  ];

  /// Membuka tab tertentu dari luar kerangka, mis. dari tombol di beranda.
  void pindahKe(int indeks) => setState(() => _indeks = indeks);

  Future<void> _segarkanBeranda() async {
    await _kunciBeranda.currentState?.muatUlang(senyap: true);
  }

  Future<void> _segarkanPesanan() async {
    await _kunciPesanan.currentState?.muatUlang(senyap: true);
  }

  Future<void> _segarkanRiwayat() async {
    await _kunciRiwayat.currentState?.muatUlang(senyap: true);
  }

  Future<void> _segarkanProfil() async {
    await _kunciProfil.currentState?.muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    final String nama = AuthService.instance.pengguna?.nama ?? '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            // Isi dibatasi lebarnya supaya tetap enak dibaca di tablet dan web,
            // bukan melar dari tepi ke tepi.
            constraints: const BoxConstraints(maxWidth: 760),
            child: IndexedStack(
              index: _indeks,
              children: <Widget>[
                PenyegarOtomatis(
                  aktif: _indeks == 0,
                  muatUlang: _segarkanBeranda,
                  child: BerandaScreen(key: _kunciBeranda, namaPengguna: nama),
                ),
                PenyegarOtomatis(
                  aktif: _indeks == 1,
                  muatUlang: _segarkanPesanan,
                  child: DaftarLayananScreen(
                    key: _kunciPesanan,
                    memilihLayanan: true,
                    tanpaScaffold: true,
                  ),
                ),
                PenyegarOtomatis(
                  aktif: _indeks == 2,
                  muatUlang: _segarkanRiwayat,
                  child: RiwayatScreen(key: _kunciRiwayat),
                ),
                PenyegarOtomatis(
                  aktif: _indeks == 3,
                  muatUlang: _segarkanProfil,
                  child: ProfilScreen(key: _kunciProfil),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeks,
        onDestinationSelected: pindahKe,
        destinations: <Widget>[
          for (final TujuanNavigasi tujuan in _tujuan)
            NavigationDestination(
              icon: Icon(tujuan.ikon),
              selectedIcon: Icon(tujuan.ikonTerpilih),
              label: tujuan.label,
            ),
        ],
      ),
    );
  }
}

/// Kerangka halaman admin.
///
/// Navigasinya sengaja berbeda dari pelanggan: tab pertama adalah dashboard
/// berisi ringkasan seluruh pesanan, dan ada tab Layanan untuk mengelola
/// daftar layanan. Admin juga bisa melihat riwayat seluruh pesanan.
///
/// Seperti pada sisi pelanggan, isi tab disegarkan sendiri oleh
/// [PenyegarOtomatis] tanpa tombol muat ulang.
class ShellAdmin extends StatefulWidget {
  const ShellAdmin({super.key});

  @override
  State<ShellAdmin> createState() => ShellAdminState();
}

class ShellAdminState extends State<ShellAdmin> {
  int _indeks = 0;

  final GlobalKey<DashboardAdminScreenState> _kunciDashboard =
      GlobalKey<DashboardAdminScreenState>();
  final GlobalKey<DaftarPesananScreenState> _kunciPesanan =
      GlobalKey<DaftarPesananScreenState>();
  final GlobalKey<KelolaLayananScreenState> _kunciLayanan =
      GlobalKey<KelolaLayananScreenState>();
  final GlobalKey<RiwayatScreenState> _kunciRiwayat =
      GlobalKey<RiwayatScreenState>();
  final GlobalKey<ProfilScreenState> _kunciProfil =
      GlobalKey<ProfilScreenState>();

  static const List<TujuanNavigasi> _tujuan = <TujuanNavigasi>[
    TujuanNavigasi(
      label: 'Dashboard',
      ikon: Icons.dashboard_outlined,
      ikonTerpilih: Icons.dashboard_rounded,
    ),
    TujuanNavigasi(
      label: 'Pesanan',
      ikon: Icons.receipt_long_outlined,
      ikonTerpilih: Icons.receipt_long_rounded,
    ),
    TujuanNavigasi(
      label: 'Layanan',
      ikon: Icons.local_laundry_service_outlined,
      ikonTerpilih: Icons.local_laundry_service_rounded,
    ),
    TujuanNavigasi(
      label: 'Riwayat',
      ikon: Icons.history_outlined,
      ikonTerpilih: Icons.history_rounded,
    ),
    TujuanNavigasi(
      label: 'Profil',
      ikon: Icons.person_outline_rounded,
      ikonTerpilih: Icons.person_rounded,
    ),
  ];

  /// Pindah ke tab Pesanan sekaligus menerapkan penyaring, dipakai ketika
  /// admin menekan salah satu kotak status di dashboard.
  void bukaPesananTersaring(StatusPesanan? status) {
    setState(() => _indeks = 1);
    _kunciPesanan.currentState?.terapkanSaring(status);
  }

  void pindahKe(int indeks) => setState(() => _indeks = indeks);

  Future<void> _segarkanDashboard() async {
    await _kunciDashboard.currentState?.muatUlang(senyap: true);
  }

  Future<void> _segarkanPesanan() async {
    await _kunciPesanan.currentState?.muatUlang(senyap: true);
  }

  Future<void> _segarkanLayanan() async {
    await _kunciLayanan.currentState?.muatUlang(senyap: true);
  }

  Future<void> _segarkanRiwayat() async {
    await _kunciRiwayat.currentState?.muatUlang(senyap: true);
  }

  Future<void> _segarkanProfil() async {
    await _kunciProfil.currentState?.muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    final String nama = AuthService.instance.pengguna?.nama ?? '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: IndexedStack(
              index: _indeks,
              children: <Widget>[
                PenyegarOtomatis(
                  aktif: _indeks == 0,
                  muatUlang: _segarkanDashboard,
                  child: DashboardAdminScreen(
                    key: _kunciDashboard,
                    namaPengguna: nama,
                    onBukaSemuaPesanan: bukaPesananTersaring,
                  ),
                ),
                PenyegarOtomatis(
                  aktif: _indeks == 1,
                  muatUlang: _segarkanPesanan,
                  child: DaftarPesananScreen(
                    key: _kunciPesanan,
                    tampilkanPelanggan: true,
                  ),
                ),
                PenyegarOtomatis(
                  aktif: _indeks == 2,
                  muatUlang: _segarkanLayanan,
                  child: KelolaLayananScreen(key: _kunciLayanan),
                ),
                PenyegarOtomatis(
                  aktif: _indeks == 3,
                  muatUlang: _segarkanRiwayat,
                  child: RiwayatScreen(
                    key: _kunciRiwayat,
                    tampilkanPelanggan: true,
                  ),
                ),
                PenyegarOtomatis(
                  aktif: _indeks == 4,
                  muatUlang: _segarkanProfil,
                  child: ProfilScreen(key: _kunciProfil),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeks,
        onDestinationSelected: pindahKe,
        destinations: <Widget>[
          for (final TujuanNavigasi tujuan in _tujuan)
            NavigationDestination(
              icon: Icon(tujuan.ikon),
              selectedIcon: Icon(tujuan.ikonTerpilih),
              label: tujuan.label,
            ),
        ],
      ),
    );
  }
}
