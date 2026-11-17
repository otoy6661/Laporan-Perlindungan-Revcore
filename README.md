# BE-11 — TUNERPRO RT COMPLETE SOFTWARE AUTOPSY

**Status:** SELESAI DENGAN KETERBATASAN YANG DINYATAKAN  
**Tanggal analisis:** 2026-11-17 s/d 2026-11-18  
**Target:** TunerPro RT 5.0.10335.0 (x86, unsigned) — `C:\Program Files (x86)\TunerPro RT`  
**Dataset:** 930 file, 159.940.598 B — `FILE BIN XDF ADX`

Paket ini menggantikan seluruh isi root repositori dengan satu work package BE-11. Tidak ada folder BE-09, BE-10, atau BE-11 di dalam repositori; dokumen final berada langsung di root.

---

## 1. Ringkasan temuan

1. TunerPro RT adalah aplikasi native x86 (PE32, 1.324.544 B, build 2026-10-15) tanpa Authenticode, dengan 8 modul internal dan 3 ekosistem plug-in.
2. Inti produk adalah **editor definisi XDF + runner ADX + lapisan plug-in hardware**.
3. **Tidak ada jalur flashing ECU Honda.** Yang ada: pemrograman chip (PromIO) dan upload ke emulator RAM (Moates), dengan batas ukuran yang terbukti menolak BIN 65.536 B.
4. XDF adalah XML 1.70 dengan alamat absolut, stride, MATH, dan checksum deklaratif. 13 XDF plaintext; 161 terenkripsi.
5. ADX adalah bahasa transaksi serial generik (send/listen/silence/macro), warisan ALDL. 3 ADX semuanya terenkripsi.
6. Checksum SUM 8-bit TunerPro (`0xEF` pada CBR) **identik secara algoritma** dengan `HondaChecksum.calculatePacketChecksum` RevCore.
7. RevCore lebih ketat pada status nilai dan flashing (default-deny), tetapi belum memiliki parser XDF/ADX atau Live Monitor.

---

## 2. Dokumen final

| No | Laporan | Isi |
|---:|---|---|
| 01 | [Ringkasan Eksekutif](01_RINGKASAN_EKSEKUTIF.md) | Temuan utama & dampak |
| 02 | [Anatomi Aplikasi](02_ANATOMI_APLIKASI.md) | Bentuk, modul, UI, command ID |
| 03 | [Inventaris Dependensi & Komponen](03_INVENTARIS_DEPENDENSI_DAN_KOMPONEN.md) | 24 file, import/export, modul runtime |
| 04 | [Analisis Statis](04_ANALISIS_STATIS.md) | PE, string, resource, inferensi |
| 05 | [Analisis Runtime](05_ANALISIS_RUNTIME.md) | Startup, menu, preferences, operasi |
| 06 | [Autopsi BIN](06_AUTOPSI_BIN.md) | Format, offset, endian, checksum |
| 07 | [Autopsi XDF](07_AUTOPSI_XDF.md) | Skema, alamat, checksum, enkripsi |
| 08 | [Autopsi ADX](08_AUTOPSI_ADX.md) | Container, skema, model perintah |
| 09 | [Analisis Live Monitor](09_ANALISIS_LIVE_MONITOR.md) | Lists/Dash/Monitor/History |
| 10 | [Analisis Protokol](10_ANALISIS_PROTOKOL_KOMUNIKASI.md) | Transport, paket, timeout, checksum |
| 11 | [Flashing & Recovery](11_ANALISIS_FLASHING_DAN_RECOVERY.md) | Tidak ada flash ECU; chip/emulator |
| 12 | [Plugin/Driver/Hardware](12_ANALISIS_PLUGIN_DRIVER_HARDWARE.md) | 3 ekosistem, perangkat, risiko |
| 13 | [Matriks Kompatibilitas Dataset](13_MATRIKS_KOMPATIBILITAS_DATASET.md) | 930 file, 174 XDF, 3 ADX |
| 14 | [Perbandingan RevCore](14_PERBANDINGAN_REVCORE.md) | Klasifikasi EXACT MATCH dll. |
| 15 | [Prototipe & Tes](15_LAPORAN_PROTOTIPE_DAN_TES.md) | 53 cek, 0 gagal |
| 16 | [Log Eksperimen](16_LOG_EKSPERIMEN.md) | E01–E24, kendala, efek samping |
| 17 | [Indeks Bukti](17_INDEKS_BUKTI.md) | EV-001…EV-045 |
| 18 | [Keterbatasan & Risiko](18_KETERBATASAN_DAN_RISIKO.md) | Batas, risiko, disclosure |
| 19 | [Cakupan & Keyakinan](19_CAKUPAN_DAN_KEYAKINAN.md) | Cakupan ±72%, per area |

---

## 3. Struktur paket

| Path | Isi | Keterbacaan |
|---|---|---|
| `01_*.md` … `19_*.md` | 19 laporan final | DIRECTLY_READABLE |
| `00_SOURCE_INVENTORY/` | Hash aplikasi/dataset, environment, skrip inventaris | DIRECTLY_READABLE |
| `02_STATIC_ANALYSIS/PE/` | JSON PE, string dump, skrip analisis | DIRECTLY_READABLE |
| `03_RUNTIME_ANALYSIS/` | Skrip probe, dump UI, screenshot | READABLE_WITH_LIMITATIONS untuk PNG; teks DIRECTLY_READABLE |
| `04_BIN_AUTOPSY/BIN_WORK_MANIFEST.csv` | Metadata 12 berkas uji BIN/XDF (hash, peran, status publikasi) | DIRECTLY_READABLE |
| `05_XDF_AUTOPSY/` | Pohon tabel, status, ekspor CSV, container | DIRECTLY_READABLE |
| `06_ADX_AUTOPSY/` | Container & Data List ADX (teks) | DIRECTLY_READABLE |
| `11_EXPERIMENTS/` | Statistik dan skrip eksperimen | DIRECTLY_READABLE |
| `13_PROTOTYPES/` | Sumber C#, proyek, `SELFTEST.txt`, matriks | DIRECTLY_READABLE |
| `15_EVIDENCE/` | Manifest SHA-256 dan skrip pembuatnya | DIRECTLY_READABLE |
| `dataset/readable_definitions/` | 13 XDF plaintext + `MAPPING.csv` (path asal → nama publikasi) | DIRECTLY_READABLE (XML) |

Tidak ada file biner aplikasi, BIN, XDF terenkripsi, ADX terenkripsi, LOG, atau arsip yang diunggah.

---

## 4. Klasifikasi dan pengecualian

Total paket: **177 file** — 148 DIRECTLY_READABLE, 27 READABLE_WITH_LIMITATIONS (PNG), 0 NOT_DIRECTLY_READABLE yang diunggah (seluruh biner dikecualikan), 0 SENSITIVE_OR_RESTRICTED, ditambah 1 `.gitattributes` dan 1 manifest sebagai infrastruktur.

| Kelas | Perlakuan |
|---|---|
| DIRECTLY_READABLE | Diunggah: Markdown, teks, CSV, JSON, XML/XDF plaintext, PowerShell, C#, csproj |
| READABLE_WITH_LIMITATIONS | Diunggah: 27 screenshot PNG (bukti visual; teks di dalam gambar tidak diindeks) |
| NOT_DIRECTLY_READABLE | Tidak diunggah: EXE/DLL, BIN, XDF/ADX terenkripsi, LOG, ZIP/RAR/7Z |
| SENSITIVE_OR_RESTRICTED | Tidak diunggah: salinan aplikasi dan dataset; tidak ada kredensial di paket ini |

Pengecualian utama dan alasannya:

- **Aplikasi dan salinan aplikasi** (`TunerPro.exe`, 8 DLL internal, plug-in DLL, `APP_COPY`) — biner, bukan teks; hash ada di `00_SOURCE_INVENTORY/APP_INVENTORY.csv`.
- **BIN dan salinan BIN** (700 file, termasuk 12 berkas uji di `04_BIN_AUTOPSY/WORK`) — biner; metadata/hash ada di `DATASET_INVENTORY.csv` dan `BIN_WORK_MANIFEST.csv`.
- **XDF terenkripsi** (161) dan **ADX terenkripsi** (3) — tidak dapat dibaca tanpa kunci; struktur dan perilakunya dianalisis di laporan 07/08.
- **LOG dan arsip** (32 LOG, 10 ZIP, 5 RAR, 1 7Z) — tidak dianalisis sebagai sumber utama dan berpotensi memuat data personal; hanya inventarisnya yang dipublikasikan.
- **`03_RUNTIME_ANALYSIS/menu_tree.txt`** — file 0 byte (kegagalan dump); digantikan oleh `menu_tree_new.txt`.

---

## 5. Verifikasi cepat

```powershell
# Integritas seluruh file publikasi
Import-Csv PUBLICATION_MANIFEST.csv | ForEach-Object {
    $h = (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash.ToLower()
    if ($h -ne $_.sha256) { "MISMATCH $($_.path)" }
}

# Hash aplikasi & dataset asal
Import-Csv 00_SOURCE_INVENTORY\APP_INVENTORY.csv | Format-Table RelPath,Bytes,SHA256

# Jalankan ulang prototipe
dotnet run --project 13_PROTOTYPES\TpFormatKit -- "$PWD" "$PWD\13_PROTOTYPES\OUT"
Get-Content 13_PROTOTYPES\OUT\SELFTEST.txt
```

Hasil prototipe: **PASS=53 FAIL=0**, 5.338 sel dari 18 tabel cocok tanpa selisih.

---

## 6. Disclosure

Probe runtime mengubah `TunerProSettings.dat`, `TPSPMSettings.dat`, dan `TPEmuPlugin.dat` (path terakhir, COM1, interface type). Tidak ada backup. Instalasi dan dataset asli tidak diubah. Pemulihan: hapus file settings atau set ulang via Preferences. Detail: laporan 18 §2.

---

## 7. Batas

Tidak ada hardware, ECU, koneksi jaringan, atau kunci dekripsi yang digunakan. Semua klaim dibatasi oleh laporan 19. Tidak ada klaim cakupan 100%, tidak ada frame Honda yang direkonstruksi, dan tidak ada penulisan ke ECU fisik.
