# 06 — AUTOPSI BIN

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Sampel utama:** `30400-K1AA-N03.bin` (262.144 B), `SUPRA-K41NC1.bin` (65.536 B), `CBR1000RR_checksum_test.bin` (262.144 B)
**Status:** SELESAI — struktur, pemetaan, endianness, dan checksum diverifikasi terhadap salinan kerja. Dataset asli tidak diubah.

---

## 1. Populasi BIN dalam dataset

| Ukuran (byte) | Jumlah file | Kelas alamat |
|---:|---:|---|
| 49.152 | 72 | 48 KB (0xC000) |
| 57.344 | 28 | 56 KB (0xE000) |
| 65.536 | 206 | 64 KB (0x10000) |
| 98.304 | 5 | 96 KB (0x18000) |
| 262.144 | 224 | 256 KB (0x40000) |
| 393.216 | 164 | 384 KB (0x60000) |
| 1.048.576 | 1 | 1 MB (0x100000) |
| **Total** | **700** | — |

Tidak ada BIN dengan ukuran di luar kelas tersebut. Ukuran selalu pangkat dua atau kelipatan 16 KB, konsisten dengan dump linear memori ECU tanpa header container.

**Implikasi:** BIN adalah **image memori mentah**. Tidak ada magic number, panjang, atau offset tabel di dalam file; seluruh makna berasal dari XDF. Ini berbeda dari format FlashPro yang memiliki struktur section sendiri.

---

## 2. Sampel K1AA-N03 (262.144 B)

### 2.1 Metadata yang dapat dibaca

| Alamat | Panjang | Isi | Metode |
|---:|---:|---|---|
| `0x000800` | 5 | `01 03 7A 00 AC` | Tabel XDF outputtype hex |
| `0x00577C` | 17 | `SH850T01R100_PV10` | Tabel XDF outputtype teks |

Keduanya adalah **tabel XDF**, bukan header biner. Tanpa XDF, urutan byte ini tidak dapat ditafsirkan sebagai ID.

### 2.2 Pemetaan tabel (20 objek XDF)

| Tabel | Offset | Dimensi | Lebar sel |
|---|---:|---|---:|
| TPS vs RPM Fast Idle #1 | `0x3815E` | 35 × 29 | 16-bit |
| TPS vs RPM Fast Idle #2 | `0x3894C` | 35 × 29 | 16-bit |
| TPS vs RPM | `0x3AD2E` | 35 × 29 | 16-bit |
| Fuel Deccel | `0x3913A` | 35 × 1 | 16-bit |
| Ignition | `0x39CF8` | 35 × 29 | 8-bit |
| S.O.I — Cold | `0x39B6E` | 8 × 5 | — |
| S.O.I — Warm | `0x39BA0` | 8 × 5 | — |
| DTC | `0x37A7C` | 35 × 2 | — |
| Limiter 1 | `0x37F02` | 2 sel | 16-bit |
| Limiter 2 | `0x38078` | 2 sel | 16-bit |
| Limiter 3 | `0x39858` | 2 sel | 16-bit |
| Limiter 4 | `0x37E18` | 2 sel | 16-bit |
| Limiter 5 | `0x3920E` | 2 sel | 16-bit |
| Target Idle RPM #1 | `0x399D0` | 2 sel | 16-bit |
| Target Idle RPM #2 | `0x3A802` | 2 sel | 16-bit |
| SW Version | `0x577C` | 1 × 17 | teks |
| ECM ID | `0x800` | 1 × 5 | hex |
| Breakpoint TPS | `0x39BFE` | 29 × 1 | — |
| Breakpoint RPM | `0x39C38` | 35 × 1 | — |
| AFR TARGET Maps | `0x3A83C` | 35 × 29 | 8-bit |

Rincian per sel ada di `05_XDF_AUTOPSY/K1AA-N03_TABLE_STATUS.csv`; pohon lengkap di `05_XDF_AUTOPSY/K1AA-N03_TREE.txt`.

### 2.3 Endianness dan encoding

- Sel 16-bit disimpan **big-endian**. Contoh: nilai 3880 pada sel pertama = `0F 28`; nilai 464 = `01 D0`.
- Edit 9999 ditulis sebagai `0F 27` pada `0x3B122` (big-endian 0x270F).
- Sel 8-bit adalah byte tunggal tanpa tanda.
- Teks adalah ASCII tanpa terminator yang dipaksakan; panjang ditentukan XDF (17 byte).
- Tidak ada padding/alignment antar tabel: tabel dapat berimpit atau berurutan tanpa header.

### 2.4 Validasi silang

Prototipe independen membaca 18 tabel numerik (5.338 sel) dan membandingkan dengan ekspor TunerPro: **0 mismatch** pada toleransi 0,055. Dua tabel teks (SW Version, ECM ID) diverifikasi terpisah dan cocok. Bukti: `13_PROTOTYPES/OUT/SELFTEST.txt`.

---

## 3. Sampel SUPRA K41-NC1 (65.536 B)

| Aspek | Nilai | Bukti |
|---|---|---|
| Checksum region | `0xFFF0`..`0xFFF0` (1 byte) | `XDFCHECKSUM` |
| Lokasi simpan | `0xFFF1` | `storeaddress` |
| Ukuran simpan | 8 bit | `storesizebits=8` |
| Metode | 0 (SUM) | `calculationmethod=0` |
| Nilai tersimpan asli | `0xFF` | Byte file |
| Perhitungan | jumlah byte region = `0xFF` (komplemen dua) | Verifikasi prototipe |

Uji kausal:

1. Byte checksum dikorupsi menjadi `0x00` → Save → aplikasi menulis `0xFF`.
2. Byte data di `0x1000` diubah → Save → byte checksum **tidak berubah** dan tidak ada delta lain (diff=0), karena `0x1000` di luar region.
3. Save tanpa perubahan → file identik secara fungsional; checksum tetap `0xFF`.

**Kesimpulan:** checksum dihitung hanya atas region yang dideklarasikan XDF, bukan seluruh image. Klaim "TunerPro memperbaiki checksum ECU" harus dibaca sebagai "TunerPro menjalankan definisi checksum XDF".

---

## 4. Sampel CBR1000RR (262.144 B)

| Aspek | Nilai |
|---|---|
| Region | `0x00000`..`0x3FFFF` (seluruh 256 KB) |
| Lokasi simpan | `0x3FFF8`, 8 bit |
| Metode | 0 (SUM) |
| Plug-in | `pluginmoduleid = 49524f4e-504f-4e59-524b-000000000000` (`IRON-PONY-RK`) |
| Nilai tersimpan | `0xEF` = komplemen dua dari jumlah seluruh byte lain |

Karena plug-in `IRON-PONY-RK` tidak terpasang, Save As gagal dengan pesan checksum. Ini membuktikan bahwa **keberadaan metode di XDF tidak cukup**; plug-in yang dirujuk harus tersedia. Lihat laporan 07 dan 12.

---

## 5. Pola lintas 700 BIN

1. **Tanpa header.** Offset tabel berada di ruang alamat absolut; XDF menentukan semuanya.
2. **Ukuran menentukan ruang alamat.** Checksum CBR di `0x3FFF8` hanya masuk akal untuk image 256 KB; checksum SUPRA di `0xFFF0` untuk image 64 KB.
3. **Metadata minim.** Hanya ECM ID dan SW Version yang dapat dibaca sebagai teks/hex, dan hanya jika XDF menunjuk lokasinya.
4. **Tidak ada signature kriptografis.** Tidak ada hash, sertifikat, atau magic yang membedakan file valid dari file acak seukuran sama.
5. **Risiko tabrakan.** Dua BIN berbeda keluarga dapat berukuran sama (mis. 262.144 B); tanpa XDF yang cocok, tidak ada cara aman menebak arti byte.

---

## 6. Batas autopsi BIN

- Tidak semua 700 BIN dibuka; sampel dipilih yang memiliki XDF plaintext.
- Tidak dilakukan pemetaan seluruh tabel untuk 161 XDF terenkripsi (isinya tidak dapat dibaca tanpa dekripsi).
- Tidak ada pengetahuan tentang arti fisik setiap tabel di luar nama XDF.
- Tidak ada verifikasi bahwa nilai tabel sesuai engine nyata (butuh dyno/ECU).

---

## 7. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Format BIN = image mentah | TINGGI |
| Offset & dimensi tabel sampel | TINGGI (XDF + ekspor + verifikasi) |
| Endianness | TINGGI (byte aktual) |
| Checksum SUM & region | TINGGI (uji kausal) |
| Generalisasi ke seluruh 700 BIN | SEDANG (berdasarkan ukuran & sampel) |
