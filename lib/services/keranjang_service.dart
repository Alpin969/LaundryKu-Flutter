import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/layanan.dart';

/// Satu layanan yang disiapkan pelanggan sebelum checkout.
class ItemKeranjang {
  ItemKeranjang({
    required this.id,
    required this.layanan,
    required this.beratPerkiraan,
    this.foto,
  });

  /// Penanda unik di dalam keranjang. Dipakai untuk mengubah dan menghapus
  /// item, supaya tidak bergantung pada posisinya di daftar.
  final int id;

  final Layanan layanan;
  double beratPerkiraan;

  /// Foto pakaian yang dipilih pelanggan, diunggah setelah pesanannya dibuat.
  XFile? foto;

  /// Perkiraan biaya item ini, dihitung dari harga layanan.
  ///
  /// Angka ini hanya bantuan sebelum pesanan dibuat. Total yang benar-benar
  /// berlaku dihitung backend setelah admin mengisi berat asli.
  double get perkiraanBiaya => beratPerkiraan * layanan.hargaPerKg;
}

/// Keranjang pesanan pelanggan.
///
/// Isinya disimpan di memori saja, jadi keranjang kembali kosong saat aplikasi
/// ditutup. Yang ditampung di sini baru pilihan pelanggan (layanan, berat
/// perkiraan, foto); pesanannya sendiri baru dibuat di backend ketika
/// pelanggan menekan "Pesan & Bayar".
class KeranjangService extends ChangeNotifier {
  KeranjangService._();

  static final KeranjangService instance = KeranjangService._();

  final List<ItemKeranjang> _item = <ItemKeranjang>[];
  int _idBerikutnya = 1;

  List<ItemKeranjang> get item => List<ItemKeranjang>.unmodifiable(_item);

  bool get kosong => _item.isEmpty;

  int get jumlah => _item.length;

  /// Jumlah perkiraan biaya seluruh item.
  double get perkiraanTotal => _item.fold(
    0.0,
    (double jumlah, ItemKeranjang item) => jumlah + item.perkiraanBiaya,
  );

  /// Menambahkan satu layanan beserta berat perkiraannya.
  ///
  /// Layanan yang sama boleh masuk beberapa kali: pelanggan bisa saja mencuci
  /// dua jenis pakaian berbeda memakai layanan yang sama.
  void tambah({
    required Layanan layanan,
    required double beratPerkiraan,
    XFile? foto,
  }) {
    _item.add(
      ItemKeranjang(
        id: _idBerikutnya,
        layanan: layanan,
        beratPerkiraan: beratPerkiraan,
        foto: foto,
      ),
    );
    _idBerikutnya++;

    notifyListeners();
  }

  void ubahBerat(int id, double beratPerkiraan) {
    final ItemKeranjang? item = _cari(id);
    if (item == null) return;

    item.beratPerkiraan = beratPerkiraan;
    notifyListeners();
  }

  void ubahFoto(int id, XFile? foto) {
    final ItemKeranjang? item = _cari(id);
    if (item == null) return;

    item.foto = foto;
    notifyListeners();
  }

  void hapus(int id) {
    final int jumlahSebelum = _item.length;
    _item.removeWhere((ItemKeranjang item) => item.id == id);

    if (_item.length != jumlahSebelum) notifyListeners();
  }

  void kosongkan() {
    if (_item.isEmpty) return;

    _item.clear();
    notifyListeners();
  }

  ItemKeranjang? _cari(int id) {
    for (final ItemKeranjang item in _item) {
      if (item.id == id) return item;
    }
    return null;
  }
}
