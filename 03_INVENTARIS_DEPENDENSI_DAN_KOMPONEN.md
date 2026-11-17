# 03 — INVENTARIS DEPENDENSI & KOMPONEN

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Tanggal analisis:** 2026-11-17 s/d 2026-11-18
**Status:** SELESAI — seluruh angka pada dokumen ini berasal dari file nyata, hash nyata, dan observasi runtime nyata. Tidak ada komponen yang diklaim ada tanpa bukti.

---

## 1. Identitas paket yang diperiksa

| Item | Nilai | Bukti |
|---|---|---|
| Nama produk | TunerPro RT | FileVersion `5, 0, 10335, 0` |
| Vendor | Creational Technologies, LLC | String versi PE |
| Executable | `TunerPro.exe` | 1.324.544 B |
| SHA-256 EXE | `fe089b04083f0af38ea50c5d22731fcb86bbe04e1060cdf3f578c9ca2a3066f9` | `00_SOURCE_INVENTORY/APP_INVENTORY.csv` |
| Arsitektur | x86 (PE32), bukan PE32+ | `Machine = 0x014C`, `PE32Plus = false` |
| Build timestamp | 2026-10-15 02:21:43 UTC | `TimeDateStamp = 1792030903` |
| Subsystem | GUI | `0x0002` |
| Image base | `0x00400000` | PE optional header |
| Entry point | RVA `0x00013749` | PE optional header |
| Jumlah section | 5 (`.text`, `.rdata`, `.data`, `.rsrc`, `.reloc`) | PE section table |
| Overlay | 0 byte | `OverlayBytes = 0` |
| Authenticode | **Tidak ada** (directory index 4, offset 0, size 0) | `AuthenticodeDir` |
| CLR / .NET | Tidak (native) | `HasCLR = false` |
| Lokasi instalasi | `C:\Program Files (x86)\TunerPro RT` | `ENVIRONMENT.txt` |
| Lokasi data pengguna | `%USERPROFILE%\Documents\TunerPro Files` | Observasi + `TPSPMSettings.dat` |

Entropy section: `.text` 6,4548; `.rdata` 5,2694; `.data` 1,8724; `.rsrc` 5,7506; `.reloc` 6,8038. Tidak ada section dengan entropy mendekati 8,0, sehingga tidak ada indikasi packer/kompresi penuh pada executable utama.

---

## 2. Inventaris file instalasi (24 entri, hash terverifikasi)

Seluruh baris di bawah diambil dari `00_SOURCE_INVENTORY/APP_INVENTORY.csv`. Kolom "Peran" adalah hasil pembacaan PE (import/export), string, dan observasi runtime — bukan asumsi dari nama file.

| File | Ukuran (B) | SHA-256 (awalan) | Peran terbukti |
|---|---:|---|---|
| `TunerPro.exe` | 1.324.544 | `fe089b04…` | Aplikasi utama; host UI, XDF/ADX orchestration, emulator & hardware glue |
| `XDFEditor.dll` | 571.392 | `0eeab655…` | Editor definisi XDF; 8 export `CreateXDF*`, `XDFShowBulkEditUI`, `PopulatePropertyGrid`; mengimpor MMCS* (checksum) |
| `ADXEditor.dll` | 551.936 | `f9e52d05…` | Editor ADX; satu export `ADXEditorEntry` (mangled C++) |
| `ScannerProModule.dll` | 498.688 | `098fbea6…` | Modul datalogging/Live Monitor; export `SPCreateViewWindow`, `SPCreateDashWindow`, `SPCreateHistoWindow`, `SPSetDefinition`, `SPUpdate*`, `SPExportDataLog`, `SPMonitors*` |
| `PromIO.dll` | 348.160 | `cec9a5f0…` | UI operasi chip PROM/EEPROM; export tunggal `StartPromUI`; FileVersion `1, 0, 4369, 1`, ProductName "Moatesware Prom IO Library" |
| `MoatesOnboardLogger.dll` | 442.880 | `8e722231…` | UI logger onboard Moates; export tunggal `StartMoatesOnboardLoggerUI` |
| `TPChecksumPlugin.dll` | 19.968 | `91a5b71e…` | Plug-in checksum; export `MMCSCalculateChecksum`, `MMCSGetChecksumInfo`, `MMCSGetChecksumPluginInfo`, `MMCSGetLastErrorMessage`, `MMMH`; string "TunerPro Default Checksum Plug-in", "SUM1.0" |
| `TPMoatesEmulatorPlugin.dll` | 73.728 | `5124c169…` | Plug-in antarmuka hardware emulator; export `TPCreatePlugin`/`TPReleasePlugin`; ProductName "Emulation Device Plugin for TunerPro", vendor "RusnaMark Software" |
| `TunerProHelp.chm` | 878.198 | `16b92612…` | Bantuan terkompilasi (CHM) |
| `TunerProPu.dat` | 152 | `2dbe46a6…` | Data pembaruan/patch kecil (isi tidak diuraikan) |
| `Sounds/emudls.wav` | 3.202 | `38625743…` | Umpan balik audio unduh emulasi |
| `Sounds/emuuls.wav` | 3.202 | `a71a7bbd…` | Umpan balik audio unggah emulasi |
| `Sounds/emuupdf.wav` | 8.228 | `9998f146…` | Umpan balik audio unggah gagal |
| `Sounds/emuupds.wav` | 3.188 | `7bb00a24…` | Umpan balik audio unggah sukses |
| `Sounds/hwconnect.wav` | 2.728 | `876965a6…` | Umpan balik audio koneksi hardware |
| `Sounds/verifyf.wav` | 4.062 | `9ad618d8…` | Umpan balik audio verifikasi gagal |
| `Sounds/verifys.wav` | 3.476 | `25291d0e…` | Umpan balik audio verifikasi sukses |
| `msvcp100.dll` | 421.200 | `a3ba6421…` | Runtime MSVC 2010 (x86) |
| `msvcr100.dll` | 770.384 | `1221a094…` | Runtime MSVC 2010 (x86) |
| `msvcp120.dll` | 455.328 | `87c42ca1…` | Runtime MSVC 2013 (x86) |
| `msvcr120.dll` | 970.912 | `86e39b59…` | Runtime MSVC 2013 (x86) |
| `vcredist_x86.exe` | 13.853.648 | `510fc8c2…` | Installer redistributable VC++ 2015–2022 (14.38.33135) |
| `unins001.exe` | 4.401.394 | `0e1617f3…` | Uninstaller Inno Setup (51.1055.0.0) |
| `unins001.dat` | 6.218 | `66d488d7…` | Data uninstaller |

**Catatan penting:** empat DLL runtime (`msvcp100/msvcr100/msvcp120/msvcr120`) adalah runtime lama yang dibundel lokal. Pada sistem uji, `MSVCP140.dll`/`VCRUNTIME140.dll` dimuat dari `System32` (lihat §5), bukan dari folder aplikasi — artinya aplikasi bergantung pada redistributable 2015–2022 yang terpasang di sistem.

---

## 3. Pohon dependensi executable (`TunerPro.exe`)

### 3.1 DLL yang diimpor (27 entri import table)

| Kelompok | DLL | Fungsi yang relevan (contoh terbukti) |
|---|---|---|
| UI / shell | `COMCTL32.dll`, `UxTheme.dll`, `SHLWAPI.dll`, `SHELL32.dll`, `USER32.dll`, `GDI32.dll`, `COMDLG32.dll` | Kontrol umum, tema, dialog file, clipboard |
| I/O & serial | `KERNEL32.dll` | `CreateFileA`, `ReadFile`, `WriteFile`, `SetCommState`, `SetCommTimeouts`, `GetCommState`, `GetCommTimeouts`, `PurgeComm` |
| Jaringan | `WININET.dll` | `InternetOpenA`, `InternetConnectA`, `HttpOpenRequestA`, `HttpSendRequestA`, `InternetReadFile` |
| Audio | `WINMM.dll` | `PlaySoundA` |
| Kriptografi / registry | `ADVAPI32.dll` | `CryptAcquireContextA`, `CryptImportKey`, `CryptDeriveKey`, `CryptEncrypt`, `CryptDecrypt`, `CryptHashData`, registry API |
| COM / RPC | `ole32.dll`, `RPCRT4.dll` | `UuidToStringA`, `UuidFromStringA` (ID plug-in/checksum) |
| Internal aplikasi | `ScannerProModule.dll`, `XDFEditor.dll` | Modul datalogging & editor XDF dimuat statis |
| Runtime C++ | `MSVCP140.dll`, `VCRUNTIME140.dll` | Runtime MSVC 2015+ |
| CRT API-set | `api-ms-win-crt-{stdio,convert,string,runtime,utility,math,heap,multibyte,locale}-l1-1-0.dll` | CRT universal |
| Versi | `VERSION.dll` | Info versi file |

### 3.2 DLL yang dimuat dinamis (tidak ada di import table)

`PromIO.dll`, `MoatesOnboardLogger.dll`, `ADXEditor.dll`, `TPMoatesEmulatorPlugin.dll`, `TPChecksumPlugin.dll`, dan `ELM327PlugIn.dll` **tidak** tercantum di import table `TunerPro.exe`. Keenamnya muncul di daftar modul proses saat runtime (lihat §5), sehingga dimuat melalui `LoadLibrary`/`LoadLibraryEx` pada waktu yang ditentukan aplikasi — bukan linked statically.

### 3.3 Ketergantungan platform (System32)

Dari snapshot 55 modul: `ntdll`, `KERNEL32`, `KERNELBASE`, `SHLWAPI`, `msvcrt`, `USER32`, `win32u`, `GDI32`, `gdi32full`, `msvcp_win`, `ucrtbase`, `COMDLG32`, `combase`, `RPCRT4`, `shcore`, `SHELL32`, `wintypes`, `ADVAPI32`, `sechost`, `bcrypt`, `bcryptPrimitives`, `ole32`, `COMCTL32` (WinSxS 6.0.22621.6060), `WININET`, `WINMM`, `UxTheme`, `VERSION`, `MSVCP140`, `VCRUNTIME140`, `IMM32`, `windows.storage`, `kernel.appcore`, `RICHED20`, `USP10`, `msls31`, `MSCTF`, `TextShaping`, `textinputframework`, `OLEAUT32`, `CoreMessaging`, `CoreUIComponents`, `CRYPTBASE`, `CRYPTSP`, `rsaenh`, `USERENV`, `profapi`.

Implikasi: aplikasi native x86 dengan UI Win32/Common Controls 6, rich edit, dan COM. Tidak ada dependensi .NET, Java, Python, atau Electron.

---

## 4. Modul internal: kontrak antarmuka

### 4.1 `XDFEditor.dll`
Export (8): `CreateXDFImageList`, `XDFObjectTypeToImageIndex`, `XDFShowBulkEditUI`, `XDFBulkEditItems`, `XDFEditorGetImageIndexByID`, `CreateXDFObjectEditor`, `CreateXDFPropertyGrid`, `PopulatePropertyGrid`. Import MMCS* menunjukkan editor XDF dapat memanggil API checksum plug-in secara langsung (bukan hanya lewat EXE).

### 4.2 `ADXEditor.dll`
Satu export C++ termangled:
`?ADXEditorEntry@@YAHPAUHWND__@@PADPAEIPAUADXE_SDEEPLINK@@PAVMMDebugOutput@@K@Z`
Parameter yang terbaca dari dekorasi: `HWND`, `char*`, `unsigned char*`, `unsigned int`, `ADXE_SDEEPLINK*`, `MMDebugOutput*`, `unsigned long`. Artinya editor ADX menerima buffer/handle dari host dan memakai kanal debug milik host.

### 4.3 `ScannerProModule.dll`
Export mencakup pembuatan view (`SPCreateViewWindow`, `SPCreateDashWindow`, `SPCreateHistoWindow`, `SPCreateMonitorView`), pembaruan (`SPUpdateView`, `SPUpdateDash`, `SPUpdateHistogramData`, `SPMonitorsUpdate`), definisi (`SPSetDefinition`), ekspor (`SPExportDataLog`), cache (`SPMonitorsPopulateDataFromCache`), notifikasi (`SPDashSetNotificationHandler`), dan toolbar (`SPCreateCmdSenderToolbar`, `SPCreateLogToolbar`). Ini adalah mesin Live Monitor; host hanya menyediakan definisi ADX dan jendela induk.

### 4.4 `PromIO.dll`
Export tunggal `?StartPromUI@@YAHPAUHWND__@@PAUPROMIOLAYOUT@@PAVMMAutoProm@@PADPAVMMDebugOutput@@K@Z` — menerima `HWND`, `PROMIOLAYOUT*`, `MMAutoProm*`, `char*`, `MMDebugOutput*`. Bergantung pada objek `MMAutoProm` milik host, jadi bukan program mandiri.

### 4.5 `MoatesOnboardLogger.dll`
Export tunggal `?StartMoatesOnboardLoggerUI@@YAHPAUHWND__@@PAVMMAutoProm@@PADPAUMOL_EXPORT_SETTINGS@@K@Z` — juga memakai `MMAutoProm*` host.

### 4.6 Plug-in (`TPCreatePlugin`/`TPReleasePlugin`)
`TPMoatesEmulatorPlugin.dll` dan `ELM327PlugIn.dll` memakai kontrak plug-in generik yang sama. `TPChecksumPlugin.dll` memakai kontrak berbeda (MMCS*), sehingga tidak muncul di daftar "About Plug-ins" (terbukti: dialog About Plug-ins hanya menampilkan TPMoatesEmulatorPlugin 1.0.0 dan ELM327PlugIn 0.6.0).

---

## 5. Urutan pemuatan modul (runtime, terbukti)

Dari `03_RUNTIME_ANALYSIS/modules_full.txt` (55 modul, sesi dengan BIN + XDF + ADX terbuka):

1. `TunerPro.exe`
2. CRT/OS inti: `ntdll`, `KERNEL32`, `KERNELBASE`, `SHLWAPI`, `msvcrt`, `USER32`, `win32u`, `GDI32`, `gdi32full`, `msvcp_win`, `ucrtbase`, `COMDLG32`, `combase`, `RPCRT4`, `shcore`, `SHELL32`, `wintypes`, `ADVAPI32`, `sechost`, `bcrypt`, `ole32`
3. `COMCTL32` (WinSxS), `WININET`, `WINMM`
4. `ScannerProModule.dll` — dimuat sangat awal (sebelum tema/editor)
5. `UxTheme`, `XDFEditor`, `VERSION`, `MSVCP140`, `VCRUNTIME140`, `IMM32`, `windows.storage`, `kernel.appcore`, `bcryptPrimitives`, `RICHED20`, `USP10`, `msls31`
6. `PromIO.dll`, `MoatesOnboardLogger.dll`, `ADXEditor.dll` — dimuat berurutan saat fitur terkait disiapkan
7. `MSCTF`, `TextShaping`, `textinputframework`, `OLEAUT32`, `CoreMessaging`, `CoreUIComponents`, `CRYPTBASE`
8. `TPMoatesEmulatorPlugin.dll` (dari folder aplikasi), `ELM327PlugIn.dll` (dari `Documents\TunerPro Files\Plugins`), `CRYPTSP`, `rsaenh`, `USERENV`, `profapi`
9. `TPChecksumPlugin.dll` — dimuat paling akhir pada snapshot 55 modul

**Ablation checksum:** dengan `TPChecksumPlugin.dll` dipindahkan sementara, proses berjalan dengan **54 modul**, aplikasi tetap start, dan file dipulihkan (`RESTORED=True`). Tidak ada crash. Ini membuktikan plug-in checksum adalah komponen opsional saat startup, meski kehadirannya memengaruhi operasi checksum XDF tertentu (lihat laporan 07 dan 12).

### 5.1 Lokasi penemuan plug-in (terbukti)
- Folder aplikasi: `TPMoatesEmulatorPlugin.dll`, `TPChecksumPlugin.dll`.
- Folder pengguna: `C:\Users\<user>\Documents\TunerPro Files\Plugins\ELM327PlugIn.dll` (hanya file ini + `Readme.txt` 81 B).
- Folder pengguna lain yang ada tetapi kosong/tidak memuat DLL: `Bin Definitions`, `Bins`, `DataStreams`, `Layouts`.

Urutan pencarian persis tidak dibuktikan; yang dibuktikan adalah kedua lokasi tersebut sama-sama efektif.

---

## 6. Data pengguna & persistensi

| File | Ukuran | Timestamp | Isi terbukti |
|---|---:|---|---|
| `TunerProSettings.dat` | 71.304 | 2026-11-18 00:34:41 | Path BIN/XDF/ADX terakhir, termasuk path work copy BE-11; konfigurasi umum |
| `TunerProSettingsFree.dat` | 71.304 | 2026-10-04 13:51:41 | Varian settings "Free"; tidak diubah probes |
| `TPSPMSettings.dat` | 580 | 2026-11-18 00:31:45 | `comport=\.\COM1`, `interfacetype=3`, `loadlastdef=1`, `recentdef=…\keihin.adx`, `lastadxpath=…\keihin.adx`, geometri panel |
| `TPEmuPlugin.dat` | 48 | 2026-11-18 00:31:45 | Biner: `00 00 00 00 01 00 00 00 … 5C 5C 2E 5C 43 4F 4D 31` (`\\.\COM1`) … `03 00 00 00` |

**Disclosure wajib:** probes runtime mengubah path terakhir dan `interfacetype` pada `TPSPMSettings.dat`/`TunerProSettings.dat`. Tidak ada backup yang dibuat sebelum probes. Pemulihan: hapus `TunerProSettings.dat`/`TPSPMSettings.dat`/`TPEmuPlugin.dat` agar aplikasi membuat default baru, atau set ulang path/port melalui Preferences. `TunerProSettingsFree.dat` tidak tersentuh dan dapat dijadikan pembanding.

---

## 7. Sumber daya internal executable

| Jenis | Jumlah/ID | Catatan |
|---|---|---|
| Menu | 10 (`136`, `210`, `288`, `289`, `2951`, `3109`, `3111`, `3112`, `3118`, `3128`) | Menu utama + konteks |
| Dialog | ±40 (103, 133, 134, 138, 142, 168, 184, 206–209, 215, 224, 230, 240, 242, 244, 273, 274, 276, 282, 285, 304, 3061, 3067, 3099, 3105, 3108, 3116, 3117, 3118–3127) | Preferences, About, error, editor |
| Bitmap | `245` (141.862 B), `3097` (28.456 B) | Splash/logo & toolbar |
| WAV | 7 file di `Sounds/` | Umpan balik audio |
| CHM | 1 | Bantuan |

Total resource di `PE_TunerPro.exe.json`: 90 entri. Tidak ada resource berisi kunci lisensi atau sertifikat.

---

## 8. Ketergantungan jaringan, kriptografi, dan lisensi

- **Jaringan:** `WININET` diimpor dan string "Check Internet For Updates…"/"Check For Updates" ada. Namun tidak ada bukti pemanggilan jaringan selama sesi (tidak ada koneksi keluar yang tertangkap). Fitur update ada secara kode, tidak diverifikasi secara runtime.
- **Kriptografi:** `ADVAPI32` CryptoAPI dipakai untuk enkripsi XDF/ADX (magic container, lihat laporan 07/08). Kunci/IV tidak diekstrak; tidak ada upaya membongkar proteksi.
- **Lisensi:** string menyatakan registrasi opsional, versi unregistered "fully functional" dan "never expires". Tidak ditemukan mekanisme pembatasan keras yang diuji.
- **RPC/UUID:** dipakai untuk ID plug-in checksum (`uniqueid`, mis. `0x1AA5`, `0x43D2`) dan GUID plug-in (`IRON-PONY-RK` pada XDF CBR1000RR).

---

## 9. Komponen yang TIDAK ada (penting untuk RevCore)

Dari import table, export, string, dan observasi runtime:

- Tidak ada driver kernel mode, service, atau filter driver yang dipasang.
- Tidak ada dependensi .NET/CLR, Java, Python, Node/Electron.
- Tidak ada library flashing ECU Honda (Keihin/Shindengen) di executable utama; operasi tulis yang ada adalah jalur chip/emulator (`PromIO`, `MMAutoProm`, Quarterhorse/RoadRunner/Ostrich).
- Tidak ada DLL `HondaChecksum`/`HondaFrame` khusus; checksum Honda ditangani lewat definisi XDF + plug-in checksum.
- Tidak ada modul yang secara eksplisit menangani protokol KWP2000 Honda; yang ada adalah primitif serial generik (`MMSerial`) dan definisi ADX.

---

## 10. Keyakinan & batas

| Aspek | Tingkat keyakinan | Dasar |
|---|---|---|
| Daftar file & hash | TINGGI | Hash dihitung langsung dari file |
| Header PE & import | TINGGI | Parsing PE langsung |
| Export DLL | TINGGI | Parsing export directory |
| Modul runtime 55/54 | TINGGI | Snapshot proses berulang + ablation |
| Urutan muat | SEDANG | Satu snapshot; urutan bisa berbeda antar sesi |
| Peran tiap DLL | TINGGI (nama export/string) / SEDANG (perilaku internal) | Export + string + observasi |
| Isi `TunerProPu.dat` | RENDAH | Tidak diuraikan; hanya ukuran/hash |
| Urutan pencarian plug-in | RENDAH | Hanya lokasi efektif yang terbukti |

**Yang tidak diklaim:** tidak ada klaim bahwa seluruh logika internal DLL telah direkonstruksi; laporan ini adalah inventaris komponen dan kontrak antarmuka, bukan dekompilasi penuh.
