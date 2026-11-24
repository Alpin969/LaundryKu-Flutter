import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/metode_pembayaran.dart';
import '../models/pesanan.dart';
import '../utils/format.dart';
import 'lencana_status.dart';

/// Kartu satu pesanan pada daftar pesanan.
///
/// Menampilkan foto pakaian bila ada, supaya pelanggan dan admin langsung
/// mengenali pesanannya tanpa harus membuka detail.
class KartuPesanan extends StatelessWidget {
  const KartuPesanan({
    super.key,
    required this.pesanan,
    required this.onTap,
    this.tampilkanPelanggan = false,
  });

  final Pesanan pesanan;
  final VoidCallback onTap;

  /// Admin perlu tahu pesanan ini milik siapa; pelanggan tidak.
  final bool tampilkanPelanggan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sudut.kartu),
        child: Padding(
          padding: const EdgeInsets.all(Jarak.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _FotoKecil(alamatFoto: pesanan.alamatFoto),
                  const SizedBox(width: Jarak.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Lencana status bisa lebih lebar daripada sisa ruang
                        // di layar sempit (mis. "Menunggu Konfirmasi"), jadi
                        // susunannya memakai Wrap: bila keduanya tidak muat
                        // bersebelahan, lencana turun ke baris berikutnya
                        // alih-alih terpotong.
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: Jarak.sm,
                          runSpacing: Jarak.xs,
                          children: <Widget>[
                            Text(
                              '#${pesanan.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Warna.teksSamar,
                                letterSpacing: 0.3,
                              ),
                            ),
                            LencanaStatus(
                              status: pesanan.status,
                              ringkas: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: Jarak.xs),
                        Text(
                          pesanan.namaLayanan,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Warna.teksUtama,
                            height: 1.35,
                          ),
                        ),
                        if (tampilkanPelanggan) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            pesanan.namaPelanggan,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Warna.teksKedua,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Jarak.md),
              Container(
                padding: const EdgeInsets.all(Jarak.md),
                decoration: BoxDecoration(
                  color: Warna.latar,
                  borderRadius: BorderRadius.circular(Sudut.kolomIsian),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _InfoKecil(
                        label: 'Berat',
                        nilai: pesanan.beratAktual == null
                            ? '${formatBerat(pesanan.beratPerkiraan)} (perkiraan)'
                            : formatBerat(pesanan.beratAktual),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: Warna.garis,
                      margin: const EdgeInsets.symmetric(
                        horizontal: Jarak.md,
                      ),
                    ),
                    Expanded(
                      child: _InfoKecil(
                        label: 'Total',
                        nilai: pesanan.hargaSudahFinal
                            ? formatRupiah(pesanan.totalHarga)
                            : 'Menunggu berat asli',
                        warnaNilai: pesanan.hargaSudahFinal
                            ? Warna.primary
                            : Warna.teksSamar,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Jarak.md),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: Warna.teksSamar,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatWaktuLalu(pesanan.dibuatPada),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Warna.teksSamar,
                    ),
                  ),
                  const Spacer(),

                  // Penanda ini membantu admin mengenali pesanan tunai yang
                  // uangnya belum diterima, langsung dari daftar.
                  if (pesanan.statusPembayaran ==
                      StatusPembayaran.belumDibayar) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Jarak.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Warna.peringatanMuda,
                        borderRadius: BorderRadius.circular(Sudut.pil),
                      ),
                      child: const Text(
                        'Belum dibayar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Warna.peringatan,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoKecil extends StatelessWidget {
  const _FotoKecil({this.alamatFoto});

  final String? alamatFoto;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Sudut.kolomIsian),
      child: SizedBox(
        width: 58,
        height: 58,
        child: alamatFoto == null
            ? Container(
                color: Warna.aksenLembut,
                child: const Icon(
                  Icons.checkroom_rounded,
                  size: 24,
                  color: Warna.primary,
                ),
              )
            : Image.network(
                alamatFoto!,
                fit: BoxFit.cover,
                // Foto lama bisa saja sudah dihapus dari server; kartu tetap
                // tampil rapi dengan ikon pengganti.
                errorBuilder: (_, _, _) => Container(
                  color: Warna.aksenLembut,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    size: 22,
                    color: Warna.teksSamar,
                  ),
                ),
                loadingBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? progress,
                    ) {
                      if (progress == null) return child;
                      return Container(
                        color: Warna.aksenLembut,
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
              ),
      ),
    );
  }
}

class _InfoKecil extends StatelessWidget {
  const _InfoKecil({
    required this.label,
    required this.nilai,
    this.warnaNilai,
  });

  final String label;
  final String nilai;
  final Color? warnaNilai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Warna.teksSamar,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          nilai,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: warnaNilai ?? Warna.teksUtama,
          ),
        ),
      ],
    );
  }
}
