import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../utils/validasi.dart';
import '../../widgets/app_logo.dart';
import 'register_screen.dart';

/// Halaman masuk untuk admin dan pelanggan.
///
/// Aplikasi tidak menyediakan pilihan role di sini: role ditentukan backend
/// dari akun yang tersimpan, lalu halaman yang tampil menyesuaikan sendiri.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _kunciForm = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _fokusPassword = FocusNode();

  bool _passwordTersembunyi = true;
  bool _sedangKirim = false;

  /// Pesan dari backend atau dari pemeriksaan sesi sebelumnya.
  String? _pesanGagal;

  /// Validasi baru dijalankan setelah pengguna menekan tombol masuk sekali,
  /// supaya tidak ada tulisan merah saat form masih kosong.
  AutovalidateMode _modeValidasi = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();

    // Misalnya sesi sebelumnya berakhir karena token kedaluwarsa.
    _pesanGagal = AuthService.instance.ambilPesanUntukLogin();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fokusPassword.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
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

    try {
      await AuthService.instance.masuk(
        email: _email.text,
        password: _password.text,
      );
      // Bila berhasil, halaman ini diganti sendiri oleh gerbang aplikasi
      // sesuai role akun. Tidak ada Navigator.push di sini.
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() => _pesanGagal = kesalahan.pesan);
    } catch (kesalahan) {
      if (!mounted) return;
      setState(() {
        _pesanGagal = 'Terjadi masalah yang tidak terduga. Coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _sedangKirim = false);
    }
  }

  void _bukaDaftar() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Jarak.xl,
              Jarak.xxl,
              Jarak.xl,
              Jarak.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Bagian brand: logo, nama, dan jenis produk. Ditaruh di
                  // luar kartu supaya halaman tetap terasa lapang di layar
                  // kecil.
                  const Center(child: AppLogo(ukuran: 72)),
                  const SizedBox(height: Jarak.lg),
                  const Center(
                    child: NamaAplikasi(
                      ukuranJudul: 26,
                      rataTengah: true,
                      tampilkanSlogan: false,
                    ),
                  ),
                  const SizedBox(height: Jarak.xs),
                  const Center(
                    child: Text(
                      NamaAplikasi.deskripsi,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Warna.teksKedua,
                      ),
                    ),
                  ),

                  const SizedBox(height: Jarak.xl),

                  Container(
                    padding: const EdgeInsets.all(Jarak.xl),
                    decoration: BoxDecoration(
                      color: Warna.permukaan,
                      borderRadius: BorderRadius.circular(Sudut.kartu),
                      border: Border.all(color: Warna.garis),
                      boxShadow: bayanganKartu,
                    ),
                    child: Form(
                      key: _kunciForm,
                      autovalidateMode: _modeValidasi,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Warna.teksUtama,
                            ),
                          ),
                          const SizedBox(height: Jarak.xs),
                          const Text(
                            'Gunakan email dan kata sandi akun RENOVA Anda.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Warna.teksKedua,
                              height: 1.5,
                            ),
                          ),

                          if (_pesanGagal != null) ...<Widget>[
                            const SizedBox(height: Jarak.lg),
                            _KotakPesan(pesan: _pesanGagal!),
                          ],

                          const SizedBox(height: Jarak.xl),

                          TextFormField(
                            controller: _email,
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
                            onFieldSubmitted: (_) =>
                                _fokusPassword.requestFocus(),
                          ),

                          const SizedBox(height: Jarak.lg),

                          TextFormField(
                            controller: _password,
                            focusNode: _fokusPassword,
                            enabled: !_sedangKirim,
                            obscureText: _passwordTersembunyi,
                            textInputAction: TextInputAction.done,
                            autofillHints: const <String>[
                              AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Kata sandi',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _passwordTersembunyi =
                                      !_passwordTersembunyi,
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
                            validator: Validasi.passwordMasuk,
                            onFieldSubmitted: (_) => _masuk(),
                          ),

                          const SizedBox(height: Jarak.xl),

                          FilledButton(
                            onPressed: _sedangKirim ? null : _masuk,
                            child: _sedangKirim
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Masuk'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: Jarak.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Belum punya akun?',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Warna.teksKedua,
                        ),
                      ),
                      TextButton(
                        onPressed: _sedangKirim ? null : _bukaDaftar,
                        child: const Text('Daftar di sini'),
                      ),
                    ],
                  ),

                  const SizedBox(height: Jarak.sm),

                  const Text(
                    NamaAplikasi.slogan,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Warna.teksSamar),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kotak pesan kegagalan pada form.
class _KotakPesan extends StatelessWidget {
  const _KotakPesan({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Jarak.md),
      decoration: BoxDecoration(
        color: Warna.bahayaMuda,
        borderRadius: BorderRadius.circular(Sudut.kolomIsian),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Warna.bahaya,
          ),
          const SizedBox(width: Jarak.sm),
          Expanded(
            child: Text(
              pesan,
              style: const TextStyle(
                fontSize: 13,
                color: Warna.bahaya,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
