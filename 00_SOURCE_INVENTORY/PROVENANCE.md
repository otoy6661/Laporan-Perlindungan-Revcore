# BE-12 — PROVENANCE & IDENTITAS FLASHPRO.inc

**Tanggal analisis:** 2026-11-18 (waktu lokal, UTC+7; timestamp di laporan ini UTC kecuali dinyatakan lain)
**Lokasi terpasang:** `C:\Program Files (x86)\FLASHPRO.inc`
**Metode:** inventaris baca-saja, hashing, parsing PE, pembandingan biner, dan penelusuran artefak instalasi sebelumnya
**Status keseluruhan bagian ini:** STATIC VERIFIED kecuali yang ditandai lain

---

## 1. Ringkasan

1. Folder terpasang berisi **7 file**. Tiga di antaranya adalah EXE, dan **ketiganya bukan executable asli**, melainkan **wrapper VB6** (stub `TJprojMain`, FileVersion 1.00, ProductName `Project1`, unsigned) yang memuat executable asli secara utuh sebagai payload.
2. Payload di dalam `FLASHPRO.exe` **identik byte-per-byte** dengan executable asli hasil ekstraksi installer (sha256 `9fafdc8e…`), yaitu build **x64 Enigma Protector 5.x**, FileVersion **0.0.1.6**, ProductName **Team Tech Tunner**, CompanyName **itech**, timestamp PE **2026-05-28 09:15:40 UTC**.
3. Payload di dalam `AUTO UPDATE.exe` juga identik dengan hasil ekstraksi installer (sha256 `181db74b…`): build x64 5 seksi, ProductName `AUTO UPDATE`, FileVersion 1.0.0.0, copyright 2026.
4. Payload di dalam `unins000.exe` adalah **uninstaller Inno Setup asli** (x86, 11 seksi, ProductName `FLASHPRO`, deskripsi `Setup/Uninstall`, versi 51.1052.0.0).
5. Format wrapper berhasil didekodkan sepenuhnya dan diverifikasi pada ketiga file (§4). Semua invarian struktur cocok.
6. Ketiga EXE ditulis ulang pada **2026-11-17 11:38:51–52 UTC**, yaitu 4 hari setelah instalasi (2026-11-13 11:53 UTC). File `flashpro.exe`+U+00A0 (salinan payload asli) muncul 28 menit kemudian, **2026-11-17 12:06 UTC**.
7. Stub wrapper memuat kapabilitas yang perlu dicatat (unduh URL, eksekusi via ShellExecute, terminasi proses, registry, file I/O) — lihat §6. Ini **deskripsi kapabilitas statis**, bukan klasifikasi malware dan bukan bukti kapabilitas tersebut dipakai.
8. Artefak lokal terkait Enigma yang bersifat sensitif (project berisi private key, keygen, salinan termodifikasi) **tidak disalin, tidak dianalisis, dan tidak akan dipublikasikan** (§9).

---

## 2. Identitas produk terpasang

| Atribut | Nilai | Bukti |
|---|---|---|
| Nama tampilan (registry) | `FLASHPRO` | HKLM `WOW6432Node\...\Uninstall\{7F1E4D66-3B9D-4A2E-8B7B-3E3A5B7E4A33}}_is1` |
| DisplayVersion | `7` | registry yang sama |
| InstallLocation | `C:\Program Files (x86)\FLASHPRO.inc\` | registry yang sama |
| InstallDate | `20261113` | registry yang sama |
| UninstallString | `"C:\Program Files (x86)\FLASHPRO.inc\unins000.exe"` | registry yang sama |
| Installer (bukti sebelumnya) | `flashpro2026-inc.exe`, Inno Setup 6.5.0 Unicode, AppId `{7F1E4D66-3B9D-4A2E-8B7B-3E3A5B7E4A33}`, sha256 `21e1885c2cb0c4389378e53571c695733d3c97f369a635db591c8127e1bff987` | `Qoder\flashpro_analysis` (BE-12 tidak memiliki installer-nya; lihat §10) |
| Publisher yang tercantum di payload | `itech` / `Team Tech Tunner` | VERSIONINFO payload `flashpro.exe`+U+00A0 |
| Versi aplikasi asli | `0.0.1.6` | VERSIONINFO payload |

Catatan: label folder `FLASHPRO.inc` tidak membuktikan bentuk badan hukum; yang terbukti hanya string vendor di VERSIONINFO dan metadata registry di atas.

---

## 3. Timeline (waktu UTC, dari NTFS + registry + PE)

| Waktu | Peristiwa | Sumber |
|---|---|---|
| 2026-01-30 08:33:06 | `lastimage.txt` ditulis (isi menyebut path PNG di `C:\Users\Home\Downloads`) | mtime file |
| 2026-05-10 06:24 | Build `REMAP CABLE DRIVER.exe` (3.847.853 B) menurut daftar file installer | installer file list (bukti sebelumnya) |
| 2026-05-28 09:15:40 | Build payload FlashPro x64 (timestamp PE) | PE header payload |
| 2026-05-28 11:45 / 16:19 | Tanggal file payload `AUTO UPDATE.exe` / `FLASHPRO.exe` di installer | installer file list (bukti sebelumnya) |
| 2026-11-13 11:53:20–21 | Instalasi dibuat; seluruh file mendapat creation time ini | NTFS |
| 2026-11-13 11:53:21 | `unins000.dat` ditulis | NTFS |
| **2026-11-17 11:38:51** | `AUTO UPDATE.exe` (wrapper) ditulis | NTFS mtime |
| **2026-11-17 11:38:52** | `FLASHPRO.exe` dan `unins000.exe` (wrapper) ditulis | NTFS mtime |
| **2026-11-17 12:06:10–11** | `flashpro.exe`+U+00A0 dibuat — salinan payload asli (sha256 `9fafdc8e…`) | NTFS creation/mtime |

Kesimpulan faktual: executable yang saat ini terpasang **bukan** file yang dipasang installer pada 13 Nov; ketiganya diganti oleh wrapper pada 17 Nov, dan salinan payload asli diletakkan 28 menit kemudian dengan nama berakhiran U+00A0.

---

## 4. Format wrapper (STATIC VERIFIED, terverifikasi pada 3 file)

### 4.1 Diagram

```text
offset 0                      ukuran tetap 122.880 B (0x1E000)
+----------------------------+
| Stub PE32 VB6 (3 seksi)    |  .text/.data/.rsrc; akhir image = 0x1E000
+----------------------------+  <-- awal overlay
| Filler                     |  N byte; satu blok 256 B diulang; N acak per build
+----------------------------+
| Header 25 B                |  u16 N | 0x0000 | 0x0E10 | 19 B data
+----------------------------+
| Executable asli (payload)  |  MZ ... PE; identik dengan file installer
+----------------------------+
| Trailer 25 B               |  u32 ukuran payload | 0x0E10 | 20 B data
+----------------------------+
```

### 4.2 Invarian yang diverifikasi

- `payload_offset = 122.880 + N + 25`, dengan `N = u16` pada header offset +0.
- Region filler tepat periodik 256 byte sampai awal header.
- `u16` pada header +4 = `0x0E10`; `u16` pada trailer +4 = `0x0E10`.
- `u32` pada trailer +0 = panjang payload, dan `ukuran file = 122.880 + N + 25 + payload + 25`.
- Header/trailer bukan teks dan belum didekode lebih jauh; 19/20 byte sisanya bervariasi antar build (lihat CSV).

### 4.3 Tabel verifikasi

| File | Ukuran | MZ payload | N | Payload (B) | Payload sha256 | vs installer | Status |
|---|---:|---:|---:|---:|---|---|---|
| `FLASHPRO.exe` | 33.460.372 | 138.363 | 15.458 | 33.321.984 | `9fafdc8e795b2809cc02356bb2d4f5e79432fa3f72ab65ff7a8b56039bd02eb3` | EXACT MATCH | STATIC VERIFIED |
| `AUTO UPDATE.exe` | 9.810.157 | 138.452 | 15.547 | 9.671.680 | `181db74b0e282e91cefa18c4d9d8f7975b0bee55df4bd32e51187cfec397d9ec` | EXACT MATCH | STATIC VERIFIED |
| `unins000.exe` | 3.831.646 | 138.336 | 15.431 | 3.693.285 | `7392f14a21b453126924dff5c2faaba73e57e4e3b50e2dd068caec060e95187a` | N/A (installer tidak tersedia) | STATIC VERIFIED |

Header/trailer per file (hex, 25 B):

| File | Header | Trailer |
|---|---|---|
| `FLASHPRO.exe` | `623c0000100e137d64671a2f25c8979ecea09c565e45dab2a4` | `0074fc01100e18685a5f312a318b646d282f312c4a2cb28f85` |
| `AUTO UPDATE.exe` | `bb3c0000100e1a7d646d1a2f2ac89796cea095565e46dab2a3` | `00949300100e1b685a5c312a378b6476282f282c4a2eb28f8b` |
| `unins000.exe` | `473c0000100e177d646c1a2f29c89798cea09d565e48dab29a` | `e55a3800100e19685a58312a338b646c282f312c4a31b28f80` |

Hasil reproduksi: `verify_wrapper.ps1` → `WRAPPER_LAYOUT_VERIFIED.csv` (semua kolom boolean `True`).

---

## 5. Payload vs file installer (bukti pembanding)

File asli hasil ekstraksi installer tersimpan pada artefak BE-12 sebelumnya:
`C:\Users\<USER>\Documents\Qoder\flashpro_analysis\embedded_2026\{app}\`

| File | sha256 file installer | Dibandingkan dengan | Hasil |
|---|---|---|---|
| `FLASHPRO.exe` (33.321.984 B) | `9fafdc8e795b2809cc02356bb2d4f5e79432fa3f72ab65ff7a8b56039bd02eb3` | payload wrapper `FLASHPRO.exe` | EXACT MATCH (`cmp` 0 beda) |
| `AUTO UPDATE.exe` (9.671.680 B) | `181db74b0e282e91cefa18c4d9d8f7975b0bee55df4bd32e51187cfec397d9ec` | 9.671.680 byte pertama payload wrapper | EXACT MATCH (`cmp` 0 beda) |
| `unins000.exe` asli | tidak tersedia | — | NOT AVAILABLE |

Daftar file installer (bukti sebelumnya, `installer_filelist.txt`) juga mencatat ukuran yang sama: `{app}\FLASHPRO.exe` 33.321.984 B dan `{app}\AUTO UPDATE.exe` 9.671.680 B. Ini konsisten dengan model wrapper.

---

## 6. Stub VB6 (wrapper)

| Atribut | Nilai |
|---|---|
| Format | PE32 x86, 3 seksi, image 122.880 B, entry RVA 0x290C, image base 0x400000 |
| Timestamp PE | 2013-04-01 07:08:22 UTC (sama untuk semua stub) |
| Import | hanya `MSVBVM60.DLL` (VB6 runtime) |
| Versi | FileVersion `1.00`, ProductName `Project1`, OriginalFilename `TJprojMain.exe`, InternalName `TJprojMain` |
| Manifest | `Microsoft.Windows.MyCoolApp`, Common-Controls 6.0, `requestedExecutionLevel level="requireAdministrator"` |
| Tanda tangan | NotSigned (semua) |
| Hash `.text` | `FLASHPRO.exe` = `AUTO UPDATE.exe` = `96f2d4f88c34a58510c7b69c0c9a287987407dccb9b00184b53a8802628df653`; `unins000.exe` = `2dfe757264399f077eaf03e6a43fc1e651e58f6ea65ffdb4dcf43c0e131596d4` (build stub berbeda) |

String internal yang terbaca di `.text`/`.data` stub:

- Modul: `mdlMain`, `mdlTweaks`, `mdlJoin`, `mdlPE`, `mdlReg`, `mdlComp`; form `frmMain`, `Form1`; modul `uExWatch`/`uExWatch1`.
- API yang direferensikan: `URLDownloadToFileA`, `DeleteUrlCacheEntryA`, `ShellExecuteA`, `TerminateProcess`, `OpenProcess`, `CreateToolhelp32Snapshot`, `Process32First/Next`, `Thread32First/Next`, `ResumeThread`, `CreateFileA`, `ReadFile`, `WriteFile`, `SetFilePointer`, `RegCreateKeyA/RegSetValueExA/RegDeleteValueA`, `SHGetFileInfoA`, `RtlGetVersion`, `ieframe.dll`/`SHDocVw` (kontrol browser).
- Path build yang tertinggal: `C:\Program Files\Microsoft Visual Studio\VB98\VB6.OLB`.

**Interpretasi (inferensi, bukan klaim):** kombinasi `mdlJoin`/`mdlPE`/`mdlComp` + filler + payload + trailer menunjukkan stub ini dihasilkan oleh **alat joiner/binder VB6** yang menggabungkan stub, data pengisi, dan executable target. Manifest template `MyCoolApp` dan ProductName `Project1` juga khas proyek VB6 tanpa kustomisasi. Kapabilitas unduh/eksekusi/terminasi proses **terdeteksi secara statis**; apakah dipakai saat runtime belum diuji (menunggu FASE III).

---

## 7. Identitas payload aplikasi

### 7.1 `FLASHPRO.exe` (payload)

| Atribut | Nilai |
|---|---|
| Ukuran / sha256 | 33.321.984 B / `9fafdc8e795b2809cc02356bb2d4f5e79432fa3f72ab65ff7a8b56039bd02eb3` |
| Format | PE32+ x64, 5 seksi (4 tanpa nama, RWX `0xE0000040`; 1 `.rsrc`) |
| Timestamp / image base / entry | 2026-05-28 09:15:40 UTC / `0x140000000` / RVA `0x05E3F798` |
| Proteksi | Enigma Protector 5.x (taggant `Enigma Protector`, CRL enigmaprotector.com; entropi seksi 7,9998 / 7,9991 / 7,8843) |
| VERSIONINFO | 0.0.1.6, ProductName `Team Tech Tunner`, CompanyName `itech`, OriginalFilename `FLASHPRO.exe` |
| Tanda tangan | NotSigned |
| Overlay | 0 |

String plaintext terbatas pada VERSIONINFO dan artefak Enigma; isi kode terenkripsi/dikemas. Analisis kode statis lebih lanjut: **BLOCKED** oleh proteksi (lihat §10).

### 7.2 `AUTO UPDATE.exe` (payload)

| Atribut | Nilai |
|---|---|
| Ukuran / sha256 | 9.671.680 B / `181db74b0e282e91cefa18c4d9d8f7975b0bee55df4bd32e51187cfec397d9ec` |
| Format | PE32+ x64, 5 seksi, layout seksi sejenis (4 seksi RWX + `.rsrc`) |
| Timestamp | `0xE6991D0A` — resolve ke 2092, **anomali** (bukan tanggal build yang wajar; penyebab belum diketahui) |
| Proteksi | Enigma Protector 5.x (taggant sama) |
| VERSIONINFO | 1.0.0.0, ProductName/FileDescription `AUTO UPDATE`, LegalCopyright `Copyright c 2026` |

### 7.3 `unins000.exe` (payload)

| Atribut | Nilai |
|---|---|
| Ukuran / sha256 | 3.693.285 B / `7392f14a21b453126924dff5c2faaba73e57e4e3b50e2dd068caec060e95187a` |
| Format | PE32 x86, 11 seksi |
| VERSIONINFO | ProductName `FLASHPRO`, FileDescription `Setup/Uninstall`, FileVersion `51.1052.0.0` (Inno Setup) |

---

## 8. File non-EXE

| File | Ukuran | sha256 | Catatan |
|---|---:|---|---|
| `DotNetZip.dll` | 472.064 | `8e9c0362e9bfb3c49af59e1b4d376d3e85b13aed0fbc3f5c0e1ebc99c07345f3` | MSIL .NET, Ionic DotNetZip 1.16.0, unsigned |
| `lastimage.txt` | 67 | `f39f9ba69bffc124b012588052ed746444a174c58a6bfa2516db9f6f9236ca84` | berisi `C:\Users\Home\Downloads\ChatGPT Image Jun 23, 2025, 04_28_04 PM.png` |
| `unins000.dat` | 5.537 | `26150ebfd98731c56cc8c399b8e03e3f8f8dd3cc5ebed21ff79cd4ae2336349c` | data uninstaller Inno |
| `flashpro.exe`+U+00A0 | 33.321.984 | `9fafdc8e795b2809cc02356bb2d4f5e79432fa3f72ab65ff7a8b56039bd02eb3` | salinan payload asli; nama berakhir U+00A0 (titik kode 160) |

---

## 9. Artefak sensitif yang dikecualikan

Dari penelitian sebelumnya diketahui adanya artefak lokal terkait Enigma Protector (project `.enigma64` yang memuat pasangan kunci RSA termasuk private key, `.enigmadb`, `.enigmamail`, `keygen.bin`, dan salinan `FLASHPROy.exe`). Sesuai work order:

- Artefak tersebut **tidak disalin ke workspace BE-12**;
- **tidak dianalisis** (termasuk tidak membuka material kunci);
- **tidak** dimasukkan ke laporan publik, ZIP, atau repository;
- klasifikasi: `SENSITIVE_OR_RESTRICTED`.

Tidak ada crack/keygen/activator yang dibuat atau dijalankan dalam BE-12.

---

## 10. Keterbatasan

| Keterbatasan | Dampak | Status |
|---|---|---|
| Installer `flashpro2026-inc.exe` tidak ada di mesin saat BE-12 | Perbandingan memakai hasil ekstraksi sebelumnya (`embedded_2026`) yang hash-nya dihitung ulang oleh BE-12 | Dinyatakan; hashing ulang dilakukan |
| Payload dikemas Enigma | Nama fungsi, alur kode, protokol tidak dapat dibaca statis | BLOCKED untuk pembacaan kode; runtime analysis menyusul |
| Belum ada ECU/hardware | Semua klaim ECU bersifat pending | NOT TESTED |
| Runtime wrapper belum diuji | Penggunaan kapabilitas unduh/eksekusi belum diketahui | NOT TESTED (FASE III) |
| 19/20 byte header/trailer wrapper belum didekode | Makna field belum diketahui | NOT FOUND (belum ada dasar) |

---

## 11. Bukti

| ID | Artefak |
|---|---|
| EV-001 | `00_SOURCE_INVENTORY/FLASHPRO_FILE_INVENTORY.csv` |
| EV-002 | `00_SOURCE_INVENTORY/WRAPPER_LAYOUT_VERIFIED.csv` + `WRAPPER_LAYOUT_VERIFIED.txt` |
| EV-003 | `00_SOURCE_INVENTORY/verify_wrapper.ps1` |
| EV-004 | `02_STATIC_ANALYSIS/PE/PE_FLASHPRO.exe.json`, `PE_flashpro_nbsp.exe.json`, `PE_AUTO UPDATE.exe.json` |
| EV-005 | `02_STATIC_ANALYSIS/PE/STRINGS_*.txt` |
| EV-006 | `17_EVIDENCE/EV003_FILESYSTEM_TIMELINE.txt` (rencana; lihat `17_EVIDENCE/`) |
| EV-007 | Hasil `cmp` payload vs `Qoder\flashpro_analysis\embedded_2026\{app}\` (dicatat di §5) |
