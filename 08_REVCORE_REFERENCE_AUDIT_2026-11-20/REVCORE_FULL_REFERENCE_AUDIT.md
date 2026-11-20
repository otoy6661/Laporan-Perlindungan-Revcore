# REVCORE FULL REFERENCE AUDIT

Work order: **REVCORE FULL REFERENCE AUTOPSY & FTDI K-LINE COMPATIBILITY AUDIT**
Project: RevCore — Owner/Creator: **otoy** — Executor: Kodir (Qoder)
Mode: **READ-ONLY, NO IMPLEMENTATION**
Tanggal: 2026-11-20

> RevCore — Jembatan untuk belajar, bukan pagar untuk membatasi pengetahuan.
> H-Diag dan FlashPro adalah sumber referensi penelitian. RevCore tetap proyek
> independen milik otoy.

---

## 1. Ringkasan eksekutif

1. **H-Diag** adalah aplikasi Qt5 32-bit dengan 25 model, ±46 label parameter,
   dan **tiga frame polling blok** (`72 05 60 03 26`, `72 05 71 00 18`,
   `72 05 00 F1 98`), bukan request per parameter. Siklus 15 langkah × 100 ms.
2. **H-Diag** juga memuat 5 frame baca DTC dan 2 frame clear, plus dictionary
   DTC Bahasa Indonesia. Format ACK dan efektivitas clear belum terbukti.
3. **Parser H-Diag tidak menyerahkan tabel offset/skala.** Nilai dipecah dan
   diformat sebagai teks. Karena itu "menyalin H-Diag" bukan opsi untuk Live Data.
4. **FlashPro Keyless** adalah pembacaan EEPROM 256 alamat via K-Line 10400,
   dengan handshake dua keluarga, probe vendor, lalu transformasi 4 byte menjadi
   ID 9 digit. `Immo_read_auto` hanyalah Read dengan deteksi ECM lebih dulu.
   `Immo_reset` adalah fungsi tulis dan sengaja tidak dianalisis.
5. **RevCore** sudah meniru kerangka Keyless (init, security, frame baca, index
   data), tetapi belum meniru probe vendor, jeda 1000 ms, dan pembacaan 256
   alamat. Model table 11 vs 27.
6. **Delapan parameter Live Data RevCore** (RPM, TPS, ECT, IAT, MAP, baterai,
   injektor, O2) semuanya **IMPLEMENTED BUT UNVERIFIED**; tidak satu pun mencapai
   ECU RESPONSE VERIFIED atau HARDWARE TESTED.
7. **Risiko routing keluarga**: `activeProfile` mengikuti `session.family` yang
   awalnya UNKNOWN (→ generik), lalu dapat berubah menjadi profil kosong bila
   header `0x7E`/`0x7C` muncul. Header itu sendiri belum terbukti.
8. **Transform Keihin/SCOOPY** RevCore (gaya C#) dan firmware (mode 1) berbeda
   struktur; belum ada known-answer test. Kandidat bug, bukan kepastian.
9. **FTDI USB OTG cukup** untuk semua kemampuan baca yang terbukti, asalkan
   antarmuka K-Line fisik ada. BREAK FTDI di Android belum diukur.
10. **Kelas D kosong.** Tidak ada ECU selama audit. Tidak ada klaim audit
    hardware selesai.

---

## 2. Ruang lingkup dan kelas bukti

Sumber: H-Diag `HDiag.exe` (`10100b34…`), FlashPro APK (`9fff9691…`),
`firmware.bin` (`fe0704fd…`), `firmware.signed.flash` (`97ca99e9…`), dan source
RevCore yang tidak diubah. Rincian hash dan log ada di
`RESEARCH_EVIDENCE_INDEX.md`.

| Kelas | Arti | Jumlah temuan |
|---|---|---|
| **A. FACT** | Terbaca dari byte/instruksi/konstanta | Mayoritas |
| **B. INFERENCE** | Simpulan logis, belum diuji | Beberapa (routing, offset/2, timing) |
| **C. UNVERIFIED** | Belum dapat dibuktikan | Parser H-Diag, ACK DTC, transform |
| **D. HARDWARE VERIFIED** | Diuji pada ECU fisik | **0** |

Aturan §7 dipatuhi: status tidak dinaikkan karena fitur terlihat di UI atau ada
di source.

---

## 3. H-Diag — kapabilitas yang ditemukan

| Kapabilitas | Bukti | Status |
|---|---|---|
| 25 model | combo `0x412ec4..0x412fac` | A |
| ±46 label parameter | `FUN_00401710` | A |
| Live data 3 frame blok | loop `0x407329` | A |
| Polling 100 ms, 15 langkah | `push 0x64`, counter | A |
| DTC baca 5 frame | disassembly | A |
| DTC clear 2 frame | `cleardtc_clicked` | A |
| Dictionary DTC Indonesia | string `0x4126d0…` | A |
| Identifikasi ECU terpisah | tidak ditemukan | C |
| Actuator/coding | tidak ditemukan | — |
| Lisensi FTDI Chip-ID | `logindialog`, `SimpleCrypt` | A |

Subset parameter per model (17/19/22) **belum** dipetakan; angka itu cocok dengan
konstanta 0x11/0x13/0x16, tetapi konstanta tersebut dipakai sebagai id baris.
Rincian: `HDIAG_PC_FULL_CAPABILITY_REPORT.md`, `HDIAG_LIVE_DATA_PARAMETER_MATRIX.md`.

---

## 4. FlashPro — Keyless ID

```
App ──Immo_read──► firmware
                    ├─ wake 10400, FE 04 72 8C, 72 05 00 F0 99
                    ├─ Keihin hello/who  ─┐
                    ├─ jeda 1000 ms       │
                    ├─ Shindengen xor1/2  │
                    ├─ probe-K 82 82 10 06 00 E6 ──► KEIHIN?
                    ├─ 72 05 71 00 18
                    └─ probe-S 91 91 07 40 4C 00 6D ──► SHINDENGEN?
                              │
                     baca 256 alamat (400/300 ms)
                              │
                     ambil 4 offset model → ID 9 digit
```

- Read = baca penuh lalu hitung ID; Identify = deteksi ECM lalu Read; Reset =
  tulis/renew (tidak dianalisis).
- Model: 27 entri; offset byte 144/145/160/161 (K59J), 64/65/76/77 (PCX/ADV160),
  60/61/62/63 (Beat/Stylo/Vario), 70/71/72/73 (Scoopy, mode 1).
- Gagal baca diisi `FF FF` oleh firmware; RevCore memilih `null` (lebih jujur).
- Rincian: `FLASHPRO_KEYLESS_ID_RESEARCH.md`.

---

## 5. Perbandingan tiga sistem

| Aspek | H-Diag PC | FlashPro | RevCore |
|---|---|---|---|
| Live data | 3 frame blok, 100 ms | 7 tabel `71 xx` | 7 tabel, 300 ms |
| Parser live | teks, tidak terbaca | offset + skala di firmware | offset + skala eksplisit |
| DTC baca | `72 07 72 D0/D1`, `73 00/01`, `74/01` | — | `74/01`, `71/20`, `00/00` |
| DTC clear | `60/01`, `D0/14/02` | — | `60/01`, `74/02`, `04` |
| Identifikasi | hanya `71 00` | ECM ID saat probe | `71 00`, `72 00`, `71 00` |
| Keyless | — | Read/Identify/Reset | Read saja |
| Tulis ECU | tidak ditemukan | reset EEPROM | tidak ada |
| Verifikasi | UI saja | firmware + APK | PROTOCOL_ANALYZED |
| Lisensi | Chip-ID | fitur bit 8 | tidak ada |

Perbedaan frame DTC dan timing bukan otomatis kesalahan RevCore; keduanya belum
diuji. Yang penting: jangan mencampur frame satu sumber dengan parser sumber lain.

---

## 6. Kelayakan FTDI K-Line

| Kemampuan | Putusan | Alasan |
|---|---|---|
| Live data (FlashPro) | REALIZABLE | Frame + offset + skala lengkap |
| Live data (H-Diag) | REALIZABLE WITH CAVEAT | Frame jelas, parser tidak |
| DTC baca/clear | REALIZABLE WITH CAVEAT | Frame jelas, ACK belum |
| Identifikasi ECU | REALIZABLE WITH CAVEAT | `71 00` saja, arti field belum |
| Keyless read/identify | REALIZABLE WITH CAVEAT | Butuh BREAK, 256 read, probe vendor |
| Keyless reset | NOT REALIZABLE (SCOPE) | Fungsi tulis, di luar etika |
| Lisensi Chip-ID | NOT REALIZABLE (IRRELEVANT) | Proteksi PC, bukan ECU |
| Actuator/coding | NOT PROVEN | Tidak ada bukti perintah |

Lapisan L1 (PC↔adaptor) tidak boleh dicampur dengan L3 (protokol ECU). Rincian:
`FTDI_KLINE_COMPATIBILITY_REPORT.md`.

---

## 7. Kondisi RevCore saat ini

### 7.1 Live Data

- 7 tabel: 17, 13, 11, 10, 16, 20, D1; urutan probe 17→13→11→10, lalu ekstensi.
- Request, offset, skala, range, bitMask, alternatif `0xFF`, dan state
  `NOT_AVAILABLE_IN_KOEO` semuanya eksplisit.
- Nilai hilang tidak diisi nol; UI memakai state per sensor.
- AFR dan FIS sengaja `UNSUPPORTED`.
- Namun: **tidak ada respons ECU** yang membuktikan satu pun dari delapan field.

### 7.2 DTC

- Baca tiga query, tolak `0x7F`, payload 4..size-1, parser database.
- Clear tiga frame, ACK header, lalu baca ulang.
- Semua **IMPLEMENTED BUT UNVERIFIED**.

### 7.3 Keyless

- Init, security, threshold, index data: cocok dengan firmware.
- Tidak ada probe vendor; hanya membaca sampai alamat model; jeda 150 ms.
- Model 11 vs 27; transform Keihin belum pasti.

### 7.4 Transport

- FTDI 10400 8N1, latency 2 ms, DTR/RTS, `setBreak`.
- Echo suppression + checksum validation; tanpa pacing inter-byte.
- Keyless memakai transport langsung tanpa validasi checksum (seperti firmware).

---

## 8. Gap matrix ringkas

Label resmi §6. Matriks lengkap ada di `REVCORE_IMPLEMENTATION_GAP_ANALYSIS.md`.

| Kapabilitas | Status |
|---|---|
| Live data 7 tabel (source) | IMPLEMENTED IN REVCORE |
| Layout live (offset/skala) | IMPLEMENTED BUT UNVERIFIED |
| Alur kirim live | COMMUNICATION FLOW IDENTIFIED |
| Balasan live ECU | ECU RESPONSE VERIFIED — **tidak ada** |
| Uji perangkat | HARDWARE TESTED — **tidak ada** |
| DTC baca/clear | IMPLEMENTED BUT UNVERIFIED |
| Identifikasi ECU | IMPLEMENTED BUT UNVERIFIED |
| Keyless read | IMPLEMENTED BUT UNVERIFIED |
| Keyless probe vendor | NOT IMPLEMENTED |
| Keyless 256 alamat | NOT IMPLEMENTED |
| Keyless reset | NOT IMPLEMENTED (sengaja) |
| Transform Keihin | UNKNOWN |
| Parser H-Diag | UNSUPPORTED |
| Lisensi Chip-ID | UNSUPPORTED |
| AFR/lambda | UNSUPPORTED |
| Routing keluarga | UNKNOWN |
| Frame DTC/Keyless di referensi | FOUND IN SOURCE |
| Alur handshake Keyless | COMMUNICATION FLOW IDENTIFIED |

Tidak ada baris yang boleh berstatus ECU RESPONSE VERIFIED atau HARDWARE TESTED.

---

## 9. Temuan teknis paling penting

1. **H-Diag bukan model "request per parameter".** Tiga frame blok; ini
   menjelaskan mengapa daftar parameter kaya tetapi request sedikit.
2. **H-Diag menyembunyikan parser.** Tanpa tabel offset, pemetaan H-Diag tidak
   dapat dipindahkan; hanya frame-nya yang berguna.
3. **Angka 17/19/22 ada, tetapi bukan bukti subset.** Konstanta dipakai sebagai
   id baris; pemetaan model belum selesai.
4. **Probe vendor adalah bagian wajib Keyless.** Firmware mencoba Keihin lebih
   dulu, lalu Shindengen. RevCore melewati langkah ini.
5. **Jeda 1000 ms pada firmware** bukan angka hiasan; RevCore 150 ms berisiko.
6. **Pembacaan 256 alamat** memberi firmware seluruh peta; RevCore hanya subset.
   Konvensi `offset/2` konsisten dengan tabel firmware, jadi bukan bug.
7. **Transform Keihin** C# vs firmware tidak identik; jangan "diperbaiki" tanpa
   known-answer.
8. **Routing keluarga RevCore** dapat mematikan fitur di tengah sesi; header
   `0x7E/0x7C` belum terbukti.
9. **Delapan parameter** terpetakan dan tidak diisi nol, tetapi belum terbukti
   dari ECU.
10. **FTDI** bukan penghalang; pengetahuan dan pengujianlah yang kurang.

---

## 10. Diagram komunikasi

### 10.1 Live data RevCore

```
UI ──queryLiveData()──► HondaProtocolEngine
                         ├─ activeProfile (generik)
                         ├─ cache / probe 17→13→11→10
                         ├─ legacyQuery
                         │    └─ EcuSessionManager ─► KlineWireEngine
                         │         ├─ purge/drain
                         │         ├─ write
                         │         ├─ read window
                         │         ├─ strip echo / tolak echo sendiri
                         │         └─ checksum + panjang
                         ├─ extractLivePayload (echo tabel cocok)
                         ├─ LiveDataFrameParser (offset/skala/range)
                         └─ LiveTelemetry (state per sensor)
```

### 10.2 Keyless RevCore

```
UI ──► KeylessReadEngine
        ├─ wake 70/130 ms @10400 BREAK
        ├─ FE 04 72 8C; 72 05 00 F0 99
        ├─ security request/key (K/S)
        ├─ baca 0..alamat model
        └─ decode (PCX / Keihin) → report
```

---

## 11. Kesimpulan dan langkah berikutnya

**Tercapai:**

- Kedua referensi diperiksa sampai tingkat alur dan byte.
- Kapabilitas H-Diag dan FlashPro diinventarisasi; batas Read/Identify/Service
  ditegaskan.
- Live Data H-Diag dipetakan sejauh bukti mengizinkan.
- Keyless ID ditelusuri sampai transformasi dan tabel model.
- Kelayakan FTDI dianalisis per lapisan.
- RevCore dibandingkan dan setiap temuan diklasifikasikan.
- Keterbatasan dilaporkan tanpa klaim hardware.

**Tidak tercapai (dan tidak diklaim):**

- Pemetaan parameter per model H-Diag.
- Rumus H-Diag.
- Verifikasi ECU, ACK DTC, atau ID Keyless pada kendaraan.

**Urutan pembuktian yang disarankan (bukan work order implementasi):**

1. Uji Live Data satu model dengan log mentah; bandingkan RPM/TPS.
2. Uji baca DTC; cocokkan jumlah kode.
3. Uji Keyless read pada satu Keihin dan satu Shindengen.
4. Uji ulang SCOOPY untuk known-answer transform.
5. Uji clear DTC terakhir.

Work order implementasi lanjutan tidak dibuat di sini. Laporan ini menunggu
ditinjau oleh otoy.
