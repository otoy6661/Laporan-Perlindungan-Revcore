# 03 — ARSITEKTUR APLIKASI

**Work order:** BE-12
**Status:** SOURCE VERIFIED (metadata) + RUNTIME VERIFIED (startup) · algoritma **NOT VERIFIED**
**Sumber:** `01_APPLICATION_ANATOMY/ARCHITECTURE.md`, `TYPE_MAP.tsv`, `FIELDS.tsv`, `PINVOKE.tsv`

---

## 1. Tiga lapisan

| Lapisan | Teknologi | Fungsi | Status |
|---|---|---|---|
| Wrapper | VB6 x86, `TJprojMain` | ekstrak/jalankan payload, minta elevasi | STATIC VERIFIED |
| Payload | x64, Enigma Protector 5.x | melindungi metadata/IL | STATIC VERIFIED |
| Aplikasi | .NET Framework 4.8 WinForms | seluruh logika ECU/UI | RUNTIME VERIFIED (metadata) |

## 2. Peta tipe utama

| Tipe | Metode | Field | Peran |
|---|---:|---:|---|
| `Form1` | 292 | 334 | dashboard, map, flash, database ECU |
| `Form11` | 89 | 60 | smartkey/EEPROM I2C |
| `Diag` | 51 | 45 | DTC, live data, reset ECM |
| `SMK` | 49 | 42 | read ID keyless + EEPROM |
| `ChartLiveMap` | 42 | 60 | chart RPM/TPS/AD/AFR |
| `DYNO` | 30 | 26 | perhitungan HP/TQ |
| `ReadECU` | 17 | 11 | baca 48 KB |
| `Reset` | 18 | 9 | reset flash count/recovery |
| `LicenseForm` | 35 | 21 | aktivasi HWID + RSA |
| `MbAuth` | 7 | 4 | kunci dari serial motherboard |
| `UpdaterClient` | 15 | 6 | update GitHub + ZIP |
| `Class15` | 12 | 0 | D2XX UART/ISO |
| `Class155` | 9 | 3 | D2XX bit-bang |

Total metadata: **168 tipe, 1.442 baris metode, 1.429 field, 2.082 string**.

## 3. Dependensi

| Dependensi | Bukti | Implikasi |
|---|---|---|
| `ftd2xx.dll` (12 fungsi) | P/Invoke | satu-satunya I/O perangkat |
| `System.Management` (WMI) | typeref + modul runtime | HWID & deteksi motherboard |
| `System.Net.Http` | typeref | hanya untuk updater |
| `System.Security.Cryptography` | typeref | AES/RSA/SHA256/DPAPI |
| `Microsoft.Win32.Registry` | typeref | konfigurasi & lisensi |
| `Ionic.Zip` 1.16 | assembly terpisah | paket update berpassword |
| `CSharpCodeProvider` | typeref | kompilasi ekspresi `Eval` runtime |

**Tidak ada:** `System.IO.Ports`, socket selain HTTP update, CAN/ELM327/J2534/UDS.

## 4. Model data Form1

```text
byte[] binBytes, binBytesORI
Stack<byte[]> undoStack, redoStack
int tpsh, rpmh, iaph, feul1..3, iap, ig1..4, limit1..7
byte/flag o2, o2mask, o2c, o2cmask, immo, immomask, mode0..4, bass, iacv, ect, iat, vss, mapp
Single konversrpm, konversilmtr
IntPtr ftHandle
int selectedStartAddress, startAddress/2/3, columnCount, rowCount
```

Skema ini **identik** dengan `VomConfig` yang sudah dipetakan RevCore (`flashpro_profiles.json`), meskipun format simpan dan UI berbeda.

## 5. Penyimpanan

| Lokasi | Isi | Status |
|---|---|---|
| `HKCU\Software\Win32Sub\SystemCtrl` | konfigurasi/lisensi (`SysCFG`) | SOURCE VERIFIED |
| `HKCU\Software\Win32Sub\SystemApp` | akun/nama bengkel | SOURCE VERIFIED |
| `HKCU\SOFTWARE\SHINDENGEN & KEIHIN HONDA ECM` | blob `Key` 180 B | SENSITIVE_OR_RESTRICTED |
| `lastimage.txt` | path background | RUNTIME VERIFIED |
| `version.txt`, `staging/`, `update.zip` | updater | SOURCE VERIFIED |
| `C:\READ ID SMARTKEY\` | dump EEPROM | SOURCE VERIFIED |

## 6. Alur startup

```text
Wrapper VB6 → payload (Enigma) → Splash/disclaimer
  → MbActivationForm (460×400)
      → Cancel = keluar
      → Activate = LicenseForm/Form1 (tidak diuji)
```

E01 membuktikan: 67 modul dimuat, CLR 4.8, WMI aktif, **tidak ada koneksi TCP** saat gerbang, dan Cancel keluar tanpa menulis file.

## 7. Konsekuensi arsitektural

1. **Pengetahuan ECU ada di kode**, bukan di definisi eksternal seperti ADX/XDF TunerPro. Menambah ECU = update aplikasi.
2. **Satu transport untuk dua mode** (UART K-Line dan bit-bang I2C) → adaptor yang sama melayani ECU dan smartkey.
3. **Semua operasi berisiko berada di balik lisensi**; tanpa lisensi, tidak ada satu pun jalur ECU yang dapat diuji.
4. **Metadata terbuka, algoritma tertutup**: cukup untuk memetakan permukaan, tidak cukup untuk mengklaim perilaku.

## 8. Batas

IL tidak dapat diambil (`GetILInfo` null) → semua algoritma berstatus **NOT VERIFIED**. Tipe yang tidak dimuat sebelum gerbang aktivasi tetap ada di tabel metadata, tetapi nilai runtime-nya belum tentu terisi.
