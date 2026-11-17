/// Metode pembayaran pesanan.
///
/// Kodenya sama dengan kolom `payment_method` di tabel orders. Tunai berbeda
/// dari yang lain: pesanannya belum lunas sampai admin mengonfirmasi uangnya
/// diterima.
enum MetodePembayaran {
  tunai(
    kode: 'CASH',
    label: 'Tunai',
    keterangan: 'Dikonfirmasi admin saat pakaian diambil.',
  ),
  qris(
    kode: 'QRIS',
    label: 'QRIS',
    keterangan: 'Langsung ditandai lunas.',
  ),
  transferBank(
    kode: 'BANK_TRANSFER',
    label: 'Transfer bank',
    keterangan: 'Langsung ditandai lunas.',
  ),
  dompetDigital(
    kode: 'EWALLET',
    label: 'E-money',
    keterangan: 'Langsung ditandai lunas.',
  );

  const MetodePembayaran({
    required this.kode,
    required this.label,
    required this.keterangan,
  });

  /// Nilai yang dipakai backend.
  final String kode;

  /// Sebutan yang ditampilkan ke pengguna.
  final String label;

  /// Apa yang terjadi pada pembayaran setelah pesanan dibuat.
  final String keterangan;

  /// Tunai baru lunas setelah admin mengonfirmasi uangnya diterima.
  bool get perluKonfirmasiAdmin => this == MetodePembayaran.tunai;

  /// Mengembalikan null untuk metode yang tidak dikenali, termasuk pesanan
  /// lama yang belum mencatat metode pembayarannya.
  static MetodePembayaran? dariKode(String? kode) {
    final String dicari = (kode ?? '').trim().toUpperCase();
    if (dicari.isEmpty) return null;

    for (final MetodePembayaran metode in values) {
      if (metode.kode == dicari) return metode;
    }

    return null;
  }
}

/// Status pembayaran pesanan, sesuai kolom `payment_status` di tabel orders.
enum StatusPembayaran {
  belumDibayar(kode: 'UNPAID', label: 'Belum dibayar'),
  lunas(kode: 'PAID', label: 'Lunas');

  const StatusPembayaran({required this.kode, required this.label});

  final String kode;
  final String label;

  /// Null untuk pesanan yang belum mencatat pembayaran sama sekali.
  static StatusPembayaran? dariKode(String? kode) {
    final String dicari = (kode ?? '').trim().toUpperCase();
    if (dicari.isEmpty) return null;

    for (final StatusPembayaran status in values) {
      if (status.kode == dicari) return status;
    }

    return null;
  }
}
