# BE-09 EXECUTIVE SUMMARY

**Dataset Separation & Technical Research — RevCore External ECU Research**
Tanggal: 17 November 2026
Laporan lengkap: `BE09_FINAL_RESEARCH_REPORT.md`

---

## Apa yang diminta

Work order BE-09 meminta pemisahan dataset, analisis statis 14 software, enam
fokus penelitian teknis, prototipe terisolasi, rekomendasi integrasi, dan laporan
akhir — tanpa menjalankan software penelitian, tanpa ECU fisik, dan tanpa mengubah
sumber atau proyek RevCore.

## Apa yang dihasilkan

**Dataset.** 877 file dipisahkan: 148 BIN standar, 392 BIN editan, 160 BIN tidak
terklasifikasi; 161 XDF locked, 13 XDF unlocked, 3 ADX. Tidak ada file gagal
disalin atau hash tidak cocok; duplikat dipertahankan.

**Software.** 14 target dianalisis statis. Yang paling produktif:
CheksumKZR (algoritma checksum dipulihkan), HondaECU 3.5.5.2 (symbol Cython),
FTD2XX_NET/ANALIST (API transport), dan XDF/TunerPro (format definisi).
PRO Remap_BE dan SCANNER HONDA terproteksi; isinya tidak diklaim.

**Temuan teknis utama.**

1. Checksum KZR adalah jumlah 16-bit little-endian stride 4, field dinolkan,
   two's complement — terbukti dari IL dan diuji pada 38 file.
2. BIN adalah image linear; alamat XDF dipakai langsung sebagai offset file.
3. ECM ID KZR ada di `0x578`, K1AA di `0x800`; lima ECM ID KZR tercatat dari tabel tool (dua sampel diuji langsung).
4. Axis XDF bertipe link harus dibaca dari tabel target, bukan alamat axis sendiri.
5. Tidak ada bukti smart key/HISS, frame K-Line, atau offset live data.

**Prototipe.** Library .NET 8 offline: parser XDF, pembaca BIN/tabel, checksum KZR,
identifikasi, skala TPS/AFR, dan abstraksi transport. Build 3/3 sukses; self-test
**46/46 lulus**. CLI menyediakan `identify`, `checksum`, `xdf list/read/export`,
`tps`, `afr`, `transport-info`.

## Yang terbukti vs belum

| Terbukti (offline) | Belum terbukti |
|---|---|
| Struktur dataset dan integritas salinan | Frame/service K-Line |
| Checksum KZR + patch | Checksum famili non-KZR |
| Identifikasi KZR/K1AA (2 sampel) | Identifikasi famili lain |
| Parsing XDF 1.60/1.70 + axis link | 161 XDF terkunci |
| Skala TPS/AFR dari XDF | Offset kanal live data |
| Build + 46 tes | Write/erase/recovery pada ECU |
| | Smart key/HISS |

## Rekomendasi

Integrasikan sekarang hanya modul **offline read-only**: parser XDF, pembaca BIN,
checksum KZR, dan utilitas skala. Registry identifikasi dan checksum lain masuk
P1. Protokol, live data, dan transport hardware masuk P2. Write/erase/recovery
masuk P3 dan memerlukan bench, catu daya stabil, serta prosedur rollback. Smart
key berada di luar lingkup etis saat ini.

## Keputusan yang menunggu pemilik

1. Apakah modul offline boleh masuk RevCore setelah review kode.
2. Platform transport yang dituju (Windows D2XX vs USB Host/adapter lain).
3. Apakah riset hardware (P2) diotorisasi, dan di bench mana.
4. Apakah 161 XDF terkunci akan dibuka oleh pemilik untuk analisis format.

## Batasan

Tidak ada ECU fisik, tidak ada eksekusi software penelitian, tidak ada dekripsi
XDF terkunci. Karena itu klaim protokol dan hardware sengaja ditahan pada status
`UNKNOWN`/`HARDWARE_PENDING`. Semua angka dan klaim di laporan ini dapat ditelusuri
ke artefak di `BE09_ARTIFACT_INDEX.md`.
