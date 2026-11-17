# LAPORAN INVENTARIS — REMAP TOOLS BE-09 Revisi 3

**Work Order 01** — Complete Archive Inventory / External ECU Research / Full Directory Mapping, File Identification & Security Classification
Tanggal inventaris: 17 November 2026
Status pekerjaan: **INVENTORY ONLY** — tidak ada eksekusi program, tidak ada perubahan file sumber, tidak ada integrasi ke RevCore.

---

## 1. Ringkasan Eksekutif

Folder sumber yang diinventaris adalah paket komersial *Honda motorcycle ECU remapping* untuk pasar Indonesia, berisi tiga kelompok besar:

1. **Dataset kalibrasi**: 700 file BIN/ROM (136,8 MB) dan 177 definisi kalibrasi (174 XDF + 3 ADX), mencakup 121 folder ECU spesifik pada 15 keluarga sepeda motor Honda. **164 dari 177 definisi terkunci/enkripsi** (header `05 22 97 00`), sehingga hanya 13 XDF yang dapat dibaca langsung sebagai XML.
2. **Perangkat lunak tuning & flashing**: HondaECU 3.5.5.2 (runtime Python tertanam), HondaECU 3.0.2/3.3.0, PRO Remap BE, SCANNER HONDA, ANALIST Pro 5.1, dua kalkulator checksum, XDF/ADX Unlocker, dan Pin Out ECU.
3. **Perkakas sistem berisiko tinggi**: dua paket penonaktifan pertahanan Windows (Defender Control v2.1 dan Windows Update Disabler berbasis PsExec), aplikasi remote access (AnyDesk, TeamViewer), dua file kredensial plaintext, serta installer driver FTDI/Zadig.

Dari 1.168 file, klasifikasi risiko akhir: **12 TINGGI, 17 SEDANG, 724 RENDAH, 415 INFO**. Dua belas temuan TINGGI seluruhnya berada di `1 Tools\`, `2 App Send To Desktop\`, dan `3 App Setup\` — **tidak ada satu pun di folder dataset BIN/XDF**.

Kesimpulan utama: dataset ROM/XDF layak dijadikan bahan referensi riset (setelah verifikasi hukum dan integritas), sedangkan **folder perkakas tidak boleh dieksekusi di workstation produksi** dan sebaiknya dipisahkan/quarantine.

---

## 2. Batas Lingkup, Metode, dan Kepatuhan

| Aspek | Pelaksanaan |
|---|---|
| Modifikasi sumber | **Tidak ada.** Semua operasi read-only (`ls`, `find`, `file`, `sha256sum`, `unzip -l`, `7z l`, `Get-AuthenticodeSignature`). |
| Eksekusi perangkat lunak | **Tidak ada.** Tidak ada `.exe`, `.bat`, `.vbs`, `.ocx`, atau installer yang dijalankan. |
| Integrasi RevCore | **Tidak dilakukan**, sesuai perintah kerja. |
| Enkripsi/kriptografi | Definisi terenkripsi **tidak didekripsi**; hanya header 4 byte yang diperiksa. |
| Kredensial | File kredensial hanya dicatat keberadaan, ukuran, dan hash; **isi tidak ditampilkan**. |
| Pemindaian malware | **Tidak dilakukan** (lihat §10). Tidak ada verdict malware. |
| Sumber pengganti | Tidak dicari; lokasi yang diperiksa adalah lokasi yang ditunjuk. |

Tingkat bukti yang dipakai pada laporan ini:

- **E1** — diamati langsung: keberadaan file, ukuran, hash SHA-256, magic `file`, status tanda tangan Authenticode, isi README/dokumentasi.
- **E2** — disimpulkan dari metadata/nama file (versi, CompanyName, pola nama ROM).
- **E3** — belum diverifikasi (perilaku runtime, isi arsip terenkripsi, verdict keamanan).

---

## 3. Snapshot Sumber

| Item | Nilai |
|---|---|
| Nama folder | `REMAP TOOLS BE-09 Revisi 3` |
| Path absolut | `C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3` |
| Status akses | Ada, dapat dibaca (E1) |
| Jumlah folder | 374 |
| Jumlah file | 1.168 |
| Symlink | 0 |
| Total ukuran | 474.105.472 byte (≈452 MiB) |
| Rentang timestamp file | 2005 – 2026 |
| File dengan hash unik | 947 dari 1.168 (221 duplikat byte-identik) |
| Hash unik BIN+XDF | 656 |

Sebaran file per top-level:

| Lokasi | File | Ukuran |
|---|---:|---:|
| `FILE BIN XDF ADX\` | 930 | 159,9 MB |
| `2 App Send To Desktop\` | 211 | 220,5 MB |
| `1 Tools\` | 16 | 3,4 MB |
| `3 App Setup\` | 8 | 52,8 MB |
| Root (`AnyDesk…exe`, `TeamViewer…exe`, `CATATAN & TUTORIAL.txt`) | 3 | 37,4 MB |

Catatan anomali waktu: `2 App Send To Desktop\InfoCustomer.txt` (58 B) bermodifikasi 2026-11-17 07:35, yaitu sebelum inventaris dijalankan (07:58) — bukan akibat pekerjaan ini. Dua artefak ADX di root dataset bertanggal Oktober 2026.

---

## 4. Peta Direktori

```text
REMAP TOOLS BE-09 Revisi 3\
├─ 1 Tools\                       16 file — perkakas sistem & skrip
│  ├─ dControl.exe / .ini / .zip  Defender Control v2.1
│  ├─ Defender_Settings.vbs
│  ├─ disable/enable/use update service.bat + README.md + PsExec.exe
│  ├─ comctl32.ocx, comdlg32.ocx, register_ocx.bat
│  └─ _Password.txt
├─ 2 App Send To Desktop\         211 file — aplikasi tuning + runtime HondaECU
│  ├─ HondaECU 3.5.5.2\           runtime Python 3.7 tertanam (±124 file)
│  │  ├─ panels\, threads\, eculib\, dialogs\, images\
│  │  ├─ .ecudb, pubkey.pem
│  │  └─ unins000.exe/.dat (InnoSetup)
│  ├─ HondaECU 3.0.2.exe, HondaECU v3.3.0 (utk file kecil).exe
│  ├─ PRO Remap_BE.exe, SCANNER HONDA.exe
│  ├─ ANALIST Pro 5.1 - Bayar Lagi.exe
│  ├─ CheksumCalculator.exe, CheksumKZR.exe
│  ├─ XDF ADX UNLOCKER.exe, Untuk Enable Menu.exe
│  ├─ Pin Out Ecu.exe, FTD2XX_NET.dll
│  ├─ zadig-2.1.0.exe, zadig-2.9.exe
│  └─ data\ (pinout PNG/JPG), InfoCustomer.txt
├─ 3 App Setup\                   8 file — installer
│  ├─ CDM212364_Setup.exe, REMAP CABLE DRIVER.exe   (FTDI, signed)
│  ├─ SetupTunerProRT_v500_9995.exe, reg_tunerproRT.tpk
│  ├─ winrar-x64-701.exe
│  ├─ YAMAHA SETUP.exe, y-diag yamaha setup.exe
│  └─ Password.txt
└─ FILE BIN XDF ADX\              930 file — dataset
   ├─ ADX KEIHIN BE.adx (+ .7z)   dan  ADX-D2 TECH\ (3 ADX)
   └─ BIN & XDF\
      ├─ 15 keluarga: ADV, BEAT, BLADE, CB -CBR, CRF, GENIO, MEGAPRO,
      │   PCX, REVO, SCOOPY, SONIC, SPACY, SUPRA - SONIC, VARIO, VERZA
      └─ 121 folder ECU; 53 folder "editan"/"file editan",
         56 folder "standar"/"file standar", 32 file .log
```

Folder `BIN & XDF` memakai dua konvensi: sebagian ECU hanya punya `standar`/`editan`, sebagian lagi berisi set bernomor `1.`–`25.` (kurasi urutan remap) dan subfolder `SIAP REMAP`.

---

## 5. Dataset ROM dan Definisi

### 5.1 Ukuran ROM (700 BIN)

| Ukuran | Jumlah | Interpretasi umum (E2) |
|---:|---:|---|
| 49.152 B (48 KB) | 72 | ECU lama / partial dump |
| 57.344 B (56 KB) | 28 | ECU lama |
| 65.536 B (64 KB) | 206 | ECU 125 cc generasi awal |
| 98.304 B (96 KB) | 5 | varian khusus |
| 262.144 B (256 KB) | 224 | mayoritas ECU 110–150 cc |
| 393.216 B (384 KB) | 164 | ECU 160 cc / keyless / ISS |
| 1.048.576 B (1 MB) | 1 | CBR1000RR |

### 5.2 Sebaran ROM per keluarga

| Keluarga | BIN |
|---|---:|
| Vario (110/125/150/160, KZR/K2VG/K60/K59/K46) | 187 |
| CB / CBR / Blade | 150 |
| Beat (K25/K46/K1AA/K81A/K81H/K61) | 126 |
| Supra / Sonic (termasuk GTR K56) | 65 |
| Scoopy (K16/K25/K46/K2F/K93) | 51 |
| PCX (150/160, K97G/K1ZG/K1ZN/K36J) | 48 |
| ADV (150/160) | 18 |
| Verza (K18) | 17 |
| CRF (150L/250) | 11 |
| Genio (K0J) | 8 |
| Megapro (KYE) | 7 |
| Spacy (KZL) | 7 |
| Revo (K03) | 5 |

Pemisahan status di katalog: **STOK** (folder `standar` atau nama `STD`/`ori`) vs **MODIFIKASI** (folder `editan` atau nama mengandung `rpm`, `dedot`, `rumble`, `stage`, `adipati`, `dimas`, `d2 tech`, `unlimiter`, `racing`, dll.). Penandaan ini berbasis nama/folder (E2), bukan perbandingan biner.

### 5.3 Definisi kalibrasi (XDF/ADX)

| Klasifikasi | Jumlah |
|---|---:|
| XDF terenkripsi (`05 22 97 00`) | 161 |
| XDF plain XML (`<!--`, TunerPro XDF) | 13 |
| ADX terenkripsi | 3 |
| **Total** | **177** |

13 XDF plain (dapat dibaca langsung):

- `ADV\ADV-150-30400-K0WF-T01\ADV 150 K0WF-T01 (Philipina) (Shindengen) (mbah Kung).xdf`
- `BEAT\BEAT -- K1AA-N03\file standar\30400-K1AA-N03.xdf`
- `BEAT\BEAT -- K61-601\standar\BEAT POP K61-601.xdf`
- `CB -CBR\CBR 150R-38770 K45A N01\standar\CBR150 38770 K45A N01.xdf`
- `CB -CBR\CBR500R 38770 MGZ-A03\standar\24= CBR500R 38770 MGZ-A03.xdf`
- `CB -CBR\CBR500R 38770 MGZ-C02\25= CBR500R 38770 MGZ-C02.xdf`
- `CB -CBR\CBR500R 38770 MGZ-C02\CBR1000RR 38770-MGP-A01\28= CBR1000RR 38770-MGP-A01.xdf`
- `SUPRA - SONIC\SUPRA X 125 38770-K41-NC1\SUPRA X 125 38770-K41-NC1.xdf`
- `SUPRA - SONIC\SUPRA-125 OLD 38770KVLN-21\standar\Supra 125 Old 38770 KVL - N21.xdf`
- `VARIO\VARIO 150\VARIO - 150 - k59A-A11 Ori\standar\VARIO 150-K59A-A11 Ind.xdf`
- 2× `XDF SPECIAL RACE 30400-K2VG-N32.xdf` (VARIO125, dua folder K2VG-N32)
- `VERZA\VERZA 38770 K18-902\standar\VERZA-150-38770-K18-902....xdf`

Implikasi: 92,7% definisi memerlukan alat/license D2 Tech atau dekripsi sebelum dapat dipakai. Kehadiran `XDF ADX UNLOCKER.exe` konsisten dengan kebutuhan tersebut, tetapi penggunaannya berisiko hukum dan keamanan.

---

## 6. Inventaris Perangkat Lunak

Status tanda tangan diambil dari 68 objek yang diperiksa (executable, DLL, OCX, installer, arsip ZIP): **16 Valid, 50 NotSigned, 1 UnknownError, 1 HashMismatch**.

| File | Fungsi | Tanda tangan | Kategori / Risiko |
|---|---|---|---|
| `1 Tools\dControl.exe` | Matikan Windows Defender | NotSigned, UPX | TOOL-DEFENDER-DISABLE / **TINGGI** |
| `1 Tools\dControl.ini`, `dControl.zip` | Konfigurasi/paket alat yang sama | — | **TINGGI** |
| `1 Tools\Defender_Settings.vbs` | Buka setelan proteksi Defender | skrip | **TINGGI** |
| `1 Tools\disable updates.bat` dkk. | Nonaktifkan Windows Update | skrip | TOOL-WINDOWS-UPDATE / **TINGGI** |
| `1 Tools\PsExec.exe` | Eksekusi sebagai SYSTEM | Valid (Microsoft) | TOOL-SISTEM / SEDANG |
| `1 Tools\comctl32.ocx` | Kontrol VB6 lawas | Valid (Microsoft) | RUNTIME-OCX / SEDANG |
| `1 Tools\comdlg32.ocx` | Kontrol VB6 lawas | **HashMismatch** | RUNTIME-OCX / SEDANG |
| `2 App…\HondaECU3552.exe` | Aplikasi flash/remap utama | UnknownError (MCU Innovations) | TOOL-TUNING / SEDANG |
| `2 App…\HondaECU 3.0.2.exe` | Versi lama | NotSigned | TOOL-TUNING / SEDANG |
| `2 App…\HondaECU v3.3.0 (utk file kecil).exe` | Versi lama | NotSigned | TOOL-TUNING / SEDANG |
| `2 App…\PRO Remap_BE.exe` | Remap | NotSigned | TOOL-TUNING / SEDANG |
| `2 App…\SCANNER HONDA.exe` | Diagnostik | NotSigned | TOOL-TUNING / SEDANG |
| `2 App…\ANALIST Pro 5.1 - Bayar Lagi.exe` | Analisis/repack | NotSigned | TOOL-TUNING / **TINGGI** (repack suspect) |
| `2 App…\CheksumCalculator.exe` | Hitung checksum | NotSigned | TOOL-CHECKSUM / SEDANG |
| `2 App…\CheksumKZR.exe` | Hitung checksum KZR | NotSigned | TOOL-CHECKSUM / SEDANG |
| `2 App…\XDF ADX UNLOCKER.exe` | Bypass proteksi XDF/ADX | NotSigned (.NET) | TOOL-UNLOCKER / **TINGGI** |
| `2 App…\Untuk Enable Menu.exe` | Tidak ada metadata | NotSigned | TOOL-UNLOCKER / **TINGGI** |
| `2 App…\Pin Out Ecu.exe` | Referensi pinout | NotSigned | TOOL-UTILITY / RENDAH |
| `2 App…\zadig-2.1.0/2.9.exe` | Driver USB generik | Valid (Akeo) | TOOL-DRIVER-USB / RENDAH |
| `2 App…\FTD2XX_NET.dll` | Akses FTDI | NotSigned | RUNTIME-APP / INFO |
| `3 App Setup\CDM212364_Setup.exe` | Driver FTDI | Valid (FTDI) | INSTALLER-DRIVER / RENDAH |
| `3 App Setup\REMAP CABLE DRIVER.exe` | Driver kabel | Valid (FTDI) | INSTALLER-DRIVER / RENDAH |
| `3 App Setup\SetupTunerProRT_v500_9995.exe` | Installer TunerPro RT | NotSigned | INSTALLER / SEDANG |
| `3 App Setup\winrar-x64-701.exe` | Arsip | Valid (win.rar) | INSTALLER / RENDAH |
| `3 App Setup\YAMAHA SETUP.exe` | Tool Yamaha | NotSigned ("My Company, Inc.") | INSTALLER / SEDANG |
| `3 App Setup\y-diag yamaha setup.exe` | Tool Yamaha (Specialtech) | NotSigned | INSTALLER / SEDANG |
| `AnyDesk_v8.1.0- Untuk Remote.exe` | Remote access | Valid (AnyDesk) | TOOL-REMOTE-ACCESS / SEDANG |
| `TeamViewer - Untuk Remote 2.exe` | Remote access | Valid (TeamViewer) | TOOL-REMOTE-ACCESS / SEDANG |

Komponen pendukung penting di `HondaECU 3.5.5.2\`: runtime Python 3.7 tertanam (numpy/scipy/cryptography/wx), `panels\*.pyd` untuk baca/tulis flash dan EEPROM, `threads\` untuk komunikasi K-Line, `pubkey.pem`, dan database terenkripsi `.ecudb` (121.874 B). Kategori RUNTIME-APP (138 file, 96 MB) sepenuhnya berasal dari runtime ini.

---

## 7. Temuan Keamanan

### T-01 — Paket penonaktifan Windows Defender (TINGGI, E1)
`1 Tools\dControl.exe` adalah **Defender Control v2.1** (Sordum), di-*pack* UPX dan tidak ditandatangani. Didampingi `dControl.ini` (87.896 B), `dControl.zip` (entri terenkripsi), changelog `ReadMe.txt`, dan `Defender_Settings.vbs`. Menonaktifkan proteksi AV pada mesin yang menjalankan binary tidak tepercaya menghilangkan lapisan deteksi.

### T-02 — Paket penonaktifan Windows Update + SYSTEM execution (TINGGI, E1)
`disable updates.bat`, `enable updates.bat`, `use update service.bat`, `README.md`, dan `PsExec.exe` 2.34. README menjelaskan penonaktifan `wuauserv`, `UsoSvc`, `WaaSMedicSvc`, penghapusan/penamaan ulang komponen, dan eksekusi sebagai SYSTEM melalui PsExec. Dampak: sistem kehilangan patch keamanan dan mudah dipakai untuk persistensi.

### T-03 — Alat bypass DRM (TINGGI, E1/E3)
`XDF ADX UNLOCKER.exe` — "XDF Unlocker & Password Cracker", .NET, metadata penulis "May Kawaii", unsigned. Berfungsi membuka definisi berenkripsi. Risiko: legalitas lisensi, dan binary pihak ketiga tanpa sumber yang jelas. Perilaku runtime **belum diverifikasi** (E3).

### T-04 — Unlocker tanpa identitas (TINGGI, E1)
`Untuk Enable Menu.exe` 162.816 B, PE32, tanpa version info/vendor, unsigned. Nama menunjukkan pembukaan menu tersembunyi; fungsi sebenarnya tidak dapat dipastikan tanpa eksekusi.

### T-05 — Kredensial plaintext (TINGGI, E1)
`1 Tools\_Password.txt` (579 B) dan `3 App Setup\Password.txt` (25 B). Keduanya teks polos. Isi tidak dibuka dalam laporan; hash tercatat di CSV. Kredensial yang sama mungkin telah tersebar — perlu rotasi.

### T-06 — OCX dengan hash tanda tangan tidak cocok (SEDANG, E1)
`comdlg32.ocx` berstatus **HashMismatch** meski rantai sertifikat Microsoft valid: file telah dimodifikasi/diganti setelah ditandatangani, atau berasal dari build berbeda. `comctl32.ocx` valid.

### T-07 — Binary tuning tidak bertanda tangan (SEDANG, E1)
Seluruh aplikasi tuning utama (HondaECU, PRO Remap, SCANNER) unsigned; `HondaECU3552.exe` menghasilkan status verifikasi **UnknownError**. Binary ini dapat menulis flash ECU dan mengakses port serial/USB — dampak tinggi bila dimodifikasi.

### T-08 — Remote access pra-instal (SEDANG, E1)
AnyDesk 8.1.0 dan TeamViewer installer bertanda tangan valid, tetapi kehadirannya memungkinkan akses jarak jauh persisten bila dipasang. Tidak ada konfigurasi/akun yang diperiksa.

### T-09 — Indikasi repack (TINGGI, E2)
`ANALIST Pro 5.1 - Bayar Lagi.exe` (15,9 MB, .NET) memuat CompanyName "RAT" dan nama file mengindikasikan versi "bayar lagi". Metadata saja tidak membuktikan malicious, tetapi konsisten dengan redistribusi tidak resmi.

### T-10 — Definisi terkunci massal (INFO, E1)
164/177 definisi memakai container terenkripsi `05 22 97 00`. Ini kontrol lisensi, bukan malware, namun menghambat riset dan mendorong penggunaan cracker.

### T-11 — Installer dengan metadata placeholder (SEDANG, E2)
`YAMAHA SETUP.exe` memakai CompanyName "My Company, Inc."; `y-diag yamaha setup.exe` dari Specialtech; keduanya unsigned. Tidak ada dokumentasi asal-usul.

### T-12 — Artefak registrasi TunerPro (SEDANG, E2)
`reg_tunerproRT.tpk` (185 B) adalah artefak registrasi; bersama installer TunerPro unsigned menunjukkan paket terdistribusi dengan lisensi yang perlu diverifikasi.

**Sebaran risiko:** TINGGI 12 file (T-01..T-05, T-09), SEDANG 17 file, RENDAH 724, INFO 415.

---

## 8. Rekapitulasi Klasifikasi

| Kategori | File | Ukuran |
|---|---:|---:|
| ROM-BIN | 700 | 136,8 MB |
| DEFINISI-XDF | 174 | 6,2 MB |
| RUNTIME-APP | 138 | 96,0 MB |
| ASET | 49 | 1,0 MB |
| LOG-SESI | 32 | <0,1 MB |
| ARSIP | 17 | 10,2 MB |
| DOKUMENTASI | 16 | <0,1 MB |
| TOOL-TUNING | 6 | 87,5 MB |
| KONFIGURASI | 5 | 0,4 MB |
| TOOL-DEFENDER-DISABLE | 4 | 1,0 MB |
| INSTALLER | 4 | 45,9 MB |
| DEFINISI-ADX | 3 | 0,1 MB |
| TOOL-WINDOWS-UPDATE | 3 | <0,1 MB |
| KREDENSIAL | 2 | <0,1 MB |
| TOOL-REMOTE-ACCESS | 2 | 35,7 MB |
| RUNTIME-OCX | 2 | 1,4 MB |
| INSTALLER-DRIVER | 2 | 4,5 MB |
| TOOL-CHECKSUM | 2 | 11,1 MB |
| TOOL-UNLOCKER | 2 | 0,6 MB |
| TOOL-DRIVER-USB | 2 | 10,1 MB |
| TOOL-UTILITY | 1 | 2,8 MB |
| TOOL-SISTEM | 1 | 0,8 MB |
| SKRIP | 1 | <0,1 MB |
| **Total** | **1.168** | **474,1 MB** |

Definisi risiko per kategori kunci:

- **TINGGI**: kredensial plaintext; Defender/Windows Update disabling; dua unlocker; ANALIST repack.
- **SEDANG**: tool tuning/flash unsigned, checksum, installer, remote access, OCX (hash mismatch), PsExec.
- **RENDAH**: ROM BIN (data, bukan program), arsip, driver bertanda tangan, pinout, skrip.
- **INFO**: definisi, runtime, aset, log, dokumentasi.

---

## 9. Rekomendasi

1. **Isolasi**: simpan arsip di host/VM offline tanpa kredensial dan tanpa akses jaringan. Jangan menjalankan `dControl`, skrip update, PsExec, unlocker, atau installer di workstation produksi.
2. **Karantina**: pindahkan `1 Tools\` (kecuali OCX yang diperlukan secara sah), `XDF ADX UNLOCKER.exe`, `Untuk Enable Menu.exe`, dan `ANALIST Pro 5.1 - Bayar Lagi.exe` ke folder quarantine terpisah; beri tanda "jangan dieksekusi".
3. **Rotasi kredensial**: ganti kata sandi yang tertulis di `_Password.txt` dan `3 App Setup\Password.txt` bila masih dipakai; jangan menyebarkan isinya.
4. **Verifikasi lisensi**: pastikan hak pakai XDF/ADX dan perangkat lunak tuning; hindari cracker untuk kepatuhan hukum.
5. **Integritas**: gunakan hash SHA-256 pada `INVENTORY.csv` sebagai baseline chain-of-custody. Bandingkan bila arsip disalin.
6. **Pemindaian malware**: pindai **salinan** arsip dengan AV/EDR (bukan folder asli) agar tidak ada karantina yang mengubah bukti. Verdict malware saat ini belum ada.
7. **Untuk RevCore**: gunakan hanya data ROM/XDF sebagai bahan referensi. Mulai dari 13 XDF plain sebagai contoh skema; perlakukan BIN sebagai data uji tanpa mengeksekusi tool vendor. Jangan menyalin kode, kunci, atau mekanisme proteksi.
8. **Dokumentasi asal-usul**: catat sumber setiap ROM (nama tuner pada nama file: Adipati, Dimas, d2 tech, DMS, dst.) dan status stok/modifikasi sebelum dipakai.

---

## 10. Keterbatasan dan Hal yang Belum Diverifikasi

- **Tidak ada pemindaian antivirus/EDR** dan tidak ada analisis perilaku. Semua penilaian risiko bersifat struktural/heuristik (E1/E2), bukan verdict malware (E3).
- **Tidak ada eksekusi**, sehingga fungsi `Untuk Enable Menu.exe`, isi `dControl.zip`, dan perilaku unlocker tidak diketahui.
- **Tidak ada dekripsi** 164 definisi; jumlah dan jenis tabel di dalamnya tidak diketahui.
- **Status Authenticode** diambil dari `Get-AuthenticodeSignature`; `UnknownError` berarti verifikasi gagal, bukan bukti mutasi.
- **Label STOK/MODIFIKASI** ditentukan dari nama folder/file, bukan diff biner terhadap ROM stok.
- **Timestamp** tidak dapat diandalkan sebagai bukti kronologi (ada file bertanggal 2025–2026).
- **Isi file kredensial tidak diperiksa**; hanya keberadaan, ukuran, dan hash yang dicatat.
- **Sebagian entri arsip tidak terbaca** (ZIP terenkripsi pada `dControl.zip`).

---

## 11. Artefak

Semua berada di `C:\Users\Lord Otoy\Documents\Qoder\work\remap_inventory_20261117\`:

| File | Isi |
|---|---|
| `INVENTORY.csv` | Katalog lengkap 1.168 baris: path, ukuran, timestamp, magic, SHA-256, kategori, risiko, flag, catatan |
| `tree_dirs.txt` / `tree_files.txt` | Peta direktori dan daftar file |
| `all_hashes.tsv` | SHA-256 seluruh file |
| `file_magic.tsv` | Hasil deteksi tipe file |
| `signatures.txt` | Status Authenticode 68 objek |
| `def_headers.tsv` | Header 177 definisi XDF/ADX (enkripsi vs plain) |
| `archive_contents.txt` | Daftar isi arsip ZIP/RAR/7Z |
| `build_catalog.ps1` | Skrip pembangun katalog (dapat dijalankan ulang, read-only terhadap sumber) |

---

*Laporan ini adalah hasil inventaris read-only. Tidak ada file sumber yang diubah dan tidak ada perangkat lunak yang dijalankan.*
