# BE-12 — EXECUTIVE SUMMARY (FINAL)

**Work order:** BE-12 — FLASHPRO.inc Full Autopsy & Three-Way Technical Comparison
**Status:** FASE 0–VI selesai · 12/12 tes prototipe lulus · dipublikasikan 2026-11-18 (lihat `PUBLICATION_SANITIZATION.md`)
**Tanggal:** 2026-11-18

---

## 1. Temuan inti

1. **Bentuk produk.** FLASHPRO.inc adalah aplikasi Windows x64 .NET Framework 4.8 WinForms (`FLASHPRO` 0.0.1.6, Team Tech Tunner/itech), dilindungi Enigma Protector 5.x, disajikan melalui wrapper VB6. Payload byte-identik dengan build installer.
2. **Struktur.** 168 tipe, 1.442 baris metode, 1.429 field, 2.082 string. Inti: `Form1`, `Form11`/`SMK`, `Diag`, `ReadECU`, `Reset`, `ChartLiveMap`, `DYNO`, `LicenseForm`, `UpdaterClient`.
3. **Transport.** Hanya FTDI D2XX: `Class15` UART/ISO, `Class155` bit-bang (K-Line + I2C EEPROM). Tidak ada COM/CAN/ELM327/J2534.
4. **Protokol.** Token `dat10/11/13/16/17/20/D1`, `dtc`..`dtc4`, `rst`..`rst4`; wire-level **tidak terbaca**, tidak ada capture.
5. **ECU.** 6 tipe (Keihin/Shindengen), 2 jalur ID (K-Line + EEPROM keyless), 160 BIN/157 part code/29 seri, 37 baris DTC.
6. **BIN/map.** Buffer + undo snapshot, offset VomConfig, sel word 16-bit, `.map` AES. Baca 48 KB. Tulis ECU dengan compare + auto-checksum.
7. **Checksum.** 7 fungsi bernama; algoritma **NOT VERIFIED**. Empat algoritma RevCore lulus vektor uji.
8. **Flash/recovery.** 7 tahap rekonstruksi + recovery key Shindengen; **tidak diuji** pada ECU.
9. **Lisensi.** Dua lapis offline, HWID (motherboard/CPU/BIOS/disk), RSA verify, anti-debug; tidak ada server.
10. **Updater.** Feed GitHub tanpa signature, ZIP berpassword, eksekusi `runas`.

## 2. Tiga arah, tanpa pemenang

| Dimensi | FLASHPRO | TunerPro | RevCore |
|---|---|---|---|
| Kekuatan utama | alur kerja Honda lengkap | fleksibilitas ADX/XDF + chip | keamanan, database, audit |
| Kelemahan utama | bukti ECU tertutup | tidak tahu Honda | belum menulis ECU |
| Status bukti | SOURCE/STATIC; ECU BLOCKED | SOURCE/STATIC; tanpa capture | SOURCE + SIMULATION; HARDWARE PENDING |

Tidak ada aplikasi yang unggul di semua dimensi. Penilaian berdasarkan jumlah menu ditolak oleh work order dan tidak dilakukan.

## 3. Posisi RevCore

RevCore adalah **platform yang lebih ketat dan lebih luas database-nya** (489 ECM/163 profil), dengan live data sejajar secara protokol, edit map sejajar, dan `FlashEngine` default-deny. Ia kehilangan smartkey, dyno, recovery nyata, dan jalur tulis — tetapi justru area berisiko itu yang bukti FLASHPRO paling lemah.

## 4. Prioritas RevCore

1. **Sekarang, tanpa hardware:** checksum vectors, audit DTC (24 hilang; 2 baris artefak), regression test profil.
2. **Dengan hardware + ECU donor:** protokol baca/tulis/erase/verify, recovery, capture live data.
3. **Setelah bukti:** UI live, auto-map/2D-3D, mode/limiter, smartkey/dyno (opsional).
4. **Jangan tiru:** lisensi hardware-bound, updater tanpa signature, urutan flash tanpa bukti.

## 5. Batas yang diakui

- Tidak ada frame ECU nyata (`NO RAW RX CAPTURE`).
- Tidak ada algoritma FLASHPRO yang terbukti (IL BLOCKED).
- Tidak ada penulisan ECU (dilarang).
- Tidak ada pengujian hardware (adaptor tidak terpasang).
- E02/E03 tidak dijalankan (UAC/pihak ketiga).

## 6. Kesimpulan satu paragraf

FLASHPRO.inc adalah produk komersial tertutup dengan cakupan fitur Honda yang luas dan bukti internal yang sangat terbatas. Autopsi ini memetakan struktur, transport, permukaan perintah, model BIN/map, lisensi, dan alur flash — tetapi tidak dapat membuktikan algoritma atau keberhasilan operasi ECU. RevCore berada pada posisi yang lebih aman dan lebih auditabel; langkah berikutnya yang paling bernilai adalah menaikkan status bukti hal-hal yang sudah ada, bukan menambah fitur baru.
