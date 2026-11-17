# 17 — MATRIKS TIGA ARAH

**Work order:** BE-12
**Status:** analisis kapabilitas · I=IMPLEMENTED, P=PARTIAL, A=ABSENT, NV=NOT VERIFIED, HP=HARDWARE PENDING
**Sumber:** `16_THREE_WAY_COMPARISON/THREE_WAY_MATRIX.md`

---

## 1. Matriks 28 baris

| # | Kapabilitas | FLASHPRO | TunerPro | RevCore |
|---:|---|---|---|---|
| 1 | Transport serial generik | A (D2XX only) | I | I (USB-serial) |
| 2 | FTDI D2XX langsung | I | A | I (driver Android) |
| 3 | K-Line init (slow/break) | I (bit-bang) | A | P (`wakePulse`) |
| 4 | I2C EEPROM bit-bang | I (Form11) | A | A |
| 5 | Identifikasi ECU via K-Line | I (NV) | A | I (HP) |
| 6 | Identifikasi via EEPROM keyless | I (NV) | A | A |
| 7 | Database ECU bawaan | I (160 BIN/157 part) | A | I (489/163) |
| 8 | Live data tabel tetap | I (7 tabel, NV) | A | I (7 tabel, HP) |
| 9 | Live data definisi pengguna | A | I (ADX) | A |
| 10 | State nilai hilang eksplisit | A | A | I |
| 11 | DTC Honda | I (37, NV) | P (definisi) | I (15, HP) |
| 12 | Baca ROM penuh | I (48 KB, NV) | P (via BIN/XDF) | P (RomBinary) |
| 13 | Edit map offset-profil | I | I (XDF) | I |
| 14 | Format map terenkripsi | I (AES) | A (XDF plaintext) | I (AES) |
| 15 | Auto-map/interpolasi | I | P (MATH) | P |
| 16 | Grafik 2D/3D map | I | P | P (heatmap/line) |
| 17 | Flash ECU | I (NV) | A | A (default-deny) |
| 18 | Recovery ECU | I (NV) | A | P (state) |
| 19 | Reset flash count | I | A | A |
| 20 | Smartkey/SCU copy | I | A | A |
| 21 | Dyno internal | I | A | A |
| 22 | Pemrogram chip/emulator | A | I (Moates) | A |
| 23 | Plugin | A | I | A |
| 24 | Updater aplikasi | I | NV | A |
| 25 | Lisensi offline | I | NV | A |
| 26 | Integritas anti-tamper | P (Enigma+lisensi) | NV | I (10-gate) |
| 27 | Audit log protokol | P (`read48k.log`) | P (debug) | I (`CommunicationSniffer`) |
| 28 | Multi-platform | A (Windows) | I | A (Android) |

## 2. Catatan per kolom

- **FLASHPRO:** hampir semua kapabilitas ada, tetapi berstatus SOURCE VERIFIED; tidak satu pun operasi ECU diuji. "I (NV)" berarti kode/pesan ada, bukan terbukti bekerja.
- **TunerPro:** kuat pada generik/definisi dan perangkat Moates; tidak punya pengetahuan Honda, live table Honda, flash ECU, atau DTC Honda tanpa definisi.
- **RevCore:** paling kuat pada integritas, database, dan keamanan; kehilangan tulis/recovery/smartkey/dyno; live data dan edit map sudah sejajar.

## 3. Tiga kesimpulan

1. **Tidak ada pemenang menyeluruh.** FLASHPRO unggul pada cakupan alur kerja ECU; TunerPro pada fleksibilitas definisi & perangkat chip; RevCore pada keamanan & database.
2. **Titik temu ketiganya** adalah transport serial + edit BIN + live data; di situ detail implementasinya berbeda.
3. **Area berisiko (tulis ECU) hanya dimiliki FLASHPRO** — dan justru itu yang paling lemah buktinya.

## 4. Cara membaca matriks

Matriks ini mengukur **keberadaan mekanisme**, bukan kualitas hasil. "I" pada FLASHPRO berarti mekanisme terlihat di metadata/string; "I" pada RevCore berarti kode ada dan dapat dibaca; "I" pada TunerPro berarti fitur tersedia di aplikasi yang dianalisis BE-11. Tidak ada kolom yang boleh dibaca sebagai "terbukti bekerja di ECU".
