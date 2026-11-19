# Laporan RevCore — Reference Autopsy (H-Diag + 3D Chart Remap K-Line)

Status: analisis referensi teknis. Bukan implementasi, bukan clone, bukan aplikasi baru.

Tanggal: 2026-11-19
Work order: REVCORE REFERENCE AUTOPSY — BAGIAN I & II

## Isi

| Folder | Isi |
|---|---|
| `00_INVENTORY/` | Inventaris 869 file (H-Diag 29, 3D Chart 840) dengan SHA-256 |
| `01_HDIAG/` | Ekstraksi string `HDiag.exe` |
| `03_EVIDENCE/` | Register bukti statis, verifikasi checksum frame, file yang dibatasi |
| `04_FINAL_REPORTS/` | Tujuh dokumen wajib |
| `05_ARTIFACTS/` | Artefak pendukung (screenshot lama yang dipertahankan) |
| `06_REPOSITORY/` | Daftar file lama yang diganti + laporan pembaruan repository |

## Laporan wajib

### H-Diag
- [HDIAG_AUTOPSY_REPORT.md](04_FINAL_REPORTS/HDIAG_AUTOPSY_REPORT.md)
- [HDIAG_FUNCTION_MAPPING.md](04_FINAL_REPORTS/HDIAG_FUNCTION_MAPPING.md)
- [HDIAG_PROTOCOL_ANALYSIS.md](04_FINAL_REPORTS/HDIAG_PROTOCOL_ANALYSIS.md)
- [HDIAG_REVCORE_REQUIREMENTS_04_10.md](04_FINAL_REPORTS/HDIAG_REVCORE_REQUIREMENTS_04_10.md)

### 3D Chart Graph Remap K-Line
- [REVCORE_SENSOR_READING_ANALYSIS.md](04_FINAL_REPORTS/REVCORE_SENSOR_READING_ANALYSIS.md)
- [REVCORE_REMAP_FUNCTION_ANALYSIS.md](04_FINAL_REPORTS/REVCORE_REMAP_FUNCTION_ANALYSIS.md)

### Ringkasan
- [REVCORE_REFERENCE_ANALYSIS_SUMMARY.md](04_FINAL_REPORTS/REVCORE_REFERENCE_ANALYSIS_SUMMARY.md)

## Bukti utama

- [HDIAG_STATIC_EVIDENCE.md](03_EVIDENCE/HDIAG_STATIC_EVIDENCE.md)
- [3DCHART_SOURCE_EVIDENCE.md](03_EVIDENCE/3DCHART_SOURCE_EVIDENCE.md)
- [PROTOCOL_FRAME_VALIDATION.csv](03_EVIDENCE/PROTOCOL_FRAME_VALIDATION.csv)
- [UNREADABLE_OR_BLOCKED.md](03_EVIDENCE/UNREADABLE_OR_BLOCKED.md)

## Tingkat bukti

| Label | Arti |
|---|---|
| FAKTA / SOURCE VERIFIED | Terbaca langsung dari string, konstanta, kode, atau aritmetika |
| REKONSTRUKSI | Diturunkan dari disassembly; bukan source |
| DUGAAN | Indikasi kuat, belum terbukti |
| SIMULASI | Hasil simulasi (tidak ada dalam pekerjaan ini) |
| UJI PERANGKAT | Pengujian perangkat fisik (tidak ada) |
| UJI ECU | Pengujian ECU nyata (tidak ada) |
| TIDAK DITEMUKAN | Tidak ada bukti |
| BELUM DIUJI | Ada implementasi, belum diverifikasi |

Prinsip: **IMPLEMENTED ≠ VERIFIED**. Tidak ada klaim keberhasilan ECU.

## Batas publikasi

Tidak dipublikasikan:

- `login.ini` atau kode lisensi.
- Key/IV AES lisensi.
- `keygen.exe` / alat bypass lisensi.
- Binary H-Diag, DLL Qt/driver, atau source lengkap pihak ketiga.
- Credential, token, atau data pribadi.

Yang dimuat hanya temuan analisis, potongan kode pendek sebagai bukti, tabel protokol, dan hash.

## Catatan penting untuk RevCore

1. Format frame dan checksum K-line terbukti dan dapat dipakai.
2. Formula sensor berasal dari source 3D Chart, belum diuji ECU.
3. H-Diag tidak membuktikan perintah/byte per parameter; jangan menganggap nama di UI sebagai dukungan penuh.
4. Altitude Mode: hanya pembacaan yang ditemukan; set Mode 1–4 **tidak terbukti**.
5. Remap: tidak ada read-back verification pada aplikasi referensi; RevCore harus menambahkannya.

## Sanitasi & manifest

- [PUBLICATION_SANITIZATION.md](PUBLICATION_SANITIZATION.md)
- [PUBLICATION_MANIFEST.csv](PUBLICATION_MANIFEST.csv)
