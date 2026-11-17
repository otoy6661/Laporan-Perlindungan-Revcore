# Matriks Tiga Arah — Kapabilitas Teknis

**Kolom:** FLASHPRO (BE-12) · TunerPro RT (BE-11) · RevCore (`work/revcore`).
**Status:** I = IMPLEMENTED, P = PARTIAL, A = ABSENT, NV = NOT VERIFIED, HP = HARDWARE PENDING, NA = tidak berlaku.

| # | Kapabilitas | FLASHPRO | TunerPro | RevCore |
|---:|---|---|---|---|
| 1 | Transport serial generik | A (D2XX only) | I | I (USB-serial) |
| 2 | Transport FTDI D2XX langsung | I | A | I (driver Android) |
| 3 | K-Line init (slow/break pulse) | I (Class155 bit-bang) | A | P (`wakePulse` via USB-serial break) |
| 4 | I2C EEPROM bit-bang | I (Form11) | A | A |
| 5 | Identifikasi ECU via K-Line | I (NV) | A (definisi pengguna) | I (HP) |
| 6 | Identifikasi via EEPROM keyless | I (NV) | A | A |
| 7 | Database ECU bawaan | I (160 BIN / 157 part) | A | I (489 ECM / 163 profil) |
| 8 | Live data tabel tetap | I (7 tabel, NV) | A | I (7 tabel, HP) |
| 9 | Live data definisi pengguna | A | I (ADX) | A |
| 10 | State nilai hilang eksplisit | A | A | I |
| 11 | DTC Honda | I (37 kode, NV) | P (definisi) | I (15 entri, HP) |
| 12 | Baca ROM penuh | I (48 KB, NV) | P (via XDF/BIN) | P (RomBinary) |
| 13 | Edit map offset-profil | I | I (XDF) | I |
| 14 | Format map terenkripsi | I (AES) | A (XDF plaintext) | I (AES, kompatibel) |
| 15 | Auto-map / interpolasi | I | P (MATH) | P (edit + validate, tanpa auto-map) |
| 16 | Grafik 2D/3D map | I | P | P (heatmap + line chart) |
| 17 | Flash ECU (erase/write/verify) | I (NV) | A | A (default-deny) |
| 18 | Recovery ECU | I (NV) | A | P (state saja) |
| 19 | Reset flash count | I | A | A |
| 20 | Smartkey/SCU copy | I | A | A |
| 21 | Dyno internal | I | A | A |
| 22 | Pemrogram chip/emulator | A | I (Moates) | A |
| 23 | Plugin | A | I | A |
| 24 | Updater aplikasi | I | NV | A |
| 25 | Lisensi offline | I | NV | A |
| 26 | Integritas aplikasi (anti-tamper) | P (Enigma + lisensi) | NV | I (10-gate) |
| 27 | Audit log protokol | P (`read48k.log`) | P (debug) | I (`CommunicationSniffer`) |
| 28 | Multi-platform | A (Windows) | I | A (Android) |

## Catatan per kolom

- **FLASHPRO**: hampir semua kapabilitas ada, tetapi statusnya SOURCE VERIFIED; tidak ada satu pun operasi ECU yang diuji. "I (NV)" berarti kode/pesan ada, bukan terbukti bekerja.
- **TunerPro**: kuat pada generik/definisi dan perangkat Moates; tidak memiliki pengetahuan Honda, live table Honda, flash ECU, atau DTC Honda tanpa definisi.
- **RevCore**: paling kuat pada integritas, database, dan keamanan; kehilangan fitur tulis/ recovery/ smartkey/ dyno; live data dan edit map sudah sejajar.

## Tiga kesimpulan matriks

1. Tidak ada pemenang menyeluruh: FLASHPRO unggul pada **cakupan alur kerja ECU**, TunerPro pada **fleksibilitas definisi & perangkat chip**, RevCore pada **keamanan & database**.
2. Satu-satunya area di mana ketiganya bertemu adalah **transport serial + edit BIN + live data**, dan di situ detail implementasinya berbeda.
3. Area berisiko (tulis ECU) hanya dimiliki FLASHPRO — dan justru itu yang paling lemah buktinya.
