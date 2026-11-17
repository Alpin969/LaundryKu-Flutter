import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../utils/validasi.dart';

/// Form ubah data akun: nama, dan bila diinginkan sekaligus kata sandi.
///
/// Dipakai pelanggan maupun admin. Penggantian kata sandi selalu meminta kata
/// sandi lama, sehingga perangkat yang tertinggal dalam keadaan sudah masuk
/// tidak cukup untuk mengunci pemilik akun dari luar.
class UbahProfilScreen extends StatefulWidget {
  const UbahProfilScreen({super.key});

  @override
  State<UbahProfilScreen> createState() => _UbahProfilScreenState();
}

class _UbahProfilScreenState extends State<UbahProfilScreen> {
  final GlobalKey<FormState> _kunciForm = GlobalKey<FormState>();

  late final TextEditingController _nama;
  final TextEditingController _sandiLama = TextEditingController();
  final TextEditingController _sandiBaru = TextEditingController();
  final TextEditingController _konfirmasi = TextEditingController();

  final FocusNode _fokusSandiLama = FocusNode();
  final FocusNode _fokusSandiBaru = FocusNode();
  final FocusNode _fokusKonfirmasi = FocusNode();

  bool _gantiSandi = false;
  bool _sandiTersembunyi = true;
  bool _sedangKirim = false;
  String? _pesanGagal;

  AutovalidateMode _modeValidasi = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(
      text: AuthService.instance.pengguna?.nama ?? '',
    );
  }

  @override
  void dispose() {
    _nama.dispose();
    _sandiLama.dispose();
    _sandiBaru.dispose();
    _konfirmasi.dispose();
    _fokusSandiLama.dispose();
    _fokusSandiBaru.dispose();
    _fokusKonfirmasi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();

    if (!(_kunciForm.currentState?.validate() ?? false)) {
      setState(() => _modeValidasi = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() {
      _sedangKirim = true;
      _pesanGagal = null;
    });

    try {
      await AuthService.instance.ubahProfil(
        nama: _nama.text,
        sandiLama: _gantiSandi ? _sandiLama.text : null,
        sandiBaru: _gantiSandi ? _sandiBaru.text : null,
      );

      if (!mounted) return;

      // true memberi tahu halaman profil bahwa data akun sudah berubah.
      Navigator.of(context).pop(true);
    } on ApiException catch (kesalahan) {
      if (!mounted) return;
      setState(() {
        _pesanGagal = kesalahan.pesan;
        _sedangKirim = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pesanGagal = 'Perubahan gagal disimpan. Coba lagi.';
        _sedangKirim = false;
      });
    }
  }

  /// Kata sandi lama hanya wajib bila pengguna memang mengganti kata sandi.
  String? _validasiSandiLama(String? nilai) {
    if (!_gantiSandi) return null;
    if ((nilai ?? '').isEmpty) return 'Kata sandi saat ini wajib diisi.';
    return null;
  }

  String? _validasiSandiBaru(String? nilai) {
    if (!_gantiSandi) return null;
    return Validasi.password(nilai);
  }

  String? _validasiKonfirmasi(String? nilai) {
    if (!_gantiSandi) return null;
    return Validasi.konfirmasiPassword(nilai, _sandiBaru.text);
  }

  @override
  Widget build(BuildContext context) {
    final String? email = AuthService.instance.pengguna?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Profil')),
      body: Form(
        key: _kunciForm,
        autovalidateMode: _modeValidasi,
        child: ListView(
          padding: const EdgeInsets.all(Jarak.xl),
          children: <Widget>[
            const Text(
              'Ubah data akun',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Warna.teksUtama,
              ),
            ),
            const SizedBox(height: Jarak.xs),
            const Text(
              'Perubahan nama langsung berlaku pada pesanan berikutnya.',
              style: TextStyle(
                fontSize: 13.5,
                color: Warna.teksKedua,
                height: 1.55,
              ),
            ),

            if (_pesanGagal != null) ...<Widget>[
              const SizedBox(height: Jarak.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Jarak.md),
                decoration: BoxDecoration(
                  color: Warna.bahayaMuda,
                  borderRadius: BorderRadius.circular(Sudut.kolomIsian),
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
                        _pesanGagal!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Warna.bahaya,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
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
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: Validasi.namaLengkap,
            ),

            const SizedBox(height: Jarak.lg),

            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              child: Text(
                email == null || email.isEmpty ? '-' : email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Warna.teksKedua,
                ),
              ),
            ),

            const SizedBox(height: Jarak.sm),
            const Text(
              'Email tidak bisa diubah sendiri karena dipakai untuk masuk. '
              'Hubungi petugas laundry bila perlu diganti.',
              style: TextStyle(
                fontSize: 12,
                color: Warna.teksSamar,
                height: 1.5,
              ),
            ),

            const SizedBox(height: Jarak.lg),

            SwitchListTile(
              value: _gantiSandi,
              onChanged: _sedangKirim
                  ? null
                  : (bool nilai) => setState(() {
                      _gantiSandi = nilai;
                      if (!nilai) {
                        _sandiLama.clear();
                        _sandiBaru.clear();
                        _konfirmasi.clear();
                      }
                    }),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Ganti kata sandi',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Warna.teksUtama,
                ),
              ),
              subtitle: const Text(
                'Nyalakan bila ingin mengganti kata sandi akun Anda.',
                style: TextStyle(fontSize: 12.5, color: Warna.teksKedua),
              ),
            ),

            if (_gantiSandi) ...<Widget>[
              const SizedBox(height: Jarak.lg),

              TextFormField(
                controller: _sandiLama,
                focusNode: _fokusSandiLama,
                enabled: !_sedangKirim,
                obscureText: _sandiTersembunyi,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi saat ini',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: _validasiSandiLama,
                onFieldSubmitted: (_) => _fokusSandiBaru.requestFocus(),
              ),

              const SizedBox(height: Jarak.lg),

              TextFormField(
                controller: _sandiBaru,
                focusNode: _fokusSandiBaru,
                enabled: !_sedangKirim,
                obscureText: _sandiTersembunyi,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Kata sandi baru',
                  helperText:
                      'Minimal ${Validasi.panjangPasswordMin} karakter.',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _sandiTersembunyi = !_sandiTersembunyi,
                    ),
                    tooltip: _sandiTersembunyi
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    icon: Icon(
                      _sandiTersembunyi
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validasiSandiBaru,
                onFieldSubmitted: (_) => _fokusKonfirmasi.requestFocus(),
              ),

              const SizedBox(height: Jarak.lg),

              TextFormField(
                controller: _konfirmasi,
                focusNode: _fokusKonfirmasi,
                enabled: !_sedangKirim,
                obscureText: _sandiTersembunyi,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Ulangi kata sandi baru',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
                validator: _validasiKonfirmasi,
                onFieldSubmitted: (_) => _simpan(),
              ),
            ],

            const SizedBox(height: Jarak.xxl),

            FilledButton.icon(
              onPressed: _sedangKirim ? null : _simpan,
              icon: _sedangKirim
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(_sedangKirim ? 'Menyimpan...' : 'Simpan Perubahan'),
            ),

            const SizedBox(height: Jarak.md),

            OutlinedButton(
              onPressed: _sedangKirim
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),

            const SizedBox(height: Jarak.lg),
          ],
        ),
      ),
    );
  }
}
