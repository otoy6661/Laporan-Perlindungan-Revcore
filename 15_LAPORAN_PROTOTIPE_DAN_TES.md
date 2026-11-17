# 15 — LAPORAN PROTOTIPE & TES

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Lokasi:** `13_PROTOTYPES/`
**Status:** SELESAI — dua prototipe C# mandiri, 53 pemeriksaan, 0 gagal.

---

## 1. Lingkungan

| Item | Nilai |
|---|---|
| Runtime | .NET 8.0.204 |
| Bahasa | C# (console, `net8.0`) |
| Dependensi eksternal | Tidak ada (BCL saja) |
| Isolasi | Folder BE-11; tidak menyentuh instalasi/dataset |
| Data uji | Salinan di `04_BIN_AUTOPSY/WORK`, `06_ADX_AUTOPSY/WORK`, `00_SOURCE_INVENTORY/DATASET_COPY` |

---

## 2. Prototipe 1 — `PeScope`

**Tujuan:** mem-parse PE secara independen dan menghasilkan inventaris struktur untuk 9 binary.

**Fungsi:**
- Membaca DOS/PE header, section table, data directory.
- Menuliskan import per DLL, export (termasuk nama termangled), resource tree.
- Mengekstrak string ASCII/UTF-16.
- Menulis JSON per file ke `02_STATIC_ANALYSIS/PE/`.

**Keluaran:** `PE_TunerPro.exe.json` + 8 `PE_*.dll.json`, `STRINGS_*.txt`, resource/menu.

**Validasi:** seluruh 9 binary berhasil diparse; jumlah section (5), image base, dan daftar import/export konsisten dengan pembacaan manual dan dengan snapshot modul runtime. Tidak ada self-test otomatis; validasi bersifat silang.

**Batas:** bukan disassembler; tidak menganalisis instruksi.

---

## 3. Prototipe 2 — `TpFormatKit`

**Tujuan:** mereproduksi pembacaan XDF/BIN/checksum/container secara independen dari TunerPro, lalu membandingkan hasilnya dengan ekspor TunerPro.

### 3.1 Cakupan

| Bagian | Fungsi |
|---|---|
| `XdfDocument` | Parse XML XDF: header, base offset, kategori, tabel, axis, embedded data, MATH, checksum |
| `MathExpr` | Evaluasi ekspresi `+ - * /` dan tanda kurung |
| `Axis`/grid | Membaca breakpoint dan sel sesuai dimensi/stride |
| `Checksum` | SUM region dan komplemen dua |
| `ContainerHeader` | Magic, marker, offset ciphertext, entropy |
| `DatasetScan` | Menghitung 930 file, klasifikasi plaintext, pasangan direktori, tulis CSV |
| `BinaryDiff` | Membandingkan BIN hasil edit |

### 3.2 Hasil self-test

`13_PROTOTYPES/OUT/SELFTEST.txt`: **PASS=53 FAIL=0**.

| Kelompok | Jumlah cek | Hasil kunci |
|---|---:|---|
| XDF parse | 9 | 20 tabel, base 0, 9 kategori, offset `0x3815E`, 35×29, 16-bit |
| BIN/axis | 6 | 262.144 B; axis 29 (0..74,3), 35 (900..9200); grid 35×29 |
| Metadata | 4 | SW Version `SH850T01R100_PV10`; ECM ID `01 03 7A 00 AC` |
| Cross-check | 2 | 18 tabel numerik, **5.338 sel, 0 mismatch** |
| Checksum SUPRA | 10 | Region `0xFFF0`, store `0xFFF1`, `0xFF`; korup `0x00` → `0xFF`; delta 1 byte |
| Checksum CBR | 3 | Region 0..`0x3FFFF`, store `0x3FFF8`, plug-in `IRON-PONY-RK`, `0xEF` |
| BIN diff | 3 | Satu range 2 byte; `0F 27` = 9999 |
| Container XDF | 4 | Magic `05 22 97 00`, marker `0x64`, cipher `0x84`, header tanpa nama |
| Container ADX | 5 | KEIHIN 40.199/entropy 7,995; SHINDENGEN 23.780/7,993 |
| Dataset matrix | 3 | 174 XDF, 13 plaintext |

### 3.3 Cara menjalankan ulang

```powershell
dotnet run --project 13_PROTOTYPES\PeScope -- "C:\Program Files (x86)\TunerPro RT\TunerPro.exe" 02_STATIC_ANALYSIS\PE
dotnet run --project 13_PROTOTYPES\TpFormatKit -- "C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY" "C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\13_PROTOTYPES\OUT"
```

Catatan: jalur dapat berbeda; argumen pertama adalah root BE-11, kedua adalah folder output.

---

## 4. Detail tes penting

### 4.1 Reproduksi tabel

Prototipe membaca langsung BIN pada offset XDF, menerapkan endianness dan MATH, lalu membandingkan dengan CSV ekspor TunerPro (`05_XDF_AUTOPSY/export_tps_rpm.csv`, 530 baris). Hasil: 5.338 sel, 0 mismatch pada toleransi 0,055. Ini membuktikan model alamat/dimensi/endian yang dipakai prototipe konsisten dengan TunerPro untuk sampel K1AA.

### 4.2 Checksum SUPRA

| Uji | Input | Output | Harapan |
|---|---|---|---|
| Nilai asli | `0xFF` | `0xFF` | Tetap |
| Korupsi | `0x00` | `0xFF` | Diperbaiki |
| Data di luar region | ubah `0x1000` | checksum tetap `0xFF` | Tidak berubah |
| Perubahan lain | — | diff = 0 | Tidak ada efek samping |

### 4.3 Checksum CBR

Nilai tersimpan `0xEF` sama dengan komplemen dua dari jumlah byte lain. Definisi meminta plug-in `IRON-PONY-RK`; prototipe hanya **memverifikasi nilai**, tidak menjalankan plug-in.

### 4.4 Container

Prototipe membaca 132 byte header dan menghitung entropy ciphertext. Tidak ada dekripsi.

### 4.5 Dataset

Prototipe memindai salinan dataset (`00_SOURCE_INVENTORY/DATASET_COPY`) dan menulis 177 baris matriks. Penghitungan dilakukan pada salinan, bukan dataset asli.

---

## 5. Batas prototipe

| Keterbatasan | Dampak |
|---|---|
| Tidak ada parser ADX biner | Definisi ADX tidak dapat direproduksi |
| Tidak ada dekripsi container | 161 XDF + 3 ADX tidak terbaca |
| Checksum hanya SUM | Tidak menguji Keihin 16-bit/CRC16 |
| MATH hanya `+ - * / ()` | Ekspresi lain (fungsi, bitwise) tidak diuji |
| Tidak menjalankan plug-in | Perilaku MMCS tidak direproduksi |
| Matriks pasangan berbasis direktori | Bukan verifikasi kompatibilitas |
| Tidak ada uji hardware | Tidak ada klaim protokol |

---

## 6. Kesimpulan pengujian

Prototipe berhasil membuktikan secara independen:

1. Model alamat XDF dan pembacaan BIN (5.338 sel).
2. Perilaku checksum SUM dan normalisasi Save.
3. Struktur container terenkripsi.
4. Skala dataset (174 XDF, 13 plaintext, 3 ADX).

Prototipe **tidak** membuktikan perilaku ECU, protokol Honda, atau isi definisi terenkripsi.

---

## 7. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Hasil self-test | TINGGI (dapat dijalankan ulang) |
| Reproduksi tabel | TINGGI (0 mismatch) |
| Checksum SUM | TINGGI |
| Container | TINGGI untuk header |
| Generalisasi ke semua XDF | SEDANG |
