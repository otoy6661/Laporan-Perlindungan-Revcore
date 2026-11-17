# Identifikasi ECU — Mekanisme yang Terbaca

**Status:** SOURCE VERIFIED (struktur) · **RUNTIME ID READ: BLOCKED** (butuh ECU fisik).

---

## 1. Keluarga ECU

Enum `ECUTYPE` (6 nilai + `value__`; metadata melaporkan 7 field):

```
KEIHINOTHER, KEIHINH8C, KEIHINM32R,
SHINDENGENV850, SHINDENGENRH850, SHINDENGENRH850B
```

Dua vendor, tiga varian Keihin, tiga varian Shindengen. Ini bukan daftar kosmetik: metode flash dan checksum berbeda per keluarga (`ShindengenPreWriteFlash`, `KeihinPreWriteFlash`, `ShindengenAutoChecksum`, `KeihinAutoChecksum`).

## 2. Dua jalur identifikasi

### A. Jalur K-Line (ECU hidup)

- `Form1.connececm` → `InitClass15Iso` → `SendCommand`.
- `Form1.GetEcuType` menentukan keluarga dari respons.
- UI menampilkan **ECM ID**, **ECM PART CODE**, **Star**, **Checksum**; kegagalan → `ID tidak valid`, `Unknown Part Code`.
- `ReadECU.Read48` membaca blok **48 KB** dari MCU; `Extract14to25` mengambil byte ke-14..25 dari respons (kandidat kuat area ID, **NOT VERIFIED** karena tanpa capture).

### B. Jalur EEPROM/keyless (SMK)

- `READ ID KEYLESS`: baca EEPROM lewat I2C, lalu `ProcessKEIHIN` / `ProcessPcxValues` mengolah isi menjadi ID.
- Ada pemilihan model (`TYPE ECM` → HONDA / KEIHIN / SHINDENGEN / YAMAHA / SUZUKI) dan `Model ECM tidak dikenali`.
- Output disimpan `C:\READ ID SMARTKEY\eeprom_{tipe}_scu_{id}_{timestamp}.bin`.

Artinya: identifikasi di FLASHPRO **tidak hanya** dari handshake K-Line; untuk Honda keyless ia membaca memori kunci.

## 3. Database yang dibawa aplikasi

| Artefak | Jumlah | Sumber |
|---|---:|---|
| Nama file BIN (`FLASHPRO.*.bin`) | 160 | string `#US` → `BIN_CATALOG.csv` |
| Part code unik (`30400-…`, `38770-…`) | 157 | string + CSV `PART_CODES.csv` (333 baris dengan duplikat sumber) |
| Seri kendaraan | 29 kategori + `Other Series` | string UI |
| DTC | 37 | string UI → `DTC_CODES.csv` |
| Profil/offset per ECM | tidak dihitung (field Form1) | `SetEcmParamsFromDb`, `ReadEmbeddedXml` |

`SetEcmParamsFromDb` mengisi field offset (`tpsh, rpmh, iaph, feul1..3, iap, ig1..4, limit1..7, o2, o2c, immo, mode0..4, bass, iacv, ect, iat, vss, mapp`, plus mask) — jadi identifikasi ECM langsung menentukan **layout map** yang akan diedit.

Pencarian: `TxtSearch_KeyDown`, `ShowECUList`, `HandleCategoryClick`, `LoadECUByDescription` → daftar ECU dapat difilter per seri.

## 4. Pesan status yang membentuk state machine identifikasi

```
SILAHKAN HUBUNGKAN ECM KE DAYA
Please Wait...
Keihin     → Please Turn OFF
Shindengen → Please Turn OFF - ON
ECM ID / ECM PART CODE / Star / Checksum
ID tidak valid
Unknown Part Code
Unknown !Please Restart ECM
BaseMap Tersedia :
```

Tidak ada status "ID cocok dengan database" eksplisit; kecocokan tampaknya disimpulkan dari terisinya part code + base map tersedia.

## 5. Yang belum terbukti

- Format byte ECM ID/part code di kabel **tidak diketahui**.
- Apakah `Extract14to25` benar area ID — **hipotesis**, bukan temuan.
- Apakah database 160 BIN benar-benar berisi 160 image utuh atau hanya nama + offset — aplikasi menyebut "Database : {0}" dan "BaseMap Tersedia", tetapi tanpa IL/resource dump isi tidak dapat dipastikan. (Resource `public_encrypted` ada; isinya belum didekripsi.)
- Pembacaan ID nyata: **NOT TESTED** (tidak ada ECU/adaptor).

## 6. Perbandingan singkat (bukti BE-11/RevCore)

RevCore sudah mengimplementasikan identifikasi K-Line Honda dan database 489 ECM / 163 profil. FLASHPRO menambahkan jalur EEPROM keyless dan cakupan multi-merek (Yamaha/Suzuki) di modul smartkey. Perbandingan lengkap ada di FASE IV.
