# Laporan Akhir — LaundryKu Flutter

Aplikasi mobile LaundryKu untuk pemesanan dan manajemen laundry skala kecil.

- **Folder kerja:** `LaundryKu_flutter` (repository Flutter tersendiri)
- **Branch:** `feature/mobile`
- **Remote:** `https://github.com/Alpin969/LaundryKu-Flutter.git`
- **Tanggal:** 17 November 2026
- **Status:** seluruh tahap selesai, sudah dipakai menguji, dan sudah ter-push

---

## A. Halaman yang berhasil dibuat

### 1. Autentikasi — 3 halaman (`lib/screens/auth/`)

| Halaman | Berkas | Isi |
|---|---|---|
| Splash | `splash_screen.dart` | Logo, nama aplikasi, slogan "Bersih, Praktis, Terpercaya", pemeriksaan sesi, tombol periksa ulang bila gagal |
| Login | `login_screen.dart` | Email, password, tombol tampil/sembunyikan sandi, tombol login, link ke register, validasi input |
| Register | `register_screen.dart` | Nama lengkap, email, password, konfirmasi password, validasi input, tombol daftar |

Register hanya membuat akun **CUSTOMER**. Form tidak punya pilihan role, dan role
tidak ikut dikirim ke backend. Ada pengujian yang membuktikan permintaan
`role: "ADMIN"` dari aplikasi tetap diabaikan backend.

### 2. Pelanggan — 10 halaman (`lib/screens/customer/`)

| Halaman | Berkas | Isi |
|---|---|---|
| Beranda | `beranda_screen.dart` | Sapaan sesuai waktu, ringkasan pesanan aktif, tombol Pesan Laundry, daftar layanan, pesanan terbaru, penjelasan enam status |
| Daftar Layanan | `daftar_layanan_screen.dart` | Nama, deskripsi, harga per kilogram, estimasi pengerjaan, pencarian, keadaan kosong |
| Detail Layanan | `detail_layanan_screen.dart` | Informasi lengkap layanan dan tombol pesan |
| Form Pemesanan | `form_pemesanan_screen.dart` | Pilihan layanan dan berat perkiraan |
| Konfirmasi Pesanan | `konfirmasi_pesanan_screen.dart` | Ringkasan layanan, berat, perkiraan biaya, dan unggah foto opsional |
| Daftar Pesanan | `daftar_pesanan_screen.dart` | Pesanan aktif dan selesai dengan penyaring status |
| Detail Pesanan | `detail_pesanan_screen.dart` | ID, layanan, berat perkiraan, berat aktual, harga per kg, total biaya, status, foto pakaian |
| Riwayat | `riwayat_screen.dart` | Pesanan sebelumnya, dikelompokkan per bulan |
| Profil | `profil_screen.dart` | Nama, email, role, ubah profil, logout dengan konfirmasi |
| Ubah Profil | `ubah_profil_screen.dart` | Ganti nama, dan ganti kata sandi dengan kata sandi lama sebagai syarat |

Navigasi bawah pelanggan: **Beranda, Pesanan, Riwayat, Profil**.

### 3. Admin — 5 berkas (`lib/screens/admin/`)

| Halaman | Berkas | Isi |
|---|---|---|
| Dashboard | `dashboard_admin_screen.dart` | Total pesanan, masih berjalan, selesai, ditambah kartu keenam status yang bisa diklik untuk membuka daftar tersaring, dan daftar "perlu dikerjakan" |
| Kelola Layanan | `kelola_layanan_screen.dart` | Daftar layanan, tambah, edit, hapus dengan dialog konfirmasi |
| Tambah/Edit Layanan | `form_layanan_screen.dart` | Form nama, deskripsi, harga per kg, estimasi |
| Update Berat | `isi_berat_screen.dart` | Input berat aktual, total biaya dari hasil hitungan backend |
| Update Status | `ubah_status_sheet.dart` | Perubahan status sesuai aturan transisi backend, dengan konfirmasi |

Detail pesanan versi admin memakai halaman yang sama (`detail_pesanan_screen.dart`),
dengan bagian "Pelanggan" yang muncul hanya untuk admin.

Navigasi bawah admin sengaja berbeda dari pelanggan:
**Dashboard, Pesanan, Layanan, Riwayat, Profil** — dan keduanya memakai kelas
shell terpisah (`ShellPelanggan` dan `ShellAdmin` di
`lib/screens/shells/shell_pelanggan.dart`).

---

## B. Fitur yang berhasil dibuat

### Autentikasi dan sesi
- Login untuk ADMIN dan CUSTOMER, register khusus CUSTOMER
- Setelah masuk maupun mendaftar, pengguna langsung dibawa ke halaman sesuai
  rolenya; halaman daftar menutup dirinya sendiri supaya tidak menutupi beranda
- Token JWT disimpan dengan `flutter_secure_storage`
- Token dikirim sebagai `Authorization: Bearer <token>` pada endpoint privat
- Profil diambil lewat `GET /api/auth/me`, bukan dari data lokal
- Pengguna diarahkan ke halaman sesuai role yang dikembalikan backend
- Logout menghapus token dan mengosongkan data pengguna
- Token tidak valid atau kedaluwarsa menutup seluruh halaman yang terbuka dan
  mengembalikan pengguna ke login

**Catatan keamanan:** role yang tersimpan di aplikasi hanya menentukan halaman
yang ditampilkan, bukan penjaga keamanan. Backend tetap memeriksa token dan role
pada setiap permintaan.

### Pemesanan
- Buat pesanan dengan memilih layanan dan berat perkiraan
- Upload foto pakaian (opsional) lewat kamera atau galeri, dengan pratinjau,
  ganti foto, dan hapus foto — termasuk foto yang sudah tersimpan di backend,
  sehingga berkasnya benar-benar dibuang dari penyimpanan
- Harga TIDAK pernah dihitung atau dikirim dari aplikasi; backend mengambil harga
  dari tabel `services` di dalam satu pernyataan SQL
- Batalkan pesanan sesuai aturan backend (hanya status yang masih boleh dibatalkan)
- Riwayat pesanan yang dikelompokkan per bulan
- Ubah profil: ganti nama, dan ganti kata sandi dengan kata sandi lama sebagai
  syarat — tersedia untuk pelanggan maupun admin

### Admin
- CRUD layanan lengkap dengan dialog konfirmasi sebelum menghapus
- Daftar seluruh pesanan dengan penyaring status
- Isi berat aktual; total biaya dihitung backend dan aplikasi hanya menampilkan hasilnya
- Ubah status mengikuti peta transisi backend (`INVALID_STATUS_TRANSITION` ditampilkan
  sebagai pesan yang jelas)
- Dashboard dengan hitungan per status yang bisa diklik untuk membuka daftar tersaring

### Penanganan kesalahan dan keadaan antarmuka
- Setiap halaman punya keadaan **memuat**, **gagal**, dan **kosong**
- Pesan kegagalan menyebutkan sebab dan langkah berikutnya
- Kegagalan koneksi menjelaskan sebabnya dengan bahasa yang bisa dipahami
  pengguna, tanpa istilah teknis seperti alamat API atau server
- Ukuran foto (2 MB) dan tipe berkas diperiksa di aplikasi sebelum dikirim, supaya
  pengguna tidak menunggu unggahan yang pasti gagal

---

## C. Struktur folder Flutter

```text
LaundryKu_flutter/
├── lib/                              42 berkas, 9.344 baris
│   ├── main.dart                     gerbang sesi + routing berdasarkan role
│   ├── config/
│   │   ├── api_config.dart           alamat API terpusat (--dart-define)
│   │   └── app_theme.dart            warna, jarak, sudut, font
│   ├── models/
│   │   ├── user.dart
│   │   ├── layanan.dart
│   │   ├── pesanan.dart
│   │   └── status_pesanan.dart
│   ├── services/
│   │   ├── api_client.dart           satu pintu keluar ke REST API
│   │   ├── auth_service.dart
│   │   ├── layanan_service.dart
│   │   └── pesanan_service.dart
│   ├── screens/
│   │   ├── auth/                     splash, login, register            (3)
│   │   ├── customer/                 beranda sampai ubah profil        (10)
│   │   ├── admin/                    dashboard sampai ubah status       (5)
│   │   └── shells/                   shell_pelanggan.dart              (1)
│   ├── widgets/                      10 widget bersama
│   └── utils/
│       ├── format.dart               tanggal, rupiah, berat
│       └── validasi.dart             validasi form
├── test/                             4 berkas, 1.928 baris
│   ├── logika_test.dart              19 pengujian
│   ├── alur_masuk_test.dart          2 pengujian (masuk dan daftar sampai beranda)
│   ├── api_integration_test.dart     56 pengujian (butuh backend)
│   └── tata_letak_test.dart          46 pengujian
├── assets/fonts/                     Poppins Regular/Medium/SemiBold/Bold
├── android/  ios/  web/
├── pubspec.yaml
└── LAPORAN.md                        berkas ini
```

Struktur ini mengikuti pendekatan sederhana yang diminta: **models, services,
screens, widgets, config** — tanpa lapisan state management tambahan.

---

## D. Dependencies

```yaml
environment:
  sdk: ^3.12.2

dependencies:
  flutter:              sdk
  flutter_localizations: sdk
  cupertino_icons:      ^1.0.8
  http:                 ^1.6.0        # komunikasi REST API
  flutter_secure_storage: ^11.2.0     # penyimpanan JWT
  image_picker:         ^1.2.4        # kamera dan galeri
  intl:                 ^0.20.2       # format tanggal dan mata uang
  http_parser:          ^4.1.2        # Content-Type multipart

dev_dependencies:
  flutter_test:         sdk
  flutter_lints:        ^6.0.0
```

**Catatan `intl`:** dipatok pada `^0.20.2` karena `flutter_localizations` dari SDK
mensyaratkan versi tersebut. Versi lebih baru (`^0.20.3`) akan gagal diresolusi.

`http_parser` dipakai hanya untuk menentukan `Content-Type` multipart saat
mengunggah foto. Tidak ada package lain yang ditambahkan.

Font Poppins dibundel sebagai aset di dalam aplikasi (bukan diunduh saat berjalan),
supaya tampilan tidak berubah-ubah tergantung jaringan.

---

## E. Endpoint yang sudah terintegrasi

Seluruh permintaan melewati satu kelas `ApiClient` (`lib/services/api_client.dart`)
yang menangani token, status HTTP, dan kegagalan koneksi.

| Endpoint | Method | Berkas dan baris |
|---|---|---|
| `/api/auth/register` | POST | `auth_service.dart:133` |
| `/api/auth/login` | POST | `auth_service.dart:104` |
| `/api/auth/me` | GET | `auth_service.dart:75, 170, 194` |
| `/api/auth/me` | PATCH | `auth_service.dart:219` |
| `/api/services` | GET | `layanan_service.dart:17` |
| `/api/services/:id` | GET | `layanan_service.dart:26` |
| `/api/services` | POST | `layanan_service.dart:31` |
| `/api/services/:id` | PUT | `layanan_service.dart:39` |
| `/api/services/:id` | DELETE | `layanan_service.dart:52` |
| `/api/orders` | GET | `pesanan_service.dart:41` |
| `/api/orders` | POST | `pesanan_service.dart:100` |
| `/api/orders/:id` | GET | `pesanan_service.dart:82` |
| `/api/orders/:id/batal` | PATCH | `pesanan_service.dart:128` |
| `/api/orders/:id/foto` | PATCH | `pesanan_service.dart:163` |
| `/api/orders/:id/foto` | DELETE | `pesanan_service.dart:179` |
| `/api/orders/:id/status` | PATCH | `pesanan_service.dart:230` |
| `/api/orders/:id/berat-asli` | PATCH | `pesanan_service.dart:247` |

Upload foto memakai `multipart/form-data` dengan nama field **`photo`**, sesuai
yang diminta backend.

Dua endpoint terakhir bertanda PATCH `/api/auth/me` dan DELETE
`/api/orders/:id/foto` ditambahkan di backend atas permintaan pemilik proyek,
karena tanpa keduanya tombol hapus foto dan halaman ubah profil tidak bisa
benar-benar bekerja. Rinciannya ada di bagian H.

Yang **tidak** dilakukan aplikasi, sesuai batasan: tidak mengakses PostgreSQL
langsung, tidak membuat endpoint sendiri, dan tidak mengirim harga.

### Konfigurasi alamat API

Alamat API dipusatkan di `lib/config/api_config.dart` dan diisi lewat `--dart-define`:

```bash
# Android Emulator (10.0.2.2 = localhost komputer)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Perangkat Android fisik (pakai IP LAN komputer)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000

# Backend online
flutter run --dart-define=API_BASE_URL=https://alamat-backend.example.com
```

Tidak ada `DB_PASSWORD`, `JWT_SECRET`, atau kredensial Aiven di dalam project ini.
Pemeriksaan sudah dijalankan terhadap seluruh berkas yang ter-track Git.

---

## F. Hasil flutter analyze

```text
$ flutter analyze
Analyzing LaundryKu_flutter...
No issues found! (ran in 5.1s)
```

Dijalankan berkali-kali sepanjang pengerjaan, termasuk sekali lagi setelah
seluruh penyempurnaan tahap akhir selesai. Hasilnya tetap tanpa temuan.

---

## G. Hasil testing

Semua hasil di bawah ini adalah keluaran sungguhan dari perintah yang dijalankan,
bukan perkiraan.

### 1. Pengujian tanpa backend

```text
$ flutter test
00:12 +67 ~1: All tests passed!
```

67 lulus, 1 dilewati. Yang dilewati adalah berkas uji integrasi API, yang
melewatkan dirinya sendiri karena backend tidak dijalankan pada perintah itu.

| Berkas | Jumlah | Cakupan |
|---|---|---|
| `test/logika_test.dart` | 19 lulus | Angka NUMERIC yang datang sebagai teks, transisi status, validasi form, format rupiah/tanggal/berat |
| `test/alur_masuk_test.dart` | 2 lulus | Masuk dan daftar sampai benar-benar tiba di beranda pelanggan |
| `test/tata_letak_test.dart` | 46 lulus | Tata letak empat ukuran layar |
| `test/api_integration_test.dart` | dilewati | Butuh backend berjalan |

`test/alur_masuk_test.dart` dibuat khusus untuk masalah yang dilaporkan
pemilik proyek: setelah daftar, pengguna tidak langsung masuk ke dashboard.
Pengujian ini menjalankan aplikasi sungguhan (gerbang sesi ikut diuji),
menekan tombol Daftar, lalu menuntut halaman daftar sudah tertutup dan beranda
pelanggan yang tampil. Backend tidak diperlukan karena seluruh permintaan
dilayani klien HTTP buatan yang dipasang lewat `ApiClient.klienUji`.

### 2. Pengujian tata letak berbagai ukuran layar

Empat ukuran diuji: **320x568** (ponsel kecil), **360x640** (ponsel umum),
**414x896** (ponsel besar), dan **768x1024** (tablet).

Pengujian ini memuat font Poppins yang asli dan menginisialisasi data lokal
`id_ID`. Keduanya penting: tanpa font asli, `flutter_test` memakai font bawaan
yang setiap hurufnya selebar satu em sehingga teks tampak jauh lebih panjang
daripada aslinya, dan laporan luapan yang muncul tidak bisa dipercaya.

### 3. Pengujian integrasi REST API nyata

Dijalankan terhadap backend LaundryKu yang benar-benar hidup:

```bash
$ flutter test test/api_integration_test.dart \
    --dart-define=UJI_API=true \
    --dart-define=API_BASE_URL=http://localhost:3001 \
    --dart-define=ADMIN_EMAIL=<email admin> \
    --dart-define=ADMIN_PASSWORD=<kata sandi admin>

00:19 +56: All tests passed!
```

56 pengujian meliputi: kesehatan API dan database, registrasi dan login, bahwa
role tidak bisa ditentukan dari aplikasi, pengambilan profil lewat `/api/auth/me`,
penolakan token palsu dan token kedaluwarsa, CRUD layanan (termasuk penolakan
menghapus layanan yang masih dipakai pesanan), pembuatan pesanan, upload foto,
**hapus foto pesanan**, **ubah profil akun**, perubahan berat, perubahan status
termasuk penolakan transisi yang tidak sah, pembatalan pesanan, dan logout.

### 4. Daftar periksa pengujian dari instruksi

| # | Butir | Hasil |
|---|---|---|
| 1 | `flutter pub get` | Berhasil |
| 2 | `flutter analyze` | No issues found |
| 3 | Uji Login | Lulus (unit + integrasi) |
| 4 | Uji Register | Lulus (unit + integrasi) |
| 5 | Uji role ADMIN | Lulus — diarahkan ke ShellAdmin |
| 6 | Uji role CUSTOMER | Lulus — diarahkan ke ShellPelanggan |
| 7 | Uji daftar layanan | Lulus |
| 8 | Uji CRUD layanan | Lulus (tambah, edit, hapus) |
| 9 | Uji pembuatan pesanan | Lulus |
| 10 | Uji upload foto | Lulus |
| 11 | Uji perubahan berat | Lulus |
| 12 | Uji perubahan status | Lulus |
| 13 | Uji riwayat | Lulus |
| 14 | Uji logout | Lulus |
| 15 | Uji layout berbagai ukuran | Lulus pada 4 ukuran layar |

### 5. Pemeriksaan tampilan

- **Screenshot halaman login** pada 320x675 px: logo, kolom email dan password,
  tombol Masuk, dan tautan "Belum punya akun? Daftar di sini" tampil sesuai rancangan.
- **Galeri komponen** dengan data sungguhan dari API: lencana status, kartu pesanan,
  kartu layanan, baris detail, serta penanda gagal dan kosong tampil sesuai rancangan.
- **Build web** untuk memeriksa hasil sungguhan di peramban:

```bash
$ flutter build web --no-web-resources-cdn --dart-define=API_BASE_URL=http://localhost:3000
√ Built build\web
```

### 6. Cacat yang ditemukan dan diperbaiki

Pengujian tata letak menemukan satu cacat nyata: **pada layar 320 px, nomor pesanan
dan lencana status saling mendesak sampai terpotong 39 px** dan 27 px pada kartu
yang berbeda. Penyebabnya susunan `Row` dengan `Spacer` di `lib/widgets/kartu_pesanan.dart`.

Perbaikannya: susunan diganti `Wrap`, sehingga lencana turun ke baris berikutnya
bila tidak muat bersebelahan — bukan terpotong dan bukan dipotong dengan elipsis.
Sesudah perbaikan, seluruh pengujian tata letak lulus, dan galeri komponen
memperlihatkan lencana "Menunggu Konfirmasi" memang turun ke baris kedua pada
kartu yang sempit.

Cacat kedua ditemukan lewat laporan pemilik proyek, bukan lewat pengujian:
**setelah mendaftar, pengguna tidak langsung masuk ke dashboard.** Ternyata
halaman daftar dibuka dengan `Navigator.push` di atas halaman login, sedangkan
gerbang sesi hanya mengganti rute pertama. Formulir pendaftaran karena itu tetap
menutupi beranda. Perbaikannya: halaman daftar menutup dirinya sendiri
(`popUntil` ke rute pertama) memakai `Navigator` yang ditangkap sebelum
permintaan dikirim. Pengujian `test/alur_masuk_test.dart` ditambahkan supaya
masalah ini tidak kembali diam-diam.

---

## H. Kendala

### 1. Batas percobaan login backend (20 per 15 menit per IP)

Backend membatasi `POST /api/auth/register` dan `POST /api/auth/login` sebanyak
20 permintaan per 15 menit per alamat IP, dihitung di dalam memori proses
(`backend/src/routes/auth.routes.js`). Pada percobaan pertama, berkas uji
melakukan login berulang untuk setiap grup sehingga kuota habis dan pengujian
gagal karena HTTP 429.

**Penanganan:** berkas uji ditulis ulang supaya melakukan login **sekali** per
jalannya pengujian, lalu memakai ulang tokennya. Pengujian juga dijalankan pada
instance backend tersendiri di port 3001, tanpa mengganggu server yang sedang
berjalan di port 3000.

### 2. Cacat backend kode `23001` — sudah diperbaiki

Ditemukan saat pengujian CRUD layanan:

```text
DELETE /api/services/:id   (layanan yang sudah dipakai pesanan)
→ HTTP 500
  {"success":false,"message":"Terjadi kesalahan pada server.","error":"23001"}
  seharusnya HTTP 409 dengan kode SERVICE_IN_USE
```

Penyebab: `backend/src/controllers/services.controller.js:151` hanya memeriksa
`error.code === '23503'`, sedangkan PostgreSQL mengirim kode **`23001`**
(`restrict_violation`) untuk pelanggaran `ON DELETE RESTRICT`. Selain itu
`backend/src/utils/pgError.js` tidak memetakan kode `23001`, sehingga kode mentah
PostgreSQL ikut bocor pada field `error`.

Pada awalnya cacat ini hanya dilaporkan karena lingkup pekerjaan dibatasi pada
Flutter. Setelah pemilik proyek memberi izin menyentuh backend, cacat ini
**diperbaiki**:

- `backend/src/utils/pgError.js` memetakan `23001` menjadi HTTP 409
  (`DATA_IN_USE`), dan kode mentah PostgreSQL tidak lagi ikut terkirim.
- `backend/src/controllers/services.controller.js` memeriksa **kedua** kode
  (23503 dan 23001) dan menjawab `SERVICE_IN_USE`.

Sekarang admin yang mencoba menghapus layanan yang masih dipakai menerima
penjelasan yang bisa dimengerti, bukan kegagalan server tanpa sebab.

### 3. Respons `POST /api/orders` tidak lengkap

Backend hanya mengembalikan kolom tabel `orders` apa adanya, tanpa `service_name`
dan `customer_name` yang sudah digabung (berbeda dari `GET /api/orders/:id`).

**Penanganan di aplikasi:** setelah membuat pesanan, aplikasi mengambil ulang
detailnya lewat `GET /api/orders/:id`. Bila pengambilan susulan itu gagal, pesanan
yang **sudah sah dibuat** tetap dikembalikan apa adanya — melempar kesalahan di
titik itu akan membuat pelanggan mengira pesanannya belum masuk dan membuatnya dua kali.

### 4. Batas ukuran foto ternyata 2 MB, bukan 5 MB

Instruksi menyebut maksimal 5 MB "sesuai batas backend jika terkonfirmasi".
Pemeriksaan `backend/src/middleware/upload.js` menunjukkan batas sebenarnya
adalah `2 * 1024 * 1024` byte, dan tipe yang diterima hanya JPEG, PNG, dan WebP.
Aplikasi mengikuti batas backend yang sebenarnya, dan memeriksanya lebih dulu di
sisi aplikasi sebelum berkas dikirim.

### 5. Tombol hapus foto dan halaman ubah profil butuh endpoint baru

Backend awalnya hanya menyediakan `PATCH /api/orders/:id/foto` untuk mengunggah
foto, tanpa cara menghapusnya. Akibatnya tombol hapus di aplikasi hanya berlaku
untuk foto yang **belum terkirim**, dan tidak ada cara mengganti nama atau kata
sandi akun dari aplikasi.

Kedua fitur itu tidak bisa dikerjakan hanya dari sisi Flutter — tidak ada
endpoint yang bisa dipanggil. Karena itu pemilik proyek memberi izin untuk
menambahkan endpoint di backend, dan dua endpoint berikut dibuat mengikuti gaya
yang sudah ada:

| Endpoint | Method | Keterangan |
|---|---|---|
| `/api/auth/me` | PATCH | Ganti nama, dan ganti kata sandi dengan kata sandi lama sebagai syarat |
| `/api/orders/:id/foto` | DELETE | Hapus foto pesanan; berkasnya ikut dibuang dari penyimpanan |

Keduanya memakai aturan yang sama dengan endpoint sejenis: `PATCH /api/auth/me`
hanya boleh mengubah akun pemilik token sendiri, dan `DELETE /api/orders/:id/foto`
boleh dilakukan pemilik pesanan maupun admin. Setelah foto dihapus, pelanggan
tetap bisa mengunggah foto baru.

Perubahan backend ini disimpan sebagai commit tersendiri di repository backend,
terpisah dari repository Flutter ini.

### 6. "Layanan populer" tidak bisa dibuat

Instruksi menyebut "Layanan populer" di beranda, tetapi backend tidak menyediakan
data layanan terpopuler. Beranda menampilkan daftar layanan **tanpa** mengaku
sebagai peringkat: judulnya "Layanan Laundry" dengan keterangan bahwa harga dan
estimasi pengerjaan yang ditampilkan adalah yang berlaku di LaundryKu. Tidak ada
angka karangan yang dibuat-buat.

### 7. Perbedaan font antara pengujian dan tampilan nyata

Pengujian widget di Flutter memakai font bawaan yang metriknya berbeda jauh dari
font asli. Pada percobaan pertama muncul laporan luapan 182 px, 168 px, 142 px,
dan 128 px yang **tidak nyata** — pada akhirnya yang benar adalah 39 px dan 27 px.
Pelajaran yang dipakai: font asli dimuat di dalam berkas uji sebelum tata letak
diukur, dan setiap widget yang memformat angka `id_ID` harus menginisialisasi
data lokalnya lebih dulu.

Pelajaran yang sama muncul lagi saat menguji alur masuk: dengan font bawaan,
halaman login melaporkan luapan 82 px yang tidak ada di perangkat. Setelah font
Poppins asli dimuat, laporan itu hilang.

### 8. Penyimpanan aman tidak punya sisi platform di dalam pengujian widget

Pengujian alur masuk mula-mula gagal dengan gejala yang membingungkan: permintaan
login berhasil, tetapi halaman tidak berpindah. Setelah ditelusuri, alur berhenti
tepat di langkah menyimpan token — `flutter_secure_storage` tidak punya
implementasi platform di dalam pengujian widget, sehingga pemanggilan kanalnya
tidak pernah selesai. Di aplikasi sungguhan hal ini tidak terjadi.

**Penanganan:** pengujian memakai pengganti resmi dari plugin
(`FlutterSecureStorage.setMockInitialValues`), sehingga penyimpanan token berjalan
seperti biasa di dalam pengujian. Pelajarannya: kegagalan di dalam pengujian
belum tentu cacat aplikasi, dan harus ditelusuri sampai ketemu sebelum diperbaiki.

---

## I. Git

| Keterangan | Nilai |
|---|---|
| **Repository** | `https://github.com/Alpin969/LaundryKu-Flutter.git` (tidak diubah) |
| **Branch pengerjaan** | `feature/mobile` |
| **Branch dasar** | `main` @ `9b2382c` ("first commit") |
| **Branch aktif saat ini** | `feature/mobile` |
| **Working tree** | bersih (tidak ada perubahan tertunda) |
| **Sinkron dengan remote** | `0  0` — tidak ada commit tertinggal, tidak ada yang belum ter-push |
| **Push status** | **Berhasil.** Setiap tahap di-push setelah selesai dan lolos pemeriksaan |

Angka sinkronisasi di atas bisa diperiksa ulang kapan saja dengan:

```bash
git rev-list --left-right --count origin/feature/mobile...HEAD
git ls-remote --heads origin feature/mobile
```

Nilai `0  0` berarti tidak ada commit yang tertinggal di belakang maupun menunggu
dikirim. Perintah kedua menampilkan hash branch di GitHub.

Commit di atas adalah tahap-tahap pekerjaan aplikasinya. Delapan commit pertama
(`3493797` sampai `b95137a`) berisi kode aplikasi dan pengujiannya, dan `436b9a8`
menambahkan berkas laporan ini. Commit sesudahnya berisi penyempurnaan akhir
aplikasi: alur masuk yang salah, teks teknis yang dihapus dari layar pengguna,
serta hapus foto dan ubah profil yang disambungkan ke backend.

Hash terakhir pada branch sengaja tidak dicantumkan di sini: setiap kali laporan
ini diperbarui dan di-commit, hash terakhir ikut berubah sehingga nilai yang
ditulis akan langsung basi. Periksa nilai terkini dengan perintah di atas.

### Daftar commit

| Hash | Pesan commit |
|---|---|
| `3493797` | feat(mobile): create Flutter project foundation |
| `941f539` | feat(mobile): integrate REST API with models, services, and shared widgets |
| `61217e7` | feat(mobile): implement authentication screens |
| `af212c5` | feat(mobile): implement customer features |
| `83cc167` | feat(mobile): implement admin features |
| `d34fd90` | test(mobile): add unit and integration tests |
| `bc6e068` | feat(mobile): tampilkan daftar layanan di beranda pelanggan |
| `b95137a` | test(mobile): uji tata letak di berbagai ukuran layar |
| `436b9a8` | docs(mobile): tambahkan laporan akhir pengerjaan |

Commit dibuat terpisah per tahap pekerjaan, bukan sekaligus di akhir. Cara
memeriksa seluruhnya sekaligus:

```bash
git log --oneline main..feature/mobile
```

### Yang TIDAK dilakukan (sesuai instruksi)

- Tidak membuat repository baru
- Tidak mengubah remote
- Tidak memakai `git reset --hard`
- Tidak memakai force checkout maupun force push
- Tidak merge otomatis ke `main`
- Tidak melakukan deployment

### Perubahan pada repository backend

Perubahan backend yang disebut di bagian H adalah pekerjaan di **repository
terpisah** (`LaundryKu`), dan sengaja tidak dicampur ke repository Flutter ini.
Yang diubah hanya enam berkas di `backend/src/`, ditambah **dua endpoint baru**:

| Berkas | Perubahan |
|---|---|
| `src/utils/pgError.js` | Kode `23001` dipetakan menjadi HTTP 409 (`DATA_IN_USE`) |
| `src/controllers/services.controller.js` | Hapus layanan yang masih dipakai menjawab `SERVICE_IN_USE`, bukan 500 |
| `src/controllers/auth.controller.js` | Handler `ubahProfil` (PATCH `/api/auth/me`) |
| `src/routes/auth.routes.js` | Rute PATCH `/me` |
| `src/controllers/orders.controller.js` | Handler `hapusFoto` (DELETE `/api/orders/:id/foto`) |
| `src/routes/orders.routes.js` | Rute DELETE `/:id/foto` |

Commit itu dikirim ke branch `feature/backend` yang sudah ada di repository
backend, dengan pemeriksaan lebih dulu bahwa pengirimannya hanya menambah:
`git merge-base --is-ancestor origin/feature/backend HEAD` memastikan commit
lama masih menjadi leluhur, sehingga `ad6448b..c248e0e` terkirim sebagai
fast-forward. Tidak ada `git reset`, tidak ada force push, dan branch `main`
di repository itu tidak tersentuh.

Aplikasi Flutter tetap tidak menyimpan kredensial apa pun. Kedua endpoint baru
dipanggil lewat `Authorization: Bearer <token>` seperti endpoint lainnya.

### Pemeriksaan berkas rahasia

Sudah diperiksa terhadap seluruh berkas yang ter-track Git: tidak ada berkas
`.env`, `.pem`, atau `.key`, dan tidak ada pola `JWT_SECRET`, `DB_PASSWORD`,
`postgres://`, maupun kredensial Aiven. Satu-satunya kemunculan kata tersebut
adalah komentar di `lib/config/api_config.dart` yang justru menyatakan bahwa
kredensial tidak disimpan di project Flutter.

Folder `build/` dan `.dart_tool/` sudah tercakup `.gitignore` — hasil build tidak
pernah ikut ter-commit.

---

## J. Pekerjaan yang belum selesai

1. **Belum merge ke `main` dan belum ada Pull Request.**
   Sengaja, sesuai instruksi untuk tidak merge otomatis. GitHub menawarkan
   tautan PR untuk `feature/mobile` bila ingin dilanjutkan.

2. **Belum diuji pada perangkat Android atau iOS yang sebenarnya.**
   Folder `android/` dan `ios/` sudah ada dan siap, tetapi belum pernah
   dijalankan di perangkat maupun emulator. Verifikasi tampilan dilakukan lewat
   build web.

3. **Data uji masih tertinggal di database bersama.**
   Akun `uji-mobile-*@laundryku.test` dan `uji-galeri-*@laundryku.test`, layanan
   berawalan `[UJI MOBILE]`, beberapa pesanan uji, dan foto di `backend/uploads`.
   Belum dibersihkan. Semua diberi awalan yang jelas supaya mudah dikenali.

4. **"Layanan populer" belum ada** karena backend tidak menyediakan datanya
   (bagian H.6).

5. **Keterangan catatan tambahan pada pesanan belum ada.**
   Formulir pemesanan tidak menyediakan kolom catatan karena tabel `orders` di
   database tidak punya kolomnya, dan instruksi melarang mengubah database.
   Menambahkannya butuh kolom baru di backend.

6. **Layar dalam keadaan login belum semuanya diperiksa dengan mata sendiri.**
   Yang sudah dilihat langsung: halaman masuk, alur masuk sampai beranda, dan
   galeri komponen dengan data API sungguhan. Layar lainnya diverifikasi lewat
   pengujian tata letak otomatis pada empat ukuran layar dan pengujian alur,
   bukan lewat gambar. Disebutkan di sini supaya tidak terbaca sebagai sudah
   diperiksa secara visual.

7. **Belum ada deployment** — sesuai batasan pekerjaan pada tahap ini.

---

## Cara menjalankan

```bash
# 1. Pasang dependensi
flutter pub get

# 2. Jalankan backend LaundryKu lebih dulu
cd ../LaundryKu/backend && npm run dev

# 3. Jalankan aplikasi
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000      # Android Emulator
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000  # perangkat fisik
```

Menjalankan pengujian:

```bash
# Pengujian unit dan tata letak (tidak butuh backend)
flutter test

# Pengujian integrasi API (butuh backend berjalan)
flutter test test/api_integration_test.dart \
  --dart-define=UJI_API=true \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=ADMIN_EMAIL=<email admin> \
  --dart-define=ADMIN_PASSWORD=<kata sandi admin>
```

Bagian khusus admin dilewati bila `ADMIN_EMAIL` dan `ADMIN_PASSWORD` tidak diisi,
sehingga berkas uji integrasi tetap berguna untuk memeriksa bagian pelanggan saja.
