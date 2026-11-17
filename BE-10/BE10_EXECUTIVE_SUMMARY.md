# BE-10 — RINGKASAN EKSEKUTIF

**Deep Technical Research: ADX + 3D Chart Graph + ECU Software**
17 November 2026 · `C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH`
Laporan lengkap: `BE10_FINAL_RESEARCH_REPORT.md`

---

## Apa yang diminta

Melanjutkan BE-09 tanpa mengulang inventaris: membedah ADX satu per satu, menganalisis source 3D Chart Graph, memperdalam 14 target software hanya yang relevan, merekonstruksi protokol/checksum/sensor/baca-tulis-recovery, membuat prototipe dan pengujian, lalu melaporkan mana yang terbukti, terblokir, dan butuh hardware.

## Apa yang dihasilkan

**ADX.** 3 file + 1 arsip 7z = **2 konten unik** (KEIHIN 40.199 byte, SHINDENGEN 23.780 byte). Layout terbukti sampai payload: magic, 127 nol, metadata 129 byte, 4 nol, **blok konstan 43 byte**, tag `0x03`/`0x02`, payload 39.891/23.472. Entropy ~7,99; tanpa signature kompresi. Isi tetap **tertutup**.

**3D Chart Graph.** C# WinForms .NET 4.8, **31.052 baris**, 152 model map, 169 ECU ID, 154 BIN. Terbaca: inisialisasi FTDI 10.400 8N1, frame K-Line, katalog perintah, **45 kanal live data**, checksum Keihin/Shindengen, seed/key, urutan tulis flash, recovery, Smart Key EEPROM, lisensi mesin. Tidak ada rutin baca BIN penuh.

**Prototipe.** .NET 8 tanpa dependensi: parser ADX, database map, pembaca tabel BIN (LE/BE), protocol codec, checksum, live-data decoder, formula, interpolasi, export/compare. **Build 0 warning/0 error; self-test 26/26 lulus; validasi 5/5 BIN nyata; katalog 45 kanal.**

## Yang terbukti vs belum

| Terbukti (offline) | Belum / terblokir |
|---|---|
| Layout ADX + tag famili | Isi ADX (`BLOCKED_BY_ACCESS_REQUIREMENT`) |
| Duplikat ADX via hash | Isi 161 XDF terkunci |
| Frame + checksum Honda | Validasi checksum pada firmware |
| 45 kanal live data (offset/rumus) | Skala aktual di kendaraan |
| Checksum Keihin/Shindengen (vektor) | Penerimaan oleh ECU |
| Seed/key Shindengen (aritmetika) | Varian recovery V850/RH850 |
| Tabel BIN 5 model | 147 model lainnya |
| Urutan tulis/recovery | Eksekusi hardware |

## Kontribusi baru vs BE-09

- ADX: dari "file terkunci" menjadi struktur kontainer yang dapat dibuktikan, termasuk hubungan dengan XDF.
- 3D Chart Graph: target baru, sumber teknis terbesar BE-10.
- Live data: 23 nama tanpa offset → **45 kanal dengan offset**.
- Protokol: frame/baud/timeout/wake-up yang sebelumnya `UNKNOWN`.
- Checksum: KZR saja → **+ Keihin + Shindengen**.
- Smart Key: `NOT_FOUND` → challenge dan frame EEPROM terbaca statis.

## Rekomendasi singkat

Integrasikan **P0 offline** sekarang: pembaca tabel BIN, registry 152 model, export/import, compare, inspeksi ADX metadata, formula. **P1** setelah review: decoder live data, checksum, seed/key (test-only), codec frame. **P2** hanya dengan bench: transport FTDI, ID runtime, live sync. **P3/tidak disarankan:** tulis/erase/recovery, Smart Key tulis, bypass lisensi, dekripsi ADX.

## Keputusan yang menunggu pemilik

1. Apakah modul P0 boleh masuk RevCore setelah review kode.
2. Apakah riset hardware P2 diotorisasi, dan di bench mana.
3. Apakah 161 XDF terkunci akan dibuka oleh pemilik untuk analisis format.
4. Apakah ADX akan dikejar dengan alat resmi/izin terpisah.

## Batasan

Tidak ada EXE/DLL dijalankan, tidak ada driver dipasang, tidak ada ECU fisik, tidak ada dekripsi ADX/XDF, tidak ada kredensial yang disalin. Semua klaim dapat ditelusuri ke `BE10_ARTIFACT_INDEX.md` dan `REPORTS\BE10_SHA256_MANIFEST.csv`.
