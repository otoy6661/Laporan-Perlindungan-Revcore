# Laporan Teknis RevCore — 2026-11-20

Pemilik proyek: **otoy** — Developer: Kodir
Work order: `WORK ORDER — LAPORAN TEKNIS REVCORE` / Upload Laporan Hasil Pekerjaan dan Investigasi Bug
Repository laporan: https://github.com/otoy6661/Laporan-Revcore

Dokumen ini adalah laporan audit independen atas kondisi aktual RevCore pada
2026-11-20. Pekerjaan ini **hanya dokumentasi**: tidak ada source RevCore yang
diubah, tidak ada Gate 10 yang diubah, dan tidak ada rahasia signing yang dimuat.

Dokumen pendukung di folder yang sama:

| Dokumen | Isi |
|---|---|
| [INVESTIGASI_MODE_0x5F.md](INVESTIGASI_MODE_0x5F.md) | Investigasi lengkap Mode Mesin `0x5F` |
| [INVESTIGASI_DISCONNECT_INTERMITTEN.md](INVESTIGASI_DISCONNECT_INTERMITTEN.md) | Investigasi koneksi terputus-putus |
| [MATRIKS_STATUS_17_PEKERJAAN.md](MATRIKS_STATUS_17_PEKERJAAN.md) | Tabel status pekerjaan + keterlacakan |
| [REGRESI_DAN_BUKTI.md](REGRESI_DAN_BUKTI.md) | Regresi, bukti, dan batas klaim |
| `bukti/` | Salinan log dan hasil uji (tanpa APK/ZIP) |

---

## 1. Metadata pemeriksaan

| Item | Nilai |
|---|---|
| Tanggal pemeriksaan | 2026-11-20 (WIB) |
| Salinan kerja source | `work/REVCORE_KEYLESS_20261120/RevCore_work` |
| Salinan kerja pembanding | `work/REVCORE_ABC_20261120/RevCore_work` |
| Versi aplikasi | `com.revcore.android` versionCode 1, versionName 1.0 |
| compileSdk / targetSdk / minSdk | 36 / 36 / 26 |
| Bahasa & UI | Kotlin + Jetpack Compose |
| Toolchain | JDK 25.0.3.9, Gradle 9.6.0, Android SDK build-tools 36.0.0 |
| OS pemeriksaan | Windows 10.0.22631 (x64), Git Bash |
| Perangkat Android tersambung | **Tidak ada** (`adb devices` kosong) |
| Adapter USB/OTG | **Tidak tersambung** |
| ECU / kendaraan | **Tidak tersambung** |

APK yang dirujuk pada laporan ini:

| Artefak | Ukuran | SHA-256 | Sertifikat |
|---|---:|---|---|
| `RevCore build 161126.apk` (rilis resmi sebelumnya, tidak diubah) | — | `b2b6c5bd68cc9c727c2babe0c510b928a6135fa7ef5e9d8847275887c8647432` | `c649cb4f…d098` |
| `RevCore-keyless-test-201126.apk` (APK uji resmi Keyless) | 39.722.410 B | `3b68fe6a4129c7d49a4721990de03bf7d73b2154af170a247d9889bb4345306e` | `c649cb4f…d098` |
| `app-debug.apk` (debug, **bukan** artefak uji resmi) | 56.766.046 B | `4dfd07955d0a86a5922bdbf3de31bc1277965495baaf08b8fd52694eaa034e68` | `CN=Android Debug` |

Cert SHA-256 resmi: `c649cb4fd7e67686a99c1df31936a489b89e62a877b8d6b358f64d027a18d098`
(pin resmi proyek, sama dengan APK 161126).

Tidak ada APK maupun ZIP rilis yang diunggah ke repository ini. Hanya hash dan
hasil verifikasi yang dilaporkan.

---

## 2. Ringkasan eksekutif

1. **Mode Mesin `0x5F`** yang dilihat pemilik bukan hasil konversi dan bukan
   error parsing. Nilai itu adalah byte `MD` dari respons dat17 yang ditampilkan
   apa adanya karena berada di luar pemetaan `1..4`. Arti `0x5F` pada ECU
   kendaraan pemilik **tidak diketahui** dan **tidak dikarang**; diperlukan
   tangkapan frame mentah.
2. Pemetaan Mode di RevCore (`raw in 1..4`) **berbeda dari** pemetaan yang
   terbaca pada referensi 3D Chart (`0x80/0x67→1`, `0x66→2`, `0x3C→3`,
   `0x59→4`, `0x79→0`). Perbedaan ini adalah temuan source-verified dan menjadi
   bug terbuka, bukan sesuatu yang sudah diperbaiki.
3. **Koneksi terputus-putus** belum dapat dinyatakan selesai atau penyebabnya
   diketahui. Tidak ada log TX/RX nyata dari perangkat. Yang ada adalah
   mekanisme pemulihan otomatis (timeout, backoff terbatas, deteksi link-loss,
   penanganan detach) yang terverifikasi di level kode dan unit test, tetapi
   **belum diuji di perangkat**.
4. Build dan signing resmi berjalan; APK uji resmi Keyless terverifikasi
   (v2+v3, 1 signer, cert cocok pin resmi, tidak debuggable, tanpa material
   kunci). **Gate 10 pada prosedur normal belum diuji** karena tidak ada
   perangkat tersambung.
5. Seluruh 330 unit test lulus pada salinan kerja ini. Itu membuktikan logika
   unit, **bukan** perilaku di kendaraan.
6. Daftar 17 item pekerjaan asli tidak ditemukan utuh dalam catatan yang
   tersimpan. Matriks status disusun dari work order A/B/C dan pekerjaan Keyless
   yang dapat dilacak, dengan catatan eksplisit pada dokumen matriks — tidak ada
   item yang dikarang.

---

## 3. Investigasi Mode Mesin `0x5F`

Ringkasan; detail dan kutipan kode ada di
[INVESTIGASI_MODE_0x5F.md](INVESTIGASI_MODE_0x5F.md).

### 3.1 Lokasi tampilan

| Lokasi | File | Keterangan |
|---|---|---|
| Kartu dashboard "MODE MESIN" | `ui/screens/LiveDataScreen.kt:440-442` | Subjudul: `Byte 18 dat17; MODE 1-4 = altitude (rekonstruksi)` |
| Baris "Mode Mesin" pada layar kendaraan | `ui/screens/EcuInfoScreen.kt:387` | Nilai dari `liveSensorValueText()` |

### 3.2 Sumber data mentah

- Profil Live Data `table17`: request `72 05 71 17 01`, `payloadStart = 4`.
- `LiveSensor.MODE` didefinisikan pada offset payload 14
  (`core/comm/LiveDataProfile.kt:384`), yaitu **byte 18 frame**.
- Nilai dibaca sebagai angka 0–255 tanpa aritmetika tambahan.

### 3.3 Alur parsing dan tampilan

1. Byte mentah `MD` masuk sebagai `Double` ke `readings[LiveSensor.MODE]`.
2. `LiveActuatorDecoder.altitudeMode(raw)` mengembalikan `raw.toInt()` hanya
   bila nilainya `1..4`; selain itu `null`
   (`core/comm/LiveActuatorDecoder.kt:43`).
3. `liveSensorValueText()` menampilkan `MODE n` bila pemetaan ada, atau
   fallback `"0x%02X"` dari byte mentah bila tidak
   (`ui/screens/LiveValueText.kt:40-42`).

`0x5F` = 95 desimal. Karena 95 tidak berada di `1..4`, tampilan jatuh ke
fallback dan menampilkan `0x5F` — persis byte yang diterima dari ECU.

### 3.4 Valid / mentah / error parsing?

- **Bukan error parsing**: decoder tidak melempar kesalahan; ia sengaja tidak
  menamai kode di luar `1..4`.
- **Mentah**: nilai yang tampil adalah byte mentah, bukan hasil konversi.
- **Validitas makna tidak diketahui**: apakah `0x5F` adalah kode mode yang sah
  pada ECU tersebut, atau kondisi khusus (mis. saat KOEO, transisi, atau
  keluarga ECU berbeda), tidak dapat ditentukan tanpa bukti protokol atau
  tangkapan frame.
- `0x5F` **tidak ada** dalam daftar kode pada bukti referensi 3D Chart
  (`{0x80,0x67,0x66,0x3C,0x59,0x79}`), sehingga referensi pun tidak menamainya
  (akan jatuh ke MODE 0). Tidak ada dasar untuk mengarang artinya.

### 3.5 Ketersediaan pemetaan per model/ECU

RevCore memakai **satu** fungsi global `altitudeMode()` untuk semua model; tidak
ada tabel per-model atau per-ECU. Pemetaan angka `1..4` di UI diberi label
"rekonstruksi" — konsisten dengan statusnya sebagai rekonstruksi, bukan bukti
protokol final.

### 3.6 Bukti pengujian sebelum/sesudah

| Jenis | Status |
|---|---|
| Unit test `LiveActuatorDecoderTest` | PASS: `1→1`, `4→4`, `0→null`, `5→null`, `null→null` (diuji di JVM) |
| Uji ECU (nilai `0x5F` nyata) | **BELUM DIUJI** — tidak ada ECU di sesi ini |
| Tangkapan frame mentah dat17 dari kendaraan pemilik | **TIDAK ADA** |
| Perbaikan pemetaan `0x5F` | **BELUM ADA** (di luar scope pelaporan) |

---

## 4. Investigasi koneksi terputus-putus (intermittent disconnect)

Ringkasan; detail ada di
[INVESTIGASI_DISCONNECT_INTERMITTEN.md](INVESTIGASI_DISCONNECT_INTERMITTEN.md).

### 4.1 Jenis koneksi

Koneksi yang dimaksud adalah **USB/OTG serial** (bukan Bluetooth). Rantainya:
Android → adapter USB serial → K-Line → ECU Honda. Putus dapat terjadi di dua
titik berbeda: **detach USB** (adapter tercabut/di-reset oleh sistem) atau
**link ECU** (tidak ada balasan valid dalam batas waktu).

### 4.2 Mekanisme yang terlibat (source-verified)

| Mekanisme | Lokasi | Perilaku |
|---|---|---|
| Broadcast receiver USB | `MainActivity.kt:51-111` | ATTACHED/DETACHED/PERMISSION; receiver `NOT_EXPORTED` pada API 33+ |
| Detach | `MainViewModel.kt:1042` | `onUsbDeviceDetached` menutup sesi adapter |
| Timeout buka adapter | `MainViewModel.kt:125, 1250` | 10.000 ms, lalu port dibersihkan |
| Read timeout K-Line | `KlineWireEngine.kt:21, 182` | 700 ms per pembacaan (baca sampai deadline) |
| Kebijakan polling | `LivePollPolicy.kt` | interval 150–1000 ms; berhenti setelah 4 kegagalan beruntun; backoff 300→3000 ms |
| Deteksi link-loss | `HondaProtocolEngine.kt:379` | setelah ambang kegagalan: ECU dianggap tidak hidup, status `LINK_LOST`, telemetri diinvalidasi (STALE) |
| Backoff pemulihan | `MainViewModel.kt:1649` | 2/4/8/16/30 detik, maksimum 8 percobaan |
| Monitor kontak | `MainViewModel.kt:621` | pemeriksaan periodik saat aplikasi di foreground |
| Status siklus komunikasi | `EcuSessionManager.kt:19, 131` | termasuk `SUSPECTED_LOSS` |

### 4.3 Temuan penting

- `CommLifecycle.SUSPECTED_LOSS` **di-set tetapi tidak pernah dibaca** di jalur
  lain. Ini state mati; dampak fungsional belum diketahui dan tidak boleh
  diklaim sebagai penyebab disconnect. Dicatat sebagai bug terbuka (tingkat
  keparahan rendah–sedang, perlu keputusan pemilik).
- Read timeout 700 ms dan ambang 4 kegagalan berarti respons lambat dapat
  terlihat sebagai "putus lalu tersambung lagi". Tanpa log waktu nyata, pola ini
  tidak dapat dibedakan dari detach fisik atau ECU yang benar-benar berhenti
  menjawab.
- Pemulihan otomatis **ada dan terbatas** (backoff sampai 8 percobaan). Berhasil
  tersambung kembali satu kali **bukan** bukti masalah selesai.

### 4.4 Log TX/RX

Satu-satunya kanal untuk memperoleh log nyata dari perangkat adalah
`CommunicationSniffer` (ring buffer 1000 entri) dengan ekspor teks/CSV dari layar
Log (`core/protocol/CommunicationSniffer.kt`, `ui/screens/LogScreen.kt`).

**Tidak ada log TX/RX dari kendaraan pemilik pada sesi ini.** Oleh karena itu:

| Pertanyaan work order | Jawaban berbasis bukti |
|---|---|
| Frekuensi/pola kejadian | **TIDAK DIKETAHUI** |
| Kondisi pemicu | **TIDAK DIKETAHUI** (kandidat: getaran/kabel, detach USB, timeout ECU) |
| Penyebab pasti | **TIDAK DIKETAHUI** |
| Auto-recovery | Ada secara kode; **BELUM DIUJI perangkat** |
| Uji stabilitas | **BELUM DILAKUKAN** |

---

## 5. Matriks status pekerjaan

Tabel lengkap 17 baris ada di
[MATRIKS_STATUS_17_PEKERJAAN.md](MATRIKS_STATUS_17_PEKERJAAN.md). Ringkasnya:

| Kelompok | Status keseluruhan |
|---|---|
| Decode flag A/B (pompa, kipas) | IMPLEMENTED — NOT TESTED di ECU |
| Parameter Live Data inti (8 kartu) | Tidak diubah; IMPLEMENTED — NOT TESTED di perangkat sesi ini |
| Parameter tambahan + label ketersediaan | IMPLEMENTED — NOT TESTED di perangkat |
| Mode Mesin / `0x5F` | PARTIALLY IMPLEMENTED — pemetaan perlu keputusan |
| FIS/FIZ | Ditandai tidak tersedia (sesuai bukti referensi) |
| Tanpa polling saat background | IMPLEMENTED — unit test PASS, perangkat BELUM DIUJI |
| Timeout buka adapter | IMPLEMENTED — perangkat BELUM DIUJI |
| Backoff pemulihan terbatas | IMPLEMENTED — perangkat BELUM DIUJI |
| Deteksi link-loss + telemetri STALE | IMPLEMENTED — ECU BELUM DIUJI |
| Penanganan detach USB | IMPLEMENTED — perangkat BELUM DIUJI |
| Layar tetap menyala saat dashboard aktif | IMPLEMENTED — perangkat BELUM DIUJI |
| Loading setelah Gate 10 / satu kali per peluncuran | IMPLEMENTED — build verified, perangkat BELUM DIUJI |
| Loading minimum 2 detik | **NOT STARTED** — menunggu keputusan pemilik |
| Keyless ID Reader | IMPLEMENTED — 15 unit test PASS, APK resmi terverifikasi; perangkat/ECU BELUM DIUJI |
| Signing fail-closed + verifikasi APK | COMPLETED (build & verifikasi); Gate 10 perangkat BLOCKED |

Catatan integritas: daftar 17 item asli tidak ditemukan utuh dalam transkrip
yang tersimpan. Matriks disusun dari butir yang dapat dilacak ke work order
Point A/B/C dan pekerjaan Keyless. Tidak ada item yang ditambahkan tanpa
rujukan.

---

## 6. Build, signing, dan Gate 10

### 6.1 Konfigurasi build

| Perintah | Hasil |
|---|---|
| `:app:compileDebugKotlin` | BUILD SUCCESSFUL |
| `:app:compileReleaseKotlin` | BUILD SUCCESSFUL |
| `:app:assembleDebug` | BUILD SUCCESSFUL |
| `:app:testDebugUnitTest` | BUILD SUCCESSFUL — 330 test, 0 gagal, 0 error, 0 skip (39 suite) |

### 6.2 Signing

- Release tanpa kredensial resmi **gagal tertutup** pada
  `:app:requireOfficialSigning` dengan pesan bahwa `REVCORE_STORE_PASSWORD` dan
  `REVCORE_KEY_PASSWORD` tidak diset; tidak ada `app-release.apk` yang
  dihasilkan. Log: `bukti/assembleRelease_tanpa_kredensial.log`.
- APK uji resmi Keyless ditandatangani melalui dialog lokal pemilik (kredensial
  tidak pernah masuk ke chat/log laporan) dan diverifikasi ulang secara
  independen dengan `apksigner`/`aapt2`: v2 dan v3 aktif, 1 signer,
  `CN=RevCore Official`, cert SHA-256 sama dengan pin resmi, tidak debuggable,
  tidak ada material kunci di dalam APK, `dist/` tidak tersentuh.
- Detail verifikasi: `bukti/verifikasi_apk_uji_keyless.txt`.
- Status kepatuhan sertifikat: **COMPLIANT** terhadap pin resmi
  `c649cb4f…d098`.

### 6.3 Gate 10

| Item | Status |
|---|---|
| APK uji resmi siap | Ya (`RevCore-keyless-test-201126.apk`) |
| Uji Gate 10 prosedur normal di perangkat | **BELUM DIUJI** — tidak ada perangkat tersambung |
| Klaim kelulusan Gate 10 | **Tidak ada** |

Sesuai work order §4, laporan ini tidak memuat source, konfigurasi, algoritma,
parameter, maupun mekanisme internal Gate 10. Hanya status pengujian yang
dilaporkan.

---

## 7. Regresi

Ringkasan; rincian di [REGRESI_DAN_BUKTI.md](REGRESI_DAN_BUKTI.md).

| Area | Metode | Hasil |
|---|---|---|
| ECM Info / informasi kendaraan | Pemeriksaan source | Tidak diubah pada pekerjaan Keyless; **perangkat BELUM DIUJI** |
| Live Data (8 parameter) | Pemeriksaan source + unit test | Kode lama tidak diubah; **ECU BELUM DIUJI** |
| Diagnostics / DTC | Pemeriksaan source | Tidak diubah; **ECU BELUM DIUJI** |
| Koneksi adapter USB | — | **BELUM DIUJI** (tidak ada adapter) |
| Koneksi & identifikasi ECU | — | **BELUM DIUJI** (tidak ada ECU) |
| Navigasi drawer (entri baru) | Build + pemeriksaan kode | BUILD VERIFIED; tampilan perangkat **BELUM DIUJI** |
| Rotasi/lifecycle layar Keyless | — | **BELUM DIUJI** |
| Gate 10 prosedur normal | — | **BLOCKED** (tidak ada perangkat) |

Klaim statis yang boleh dibuat: tidak ada perubahan pada driver USB, layar Live
Data/Diagnostics selain penambahan, tabel/route lama tidak berubah, akses
transport Keyless memakai lock sesi yang sama (tidak menambah jalur paralel), dan
tidak ada perubahan pada kode integritas/Gate 10.

---

## 8. Bukti

| Bukti | Lokasi di repository | Asal |
|---|---|---|
| Log build release tanpa kredensial | [`bukti/assembleRelease_tanpa_kredensial.log`](bukti/assembleRelease_tanpa_kredensial.log) | `REVCORE_KEYLESS_20261120/bukti/` |
| Log unit test | [`bukti/testDebugUnitTest.log`](bukti/testDebugUnitTest.log) | idem |
| Ringkasan hasil XML unit test | [`bukti/RINGKASAN_UNIT_TEST.md`](bukti/RINGKASAN_UNIT_TEST.md) | dihitung dari 39 XML hasil |
| Verifikasi APK uji resmi | [`bukti/verifikasi_apk_uji_keyless.txt`](bukti/verifikasi_apk_uji_keyless.txt) | idem |
| Verifikasi APK resmi 161126 | [`bukti/verifikasi_apk_161126.txt`](bukti/verifikasi_apk_161126.txt) | idem |
| SHA-256 berkas bukti | [`bukti/SHA256SUMS.txt`](bukti/SHA256SUMS.txt) | dihitung ulang |

Bukti frame mentah dat17 dari kendaraan: **TIDAK ADA**. Bukti log TX/RX
perangkat: **TIDAK ADA**. Bukti uji Gate 10 perangkat: **TIDAK ADA**.

---

## 9. Kesimpulan

1. Kondisi RevCore saat ini: build dan signing resmi sehat; fitur Keyless sudah
   ter-build, ter-sign resmi, dan terverifikasi secara statis, tetapi belum
   diuji pada perangkat/ECU.
2. `0x5F` adalah byte mentah Mode Mesin di luar pemetaan `1..4`. Artinya tidak
   diketahui dan tidak boleh diklaim; pemetaan RevCore juga berbeda dari
   referensi 3D Chart dan perlu keputusan pemilik.
3. Disconnect intermiten belum terjelaskan. Mekanisme pemulihan ada, tetapi
   tanpa log perangkat dan uji stabilitas, statusnya **BELUM TERBUKTI**.
4. Gate 10 dan seluruh regresi perangkat masih **FIELD_TEST_PENDING**.
5. Laporan ini tidak mengubah source RevCore dan tidak memuat rahasia signing
   maupun mekanisme internal Gate 10.

---

## 10. Daftar masalah terbuka

| # | Masalah | Tingkat | Status |
|---|---|---|---|
| B1 | Arti Mode `0x5F` tidak diketahui; tidak ada tangkapan frame | Tinggi (audit data) | TERBUKA |
| B2 | Pemetaan Mode RevCore (`1..4`) tidak cocok dengan bukti referensi (`0x80/0x67/0x66/0x3C/0x59/0x79`) | Tinggi (nilai salah tampil) | TERBUKA |
| B3 | Disconnect intermiten: penyebab, frekuensi, pola belum diketahui | Tinggi | TERBUKA |
| B4 | `CommLifecycle.SUSPECTED_LOSS` tidak pernah dikonsumsi | Rendah–sedang | TERBUKA |
| B5 | Loading minimum 2 detik belum diterapkan (menunggu keputusan pemilik) | Rendah | TERBUKA |
| B6 | Gate 10 belum diuji pada prosedur normal di perangkat | Tinggi | BLOCKED — butuh perangkat |
| B7 | Semua fitur baru (Keyless, penanganan disconnect) belum diuji perangkat/ECU | Tinggi | FIELD_TEST_PENDING |
| B8 | Label UI "MODE 1-4 = altitude (rekonstruksi)" berpotensi menyesatkan jika nilai mentah `1..4` bukan kode mode sebenarnya | Sedang (dokumentasi/UI) | TERBUKA |

---

## 11. Rekomendasi

1. **Tangkap frame mentah**: ekspor log dari layar Log (CommunicationSniffer)
   saat Mode Mesin menampilkan `0x5F`, beserta kondisi (KOEO/KOER, suhu, model).
   Tanpa ini, jangan mengubah pemetaan.
2. **Uji stabilitas terukur**: minimal 30 menit KOEO dan 30 menit KOER, dengan
   percobaan detach/attach dan pencatatan waktu kejadian; ekspor TX/RX untuk
   setiap kejadian putus.
3. **Keputusan pemetaan Mode**: setelah bukti frame terkumpul, pemilik memutuskan
   apakah mengikuti pemetaan referensi 3D Chart atau tetap rekonstruksi. Ini
   perubahan source, sehingga **di luar** pekerjaan pelaporan ini.
4. **Uji Gate 10** dengan APK uji resmi di perangkat pemilik setelah instalasi
   bersih.
5. **Review state `SUSPECTED_LOSS`**: konsumsi atau hapus agar tidak menjadi
   state mati yang membingungkan diagnosis.
6. **Keputusan loading 2 detik**: terapkan atau hapus dari daftar kebutuhan
   secara eksplisit.

---

## 12. Kepatuhan batasan work order

| Batasan | Status |
|---|---|
| Tidak mengubah source RevCore | DIPATUHI — tidak ada perubahan source pada pekerjaan ini |
| Tidak mengubah Gate 10 | DIPATUHI |
| Tidak mengunggah rahasia signing | DIPATUHI — tidak ada keystore/password/private key |
| Tidak mengunggah APK/ZIP rilis tanpa persetujuan Otoy | DIPATUHI — hanya hash dan hasil verifikasi |
| Tidak mengklaim fitur berhasil tanpa uji | DIPATUHI — semua klaim diberi label bukti |
| Tidak menghapus/mengubah riwayat repository | DIPATUHI — riwayat dipertahankan; file baru ditambahkan |
| Identitas/kredit pemilik **otoy** | DIPERTAHANKAN |
