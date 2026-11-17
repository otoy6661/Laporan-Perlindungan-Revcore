# 13 — PROTOTIPE & TES OTOMATIS

**Work order:** BE-12 — FLASHPRO.inc Full Autopsy
**Fase:** VI (prototipe, verifikasi algoritmik, bukti yang dapat dijalankan ulang)
**Status:** SELESAI — 12/12 tes lulus; **bukan** bukti algoritma internal FLASHPRO.

---

## 1. Tujuan dan batas

Prototipe ini menjawab satu pertanyaan sempit: **apakah algoritma dan struktur data yang diklaim RevCore dapat dieksekusi dan konsisten dengan vektor uji yang diketahui?** Prototipe **tidak** membuktikan bahwa FLASHPRO memakai algoritma yang sama, karena IL payload tidak dapat diambil (EV-021, `BLOCKED`).

| Yang dibuktikan | Yang tidak dibuktikan |
|---|---|
| Implementasi checksum RevCore berjalan sesuai vektor | Checksum internal FLASHPRO |
| Validator frame menolak frame cacat | Format frame FLASHPRO atau capture ECU |
| Katalog DTC FLASHPRO vs RevCore dapat dibandingkan | Arti/kebenaran DTC di ECU fisik |
| Struktur 163 profil RevCore konsisten | Kesesuaian offset profil dengan ROM nyata |

Label bukti yang dipakai: **SIMULATION VERIFIED** untuk hasil eksekusi prototipe; **SOURCE VERIFIED** untuk masukan yang dibaca dari source RevCore.

---

## 2. Isi folder

| Path | Fungsi |
|---|---|
| `tools/checksum.js` | Port algoritma checksum RevCore (`HondaChecksum.kt`, `RomBinary.kt`) |
| `tools/frame_validator.js` | Validator frame Honda ala RevCore + `buildFrame` |
| `tools/dtc_gap.js` | Diff katalog DTC FLASHPRO (CSV) vs `HondaDtcDatabase.kt` |
| `tools/profile_audit.js` | Audit struktur `flashpro_profiles.json` |
| `tests/run_tests.js` | 12 tes deterministik untuk empat tool |
| `RESULTS/01_TEST_HARNESS_OUTPUT.txt` | Keluaran lengkap 12 tes |
| `RESULTS/02_FRAME_VALIDATION_OUTPUT.txt` | Ekstrak uji frame |
| `RESULTS/03_DTC_GAP_OUTPUT.txt` | Diff DTC (24 hilang, 2 ekstra) |
| `RESULTS/04_PROFILE_AUDIT_OUTPUT.json` | Hasil audit profil |
| `RESULTS/05_ENVIRONMENT.txt` | Runtime, hash skrip, verifikasi unduhan |

---

## 3. Cara menjalankan

```bash
# dari folder 13_PROTOTYPES
node tests/run_tests.js
node tools/dtc_gap.js
node tools/profile_audit.js
```

Node tidak tersedia di PATH host saat run; dipakai distribusi resmi portabel `node-v24.22.1-win-x64` yang diverifikasi terhadap `SHASUMS256.txt` (`OK`). Detail di `RESULTS/05_ENVIRONMENT.txt`.

---

## 4. Hasil

```
PASS | sum8 [01 02 03] = FA | FA, appended sum=0
PASS | keihin16 [12 34 56 78] = 68AC | 0x68AC
PASS | inverted8 edge cases | FF, 00, FC
PASS | CRC16/MODBUS check "123456789" = 4B37 | 0x4B37
PASS | shindengenAdditive [FF FF] = 01FE | 0x01FE
PASS | frame valid 72 04 03 87 | service=0x3
PASS | frame reject bad checksum | bad-checksum
PASS | frame reject length mismatch | length-mismatch,bad-checksum
PASS | frame reject unknown header | bad-header,bad-checksum
PASS | buildFrame roundtrip + negative response flag | 72057F10FA
PASS | DTC catalogs parse and gap computed | flashpro=37 revcore=15 missing=24
PASS | profile audit structure | count=163 withOffsets=162 unique=163 problems=0 maxOffset=0x4256C

RESULT 12/12 passed
```

### 4.1 Checksum

| Vektor | Hasil | Dasar |
|---|---|---|
| `[01 02 03]` SUM dua-komplemen | `FA`; total frame = 0 | Definisi checksum RevCore |
| `[12 34 56 78]` Keihin 16-bit | `68AC` | Penjumlahan word big-endian & `0xFFFF` |
| `[00]`, `[FF]`, `[01 02]` inverted 8-bit | `FF`, `00`, `FC` | `sum XOR 0xFF` |
| `"123456789"` CRC-16 | `4B37` | Seed `0xFFFF`, poly `0xA001` (konvensi MODBUS) |
| `[FF FF]` additive 16-bit | `01FE` | Penjumlahan & `0xFFFF` |

CRC `4B37` adalah nilai uji standar untuk parameter seed/poly tersebut. Ini **tidak** membuktikan byte-order penyimpanan SHINDENGEN di ECU; hanya membuktikan fungsi RevCore berjalan sesuai parameter yang dideklarasikan.

### 4.2 Frame

- Frame valid `72 04 03 87` diterima (header `0x72`, panjang 4, service `0x03`).
- Checksum salah, panjang salah, dan header tak dikenal ditolak dengan alasan eksplisit.
- `buildFrame(0x72, 0x7F, [0x10])` → `72 05 7F 10 FA`, dan `negative=true` terdeteksi.

Struktur ini adalah **struktur RevCore** (header, length, service, checksum), bukan spesifikasi FLASHPRO. Tidak ada capture RX mentah (`NO RAW RX CAPTURE`).

### 4.3 DTC

- FLASHPRO: **37** baris; RevCore: **15** entri.
- **24** kode FLASHPRO tidak ada di RevCore; **2** kode RevCore tidak ada di FLASHPRO (`7-0`→P0115, `33-1`→P0605).
- Dua baris CSV FLASHPRO berisi kode lain di kolom deskripsi: `25-3 → "29-1"` dan `57-2 → "86-1"`. Ini indikasi **artefak ekstraksi** metadata, bukan DTC sebenarnya.
- Baris `21-1` dan `23-1` mengandung karakter `O₂` yang rusak encoding (`0â‚‚`), juga artefak ekstraksi.

### 4.4 Profil

- `count = 163`, seluruh 163 `index` berurutan, tidak ada field wajib hilang, tidak ada `ecmId` duplikat/placeholder.
- 162 profil memiliki minimal satu offset > 0; offset maksimum `0x4256C`.
- Audit **tidak** memvalidasi bahwa offset menunjuk alamat ROM yang benar; itu memerlukan BIN/ECU.

---

## 5. Konsekuensi untuk RevCore

1. Empat algoritma checksum RevCore dapat direproduksi dan diuji; jadikan vektor di atas sebagai **regression test** di repositori RevCore.
2. Tambahkan **24 DTC** yang hilang hanya setelah diverifikasi ke sumber Honda; dua baris artefak harus diabaikan sampai sumbernya jelas.
3. Audit profil sebaiknya dijalankan otomatis pada CI untuk mencegah regresi `flashpro_profiles.json`.
4. Jangan memakai prototipe ini sebagai bukti kompatibilitas FLASHPRO; ia hanya memverifikasi sisi RevCore.

---

## 6. Keterbatasan

| Aspek | Status |
|---|---|
| Algoritma FLASHPRO | `BLOCKED` (IL tidak tersedia) |
| Capture frame ECU | `NOT TESTED` (tidak ada adaptor/ECU) |
| Uji tulis ECU | `NOT TESTED` (dilarang oleh work order) |
| Sumber DTC FLASHPRO | Turunan metadata; dua baris terbukti artefak |
| Node.js | Runtime portabel di luar workspace; tidak untuk publikasi |

Tidak ada klaim bahwa hasil ini meningkatkan status FLASHPRO dari `STATIC VERIFIED` menjadi `RUNTIME/HARDWARE VERIFIED`.
