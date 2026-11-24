import 'package:intl/intl.dart';

/// Pembantu format angka dan tanggal untuk seluruh aplikasi.
///
/// Nilai uang dan berat dari backend datang sebagai teks (kolom NUMERIC di
/// PostgreSQL dikirim driver `pg` sebagai string, mis. "7500.00"), sehingga
/// perlu diubah dulu menjadi angka sebelum ditampilkan.

/// Mengubah nilai apa pun dari JSON menjadi double.
///
/// Diterima angka maupun teks karena kedua bentuk itu benar-benar muncul di
/// response backend: INTEGER datang sebagai angka, NUMERIC sebagai teks.
double? angkaDariJson(Object? nilai) {
  if (nilai == null) return null;
  if (nilai is num) return nilai.toDouble();
  return double.tryParse(nilai.toString());
}

/// Sama seperti [angkaDariJson], tetapi untuk kolom INTEGER.
int? bulatDariJson(Object? nilai) {
  if (nilai == null) return null;
  if (nilai is int) return nilai;
  if (nilai is num) return nilai.toInt();
  return int.tryParse(nilai.toString());
}

final NumberFormat _formatRupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final NumberFormat _formatBerat = NumberFormat('#,##0.##', 'id_ID');

final DateFormat _formatTanggalLengkap = DateFormat(
  'd MMMM yyyy, HH:mm',
  'id_ID',
);

final DateFormat _formatTanggalSingkat = DateFormat('d MMM yyyy', 'id_ID');

final DateFormat _formatBulan = DateFormat('MMMM yyyy', 'id_ID');

/// Contoh: 7500 -> "Rp 7.500".
String formatRupiah(double? nilai) {
  if (nilai == null) return '-';
  return _formatRupiah.format(nilai);
}

/// Contoh: 3.5 -> "3,5 kg".
String formatBerat(double? nilai) {
  if (nilai == null) return '-';
  return '${_formatBerat.format(nilai)} kg';
}

/// Contoh: 16 Nov 2026, 18:30 (waktu perangkat pengguna).
String formatTanggalLengkap(DateTime? waktu) {
  if (waktu == null) return '-';
  return _formatTanggalLengkap.format(waktu.toLocal());
}

/// Contoh: 16 Nov 2026.
String formatTanggalSingkat(DateTime? waktu) {
  if (waktu == null) return '-';
  return _formatTanggalSingkat.format(waktu.toLocal());
}

/// Contoh: November 2026. Dipakai sebagai judul kelompok di riwayat pesanan.
String formatBulan(DateTime waktu) {
  return _formatBulan.format(waktu.toLocal());
}

/// Lama waktu berjalan, mis. "3 jam lalu" atau "2 hari lalu".
String formatWaktuLalu(DateTime? waktu) {
  if (waktu == null) return '-';

  final Duration selisih = DateTime.now().difference(waktu.toLocal());

  if (selisih.inMinutes < 1) return 'Baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
  if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
  if (selisih.inDays < 30) return '${selisih.inDays} hari lalu';

  return formatTanggalSingkat(waktu);
}
