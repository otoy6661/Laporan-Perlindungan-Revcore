# BE-09 ARTIFACT INDEX

**Workspace:** `C:\Users\Lord Otoy\Documents\REVCORE_EXTERNAL_ECU_RESEARCH`
**Tanggal:** 17 November 2026

Semua path di bawah relatif terhadap workspace. Tidak ada artefak di luar workspace
riset dan tidak ada file sumber BE-09 yang diubah.

---

## 1. FASE A–B — Dataset

| Path | Isi | Jumlah |
|---|---|---:|
| `BIN XDF STANDAR/BIN/` | BIN standar per famili | 148 |
| `BIN XDF EDITED/BIN/` | BIN editan per famili | 392 |
| `UNCLASSIFIED/BIN/` | BIN tanpa penanda/konflik | 160 |
| `BIN XDF STANDAR/XDF/{LOCKED,UNLOCKED}/` | XDF standar | 107 (100 L + 7 U) |
| `UNCLASSIFIED/XDF/{LOCKED,UNLOCKED}/` | XDF tidak terklasifikasi + 3 ADX | 70 (64 L + 6 U) |
| `REPORTS/DATASET_MANIFEST.csv` | 877 baris: sumber, tujuan, SHA-256, status | 877 |
| `REPORTS/BIN_STANDARD_INDEX.csv` | Indeks BIN standar | 148 |
| `REPORTS/BIN_EDITED_INDEX.csv` | Indeks BIN editan | 392 |
| `REPORTS/XDF_LOCKED_INDEX.csv` | Indeks XDF locked | 161 |
| `REPORTS/XDF_UNLOCKED_INDEX.csv` | Indeks XDF unlocked | 13 |
| `REPORTS/XDF_UNKNOWN_INDEX.csv` | Indeks XDF unknown (header saja) | 0 |
| `REPORTS/UNCLASSIFIED_INDEX.csv` | BIN + XDF + ADX tidak terklasifikasi | 230 |
| `REPORTS/DATASET_SUMMARY.json` | Ringkasan angka | — |
| `REPORTS/DATASET_CLASSIFICATION_REPORT.md` | Aturan, konflik, duplikat | — |
| `TOOLS/separate_dataset.ps1` | Skrip pemisahan yang dapat dijalankan ulang | — |

---

## 2. FASE C — Analisis software

| Path | Isi |
|---|---|
| `SOFTWARE_RESEARCH/README.md` | Ringkasan 14 target |
| `SOFTWARE_RESEARCH/HondaECU_3.5.5.2/README.md` | Symbol Cython, transport, batasan |
| `SOFTWARE_RESEARCH/HondaECU_3.3.0/README.md` | PyInstaller onefile |
| `SOFTWARE_RESEARCH/HondaECU_3.0.2/README.md` | PyInstaller onefile |
| `SOFTWARE_RESEARCH/PRO_Remap_BE/README.md` | Binary packed |
| `SOFTWARE_RESEARCH/SCANNER_HONDA/README.md` | Enigma Protector |
| `SOFTWARE_RESEARCH/ANALIST_Pro_5.1/README.md` | Referensi FTD2XX_NET |
| `SOFTWARE_RESEARCH/TunerPro_RT/README.md` | Installer dan XDF |
| `SOFTWARE_RESEARCH/Pin_Out_ECU/README.md` | Dokumentasi pinout |
| `SOFTWARE_RESEARCH/CheksumCalculator/README.md` | Delphi/FMX |
| `SOFTWARE_RESEARCH/CheksumKZR/README.md` | Checksum + ECM ID |
| `SOFTWARE_RESEARCH/FTDI_CDM_Driver/README.md` | Installer driver |
| `SOFTWARE_RESEARCH/REMAP_CABLE_DRIVER/README.md` | Installer driver |
| `SOFTWARE_RESEARCH/FTD2XX_NET/README.md` | Wrapper .NET |
| `SOFTWARE_RESEARCH/OCX_Python_Runtime/README.md` | Runtime |

**Total:** 15 README (14 target + 1 ringkasan).

### Bukti

| Path | Isi | Jumlah file |
|---|---|---:|
| `EVIDENCE/pe/` | `*.meta.json`, `*.strings.ascii.txt`, `*.strings.utf16.txt`, `*.il.txt`, `*.calls.tsv` | 107 |
| `EVIDENCE/pyi/` | `PYI_TOC.tsv` untuk 3 HondaECU | 3 |
| `TOOLS/PeScan/` | Parser PE (sumber) | — |
| `TOOLS/PyExtract/` | Parser PyInstaller (sumber) | — |
| `TOOLS/xdf_scan.ps1` | Pemindai XDF | — |

---

## 3. FASE D — Enam fokus teknis

| Path | Fokus |
|---|---|
| `TECHNICAL_FINDINGS/ECU_IDENTIFICATION_RESEARCH.md` | F1 |
| `TECHNICAL_FINDINGS/BIN_FORMAT_RESEARCH.md` | F2 |
| `TECHNICAL_FINDINGS/XDF_FORMAT_RESEARCH.md` | F2 |
| `TECHNICAL_FINDINGS/TUNERPRO_RT_RESEARCH.md` | F2 |
| `TECHNICAL_FINDINGS/BIN_XDF_MAPPING_EXAMPLES.md` | F2 |
| `TECHNICAL_FINDINGS/ECU_READ_PROCEDURE.md` | F3 |
| `TECHNICAL_FINDINGS/ECU_WRITE_PROCEDURE.md` | F3 |
| `TECHNICAL_FINDINGS/ECU_CHECKSUM_RESEARCH.md` | F3 |
| `TECHNICAL_FINDINGS/ECU_RECOVERY_RESEARCH.md` | F3 |
| `TECHNICAL_FINDINGS/FTDI_API_RESEARCH.md` | F4 |
| `TECHNICAL_FINDINGS/KLINE_COMMUNICATION_RESEARCH.md` | F4 |
| `TECHNICAL_FINDINGS/FTDI_KLINE_PROTOCOL_FLOW.md` | F4 |
| `TECHNICAL_FINDINGS/SMART_KEY_ID_RESEARCH.md` | F5 |
| `TECHNICAL_FINDINGS/LIVE_DATA_INVENTORY.md` | F6 |
| `TECHNICAL_FINDINGS/TPS_CONVERSION_RESEARCH.md` | F6 |
| `TECHNICAL_FINDINGS/AFR_LAMBDA_RESEARCH.md` | F6 |
| `TECHNICAL_FINDINGS/LIVE_DATA_PROTOCOL_MAPPING.md` | F6 |
| `REPORTS/SENSOR_SCALING_REFERENCE.csv` | F6 |

**Total:** 18 artefak (17 MD + 1 CSV).

---

## 4. FASE E — Prototipe

| Path | Isi |
|---|---|
| `PROTOTYPES/README.md` | Arsitektur, build, CLI, batas |
| `PROTOTYPES/src/RevCore.Research.Core/` | 11 file sumber + csproj |
| `PROTOTYPES/src/RevCore.Research.Cli/` | CLI (1 file + csproj) |
| `PROTOTYPES/tests/RevCore.Research.SelfTest/` | 46 assertion |
| `PROTOTYPES/testdata/` | 5 salinan + `PROVENANCE.json` |
| `PROTOTYPES/RESULTS/BUILD.txt` | Log build Release |
| `PROTOTYPES/RESULTS/SELFTEST.txt` | Hasil 46/46 |
| `PROTOTYPES/RESULTS/CLI_SMOKE.txt` | Log CLI |
| `PROTOTYPES/RESULTS/PROTOTYPE_RESULTS.md` | Analisis hasil |
| `PROTOTYPES/RESULTS/k1aa_definitions.csv` | Ekspor 20 definisi XDF |
| `PROTOTYPES/RESULTS/kzrm_b31_10pct.patched.bin` | Salinan uji checksum |

---

## 5. FASE F — Rekomendasi

| Path | Isi |
|---|---|
| `REVCORE_INTEGRATION_RECOMMENDATIONS.md` | Kategori A–D, larangan integrasi, urutan |
| `REVCORE_TECHNICAL_GAP_ANALYSIS.md` | 16 kapabilitas, gap G1–G4 |
| `REVCORE_RESEARCH_PRIORITY.md` | P0–P4, kriteria terima, kriteria berhenti |

---

## 6. FASE G — Laporan akhir

| Path | Isi |
|---|---|
| `BE09_FINAL_RESEARCH_REPORT.md` | Laporan lengkap + audit |
| `BE09_EXECUTIVE_SUMMARY.md` | Ringkasan + keputusan pemilik |
| `BE09_RESEARCH_STATUS.csv` | 58 baris status per item |
| `BE09_ARTIFACT_INDEX.md` | File ini |

---

## 7. Audit kelengkapan persyaratan

| Persyaratan work order | Artefak | Status |
|---|---|---|
| Cek workspace/inventaris | FASE A laporan | ADA |
| Pisahkan BIN/XDF/UNCLASSIFIED | Folder + manifest + 6 indeks | ADA |
| Klasifikasi hanya dari nama/path | `DATASET_CLASSIFICATION_REPORT.md` §3 | ADA |
| Copy, bukan move; duplikat dipertahankan | Manifest + laporan §6 | ADA |
| SHA-256 setiap file | Manifest | ADA (877) |
| Analisis 14 target | 14 README | ADA (14/14) |
| Enam fokus teknis | 18 artefak | ADA (18/18) |
| Prototipe terisolasi + tes | `PROTOTYPES/` | ADA (46/46) |
| Rekomendasi integrasi/gap/prioritas | 3 dokumen FASE F | ADA |
| Laporan akhir + ringkasan + status + indeks | 4 dokumen FASE G | ADA |
| Audit kelengkapan | Laporan akhir §8 + file ini §7 | ADA |

---

## 8. Verifikasi integritas

| Pemeriksaan | Hasil |
|---|---|
| File gagal disalin | 0 |
| Hash sumber vs salinan tidak cocok | 0 |
| EXE/installer/DLL penelitian dijalankan | 0 |
| Koneksi ECU fisik | 0 |
| XDF terkunci didekripsi | 0 |
| File sumber BE-09 diubah | 0 |
| Proyek RevCore diubah | 0 |
| Build prototipe | 3/3 sukses |
| Self-test | 46/46 lulus |
