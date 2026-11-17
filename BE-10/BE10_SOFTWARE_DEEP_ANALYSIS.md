# BE-10 — ANALISIS MENDALAM 14 TARGET SOFTWARE (BE-09 → BE-10)

**Prinsip:** BE-10 tidak mengulang inventaris BE-09. Setiap target hanya didalami bila relevan dengan pertanyaan BE-10 (FTDI, ADX, BIN/XDF/map editor, checksum lintas famili, sensor/live data, baca/tulis/recovery, identifikasi ECU). Yang tidak menghasilkan bukti baru dinyatakan apa adanya.

**Target baru di BE-10:** `3D Chart Graph / Remap Honda K-Line` — bukan bagian dari 14 target BE-09, tetapi menjadi sumber teknis utama BE-10. Analisisnya ada di `BE10_3D_CHART_SOURCE_ANALYSIS.md`.

---

## 1. Tabel status

| # | Target | Status BE-09 | Tindakan BE-10 | Status BE-10 | Bukti / catatan |
|---:|---|---|---|---|---|
| 1 | HondaECU 3.5.5.2 | ANALYZED (symbol Cython; payload onefile UNKNOWN) | Tidak ada source baru; tidak dijalankan | **UNKNOWN_AFTER_ANALYSIS** untuk payload | Struktur Cython tetap; tidak diklaim |
| 2 | HondaECU 3.3.0 | FOUND | Tidak ada ekstraksi baru | **UNKNOWN_AFTER_ANALYSIS** | Payload tetap tidak diekstrak |
| 3 | HondaECU 3.0.2 | FOUND | Tidak ada ekstraksi baru | **UNKNOWN_AFTER_ANALYSIS** | Sama |
| 4 | PRO Remap_BE | FOUND (packed) | Tidak di-unpack; hanya metadata | **BLOCKED_BY_ACCESS_REQUIREMENT** | Isi tidak diklaim |
| 5 | SCANNER HONDA | FOUND (Enigma Protector) | Tidak di-unpack | **BLOCKED_BY_ACCESS_REQUIREMENT** | Isi tidak diklaim |
| 6 | ANALIST Pro 5.1 | ANALYZED (logika obfuscated; hanya referensi FTD2XX_NET) | Cross-check pola D2XX dengan 3D; tidak ada bukti baru di dalam ANALIST | **STATICALLY_ANALYZED** (permukaan) | 11 API D2XX dari BE-09 |
| 7 | TunerPro RT | FOUND (installer Inno Setup) | Tidak diekstrak; format XDF/ADX dipelajari dari file, bukan dari EXE | **UNKNOWN_AFTER_ANALYSIS** (perilaku EXE) | Format: `BE10_BIN_XDF_ADX_RELATIONSHIP.md` |
| 8 | Pin Out ECU | ANALYZED (pinout) | Tidak relevan algoritma | **STATICALLY_ANALYZED** | Dokumentasi pinout |
| 9 | CheksumCalculator | FOUND (algoritma UNKNOWN) | Tidak ada bukti baru | **UNKNOWN_AFTER_ANALYSIS** | — |
| 10 | CheksumKZR | ANALYZED (checksum + ECM ID dari IL) | Diperluas dengan checksum Keihin/Shindengen dari 3D | **STATICALLY_ANALYZED** | BE-09: checksum KZR; BE-10: dua famili lain |
| 11 | FTDI CDM Driver | FOUND (installer 2.12.36.4) | Tidak dijalankan/dipasang | **FOUND_IN_SOURCE** | Versi saja |
| 12 | REMAP CABLE DRIVER | FOUND (installer 2.12.28.2) | Tidak dijalankan/dipasang | **FOUND_IN_SOURCE** | Versi saja |
| 13 | FTD2XX_NET | ANALYZED (11 API) | Dikonfirmasi pola pemakaian di 3D: open/purge/bitmode/baud/timeout/latency/read/write | **STATICALLY_ANALYZED** | `BE10_ECU_PROTOCOL_FINDINGS.md` |
| 14 | OCX + Python runtime | FOUND | Tidak ada bukti baru | **FOUND_IN_SOURCE** | Dependensi runtime |

---

## 2. Yang benar-benar bertambah

### 2.1 Checksum lintas famili (target #10 + sumber 3D)

BE-09 hanya memulihkan checksum KZR: jumlah 16-bit little-endian stride 4, field dinolkan, two's complement.

BE-10 menemukan dua algoritma tambahan di `Form1.cs`:

- **Keihin**: jumlah byte dengan pengecualian field checksum; tulis `0 - sum` 8-bit (`Form1.cs:1721`).
- **Shindengen**: jumlah word 32-bit LE pada dua rentang, marker `D0 07`, tulis `0 - total` uint32 (`Form1.cs:1130`).

Keduanya diuji pada vektor sintetis (`CK-02`, `CK-03`), bukan pada firmware nyata. Ini menambah cakupan famili, tetapi **belum** memvalidasi checksum pada file BIN Honda asli.

### 2.2 FTDI (target #11–#13)

BE-09 hanya mengetahui 11 API dan installer. BE-10 memulihkan **urutan konfigurasi** dari 3D:

- open index 0, purge 3, bitmode `(0,0)`, 8N1, **10.400**, timeout 50 ms, latency 8 ms;
- wake bit-bang `(1,1)` tulis `0x00` lalu `0x01`, kembali ke UART;
- fast write **62.500**.

Ini bukan bukti tentang driver installer, tetapi bukti tentang **cara aplikasi memakai driver**. Status driver tetap `FOUND_IN_SOURCE`.

### 2.3 BIN/XDF/map editor (target #7, #9)

- TunerPro RT tetap tidak dianalisis EXE-nya.
- Namun format XDF/ADX dipelajari langsung dari file: magic, prefix 132 byte, divergensi `0x108`.
- Parser tabel BIN mandiri divalidasi pada 5 file (termasuk big-endian).
- Status format: **STATICALLY_ANALYZED**; status perilaku TunerPro: **UNKNOWN_AFTER_ANALYSIS**.

### 2.4 Sensor/live data

BE-09 hanya punya 23 nama kanal tanpa offset. BE-10 memulihkan **45 kanal** dengan byte index dan rumus dari `Diag.cs`/`Form1.cs` (`REPORTS\BE10_SENSOR_LIVE_DATA_CATALOG.csv`). Ini kontribusi terbesar BE-10 untuk live data.

### 2.5 Baca/tulis/recovery

- Tulis: urutan pra-tulis, header blok, fast write, checksum — **STATICALLY_ANALYZED**.
- Recovery: ID berakhiran `0000`, key recovery, pergeseran RH850B — **STATICALLY_ANALYZED**.
- Baca BIN penuh: **NOT_FOUND_AFTER_MEANINGFUL_SEARCH** di 3D.
- Semua eksekusi hardware: **HARDWARE_PENDING**.

### 2.6 Identifikasi ECU

- Database 169 ID (97 Keihin, 72 Shindengen) diparse dan dihitung.
- ID runtime dibaca lewat `72 07 72 00 00 05 10`; 5 byte.

---

## 3. Target yang tidak maju — dan mengapa

| Target | Alasan tidak maju | Status yang benar |
|---|---|---|
| HondaECU 3.x | Payload onefile/Cython tidak diekstrak; tidak ada source baru | `UNKNOWN_AFTER_ANALYSIS` |
| PRO Remap_BE | Packed; aturan BE-10 melarang eksekusi/unpacking tanpa izin | `BLOCKED_BY_ACCESS_REQUIREMENT` |
| SCANNER HONDA | Enigma Protector | `BLOCKED_BY_ACCESS_REQUIREMENT` |
| CheksumCalculator | Tidak ada algoritma yang bisa dipulihkan dari artefak yang ada | `UNKNOWN_AFTER_ANALYSIS` |
| TunerPro RT | Installer tidak diekstrak; perilaku EXE tidak diamati | `UNKNOWN_AFTER_ANALYSIS` |
| Pin Out ECU | Dokumen pinout, bukan algoritma | `STATICALLY_ANALYZED` |

Tidak ada klaim "berhasil dianalisis" untuk target yang hanya diketahui namanya.

---

## 4. Relevansi terhadap RevCore

| Target | Nilai untuk RevCore | Prioritas |
|---|---|---|
| 3D Chart Graph (baru) | Protokol, live data, checksum, tabel | **P1** |
| CheksumKZR | Checksum KZR yang sudah terbukti | **P1** |
| FTD2XX_NET | Pola transport Windows | **P2** |
| TunerPro RT | Format XDF/ADX (file, bukan EXE) | **P2** |
| HondaECU 3.x | Tidak ada bukti yang bisa diintegrasikan | **P3** |
| PRO Remap_BE / SCANNER | Terproteksi; tidak ada bukti | **P4** |
| Driver installer | Hanya referensi versi | **P4** |

---

## 5. Evidensi

- `BE09_RESEARCH_STATUS.csv` — status baseline.
- `BE10_3D_CHART_SOURCE_ANALYSIS.md` — sumber teknis baru.
- `BE10_ECU_PROTOCOL_FINDINGS.md` — protokol/checksum/live data.
- `REPORTS\BE10_SENSOR_LIVE_DATA_CATALOG.csv` — 45 kanal.
