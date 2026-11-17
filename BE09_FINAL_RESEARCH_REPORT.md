# BE-09 FINAL RESEARCH REPORT
## Dataset Separation & Technical Research — RevCore External ECU Research

**Tanggal:** 17 November 2026
**Work order:** BE-09 (Revisi 3)
**Sumber:** `C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3`
**Workspace:** `C:\Users\Lord Otoy\Documents\REVCORE_EXTERNAL_ECU_RESEARCH`
**Inventaris sebelumnya:** `C:\Users\Lord Otoy\Documents\Qoder\work\remap_inventory_20261117`

---

## 1. Ringkasan eksekutif

BE-09 memisahkan 877 file dataset (700 BIN, 174 XDF, 3 ADX) ke dalam folder
standar/editan/tidak terklasifikasi, menganalisis 14 target software secara statis,
menyusun enam fokus penelitian teknis, dan membangun prototipe offline yang diuji.

Hasil utama:

1. **Pemisahan dataset selesai:** 148 BIN standar, 392 BIN editan, 160 BIN
   tidak terklasifikasi; 161 XDF locked dan 13 XDF unlocked; 0 file gagal disalin;
   0 hash tidak cocok; duplikat dipertahankan.
2. **Checksum KZR terbukti dan diuji:** algoritma stride-4 16-bit dipulihkan dari IL;
   38 file diuji (31 valid, 7 invalid); patch menghasilkan checksum yang valid.
3. **Identifikasi offline terbukti pada dua famili:** KZRA `010123` di `0x578` dan
   K1AA `01037A00AC` di `0x800`, plus string versi.
4. **Parser XDF 1.60/1.70 berfungsi:** 20 tabel K1AA terbaca; axis tertaut
   (`embedinfo type="3"`) diselesaikan ke tabel target.
5. **Prototipe lulus 46/46 self-test**, build 0 warning/0 error.
6. **Protokol ECU, live data, write/erase, recovery, dan smart key tetap
   `UNKNOWN`/`HARDWARE_PENDING`/`NOT_FOUND`** dan tidak diklaim sebagai fitur.

Yang **tidak** dilakukan: menjalankan EXE/installer/BAT/CMD/DLL/OCX penelitian,
menghubungkan ECU fisik, mendekripsi XDF terkunci, membobol lisensi, mengubah
dataset sumber, atau mengubah proyek RevCore.

---

## 2. Kepatuhan terhadap aturan work order

| Aturan | Penerapan | Bukti |
|---|---|---|
| Sumber tidak diubah/dipindah/dihapus | Semua operasi salin; hash sumber vs salinan dibandingkan | `REPORTS/DATASET_MANIFEST.csv` |
| RevCore tidak diubah | Tidak ada akses tulis ke proyek RevCore | — |
| Hasil di workspace riset | Semua artefak di `REVCORE_EXTERNAL_ECU_RESEARCH` | `BE09_ARTIFACT_INDEX.md` |
| Tidak menjalankan software penelitian | Analisis statis (PE, IL, symbol, string) | `EVIDENCE/pe/*` |
| Tidak menghubungkan ECU | Tidak ada operasi hardware | `PROTOTYPES/RESULTS/PROTOTYPE_RESULTS.md` |
| Tidak mengirim kredensial | Tidak ada kredensial yang dibaca/dikirim | — |
| Tidak menganggap fitur hanya dari nama | Setiap klaim merujuk bukti/status | `TECHNICAL_FINDINGS/*` |
| Tidak berhenti di inventaris | Analisis + prototipe + uji | `PROTOTYPES/` |
| Lingkup tidak diubah | Tidak ada target/fitur di luar BE-09 | laporan ini |

---

## 3. FASE A–B — Dataset dan pemisahan

### 3.1 Populasi

| Kategori | Jumlah |
|---|---:|
| BIN standar | 148 |
| BIN editan | 392 |
| BIN tidak terklasifikasi | 160 |
| **Total BIN** | **700** |
| XDF locked (`05 22 97 00`) | 161 |
| XDF unlocked (XML) | 13 |
| XDF unknown | 0 |
| ADX (locked, di luar lingkup) | 3 |
| **Total dataset** | **877** |

Integritas: 0 file gagal disalin, 0 hash tidak cocok, 100 file diberi sufiks
`__dupN` karena benturan nama, 157 grup duplikat (376 file) dipertahankan.

### 3.2 Ukuran BIN

Tujuh ukuran: 49.152; 57.344; 65.536; 98.304; 262.144; 393.216; 1.048.576 byte.
Semua kelipatan 4 KB; tidak ada container header seragam.

### 3.3 Batas klasifikasi

Status BIN hanya dari nama/folder/path, bukan isi. Konflik penanda (15 file) dan
file tanpa penanda (214 file) masuk `UNCLASSIFIED`. Detail:
`REPORTS/DATASET_CLASSIFICATION_REPORT.md`.

---

## 4. FASE C — 14 target software (analisis statis)

| No | Target | Teknologi (bukti) | Status | Relevansi |
|---|---|---|---|---|
| 1 | HondaECU 3.5.5.2 | PyInstaller onefile + 59 `.pyd` Cython (Py 3.7 x86) | `FOUND/ANALYZED` (modul); payload `UNKNOWN` | F1, F3–F6 |
| 2 | HondaECU 3.3.0 | PyInstaller onefile | `FOUND`; payload tidak diekstrak | tidak langsung |
| 3 | HondaECU 3.0.2 | PyInstaller onefile | `FOUND`; payload tidak diekstrak | tidak langsung |
| 4 | PRO Remap_BE | Native x64, packed, entropi ~8 | `FOUND`; isi `UNKNOWN` | — |
| 5 | SCANNER HONDA | Native x86, Enigma Protector | `FOUND`; terproteksi | — |
| 6 | ANALIST Pro 5.1 | .NET, 1.570 tipe, nama diobfuskasi | `ANALYZED` (FTDI); protokol `UNKNOWN` | F4 |
| 7 | TunerPro RT | Installer Inno Setup 5.00.9995 | `FOUND`; payload tidak diekstrak | F2 |
| 8 | Pin Out ECU | VB.NET WinForms + gambar | `ANALYZED` | tidak relevan |
| 9 | CheksumCalculator | Delphi/FMX native | `FOUND`; algoritma `UNKNOWN` | F3 (parsial) |
| 10 | CheksumKZR | VB.NET | `ANALYZED`; checksum + ECM ID dipulihkan | F1, F3 |
| 11 | FTDI CDM Driver | SFX CDM 2.12.36.4 | `FOUND` | F4 |
| 12 | REMAP CABLE DRIVER | SFX CDM 2.12.28.2 | `FOUND` | F4 |
| 13 | FTD2XX_NET | .NET wrapper D2XX 1.0.0.0 | `ANALYZED` (11 API) | F4 |
| 14 | OCX + Python runtime | `comctl32.ocx`, `python37.dll`, dll | `FOUND` | tidak relevan |

Bukti: 110 file di `EVIDENCE/` (107 PE + 3 PyInstaller TOC), 15 README di
`SOFTWARE_RESEARCH/`.

---

## 5. FASE D — Enam fokus teknis

| Fokus | Artefak | Status | Temuan kunci |
|---|---|---|---|
| F1 Identifikasi ECU | `ECU_IDENTIFICATION_RESEARCH.md` | `ANALYZED` offline; runtime `HARDWARE_PENDING` | Offset per famili; 5 ECM ID KZR; XDF vs BIN mismatch pada K59A |
| F2 BIN/XDF/TunerPro | `BIN_FORMAT_RESEARCH.md`, `XDF_FORMAT_RESEARCH.md`, `TUNERPRO_RT_RESEARCH.md`, `BIN_XDF_MAPPING_EXAMPLES.md` | `ANALYZED` | BIN image linear; XDF definition-driven; 287 tabel di 13 XDF |
| F3 Baca/tulis/recovery/checksum | `ECU_READ_PROCEDURE.md`, `ECU_WRITE_PROCEDURE.md`, `ECU_CHECKSUM_RESEARCH.md`, `ECU_RECOVERY_RESEARCH.md` | `ANALYZED` (pipeline); checksum KZR `TESTED_PASS` | Checksum stride-4; frame/timing `UNKNOWN` |
| F4 FTDI + K-Line | `FTDI_API_RESEARCH.md`, `KLINE_COMMUNICATION_RESEARCH.md`, `FTDI_KLINE_PROTOCOL_FLOW.md` | `ANALYZED` (API); protokol `UNKNOWN` | `ftd2xx.dll` 90 export; 11 API ANALIST; “K-Line” hanya nama modul |
| F5 Smart Key ID | `SMART_KEY_ID_RESEARCH.md` | `NOT_FOUND` | Hanya `pgmfi_set_hiss_key_variables`; tidak ada baca/registrasi |
| F6 Sensor/live/AFR | `LIVE_DATA_INVENTORY.md`, `SENSOR_SCALING_REFERENCE.csv`, `TPS_CONVERSION_RESEARCH.md`, `AFR_LAMBDA_RESEARCH.md`, `LIVE_DATA_PROTOCOL_MAPPING.md` | `ANALYZED` (skala); offset `UNKNOWN` | 23 kanal; divisor TPS 10/7.43/13.286/9.4; AFR 9.5/9/8.725/10/7.71 |

False positive yang ditolak: marker `KWP`/`UDS`/`CRC` di ANALIST dan string
`HISSZboc` di SCANNER HONDA (blok byte acak pada binary packed).

---

## 6. FASE E — Prototipe

### 6.1 Cakupan

| Komponen | Bukti | Status |
|---|---|---|
| `KzrChecksum` | IL CheksumKZR | `TESTED_PASS` |
| `BinIdentifier` | dump KZR/K1AA | `TESTED_PASS` (2 famili) |
| `XdfParser` + `TableReader` | XDF 1.60/1.70 | `TESTED_PASS` (2 XDF) |
| `EquationEvaluator` | MATH XDF | `TESTED_PASS` |
| `TpsScale` / `AfrLambda` | XDF | `TESTED_PASS` (aritmetika) |
| `D2xxTransport` | `ftd2xx.dll` | `HARDWARE_PENDING`, tidak dieksekusi |
| `FakeTransport` | — | `TESTED_PASS` |

### 6.2 Hasil uji

- Build Release: 3/3 sukses, 0 warning, 0 error.
- Self-test: **46/46 lulus**.
- Checksum: `kzra601.bin` valid `0xFFFF`; `kzrm_b31_10pct.bin` stored `0x8744`
  vs needed `0xB36E`; patch → verify `True`; input tidak berubah.
- Identifikasi: `010123` @ `0x578`; `01037A00AC` @ `0x800`;
  `SH850T01R100_PV10` @ `0x577C`.
- Tabel: Fast Idle 35×29, raw pertama `3880`, delapan nilai pertama cocok.
- Axis: link ke `Breakpoint TPS`/`Breakpoint RPM`; nilai `0, 0.4, 0.6, 1, ...`
  dan `900, 1200, 1400, ...`.

### 6.3 Temuan teknis baru

Axis XDF dengan `<embedinfo type="3" linkobjid="..."/>` tidak boleh dibaca dari
`mmedaddress` axis sendiri. Sebelum perbaikan, axis Y AFR menghasilkan sampah
(`4609, 1513, ...`); setelah resolusi ke `Breakpoint RPM` hasilnya benar.

Detail: `PROTOTYPES/RESULTS/PROTOTYPE_RESULTS.md`, `PROTOTYPES/README.md`.

---

## 7. FASE F — Rekomendasi

Dokumen:

- `REVCORE_INTEGRATION_RECOMMENDATIONS.md` — 5 paket langsung, 5 perlu adaptasi,
  6 perlu riset, 5 tidak relevan.
- `REVCORE_TECHNICAL_GAP_ANALYSIS.md` — 16 kapabilitas dinilai G1–G4.
- `REVCORE_RESEARCH_PRIORITY.md` — P0 offline, P1 lanjutan offline, P2 hardware,
  P3 write/recovery, P4 di luar lingkup.

Kesimpulan: yang dapat diintegrasikan sekarang hanya modul **offline read-only**
(parser XDF, pembaca BIN, checksum KZR, skala). Protokol, write, recovery, live
data, dan smart key belum memenuhi syarat bukti.

---

## 8. Audit kelengkapan FASE G

| Fase | Artefak wajib | Jumlah | Status |
|---|---|---:|---|
| A | Verifikasi workspace + inventaris sebelumnya | 1 | LENGKAP |
| B | Laporan, manifest, 6 indeks | 8 | LENGKAP (877 baris manifest) |
| C | Analisis 14 target | 14 README + 1 ringkasan | LENGKAP (14/14) |
| D | 6 fokus / 18 artefak | 17 MD + 1 CSV | LENGKAP (18/18) |
| E | Prototipe + tes/hasil + README | 17 file sumber/konfigurasi + 5 testdata + 6 hasil | LENGKAP (46/46 tes) |
| F | 3 dokumen rekomendasi | 3 | LENGKAP |
| G | Laporan akhir, ringkasan, status CSV, indeks artefak | 4 | LENGKAP |

Pemeriksaan silang:

- Semua 14 folder `SOFTWARE_RESEARCH/*/README.md` ada.
- Semua 18 artefak FASE D ada di `TECHNICAL_FINDINGS/` + `REPORTS/`.
- Semua file prototipe dapat dibangun ulang dari source.
- Tidak ada file sumber BE-09 yang berubah (hash salinan cocok).
- Tidak ada EXE/installer/DLL yang dieksekusi.

---

## 9. Batasan dan risiko

1. **Cakupan verifikasi:** hanya 2 famili BIN dan 2 XDF diuji; 161 XDF terkunci
   tidak dibaca; 11 XDF terbuka lain belum diuji di prototipe.
2. **Protokol:** tidak ada frame, service ID, baud, timing, atau security access
   yang terbukti. Semua `UNKNOWN`/`HARDWARE_PENDING`.
3. **Checksum:** hanya KZR terbukti; checksum famili lain dan `checksum8bitHonda`
   belum.
4. **Hardware:** tidak ada ECU fisik; write/erase/recovery tidak divalidasi.
5. **Klasifikasi dataset:** berbasis nama/path; bukan analisis isi.
6. **Binary terproteksi:** PRO Remap_BE dan SCANNER HONDA tidak dianalisis isinya.
7. **TunerPro:** executable tidak diekstrak; perilaku UI tidak diverifikasi.
8. **Etika:** smart key/HISS tidak dikembangkan; tidak ada upaya bypass.

---

## 10. Kesimpulan

BE-09 mencapai target penelitian yang dapat dibuktikan tanpa hardware:

- dataset terpisah dan terverifikasi integritasnya;
- 14 target software dianalisis pada tingkat yang memungkinkan;
- enam fokus teknis terdokumentasi dengan bukti dan status eksplisit;
- algoritma offline utama (XDF, identifikasi, checksum KZR, skala) diprototipekan
  dan lulus uji;
- rekomendasi integrasi, gap, dan prioritas tersedia.

Yang belum tercapai — dan tidak dapat diklaim tercapai — adalah verifikasi
protokol dan operasi ECU pada hardware. Pekerjaan itu memerlukan bench ECU,
izin pemilik, dan prosedur keselamatan; dokumen prioritas menempatkannya di P2–P3.

---

## 11. Indeks artefak

Lihat `BE09_ARTIFACT_INDEX.md`. Ringkasan eksekutif: `BE09_EXECUTIVE_SUMMARY.md`.
Status per item: `BE09_RESEARCH_STATUS.csv`.
