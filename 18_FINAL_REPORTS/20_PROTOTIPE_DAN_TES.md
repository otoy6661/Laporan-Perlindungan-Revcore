# 20 — PROTOTIPE DAN TES

**Work order:** BE-12
**Status:** SIMULATION VERIFIED (12/12 lulus) · **bukan** bukti algoritma FLASHPRO
**Sumber:** `13_PROTOTYPES/README.md`, `RESULTS/`

---

## 1. Tujuan

Menjawab pertanyaan sempit: apakah algoritma dan struktur data yang diklaim RevCore dapat dieksekusi dan konsisten dengan vektor uji? Prototipe **tidak** membuktikan FLASHPRO memakai algoritma yang sama.

## 2. Isi

| Path | Fungsi |
|---|---|
| `tools/checksum.js` | port checksum RevCore |
| `tools/frame_validator.js` | validator frame + `buildFrame` |
| `tools/dtc_gap.js` | diff DTC FLASHPRO vs RevCore |
| `tools/profile_audit.js` | audit 163 profil |
| `tests/run_tests.js` | 12 tes deterministik |
| `RESULTS/01…05` | output, diff, audit, environment |

## 3. Eksekusi

Node tidak ada di PATH host; dipakai distribusi resmi portabel `node-v24.22.1-win-x64`, diverifikasi terhadap `SHASUMS256.txt` (**OK**), SHA-256 arsip `d2046d28…b95fa5`. Runtime berada di luar workspace dan tidak termasuk artefak publikasi.

## 4. Hasil

```
PASS | sum8 [01 02 03] = FA
PASS | keihin16 [12 34 56 78] = 68AC
PASS | inverted8 edge cases | FF, 00, FC
PASS | CRC16/MODBUS check "123456789" = 4B37
PASS | shindengenAdditive [FF FF] = 01FE
PASS | frame valid 72 04 03 87 | service=0x3
PASS | frame reject bad checksum
PASS | frame reject length mismatch
PASS | frame reject unknown header
PASS | buildFrame roundtrip + negative response | 72057F10FA
PASS | DTC catalogs parse and gap computed | flashpro=37 revcore=15 missing=24
PASS | profile audit structure | count=163 withOffsets=162 unique=163 problems=0 maxOffset=0x4256C

RESULT 12/12 passed
```

## 5. Temuan

### Checksum

Vektor SUM8/Keihin16/inverted8/CRC16/additive semuanya sesuai. CRC `4B37` adalah nilai uji standar untuk seed `FFFF`/poly `A001`; ini membuktikan fungsi berjalan, bukan byte-order penyimpanan SHINDENGEN di ECU.

### Frame

Frame valid diterima; checksum/panjang/header cacat ditolak. `buildFrame(0x72,0x7F,[0x10])` menghasilkan `72 05 7F 10 FA` dan `negative=true`. Struktur ini milik RevCore, bukan capture FLASHPRO.

### DTC

- 37 baris FLASHPRO vs 15 entri RevCore; 24 hilang, 2 ekstra (`7-0`/P0115, `33-1`/P0605).
- Dua baris CSV berisi kode lain di deskripsi (`25-3→29-1`, `57-2→86-1`) — artefak ekstraksi.
- `21-1`/`23-1` mengandung `O₂` rusak encoding.

### Profil

163 profil, index berurutan, tanpa field hilang/duplikat/placeholder; 162 punya offset; offset maks `0x4256C`. Audit tidak memvalidasi alamat ROM sebenarnya.

## 6. Konsekuensi

1. Empat tipe checksum image RevCore + checksum frame SUM8 layak dijadikan **regression test**.
2. 24 DTC hanya ditambahkan setelah verifikasi manual servis; dua baris artefak diabaikan.
3. Audit profil sebaiknya masuk CI.
4. Prototipe tidak menaikkan status FLASHPRO; ia hanya memverifikasi sisi RevCore.

## 7. Batas

| Aspek | Status |
|---|---|
| Algoritma FLASHPRO | BLOCKED |
| Capture frame ECU | NOT TESTED |
| Uji tulis ECU | NOT TESTED (dilarang) |
| Sumber DTC FLASHPRO | turunan metadata; dua baris artefak |
| Node.js | runtime portabel, tidak untuk publikasi |

Tidak ada klaim bahwa hasil ini meningkatkan status FLASHPRO dari STATIC VERIFIED menjadi RUNTIME/HARDWARE VERIFIED.
