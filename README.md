# PROTOTYPES — Prototipe Riset BE-09

Workspace terisolasi untuk membuktikan algoritma yang didukung bukti dari FASE C/D.
Tidak ada kode RevCore yang diubah, tidak ada software yang diteliti yang dijalankan,
dan tidak ada koneksi ke ECU fisik.

## 1. Prinsip

1. Hanya algoritma dengan bukti (IL, symbol, XDF, dump BIN) yang diimplementasikan.
2. Input selalu berupa **salinan** di `testdata/`; file sumber tidak disentuh.
3. Semua operasi tulis (patch checksum) menghasilkan file baru dan menolak menimpa input.
4. Transport D2XX hanya dikompilasi, **tidak pernah dieksekusi**; tidak ada frame protokol.
5. Status bukti per komponen: `ANALYZED`, `PROTOTYPED`, `TESTED_PASS`, `HARDWARE_PENDING`.

## 2. Struktur

```text
PROTOTYPES/
├── src/
│   ├── RevCore.Research.Core/       # library algoritma
│   │   ├── Binary/BinImage.cs       # akses image linear + bounds check
│   │   ├── Checksum/KzrChecksum.cs  # checksum KZR stride-4 16-bit
│   │   ├── Identification/BinIdentifier.cs
│   │   ├── Conversions/Scales.cs    # TPS % dan AFR/lambda
│   │   ├── Xdf/                      # parser XDF 1.60/1.70, evaluator, pembaca tabel
│   │   └── Transport/               # ITransport, FakeTransport, D2xxTransport (tidak dieksekusi)
│   ├── RevCore.Research.Cli/        # CLI: identify, checksum, xdf, tps, afr
├── tests/RevCore.Research.SelfTest/ # 46 assertion tanpa framework eksternal
├── testdata/                        # 5 salinan + PROVENANCE.json (SHA-256)
└── RESULTS/                         # BUILD.txt, SELFTEST.txt, CLI_SMOKE.txt, CSV, patched copy
```

## 3. Komponen dan dasar bukti

| Komponen | Dasar bukti | Status |
|---|---|---|
| `KzrChecksum` | IL `CheksumKZR.Form1::Checksum` (stride 4, zero field, two's complement) — lihat `TECHNICAL_FINDINGS/ECU_CHECKSUM_RESEARCH.md` | `TESTED_PASS` |
| `BinIdentifier` | Tabel offset ECM ID/versi dari dump nyata — `ECU_IDENTIFICATION_RESEARCH.md` | `TESTED_PASS` (offline, 2 famili) |
| `XdfParser` | XDF 1.60/1.70 XML: `XDFTABLE`, `XDFCONSTANT`, `XDFFLAG`, `XDFPATCH`, axis link `embedinfo type="3"` | `TESTED_PASS` (2 XDF) |
| `EquationEvaluator` | Ekspresi `XDF` (`X`, angka, `+ - * /`, kurung) tanpa `eval` | `TESTED_PASS` |
| `TableReader` | `mmedaddress`/`mmedelementsizebits`/row/col, equation z, axis 8/16/32-bit | `TESTED_PASS` |
| `TpsScale`, `AfrLambda` | Divisor XDF 10 / 7.43 / 13.286 / 9.4; AFR X/9.5, X/9, X/8.725, X/10, X/7.71 | `TESTED_PASS` (aritmetika) |
| `D2xxTransport` | P/Invoke `ftd2xx.dll` (nama fungsi dari ANALIST/HondaECU) | `HARDWARE_PENDING`, tidak dieksekusi |
| `FakeTransport` | Loopback in-memory untuk antarmuka transport | `TESTED_PASS` |

## 4. Build

Prasyarat: .NET SDK 8 (teruji pada 8.0.204), Windows.

```powershell
dotnet build src/RevCore.Research.Core/RevCore.Research.Core.csproj -c Release
dotnet build src/RevCore.Research.Cli/RevCore.Research.Cli.csproj -c Release
dotnet build tests/RevCore.Research.SelfTest/RevCore.Research.SelfTest.csproj -c Release
```

Log: `RESULTS/BUILD.txt` — 3/3 build sukses, 0 warning, 0 error.

## 5. Self-test

```powershell
dotnet run --project tests/RevCore.Research.SelfTest/RevCore.Research.SelfTest.csproj -c Release
```

Hasil terakhir: **46 passed, 0 failed** (`RESULTS/SELFTEST.txt`).

Cakupan: checksum KZR valid/invalid/patch, identifikasi KZRA/K1AA, parsing XDF
(20 tabel K1AA, ECM ID 0x800/0x788, SW Version 0x577C, AFR X/9.5), pembacaan tabel
Fast Idle 35×29 + axis ter-link, evaluator, TPS/AFR, loopback transport.

## 6. CLI

```powershell
dotnet run --project src/RevCore.Research.Cli -- identify testdata/k1aa_n03.bin
dotnet run --project src/RevCore.Research.Cli -- checksum testdata/kzrm_b31_10pct.bin
dotnet run --project src/RevCore.Research.Cli -- checksum testdata/kzrm_b31_10pct.bin --patch RESULTS/out.bin
dotnet run --project src/RevCore.Research.Cli -- xdf list testdata/30400-K1AA-N03.xdf
dotnet run --project src/RevCore.Research.Cli -- xdf read testdata/30400-K1AA-N03.xdf testdata/k1aa_n03.bin --title "AFR TARGET Maps"
dotnet run --project src/RevCore.Research.Cli -- xdf export testdata/30400-K1AA-N03.xdf RESULTS/k1aa_definitions.csv
dotnet run --project src/RevCore.Research.Cli -- tps 500 --divisor 7.43
dotnet run --project src/RevCore.Research.Cli -- afr 128 --divisor 9.5
dotnet run --project src/RevCore.Research.Cli -- transport-info
```

Contoh keluaran lengkap: `RESULTS/CLI_SMOKE.txt`.
Exit code `checksum`: 0 valid, 3 tidak valid, 2 kesalahan argumen/penolakan tulis.

## 7. Temuan dari prototipe

- Checksum KZR terbukti: file 10% menyimpan `0x8744`, seharusnya `0xB36E`;
  patch menghasilkan `0xB36E` dan verifikasi `True` tanpa mengubah input.
- Axis XDF bertipe `embedinfo type="3"` (linked) **tidak** memakai `mmedaddress`
  miliknya sendiri; jika dibaca mentah hasilnya sampah (contoh axis Y AFR).
  Resolusi ke tabel target (`Breakpoint TPS` / `Breakpoint RPM`) menghasilkan
  axis yang konsisten: `0, 0.4, 0.6, 1, ...` dan `900, 1200, 1400, ...`.
- XDF K1AA memakai `X/10` pada Breakpoint TPS; raw 743 → 74.3. Divisor 7.43
  (dari XDF lain) memetakan 743 → 100. Perbedaan ini dicatat, tidak “diperbaiki”
  secara diam-diam.
- Tabel AFR K1AA menunjukkan nilai awal 13.4737 (128 / 9.5) pada 3×6 sel pertama.

## 8. Batas yang tidak dilampaui

- Tidak ada frame K-Line/ECU, service ID, baud, atau timing yang dikarang.
- `D2xxTransport` tidak dijalankan; `ftd2xx.dll` tidak dimuat.
- Live data tidak didekode karena offset channel belum diketahui.
- HISS/Smart Key tidak diimplementasikan (hanya satu symbol setter; batas etis).
- Tidak ada operasi write/erase ECU, recover, atau unlock XDF.
- Hanya 2 famili BIN dan 2 XDF yang diuji; generalisasi belum dibuktikan.

## 9. Provenance

`testdata/PROVENANCE.json` mencatat path sumber, ukuran, dan SHA-256 setiap salinan.
Semua berasal dari dataset yang sudah dipisahkan di workspace ini.
