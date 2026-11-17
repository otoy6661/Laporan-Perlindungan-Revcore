# PROTOTYPE RESULTS — BE-09 FASE E

**Tanggal:** 17 November 2026
**Lingkungan:** Windows, .NET SDK 8.0.204, MSBuild 17.9.8
**Lokasi:** `C:\Users\Lord Otoy\Documents\REVCORE_EXTERNAL_ECU_RESEARCH\PROTOTYPES`
**Batas:** tidak ada EXE/installer/DLL penelitian yang dijalankan; tidak ada ECU fisik;
tidak ada perubahan pada dataset sumber atau proyek RevCore.

---

## 1. Build

| Proyek | Konfigurasi | Hasil | Warning | Error |
|---|---|---|---:|---:|
| `RevCore.Research.Core` | Release | `TESTED_PASS` | 0 | 0 |
| `RevCore.Research.Cli` | Release | `TESTED_PASS` | 0 | 0 |
| `RevCore.Research.SelfTest` | Release | `TESTED_PASS` | 0 | 0 |

Log: `RESULTS/BUILD.txt`.

Catatan build: folder sumber `Bin/` gagal dikompilasi karena MSBuild mengecualikan
folder bernama `bin` (case-insensitive). Folder diubah menjadi `Binary/`; namespace
tetap `RevCore.Research.Bin`. Ini masalah build, bukan perubahan algoritma.

---

## 2. Self-test

Perintah:

```powershell
dotnet run --project tests/RevCore.Research.SelfTest/RevCore.Research.SelfTest.csproj -c Release
```

Hasil: **46 passed, 0 failed** (`RESULTS/SELFTEST.txt`).

| Grup | Assertion | Hasil |
|---|---:|---|
| KZR checksum | 8 | `TESTED_PASS` |
| BIN identification | 5 | `TESTED_PASS` |
| XDF parsing | 8 | `TESTED_PASS` |
| Table reading | 11 | `TESTED_PASS` |
| Equation evaluator | 5 | `TESTED_PASS` |
| TPS / AFR / lambda | 5 | `TESTED_PASS` |
| Loopback transport | 4 | `TESTED_PASS` |
| **Total** | **46** | **`TESTED_PASS`** |

### 2.1 Checksum KZR

| Uji | Nilai teramati |
|---|---|
| `kzra601.bin` stored | `0xFFFF` |
| `kzra601.bin` computed | `0xFFFF` |
| `kzra601.bin` verify | `True` |
| `kzrm_b31_10pct.bin` stored | `0x8744` |
| `kzrm_b31_10pct.bin` computed | `0xB36E` |
| `kzrm_b31_10pct.bin` verify | `False` |
| Patch → verify | `True` |
| Input setelah patch | tidak berubah (`0x8744`, verify `False`) |

Kesimpulan: algoritma hasil pemulihan IL konsisten dengan 38 file uji FASE D
(31 valid, 7 invalid); prototipe mereproduksi dua kasus yang mewakili keduanya.

### 2.2 Identifikasi BIN

| File | Offset | Nilai | Keyakinan |
|---|---|---|---|
| `kzra601.bin` | `0x578` | `010123` | High (ukuran KZR + marker) |
| `k1aa_n03.bin` | `0x800` | `01037A00AC` | High (ukuran K1AA + marker) |
| `k1aa_n03.bin` | `0x577C` | `SH850T01R100_PV10` | string versi |
| KZR checksum suggestion | — | `0x2BB70` | hanya bila ukuran/marker KZR |
| K1AA checksum suggestion | — | `(none)` | tidak dipaksakan |

### 2.3 Pembacaan tabel dan axis ter-link

| Uji | Nilai |
|---|---|
| `TPS vs RPM Fast Idle #1` | 35×29, 16-bit, `0x3815E` |
| Sel pertama (raw) | `3880` |
| 8 nilai pertama | `3880, 4024, 4184, 4412, 4644, 4846, 5473, 5889` |
| Axis X | link ke `Breakpoint TPS`; `0, 0.4, 0.6, 1, 1.5, 2, 3.1, 4.1, 5.1, 6.1` |
| Axis Y | link ke `Breakpoint RPM`; `900, 1200, 1400, 1500, 1600, ...` |
| `AFR TARGET Maps` axis Y[0] | `900` |
| `AFR TARGET Maps` axis X[0] | `0` |

Temuan: axis dengan `<embedinfo type="3" linkobjid="..."/>` harus dibaca dari
tabel target, bukan dari `mmedaddress` axis itu sendiri. Contoh kegagalan sebelum
perbaikan: axis Y `AFR TARGET Maps` menghasilkan `4609, 1513, 5830, ...` dari
`0x1AA2E`. Setelah resolusi: `900, 1200, 1400, ...` dari `Breakpoint RPM` (`0x39C38`).

### 2.4 Evaluator dan konversi

| Ekspresi | Input | Hasil |
|---|---:|---:|
| `X/10` | 1000 | 100 |
| `X/9.5` | 128 | 13.4737 |
| `(X/36.4082)*10` | 3640.82 | 1000 |
| `(((128/x*10)*12.8)+1.9)+10` | 1000 | 28.284 |
| `X + foo` | 1 | ditolak |

| Konversi | Input | Hasil |
|---|---:|---:|
| TPS | 1000 / 10 | 100.0 |
| TPS | 500 / 7.43 | 67.2948 |
| TPS clamp | 2000 / 7.43 | 100.0 |
| AFR | 128 / 9.5 | 13.4737 |
| Lambda | 13.4737 / 14.7 | 0.9166 |

---

## 3. CLI smoke test

Log lengkap: `RESULTS/CLI_SMOKE.txt`.

| Perintah | Hasil kunci |
|---|---|
| `identify kzra601.bin` | `010123` @ `0x578`, checksum `0x2BB70` |
| `identify k1aa_n03.bin` | `01037A00AC` @ `0x800`, versi `SH850T01R100_PV10` |
| `checksum kzrm_b31_10pct.bin` | stored `0x8744`, needed `0xB36E`, `Valid: False` |
| `checksum ... --patch RESULTS/...bin` | `Verify: True` |
| `checksum patched` | `Valid: True` |
| `xdf list` | 20 `XDFTABLE`, termasuk `ECM ID 0x800`, `SW Version 0x577C` |
| `xdf read Fast Idle #1` | 35×29, axis ter-link, nilai pertama `3880` |
| `xdf read AFR TARGET Maps` | axis benar setelah resolusi link |
| `xdf export` | 20 definisi → `RESULTS/k1aa_definitions.csv` |
| `tps 743 --divisor 7.43` | `100` |
| `afr 128 --divisor 9.5` | AFR `13.4737`, lambda `0.9166` |
| `transport-info` | menyatakan D2XX tidak dieksekusi, `HARDWARE_PENDING` |

Representasi 16-bit `Breakpoint TPS` yang teramati: `0, 4, 6, 10, 15, 20, 31, ...,
666, 717, 727, 743`. Dengan equation XDF `X/10` nilai tampil berakhir di `74.3`.
Dengan divisor `7.43` (ditemukan pada XDF lain) nilai `743` menjadi `100`. Kedua
interpretasi dicatat; prototipe tidak mengubah equation XDF.

---

## 4. Hash sumber prototipe

| File | SHA-256 |
|---|---|
| `Xdf/EquationEvaluator.cs` | `a201c99488f07611fbe7375703407f3f77bc6469072ef497231070daacc2ccc7` |
| `Xdf/TableReader.cs` | `03622f68ee160835a17652b280eaf4934e16b262b12a09f5b362578733f594b1` |
| `Xdf/XdfDefinition.cs` | `f4b989ce21c8b36d902e95d63533a54b08f55d6ebd4b1d1bdfe18b3560304176` |
| `Xdf/XdfParser.cs` | `f90d71b6f431946cb9afe7b88721666af1218f23f41654f2d5c4231066048391` |
| `Checksum/KzrChecksum.cs` | `95726430885da00d2e167595933ad03fa5d42552e2259f276c09eb78adb5824b` |
| `Identification/BinIdentifier.cs` | `de2a8160d22e1dcd4c501ebdf95249705300c995b6fd2e1d14b55ef51fead87d` |
| `Conversions/Scales.cs` | `6705d561d69b3420fae5ab78ede9344d13f4d8605162fd4923c048abb0989a94` |
| `Binary/BinImage.cs` | `061d032e743a2f37ff75aab1cfa130aabd06db907b4bb9c106af48c598f575c8` |
| `Transport/D2xxTransport.cs` | `bd09b6a3806474cecce84aa640f3c03ee3b57734f8d45bec09ff4efbef3de4b9` |
| `Transport/FakeTransport.cs` | `542f88390ca938bf07f0e54215c343ca46c7b0610f5836a4ee443d604fc16b92` |
| `Transport/ITransport.cs` | `dbc6934610d53748150f1079fa456804f785150569c8b5f1d25eaa26afe3f620` |
| CLI `Program.cs` | `d1f329dccffb569e3d444e0fc1328ca7ac3e33cd883c51fa354a4cdf2cce9b30` |
| SelfTest `Program.cs` | `0e02d5ed697e26aa381ea6b8ac739540a3808c25af8c9ffa3fa96cc3711248a1` |

Hash ini berlaku untuk hasil build pada tanggal di atas; perubahan kode berikutnya
mengubah nilainya.

---

## 5. Artefak hasil

| File | Isi |
|---|---|
| `RESULTS/BUILD.txt` | log build tiga proyek |
| `RESULTS/SELFTEST.txt` | 46 assertion |
| `RESULTS/CLI_SMOKE.txt` | keluaran seluruh perintah CLI |
| `RESULTS/k1aa_definitions.csv` | 20 definisi XDF K1AA |
| `RESULTS/kzrm_b31_10pct.patched.bin` | salinan ter-patch checksum, verify `True` |

`kzrm_b31_10pct.patched.bin` adalah turunan dataset untuk uji; bukan file ECU siap
pakai dan tidak boleh ditulis ke ECU tanpa validasi hardware serta prosedur resmi.

---

## 6. Kesimpulan status

| Klaim | Status |
|---|---|
| Checksum KZR stride-4 dapat dihitung dan dipatch | `TESTED_PASS` |
| Checksum file 10% memang tidak valid | `TESTED_PASS` |
| Offset ECM ID K1AA/KZR terbaca pada dua famili | `TESTED_PASS` untuk 2 sampel; generalisasi `UNKNOWN` |
| Parser XDF membaca tabel/konstanta/axis link | `TESTED_PASS` untuk 2 XDF |
| Equation XDF dievaluasi tanpa `eval` | `TESTED_PASS` |
| Skala TPS/AFR konsisten dengan XDF | `TESTED_PASS` (aritmetika) |
| Transport D2XX berfungsi pada hardware | `HARDWARE_PENDING` (belum dieksekusi) |
| Frame/protokol K-Line | `UNKNOWN` |
| Live data channel | `UNKNOWN` |
| HISS / Smart Key | `NOT_FOUND` |

Tidak ada klaim hardware, protokol, atau dukungan kendaraan baru yang dibuat dari
hasil prototipe ini.
