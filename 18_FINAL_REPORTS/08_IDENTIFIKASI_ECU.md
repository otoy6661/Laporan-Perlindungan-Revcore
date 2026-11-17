# 08 — IDENTIFIKASI ECU

**Work order:** BE-12
**Status:** SOURCE VERIFIED (struktur) · pembacaan ID nyata **BLOCKED**
**Sumber:** `05_ECU_IDENTIFICATION/ECU_IDENTIFICATION.md`, `DTC_CODES.csv`, `PART_CODES.csv`, `BIN_CATALOG.csv`

---

## 1. Keluarga ECU

Enum `ECUTYPE` (6 nilai + `value__`):

```
KEIHINOTHER, KEIHINH8C, KEIHINM32R,
SHINDENGENV850, SHINDENGENRH850, SHINDENGENRH850B
```

Dua vendor, tiga varian masing-masing. Ini bukan daftar kosmetik: jalur pra-tulis dan checksum berbeda per keluarga (`KeihinPreWriteFlash`/`ShindengenPreWriteFlash`, `KeihinAutoChecksum`/`ShindengenAutoChecksum`).

## 2. Dua jalur identifikasi

### A. K-Line (ECU hidup)

```
Form1.connececm → InitClass15Iso → SendCommand → GetEcuType
```

UI menampilkan **ECM ID**, **ECM PART CODE**, **Star**, **Checksum**. Kegagalan → `ID tidak valid`, `Unknown Part Code`.

`ReadECU.Read48` membaca blok **48 KB** dari MCU; `Extract14to25` mengambil byte ke-14..25 (kandidat area ID, **hipotesis** — tanpa capture tidak terbukti).

### B. EEPROM/keyless (SMK)

`READ ID KEYLESS` membaca EEPROM melalui I2C, lalu `ProcessKEIHIN`/`ProcessPcxValues` mengolahnya menjadi ID. Ada pemilihan model HONDA/KEIHIN/SHINDENGEN/YAMAHA/SUZUKI; output ke `C:\READ ID SMARTKEY\eeprom_{tipe}_scu_{id}_{timestamp}.bin`.

Artinya identifikasi tidak hanya dari handshake K-Line; untuk Honda keyless, aplikasi membaca memori kunci.

## 3. Database yang dibawa

| Artefak | Jumlah | Sumber |
|---|---:|---|
| Nama BIN `FLASHPRO.*.bin` | 160 | string `#US` → `BIN_CATALOG.csv` |
| Part code unik | 157 | string + `PART_CODES.csv` (333 baris dengan duplikat) |
| Seri kendaraan | 29 + `Other Series` | string UI |
| DTC | 37 | `DTC_CODES.csv` |
| Profil offset | field per ECM | `SetEcmParamsFromDb`, `ReadEmbeddedXml` |

`SetEcmParamsFromDb` mengisi `tpsh/rpmh/iaph/feul1..3/iap/ig1..4/limit1..7/o2/o2c/immo/mode0..4/bass/iacv/ect/iat/vss/mapp` + mask. Jadi identifikasi ECM langsung menentukan **layout map** yang diedit.

## 4. State machine identifikasi

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

## 5. DTC: temuan prototipe

Perbandingan otomatis (FASE VI) menunjukkan:

- FLASHPRO **37** baris vs RevCore **15** entri;
- **24** kode FLASHPRO tidak ada di RevCore;
- **2** kode RevCore tidak ada di FLASHPRO: `7-0` (P0115), `33-1` (P0605);
- dua baris CSV FLASHPRO berisi kode lain di kolom deskripsi (`25-3 → "29-1"`, `57-2 → "86-1"`) — **artefak ekstraksi**, bukan DTC sebenarnya;
- baris `21-1`/`23-1` memiliki karakter `O₂` rusak encoding.

Kesimpulan: angka 37 adalah **jumlah baris katalog**, bukan bukti 37 DTC valid. Jangan memindahkan semua 37 ke RevCore tanpa verifikasi manual servis.

## 6. Yang belum terbukti

- Format byte ECM ID/part code di kabel.
- Apakah `Extract14to25` benar area ID.
- Apakah database 160 BIN berisi 160 image utuh atau hanya nama + offset. Resource `public_encrypted` ada, isinya belum didekripsi.
- Pembacaan ID nyata: **NOT TESTED** (tidak ada ECU/adaptor).

## 7. Perbandingan singkat

RevCore memiliki `ecm_database.json` **489** ECM dan **163** profil VomConfig; FLASHPRO memiliki **160** nama BIN dan **157** part code. Keduanya Honda-specific; angka berbeda karena cakupan dan format penyimpanan, bukan karena salah satu mencakup merek lain. FLASHPRO menambahkan jalur EEPROM keyless dan multi-merek di smartkey; RevCore tidak memilikinya.
