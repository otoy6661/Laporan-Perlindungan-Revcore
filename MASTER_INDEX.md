# BE-12 — MASTER INDEX

**Workspace:** `C:\Users\<USER>\Documents\REVCORE_BE12_FLASHPRO_AUTOPSY`
**Status:** FASE 0–VI selesai · 22 laporan final selesai · dipublikasikan 2026-11-18
**Terakhir diperbarui:** 2026-11-18 (lokal)

---

## 1. Dokumen akar

| Dokumen | Isi | Status |
|---|---|---|
| `README.md` | aturan, temuan, peta folder, verifikasi | Final |
| `RESEARCH_SCOPE.md` | lingkup, batas, standar bukti, urutan fase | Final |
| `EXECUTIVE_SUMMARY.md` | ringkasan eksekutif final | Final |
| `MASTER_INDEX.md` | dokumen ini | Final |
| `COVERAGE_MATRIX.csv` | cakupan per area | Final |
| `EVIDENCE_REGISTER.csv` | EV-001…EV-026 | Final |

## 2. FASE 0 — inventaris & provenance

| Artefak | Isi |
|---|---|
| `00_SOURCE_INVENTORY/PROVENANCE.md` | identitas, timeline, wrapper, payload vs installer |
| `FLASHPRO_FILE_INVENTORY.csv/.json` | 7 file: hash, PE, versi, signature |
| `verify_wrapper.ps1` | verifier format wrapper (read-only) |
| `WRAPPER_LAYOUT_VERIFIED.csv/.txt` | hasil verifikasi 3 wrapper |
| `APP_COPY/` | salinan kerja (binary; **tidak untuk publikasi**) |
| `17_EVIDENCE/EV001…EV005` | inventaris, wrapper, timeline, environment, payload |

## 3. 22 laporan final (`18_FINAL_REPORTS/`)

| No | Laporan | Artefak pendukung | Status |
|---:|---|---|---|
| 01 | `01_IDENTIFIKASI_PRODUK.md` | `00_SOURCE_INVENTORY` | Selesai |
| 02 | `02_INVENTARIS_FILE.md` | `00_SOURCE_INVENTORY` | Selesai |
| 03 | `03_ARSITEKTUR_APLIKASI.md` | `01_APPLICATION_ANATOMY` | Selesai |
| 04 | `04_ANALISIS_STATIS.md` | `02_STATIC_ANALYSIS` | Selesai |
| 05 | `05_ANALISIS_RUNTIME.md` | `03_RUNTIME_ANALYSIS` | Selesai |
| 06 | `06_HARDWARE_DAN_DRIVER.md` | `10_HARDWARE_DRIVER` | Selesai |
| 07 | `07_PROTOKOL_KOMUNIKASI_ECU.md` | `04_PROTOCOL_AUTOPSY` | Selesai |
| 08 | `08_IDENTIFIKASI_ECU.md` | `05_ECU_IDENTIFICATION` | Selesai |
| 09 | `09_LIVE_DATA_DAN_SENSOR.md` | `06_LIVE_DATA_AUTOPSY` | Selesai |
| 10 | `10_BIN_DAN_ROM.md` | `07_BIN_MAP_AUTOPSY` | Selesai |
| 11 | `11_MAP_DAN_KALIBRASI.md` | `07_BIN_MAP_AUTOPSY` | Selesai |
| 12 | `12_ANALISIS_CHECKSUM.md` | `08_CHECKSUM_AUTOPSY` | Selesai |
| 13 | `13_FLASHING_DAN_RECOVERY.md` | `09_FLASHING_RECOVERY` | Selesai |
| 14 | `14_ARSITEKTUR_LISENSI.md` | `11_LICENSE_ARCHITECTURE` | Selesai |
| 15 | `15_KOMPARASI_TUNERPRO.md` | `14_TUNERPRO_COMPARISON` | Selesai |
| 16 | `16_KOMPARASI_REVCORE.md` | `15_REVCORE_COMPARISON` | Selesai |
| 17 | `17_MATRIKS_TIGA_ARAH.md` | `16_THREE_WAY_COMPARISON` | Selesai |
| 18 | `18_KOMPARASI_PROTOKOL_TIGA_ARAH.md` | `16_THREE_WAY_COMPARISON` | Selesai |
| 19 | `19_GAP_ANALYSIS_REVCORE.md` | `15_REVCORE_COMPARISON` | Selesai |
| 20 | `20_PROTOTIPE_DAN_TES.md` | `13_PROTOTYPES` | Selesai |
| 21 | `21_BUKTI_DAN_CAKUPAN.md` | `17_EVIDENCE` | Selesai |
| 22 | `22_KESIMPULAN_TEKNIS.md` | semua | Selesai |

## 4. FASE lain

| Fase | Artefak | Status |
|---|---|---|
| I — anatomi | `01_APPLICATION_ANATOMY/ARCHITECTURE.md`, `UI_MENU_MAP.md` | Selesai |
| II — autopsi | `02_STATIC_ANALYSIS/`, `04…11_*` | Selesai (algoritma NOT VERIFIED) |
| III — runtime | `03_RUNTIME_ANALYSIS/`, `12_EXPERIMENTS/E01` | Selesai; E02/E03 NOT TESTED |
| IV — TunerPro | `14_TUNERPRO_COMPARISON/` | Selesai |
| V — RevCore | `15_REVCORE_COMPARISON/`, `16_THREE_WAY_COMPARISON/` | Selesai |
| VI — prototipe | `13_PROTOTYPES/` (12/12 PASS) | Selesai |

## 5. Log keputusan & koreksi

| Tanggal | Peristiwa |
|---|---|
| 2026-11-18 | Workspace dibuat; salinan kerja; hash 7 file |
| 2026-11-18 | Tiga EXE = wrapper VB6; payload = file installer (verified) |
| 2026-11-18 | Format wrapper didekodkan & diverifikasi 3/3 |
| 2026-11-18 | Koreksi: `flashpro.exe`+U+00A0 dibaca via salinan `flashpro_nbsp.exe` |
| 2026-11-18 | Metadata runtime berhasil (235.832 B); IL BLOCKED |
| 2026-11-18 | E01 selesai; E02/E03 tidak dijalankan (UAC/pihak ketiga) |
| 2026-11-18 | Koreksi hitungan DTC RevCore: 15 (bukan 16) |
| 2026-11-18 | Koreksi ECUTYPE: 6 nilai + `value__` |
| 2026-11-18 | Koreksi rentang baris string (BIN 650–809; part 1805–1838) |
| 2026-11-18 | FASE VI: 12/12 tes lulus; Node portabel terverifikasi |
| 2026-11-18 | Ditemukan 2 baris CSV DTC artefak (25-3, 57-2) |
| 2026-11-18 | Koreksi: ftd2xx memiliki 12 fungsi unik (bukan 13) |
| 2026-11-18 | 22 laporan final selesai; tidak ada publikasi |

## 6. Aturan yang tetap berlaku

- Instalasi FLASHPRO, TunerPro, dan RevCore tidak diubah.
- Tidak ada penulisan ECU; tidak ada crack/keygen/bypass.
- Tidak ada publikasi/push/ZIP/repository sebelum persetujuan eksplisit.
- `APP_COPY` dan artefak sensitif tidak boleh dipublikasikan.
