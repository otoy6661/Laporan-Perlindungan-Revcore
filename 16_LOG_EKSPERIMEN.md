# 16 — LOG EKSPERIMEN

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Prinsip:** setiap eksperimen mencatat tujuan, tindakan, hasil, artefak, dan efek samping. Kegagalan tidak dihapus.

---

## 1. Aturan keselamatan yang dipatuhi

- Tidak ada file instalasi yang diubah permanen. Satu-satunya intervensi adalah rename sementara `TPChecksumPlugin.dll` (dipulihkan, `RESTORED=True`).
- Tidak ada file dataset asli yang diedit; semua uji memakai salinan di `04_BIN_AUTOPSY/WORK` dan `06_ADX_AUTOPSY/WORK`.
- Tidak ada penulisan ke ECU/perangkat.
- Tidak ada eksekusi installer (`vcredist_x86.exe`, `unins001.exe`) atau update jaringan.
- Tidak ada dekripsi paksa/password cracking.

---

## 2. Log eksperimen

| ID | Tujuan | Tindakan | Hasil | Artefak | Efek samping |
|---|---|---|---|---|---|
| E01 | Baseline lingkungan | Catat OS/CPU/RAM/.NET/path | Windows 11 22631, i7-4770, 15,5 GB, .NET 8.0.204 | `00_SOURCE_INVENTORY/ENVIRONMENT.txt` | — |
| E02 | Inventaris aplikasi | Hash 24 file, baca versi | Semua hash konsisten; EXE 1.324.544 B | `APP_INVENTORY.csv` | — |
| E03 | Inventaris dataset | Enumerasi 930 file | 700 BIN, 174 XDF, 3 ADX, total 159.940.598 B | `DATASET_INVENTORY.csv` | — |
| E04 | Analisis PE | Parse 9 binary, ekstrak string/resource | 27 import EXE, 90 resource, 27.115 baris string | `02_STATIC_ANALYSIS/PE/*` | — |
| E05 | Startup tanpa BIN valid | Jalankan aplikasi dengan path BIN hilang | `Failed to open BIN file`; tidak crash | `startup_corrupt.png` | Settings path diperbarui |
| E06 | Buka pasangan K1AA | BIN 262.144 B + XDF plaintext | Tree/tabel terbuka | `loaded_pair.png`, `cbr_loaded.png` | Recent files berubah |
| E07 | Buka/edit tabel | Buka tabel 35×29, edit sel | Grid menerima edit | `table_open.png`, `after_edit.png` | — |
| E08 | Ekspor tabel | Ekspor tabel ke CSV | 530 baris | `05_XDF_AUTOPSY/export_tps_rpm.csv` | — |
| E09 | Uji Save SUPRA | Save BIN tanpa perubahan | Checksum tetap `0xFF` | `SELFTEST.txt` | Work copy berubah |
| E10 | Uji korupsi checksum | Set byte `0x00`, Save | Menjadi `0xFF` | `CHECKSUM_DELTA_TEST*` | Work copy |
| E11 | Uji delta data | Ubah `0x1000`, Save | Checksum tidak berubah; diff 0 | `CHECKSUM_DELTA_TEST*` | Work copy |
| E12 | Uji CBR | Save As XDF/BIN CBR | Gagal: checksum plug-in `IRON-PONY-RK` tidak ada | `cbr_save_error.png` | Tidak ada file tujuan |
| E13 | Buka XDF terenkripsi | Buka ADV K0WA | Tree hanya header/kompatibel ECU | `encxdf_load.txt`, `encxdf_header.txt` | Recent files |
| E14 | Buka ADX | Buka `keihin.adx` | 11 baris, 9 gauge, 2 chart, history | `adx_*_runtime.txt/png` | ADX path tersimpan |
| E15 | Coba scan | Start/Stop Data Scan tanpa hardware | `DA: Connecting...`; tanpa dialog | `adx_scan_runtime.txt` | Status DA berubah |
| E16 | Perintah hardware | System Check, Init, Upload/Download/Verify, Live Tuning, Release | System Check “All is well!”; emulasi error 64 KB; lainnya senyap | `ui_commands.out` | TPEmuPlugin.dat |
| E17 | About Plug-ins | Buka dialog | 2 plug-in hardware; checksum tidak tampil | `about_plugins.png` | — |
| E18 | Ablation checksum | Rename `TPChecksumPlugin.dll`, start, restore | 54 modul; aplikasi start; `RESTORED=True` | `plugin_ablation_checksum.txt` | File dipulihkan |
| E19 | Snapshot settings | Baca `.dat`, ekstrak path/hex | `comport=\\.\COM1`, `interfacetype=3` | `settings_snapshot.txt` | — |
| E20 | Matriks dataset | Scan salinan, tulis CSV | 177 baris; 174 SAME_DIR, 3 NO_BIN | `DATASET_COMPATIBILITY_MATRIX.csv` | — |
| E21 | Self-test prototipe | Jalankan TpFormatKit | PASS=53 FAIL=0 | `SELFTEST.txt` | — |
| E22 | Dump menu ulang | Jalankan `menu_dump.ps1` | 5.522 B dump lengkap; koreksi ID Save | `menu_tree_new.txt` | Settings recent files |
| E23 | Statistik matriks | Jalankan `matrix_stats.ps1` | 161/13 XDF, 3 ADX, 174 SAME_DIR | `matrix_stats.txt` | — |
| E24 | Inventaris runtime | Snapshot 55/54 modul | Urutan muat terdokumentasi | `modules_full.txt` | — |

---

## 3. Kendala dan kegagalan yang tidak disembunyikan

| Kendala | Dampak | Penyelesaian |
|---|---|---|
| Python tidak terpasang | Awalnya gagal parse JSON/CSV | Beralih ke C#/PowerShell |
| Bash mengonsumsi `$` pada perintah PowerShell inline | Beberapa perintah gagal | Menulis `.ps1` dan memanggil `-File` |
| Pipe PowerShell ditangani bash | `Out-File: command not found` | Redireksi `>` dari bash |
| `menu_tree.txt` pertama 0 byte | Bukti ID menu hilang | Dijalankan ulang → `menu_tree_new.txt` |
| UI Automation tidak stabil | Dump kontrol awal tidak lengkap | Beralih ke enumerasi Win32 |
| Screenshot awal tidak tersimpan | Bukti visual hilang | Ulangi dengan path absolut |
| Tidak ada hardware | Semua jalur serial berhenti di validasi host | Dinyatakan sebagai batas, bukan hasil |
| ADX/XDF terenkripsi | Isi tidak dapat dibaca | Dinyatakan `NOT_DIRECTLY_READABLE` |
| Dialog Help/Registration tidak diuji | Cakupan tidak penuh | Dicatat di laporan 19 |

---

## 4. Perubahan state yang disebabkan pengujian

| File | Perubahan | Status |
|---|---|---|
| `TunerProSettings.dat` | Path BIN/XDF/ADX terakhir ke work copy | Tidak dipulihkan (tidak ada backup) |
| `TPSPMSettings.dat` | `lastadxpath`, `recentdef`, `comport`, `interfacetype=3` | Tidak dipulihkan |
| `TPEmuPlugin.dat` | Menyimpan `\\.\COM1` | Tidak dipulihkan |
| `TunerProSettingsFree.dat` | Tidak berubah | Aman |
| Folder instalasi | Tidak berubah (kecuali rename sementara yang dipulihkan) | Aman |
| Dataset asli | Tidak berubah | Aman |

Prosedur pemulihan: hapus tiga file settings (aplikasi membuat default) atau set ulang melalui Preferences; `TunerProSettingsFree.dat` dapat dijadikan pembanding.

---

## 5. Eksperimen yang sengaja TIDAK dilakukan

| Eksperimen | Alasan |
|---|---|
| Menjalankan `Check Internet For Updates` | Tidak perlu; berisiko jaringan tanpa manfaat bukti |
| Registrasi | Tidak relevan untuk autopsi teknis |
| Dekripsi XDF/ADX | Melanggar batas; tidak ada kunci |
| Menjalankan installer/updater | Dapat mengubah instalasi |
| Menulis ke ECU/emulator | Tidak ada hardware; berisiko |
| Fuzzing file XDF/ADX | Berisiko crash; tidak diperlukan untuk 19 deliverable |
| Analisis antivirus penuh | Di luar cakupan; tidak ada indikasi malware |

---

## 6. Reproduksibilitas

- Hash semua input ada di `APP_INVENTORY.csv`/`DATASET_INVENTORY.csv`.
- Skrip tersimpan di `03_RUNTIME_ANALYSIS/*.ps1` dan `11_EXPERIMENTS/*.ps1`.
- Prototipe dapat dijalankan ulang (lihat laporan 15).
- Screenshot dan dump disimpan apa adanya; tidak diedit.

---

## 7. Keyakinan log

| Aspek | Keyakinan |
|---|---|
| Urutan/tindakan | TINGGI (artefak per langkah) |
| Hasil | TINGGI untuk yang tersimpan; SEDANG untuk yang hanya console |
| Efek samping | TINGGI (file dapat diperiksa) |
| Kelengkapan | SEDANG (beberapa dialog tidak diuji) |
