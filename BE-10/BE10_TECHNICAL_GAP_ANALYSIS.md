# BE-10 — ANALISIS CELAH TEKNIS

**Tujuan:** menyebutkan celah secara spesifik, bukan umum. Setiap celah memuat: yang sudah diketahui, yang masih hilang, cara menutup, dan status.

---

## 1. Ringkasan prioritas

| # | Celah | Dampak | Status | Prioritas |
|---:|---|---|---|---|
| G1 | Isi ADX (cipher/kunci/metadata) | Tidak bisa memakai ADX | `BLOCKED_BY_ACCESS_REQUIREMENT` | rendah (di luar izin) |
| G2 | Isi XDF terkunci (161 file) | Tidak bisa membaca definisi terkunci | `BLOCKED_BY_ACCESS_REQUIREMENT` | rendah |
| G3 | Prosedur baca BIN dari ECU | Tidak bisa backup firmware | `NOT_FOUND_AFTER_MEANINGFUL_SEARCH` | **tinggi** |
| G4 | Validasi checksum pada firmware nyata | Risiko bricking saat tulis | `STATICALLY_ANALYZED` | **tinggi** |
| G5 | Verifikasi live data pada kendaraan | Skala bisa salah | `HARDWARE_PENDING` | tinggi |
| G6 | Seed/key & recovery per varian | Recovery bisa gagal | `HARDWARE_PENDING` | tinggi |
| G7 | Timing fisik K-Line | Koneksi tidak stabil | `HARDWARE_PENDING` | sedang |
| G8 | Arti unit tabel (fuel/MAP/ADV) | Salah tafsir map | `UNKNOWN_AFTER_ANALYSIS` | sedang |
| G9 | Pemetaan 154 BIN ↔ 152 model | Model tidak cocok | `STATICALLY_ANALYZED` | sedang |
| G10 | Flash count & status ECU | Diagnostik terbatas | `UNKNOWN_AFTER_ANALYSIS` | rendah |
| G11 | Smart Key EEPROM | Risiko keamanan | `STATICALLY_ANALYZED` | rendah (tidak diaktifkan) |
| G12 | Lisensi/proteksi | Tidak relevan integrasi | `STATICALLY_ANALYZED` | rendah |

---

## 2. G1 — ADX

**Diketahui:** magic, header 132 byte, metadata 129 byte, blok konstan 43 byte, tag `0x03`/`0x02`, payload 39.891/23.472, entropy ~7,99, tanpa signature kompresi di awal payload.

**Hilang:** cipher, mode, kunci, KDF, struktur metadata, apakah payload berisi definisi tabel atau data lain.

**Cara menutup:** hanya dengan alat resmi/berlisensi atau kunci dari pemilik; memerlukan izin terpisah. Tidak boleh brute force.

**Status:** `BLOCKED_BY_ACCESS_REQUIREMENT`.

---

## 3. G2 — XDF terkunci

**Diketahui:** prefix 132 byte sama dengan ADX; divergensi di `0x108`; XDF terkunci tidak punya blok konstan/tag.

**Hilang:** isi 161 XDF terkunci; apakah kuncinya sama dengan ADX.

**Cara menutup:** pembukaan oleh pemilik atau alat resmi; bukan target BE-10.

**Status:** `BLOCKED_BY_ACCESS_REQUIREMENT`.

---

## 4. G3 — Baca BIN dari ECU

**Diketahui:** 3D Chart Graph hanya membaca ECM ID (`72 07 72 00 00 05 10`) dan flash count; tidak ada loop baca flash.

**Hilang:** service baca memori, alamat awal/akhir, ukuran blok, format transfer, timeout, apakah ECU mengizinkan baca tanpa security.

**Cara menutup:** analisis tool lain yang memiliki fitur baca (HondaECU/PRO Remap) jika source tersedia; atau tangkap lalu lintas K-Line pada bench dengan izin. Ini pekerjaan hardware.

**Status:** `NOT_FOUND_AFTER_MEANINGFUL_SEARCH` untuk 3D; `HARDWARE_PENDING` untuk pembuktian.

---

## 5. G4 — Checksum pada firmware nyata

**Diketahui:** algoritma Keihin dan Shindengen dari source; lulus vektor sintetis.

**Hilang:** offset checksum per BIN, apakah checksum dihitung atas seluruh image atau rentang tertentu, apakah ada checksum kedua, dan apakah hasil patch diterima ECU.

**Cara menutup:** petakan ECU ID → checksum offset dari database; jalankan checksum pada BIN asli dan bandingkan dengan nilai yang sudah ada; verifikasi di bench.

**Status:** `STATICALLY_ANALYZED`; belum `SAMPLE_TEST_PASSED` pada firmware.

---

## 6. G5 — Live data

**Diketahui:** 45 kanal dengan byte index/rumus; dua skala O2 (`/195.195195` dan `/50.9937`) ada di source.

**Hilang:** verifikasi bahwa frame ID dan offset cocok untuk setiap model; satuan MAP/ADV; apakah AFR estimasi cukup akurat; perilaku saat sensor gagal.

**Cara menutup:** log frame dari ECU berjalan dan bandingkan dengan dashboard/referensi; uji tiap varian dat10/11/13/16/17.

**Status:** `HARDWARE_PENDING`.

---

## 7. G6 — Seed/key dan recovery

**Diketahui:** aritmetika key Shindengen; recovery jika ID berakhiran `0000`; pergeseran RH850B 6 byte.

**Hilang:** varian V850 vs RH850 vs RH850B, kapan recovery key dipakai, apakah ada challenge tambahan, dan apakah ECU menolak key yang salah dengan aman.

**Cara menutup:** bench dengan ECU cadangan; uji setiap varian; catat respons.

**Status:** `HARDWARE_PENDING`.

---

## 8. G7 — Timing fisik

**Diketahui:** 10.400 8N1, timeout 50 ms, latency 8 ms, wake bit-bang `0x00`/`0x01`, fast write 62.500.

**Hilang:** durasi pulsa wake sebenarnya, jeda antar-frame, toleransi ECU, pengaruh kabel.

**Cara menutup:** logika analyzer pada pin K-Line; ukur saat connect dan write.

**Status:** `HARDWARE_PENDING`.

---

## 9. G8 — Arti unit tabel

**Diketahui:** fuel `raw/1000`, TPS `raw/10`, RPM `raw/kon`.

**Hilang:** satuan fuel (ms? mg/stroke?), satuan MAP mentah, apakah ADV sudah derajat, apakah TPS2 persen atau posisi.

**Cara menutup:** dokumentasi pabrikan atau korelasi dengan log; jangan mengklaim satuan tanpa bukti.

**Status:** `UNKNOWN_AFTER_ANALYSIS`.

---

## 10. G9 — Pemetaan BIN ↔ model

**Diketahui:** 152 model, 154 BIN; 5 model tervalidasi.

**Hilang:** 149 model belum diuji; beberapa BIN mungkin tidak punya entri; nama resource bisa tidak unik.

**Cara menutup:** jalankan validator pada semua pasangan yang cocok; laporkan yang gagal, jangan dipaksa.

**Status:** `STATICALLY_ANALYZED`; 5 `SAMPLE_TEST_PASSED`.

---

## 11. G10 — Flash count/status

**Diketahui:** perintah `7D 06 01 01 03 78` dan `7B 06 02 01 03 79`; byte 6.

**Hilang:** arti angka (jumlah tulis? siklus?), reset, dan apakah bisa diubah.

**Status:** `UNKNOWN_AFTER_ANALYSIS`.

---

## 12. G11 — Smart Key

**Diketahui:** challenge, frame baca halaman, 256×2 byte.

**Hilang:** layout EEPROM, arti tiap halaman, prosedur tulis yang aman.

**Status:** `STATICALLY_ANALYZED`; tidak diaktifkan.

---

## 13. G12 — Lisensi

**Diketahui:** `lic.kye` 160 byte, AES, serial prosesor+disk; gerbang di `Form1_Load`/tombol tulis/koneksi.

**Hilang:** detail KDF dan format file (sengaja tidak direproduksi).

**Status:** `STATICALLY_ANALYZED`; tidak relevan untuk integrasi RevCore.

---

## 14. Celah yang tidak bisa ditutup dalam BE-10

- ADX/XDF terkunci: butuh otorisasi dan alat resmi.
- Baca ECU: butuh hardware.
- Validasi checksum/live data: butuh ECU.
- Smart Key: butuh ECU dan pertimbangan etis.

Semua dinyatakan terbuka, bukan disembunyikan.
