# BE-10 — LAPORAN AKHIR RISET TEKNIS MENDALAM

**Work Order:** BE-10 — ADX + 3D Chart Graph + ECU Software
**Tanggal:** 17 November 2026
**Ruang kerja:** `C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH`
**Baseline:** BE-09 (`REVCORE_EXTERNAL_ECU_RESEARCH`) — tidak diulang, tidak diubah

---

## Ringkasan satu paragraf

BE-10 menemukan bahwa ADX adalah kontainer terenkripsi dua-famili (KEIHIN `0x03`, SHINDENGEN `0x02`) dengan tata letak yang dapat dibuktikan sampai batas payload, tetapi isinya tetap tertutup. Sumber utama baru, **3D Chart Graph / Remap Honda K-Line** (C# WinForms, 31.052 baris), membuka lapisan yang sebelumnya `UNKNOWN` di BE-09: inisialisasi FTDI, format frame K-Line, katalog perintah, 45 kanal live data dengan offset pasti, checksum Keihin/Shindengen, seed/key, urutan tulis flash, recovery, dan Smart Key EEPROM. Prototipe .NET 8 mereproduksi tabel BIN, frame, checksum, live-data, dan inspeksi ADX; **26/26 self-test lulus**, **5/5 BIN nyata tervalidasi**, dan **45 kanal** terkatakan. Yang belum: isi ADX/XDF terkunci, prosedur baca BIN penuh, dan seluruh validasi hardware.

---

## 1. Apa yang ditemukan

### 1.1 ADX

- Folder `ADX-D2 TECH` berisi **2 file berbeda**; total di dataset **3 file + 1 arsip 7z = 2 konten unik**.
- Layout terbukti: magic `05 22 97 00`; 127 nol; metadata 129 byte; 4 nol; **blok konstan 43 byte**; tag famili; payload.
- KEIHIN: payload 39.891 byte, tag `0x03`, entropy 7,9954, printable 0,3752.
- SHINDENGEN: payload 23.472 byte, tag `0x02`, entropy 7,993.
- Blok 43 byte identik pada kedua file; perbedaan pertama adalah tag di `0x133`.
- Tidak ada signature zlib/gzip/zip di awal payload.

### 1.2 Hubungan ADX–XDF

- XDF terkunci dan ADX berbagi **prefix 132 byte** (magic, nol, penanda `0x64`).
- Keduanya punya 4 nol di `0x104–0x107`.
- Di `0x108` berpisah: ADX memakai blok konstan 43 byte; XDF langsung high-entropy.
- Ini membuktikan satu keluarga kontainer, tetapi ADX adalah varian dengan tag famili.

### 1.3 3D Chart Graph

- WinForms .NET 4.8, C# 7.3, 27 file, **31.052 baris**.
- **152 model** map, **169 ECU ID** (97 Keihin/72 Shindengen), **154 BIN** tertanam.
- Tabel: `uint16` row-major; TPS `raw/10`, RPM `raw/kon`, fuel `raw/1000`; 4 offset big-endian.
- FTDI: open 0, purge 3, 8N1, **10.400**, timeout 50 ms, latency 8 ms, wake bit-bang; fast write **62.500**.
- Frame: `[format][total_length][data][checksum]`; checksum Honda `(sum^FF)+1`.
- Perintah: ID `72 07 72 00 00 05 10`; live dat10/11/13/16/17/20/D1; keepalive; flash count.
- Live data: **45 kanal** dengan byte index dan rumus.
- Checksum Keihin (8-bit) dan Shindengen (32-bit, marker `D0 07`).
- Seed/key Shindengen: `c1*(seed+c0) + (seed%c2 atau seed)`.
- Tulis: pra-tulis 9 frame per famili; blok 128 byte; H8C 64 byte; checksum berlapis.
- Recovery: ID berakhiran `0000`; RH850B shift 6 byte.
- Smart Key: challenge Keihin/Shindengen; baca 256 halaman × 2 byte.
- Lisensi: `lic.kye` 160 byte + serial mesin; gerbang di load/tulis/koneksi.
- **Tidak ada** rutin baca BIN penuh; **tidak ada** referensi ADX/XDF.

---

## 2. Mekanisme yang berhasil direkonstruksi

| Mekanisme | Tingkat bukti |
|---|---|
| Kontainer ADX (layout, tag, payload) | `STATICALLY_ANALYZED` + `SAMPLE_TEST_PASSED` |
| Format frame dan checksum Honda | `STATICALLY_ANALYZED` + `SAMPLE_TEST_PASSED` (vektor) |
| Decoding 45 kanal live data | `STATICALLY_ANALYZED` |
| Checksum Keihin/Shindengen | `STATICALLY_ANALYZED` + `SAMPLE_TEST_PASSED` (vektor) |
| Seed/key Shindengen | `STATICALLY_ANALYZED` + `SAMPLE_TEST_PASSED` (aritmetika) |
| Pra-tulis/tulis flash | `STATICALLY_ANALYZED` |
| Recovery state machine | `STATICALLY_ANALYZED` |
| Smart Key EEPROM read | `STATICALLY_ANALYZED` |
| Tabel BIN + endianness | `SAMPLE_TEST_PASSED` (5 BIN) |
| Lisensi mesin | `STATICALLY_ANALYZED` (tanpa membocorkan rahasia) |

Yang **tidak** direkonstruksi: cipher ADX, isi XDF terkunci, prosedur baca ECU, dan seluruh perilaku hardware.

---

## 3. Prototipe yang dibuat

`PROTOTYPES\src\BE10Tools` (.NET 8, tanpa dependensi eksternal):

- `AdxInspector` — metadata kontainer, tanpa dekripsi.
- `MapDatabase` + `BinTableReader` — 152 model, baca/tulis tabel, endianness, export CSV, compare.
- `Interpolation` — bilinear/nearest.
- `HondaProtocol` — frame, checksum Honda/Keihin/Shindengen, seed/key.
- `LiveData` — decoder dat10/11/13/16/17/20/D1.
- `SimpleFormula` — evaluator ekspresi.
- `TestRunner` — 26 tes dengan hash sebelum/sesudah.
- CLI: `selftest`, `adx`, `validate`, `catalog`, `compare`.

Build: **0 warning, 0 error**.

---

## 4. Pengujian yang dilakukan

| Uji | Hasil |
|---|---|
| Self-test | **26/26 lulus** |
| Validasi tabel BIN | **5/5 lulus**, termasuk big-endian |
| Katalog sensor | **45 kanal** dihasilkan |
| Export/import grafik | 35×29, nilai ujung sama |
| Edit pada salinan | nilai berubah, hash sumber tetap |
| Compare BIN | 131.901 byte berbeda terdeteksi |
| Stabilitas hash input | 9 file `UNCHANGED` |

Setiap uji mencatat input, metode, output, expected, actual, status, dan hash sebelum/sesudah. Tidak ada file sumber yang diubah.

---

## 5. Apa yang tidak ditemukan

| Item | Status |
|---|---|
| Isi ADX | `BLOCKED_BY_ACCESS_REQUIREMENT` |
| Isi XDF terkunci | `BLOCKED_BY_ACCESS_REQUIREMENT` |
| Rutin baca BIN penuh di 3D | `NOT_FOUND_AFTER_MEANINGFUL_SEARCH` |
| Lapisan ISO 9141/KWP/UDS | `NOT_FOUND_AFTER_MEANINGFUL_SEARCH` |
| Checksum famili lain | `UNKNOWN_AFTER_ANALYSIS` |
| Satuan fuel/MAP/ADV | `UNKNOWN_AFTER_ANALYSIS` |
| Arti flash count | `UNKNOWN_AFTER_ANALYSIS` |

---

## 6. Apa yang terblokir

- **ADX/XDF terkunci**: memerlukan kunci/alat resmi dan izin terpisah. Tidak ada brute force.
- **Tool packed** (PRO Remap_BE, SCANNER HONDA): tidak di-unpack; isi tidak diklaim.
- **Payload HondaECU**: onefile/Cython tidak diekstrak.
- **Lisensi**: dianalisis sebagai mekanisme, tetapi nilai kunci/isi file tidak direproduksi.

---

## 7. Apa yang memerlukan hardware

| Kebutuhan | Mengapa |
|---|---|
| Kabel FTDI + ECU | Validasi transport, ID, live data |
| Bench + catu daya stabil | Uji tulis/erase/recovery |
| Logika analyzer | Ukur wake pulse/timing |
| ECU cadangan | Uji recovery dan seed/key |
| Izin pemilik | Semua di atas |

Tidak ada perintah yang dikirim ke ECU fisik dalam BE-10.

---

## 8. Kontribusi baru dibanding BE-09

| Area | BE-09 | BE-10 |
|---|---|---|
| ADX | Dihitung sebagai file terkunci | Layout, tag, blok 43 byte, duplikat, hubungan XDF |
| 3D Chart Graph | Tidak dianalisis | Source lengkap 31k baris dianalisis |
| Live data | 23 nama, offset UNKNOWN | 45 kanal dengan offset/rumus |
| Protokol | Frame UNKNOWN | Frame, perintah, timeout, wake-up |
| Checksum | Hanya KZR | + Keihin + Shindengen |
| Seed/key | Tidak ada | Aritmetika Shindengen |
| Tulis/recovery | Konseptual | Urutan frame, fast write, recovery |
| Tabel BIN | Pemetaan XDF | Parser mandiri, 5 BIN tervalidasi, BE |
| Smart Key | NOT_FOUND | Challenge/frame EEPROM terbaca statis |
| Prototipe | 46 tes | 26 tes baru, fokus BE-10 |

---

## 9. Kandidat integrasi RevCore

**Sekarang (P0):** pembaca tabel BIN, registry 152 model, export/import CSV, compare, inspeksi ADX metadata, formula.

**P1:** decoder 45 kanal, checksum Keihin/Shindengen, seed/key (test-only), codec frame, database 169 ID.

**P2:** transport FTDI, ID runtime, sinkronisasi live data, timing — setelah bench.

**P3/tidak disarankan:** tulis/erase/recovery, Smart Key tulis, bypass lisensi, dekripsi ADX.

Detail: `BE10_REVCORE_INTEGRATION_RECOMMENDATIONS.md`.

---

## 10. Batasan dan kejujuran status

- `STATICALLY_ANALYZED` berarti kode/artefak dibaca, bukan dijalankan.
- `SAMPLE_TEST_PASSED` berarti prototipe lulus pada input yang tercatat, bukan ECU.
- `HARDWARE_PENDING` berarti tidak ada klaim keberhasilan hardware.
- Tidak ada klaim bahwa ADX dapat dibuka.
- Tidak ada klaim bahwa checksum sudah diterima ECU.
- Tidak ada klaim bahwa 152 model sudah tervalidasi; baru 5.

---

## 11. Kepatuhan keamanan

Work order BE-10 dipatuhi:

1. Tidak menjalankan EXE/installer/BAT/CMD/VBS.
2. Tidak menjalankan DLL/OCX.
3. Analisis statis lebih dulu.
4. Windows Defender tidak dimatikan.
5. Tidak memasang driver.
6. Tidak memakai remote access.
7. Source asli tidak diubah.
8. Proyek RevCore tidak diubah.
9. Tidak menghapus file.
10. Tidak mengunggah source donasi.
11. Tidak menyalin kredensial/kunci/lisensi ke laporan.
12. Tidak mengirim perintah ke ECU fisik.

---

## 12. Indeks bukti

- `BE10_ADX_ANALYSIS.md`
- `BE10_3D_CHART_SOURCE_ANALYSIS.md`
- `BE10_ECU_PROTOCOL_FINDINGS.md`
- `BE10_BIN_XDF_ADX_RELATIONSHIP.md`
- `BE10_SOFTWARE_DEEP_ANALYSIS.md`
- `BE10_PROTOTYPE_RESULTS.md`
- `BE10_REVCORE_INTEGRATION_RECOMMENDATIONS.md`
- `BE10_TECHNICAL_GAP_ANALYSIS.md`
- `BE10_RESEARCH_STATUS.csv`
- `BE10_ARTIFACT_INDEX.md`
- `BE10_EXECUTIVE_SUMMARY.md`
- `REPORTS\BE10_SENSOR_LIVE_DATA_CATALOG.csv`
- `REPORTS\BE10_SHA256_MANIFEST.csv`
- `PROTOTYPES\RESULTS\SELFTEST.txt`
- `PROTOTYPES\RESULTS\BE10_PROTOTYPE_TESTS.csv`
- `PROTOTYPES\RESULTS\BE10_TABLE_VALIDATION.csv`
- `ANALYSIS\ADX_XDF_LAYOUT_PROOF.txt`
- `README.md`
