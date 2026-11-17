# REVCORE TECHNICAL GAP ANALYSIS — BE-09

**Tanggal:** 17 November 2026
**Cakupan:** kesenjangan antara bukti BE-09 dan kebutuhan tool ECU offline/online.
**Batas:** source RevCore tidak diaudit. Karena itu “gap” di bawah adalah gap relatif
terhadap kapabilitas yang secara umum diperlukan, bukan penilaian atas kode RevCore.

Jenis gap:

- **G1 — Bukti:** perilaku belum terbukti dari artefak (IL/symbol/XDF/dump).
- **G2 — Implementasi:** algoritma sudah terbukti tetapi belum menjadi kode produksi.
- **G3 — Verifikasi:** kode sudah ada tetapi belum diuji pada perangkat/hardware.
- **G4 — Keputusan pemilik:** pilihan platform, lisensi, atau lingkup fitur.

---

## 1. Matriks gap per kapabilitas

| # | Kapabilitas | Bukti BE-09 | Prototipe | Gap utama | Jenis | Verifikasi yang diperlukan | Prioritas |
|---|---|---|---|---|---|---|---|
| 1 | Identifikasi BIN offline | Offset KZR `0x578`, K1AA `0x800`, versi `0x577C`/`0x68AC`; 5 ECM ID | `BinIdentifier` | Offset famili lain belum dipetakan; generalisasi belum diuji | G1/G2 | Uji seluruh 700 BIN; cocokkan dengan nama file | P0 |
| 2 | Parsing XDF 1.60/1.70 | 13 XDF; 287 tabel | `XdfParser` | 161 XDF terkunci tidak dapat dibaca (dan tidak boleh di-crack) | G1 | Uji 13 XDF; bandingkan hasil dengan pembacaan manual | P0 |
| 3 | Pembacaan tabel + equation | Contoh K1AA 35×29, AFR, ignition | `TableReader` | Stride `major/minor` belum diterapkan; tabel non-kontigu belum diuji | G2 | Uji tabel dengan `mmedmajorstridebits` ≠ 0 | P0 |
| 4 | Axis tertaut | `embedinfo type="3"` → `0x4F1D`, `0x2D94` | Resolusi link + equation target | Semantik `DALINK` (hash/objid) belum dipetakan | G1/G2 | Uji seluruh axis link di 13 XDF | P1 |
| 5 | Checksum KZR | IL `CheksumKZR`; 38 file | `KzrChecksum` | Diterima ECU belum diuji | G3 | Bench ECU / validasi tool resmi | P0 (offline), P3 (hardware) |
| 6 | Checksum famili lain | Hanya nama `checksum8bit`, `checksum8bitHonda`; ChecksumCalculator UI | Tidak ada | Algoritma, alamat, rentang tidak diketahui | G1 | IL/native analysis tambahan + dump | P1 |
| 7 | Alur edit + re-checksum | Checksum terbukti; XDF menyediakan alamat | Patch checksum saja | Belum ada editor, diff, validasi dimensi, undo | G2 | Uji end-to-end pada salinan BIN | P1 |
| 8 | Identifikasi runtime | Symbol `GetEcmid`, `detect_ecu_state`, `ping` | Tidak ada | Frame, baud, timing, respons tidak diketahui | G1 | Bench ECU | P2 |
| 9 | Baca flash | Pipeline `ReadFlashHelper`, `pgmfi_read_flash_bytes` | Tidak ada | Service ID, chunk size, timeout tidak diketahui | G1 | Bench ECU | P2 |
| 10 | Tulis/erase | `pgmfi_flash_write`, `pgmfi_flash_erase`, `do_erase_wait` | Tidak ada | Frame, urutan security, ambang tegangan | G1 | Bench + catu daya stabil | P3 |
| 11 | Recovery | State `RECOVER_NEW/OLD` | Tidak ada | Perintah, kriteria, citra recovery | G1 | Bench; risiko brick tinggi | P3 |
| 12 | Live data | 23 nama kanal; format `struct` kandidat | Tidak ada | Offset/tipe/skala per kanal | G1 | Capture + stimulasi input | P2 |
| 13 | Smart key / HISS | Satu symbol setter | Tidak ada | Tidak ada bukti baca/registrasi | G1/G4 | Di luar lingkup etis saat ini | — |
| 14 | Transport FTDI | `ftd2xx.dll` 90 export; 11 API ANALIST | `D2xxTransport` (tidak dieksekusi) | Parameter aktual (baud, bitmode, timeout) | G1/G3 | Uji adapter pada OS target | P2 |
| 15 | Protokol K-Line | Nama modul dan operasi | Tidak ada | Tidak ada bukti ISO 9141/KWP/UDS | G1 | Logic analyzer + bench | P2 |
| 16 | Keamanan/seed-key | Symbol `do_seed_key_challenge` | Tidak ada | Algoritma dan urutan tidak diketahui | G1/G4 | Otorisasi eksplisit | — |

---

## 2. Gap yang menghalangi integrasi sekarang

1. **Cakupan identifikasi (G1).** Hanya 2 famili yang diuji. Menambah offset tanpa
   bukti berisiko salah identifikasi.
2. **Stride tabel (G2).** Banyak XDF memakai `mmedmajorstridebits` negatif; prototipe
   belum menerapkannya, sehingga tabel tertentu dapat terbaca tidak berurutan.
3. **Checksum non-KZR (G1).** Tanpa algoritma, file famili lain tidak dapat
   diverifikasi setelah edit.
4. **Keputusan platform transport (G4).** D2XX native adalah solusi Windows; platform
   RevCore menentukan apakah perlu USB Host, adapter firmware, atau pendekatan lain.

---

## 3. Gap yang tidak menghalangi modul offline

Parser XDF, pembaca BIN, checksum KZR, dan utilitas skala tidak bergantung pada
hardware. Keempatnya dapat diintegrasikan sebagai modul offline murni setelah
review kode, tanpa menunggu bench ECU.

---

## 4. Risiko gap bila dipaksakan

| Gap | Bila diabaikan | Dampak |
|---|---|---|
| Offset identifikasi belum terbukti | ID salah | checksum/alamat salah, image ditolak |
| Stride belum diterapkan | sel tertukar | nilai tabel kacau, keputusan tuning salah |
| Checksum non-KZR | file tidak valid | ECU menolak atau perilaku tidak aman |
| Protokol belum terbukti | frame salah | ECU tidak merespons; risiko state tidak dikenal |
| Write/recovery tanpa bench | brick | kerusakan ECU dan kerugian |
| Live data offset ditebak | kanal tertukar | diagnosis salah |

---

## 5. Rekomendasi penutupan gap

| Gap | Cara menutup | Bukti yang harus disimpan |
|---|---|---|
| Identifikasi | uji 700 BIN, cocokkan nama vs offset | tabel hasil + hash |
| Stride | implementasi + uji tabel stride ≠ 0 | diff nilai sebelum/sesudah |
| Checksum lain | analisis IL/native + dump uji | algoritma + vektor uji |
| Protokol | capture bench dengan izin | log frame hex + timing |
| Live data | stimulasi input + diff byte | descriptor per profil |
| Transport | uji adapter pada OS target | log API + parameter |

---

## 6. Kesimpulan

BE-09 menutup gap **offline** secara memadai untuk KZR/K1AA dan format XDF.
Gap terbesar ada pada **protokol runtime, checksum famili lain, dan verifikasi
hardware** — semuanya berstatus `UNKNOWN`/`HARDWARE_PENDING` dan tidak boleh
diklaim sebagai fitur yang sudah berfungsi.
