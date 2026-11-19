# Repository Update & Remote Verification

Repository: `https://github.com/otoy6661/Laporan-Revcore`
Branch: `main`
Date: 2026-11-19

## 1. Sebelum pembaruan

| Item | Nilai |
|---|---|
| HEAD remote | `9b7037e` (`Add files via upload`) |
| Jumlah file terlacak | 136 |
| Isi | Laporan BE-11/BE-12 (FLASHPRO.inc) + 3 screenshot |

## 2. Tindakan

1. Clone repository (riwayat penuh).
2. Catat 136 file lama ke `06_REPOSITORY/REMOVED_OLD_FILES.txt`.
3. Hapus seluruh isi kerja lama kecuali `.git`.
4. Susun struktur baru: inventory, H-Diag, evidence, 7 laporan wajib, artefak.
5. Pertahankan 3 screenshot unggahan pemilik (`9b7037e`) dengan memindahkannya ke `05_ARTIFACTS/legacy_screens/`.
6. Commit normal, tanpa force push, tanpa amend, tanpa menulis ulang sejarah.
7. Push ke `origin main`.

## 3. Commit

| Item | Nilai |
|---|---|
| Commit ID | `138226dfb1983ae890927daea91c9ba2755c1d54` |
| Pesan | `BE-13: replace report root with H-Diag and 3D Chart reference autopsy` |
| Orang tua | `9b7037e` (riwayat utuh) |
| File di tree baru | 21 |
| File lama dihapus dari kondisi terbaru | 136 (masih ada di riwayat) |

## 4. Push

```
To https://github.com/otoy6661/Laporan-Revcore.git
   9b7037e..138226d  main -> main
```

## 5. Verifikasi remote (bukan hanya pesan push)

| Pemeriksaan | Hasil |
|---|---|
| `git ls-remote origin refs/heads/main` | `138226dfb1983ae890927daea91c9ba2755c1d54` |
| `git fetch` + `git rev-parse origin/main` | `138226dfb1983ae890927daea91c9ba2755c1d54` |
| `HEAD == origin/main` | Ya |
| `git ls-tree -r origin/main` jumlah file | 21 |
| `raw.githubusercontent.com` README | HTTP 200 |
| `raw.githubusercontent.com` H-Diag report | HTTP 200 |
| `raw.githubusercontent.com` sensor report | HTTP 200 |
| `raw.githubusercontent.com` remap report | HTTP 200 |
| Riwayat commit lama | Utuh; `9b7037e` tetap menjadi parent |

## 6. Isi tree baru

```
.gitattributes
00_INVENTORY/SOURCE_INVENTORY.csv
01_HDIAG/STRINGS_HDiag.exe.tsv
01_HDIAG/STRINGS_HDiag.exe_comma.tsv
03_EVIDENCE/3DCHART_SOURCE_EVIDENCE.md
03_EVIDENCE/HDIAG_STATIC_EVIDENCE.md
03_EVIDENCE/PROTOCOL_FRAME_VALIDATION.csv
03_EVIDENCE/UNREADABLE_OR_BLOCKED.md
04_FINAL_REPORTS/HDIAG_AUTOPSY_REPORT.md
04_FINAL_REPORTS/HDIAG_FUNCTION_MAPPING.md
04_FINAL_REPORTS/HDIAG_PROTOCOL_ANALYSIS.md
04_FINAL_REPORTS/HDIAG_REVCORE_REQUIREMENTS_04_10.md
04_FINAL_REPORTS/REVCORE_REFERENCE_ANALYSIS_SUMMARY.md
04_FINAL_REPORTS/REVCORE_REMAP_FUNCTION_ANALYSIS.md
04_FINAL_REPORTS/REVCORE_SENSOR_READING_ANALYSIS.md
05_ARTIFACTS/legacy_screens/screen_dtc_demo.png
05_ARTIFACTS/legacy_screens/screen_pause_log.png
05_ARTIFACTS/legacy_screens/screen_probe_live_demo.png
06_REPOSITORY/REMOVED_OLD_FILES.txt
PUBLICATION_SANITIZATION.md
README.md
```

`PUBLICATION_MANIFEST.csv` ditambahkan pada commit lanjutan setelah manifest dihitung.

## 7. Catatan

- Tidak ada credential/token/PII yang diunggah.
- Tidak ada binary pihak ketiga baru; hanya screenshot yang sudah ada di repository.
- `login.ini`, keygen, dan binary H-Diag tidak diunggah.
- File lama masih dapat diakses melalui commit `9b7037e` dan sebelumnya.

## 8. Pembaruan Tahap 2 (2026-11-19)

Work order: DEEP AUTOPSY TAHAP 2 / H-Diag 2.1 & 3D Chart Graph Remap K-Line.

| Item | Tindakan |
|---|---|
| Laporan Tahap 1 | Tidak diubah; tetap sebagai riwayat |
| File baru | 7 dokumen Tahap 2 + 3 bukti Tahap 2 + `CHANGELOG.md` |
| File diperbarui | `README.md` (indeks Tahap 2), `PUBLICATION_MANIFEST.csv` (hash ulang), laporan ini |
| Commit | Commit normal di atas `89f8bde`; tanpa force push, tanpa hapus riwayat |
| Isi sensitif | Tidak ada; algoritma kunci seed/key tidak diuraikan, keygen tidak disentuh |
| Verifikasi | `HEAD == origin/main` dan `raw.githubusercontent.com` dicek setelah push |

Rincian perubahan per file ada di `CHANGELOG.md`. Hash commit Tahap 2 dicatat pada laporan akhir yang disampaikan ke pemilik.
