# BE-10 — HASIL PROTOTIPE DAN PENGUJIAN

**Lokasi:** `PROTOTYPES\src\BE10Tools`
**Runtime:** .NET 8 (console), tanpa dependensi eksternal
**Prinsip:** hanya membaca salinan uji; tidak menyentuh source donasi, tidak menghubungi ECU.

---

## 1. Build

```
dotnet build -c Release
Build succeeded. 0 Warning(s) 0 Error(s)
```

Dikonfirmasi ulang pada 17 November 2026 setelah seluruh pekerjaan tulis laporan dimulai; tidak ada perubahan kode.

---

## 2. Cakupan prototipe

| Modul | Fungsi |
|---|---|
| `Adx/AdxInspector.cs` | Inspeksi kontainer ADX tanpa dekripsi |
| `Maps/MapDatabase.cs` | Parse database 152 model (33 kolom) |
| `Maps/BinTableReader.cs` | Baca/tulis tabel, endianness, export CSV, bandingkan BIN |
| `Maps/Interpolation.cs` | Bilinear, nearest, statistik perbandingan |
| `Protocol/HondaProtocol.cs` | Frame, checksum Honda/Keihin/Shindengen, seed/key |
| `Protocol/LiveData.cs` | Decoder dat10/11/13/16/17/20/D1 |
| `Formula/SimpleFormula.cs` | Evaluator ekspresi (shunting-yard) |
| `Tests/TestRunner.cs` | 26 tes dengan hash sebelum/sesudah |
| `Program.cs` | `selftest`, `adx`, `validate`, `catalog`, `compare` |

---

## 3. Hasil self-test

**26/26 lulus, 0 gagal** (`PROTOTYPES\RESULTS\SELFTEST.txt`).

| Kelompok | ID | Hasil | Inti |
|---|---|---|---|
| ADX | ADX-01..03 | 3/3 `SAMPLE_TEST_PASSED` | Kontainer, tag, entropy, hash stabil |
| Database | DB-01..02 | 2/2 | 152 model; 169 ID (97/72) |
| Tabel BIN | MAP-01..05 | 5/5 | 5 BIN nyata, termasuk big-endian |
| Checksum | CK-01..03 | 3/3 | Honda, Keihin, Shindengen |
| Seed/key | SK-01 | 1/1 | `0x39A4` |
| Live data | LD-01..06 | 6/6 | dat10/13/16/17/20/D1 |
| Formula | FX-01 | 1/1 | Tiga ekspresi |
| Interpolasi | IN-01 | 1/1 | Titik tengah, clamp, nearest |
| Edit | ED-01 | 1/1 | Tulis ke salinan, hash sumber tetap |
| Export | EX-01 | 1/1 | 35×29, nilai pertama/terakhir benar |
| Compare | CP-01 | 1/1 | 131.901 byte berbeda |
| Frame | FR-01 | 1/1 | 2 frame, checksum kedua ditolak |

---

## 4. Validasi tabel nyata

`validate` memetakan 5 model ke BIN asli dan menulis `BE10_TABLE_VALIDATION.csv`.

| Model | Grid | Endian | Rentang fuel | Hasil |
|---|---|---|---|---|
| BEAT 110 K1AA-N03 | 29×35 | LE | 0,464–12,584 | `SAMPLE_TEST_PASSED` |
| VARIO 150 K59A-A11 | 25×29 | LE | 0,174–3,381 | `SAMPLE_TEST_PASSED` |
| BEAT 110 K25G-601 | 25×29 | LE | 0,141–3,821 | `SAMPLE_TEST_PASSED` |
| VARIO 125 KZRM-B31 | 25×29 | LE | 0,066–3,587 | `SAMPLE_TEST_PASSED` |
| VARIO 110 K46-N21 | 25×29 | **BE** | 0,376–10,190 | `SAMPLE_TEST_PASSED` |

Angka TPS/RPM/fuel masuk akal untuk map injeksi: TPS 0–74,3%; RPM 900–9.850; fuel 0,07–12,6. Tidak ada grid yang menghasilkan nilai negatif atau lompatan tak wajar.

---

## 5. Katalog sensor

`catalog` menulis `REPORTS\BE10_SENSOR_LIVE_DATA_CATALOG.csv` — **45 kanal**. Setiap baris memuat perintah, byte index, tipe raw, ekspresi, rumus fisik, unit, varian, evidensi, dan status `STATICALLY_ANALYZED`.

Contoh: RPM `(b[4]<<8)+b[5]`; TPS1 `b[6]*5/256`; TPS2 `b[7]/2`; ECT2 `b[9]-40`; AFR `-5.351*(b[4]/50.9937)+17.7` (estimasi software).

---

## 6. Export grafik

`EX-01` mengekspor map fuel K1AA-N03 ke `BE10_K1AA_FUEL_GRAPH.csv`:

- 35 baris data × 29 kolom;
- nilai pertama 3,880; terakhir 10,149;
- re-import membaca jumlah baris/kolom dan nilai ujung yang sama.

Ini membuktikan format export/import konsisten, bukan sekadar menulis file.

---

## 7. Edit dan integritas

`ED-01`:

- Menyalin `k1aa_n03.bin` → `work_k1aa.bin`.
- Menulis raw `5000` di `feul1` baris 0 kolom 0.
- Membaca ulang: nilai 5,000; byte di `0x3815E` = `88 13` (LE).
- SHA-256 sumber **tidak berubah**.

Tidak ada file sumber yang ditulis. Semua uji memakai salinan di `PROTOTYPES\testdata` atau `RESULTS`.

---

## 8. Stabilitas hash input

Bagian `INPUT HASH STABILITY` di `SELFTEST.txt` mencatat 9 file uji:

- 2 ADX
- 2 CSV database
- 5 BIN

Semuanya `UNCHANGED` sebelum/sesudah. Ini bukti kuat bahwa pekerjaan bersifat read-only terhadap data.

---

## 9. Batasan

- Decoder live data diuji dengan **response sintetis**, bukan frame ECU nyata.
- Checksum diuji dengan vektor sintetis dan tabel BIN; belum pada firmware ECU asli.
- Seed/key diuji aritmetikanya; belum pada ECU.
- ADX hanya kontainer; isi tidak dibaca.
- Tidak ada eksekusi FTDI, tidak ada koneksi serial, tidak ada perintah ke ECU.

---

## 10. Cara mereproduksi

```
cd PROTOTYPES\src\BE10Tools
dotnet build -c Release
dotnet run -c Release --no-build -- selftest
dotnet run -c Release --no-build -- validate
dotnet run -c Release --no-build -- catalog
```

Output ditulis ke `PROTOTYPES\RESULTS` dan `REPORTS`.
