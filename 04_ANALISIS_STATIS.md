# 04 — ANALISIS STATIS

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Cakupan:** `TunerPro.exe`, `XDFEditor.dll`, `ADXEditor.dll`, `ScannerProModule.dll`, `PromIO.dll`, `MoatesOnboardLogger.dll`, `TPChecksumPlugin.dll`, `TPMoatesEmulatorPlugin.dll`, dan `ELM327PlugIn.dll`
**Status:** SELESAI — analisis struktural (header PE, import/export, resource, string table). Tidak ada dekompilasi penuh; batas dinyatakan di §9.

---

## 1. Metode

| Langkah | Alat/cara | Keluaran |
|---|---|---|
| Parsing header PE | Skrip PowerShell `resources.ps1`, `summarize.ps1` | `PE_*.json` (section, data directory, import, export, resource) |
| Ekstraksi string | ASCII + UTF-16, minimum 4 karakter | `STRINGS_*.txt` (27.115 baris total) |
| Pemetaan resource | Resource directory walk | 90 resource EXE; menu/dialog/bitmap/WAV |
| Korelasi runtime | Snapshot modul, UIA dump, screenshot | `03_RUNTIME_ANALYSIS/*` |
| Verifikasi hash | SHA-256 per file | `APP_INVENTORY.csv` |

Tidak digunakan: disassembler interaktif, decompiler, atau eksekusi kode yang dipatch. Analisis perilaku dilakukan lewat observasi runtime terkontrol (laporan 05).

---

## 2. Provenance build

Seluruh modul inti memiliki timestamp build yang berurutan dalam rentang 33 detik pada 2026-10-15, menunjukkan satu batch build:

| Modul | Build (UTC) | Image base | Section | Entry RVA | Authenticode |
|---|---|---|---:|---:|---|
| `TunerPro.exe` | 02:21:43 | `0x00400000` | 5 | `0x13749` | Tidak ada |
| `XDFEditor.dll` | 02:21:35 | `0x10000000` | 5 | `0x0915C` | Tidak ada |
| `ADXEditor.dll` | 02:21:36 | `0x10000000` | 5 | `0x07762` | Tidak ada |
| `ScannerProModule.dll` | 02:21:31 | `0x10000000` | 5 | `0x08108` | Tidak ada |
| `PromIO.dll` | 02:21:14 | `0x10000000` | 5 | `0x0B938` | Tidak ada |
| `MoatesOnboardLogger.dll` | 02:21:26 | `0x10000000` | 5 | `0x09E1D` | Tidak ada |
| `TPChecksumPlugin.dll` | 02:21:03 | `0x10000000` | 5 | `0x01D16` | Tidak ada |
| `TPMoatesEmulatorPlugin.dll` | 02:21:05 | `0x10000000` | 5 | `0x0439C` | Tidak ada |

Semua PE32 x86, GUI subsystem, tanpa overlay, tanpa CLR. Semua modul internal memakai image base `0x10000000`, konsisten dengan DLL yang di-load pada alamat preferensial.

**Implikasi:** tidak ada modul pihak ketiga "asing" yang disisipkan belakangan ke folder aplikasi; seluruh DLL inti dibangun bersama. `ELM327PlugIn.dll` berbeda: bertimestamp file 2025-10-15 09:21 (lihat §6) dan berada di folder pengguna.

---

## 3. Struktur section `TunerPro.exe`

| Section | VA | Virtual size | Raw size | Flags | Entropy |
|---|---|---:|---:|---|---:|
| `.text` | `0x00001000` | 902.685 | 903.168 | `0x60000020` (code, execute, read) | 6,4548 |
| `.rdata` | `0x000DE000` | 96.896 | 97.280 | `0x40000040` (initialized data, read) | 5,2694 |
| `.data` | `0x000F6000` | 178.384 | 21.504 | `0xC0000040` (read/write) | 1,8724 |
| `.rsrc` | `0x00122000` | 248.472 | 248.832 | `0x40000040` | 5,7506 |
| `.reloc` | `0x0015F000` | 52.700 | 52.736 | `0x42000040` (discardable, read) | 6,8038 |

`.data` memiliki virtual size jauh lebih besar dari raw size (178.384 vs 21.504), khas buffer runtime statis berukuran besar (kemungkinan buffer BIN/emulasi). Tidak ada indikasi packer: entry point berada di `.text` normal dan import table terbaca penuh.

---

## 4. Matriks kapabilitas dari import table

| Kapabilitas | Bukti import | Modul |
|---|---|---|
| Serial port | `SetCommState`, `SetCommTimeouts`, `GetCommState`, `GetCommTimeouts`, `PurgeComm` | `TunerPro.exe` |
| File I/O | `CreateFileA`, `ReadFile`, `WriteFile`, `SetFilePointer` | `TunerPro.exe`, semua DLL |
| Jaringan HTTP | `InternetOpenA`, `InternetConnectA`, `HttpOpenRequestA`, `HttpSendRequestA`, `InternetReadFile` | `TunerPro.exe` |
| Audio | `PlaySoundA` | `TunerPro.exe` |
| Kriptografi | `CryptAcquireContextA`, `CryptImportKey`, `CryptDeriveKey`, `CryptEncrypt`, `CryptDecrypt`, `CryptHashData` | `TunerPro.exe`, `XDFEditor.dll`, `ADXEditor.dll` |
| Registry | `RegOpenKeyExA`, `RegQueryValueExA`, `RegSetValueExA` | `TunerPro.exe` |
| COM/RPC | `UuidToStringA`, `UuidFromStringA`, `CoCreateInstance` | `TunerPro.exe` |
| UI tingkat lanjut | Common Controls 6, UxTheme, RichEdit, GDI | EXE + editor DLL |
| Dialog file | `GetOpenFileNameA`, `GetSaveFileNameA` | EXE, editor DLL |

`ScannerProModule.dll` tidak mengimpor fungsi serial langsung; ia menerima data melalui antarmuka host. Ini konsisten dengan pembagian peran: **host memiliki port serial**, modul hanya mengelola tampilan dan definisi.

---

## 5. Permukaan export

| Modul | Jumlah export relevan | Inti |
|---|---:|---|
| `XDFEditor.dll` | 8 | Pembuatan editor properti, image list, bulk edit, property grid |
| `ADXEditor.dll` | 1 | `ADXEditorEntry` (entry tunggal, semua logika di baliknya) |
| `ScannerProModule.dll` | 25+ `SP*` | View, dash, histogram, monitor, update, ekspor, toolbar, cache |
| `PromIO.dll` | 1 | `StartPromUI` |
| `MoatesOnboardLogger.dll` | 1 | `StartMoatesOnboardLoggerUI` |
| `TPChecksumPlugin.dll` | 4 `MMCS*` + 1 `MMMH` | Hitung/info checksum, pesan error |
| `TPMoatesEmulatorPlugin.dll` | 2 | `TPCreatePlugin`, `TPReleasePlugin` |
| `ELM327PlugIn.dll` | 2 | `TPCreatePlugin`, `TPReleasePlugin` |

Tidak ada export yang mengekspos fungsi tulis ECU langsung. Operasi tulis berada di balik objek `MMAutoProm` (parameter `StartPromUI`) dan di balik antarmuka plug-in.

---

## 6. Katalog bukti string

String diekstrak dari image; kutipan di bawah adalah teks persis (bukan parafrase).

### 6.1 Serial & transport
- `MMSerial: Open Port %s Failed`, `MMSerial: Successfully opened %s`, `MMSerial: GetCommState Failed`, `MMSerial: SetCommState Failed`
- `MMSerial` (baud/read/write family)
- `MMAutoProm: Software data passthrough mode entry SUCCESS: %i baud`
- `MMAutoProm: Software data passthrough mode exit SUCCESS`
- `FAILURE: AutoProm passthrough requires send commands to be followed immediately by listenpacket commands`
- `Trace mode entered. Monitoring addresses %X -> %X`

### 6.2 Kode error perangkat
`AP_E_BAD_CHECKSUM`, `AP_E_EXTERNAL_CS_INVALID`, `AP_E_INTERNAL_CS_INVALID`, `AP_E_INVALID_FIRMWARE_IMAGE`, `AP_E_INVALID_HARDWARE_ID`, `AP_E_INVALID_VERSION`, `AP_E_TRIALS_EXPIRED` (dan famili `AP_E_*` lain).

### 6.3 Nama perangkat keras
`AutoProm`, `BoostedNW Burner`, `Flash & Burn`, `Ostrich II`, `Ostrich`, `RoadRunner`, `Quarterhorse`, `Superlogger`, `Demon2`, `FlashOnline`, `Destiny Programmer`, `F2E Ford EEC-IV/V Reader`, `29F010`, `29F020`, `29F040`, `2732A`, `27C010`, `27C128`, `27C256`, `27C512` (Read-Only).

### 6.4 Mode emulasi
`RoadRunner: Serial requested`, `RoadRunner: Setting Device Vendor ID`, `RoadRunner: Setting Device Serial`, `RoadRunner: Set Emulation Mode Succeeded: Mode %c`, `RoadRunner I/O request address/size alignment error`, `Quarterhorse`.

### 6.5 Operasi chip (PromIO)
`Hardware does not support burning!`, `ERROR: Chip start address must be divisible by 64`, `ERROR: Chip memory range must be divisible by 64`, `ERROR: Source memory range should be divisible by 64`, plus operasi erase/bank erase, blank check, program, read, verify.

### 6.6 Logger onboard (MoatesOnboardLogger)
Sesi dari dump flash, memori terpakai %, nomor sesi, `Export Session To XDL`, `Erase Onboard Memory`, `Begin Logging on Powerup`, `Headless Logging`, `Output Log Path`; syarat ADX harus memiliki perintah loggable dengan ukuran paket cocok.

### 6.7 Skema XDF (XDFEditor)
Token: `XDFFORMAT`, `XDFHEADER`, `BASEOFFSET`, `REGION`, `CATEGORY`, `XDFTABLE`, `XDFAXIS`, `XDFCONSTANT`, `XDFFLAG`, `XDFFUNCTION`, `XDFPATCH`, `XDFCHECKSUM`, `EMBEDDEDDATA`, `MATH`, `mmedaddress`, `mmedelementsizebits`, `mmedmajorstridebits`, `mmedminorstridebits`, `mmedrowcount`, `mmedcolcount`, `mmedtypeflags`; label UI `Open Password`, `Edit Password`, `Encrypt File`, `Checksum`.

### 6.8 Skema ADX (ADXEditor)
Token: `ADXFORMAT`, `ADXHEADER`, `ADXVALUE`, `ADXBITMASK`, `ADXLOOKUPTABLE`, `ADXLISTVIEW`, `ADXMONITOR`, `ADXDASHBOARD`, `ADXHISTOGRAM`, `ADXCLISTENPACKET`, `ADXCSENDCOMMAND`, `ADXCLISTENSILENCE`, `ADXCLISTEN160BAUD`, `ADXCTRIGGER`, `ADXMACRO`; field `packetoffset`, `packetoffsetinbody`, `packetbodylength`, `headerstring`, `footerstring`, `packetsize`, `listentimeout`, `silencelen`, `baud`, `parity`, `stopbits`, `monitorcmd`, `unpausecmd`, `SNDCMDCHECKSUM`, `lookupmode`, `lookupidhash`, `triggertype`.

### 6.9 Plug-in ELM327
`ELM327 OBDII Parser Plug-in`, `ELM327 OBDII Interface Driver Component`, `ELM327: Request for Mode %i PID %.4X succeeded`, `...failed`, `ELM327PlugIn.dat`, `COM%i`, `\\.\COM%u`, `MMSerial` baud.

### 6.10 Pembaruan & registrasi
`Check Internet For Updates...`, `Check For Updates`; string registrasi menyatakan versi unregistered tetap "fully functional" dan "never expires".

---

## 7. Resource, menu, dan command ID

- **Menu:** 10 resource (`136`, `210`, `288`, `289`, `2951`, `3109`, `3111`, `3112`, `3118`, `3128`).
- **Dialog:** ±40 resource, termasuk Preferences, About, dialog error, dan editor.
- **Bitmap:** `245` (141.862 B) dan `3097` (28.456 B).
- **Command ID yang terverifikasi dari dump menu runtime:**

| ID | Aksi |
|---:|---|
| 32773 | Open Bin |
| 32774 | Save Bin |
| 32775 | Save Bin As |
| 32776 | Select XDF |
| 32787 | Save XDF |
| 32788 | Save XDF As |
| 32778 | Preferences |
| 32854 | Initialize Hardware |
| 32897 | Emulation Upload |
| 32899 | Verify |
| 32900 | Live Tuning |
| 32904 | Download |
| 32991 | System Check |
| 33052 | Open ADX |
| 33104 | Release Hardware |
| 33127 | About Plug-ins |

Pemetaan ini berasal dari dump menu runtime (`menu_tree.txt`), bukan dari asumsi urutan resource.

---

## 8. Inferensi arsitektur dari bukti statis

1. **Host-centric I/O.** Hanya `TunerPro.exe` yang mengimpor API serial. Semua modul lain menerima data melalui parameter/host. Ini menjelaskan mengapa `ScannerProModule` dapat dipakai untuk Live Monitor tanpa mengetahui port.
2. **Plug-in checksum terpisah dari plug-in hardware.** `TPChecksumPlugin` memakai kontrak `MMCS*` (dipanggil juga oleh `XDFEditor.dll`), sedangkan plug-in hardware memakai `TPCreatePlugin`/`TPReleasePlugin`. Dua ekosistem plug-in berbeda.
3. **Dua jalur tulis berbeda.** `PromIO`/`MMAutoProm` adalah jalur chip/emulator (buffer ↔ perangkat), bukan flash ECU. Tidak ada API flashing ECU Honda di executable.
4. **Definisi data-driven.** XDF/ADX adalah container yang mendeskripsikan alamat, skala, checksum, dan paket. Aplikasi tidak "tahu" Honda secara khusus; pengetahuan ada di file definisi.
5. **Enkripsi container adalah fitur produk.** CryptoAPI diimpor oleh editor dan host; XDF/ADX dapat dienkripsi dengan password. Ini bukan proteksi bajakan, melainkan fitur distribusi definisi.

---

## 9. Batas analisis statis

- Tidak ada disassembly instruksi per fungsi; hubungan sebab-akibat internal (mis. urutan inisialisasi checksum) disimpulkan dari export/import/string dan diverifikasi lewat runtime.
- `TunerProPu.dat` (152 B) tidak diuraikan isinya.
- `unins001.exe`/`unins001.dat` hanya dicatat sebagai komponen installer/uninstaller; tidak dijalankan.
- Tidak ada klaim tentang algoritma internal yang tidak memiliki bukti string/observasi.
- String dapat berasal dari kode yang tidak pernah dieksekusi; status "ada di binary" tidak sama dengan "aktif". Setiap fitur yang diklaim aktif memiliki bukti runtime terpisah (laporan 05).

---

## 10. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Header, section, import, export, resource | TINGGI (parsing langsung) |
| Provenance build | TINGGI (timestamp PE) |
| Kapabilitas per modul | TINGGI untuk import; SEDANG untuk perilaku |
| Pemetaan command ID | TINGGI (dump runtime) |
| Interpretasi arsitektur | SEDANG (inferensi konsisten, bukan dekompilasi) |
