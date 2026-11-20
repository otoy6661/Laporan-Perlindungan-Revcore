# REVCORE IMPLEMENTATION GAP ANALYSIS

Work order §5–§6. Audit READ-ONLY atas source RevCore:
`C:\Users\Lord Otoy\Documents\Qoder\work\REVCORE_KEYLESS_20261120\RevCore_work`
(applicationId `com.revcore.android`, versionName `1.0`).

Kelas bukti §7. **Kelas D kosong.** Label gap memakai sembilan istilah yang
diwajibkan work order, tanpa sinonim.

---

## 1. Metode

1. Membaca seluruh modul komunikasi, live data, DTC, Keyless, dan transport.
2. Mencocokkan setiap konstanta dengan sumbernya (firmware FlashPro atau baseline
   RevCore).
3. Memeriksa apakah nilai yang ditampilkan UI berasal dari ECU, derivasi UI, atau
   default kosong.
4. Tidak menjalankan aplikasi pada ECU. Semua status "verified" di source
   diperlakukan sebagai klaim yang harus dibuktikan, bukan bukti.

---

## 2. Inventaris fitur (source-level)

| Area | Modul utama | Status source |
|---|---|---|
| Transport USB/OTG | `UsbSerialLibraryTransport.kt` | Ada |
| Wire engine | `KlineWireEngine.kt` | Ada |
| Sesi/keluarga ECU | `EcuSessionManager.kt`, `EcuFamily.kt` | Ada, routing belum terbukti |
| Profil katalog | `HondaEcuProfiles.kt` | Generik terisi; keluarga lain kosong |
| Live data | `LiveDataProfile.kt`, `HondaProtocolEngine.kt` | 7 tabel |
| DTC | `HondaProtocolEngine.kt`, `HondaDtcDatabase` | Baca + clear baseline |
| Keyless | `Keyless*` (4 file) | Read saja |
| UI Live Data | `LiveDataScreen.kt` | 16+ kartu/baris |
| Tuning/MAP/Backup | modul lain | Di luar fokus work order |

---

## 3. Delapan parameter Live Data — diperiksa satu per satu

Delapan parameter dashboard yang dimaksud source (`LiveTelemetry.kt` baris 58–63:
"eight dashboard parameters") adalah:

1. RPM
2. TPS
3. ECT
4. IAT
5. MAP
6. Baterai
7. Injektor
8. O2

Untuk masing-masing: request, offset, rumus, sumber, dan status.

### 3.1 RPM

- Request: `72 05 71 17 01` (tabel 17), fallback 13/11/10/16.
- Offset: payload 0–1, big-endian, 2 byte.
- Rumus: `raw` (tanpa skala). Rentang 0..20.000.
- Sumber: decoder firmware FlashPro.
- Status: **IMPLEMENTED BUT UNVERIFIED**. Layout terbaca; belum ada balasan ECU
  yang membuktikan offset 0–1 benar untuk motor pemilik.

### 3.2 TPS

- Request: tabel 17/13/11/10.
- Offset: 2 (ADC), panjang 1.
- Rumus:
  - `TPS_ADC` = raw (0..255)
  - `TPS_VOLTAGE` = raw × 5/256 V
  - `TPS_PERCENT` = raw × 100/256 %
  - `TPS_DEGREES` = raw × 0.5 derajat
- Catatan source: persen adalah **derivasi UI** dari ADC yang sama, bukan kanal
  ECU terpisah; tidak ada auto-zero.
- Status: **IMPLEMENTED BUT UNVERIFIED**. Konsisten secara aritmetika, tetapi
  kalibrasi 0–100 % belum diuji pada throttle fisik.

### 3.3 ECT

- Offset: primary 9, alternatif 5 bila byte utama `0xFF`; tabel 17 memakai 8/9
  dengan alternatif 4/5.
- Rumus: `raw - 40` °C.
- Status: **IMPLEMENTED BUT UNVERIFIED**. Bias -40 adalah konvensi Honda, tetapi
  belum dicocokkan dengan suhu nyata.

### 3.4 IAT

- Offset: 7 (tabel 17), 6/7 untuk tabel lain.
- Rumus: `raw - 40` °C.
- Status: **IMPLEMENTED BUT UNVERIFIED**.

### 3.5 MAP

- Offset: 9 (tabel 13/11/10), 16 di tabel 16.
- Rumus: `raw` kPa; `MAP_VOLTAGE` terpisah = raw × 5/256 V.
- Status: **IMPLEMENTED BUT UNVERIFIED**. Perlu dicatat: nilai kPa ini adalah
  angka mentah ECU, bukan hasil konversi tekanan dari tegangan sensor. Hubungan
  dengan tekanan absolut belum dibuktikan.

### 3.6 Baterai

- Offset: 10 (tabel 17/13), 12 (tabel 11/10), 17 (tabel 16).
- Rumus: `raw × 0.1` V.
- Status: **IMPLEMENTED BUT UNVERIFIED**.

### 3.7 Injektor

- Offset: 11 (tabel 17/13/11/10), 19 (tabel 16, 1 byte).
- Rumus: `raw / 200` ms (2 byte di tabel utama, 1 byte di tabel 16).
- Status: **IMPLEMENTED BUT UNVERIFIED**. Perbedaan panjang field antar tabel
  berasal dari firmware; belum diuji.

### 3.8 O2

- Request: `72 05 71 20 F8` (tabel 20).
- Offset: 0; panjang 1.
- Rumus: `raw / 50.993698` V.
- Syarat: hanya bermakna saat mesin berputar; state `NOT_AVAILABLE_IN_KOEO`.
- Status: **IMPLEMENTED BUT UNVERIFIED**. AFR dan lambda **UNSUPPORTED** dan tidak
  diturunkan dari tegangan O2. Ini keputusan yang benar.

### 3.9 Ringkasan delapan parameter

| Parameter | Request | Offset | Rumus | Status |
|---|---|---|---|---|
| RPM | 17/13/11/10 | 0–1 | raw | IMPLEMENTED BUT UNVERIFIED |
| TPS | 17/13/11/10 | 2 | ADC, 5/256 V, 100/256 %, 0.5° | IMPLEMENTED BUT UNVERIFIED |
| ECT | 17/13/11/10 | 9 (alt 5) | raw-40 °C | IMPLEMENTED BUT UNVERIFIED |
| IAT | 17/13/11/10 | 7 | raw-40 °C | IMPLEMENTED BUT UNVERIFIED |
| MAP | 13/11/10 | 9 | raw kPa | IMPLEMENTED BUT UNVERIFIED |
| Baterai | 17/13/11/10 | 10/12 | raw×0.1 V | IMPLEMENTED BUT UNVERIFIED |
| Injektor | 17/13/11/10/16 | 11/19 | raw/200 ms | IMPLEMENTED BUT UNVERIFIED |
| O2 | 20 | 0 | raw/50.993698 V | IMPLEMENTED BUT UNVERIFIED |

Tidak ada satu pun yang mencapai **ECU RESPONSE VERIFIED** atau
**HARDWARE TESTED**. Klaim "delapan parameter tersedia" di source benar dalam
arti "delapan field ada dan dipetakan", tidak benar dalam arti "terbukti keluar
dari ECU".

---

## 4. Request, parser, dan konversi (ringkas)

| Tabel | Request | Payload start | Min field | Isi |
|---|---|---|---|---|
| 17 | `72 05 71 17 01` | 4 | 16 | RPM, TPS, ECT, IAT, BATT, INJ, ADV, MODE, VSS |
| 13 | `72 05 71 13 05` | 4 | 14 | RPM, TPS, ECT, IAT, MAP, BATT, INJ, ADV |
| 11 | `72 05 71 11 07` | 4 | 17 | seperti 13 + VSS, IACV |
| 10 | `72 05 71 10 08` | 4 | 17 | sama dengan 11 |
| 16 | `72 05 71 16 02` | 4 | 21 | APS/TP, COR, sensor, injektor 1 byte |
| 20 | `72 05 71 20 F8` | 4 | 2 | O2, STF |
| D1 | `72 05 71 D1 47` | 4 | 7 | gear, side stand, starter, flag |

Parser `LiveDataFrameParser.parse`:

- memilih offset utama; bila byte `0xFF` dan ada alternatif, pindah;
- endian big, signed opsional;
- `bitMask` untuk switch;
- nilai di luar rentang → `INVALID_RESPONSE`, tidak dijadikan 0;
- frame valid bila minimal satu sensor lolos.

`extractLivePayload`:

- menolak frame < `minFrameSize`;
- menolak service `0x7F`;
- mensyaratkan `frame[3]` sama dengan tabel yang diminta;
- payload = byte 4..size-2.

Ini sesuai praktik yang baik. Yang belum ada: verifikasi bahwa ECU benar-benar
mengirim susunan ini.

---

## 5. Profil kendaraan dan routing keluarga

- `HondaEcuProfiles.genericBaseline` berisi katalog lengkap (0x72).
- Profil Keihin H99B, Keihin KWP, Shindengen H99B, Denso H99B **kosong**
  (UNRESOLVED) dan komentar menyatakan tidak ada frame yang dikarang.
- `HondaProtocolEngine.activeProfile = HondaEcuProfiles.forFamily(session.family.value)`.
- `EcuFamily` awalnya UNKNOWN → `forFamily(UNKNOWN)` = genericBaseline.
- Keluarga hanya berubah bila header respons `0x7E`/`0x7C` terlihat; pemetaan itu
  **HYPOTHESIS**, tidak bersumber dari referensi.

**Konsekuensi (B. INFERENCE):**

1. Pada awal sesi, semua fitur memakai katalog generik. Ini masuk akal.
2. Jika header `0x7E`/`0x7C` muncul dan keluarga berubah, `activeProfile` menjadi
   profil kosong → live data (`UNSUPPORTED_PROFILE`) dan DTC berhenti, padahal
   koneksi tetap. Tidak ada mekanisme kembali ke generik.
3. Karena header belum terbukti, perilaku ini belum pernah teramati pada ECU.

Ini konflik desain yang perlu dicatat, bukan diperbaiki dalam audit ini.

---

## 6. DTC

| Aspek | Implementasi | Status |
|---|---|---|
| Baca | Query `74/01`, `71/20`, `00/00` berurutan | IMPLEMENTED BUT UNVERIFIED |
| Tolak negatif | service `0x7F` dilewati | IMPLEMENTED |
| Payload | byte 4..size-1 | IMPLEMENTED BUT UNVERIFIED |
| Parser | `HondaDtcDatabase.parseDtcPacket` | IMPLEMENTED BUT UNVERIFIED |
| Clear | `60/01`, `74/02`, `04` | IMPLEMENTED BUT UNVERIFIED |
| ACK | header `0x02/0x72/0x7E/0x7C` | UNKNOWN |
| Verifikasi ulang | baca ulang setelah clear | IMPLEMENTED BUT UNVERIFIED |

Perbedaan dengan H-Diag: H-Diag memakai `72 07 72 D0/D1` dan `73 00/01`.
Tidak ada bukti bahwa frame RevCore lebih benar; keduanya belum diuji.

---

## 7. Keyless

| Aspek | RevCore | Firmware | Status |
|---|---|---|---|
| Init | sama | sama | Cocok |
| Security | sama | sama | Cocok |
| Jeda | 150 ms | 1000 ms | Berbeda |
| Deteksi vendor | tidak | probe-K/S | NOT IMPLEMENTED |
| Jumlah alamat | sampai alamat model | 256 | Berbeda |
| Threshold | 13/15 | 0x0C/0x0D | Cocok |
| Data index | 10/11, 11/12 | sama | Cocok |
| Model table | 11 | 27 | Berbeda |
| Transform Keihin | C# style | mode 1 | C. UNVERIFIED |
| Reset/tulis | tidak ada | ada | Sesuai batas etika |

Kesalahan yang **tidak** terjadi: konvensi `offset/2` bukan bug. Untuk K59J,
offset 144/145 → alamat 72/80 byte, dan tabel firmware memang memakai offset byte
pada buffer 512 byte. Statusnya **B. INFERENCE**, bukan fakta teruji.

---

## 8. Transport dan FTDI

- 10400 8N1, latency 2 ms, DTR/RTS, `setBreak`.
- Transaksi default 700 ms, retry 1, tanpa pacing antar-byte.
- Echo: strip di awal + tolak frame identik yang dikirim < 1500 ms.
- Checksum wajib valid.
- Keyless engine memakai transport langsung dan **tidak** memvalidasi checksum
  balasan (sama seperti firmware).

Risiko: tanpa pacing, FTDI dapat mengirim byte lebih rapat daripada firmware
(30 unit delay). Kelas B.

---

## 9. Bug, batas, dan konflik

| # | Temuan | Bukti | Kelas |
|---|---|---|---|
| 1 | Routing keluarga dapat mematikan live data/DTC di tengah sesi | `activeProfile` + profil kosong | B |
| 2 | Header `0x7E`/`0x7C` sebagai penentu keluarga | `EcuSessionManager` | HYPOTHESIS |
| 3 | Keyless tidak mendeteksi vendor | `KeylessReadEngine` | A |
| 4 | Keyless hanya membaca sampai alamat model | loop `0..lastAddress` | A |
| 5 | Jeda Keyless 150 ms vs 1000 ms | konstanta | A |
| 6 | Transform Keihin berbeda struktur | decoder vs firmware | C |
| 7 | Model Keyless 11 vs 27 | `KeylessModels` vs tabel | A |
| 8 | DTC frames berbeda dari H-Diag | katalog | A |
| 9 | `ProfileVerification.VERIFIED` menandai layout, bukan respons ECU | `LiveDataProfile.kt` | A (risiko tafsir) |
| 10 | Tanpa pacing inter-byte | `KlineWireConfig` | A |
| 11 | MAP berupa raw kPa, bukan konversi tekanan | field | A |
| 12 | TPS persen adalah derivasi UI | komentar source | A |

Tidak ditemukan: nilai palsu/karangan pada live data (default 0 selalu digerbangi
state), klaim clear DTC sukses tanpa ACK, atau keyless menulis EEPROM.

---

## 10. Gap matrix (sembilan label resmi)

Legenda kolom: **LOC** = lokasi file/fungsi, **EXCERPT** = potongan kode,
**METHOD** = cara verifikasi yang dipakai/dibutuhkan.

| # | Kapabilitas | Status | LOC | EXCERPT | METHOD |
|---|---|---|---|---|---|
| 1 | Live data 7 tabel | IMPLEMENTED IN REVCORE | `core/comm/LiveDataProfile.kt` `HondaLiveDataProfiles` | `request = byteArrayOf(0x72,0x05,0x71,0x17,0x01)` | Baca source |
| 2 | Layout offset/scaling | IMPLEMENTED BUT UNVERIFIED | sama, `field(...)` | `scale = 5.0/256.0` | Belum ada respons ECU |
| 3 | Request live terkirim | COMMUNICATION FLOW IDENTIFIED | `HondaProtocolEngine.queryLiveData` | `legacyQuery(d, command, ...)` | Trace kode |
| 4 | Balasan ECU live | ECU RESPONSE VERIFIED | — | — | Tidak ada; butuh log ECU |
| 5 | Uji perangkat live | HARDWARE TESTED | — | — | Tidak ada |
| 6 | DTC read | IMPLEMENTED BUT UNVERIFIED | `readDtcsInternal` | `for (req in profile.dtcRead)` | Belum ada ECU |
| 7 | DTC clear | IMPLEMENTED BUT UNVERIFIED | `clearDtcs` | `profile.dtcClear` | ACK belum terbukti |
| 8 | Identifikasi ECU | IMPLEMENTED BUT UNVERIFIED | `HondaProtocolEngine` | `71 00` dsb. | Belum ada ECU |
| 9 | Keyless read | IMPLEMENTED BUT UNVERIFIED | `KeylessReadEngine.read` | `for (address in 0..lastAddress)` | Tidak ada ECU |
| 10 | Keyless vendor detect | NOT IMPLEMENTED | `KeylessReadEngine` | tidak ada probe | Bandingkan firmware |
| 11 | Keyless 256 alamat | NOT IMPLEMENTED | sama | `0..lastAddress` | Bandingkan firmware |
| 12 | Keyless reset/tulis | NOT IMPLEMENTED | — | — | Sengaja (etika) |
| 13 | Keyless transform Keihin | UNKNOWN | `KeylessIdDecoder` | `part1 shl 14` | Butuh known-answer test |
| 14 | H-Diag live parser | UNSUPPORTED | — | — | Tidak ada tabel offset |
| 15 | H-Diag license Chip-ID | UNSUPPORTED | — | — | Bukan protokol ECU |
| 16 | AFR/lambda | UNSUPPORTED | `LiveParameterStates` | `AFR to UNSUPPORTED` | Keputusan desain |
| 17 | FIS | UNSUPPORTED | sama | `FIS to UNSUPPORTED` | Konflik byte MODE |
| 18 | Routing keluarga | UNKNOWN | `EcuSessionManager` | `family` 0x7E/0x7C | Hanya hipotesis |
| 19 | FTDI break di Android | IMPLEMENTED BUT UNVERIFIED | `UsbSerialLibraryTransport.setBreak` | `port.setBreak(enable)` | Butuh osiloskop/ECU |
| 20 | H-Diag DTC frames | FOUND IN SOURCE | HDiag.exe | `72 07 72 D0 00 0E 37` | Disassembly |
| 21 | FlashPro Keyless frames | FOUND IN SOURCE | firmware | `82 82 10 06` | Ghidra |
| 22 | FlashPro handshake alur | COMMUNICATION FLOW IDENTIFIED | firmware | probe-K/S | Ghidra |

Tidak ada baris yang boleh berstatus **ECU RESPONSE VERIFIED** atau
**HARDWARE TESTED** pada audit ini.

---

## 11. Prioritas risiko (untuk laporan akhir, bukan work order)

1. Keyless Keihin/Scoopy: transformasi belum cocok → risiko ID salah.
2. Routing keluarga: fitur bisa mati setelah header tertentu.
3. Jeda Keyless 150 ms vs 1000 ms: risiko handshake gagal pada ECU lambat.
4. DTC clear: ACK tidak diketahui; jangan tampilkan "berhasil" tanpa bukti.
5. Label `VERIFIED` pada layout: risiko dibaca sebagai "fitur terverifikasi".

Semua di atas adalah temuan audit. Work order implementasi tidak dibuat di sini.
