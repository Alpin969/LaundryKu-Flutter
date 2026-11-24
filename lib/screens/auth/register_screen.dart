import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../utils/validasi.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/pesan_ui.dart';

/// Pendaftaran akun pelanggan baru.
///
/// Form ini tidak punya pilihan role: setiap akun baru dari aplikasi selalu
/// berperan pelanggan. Akun admin hanya dibuat oleh pengelola laundry.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _kunciForm = GlobalKey<FormState>();
  final TextEditingController _nama = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _konfirmasi = TextEditingController();

  final FocusNode _fokusEmail = FocusNode();
  final FocusNode _fokusPassword = FocusNode();
  final FocusNode _fokusKonfirmasi = FocusNode();

  bool _passwordTersembunyi = true;
  bool _konfirmasiTersembunyi = true;
  bool _sedangKirim = false;
  String? _pesanGagal;

  AutovalidateMode _modeValidasi = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _password.dispose();
    _konfirmasi.dispose();
    _fokusEmail.dispose();
    _fokusPassword.dispose();
    _fokusKonfirmasi.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    FocusScope.of(context).unfocus();

    if (!(_kunciForm.currentState?.validate() ?? false)) {
      setState(() => _modeValidasi = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() {
      _sedangKirim = true;
      _pesanGagal = null;
      _modeValidasi = AutovalidateMode.onUserInteraction;
    });

    // Navigator dan ScaffoldMessenger ditangkap lebih dulu: halaman ini ikut
    // ditutup begitu pendaftaran berhasil, sehingga context miliknya sudah
    // tidak berlaku lagi saat pesan keberhasilan ditampilkan.
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await AuthService.instance.daftar(
        nama: _nama.text,
        email: _email.text,
        password: _password.text,
      );

      // Pendaftaran langsung memberi sesi yang sah, jadi halaman ini harus
      // ditutup supaya pengguna benar-benar melihat beranda pelanggan.
      //
      // popUntil dipakai, bukan pop: halaman ini dibuka lewat Navigator.push
      // di atas halaman login, sedangkan beranda berada pada rute pertama.
      // Tanpa popUntil, formulir pendaftaran tetap menutupi beranda dan
      // pengguna merasa pendaftarannya tidak berhasil.
      navigator.popUntil((Route<dynamic> rute) => rute.isFirst);

      tampilkanPesanLewat(
        messenger,
        'Pendaftaran berhasil. Selamat datang di RENOVA.',
        jenis: JenisPesan.sukses,
      );
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() => _pesanGagal = kesalahan.pesan);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pesanGagal = 'Terjadi masalah yang tidak terduga. Coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _sedangKirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        leading: IconButton(
          onPressed: _sedangKirim ? null : () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Jarak.xl,
              Jarak.sm,
              Jarak.xl,
              Jarak.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _kunciForm,
                autovalidateMode: _modeValidasi,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Center(child: AppLogo(ukuran: 56)),
                    const SizedBox(height: Jarak.md),
                    const Center(
                      child: NamaAplikasi(
                        ukuranJudul: 21,
                        rataTengah: true,
                        tampilkanSlogan: false,
                      ),
                    ),
                    const SizedBox(height: Jarak.xl),

                    const Text(
                      'Buat akun pelanggan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Warna.teksUtama,
                      ),
                    ),
                    const SizedBox(height: Jarak.xs),
                    const Text(
                      'Setelah mendaftar Anda bisa langsung memesan layanan '
                      'laundry dan memantau statusnya.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Warna.teksKedua,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: Jarak.lg),
                    _Catatan(
                      ikon: Icons.info_outline_rounded,
                      teks:
                          'Pendaftaran ini untuk akun pelanggan. Akun petugas '
                          'laundry diberikan oleh pengelola.',
                    ),

                    if (_pesanGagal != null) ...<Widget>[
                      const SizedBox(height: Jarak.lg),
                      _Catatan(
                        ikon: Icons.error_outline_rounded,
                        teks: _pesanGagal!,
                        berbahaya: true,
                      ),
                    ],

                    const SizedBox(height: Jarak.xl),

                    TextFormField(
                      controller: _nama,
                      enabled: !_sedangKirim,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        hintText: 'Nama sesuai identitas Anda',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: Validasi.namaLengkap,
                      onFieldSubmitted: (_) => _fokusEmail.requestFocus(),
                    ),

                    const SizedBox(height: Jarak.lg),

                    TextFormField(
                      controller: _email,
                      focusNode: _fokusEmail,
                      enabled: !_sedangKirim,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'nama@email.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: Validasi.email,
                      onFieldSubmitted: (_) => _fokusPassword.requestFocus(),
                    ),

                    const SizedBox(height: Jarak.lg),

                    TextFormField(
                      controller: _password,
                      focusNode: _fokusPassword,
                      enabled: !_sedangKirim,
                      obscureText: _passwordTersembunyi,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi',
                        helperText:
                            'Minimal ${Validasi.panjangPasswordMin} karakter.',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _passwordTersembunyi = !_passwordTersembunyi,
                          ),
                          tooltip: _passwordTersembunyi
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          icon: Icon(
                            _passwordTersembunyi
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: Validasi.password,
                      onFieldSubmitted: (_) => _fokusKonfirmasi.requestFocus(),
                    ),

                    const SizedBox(height: Jarak.lg),

                    TextFormField(
                      controller: _konfirmasi,
                      focusNode: _fokusKonfirmasi,
                      enabled: !_sedangKirim,
                      obscureText: _konfirmasiTersembunyi,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi kata sandi',
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _konfirmasiTersembunyi =
                                !_konfirmasiTersembunyi,
                          ),
                          tooltip: _konfirmasiTersembunyi
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          icon: Icon(
                            _konfirmasiTersembunyi
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (String? nilai) =>
                          Validasi.konfirmasiPassword(nilai, _password.text),
                      onFieldSubmitted: (_) => _daftar(),
                    ),

                    const SizedBox(height: Jarak.xl),

                    FilledButton(
                      onPressed: _sedangKirim ? null : _daftar,
                      child: _sedangKirim
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Daftar'),
                    ),

                    const SizedBox(height: Jarak.lg),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Sudah punya akun?',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Warna.teksKedua,
                          ),
                        ),
                        TextButton(
                          onPressed: _sedangKirim
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Masuk di sini'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kotak keterangan kecil dengan ikon, dipakai untuk info maupun kegagalan.
class _Catatan extends StatelessWidget {
  const _Catatan({
    required this.ikon,
    required this.teks,
    this.berbahaya = false,
  });

  final IconData ikon;
  final String teks;
  final bool berbahaya;

  @override
  Widget build(BuildContext context) {
    final Color warna = berbahaya ? Warna.bahaya : Warna.primaryGelap;

    return Container(
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: berbahaya ? Warna.bahayaMuda : Warna.aksenLembut,
        borderRadius: BorderRadius.circular(Sudut.kolomIsian),
        border: Border.all(
          color: berbahaya ? const Color(0xFFFECACA) : const Color(0xFFA5F3FC),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(ikon, size: 17, color: warna),
          const SizedBox(width: Jarak.sm),
          Expanded(
            child: Text(
              teks,
              style: TextStyle(fontSize: 12.5, color: warna, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
