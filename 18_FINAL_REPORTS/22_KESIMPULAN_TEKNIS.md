# 22 — KESIMPULAN TEKNIS

**Work order:** BE-12 — FLASHPRO.inc Full Autopsy & Three-Way Technical Comparison
**Status:** final · tanpa publikasi/push/perubahan repositori
**Basis:** laporan 01–21, `EVIDENCE_REGISTER.csv` EV-001…EV-026

---

## 1. Jawaban langsung atas pertanyaan work order

### Apa FLASHPRO.inc sebenarnya?

Aplikasi Windows **x64 .NET Framework 4.8 WinForms** (assembly `FLASHPRO` 0.0.1.6, vendor Team Tech Tunner/itech) yang dilindungi **Enigma Protector 5.x** dan disajikan melalui **wrapper VB6**. Payload-nya byte-identik dengan build installer. Ia bukan aplikasi native tunggal dan bukan aplikasi yang dapat diuji tanpa lisensi + adaptor FTDI.

### Bagaimana struktur internalnya?

168 tipe, 1.442 baris metode, 1.429 field, 2.082 string. Inti: `Form1` (dashboard/map/flash), `Form11`/`SMK` (smartkey/EEPROM), `Diag` (DTC/live), `ReadECU`, `Reset`, `ChartLiveMap`, `DYNO`, `LicenseForm`, `UpdaterClient`, `Class15`/`Class155` (D2XX). Metadata terbaca; **IL tidak**.

### Bagaimana ia berbicara ke ECU/hardware?

Hanya melalui **FTDI D2XX** (`ftd2xx.dll`): `Class15` untuk UART/ISO K-Line, `Class155` untuk bit-bang (init K-Line + I2C EEPROM). Tidak ada COM port, CAN, ELM327, atau J2534. Nilai baud/timeout tidak terbaca; **tidak ada capture** (`NO RAW RX CAPTURE`).

### Bagaimana BIN dibaca/diedit/disimpan/ditulis?

Dua jalur terpisah: file `.bin`/`.map` di PC vs ROM ECU. Edit memakai buffer `binBytes` + undo/redo snapshot penuh, offset VomConfig, sel word 16-bit. `.map` adalah kontainer AES + hash. Baca ECU memakai `Read48` (**48 KB**) + log. Tulis ECU memakai `WriteFlash` + `CompareMemory` + auto-checksum. **Tidak ada satu pun yang diuji pada ECU.**

### ECU ID, Live Data, checksum, flashing, recovery?

- ID: K-Line (`GetEcuType`, `Extract14to25`) + EEPROM keyless; 6 tipe ECU; 160 BIN/157 part code/29 seri.
- Live: 7 tabel (`dat10/11/13/16/17/20/D1`), 36 label, tanpa state nilai hilang.
- Checksum: 7 fungsi bernama; algoritma **NOT VERIFIED**.
- Flash: 7 tahap rekonstruksi (pre-write → seed/key → erase → write → compare → checksum → GOOD/BAD), **NOT TESTED**.
- Recovery: mode recovery + recovery key Shindengen + reset flash count; **belum terbukti**.

## 2. Kemampuan unik masing-masing

### FLASHPRO

Satu-satunya dari ketiganya yang memiliki **alur kerja bengkel Honda lengkap di satu aplikasi**: identifikasi K-Line → live data → edit map → tulis ECU + verify → recovery → smartkey/EEPROM I2C (termasuk Yamaha/Suzuki) → dyno. Keunikannya adalah **integrasi vertikal**, bukan keunggulan algoritma yang terbukti.

### TunerPro RT

Platform **definisi-driven** yang generik: ADX/XDF, mesin transaksi dengan timeout/echo eksplisit, plugin checksum, pemrogram chip/emulator Moates. Keunikannya adalah **fleksibilitas** dan **perangkat chip**, bukan pengetahuan Honda.

### RevCore

**Basis kode terbuka yang dapat diaudit** dengan database lebih besar (489 ECM/163 profil), state live eksplisit, integritas 10-gate, dan `FlashEngine` default-deny. Keunikannya adalah **keamanan yang dapat diverifikasi** dan **traceability**.

## 3. Posisi RevCore

| Dimensi | Posisi |
|---|---|
| Database | **unggul** (489/163 vs 160/157) |
| Live data | sejajar secara protokol; unggul pada state, kurang pada jumlah parameter |
| Edit map | sejajar; kurang pada auto-map/2D-3D |
| Flash | **sengaja absen**; lebih aman, belum lengkap |
| Recovery | state saja, tanpa rutin |
| Smartkey/dyno/updater | absen |
| Bukti | paling kuat: kode dapat dibaca dan diuji |

RevCore **bukan** versi "kurang lengkap" dari FLASHPRO. Ia adalah **platform dengan prioritas berbeda**: keselamatan dan auditabilitas di atas cakupan fitur.

## 4. Prioritas pengembangan RevCore

1. **P0-2 checksum vectors** — bisa diselesaikan sekarang, tanpa hardware.
2. **P0-3 DTC** — 24 kode hilang, tetapi dua baris CSV artefak; verifikasi manual dulu.
3. **P0-1/P0-5 protokol tulis + recovery** — hanya dengan adaptor + ECU donor + capture; jangan dipercepat.
4. **P0-4 parameter live** — setelah capture.
5. **P1-1 baca ROM** — langkah antara menuju flash aman.
6. **P1-2/P1-3/P1-4** UI live, auto-map/2D-3D, mode/limiter — setelah fondasi bukti.

Yang **tidak** perlu ditiru: lisensi hardware-bound, updater tanpa signature, dan urutan flash tanpa bukti.

## 5. Mengapa tidak ada pemenang

Work order melarang menentukan pemenang berdasarkan jumlah menu atau klaim pemasaran. Berdasarkan mekanisme:

- FLASHPRO menang pada **cakupan alur kerja**, tetapi seluruh bukti ECU-nya tertutup.
- TunerPro menang pada **fleksibilitas definisi & perangkat chip**, tetapi tidak punya pengetahuan Honda.
- RevCore menang pada **keamanan, database, dan auditabilitas**, tetapi belum menulis ECU.

Tidak ada satu aplikasi yang unggul di semua dimensi, dan tidak ada bukti hardware untuk salah satu pun di BE-12.

## 6. Keyakinan

| Aspek | Keyakinan | Dasar |
|---|---|---|
| Identitas & struktur | TINGGI | hash + metadata + runtime |
| Transport D2XX | TINGGI | P/Invoke + lingkungan |
| Permukaan perintah | SEDANG–TINGGI | nama metode + string |
| Wire-level protocol | RENDAH | tanpa capture |
| Checksum FLASHPRO | RENDAH | tanpa IL/vektor |
| Flash/recovery | RENDAH | tanpa ECU |
| Komparasi fungsional | TINGGI | source/kode kedua sisi |
| Gap analysis | TINGGI | bukti langsung + prioritas eksplisit |

## 7. Pernyataan penutup

FLASHPRO.inc adalah produk komersial tertutup dengan cakupan fitur Honda yang luas dan bukti internal yang sangat terbatas. Autopsi ini berhasil memetakan **apa yang ada dan bagaimana ia disusun**, tetapi tidak berhasil membuktikan **bagaimana algoritmanya bekerja** atau **apakah operasi ECU-nya berhasil**. Itu bukan kekurangan laporan; itu adalah batas yang ditetapkan oleh proteksi, lisensi, dan ketiadaan hardware — dan dilaporkan sebagaimana adanya.

Langkah berikutnya yang paling bernilai bukan menambah fitur RevCore, melainkan **menaikkan status bukti** untuk hal-hal yang sudah ada: checksum, DTC, lalu protokol baca/tulis dengan hardware.
