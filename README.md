# BE-12 — FLASHPRO.inc FULL AUTOPSY & THREE-WAY TECHNICAL COMPARISON

Workspace penelitian untuk work order **BE-12**: autopsi penuh FLASHPRO.inc dan perbandingan teknis tiga aplikasi (FLASHPRO.inc vs TunerPro RT vs RevCore).

**Tanggal:** 2026-11-18 (lokal)
**Target utama:** `C:\Program Files (x86)\FLASHPRO.inc` (dibaca dari salinan kerja `00_SOURCE_INVENTORY/APP_COPY`)
**Pembanding:** TunerPro RT 5.0.10335.0 (baseline BE-11) dan source RevCore (`work/revcore`; repo publik v0.3.0 = `4160763`)
**Status:** FASE 0–VI selesai · 22 laporan final · dipublikasikan 2026-11-18
**Sanitasi publikasi:** [`PUBLICATION_SANITIZATION.md`](PUBLICATION_SANITIZATION.md) · **Manifest hash:** [`PUBLICATION_MANIFEST.csv`](PUBLICATION_MANIFEST.csv)

---

## 1. Aturan yang berlaku

- Instalasi FLASHPRO.inc, TunerPro RT, dan proyek RevCore **tidak diubah**. Semua eksperimen memakai salinan kerja.
- Hash SHA-256 dicatat sebelum/sesudah eksperimen.
- Tidak ada penulisan ke ECU fisik; tidak ada crack/keygen/aktivator.
- Tidak ada publikasi, push, ZIP final, atau perubahan repository sebelum persetujuan eksplisit pemilik.
- Status bukti hanya memakai: SOURCE VERIFIED, STATIC VERIFIED, RUNTIME VERIFIED, SIMULATION VERIFIED, HARDWARE VERIFIED, NOT FOUND, NOT TESTED, BLOCKED.
- Tidak ada klaim 100%; cakupan diukur terhadap ruang lingkup yang dapat diakses.

---

## 2. Temuan inti

1. Tiga EXE terpasang adalah **wrapper VB6** (`TJprojMain`, v1.00, unsigned) yang memuat executable asli utuh.
2. Payload `FLASHPRO.exe` **identik** dengan file installer: x64 Enigma Protector 5.x, v**0.0.1.6**, vendor **Team Tech Tunner / itech**.
3. Wrapper ditulis ulang **2026-11-17 11:38:51–52 UTC**; payload asli muncul sebagai `flashpro.exe`+U+00A0 pada **12:06 UTC**.
4. Aplikasi berhenti di **gerbang aktivasi** offline (WMI + registry + RSA); tidak ada koneksi jaringan saat start.
5. Transport hanya **FTDI D2XX**; tidak ada COM/CAN/ELM327/J2534.
6. Permukaan perintah `dat10/11/13/16/17/20/D1`, `dtc`..`dtc4`, `rst`..`rst4`; **wire-level tidak terbaca**.
7. Model BIN/map memakai **VomConfig** yang identik dengan RevCore; `.map` terenkripsi AES.
8. Checksum/flash/recovery ada sebagai **nama & pesan**, bukan algoritma terbukti.
9. Prototipe FASE VI: **12/12 tes lulus** (checksum, frame, DTC gap, audit profil).
10. Tidak ada pemenang tiga arah; posisi tiap aplikasi berbeda.

Detail: [`EXECUTIVE_SUMMARY.md`](EXECUTIVE_SUMMARY.md) · [`18_FINAL_REPORTS/22_KESIMPULAN_TEKNIS.md`](18_FINAL_REPORTS/22_KESIMPULAN_TEKNIS.md)

---

## 3. Peta workspace

| Folder | Isi | Status |
|---|---|---|
| `00_SOURCE_INVENTORY` | inventaris, provenance, verifier, salinan kerja | Selesai |
| `01_APPLICATION_ANATOMY` | arsitektur, UI/menu | Selesai |
| `02_STATIC_ANALYSIS` | metadata, updater, proteksi | Selesai |
| `03_RUNTIME_ANALYSIS` | E01, string catalog | Selesai; E02/E03 NOT TESTED |
| `04_PROTOCOL_AUTOPSY` | transport, command surface | Selesai |
| `05_ECU_IDENTIFICATION` | ECU, DTC, part codes | Selesai |
| `06_LIVE_DATA_AUTOPSY` | 36 parameter | Selesai |
| `07_BIN_MAP_AUTOPSY` | BIN/ROM, map | Selesai |
| `08_CHECKSUM_AUTOPSY` | checksum | Selesai (NOT VERIFIED) |
| `09_FLASHING_RECOVERY` | flash/recovery | Selesai (NOT TESTED) |
| `10_HARDWARE_DRIVER` | FTDI, wiring, environment | Selesai |
| `11_LICENSE_ARCHITECTURE` | lisensi (analisis) | Selesai |
| `12_EXPERIMENTS` | log E01 + hash | Selesai |
| `13_PROTOTYPES` | 4 tool + 12 tes + hasil | Selesai |
| `14_TUNERPRO_COMPARISON` | komparasi | Selesai |
| `15_REVCORE_COMPARISON` | komparasi + gap | Selesai |
| `16_THREE_WAY_COMPARISON` | matriks kapabilitas/protokol | Selesai |
| `17_EVIDENCE` | EV-001…EV-026 | Selesai |
| `18_FINAL_REPORTS` | 22 laporan | Selesai |

---

## 4. Verifikasi cepat

```powershell
# Inventaris 7 file (hash, PE, versi)
Import-Csv 00_SOURCE_INVENTORY\FLASHPRO_FILE_INVENTORY.csv | Format-Table filename,bytes,pe_machine,file_version,sha256

# Verifikasi format wrapper
powershell -NoProfile -ExecutionPolicy Bypass -File 00_SOURCE_INVENTORY\verify_wrapper.ps1
Get-Content 00_SOURCE_INVENTORY\WRAPPER_LAYOUT_VERIFIED.txt
```

```bash
# Prototipe (butuh Node.js)
cd 13_PROTOTYPES
node tests/run_tests.js
```

---

## 5. Peringatan distribusi

- `00_SOURCE_INVENTORY/APP_COPY` berisi **binary pihak ketiga** (FLASHPRO, payload, uninstaller). **Tidak boleh dipublikasikan** dan tidak boleh dimasukkan ke ZIP/repository.
- Artefak sensitif Enigma (project berisi private key, keygen, salinan termodifikasi) tidak disalin ke workspace ini.
- Laporan publik hanya memuat temuan, hash, dan artefak yang boleh didistribusikan.
- Node.js portabel yang dipakai untuk tes berada di luar workspace dan tidak termasuk artefak.
