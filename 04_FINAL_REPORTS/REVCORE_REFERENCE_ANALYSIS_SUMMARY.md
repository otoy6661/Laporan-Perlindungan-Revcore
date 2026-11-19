# RevCore Reference Analysis — Summary

Work order: REVCORE REFERENCE AUTOPSY (H-Diag + 3D Chart Graph Remap K-Line)
Date: 2026-11-19
Analyst: Kodir

## 1. Dua sumber, dua laporan terpisah

| Sumber | Tujuan | Dokumen |
|---|---|---|
| H-Diag 2.1 (`C:\Program Files (x86)\H-Diag`) | kebutuhan RevCore 4–10 | `HDIAG_AUTOPSY_REPORT.md`, `HDIAG_FUNCTION_MAPPING.md`, `HDIAG_PROTOCOL_ANALYSIS.md`, `HDIAG_REVCORE_REQUIREMENTS_04_10.md` |
| 3D Chart Graph Remap K-Line | pembacaan sensor + fungsi remap | `REVCORE_SENSOR_READING_ANALYSIS.md`, `REVCORE_REMAP_FUNCTION_ANALYSIS.md` |

Hasil kedua sumber **tidak dicampur**. Setiap klaim menyebut sumber dan tingkat bukti.

## 2. Temuan lintas sumber (fakta)

Kedua aplikasi memakai dialek K-line yang sama:

```
[0x72] [len] [fn] [sub] [param...] [checksum]
checksum = ((sum8(frame[0..len-2]) ^ 0xFF) + 1) & 0xFF
```

- 5-byte request umum: `72 05 71 xx cc`.
- DTC: `72 05 73/74 ...`, ditambah frame 7-byte `72 07 72 ...`.
- Wake: `FE 04 72 8C` (3D Chart) dan pola handshake serupa di H-Diag.
- Semua frame yang dikutip lolos verifikasi checksum (`03_EVIDENCE/PROTOCOL_FRAME_VALIDATION.csv`).

Kesamaan ini adalah fakta aritmetik/konstanta, bukan asumsi bahwa seluruh layout respons identik.

## 3. H-Diag — hasil untuk RevCore 4–10

| # | Kebutuhan | Label H-Diag | Yang terbukti | Yang belum |
|---:|---|---|---|---|
| 4 | Fuel Pump | POM | label, polling | byte, konversi |
| 5 | Starter Relay | STS/SSW | label "Switch Starter" | "Relay" tidak ada; byte |
| 6 | Side Stand | SS | label, polling | byte, konversi |
| 7 | FISV/FID | FIS | label "Fast Idle Switch" | FID tidak ada; nilai numerik |
| 8 | IACV | IAC | baris 12 ← teks respons `+0x0D` (key 8) | perintah, satuan |
| 9 | STF | STF | label, polling | byte, konversi |
| 10 | Altitude Mode | MOD/ALT | label, polling | pembacaan byte; **set tidak ditemukan** |

Kesimpulan: H-Diag membuktikan **keberadaan parameter dan mekanisme polling kolektif**, tetapi tidak membuktikan perintah/byte/konversi per parameter. Klaim "H-Diag mendukung FID/Relay/Set Altitude" tidak boleh dibuat.

## 4. 3D Chart — pembacaan sensor

Terbukti dari source:

- Transport FTDI, wake 70/130 ms, 10400 bps, timeout 50 ms.
- Tujuh frame live data (`dat10`, `dat11`, `dat13`, `dat16`, `dat17`, `dat20`, `datD1`).
- Formula decoding lengkap (RPM, TPS, ECT, IAT, MAP, battery, VSS, inj, adv, O2, STF, AFR, APS/TP, switch, gear).
- Pemetaan 12 baris UI.
- Cacat: timeout diabaikan, `Task.Delay` tidak di-await, IAC dihitung tidak ditampilkan, STF hanya 1 byte, tidak ada status invalid.

## 5. 3D Chart — remap

Terbukti dari source:

- Deteksi ECU via signature (Shindengen V850/RH850/RH850B, Keihin H8C/M32R/OTHER).
- Checksum Shindengen 32-bit two's complement dan Keihin 8-bit.
- Pre-write, seed/key, erase, block write 128/64 byte.
- Format blok: header, alamat, data, next address, dua checksum data, checksum frame.
- Finalisasi status `0x0F`.
- **Tidak ada read-back verification.**
- License gate AES hardcoded (nilai tidak dipublikasikan); keygen di folder sumber tidak dijalankan/dianalisis.

## 6. Temuan yang dapat dimanfaatkan RevCore

| Temuan | Sumber | Status | Catatan |
|---|---|---|---|
| Format frame & checksum K-line | keduanya | FAKTA + aritmetik | dapat langsung dipakai untuk transport |
| Wake 70/130 ms @10400 | 3D | SOURCE VERIFIED | verifikasi per ECU |
| Frame live data `71 xx` | 3D | SOURCE VERIFIED | H-Diag memakai `71 00` (layout beda) |
| Formula sensor | 3D | SOURCE VERIFIED | belum ECU-verified |
| Fuel pump `D1 b[8]` | 3D | SOURCE VERIFIED | 0x01/0x05 ON, 0x00/0x04 OFF |
| Side stand/starter `D1 b[4]` | 3D | SOURCE VERIFIED | bitfield nilai terbatas |
| Mode altitude `dat17 b[18]` | 3D | SOURCE VERIFIED (baca) | set tidak ada |
| IAC `dat11 b[22]` | 3D | SOURCE (tidak tampil) | satuan belum jelas |
| STF `dat20 b[5]` | 3D | SOURCE (formula) | validitas 8/16-bit belum jelas |
| Deteksi ECU & checksum BIN | 3D | SOURCE VERIFIED | berguna untuk modul remap |
| Seed/key berbasis BIN | 3D | SOURCE VERIFIED | bukan lisensi; tetap sensitif |

## 7. Temuan yang belum dapat dipastikan

1. Perintah/byte/konversi H-Diag untuk STF, POM, SS, STS, SSW, FIS, MOD, ALT.
2. Apakah "Starter Relay" di RevCore sama dengan "Switch Starter" H-Diag.
3. Apakah FISV/FID membutuhkan nilai numerik atau hanya status biner.
4. Apakah STF 8-bit atau 16-bit; arah tanda dan satuan.
5. Apakah Altitude Mode dapat diset; tidak ada bukti di kedua sumber.
6. Arti frame H-Diag `72 05 00 F1 98`.
7. Apakah `b[2]` benar-benar table type atau echo fungsi.
8. Perilaku ECU nyata untuk semua frame (belum ada pengujian).

## 8. Tingkat bukti

| Tingkat | Isi |
|---|---|
| FAKTA SOURCE/BINARY | string, konstanta frame, formula, checksum, signature |
| REKONSTRUKSI | dispatch respons H-Diag, handshake parsial, alur tulis |
| DUGAAN | arti frame C, tableType, bug alamat, fast-write frame |
| SIMULASI | tidak ada |
| UJI PERANGKAT | tidak ada |
| UJI ECU | tidak ada |

## 9. Rekomendasi prioritas untuk RevCore

1. **Transport**: implementasi frame/checksum/wake yang sudah terbukti; tambahkan status validitas per pembacaan.
2. **Sensor**: mulai dari dat10/dat17/dat20/datD1; tampilkan raw + hasil; jangan menampilkan nilai saat timeout.
3. **Kebutuhan 4–10**: gunakan frame 3D Chart sebagai hipotesis implementasi, lalu verifikasi pada ECU nyata; jangan mengklaim H-Diag sebagai bukti.
4. **Altitude Mode**: hanya baca; riset perintah set terpisah.
5. **Remap**: tambahkan read-back verify dan checksum pasca-tulis; tangani M32R secara eksplisit.
6. **Lisensi**: jangan meniru gate/keygen; gunakan skema RevCore sendiri.

## 10. Daftar artefak

- `00_INVENTORY/SOURCE_INVENTORY.csv` — 869 file, hash SHA-256.
- `01_HDIAG/STRINGS_HDiag.exe.tsv`, `..._comma.tsv` — string H-Diag.
- `03_EVIDENCE/HDIAG_STATIC_EVIDENCE.md` — bukti alamat/string.
- `03_EVIDENCE/3DCHART_SOURCE_EVIDENCE.md` — bukti source 3D Chart.
- `03_EVIDENCE/PROTOCOL_FRAME_VALIDATION.csv` — verifikasi checksum 30 frame.
- `03_EVIDENCE/UNREADABLE_OR_BLOCKED.md` — file yang tidak dapat dianalisis.
- `04_FINAL_REPORTS/*` — tujuh dokumen wajib.
- `PUBLICATION_SANITIZATION.md`, `PUBLICATION_MANIFEST.csv` — sanitasi & hash publikasi.

## 11. Pernyataan penutup

Tidak ada protokol, frame, checksum, alamat, atau keberhasilan fungsi yang dikarang. Semua yang tidak terbukti dinyatakan sebagai belum terbukti. Pekerjaan ini adalah analisis referensi teknis, bukan implementasi dan bukan clone.
