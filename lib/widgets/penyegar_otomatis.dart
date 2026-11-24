import 'dart:async';

import 'package:flutter/material.dart';

/// Menyegarkan isi layar secara berkala, tanpa tombol muat ulang.
///
/// [muatUlang] dipanggil saat layar baru aktif, lalu setiap [jeda] selama
/// layar tetap aktif, dan sekali setiap aplikasi kembali ke depan. Selama
/// penyegaran sebelumnya belum selesai, jadwal berikutnya dilewati supaya
/// permintaan tidak menumpuk di jaringan yang lambat.
///
/// Pemanggil sebaiknya memakai penyegaran bertanda senyap, supaya penanda
/// memuat tidak muncul dan data lama tetap tampil sampai data baru siap.
///
/// Layar yang tidak sedang dilihat (mis. tab tersembunyi di dalam IndexedStack)
/// tidak disegarkan: [aktif] diisi false oleh kerangka navigasi.
class PenyegarOtomatis extends StatefulWidget {
  const PenyegarOtomatis({
    super.key,
    required this.muatUlang,
    required this.child,
    this.aktif = true,
    this.jeda = const Duration(seconds: 30),
  });

  final Future<void> Function() muatUlang;
  final Widget child;
  final bool aktif;
  final Duration jeda;

  @override
  State<PenyegarOtomatis> createState() => _PenyegarOtomatisState();
}

class _PenyegarOtomatisState extends State<PenyegarOtomatis>
    with WidgetsBindingObserver {
  Timer? _pewaktu;
  bool _sedangJalan = false;
  bool _aplikasiDiDepan = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _aturPewaktu();
  }

  @override
  void didUpdateWidget(PenyegarOtomatis lama) {
    super.didUpdateWidget(lama);

    // Tab yang baru dibuka langsung menampilkan data terbaru, tidak menunggu
    // jeda berikutnya.
    if (widget.aktif && !lama.aktif) {
      unawaited(_segarkan());
    }

    if (widget.aktif != lama.aktif || widget.jeda != lama.jeda) {
      _aturPewaktu();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState status) {
    final bool diDepan = status == AppLifecycleState.resumed;
    if (diDepan == _aplikasiDiDepan) return;

    _aplikasiDiDepan = diDepan;
    if (diDepan) unawaited(_segarkan());
  }

  @override
  void dispose() {
    _pewaktu?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _aturPewaktu() {
    _pewaktu?.cancel();
    if (!widget.aktif) return;

    _pewaktu = Timer.periodic(widget.jeda, (_) => unawaited(_segarkan()));
  }

  Future<void> _segarkan() async {
    if (_sedangJalan || !_aplikasiDiDepan || !mounted) return;

    // Halaman yang sedang tertutup halaman lain tidak perlu disegarkan: yang
    // dilihat pengguna bukan halaman ini.
    final ModalRoute<dynamic>? rute = ModalRoute.of(context);
    if (rute != null && !rute.isCurrent) return;

    _sedangJalan = true;
    try {
      await widget.muatUlang();
    } catch (_) {
      // Kegagalan penyegaran latar tidak perlu menggangu pengguna: layar yang
      // bersangkutan sudah punya penandanya sendiri (TampilanGagal), dan
      // penyegaran berikutnya masih akan berjalan.
    } finally {
      _sedangJalan = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
