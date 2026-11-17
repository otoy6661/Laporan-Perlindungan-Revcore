# 14 — PERBANDINGAN DENGAN REVCORE

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Sumber RevCore (read-only):** `HondaChecksum.kt`, `HondaFrameCodec.kt`, `LiveDataProfile.kt`, `FlashEngine.kt`, `RomBinary.kt`, `MapParser.kt`, `HondaEcuProfiles.kt`
**Status:** SELESAI — perbandingan tingkat kode vs bukti TunerPro. Setiap klaim diberi label klasifikasi.

---

## 1. Label yang dipakai

| Label | Arti |
|---|---|
| **EXACT MATCH** | Detail teknis identik dan terverifikasi |
| **SAME FRAME FAMILY** | Keluarga/konsep sama, detail belum tentu identik |
| **DIFFERENT COMMAND** | Perintah/ID berbeda untuk tujuan yang sama |
| **DIFFERENT IMPLEMENTATION** | Tujuan sama, arsitektur berbeda |
| **NOT FOUND** | Tidak ada padanan |
| **INSUFFICIENT EVIDENCE** | Bukti tidak cukup untuk menyimpulkan |
| **HARDWARE VALIDATION PENDING** | Cocok secara kode, belum diuji di ECU |

---

## 2. Matriks perbandingan

| Area | TunerPro RT | RevCore | Klasifikasi |
|---|---|---|---|
| Framing | ADX: statis/variabel, header/footer | Tetap: header, length, service, params, checksum | **DIFFERENT IMPLEMENTATION** |
| Checksum frame 8-bit SUM | SUM dua-komplemen (CBR `0xEF`) | `(256 - sum) & 0xFF` | **EXACT MATCH** (algoritma) / **HARDWARE VALIDATION PENDING** |
| Checksum 16-bit Keihin | Tidak ada bukti dukungan 16-bit | `calculateKeihin16BitChecksum` | **NOT FOUND** di TunerPro |
| CRC-16 Shindengen | TPChecksum hanya `SUM1.0` | `SHINDENGEN_CRC16` poly `0xA001` | **NOT FOUND** di TunerPro |
| Checksum file XDF | Deklaratif (`XDFCHECKSUM`), butuh plug-in | Hardcoded per `ChecksumType` | **DIFFERENT IMPLEMENTATION** |
| Header request Honda | ADX (tidak terbaca) | `0x72 0x05 0x71 …` | **INSUFFICIENT EVIDENCE** |
| Baud | Per ADX/per perintah | 10.400 (kandidat 9.600/10.400) | **DIFFERENT IMPLEMENTATION** |
| Timeout/silence | `listentimeout`, `silencelen` | Tidak dimodelkan | **NOT FOUND** di RevCore |
| Echo | `RS232 Echo` | `stripLeadingEcho` | **SAME FRAME FAMILY** |
| Endianness nilai | Opsi LSB first | Big-endian per field | **DIFFERENT IMPLEMENTATION** |
| Bias suhu | Label ADX `Engine Temp (-40)` | `bias = -40.0` | **EXACT MATCH** (konvensi) |
| Bias ignition | Label ADX `Ignition (-64.0)` | `bias = -64.0`, scale 0.5 | **EXACT MATCH** (konvensi) |
| TPS % | ADX `TPS Volt` (tegangan) | ADC 5/256 V; % 100/256 | **SAME FRAME FAMILY** |
| AFR | Baris ADX `AFR (19.50)` | `UNSUPPORTED` (narrowband only) | **DIFFERENT IMPLEMENTATION** |
| Status nilai hilang | Tidak ada; nilai bisa 0 | `VALID`/`NOT_RESPONDING`/`STALE`/… | **DIFFERENT IMPLEMENTATION** |
| Model tabel | XDF absolut + stride + MATH | FlashPro section + offset absolut | **SAME FRAME FAMILY** / beda format |
| Parser XDF | Ada | Tidak ada | **NOT FOUND** di RevCore |
| Parser ADX | Ada | Tidak ada | **NOT FOUND** di RevCore |
| Edit BIN mentah | Ya, via XDF | Hanya image FlashPro | **DIFFERENT IMPLEMENTATION** |
| Flash ECU | Tidak ada | `FlashEngine` default-deny | **NOT FOUND** di TunerPro |
| Recovery ECU | Tidak ada | State `RECOVERY_REQUIRED` (tanpa rutin) | **NOT FOUND** keduanya |
| Emulator RAM | Ya (Moates) | Tidak ada | **NOT FOUND** di RevCore |
| Chip programmer | Ya (PromIO) | Tidak ada | **NOT FOUND** di RevCore |
| Plug-in | 2 registry + modul tetap | Tidak ada | **NOT FOUND** di RevCore |
| Live Monitor UI | ScannerPro (Lists/Dash/Monitor/History) | Belum ada UI setara | **NOT FOUND** di RevCore |
| Playback log | Ada | Tidak ada | **NOT FOUND** di RevCore |

---

## 3. Analisis per area

### 3.1 Checksum

RevCore memiliki empat tipe: `KEIHIN_16BIT_ADD`, `KEIHIN_8BIT_INVERTED`, `SHINDENGEN_ADDITIVE`, `SHINDENGEN_CRC16`. TunerPro hanya membawa SUM 8-bit melalui `TPChecksumPlugin` (`SUM1.0`), sedangkan XDF dapat mendeklarasikan metode 0 dan plug-in tertentu.

**Temuan penting:** checksum CBR `0xEF` adalah komplemen dua dari jumlah byte 0..`0x3FFF7`, identik dengan rumus `calculatePacketChecksum`. Jadi RevCore memiliki **EXACT MATCH** untuk keluarga SUM 8-bit, tetapi belum ada bukti checksum ini dipakai pada frame perintah Honda (hanya pada file kalibrasi CBR).

**Konsekuensi:** klaim “RevCore checksum sama dengan TunerPro” hanya benar untuk SUM 8-bit. Untuk Keihin 16-bit dan CRC16, TunerPro tidak menyediakan pembanding.

### 3.2 Framing dan live data

TunerPro tidak memiliki frame Honda hardcoded. ADX yang terenkripsi memuat definisi, sehingga tidak dapat dibandingkan per byte. Yang dapat dibandingkan hanya konvensi skala yang terlihat di label runtime:

- `Engine Temp (-40)` → sama dengan `bias = -40.0` RevCore.
- `Ignition (-64.0)` → sama dengan `bias = -64.0`, scale 0.5.
- `Battery Volt` → konsisten dengan skala 0,1 V.
- `Injector Duration` → konsisten dengan skala ms.

Ini **EXACT MATCH pada konvensi**, bukan bukti frame.

### 3.3 Status nilai

RevCore melarang nilai hilang menjadi 0 (`LiveParameterState`). TunerPro tidak memiliki model ini; Data List dapat menampilkan nilai definisi/konstanta (contoh AFR 19.50) saat tidak ada data. Ini perbedaan filosofis penting: **RevCore lebih aman untuk diagnostik**, TunerPro lebih fleksibel untuk tuning.

### 3.4 Flashing

TunerPro tidak memiliki jalur flash ECU; RevCore memiliki state machine tetapi default-deny dan belum terbukti. Tidak ada yang bisa diadopsi dari TunerPro untuk flashing ECU. Sebaliknya, RevCore sudah lebih ketat daripada TunerPro pada aspek ini.

### 3.5 XDF/ADX sebagai peluang

Jika RevCore ingin membaca dataset ini, dua kemampuan baru diperlukan:

1. **Parser XDF** (setidaknya 13 plaintext) untuk memetakan tabel ke BIN mentah.
2. **Parser/ADX runner** atau konversi ADX → profil internal, dengan penanganan enkripsi yang sah.

Tanpa itu, 174 XDF dan 3 ADX tidak dapat dipakai, dan 700 BIN hanya dapat dibaca sebagai byte tanpa makna.

---

## 4. Ringkasan kesesuaian

| Kategori | Jumlah area |
|---|---:|
| EXACT MATCH | 3 (SUM 8-bit, bias -40, bias -64) |
| SAME FRAME FAMILY | 3 (echo, TPS, model tabel) |
| DIFFERENT IMPLEMENTATION | 9 |
| DIFFERENT COMMAND | 0 (tidak ada perintah Honda yang dapat dibandingkan) |
| NOT FOUND | 12 |
| INSUFFICIENT EVIDENCE | 2 |
| HARDWARE VALIDATION PENDING | 1 (SUM 8-bit pada frame ECU) |

Tidak ada **EXACT MATCH** pada level frame/perintah Honda karena ADX tidak terbaca dan tidak ada capture.

---

## 5. Rekomendasi untuk RevCore (tanpa mengubah kode)

1. Pertahankan default-deny `FlashEngine`; jangan adopsi model TunerPro yang tidak memiliki gerbang bukti.
2. Tambahkan registry checksum jika ingin membaca XDF; jangan hardcode hanya empat tipe.
3. Perlakukan XDF/ADX terenkripsi sebagai **tidak dapat diaudit**; jangan klaim kompatibilitas.
4. Modelkan timeout/silence/echo sebelum mengklaim dukungan ADX.
5. Jangan menurunkan status `UNSUPPORTED` AFR hanya karena ADX menampilkan baris AFR; baris itu bisa konstanta.
6. Jika mengadopsi checksum SUM 8-bit, tambahkan uji vektor dari CBR (`0xEF`) sebagai bukti.

---

## 6. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Perbandingan checksum 8-bit | TINGGI (nilai file + kode) |
| Perbandingan bias | TINGGI (label runtime + kode) |
| Perbandingan frame | RENDAH (ADX terenkripsi) |
| Perbandingan flashing | TINGGI (tidak ada jalur ECU) |
| Klasifikasi NOT FOUND | TINGGI untuk fitur yang diperiksa; tidak berlaku untuk fitur tersembunyi |
