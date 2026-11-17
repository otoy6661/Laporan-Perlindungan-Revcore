# 21 — BUKTI DAN CAKUPAN

**Work order:** BE-12
**Status:** ringkasan bukti & cakupan
**Sumber:** `EVIDENCE_REGISTER.csv` (EV-001…EV-026), `COVERAGE_MATRIX.csv`, `17_EVIDENCE/`

---

## 1. Status bukti yang dipakai

| Status | Arti | Contoh di BE-12 |
|---|---|---|
| SOURCE VERIFIED | terbaca dari metadata/source | 168 tipe, 1.442 metode, nama perintah |
| STATIC VERIFIED | terbukti dari file/PE/hash | wrapper, payload, signature, format |
| RUNTIME VERIFIED | diamati pada proses/lingkungan | E01, ftd2xx 3.2.21.1, feed 0.0.1.8 |
| SIMULATION VERIFIED | dijalankan & diuji deterministik | 12/12 prototipe |
| HARDWARE VERIFIED | diuji pada ECU/perangkat | **tidak ada** |
| NOT FOUND | dicari, tidak ada | frame, seed/key literal, ROM |
| NOT TESTED | belum dijalankan | E02/E03, tulis ECU |
| BLOCKED | tidak dapat diakses | IL, ECU, hardware |

## 2. Register bukti (ringkas)

| EV | Area | Inti | Status |
|---|---|---|---|
| 001 | inventaris | 7 file, hash | STATIC |
| 002 | wrapper | format & invarian 3 EXE | STATIC |
| 003 | timeline | instalasi vs penulisan ulang | STATIC |
| 004 | payload | PE/proteksi/versi | STATIC |
| 005 | payload vs installer | EXACT MATCH 2 file | STATIC |
| 014 | metadata | 235.832 B, SHA-256 | RUNTIME |
| 015 | struktur | 168/1.442/1.429/2.082 | SOURCE |
| 016 | startup | activation gate, no TCP, clean exit | RUNTIME |
| 017 | transport | D2XX only, Class15/155 | SOURCE |
| 018 | lingkungan FTDI | 3.2.21.1, Present=False | RUNTIME |
| 019 | feed | 0.0.1.8, update.zip | RUNTIME |
| 020 | redaksi | marker terverifikasi | VERIFIED (lokal) |
| 021 | IL | GetILInfo null | BLOCKED |
| 022 | wrapper/updater | E02/E03 tidak dijalankan | NOT TESTED |
| 023 | checksum | 5 vektor lulus | SIMULATION |
| 024 | frame | valid/invalid/roundtrip | SIMULATION |
| 025 | DTC | 37 vs 15, 24 hilang, 2 ekstra | SIMULATION |
| 026 | profil | 163, 0 masalah, max 0x4256C | SIMULATION |

## 3. Cakupan per area

| Area | Cakupan | Status | Blocker |
|---|---|---|---|
| Identitas & inventaris | semua 7 file | SELESAI | — |
| Wrapper | 3/3 | SELESAI | — |
| Payload statis | PE/proteksi/versi | SELESAI | Enigma |
| Metadata | tipe/metode/field/string | SELESAI | IL |
| Runtime E01 | startup | SELESAI | lisensi setelah gate |
| Runtime E02/E03 | wrapper/updater | TIDAK | UAC/eksekusi pihak ketiga |
| Protokol | permukaan | SELESAI | capture |
| ECU ID | struktur | SELESAI | ECU |
| Live data | label/metode | SELESAI | ECU |
| BIN/ROM | model | SELESAI | BIN/ECU |
| Checksum | nama/kontrol + sisi RevCore | SELESAI sebagian | IL |
| Flash/recovery | tahapan | SELESAI | ECU/dilarang |
| Hardware | lingkungan | SELESAI | adaptor |
| Lisensi | mekanisme | SELESAI | — |
| Komparasi | tiga arah | SELESAI | capture |
| Prototipe | 12 tes | SELESAI | — |

## 4. Yang tidak dapat diklaim

- Tidak ada frame ECU nyata.
- Tidak ada algoritma FLASHPRO yang terbukti.
- Tidak ada penulisan ECU.
- Tidak ada pengujian hardware.
- Tidak ada klaim "100% complete". Cakupan diukur terhadap yang dapat diakses.

## 5. Integritas & preservasi

- Instalasi asli, TunerPro, dan RevCore tidak diubah.
- E01 memakai salinan; hash sebelum/sesudah identik.
- Tidak ada registry/driver yang diubah.
- Artefak sensitif (private key/keygen, blob lisensi, password) tidak disalin/dipublikasikan.
- `APP_COPY` berisi binary pihak ketiga dan **tidak boleh** masuk publikasi.

## 6. Keterbatasan utama

Satu ketergantungan yang sama muncul di hampir semua area: **adaptor FTDI + ECU donor + capture**. Tanpa itu, status tertinggi yang dapat dicapai adalah SOURCE/STATIC/SIMULATION VERIFIED. Ini bukan kegagalan metodologi, melainkan batas yang ditetapkan work order (tidak menulis ECU, tidak menjalankan executable berisiko).
