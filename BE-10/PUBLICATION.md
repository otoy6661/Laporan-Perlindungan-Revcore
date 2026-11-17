# BE-10 — Paket Publikasi Riset Teknis

**Identitas paket:** BE-10 — Deep Technical Research: ADX + 3D Chart Graph + ECU Software
**Versi publikasi:** 1.0 (17 November 2026)
**Sumber:** `C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH`
**Persetujuan pemilik:** UPLOAD KE REPOSITORY (dipilih 17 November 2026)

## 1. Sifat paket

Ini adalah **salinan publikasi** dari laporan BE-10. File sumber di workspace riset
tidak dipindahkan, tidak diubah, dan tidak ditimpa. Salinan ini dibuat khusus untuk
repositori `otoy6661/Laporan-Revcore`, branch `main`.

Seluruh hasil pengujian, angka, status, dan isi laporan dipertahankan apa adanya.
Tidak ada hasil tes yang diubah agar "cocok" dengan struktur repositori.

## 2. Isi paket

| Lokasi | Isi |
|---|---|
| `BE10_*.md` (11 file) | Laporan lengkap, termasuk ringkasan eksekutif, laporan akhir 9 pertanyaan, analisis ADX, analisis source 3D Chart Graph, temuan protokol ECU, relasi BIN/XDF/ADX, pendalaman 14 software, hasil prototipe, rekomendasi RevCore, gap analysis, indeks artefak |
| `BE10_RESEARCH_STATUS.csv` | Register status 76 baris, hanya memakai kosakata status yang diizinkan |
| `README.md` | README workspace riset (cara reproduksi prototipe) |
| `REPORTS/BE10_SENSOR_LIVE_DATA_CATALOG.csv` | 45 kanal live data dengan formula dan dasar bukti |
| `REPORTS/BE10_SHA256_MANIFEST.csv` | Manifest provenance 552 entri (metadata hash, bukan isi file) |
| `ANALYSIS/*.ps1` (23 skrip) | Skrip analisis statis yang menghasilkan bukti |
| `RESULTS/SELFTEST.txt` | Log 26/26 tes prototipe, termasuk hash input sebelum/sesudah |
| `RESULTS/BE10_PROTOTYPE_TESTS.csv` | Register 26 tes |
| `RESULTS/BE10_TABLE_VALIDATION.csv` | Validasi 5 BIN sampel terhadap database 152 model |

## 3. Yang sengaja TIDAK dipublikasikan

Sesuai Work Order BE-10 butir 10 (larangan mengunggah source donasi ke publik) dan
pemeriksaan keamanan, paket ini **tidak** memuat:

- File ADX donasi (Keihin/Shindengen), arsip 7z, dan kedua ZIP 3D Chart Graph.
- Source code pihak ketiga (208 file) dan 154 BIN yang tertanam di aplikasi.
- Salinan `PROTOTYPES/testdata/` (9 file BIN/ADX/CSV donasi).
- Dump mentah hasil ekstraksi resource aplikasi (`3D_MAP_DATABASE.csv`,
  `3D_ECU_ID_DATABASE.csv`).
- Dump byte mentah header ADX (`ADX_BYTE_SCAN.txt`, `ADX_XDF_LAYOUT_PROOF.txt`).
- Permukaan bahan bakar lengkap 35 x 29 (`BE10_K1AA_FUEL_GRAPH.csv`) dan salinan
  kerja `work_k1aa.bin`.
- `lic.kye` atau nilai lisensi/kunci apa pun.

Artefak yang dikecualikan tetap berada di workspace riset lokal. Laporan tetap
memuat temuan agregat, statistik, offset, dan formula yang menjadi inti riset.

## 4. Pemeriksaan keamanan dan integritas

- Tidak ada kredensial, password, private key, token, atau nilai lisensi di paket.
- Nilai kunci AES yang disebut di laporan tidak direproduksi (hanya keberadaannya).
- Encoding seluruh file teks: UTF-8 tanpa BOM; tidak ada mojibake atau karakter CJK.
- Hash setiap file salinan publikasi dibandingkan dengan file sumber; identik.
- 15/15 file wajib BE-10 tersedia di paket ini.
- Prototipe: 26/26 self-test lulus, 5/5 validasi BIN lulus (dijalankan ulang sebelum publikasi).

## 5. Catatan keterlacakan

Path yang disebut di dalam laporan (misalnya `ANALYSIS\...`, `PROTOTYPES\testdata\...`)
merujuk pada workspace riset asli, bukan struktur repositori ini. Manifest 552 entri
mencakup artefak lokal yang tidak semuanya dipublikasikan; hash tersebut adalah bukti
provenance, bukan tautan unduhan.

Batas status tetap berlaku: payload ADX `BLOCKED_BY_ACCESS_REQUIREMENT`, perilaku ECU
fisik `HARDWARE_PENDING`, dan tidak ada klaim bahwa fitur yang ditulis sudah terverifikasi
di hardware.
