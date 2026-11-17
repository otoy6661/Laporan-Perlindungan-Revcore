# REVCORE INTEGRATION RECOMMENDATIONS — BE-09

**Tanggal:** 17 November 2026
**Sifat:** rekomendasi penelitian, bukan perubahan kode RevCore.
**Batas:** proyek RevCore tidak dibuka, tidak diubah, dan tidak diaudit dalam work order ini.
Gap dinilai terhadap kebutuhan umum editor/tool ECU offline, bukan terhadap source RevCore.

Status bukti: `ANALYZED`, `PROTOTYPED`, `TESTED_PASS`, `HARDWARE_PENDING`, `UNKNOWN`, `NOT_FOUND`.

---

## 1. Ringkasan keputusan

| Kategori | Jumlah paket | Boleh masuk RevCore sekarang? |
|---|---:|---|
| A. Dapat diterapkan langsung | 5 | Ya, setelah review kode dan lisensi |
| B. Perlu adaptasi | 5 | Belum; perlu desain/porting |
| C. Perlu riset lanjutan | 6 | Tidak |
| D. Tidak relevan | 5 | Tidak |

Aturan umum: hanya komponen kategori A yang boleh dipertimbangkan untuk integrasi
awal, dan hanya sebagai **modul offline** (baca/analisis), bukan operasi ECU.

---

## 2. Kategori A — Dapat diterapkan langsung

### A1. Parser XDF 1.60/1.70 (subset)

- **Yang diterapkan:** `XDFFORMAT`, `XDFHEADER` (region/default/category), `XDFTABLE`
  (z, x, y), `XDFCONSTANT`, `XDFFLAG`, `XDFPATCH`, `MATH`, `EMBEDDEDDATA`,
  `CATEGORYMEM`, `embedinfo`/`linkobjid`.
- **Bukti:** 13 XDF terbuka, 287 tabel, 11 konstanta, 22 flag, 5 patch
  (`REPORTS/XDF_DEFINITION_INVENTORY.csv`).
- **Prototipe:** `PROTOTYPES/src/RevCore.Research.Core/Xdf/` — 46 self-test lulus.
- **Syarat integrasi:** parser harus menolak XDF terkunci (`05 22 97 00`) dengan pesan
  jelas; tidak ada dekripsi. Jangan mengimpor `DALINK` sebagai data sampai semantiknya
  terbukti.
- **Risiko:** rendah (read-only, input tervalidasi).
- **Status:** `TESTED_PASS` untuk 2 XDF; cakupan 13 XDF belum diuji seluruhnya.

### A2. Identifikasi BIN offline berbasis offset + ukuran

- **Yang diterapkan:** tabel offset ECM ID (`0x578`, `0x788`, `0x800`, `0x1AFEC`,
  `0x2E4E`, `0x2B72`, `0x7CD4`, `0x97CD`, `0x3D16C`), offset string versi
  (`0x577C`, `0x68AC`, dst.), dan skor keyakinan.
- **Bukti:** dump nyata KZR `010123` dan K1AA `01037A00AC`; tabel lima ECM ID
  (`CheksumKZR` IL).
- **Prototipe:** `Identification/BinIdentifier.cs`; dua sampel lulus.
- **Syarat integrasi:** hasil harus selalu menyertakan offset, ukuran file, dan
  tingkat keyakinan; konflik → `UNKNOWN`, bukan tebakan.
- **Risiko:** sedang (offset tidak universal; salah ID dapat menyesatkan pengguna).
- **Status:** `TESTED_PASS` 2 famili; generalisasi `UNKNOWN`.

### A3. Checksum KZR (Shindengen 384 KB)

- **Yang diterapkan:** jumlah 16-bit little-endian stride 4, field dinolkan,
  two's complement, patch ke file **baru**.
- **Bukti:** IL `CheksumKZR.Form1::Checksum`; 38 file diuji (31 valid, 7 invalid).
- **Prototipe:** `Checksum/KzrChecksum.cs`; kasus valid `0xFFFF` dan invalid
  `0x8744 → 0xB36E` lulus, input tidak berubah.
- **Syarat integrasi:** hanya untuk ECM ID yang tercantum (`010123`, `010173`,
  `010169`, `0101BE`, `0101AE`) dan ukuran 384 KB; alamat `0x2BB70`.
- **Risiko:** tinggi bila dipakai di luar keluarga; checksum salah dapat membuat ECU
  menolak image. Wajib konfirmasi sebelum menulis.
- **Status:** `TESTED_PASS` (offline), `HARDWARE_PENDING` (diterima ECU).

### A4. Utilitas skala TPS/AFR yang digerakkan data

- **Yang diterapkan:** fungsi murni `raw/divisor`, clamp, dan `AFR = raw/divisor`,
  `lambda = AFR/14.7` — tanpa tabel tersembunyi.
- **Bukti:** divisor XDF `10`, `7.43`, `13.286`, `9.4`; AFR `9.5`, `9`, `8.725`,
  `10`, `7.71` (`REPORTS/SENSOR_SCALING_REFERENCE.csv`).
- **Prototipe:** `Conversions/Scales.cs`; 10 assertion lulus.
- **Syarat integrasi:** divisor dan satuan harus berasal dari XDF/descriptor, bukan
  konstanta global. Tampilkan `UNKNOWN` bila tidak ada definisi.
- **Risiko:** rendah bila data-driven; tinggi bila di-hardcode per model.
- **Status:** `TESTED_PASS` (aritmetika).

### A5. Pola validasi offline & pelaporan

- **Yang diterapkan:** pipeline `load → identify → parse XDF → baca tabel → cek
  checksum → laporkan`, dengan exit code dan output yang dapat diaudit.
- **Bukti:** CLI prototipe (`identify`, `checksum`, `xdf list/read/export`).
- **Syarat integrasi:** pertahankan pemisahan Core/CLI/UI; jangan mencampur I/O
  hardware dengan logika parsing.
- **Risiko:** rendah.
- **Status:** `TESTED_PASS`.

---

## 3. Kategori B — Perlu adaptasi

### B1. Resolusi axis tertaut (`embedinfo type="3"`)

Prototipe sudah menyelesaikan link ke tabel target dan menerapkan equation target.
Namun `mmedmajorstridebits`/`mmedminorstridebits` belum diimplementasikan; tabel
dengan stride bukan 0 (mis. axis `-32`) perlu pengujian tambahan. **Status:**
`PROTOTYPED`; perlu uji pada seluruh 13 XDF dan tabel non-kontigu.

### B2. Registry identifikasi multi-famili

Saat ini hanya KZR dan K1AA yang diverifikasi. Registry perlu skema
`{family, size, id_offset, id_length, version_offset, checksum}` dengan sumber bukti
per entri. Tanpa registry, jangan menambah offset baru. **Status:** `PROTOTYPED`
(2 entri), sisanya `UNKNOWN`.

### B3. Model descriptor live data

Skema `{ecu_family, firmware, profile, channels[]}` dengan offset/tipe/skala per
kanal. Isi kanal masih `UNKNOWN`; yang dapat diintegrasikan sekarang hanya skema dan
aturan penolakan frame. **Status:** `ANALYZED` (skema), isi `UNKNOWN`.

### B4. Abstraksi transport

Antarmuka `ITransport` (open/close/read/write/baud/bitmode/purge/queue) sudah ada,
tetapi implementasi D2XX hanya untuk Windows dan belum dieksekusi. Untuk RevCore
(Android/APK berdasarkan artefak rilis yang tercatat di memori proyek), D2XX native
tidak tersedia tanpa root; perlu USB Host + driver serial atau adapter yang
mengekspos protokol di firmware. **Status:** `HARDWARE_PENDING`; keputusan platform
adalah keputusan pemilik proyek.

### B5. Alur edit tabel + re-checksum

Prototipe dapat membaca tabel dan mem-patch checksum, tetapi belum ada editor,
undo, atau validasi ukuran/dimensi saat menulis. Perlu desain “edit → diff → hitung
ulang checksum → verifikasi → simpan salinan baru”. **Status:** `PROTOTYPED`
(komponen), alur end-to-end belum.

---

## 4. Kategori C — Perlu riset lanjutan

| No | Topik | Yang kurang | Prasyarat |
|---|---|---|---|
| C1 | Frame/service K-Line | service ID, header, panjang, checksum frame, baud, timing, init sequence | bench ECU + izin pemilik |
| C2 | Security access (seed/key) | algoritma, urutan, sumber entropy | otorisasi eksplisit; batas etis |
| C3 | Checksum keluarga non-KZR | `checksum8bit`, `checksum8bitHonda`, ChecksumCalculator | dump + dokumentasi/IL tambahan |
| C4 | Recovery ECU | perintah, kriteria `RECOVER_NEW` vs `RECOVER_OLD`, ambang tegangan/RPM | bench + catu daya terkendali |
| C5 | Live data offset | peta kanal per profil | capture frame + stimulasi input |
| C6 | Perilaku TunerPro/ADX | ekstraksi installer, format ADX | persetujuan lingkungan terisolasi |

Semua item C berstatus `UNKNOWN` atau `HARDWARE_PENDING`; tidak boleh masuk roadmap
sebagai fitur yang “sudah didukung”.

---

## 5. Kategori D — Tidak relevan

| No | Item | Alasan |
|---|---|---|
| D1 | Pin Out ECU | dokumentasi pinout; tidak ada algoritma |
| D2 | OCX + Python runtime | dependensi runtime, bukan kapabilitas |
| D3 | FTDI CDM / REMAP CABLE DRIVER (installer) | deployment driver, bukan kode aplikasi |
| D4 | Smart Key / HISS | hanya satu nama symbol; `NOT_FOUND`; di luar batas etis |
| D5 | Lisensi/aktivasi (CheksumCalculator, TunerPro `.tpk`) | tidak relevan dan tidak boleh dibobol |

---

## 6. Larangan integrasi

1. Jangan menambahkan operasi tulis/erase/recovery ke RevCore berdasarkan work order
   ini; belum ada bukti hardware.
2. Jangan memakai nama fungsi sebagai bukti fitur (`fast_write`, `only_main_table`,
   `pgmfi_set_hiss_key_variables`).
3. Jangan menyalin kode pihak ketiga (FTD2XX_NET, Python `ftd2xx`) tanpa kajian
   lisensi; implementasikan wrapper sendiri dari dokumentasi API publik.
4. Jangan men-decode/menulis XDF terkunci atau membuat unlocker.
5. Jangan mengklaim dukungan kendaraan dari nama file XDF.

---

## 7. Urutan integrasi yang disarankan

1. Parser XDF + pembaca BIN + checksum KZR (modul offline, tanpa UI).
2. Registry identifikasi dengan bukti per entri.
3. Editor tabel read-only + ekspor CSV untuk verifikasi.
4. Alur edit + re-checksum dengan salinan baru.
5. Transport hanya setelah keputusan platform dan uji bench.
6. Live data dan write/erase setelah C1–C5 selesai.

---

## 8. Bukti

- `TECHNICAL_FINDINGS/` — 17 laporan.
- `PROTOTYPES/RESULTS/PROTOTYPE_RESULTS.md` — hasil build/uji.
- `REPORTS/SENSOR_SCALING_REFERENCE.csv` — 48 baris skala.
- `REPORTS/XDF_DEFINITION_INVENTORY.csv` — 325 definisi.
