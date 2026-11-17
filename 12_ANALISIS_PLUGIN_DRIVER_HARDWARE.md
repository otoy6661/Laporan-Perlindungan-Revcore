# 12 — ANALISIS PLUGIN, DRIVER & HARDWARE

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Status:** SELESAI — model plug-in, lokasi penemuan, kontrak, perangkat yang didukung, dan risiko keamanan dipetakan.

---

## 1. Tiga ekosistem plug-in yang berbeda

| Ekosistem | Kontrak | Contoh | Dipanggil oleh |
|---|---|---|---|
| Checksum | `MMCSCalculateChecksum`, `MMCSGetChecksumInfo`, `MMCSGetChecksumPluginInfo`, `MMCSGetLastErrorMessage` | `TPChecksumPlugin.dll` | `TunerPro.exe`, `XDFEditor.dll` |
| Hardware/emulator | `TPCreatePlugin`, `TPReleasePlugin` | `TPMoatesEmulatorPlugin.dll`, `ELM327PlugIn.dll` | `TunerPro.exe` |
| Modul tetap (bukan plug-in) | Export `StartPromUI`, `StartMoatesOnboardLoggerUI`, `SP*` | `PromIO.dll`, `MoatesOnboardLogger.dll`, `ScannerProModule.dll` | `TunerPro.exe` |

**Implikasi:** “Plug-ins…” di menu Help hanya menampilkan ekosistem hardware. Checksum plugin tidak muncul karena memakai kontrak berbeda. Ini bukan bug; ini dua registry terpisah.

---

## 2. Penemuan dan pemuatan

| Lokasi | Isi teramati | Status |
|---|---|---|
| Folder aplikasi | `TPChecksumPlugin.dll`, `TPMoatesEmulatorPlugin.dll` | Dimuat |
| `Documents\TunerPro Files\Plugins\` | `ELM327PlugIn.dll`, `Readme.txt` | Dimuat |
| `Documents\TunerPro Files\Bin Definitions`, `Bins`, `DataStreams`, `Layouts` | Kosong | Tidak memuat DLL |

String `Plugins\` di `TunerPro.exe` menunjukkan subfolder plug-in pengguna. String `TPCreatePlugin`/`TPReleasePlugin` adalah nama export yang dicari. Urutan pencarian persis tidak dibuktikan; yang terbukti: kedua lokasi efektif.

**Ablation:** menghilangkan `TPChecksumPlugin.dll` menurunkan modul dari 55 ke 54; aplikasi tetap start; file dipulihkan (`RESTORED=True`). Plug-in checksum tidak wajib untuk startup.

---

## 3. Plug-in checksum

| Properti | Nilai |
|---|---|
| Ukuran | 19.968 B |
| SHA-256 | `91a5b71e…` |
| Export | `MMCSCalculateChecksum`, `MMCSGetChecksumInfo`, `MMCSGetChecksumPluginInfo`, `MMCSGetLastErrorMessage`, `MMMH` |
| String | `TunerPro Default Checksum Plug-in`, `Sums the data in the range specified, stores in the size and location specified.`, `SUM1.0`, `Invalid Checksum Index` |
| Metode | SUM (satu-satunya yang diklaim) |
| Visibilitas | Tidak muncul di About Plug-ins |

**Keterbatasan:** hanya menyediakan SUM. XDF CBR yang meminta plug-in `IRON-PONY-RK` tidak dapat dipenuhi, sehingga Save gagal. Ini adalah contoh baik bahwa “plugin tersedia” ≠ “plugin yang diminta tersedia”.

---

## 4. Plug-in hardware/emulator

### 4.1 `TPMoatesEmulatorPlugin.dll`

| Properti | Nilai |
|---|---|
| Ukuran | 73.728 B |
| SHA-256 | `5124c169…` |
| Versi | 1.0.0 |
| Vendor | RusnaMark Software |
| Deskripsi | `Emulation Device Plugin for TunerPro` / “TunerPro Hardware Interface Plug-in” |
| Export | `TPCreatePlugin`, `TPReleasePlugin` |
| Terlihat di About Plug-ins | Ya |

### 4.2 `ELM327PlugIn.dll`

| Properti | Nilai |
|---|---|
| Ukuran | 37.888 B |
| SHA-256 | `F5C293A9…` (huruf besar pada file) |
| Versi | 0.6.0 |
| Deskripsi | “ELM327 OBDII Parser Plug-in” |
| Lokasi | `Documents\TunerPro Files\Plugins` |
| Export | `TPCreatePlugin`, `TPReleasePlugin` |
| String kunci | `ELM327 OBDII Interface Driver Component`, `ELM327: Request for Mode %i PID %.4X succeeded/failed`, `ELM327PlugIn.dat`, `COM%i`, `\\.\COM%u`, `MMSerial` baud |
| Terlihat di About Plug-ins | Ya |

ELM327 adalah plugin OBD-II generik (Mode/PID), **bukan** protokol Honda K-line. Tidak ada bukti plugin ini dipakai untuk membaca/menulis ECU Honda.

---

## 5. Perangkat keras yang disebut binary

| Perangkat | Jenis | Jalur |
|---|---|---|
| AutoProm | Emulator + logger + programmer | `MMAutoProm`, PromIO |
| BoostedNW Burner | Programmer chip | PromIO |
| Flash & Burn | Programmer chip | PromIO |
| Ostrich / Ostrich II | Emulator RAM | Emulation |
| RoadRunner | Emulator dengan mode kendaraan | `RoadRunner: …` |
| Quarterhorse | Emulator | `Quarterhorse` |
| Superlogger | Logger | Onboard logging |
| Demon2 | Emulator/logger | Emulation |
| FlashOnline | Emulator | Emulation |
| Destiny Programmer | Programmer chip | PromIO |
| F2E Ford EEC-IV/V Reader | Reader Ford | PromIO |
| 29F010/020/040, 2732A, 27C010/128/256/512 | Chip memori | PromIO |

Tidak ada perangkat Honda-specific (mis. HDS, Keihin interface) di daftar.

---

## 6. Driver

- Tidak ada driver kernel mode, service, atau filter driver yang dipasang oleh aplikasi.
- Komunikasi melalui port serial (`\\.\COMx`); perangkat USB muncul sebagai virtual COM port yang driver-nya disediakan sistem/perangkat, bukan TunerPro.
- Tidak ada file `.sys` dalam paket instalasi.
- Tidak ada instalasi driver saat runtime (tidak ada eksekusi `pnputil`/`InstallHinfSection` yang teramati).

---

## 7. Risiko keamanan

| Risiko | Penjelasan | Mitigasi |
|---|---|---|
| DLL tanpa signature | Semua DLL inti tanpa Authenticode | Verifikasi SHA-256 terhadap manifest |
| User-writable plugin path | `Documents\TunerPro Files\Plugins` dapat ditulis pengguna | Batasi izin; audit isi |
| Eksekusi in-process | Plug-in berjalan dengan hak penuh aplikasi | Jalankan sebagai user standar; hindari plugin tak dikenal |
| Checksum plugin opsional | Menghilangkan plugin mengubah perilaku Save | Deteksi dan laporkan plug-in yang hilang |
| ELM327 pihak ketiga | Asal/usul tidak terdokumentasi di paket | Periksa hash; jangan aktifkan tanpa kebutuhan |
| Tanpa update signature | `Check Internet For Updates` via HTTP (WININET) | Tidak diuji; jangan andalkan integritas update |

Tidak ada indikasi malware pada pemindaian string/PE; namun “tidak ada indikasi” bukan jaminan. Tidak dilakukan analisis antivirus penuh.

---

## 8. Perbandingan dengan RevCore

| Aspek | TunerPro | RevCore |
|---|---|---|
| Arsitektur plug-in | Ya (2 registry + modul tetap) | Tidak ada |
| Checksum plug-in | MMCS, hanya SUM | `HondaChecksum` hardcoded, beberapa varian |
| Hardware abstraction | `MMAutoProm`, `TPCreatePlugin` | Belum ada |
| Driver | Serial/COM generik | Serial (rencana) |
| Perangkat Honda | Tidak ada | Tidak ada |
| Keamanan plug-in | Tanpa signature, in-process | Tidak ada permukaan plug-in |

**Klasifikasi:** **NOT FOUND** untuk plug-in Honda di TunerPro; **DIFFERENT IMPLEMENTATION** untuk checksum; **SAME FRAME FAMILY** untuk transport serial.

---

## 9. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Tiga ekosistem plug-in | TINGGI (export + runtime) |
| Lokasi & pemuatan | TINGGI (modul list + ablation) |
| Perangkat yang didukung | TINGGI (string) |
| Tidak ada driver kernel | TINGGI (paket file + runtime) |
| Keamanan plugin | SEDANG (statis, tanpa uji dinamis) |
