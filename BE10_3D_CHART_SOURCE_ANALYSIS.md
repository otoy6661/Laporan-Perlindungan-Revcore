# BE-10 — ANALISIS SOURCE 3D CHART GRAPH (REMAP HONDA K-LINE)

**Sumber:** `...\Downloads\Mobile Devices\3D Chart Graph remap kline\3D Chart Graph remap kline`
**Salinan riset:** `SOURCES\3D_CHART_GRAPH\PROJECT`, `EXTRACTED_ZIPS`, `SOURCES\3D_CHART_GRAPH\ZIPS`
**Status:** **STATICALLY_ANALYZED**; fitur hardware **HARDWARE_PENDING**.

---

## 1. Struktur solusi

- Solution: `Kline_Remap.sln`
- Project: `3D Chart Graph` — WinForms, **.NET Framework 4.8**, C# 7.3
- Output: `Remap Honda K-Line.exe` (WinExe)
- Source total: **31.052 baris** di 27 file `.cs`

File terbesar:

| File | Baris | Peran |
|---|---:|---|
| `Form1.cs` | 19.973 | Monolit utama: koneksi, live data, tabel, tulis flash, lisensi, Smart Key |
| `SMK.cs` | 1.856 | Smart Key / EEPROM |
| `Form1.Designer.cs` | 1.589 | Layout UI |
| `Graph3D.cs` | 1.573 | Grafik 3D |
| `AGauge.cs` | 1.537 | Gauge analog |
| `Diag.cs` | 1.399 | Dashboard diagnostik/live data |
| `DYNO.cs` | 361 | Dyno |
| `Graph3DMainForm.cs` | 271 | Host grafik |
| `Chart.cs` | 204 | Grafik 2D |
| `FunctionCompiler.cs` | 115 | Evaluator ekspresi |
| `Program.cs` | 30 | Entry point |

Hash source kunci:

- `Form1.cs` = `01fc11d11cc3af02fbf1e8f9bc75f740c07d70fb80f0ac91fe1c1d63264d326e`
- `Diag.cs` = `38c2844f6b573e646eee04f689bb4429891610cddecf34a2e945ff34efd56135`
- `SMK.cs` = `f8dbf0beecd3569d660c72df3423850797f3500b7cb698120bba013d12308a49`

---

## 2. Dependensi

Dari `Kline_Remap.csproj`:

| Dependensi | Versi | Dipakai untuk |
|---|---|---|
| `Bunifu.Licensing` | 6.0.4 | Lisensi UI |
| `FTD2XX_NET` | (DLL eksternal) | Transport K-Line |
| `Newtonsoft.Json` | 13.0.3 | Konfigurasi/JSON |
| `RestSharp` | 112.1.0 | HTTP client (fitur online/telemetry) |
| `System.Management` | — | Serial number hardware |
| `ZXing.Net` | 0.16.11 | QR/barcode |
| `System.CodeDom` | 9.0.0-preview | Kompilasi ekspresi runtime |

Implikasi: aplikasi tidak berdiri sendiri secara kriptografis; ia memakai DLL FTDI dan komponen lisensi. Untuk RevCore, **jangan** meniru ketergantungan ini; cukup tiru protokolnya.

---

## 3. Database internal

### 3.1 Map database

`ANALYSIS\3D_MAP_DATABASE.csv` — **152 model**, 33 kolom:

`Index, Name, Resource, columnCount, rowCount, tpsh, rpmh, iaph, feul1..3, ig1..5, limit1..7, lm, o2, o2c, IMMO, MODE0..4, kon`

- `columnCount`: 22, 25, atau 29 (TPS breakpoint).
- `rowCount`: 29 atau 35 (RPM breakpoint).
- `kon`: 104 model `1.0f`; 32 model `3.64086f`; 16 model `3.6408695f`. Nilai ini adalah pembagi RPM; dua nilai 3.64086… hanya berbeda presisi float.
- Offset adalah **offset file BIN**, bukan alamat ECU.
- 7 baris memakai tabel big-endian: `feul1 = 0x3A804` (6 model) atau `0x3911C` (1 model). `BinTableReader.BigEndianForTable` juga mengenali `0x3A258` dan `0x396C8` dari source.

### 3.2 ECU ID database

`ANALYSIS\3D_ECU_ID_DATABASE.csv` — **169 ID**:

- KEIHIN: 97
- SHINDENGEN: 72
- Contoh pertama: `0101F30F11` / `VERZA 150 (K18G-941)`, start `0x8000`, checksum offset `0`.
- Beberapa `ChecksumOffset` bernilai literal `"auto"`; software menyelesaikannya saat runtime dengan pemindaian signature (`ShindengenAutoChecksum`).

### 3.3 BIN contoh tertanam

**154 file** `.bin` di project (`EmbeddedResource`), termasuk `STD.bin` dan `STD32.bin`:

- 51 × 262.144 byte (256 KB)
- 41 × 393.216 byte (384 KB)
- 16 × 49.152 byte (48 KB)
- 46 × 65.536 byte (64 KB)

Tidak ada file > 512 KB. Ini konsisten dengan image linear ECU Honda kecil/menengah.

---

## 4. Model tabel dan parsing

Dari `Form1.cs` dan divalidasi prototipe:

- Tabel bahan bakar: `uint16` **row-major**, `rows = RPM`, `cols = TPS`.
- TPS fisik = `raw / 10`.
- RPM fisik = `raw / kon`.
- Bahan bakar = `raw / 1000` (satuan ditampilkan sebagai ms; bukan dikonfirmasi).
- Default little-endian; tabel tertentu big-endian (lihat 3.1).
- Axis TPS/RPM dibaca dari offset `tpsh`/`rpmh`, bukan dari tabel itu sendiri.

Validasi nyata (`PROTOTYPES\RESULTS\BE10_TABLE_VALIDATION.csv`, 5/5 `SAMPLE_TEST_PASSED`):

| Model | BIN | Offset | BE | Grid | TPS | RPM | Fuel |
|---|---|---|---:|---|---|---|---|
| BEAT 110 K1AA-N03 | 262.144 | `0x3815E` | tidak | 29×35 | 0–74,3 | 900–9.200 | 0,464–12,584 |
| VARIO 150 K59A-A11 | 393.216 | `0x190EC` | tidak | 25×29 | 0–74,3 | 900–9.600 | 0,174–3,381 |
| BEAT 110 K25G-601 | 262.144 | `0x19130` | tidak | 25×29 | 0–74,3 | 1.000–9.500 | 0,141–3,821 |
| VARIO 125 KZRM-B31 | 393.216 | `0x194C0` | tidak | 25×29 | 0–74,3 | 900–9.850 | 0,066–3,587 |
| VARIO 110 K46-N21 | 262.144 | `0x3911C` | **ya** | 25×29 | 0–74,3 | 1.000–9.500 | 0,376–10,190 |

Ini memperluas BE-09: BE-09 hanya memvalidasi pemetaan XDF; BE-10 membuktikan **parser tabel BIN mandiri** bekerja pada lima file nyata, termasuk satu tabel big-endian.

---

## 5. Fitur aplikasi (dari source, bukan dari nama menu)

| Fitur | Bukti | Status |
|---|---|---|
| Buka BIN dari file | `binBytes`, `SaveBinBytesWithDialog` | `FOUND_IN_SOURCE` |
| Edit tabel 2D/3D | `dataGridView1`, `StoreInitialCellValues` | `FOUND_IN_SOURCE` |
| Grafik 3D | `Graph3D.cs` | `FOUND_IN_SOURCE` |
| Grafik 2D | `Chart.cs` | `FOUND_IN_SOURCE` |
| Gauge | `AGauge.cs`, `analogrpm/analogtps` | `FOUND_IN_SOURCE` |
| Live data | `LoopDat17`, `dat10/11/13/16/17/20` | `STATICALLY_ANALYZED` |
| Tulis flash | `WriteFlash`, pra-tulis | `STATICALLY_ANALYZED` |
| Baca ECM ID | `WorkerThread` (`Form1.cs:686–689`) | `STATICALLY_ANALYZED` |
| Baca flash count | `array4/array5` | `STATICALLY_ANALYZED` |
| Recovery | ID berakhiran `0000` | `STATICALLY_ANALYZED` |
| Smart Key EEPROM | `SMK.cs` | `STATICALLY_ANALYZED` |
| Dyno | `DYNO.cs` | `FOUND_IN_SOURCE` |
| License | `lic.kye`, AES, serial mesin | `STATICALLY_ANALYZED` |

**Yang tidak ada:** rutin **baca BIN penuh dari ECU**. `WorkerThread` hanya mengirim ID dan flash count; tidak ada loop membaca memori/flash. Status: `NOT_FOUND_AFTER_MEANINGFUL_SEARCH`.

---

## 6. Alur koneksi dan identifikasi

`WorkerThread` (`Form1.cs:572–741`):

1. `InitFtdiIso()`.
2. Kirim `FE 04 72 8C` (wake) lalu `72 05 00 F0 99`.
3. Fallback keepalive: `7E 06 01 01 00 7A` (Keihin) atau `7C 06 02 01 00 7B` (Shindengen), tergantung balasan.
4. Baca ECM ID: `72 07 72 00 00 05 10`; ambil 5 byte pada offset 5..9 → string hex 10 karakter.
5. Baca flash count: `7D 06 01 01 03 78` / `7B 06 02 01 03 79`; byte 6.
6. Cocokkan ID dengan `khEcmId`/`shEcmId` untuk menentukan tipe ECU.

Tidak ada autentikasi sebelum baca ID; security (seed/key) baru muncul saat pra-tulis.

---

## 7. Lisensi dan proteksi

- File lisensi: `lic.kye`, **160 byte**, SHA-256 `8cbf4bdc354b5d9565b237532490efd77c334a2e579c375cba6b58026f5df69f`. Identik di kedua ZIP.
- Lisensi mengikat **serial prosesor + serial disk** menjadi satu string, di-hash, lalu dibandingkan dengan isi `lic.kye` yang didekripsi.
- Source memuat konstanta kunci/IV AES **hardcoded**. Nilainya **sengaja tidak direproduksi** di laporan ini (aturan work order: jangan menyalin kredensial/private key/lisensi).
- Gerbang lisensi:
  - `Form1_Load` (`Form1.cs:19326`) keluar aplikasi bila user/phone kosong atau serial tidak cocok.
  - `BtnWrite_Click_1` (`Form1.cs:18417`) menolak tulis bila lisensi tidak valid.
  - `button3_Click` (`Form1.cs:18466`) menolak koneksi bila lisensi tidak valid.
  - `flas()` memiliki pemeriksaan dalam yang **selalu lolos** karena membandingkan konstanta `KeyFilePath != "lic.kye"` (`Form1.cs:751`), tetapi `flas()` hanya dipanggil dari `BtnWrite_Click_1` setelah gerbang luar lolos.
- Kesimpulan: proteksi **ada dan menargetkan mesin**, bukan sekadar UI. Tidak ada upaya bypass; analisis berhenti di deskripsi.

Catatan etis: laporan ini tidak memuat nilai kunci, isi `lic.kye`, atau langkah melewati lisensi.

---

## 8. Provenance ZIP

| Arsip | SHA-256 | Isi |
|---|---|---|
| `Remap Honda K-Line.zip` | `ced606c24d40d09bf24b26f22fcfc03dc4bfd49898dd78f8a21f08f0204dea5a` | 1 EXE, PDB, config, `lic.kye`, 20+ DLL/XML |
| `REMAP HONDA KLINE SIAP.zip` | `e125db10840f5e708eb89ea2e34a406b301f07b9a6ce2b104fc27d9f2cb8d43f` | Struktur sama, build berbeda |

Bukti build berbeda:

- `Remap Honda K-Line.exe` = `2d170cc1…` vs `7f59b027…`
- PDB = `aebdde61…` vs `63600458…`
- `lic.kye`, config, dan `K-Line Remap.exe.config` identik.

Tidak ditemukan ZIP bersarang di dalam kedua arsip. Ekstraksi dilakukan ke `EXTRACTED_ZIPS` tanpa menimpa file dan tanpa mengubah arsip asli.

---

## 9. Kemandirian dari ADX/XDF

Pencarian case-insensitive `.adx` dan `.xdf` di seluruh `.cs` dan `.csproj`: **tidak ada hasil**. Aplikasi ini:

- tidak membaca ADX;
- tidak membaca XDF;
- memakai database CSV internal (`MapDatabase`) dan file BIN.

Jadi klaim "3D Chart Graph adalah editor ADX" **tidak benar** untuk source ini. ADX adalah artefak terpisah dalam dataset.

Status: `NOT_FOUND_AFTER_MEANINGFUL_SEARCH` untuk ketergantungan ADX/XDF.

---

## 10. Kualitas dan risiko source

- `Form1.cs` 19.973 baris adalah monolit; sulit diaudit dan rawan regresi.
- Banyak angka ajaib (offset, checksum, timing) tanpa konstanta bernama.
- Jalur tulis dan Smart Key berada di file yang sama dengan UI; tidak ada pemisahan lapisan.
- Tidak ada unit test di source.
- Tidak ada dokumentasi protokol internal.

Untuk RevCore, rekomendasinya adalah **memisahkan** transport, protokol, checksum, dan UI — bukan menyalin struktur ini.

---

## 11. Evidensi

- `SOURCES\3D_CHART_GRAPH\PROJECT\3D Chart Graph\` — source lengkap.
- `ANALYSIS\3D_MAP_DATABASE.csv`, `3D_ECU_ID_DATABASE.csv`.
- `PROTOTYPES\RESULTS\BE10_TABLE_VALIDATION.csv`.
- `REPORTS\BE10_SHA256_MANIFEST.csv` — hash 154 BIN, DLL, EXE, ZIP, ADX.
