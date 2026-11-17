# RevCore Research — Paket Kerja Terkini (BE-10)

Repository ini berisi **satu paket hasil kerja terkini** di root. Publikasi baru
menggantikan seluruh isi publikasi sebelumnya, tetapi riwayat Git dipertahankan.
Tidak ada folder arsip berdasarkan nomor pekerjaan (BE-09/BE-10/BE-11) di root.

**Paket:** BE-10 — Deep Technical Research: ADX + 3D Chart Graph + ECU Software
**Tanggal:** 17 November 2026
**Sumber lokal:** `C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH` (tidak diubah)

## 1. Titik masuk

1. `BE10_EXECUTIVE_SUMMARY.md` — ringkasan hasil
2. `BE10_FINAL_RESEARCH_REPORT.md` — laporan lengkap yang menjawab 9 pertanyaan
3. `BE10_ECU_PROTOCOL_FINDINGS.md` — K-Line, checksum, seed/key, tulis/recovery
4. `BE10_ADX_ANALYSIS.md` — struktur kontainer ADX
5. `BE10_SELFTEST.txt` — log 26/26 tes prototipe

## 2. Isi paket

| Kategori | Jumlah | Keterangan |
|---|---:|---|
| Laporan dan dokumentasi (`.md`) | 13 | 11 laporan BE-10, README workspace asli, README ini |
| Data dan register (`.csv`) | 5 | Status riset, katalog 45 kanal sensor, manifest provenance 552 entri, register 26 tes, validasi 5 BIN |
| Hasil pengujian (`.txt`) | 1 | `BE10_SELFTEST.txt` (26/26 lulus, hash input sebelum/sesudah) |
| Skrip analisis (`.ps1`) | 23 | Pembangkit bukti ADX, layout, statistik database, manifest |
| Source prototipe (`.cs`, `.csproj`) | 10 | `src/BE10Tools/` — ADX inspector, pembaca/edit tabel, checksum, protokol, live data, formula, test runner |

Seluruh 52 artefak konten di atas berstatus **DIRECTLY_READABLE**: teks UTF-8 yang
dapat dibaca langsung melalui GitHub. Tidak ada artefak `READABLE_WITH_LIMITATIONS`
dalam paket ini. `PUBLICATION_MANIFEST.csv` mencatat nama, kategori, ekstensi,
ukuran, dan SHA-256 setiap file (manifest tidak memuat dirinya sendiri).

## 3. Source prototipe

`src/BE10Tools/` adalah source C# .NET 8 yang menghasilkan angka pada laporan:

- `Adx/AdxInspector.cs` — inspeksi kontainer ADX
- `Maps/BinTableReader.cs`, `MapDatabase.cs`, `Interpolation.cs` — pembacaan tabel BIN, database 152 model, interpolasi
- `Protocol/HondaProtocol.cs`, `LiveData.cs` — frame K-Line, checksum, seed/key, dekode live data
- `Formula/SimpleFormula.cs` — evaluator formula
- `Tests/TestRunner.cs` — 26 tes
- `Program.cs`, `BE10Tools.csproj`

Proyek merujuk salinan uji relatif (`..\..\testdata\`). Salinan BIN/ADX donasi tidak
dipublikasikan, sehingga build dapat dilakukan tetapi eksekusi tes memerlukan
penyediaan data uji lokal sendiri.

## 4. Yang tidak dipublikasikan

| Artefak | Alasan |
|---|---|
| ADX Keihin/Shindengen, arsip 7z, dua ZIP 3D Chart Graph | Kontainer terenkripsi/arsip; bukan teks yang dapat dianalisis langsung |
| Source aplikasi pihak ketiga (208 file) | Materi donasi; tidak boleh dipublikasikan (Work Order BE-10 butir 10) |
| 154 BIN tertanam + salinan `testdata/` (9 file) | Biner donasi; tidak dapat dibaca langsung sebagai teks |
| `3D_MAP_DATABASE.csv`, `3D_ECU_ID_DATABASE.csv` | Dataset hasil ekstraksi resource aplikasi donasi; dibatasi |
| `ADX_BYTE_SCAN.txt`, `ADX_XDF_LAYOUT_PROOF.txt` | Dump byte mentah header ADX donasi; dibatasi |
| `BE10_K1AA_FUEL_GRAPH.csv`, `work_k1aa.bin` | Permukaan bahan bakar lengkap dan salinan kerja dari BIN donasi; dibatasi |
| `lic.kye`, nilai lisensi/kunci | Sensitif; tidak pernah disalin |
| `bin/`, `obj/` | Artefak build yang dihasilkan, bukan source |

Laporan tetap memuat temuan agregat, offset, formula, dan statistik yang menjadi inti
riset. Artefak yang dikecualikan tetap berada di workspace riset lokal.

## 5. Verifikasi

- 15/15 file wajib BE-10 tersedia.
- Self-test prototipe: **26/26 lulus, 0 gagal** (`BE10_SELFTEST.txt`).
- Validasi tabel BIN: **5/5** (`BE10_TABLE_VALIDATION.csv`).
- Katalog sensor: **45 kanal** (`BE10_SENSOR_LIVE_DATA_CATALOG.csv`).
- Manifest provenance lokal: **552 entri** (`BE10_SHA256_MANIFEST.csv`).
- Tidak ada kredensial, password, private key, token, atau nilai lisensi.
- Encoding UTF-8 tanpa BOM; tidak ada mojibake.
- Hash setiap file publikasi dibandingkan dengan sumbernya; identik byte-per-byte.

## 6. Batas status

`IMPLEMENTED` tidak pernah diperlakukan sebagai `VERIFIED`. Payload ADX berstatus
`BLOCKED_BY_ACCESS_REQUIREMENT`; perilaku terhadap ECU fisik berstatus
`HARDWARE_PENDING`. Tidak ada ECU fisik yang dihubungi dan tidak ada perintah tulis
ECU yang dijalankan.

## 7. Reproduksi

```
cd src/BE10Tools
dotnet build -c Release
dotnet run -c Release --no-build -- selftest
```

Data uji harus disediakan lokal; lihat `BE10_RESEARCH_README.md` untuk perintah lengkap
dan `BE10_PROTOTYPE_RESULTS.md` untuk hasil.
