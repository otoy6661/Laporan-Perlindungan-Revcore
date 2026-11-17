# Arsitektur Aplikasi — FLASHPRO (Windows)

**Status keseluruhan:** SOURCE VERIFIED (metadata .NET diekstrak dari proses hidup) + RUNTIME VERIFIED (startup/dialog) — bukan hasil dekompilasi penuh.
**Sumber bukti:** `12_EXPERIMENTS/E01_FIRST_LAUNCH/OBSERVATION/CLR_DUMP/` (metadata 235.832 B, SHA-256 di `02_STATIC_ANALYSIS/METADATA_EXTRACTION.md`), `03_RUNTIME_ANALYSIS/E01_FIRST_LAUNCH/`, `01_APPLICATION_ANATOMY/*.tsv`.

---

## 1. Bentuk sebenarnya

FLASHPRO yang terpasang **bukan satu executable tunggal**. Tiga EXE di folder instalasi adalah *wrapper* VB6 (122.880 B) yang membawa payload asli di belakangnya:

| Lapisan | Isi | Status |
|---|---|---|
| Wrapper | PE32 x86, 3 seksi, VB6 (`MSVBVM60.DLL`), manifest `requireAdministrator`, VERSIONINFO `Project1`/`TJprojMain.exe` | STATIC VERIFIED |
| Payload | PE32+ x64 33.321.984 B, 5 seksi RWX ber-entropy ~8, Enigma Protector 5.x | STATIC VERIFIED |
| Isi payload | **.NET Framework 4.8 WinForms, assembly `FLASHPRO` v0.0.1.6** | RUNTIME VERIFIED (metadata) |

Payload terpasang **byte-identik** dengan `{app}\FLASHPRO.exe` dari installer (SHA-256 `9fafdc8e…`), sehingga aplikasi yang dianalisis adalah build vendor, bukan hasil patch.

## 2. Peta tipe (bukti: `TYPE_MAP.tsv`)

| Tipe | Metode | Field | Peran |
|---|---:|---:|---|
| `FLASHPRO.Form1` | 292 | 334 | Dashboard utama: tabel map, live gauge, flash, ECU database |
| `FLASHPRO.Form11` | 89 | 60 | Smartkey/EEPROM: I2C bit-bang, read/write/copy SCU |
| `FLASHPRO.Diag` | 51 | 45 | Diagnostik: DTC, live data mentah, reset ECM |
| `FLASHPRO.SMK` | 49 | 42 | Read ID keyless Honda + Keihin/Shindengen EEPROM |
| `FLASHPRO.DYNO` | 30 | 26 | Perhitungan HP/TQ dari data live |
| `FLASHPRO.ReadECU` | 17 | 11 | Baca 48 KB dari MCU (`Read48`), log frame |
| `FLASHPRO.Reset` | 18 | 9 | Reset flash count / recovery |
| `FLASHPRO.ChartLiveMap` | 42 | 60 | Chart live RPM/TPS/AD/AFR |
| `FLASHPRO.LicenseForm` | 35 | 21 | Aktivasi berbasis HWID + RSA |
| `FLASHPRO.MbAuth` | 7 | 4 | Kunci lisensi dari serial motherboard |
| `FLASHPRO.UpdaterClient` | 15 | 6 | Update via JSON GitHub + ZIP |
| `FLASHPRO.Class15` | 12 | 0 | Pembungkus D2XX mode UART/ISO |
| `FLASHPRO.Class155` | 9 | 3 | Pembungkus D2XX mode bit-bang |
| AGauge, Plot3D | — | — | Gauge & grafik 3D pihak ketiga |

Tipe domain lain: `ECUTYPE` (KEIHINOTHER, KEIHINH8C, KEIHINM32R, SHINDENGENV850, SHINDENGENRH850/RH850B), `EepromType` (AT24C02/AT24C04), `UpdateResult`, `STATUS`.

## 3. Dependensi eksternal (bukti: `PINVOKE.tsv`, `TYPEREFS.txt`)

- **`ftd2xx.dll`** (FTDI D2XX, 12 fungsi) — satu-satunya jalur I/O perangkat.
- `user32/gdi32` — efek UI (layered window, rounded region).
- .NET: `System.Management` (WMI), `System.Net.Http` (update), `System.Security.Cryptography` (AES/RSA/SHA256/DPAPI), `Microsoft.Win32.Registry`.
- `Ionic.Zip` 1.16 (DotNetZip) — paket update berpassword.
- `Microsoft.CSharp.CSharpCodeProvider` — kompilasi ekspresi matematika pengguna menjadi C# saat runtime (kelas `Eval`); fitur "Function" pada editor map.
- **Tidak ada** `System.IO.Ports`, tidak ada socket selain HTTP update, tidak ada CAN/ELM327.

## 4. Model data inti (Form1)

Field yang terbaca dari metadata (bukti: `FIELDS.tsv`):

- `byte[] binBytes`, `byte[] binBytesORI` — buffer kerja + salinan asli; `Stack<byte[]> undoStack/redoStack`.
- Offset per seksi: `tpsh, rpmh, iaph, feul1..3, iap, ig1..4, limit1..7` (Int32) — **sama dengan skema `VomConfig` FLASHPRO Android** yang sudah dipetakan RevCore (`flashpro_profiles.json`).
- Switch biner: `o2/o2mask, o2c/o2cmask, immo/immomask, mode0..4, bass, iacv, ect, iat, vss, mapp` + mask.
- `konversrpm`, `konversilmtr` (Single) — faktor konversi sumbu.
- `ftHandle` (IntPtr), `selectedStartAddress`, `startAddress/2/3`, `columnCount/rowCount`, `minValue/maxValue`.

## 5. Penyimpanan & konfigurasi

| Lokasi | Isi | Status |
|---|---|---|
| `HKCU\Software\Win32Sub\SystemCtrl` (`SysCFG`) | konfigurasi/lisensi | SOURCE VERIFIED (string) |
| `HKCU\Software\Win32Sub\SystemApp` | data akun/nama bengkel | SOURCE VERIFIED (string) |
| `HKCU\SOFTWARE\SHINDENGEN & KEIHIN HONDA ECM` | nilai biner `Key` 180 B, entropy 6,97 — blob terenkripsi | RUNTIME VERIFIED (dibaca), **SENSITIVE_OR_RESTRICTED** |
| `lastimage.txt` (folder app) | path gambar background terakhir | RUNTIME VERIFIED |
| `version.txt`, `staging/`, `update.zip` | mekanisme updater | SOURCE VERIFIED (string) |
| `C:\READ ID SMARTKEY\` | dump EEPROM hasil fitur smartkey | SOURCE VERIFIED (string) |
| `read48k.log` | log pembacaan 48 KB | SOURCE VERIFIED (nama file) |

## 6. Alur startup (RUNTIME VERIFIED)

1. Proses dimuat (67 modul; CLR 4.8, WinForms, WMI, GDI+).
2. Sebelum UI utama: **gerbang aktivasi** `MbActivationForm` — jendela 460×400 "ECM MANAGER - Activation / TEAM TECH TUNNER" (screenshot `03_RUNTIME_ANALYSIS/E01_FIRST_LAUNCH/E01_WINDOW.png`).
3. Tombol Cancel → proses keluar (exit code tidak direkam). Tanpa aktivasi, Form1 tidak pernah dimuat.
4. Tidak ada koneksi TCP saat dialog (pemeriksaan `Get-NetTCPConnection` kosong); tidak ada file konfigurasi baru di folder app/TEMP.

## 7. Batas analisis

- Kode IL **tidak dapat diambil**: `ClrMethod.GetILInfo()` mengembalikan null untuk assembly ini (Enigma). Lihat `02_STATIC_ANALYSIS/METADATA_EXTRACTION.md`.
- Semua perilaku ECU di balik aktivasi berstatus **BLOCKED (lisensi)** — bukan karena alat, tetapi karena gerbang lisensi yang tidak boleh dilewati.
- Wrapper tidak dijalankan (butuh elevasi/UAC) → **NOT TESTED**.
