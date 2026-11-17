# 11 — MAP DAN KALIBRASI

**Work order:** BE-12
**Status:** SOURCE VERIFIED (model & operasi) · isi/rumus **NOT VERIFIED**
**Sumber:** `07_BIN_MAP_AUTOPSY/BIN_MAP_MODEL.md`, `UI_MENU_MAP.md`

---

## 1. Skema VomConfig

FLASHPRO Windows memakai field offset yang **identik** dengan `VomConfig` yang sudah dipetakan RevCore:

| Kelompok | Field |
|---|---|
| Sumbu | `tpsh`, `rpmh`, `iaph` |
| Bahan bakar | `feul1`, `feul2`, `feul3`, `iap` |
| Pengapian | `ig1`..`ig4` |
| Limiter | `limit1`..`limit7` |
| Switch/flag | `o2/o2mask`, `o2c/o2cmask`, `immo/immomask`, `mode0..4`, `bass`, `iacv`, `ect`, `iat`, `vss`, `mapp` |
| Skala | `konversrpm`, `konversilmtr` (Single) |

Ini kesamaan struktural paling kuat antara FLASHPRO dan RevCore. Namun kesamaan nama field **tidak** membuktikan offset/rumus identik untuk setiap ECM.

## 2. Representasi sel

- `ConvertUShortToValue`, `ConvertValueToUShort` (dan varian `2`) → sel = word 16-bit little-endian.
- `Clamp` membatasi nilai.
- `CreateTable`, `DisplayData`, `TPSBREAK`, `RPMBREAKPOIN`, `IAPBREAK`, `ukuran/2/3` membentuk tabel 3D dari breakpoint × breakpoint.
- Skala/offset per tabel **NOT VERIFIED** (tanpa IL).

## 3. Operasi edit

| Operasi | Metode/string |
|---|---|
| Tambah/kurangi | `TambahNilai`, `KurangiNilai`, `Tambah Value`, `Kurangi Value` |
| Persentase | `Tambah Value (%)`, `Kurangi Value (%)` |
| Isi/flatten | `Fill / Set Value`, `isivom` |
| Interpolasi | `TambahNilaiInterpolasi`, `Interpolasi (%)` |
| Kali/bagi | `KaliNilai`, `BagiNilai` |
| Copy/paste blok | `CopySelectedCells`, `PasteDataToSelectedCells`, Ctrl+C/V |
| Bandingkan | `COMPARE MODE ON`, `CompareValues` |
| Auto-map | `Automaping_Click_1`, `compareToDataBaseToolStripMenuItem` |
| Simpan nilai | `SaveEditedValues(2)`, `Save Value` |

`Eval` mengompilasi ekspresi C# saat runtime (`sin/cos/log/pow`) — fitur produktivitas, bukan protokol.

## 4. Menu & tampilan

- File: Open/Save/Save As.
- Map: Base Map, Auto Mapping, Compare to Database.
- View: RPM/TPS/IAP 2D, Show All, 3D.
- Breakpoint: RPM/TPS/IAP.
- Fuel, Ignition 1–5, Limiter 1–7.
- O2/sensor toggles (`offBASSensor`, `offMAPSensor`, `offECT`, `offIAT`, `offVSS`), Mode 4 OFF.
- Chart: RPM vs TPS 1/2, RPM vs IAP; `Graph3D` (Plot3D) dengan tema warna.

Nama menu berasal dari handler; perilaku tidak dieksekusi.

## 5. Format `.map`

- Menu Maping menyimpan `.map` (`Map File (*.map)|*.map`), parameter `Stride`/`MinorStride`.
- Ada `EncryptBytes`/`DecryptBytes2`, literal `SHA256`, dan sepasang kunci AES 16-byte hardcoded.
- Kesimpulan: `.map` **bukan** dump mentah; ia kontainer terenkripsi + metadata/hash. Format persisnya sudah dipetakan di `MapCrypto.kt` RevCore; untuk laporan ini cukup: **terenkripsi, tidak dapat dibaca tanpa kunci**.
- Apakah `.bin` yang disimpan juga dienkripsi: **tidak terbukti** (kedua jalur memakai `EncryptBytes`, pemanggil tidak dapat dipastikan tanpa IL).

## 6. Perbandingan dengan RevCore

| Aspek | FLASHPRO | RevCore |
|---|---|---|
| Skema offset | VomConfig identik | VomConfig |
| Sel | word 16-bit | word/scalar sesuai parser |
| Editor | 2D/3D, auto-map, ekspresi, compare DB | heatmap + line chart, edit + validasi |
| Format simpan | `.map` AES | `.map` AES (kompatibel) |
| Auto-map | Ada | Belum |
| Verifikasi round-trip | Tidak terlihat | `MapEditor.verifyRoundTrip` |

## 7. Batas

Tidak ada file BIN/MAP nyata di workspace; tidak ada uji buka→edit→simpan. Semua pernyataan tentang hasil edit, skala, dan round-trip berstatus **NOT VERIFIED**.
