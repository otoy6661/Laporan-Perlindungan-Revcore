# H-Diag → RevCore Requirements 4–10

Format pemetaan yang diminta:

`Permintaan RevCore → Fungsi H-Diag → Mekanisme Teknis → Bukti → Rekomendasi untuk RevCore`

Status yang dipakai:

- **FAKTA** — terbukti langsung dari string/konstanta/aritmetika binary.
- **REKONSTRUKSI** — terbukti dari disassembly, tetapi bukan source.
- **DUGAAN** — indikasi kuat, belum terbukti.
- **TIDAK DITEMUKAN** — tidak ada bukti.
- **BELUM DIUJI** — tidak ada perangkat/ECU.

> Catatan pemisahan: kolom "Referensi 3D Chart" adalah hasil analisis SUMBER 2 dan **bukan bukti perilaku H-Diag**. Ia dicantumkan hanya sebagai rekomendasi implementasi untuk RevCore.

---

## Ringkasan

| # | Kebutuhan | Label H-Diag | Bukti H-Diag | Status H-Diag | Referensi 3D Chart (terpisah) |
|---:|---|---|---|---|---|
| 4 | Fuel Pump Status | `POM - Pompa Bahan Bakar` (row 1) | label + polling | FAKTA label; parsing BELUM | `72 05 71 D1 47`, `b[8]`: 00 OFF, 01/05 ON, 04 OFF |
| 5 | Starter Relay Status | `STS`/`SSW - Switch Starter` (row 3/4) | label + polling | FAKTA label; "Relay" TIDAK DITEMUKAN; parsing BELUM | `b[4]`: 0x02 SSW ON |
| 6 | Side Stand Status | `SS - Standar Samping` (row 2) | label + polling | FAKTA label; parsing BELUM | `b[4]`: 0x01 SSS ON, 0x00 OFF |
| 7 | FISV/FID | `FIS - Fast Idle Switch` (row 5) | label + polling | FAKTA label; `FID` TIDAK DITEMUKAN; parsing BELUM | `dat17 b[18]`: <128 ON, ≥128 OFF (`fiz`) |
| 8 | IACV | `IAC - Katup Udara Masuk` (row 12) | label + dispatch key 8 | REKONSTRUKSI: row 12 ← teks `edi+0x0D` | `dat11 b[22]/10000` (dihitung, tidak ditampilkan) |
| 9 | STF | `STF - Campuran Bahan Bakar` (row 0) | label + polling | FAKTA label; parsing BELUM | `dat20 b[5]/128.25651` |
| 10 | Altitude Mode 1–4 | `MOD` (row 6), `ALT` (row 7) | label + polling | FAKTA label; SET TIDAK DITEMUKAN | `dat17 b[18]` → MODE 1–4; read-only |

---

## 4. Live Data Fuel Pump Status

**Permintaan:** mengetahui status Fuel Pump, sumber data, perintah, respons, interpretasi.

**Fungsi H-Diag:** baris tabel `POM - Pompa Bahan Bakar` (row 1). Tabel diinisialisasi pada `0x402434`.

**Mekanisme:** nilai POM diisi dari salah satu respons polling (`72 05 60 03 26`, `72 05 71 00 18`, `72 05 00 F1 98`). Jalur dispatch byte → row 1 tidak ditemukan dalam blok `0x405F90`–`0x406A91`; kemungkinan berada di jalur key `0xC` atau `7` yang belum direkonstruksi.

**Bukti:** string VA `0x412c5c`; row offset `+0x64`; frame polling E-HD-03. Tidak ada bukti byte/format respons untuk POM.

**Status:** FAKTA (label, polling); BELUM (perintah spesifik, byte, konversi).

**Rekomendasi untuk RevCore:** implementasi awal dapat memakai frame `72 05 71 D1 47` dan interpretasi `b[8]` dari 3D Chart (SUMBER 2, SOURCE VERIFIED untuk formula). Nilai `0x04` = OFF dan `0x01/0x05` = ON; arti perbedaan 0x01 vs 0x05 belum dijelaskan. Verifikasi pada ECU nyata sebelum rilis.

---

## 5. Live Data Starter Relay Status

**Permintaan:** status Starter Relay dan mekanismenya.

**Fungsi H-Diag:** dua baris: `STS - Switch Starter` (row 3) dan `SSW - Switch Starter` (row 4). Tidak ada string `Relay` di binary.

**Mekanisme:** polling kolektif; jalur row 3/4 belum ditemukan.

**Bukti:** string VA `0x412c8c`, `0x412ca4`; row offset `+0x6c`, `+0x70`. Pencarian `Relay` = TIDAK DITEMUKAN.

**Status:** FAKTA label; "Starter Relay" sebagai nama TIDAK TERBUKTI. Parsing BELUM.

**Rekomendasi:** jangan menamai parameter RevCore "Starter Relay" sebelum terbukti bahwa sinyal yang dibaca adalah relay, bukan switch starter. 3D Chart hanya memetakan `SSW` dari `b[4]` (0x02 = ON). Perlu verifikasi sinyal fisik.

---

## 6. Live Data Side Stand Status

**Permintaan:** status Side Stand, parameter, respons, interpretasi.

**Fungsi H-Diag:** `SS - Standar Samping` (row 2).

**Mekanisme:** polling kolektif; jalur row 2 belum ditemukan.

**Bukti:** string VA `0x412c74`; row offset `+0x68`.

**Status:** FAKTA label; parsing BELUM.

**Rekomendasi:** 3D Chart memetakan `sss` dari `b[4]` (0x01 = ON, 0x00 = OFF) pada frame `72 05 71 D1 47`. Gunakan sebagai hipotesis implementasi, verifikasi dengan posisi standar sebenarnya.

---

## 7. Live Data FISV/FID

**Permintaan:** pembacaan FISV/FID, sumber data, format, interpretasi.

**Fungsi H-Diag:** hanya `FIS - Fast Idle Switch` (row 5). Tidak ada `FID` atau `FISV` numerik.

**Mekanisme:** polling kolektif; jalur row 5 belum ditemukan.

**Bukti:** string VA `0x412cbc`; row offset `+0x74`. Pencarian `FID` = TIDAK DITEMUKAN.

**Status:** FAKTA label FIS; FID/FISV sebagai nilai numerik TIDAK TERBUKTI.

**Rekomendasi:** 3D Chart menghitung `fiz = b[18] < 128 ? "ON" : "OFF"` dari frame `72 05 71 17 01` (Fast Idle Step). Itu adalah status biner, bukan nilai FISV. Jika RevCore membutuhkan FISV numerik, riset tambahan diperlukan.

---

## 8. Live Data IACV

**Permintaan:** perintah, respons, satuan, interpretasi IACV.

**Fungsi H-Diag:** `IAC - Katup Udara Masuk` (row 12).

**Mekanisme:** pada dispatch key 8 (`0x405F90`), baris `0x0C` (12) kolom 3 diisi dari teks respons `edi+0x0D`. Respons berupa teks ASCII (QString panjang 0). Frame sumber belum dapat dipastikan; kandidat frame B (`72 05 71 00 18`).

**Bukti:** string VA `0x412d50`; row offset `+0x90`; update `0x405FA9`–`0x405FD5`.

**Status:** REKONSTRUKSI (row + offset); perintah/format/satuan BELUM.

**Rekomendasi:** 3D Chart menghitung `iac = b[22] / 10000` dari `72 05 71 11 07` (dat11) tetapi **tidak menampilkannya**. Nilai ini hanya 1 byte, sehingga satuan/range belum jelas. RevCore sebaiknya menampilkan nilai mentah + label "unverified" sampai dikonfirmasi pada ECU.

---

## 9. Live Data STF (Short Term Fuel Trim)

**Permintaan:** parameter, format, konversi, interpretasi STF.

**Fungsi H-Diag:** `STF - Campuran Bahan Bakar` (row 0).

**Mekanisme:** polling kolektif; jalur row 0 belum ditemukan.

**Bukti:** string VA `0x412c40`; row offset `+0x60`.

**Status:** FAKTA label; parsing BELUM.

**Rekomendasi:** 3D Chart: `stf = b[5] / 128.25651` dari `72 05 71 20 F8`. Perhatikan bahwa formula memakai hanya **satu byte** (low byte) dari pasangan yang mungkin 16-bit; ini berpotensi cacat. RevCore harus memverifikasi apakah STF sebenarnya 8-bit atau 16-bit, arah positif/negatif, dan satuan persen.

---

## 10. Altitude Mode 1–4

**Permintaan:** apakah H-Diag mendukung pembacaan atau pengaturan Mode 1–4; perintah, respons, konfirmasi; jika tidak ada, nyatakan.

**Fungsi H-Diag:** `MOD - Mode Altitude` (row 6) dan `ALT - Koreksi Altitude` (row 7).

**Mekanisme baca:** polling kolektif; jalur row 6/7 belum ditemukan. Tidak ada frame dengan parameter mode di loop polling.

**Mekanisme set:** TIDAK DITEMUKAN. Tidak ada tombol/menu/perintah tulis yang terkait MOD/ALT di jalur yang dianalisis; seluruh frame loop adalah read/keep-alive.

**Bukti:** string VA `0x412cd4`, `0x412ce8`; row offset `+0x78`, `+0x7c`; frame loop E-HD-03.

**Status:** FAKTA label; pembacaan BELUM; pengaturan TIDAK DITEMUKAN.

**Rekomendasi:** 3D Chart (`dat17`, `72 05 71 17 01`) memetakan `b[18]`:

| Nilai | Mode |
|---:|---:|
| 0x80 atau 0x67 | 1 |
| 0x66 | 2 |
| 0x3C | 3 |
| 0x59 | 4 |
| 0x79 | 0 |

Ini adalah pembacaan mode, bukan pengaturan. Untuk RevCore: tampilkan mode 0–4 dari byte tersebut; jangan mengklaim kemampuan set Mode 1–4 sampai ada bukti perintah tulis dan konfirmasi ECU.

---

## Kesimpulan kebutuhan 4–10

1. H-Diag **menampilkan** seluruh parameter yang diminta (kecuali FID dan nama "Relay").
2. H-Diag **tidak** memberi bukti lengkap perintah/byte/konversi per parameter karena tidak ada source; hanya sebagian jalur update yang berhasil direkonstruksi.
3. Sumber 2 (3D Chart) memberikan frame dan formula yang jauh lebih lengkap untuk kebutuhan 4, 6, 7, 8, 9, 10, tetapi tetap berstatus source-verified, bukan ECU-verified.
4. Tidak ada bukti bahwa Altitude Mode dapat **diset** oleh salah satu aplikasi.
5. Semua rekomendasi implementasi wajib melewati pengujian ECU nyata sebelum dinyatakan VERIFIED.
