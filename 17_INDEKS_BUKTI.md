# 17 — INDEKS BUKTI

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Tujuan:** setiap klaim dalam laporan 01–16 dapat ditelusuri ke artefak nyata.
**Manifest hash:** `15_EVIDENCE/EVIDENCE_MANIFEST.csv`

---

## 1. Tingkat bukti

| Kode | Arti |
|---|---|
| **E1** | Byte/file langsung (hash, header, isi biner) |
| **E2** | Observasi runtime langsung (window, dialog, status, modul) |
| **E3** | String/export statis dari binary |
| **E4** | Inferensi konsisten (tidak berdiri sendiri) |

Klaim dengan E4 tidak boleh diperlakukan sebagai fakta terverifikasi.

---

## 2. Indeks per klaim

| ID | Klaim | Tingkat | Artefak |
|---|---|---|---|
| EV-001 | TunerPro 5.0.10335.0, x86, 1.324.544 B, build 2026-10-15 | E1 | `02_STATIC_ANALYSIS/PE/PE_TunerPro.exe.json`, `APP_INVENTORY.csv` |
| EV-002 | Tidak ada Authenticode/overlay; 5 section | E1 | `PE_TunerPro.exe.json` |
| EV-003 | 27 DLL diimpor; WININET/CRYPTO/serial ada | E1/E3 | `PE_TunerPro.exe.json` |
| EV-004 | 24 file instalasi + hash | E1 | `APP_INVENTORY.csv` |
| EV-005 | 8 modul internal + peran export | E1/E3 | `PE_*.dll.json`, `STRINGS_*.txt` |
| EV-006 | Checksum plugin memakai MMCS*, bukan TP* | E3 | `PE_TPChecksumPlugin.dll.json`, `STRINGS_TPChecksumPlugin.dll.txt` |
| EV-007 | 55 modul dengan checksum; 54 tanpa; RESTORED | E2 | `modules_full.txt`, `plugin_ablation_checksum.txt` |
| EV-008 | About Plug-ins hanya 2 plug-in hardware | E2 | `about_plugins.png`, `ui_commands.out` |
| EV-009 | Menu lengkap + command ID | E2 | `menu_tree_new.txt` |
| EV-010 | Preferences 6 tab + nilai default | E2 | `preferences.png`, `preferences_dataacq.png` |
| EV-011 | Startup memuat file terakhir; BIN hilang → error | E2 | `startup_window.png`, `startup_corrupt.png` |
| EV-012 | Status bar `Hardware Not Found`/`DA: Not Connected` | E2 | Screenshot, `ui_commands.out` |
| EV-013 | XDF 1.70: header, region, tabel, axis, MATH | E1 | `04_BIN_AUTOPSY/WORK/K1AA-N03/30400-k1aa-n03.xdf` |
| EV-014 | 20 tabel K1AA, offset `0x3815E`, 35×29, 16-bit | E1/E2 | `K1AA-N03_TABLE_STATUS.csv`, `SELFTEST.txt` |
| EV-015 | 5.338 sel direproduksi, 0 mismatch | E1/E2 | `export_tps_rpm.csv`, `SELFTEST.txt` |
| EV-016 | SW Version/ECM ID terbaca | E1 | `SELFTEST.txt` |
| EV-017 | Checksum SUPRA region `0xFFF0`, store `0xFFF1` | E1 | `SUPRA-K41NC1.xdf`, `SELFTEST.txt` |
| EV-018 | Save menormalkan `0x00` → `0xFF` | E1/E2 | `CHECKSUM_DELTA_TEST*`, `SELFTEST.txt` |
| EV-019 | CBR butuh plug-in `IRON-PONY-RK`; Save gagal | E1/E2 | `CBR1000RR.xdf`, `cbr_save_error.png` |
| EV-020 | XDF terenkripsi magic `05 22 97 00`, marker `0x64`, cipher `0x84` | E1 | `ENC_XDF_CONTAINER.txt`, `SELFTEST.txt` |
| EV-021 | XDF terenkripsi hanya menampilkan header/kompatibel ECU | E2 | `encxdf_load.txt`, `encxdf_load.png` |
| EV-022 | ADX 40.199/23.780 B, entropy ~7,99 | E1 | `SELFTEST.txt`, `06_ADX_AUTOPSY/*` |
| EV-023 | ADX 11 baris, 9 gauge, 2 chart, history | E2 | `adx_lists_runtime.txt`, `adx_dash_runtime.txt`, `adx_monitors_runtime.txt`, `adx_history_runtime.txt` |
| EV-024 | Model perintah ADX (send/listen/silence/macro) | E3 | `STRINGS_ADXEditor.dll.txt` (deskripsi UTF-16) |
| EV-025 | Tidak ada string KWP/ISO/Honda di EXE | E3 | `STRINGS_TunerPro.exe.txt` |
| EV-026 | Warisan ALDL (kelas `ALDL*`) | E3 | `STRINGS_TunerPro.exe.txt` |
| EV-027 | Emulasi menolak BIN 65.536 B | E2 | `ui_commands.out` |
| EV-028 | PromIO: erase/blank/program/verify, alignment 64 | E3 | `STRINGS_PromIO.dll.txt` |
| EV-029 | Tidak ada string recovery/bootloader | E3 | `STRINGS_TunerPro.exe.txt` |
| EV-030 | 930 file dataset, 159.940.598 B | E1 | `DATASET_INVENTORY.csv` |
| EV-031 | 174 XDF: 13 plaintext, 161 encrypted; 3 ADX encrypted | E1 | `DATASET_COMPATIBILITY_MATRIX.csv`, `SELFTEST.txt` |
| EV-032 | 174 SAME_DIR, 3 NO_BIN | E1 | `DATASET_COMPATIBILITY_MATRIX.csv`, `matrix_stats.txt` |
| EV-033 | Cakupan tabel 13 XDF plaintext | E1 | `matrix_stats.txt` |
| EV-034 | Settings pengguna berubah karena probes | E1/E2 | `settings_snapshot.txt` |
| EV-035 | Tidak ada driver kernel/service | E1/E3 | Daftar file instalasi, `PE_*.json` |
| EV-036 | RevCore: checksum SUM 8-bit `(256-sum)&0xFF` | E1 | `HondaChecksum.kt` (dibaca, tidak diubah) |
| EV-037 | RevCore: frame `[header][len][service][params][checksum]` | E1 | `HondaFrameCodec.kt` |
| EV-038 | RevCore: live profiles & state | E1 | `LiveDataProfile.kt` |
| EV-039 | RevCore: FlashEngine default-deny | E1 | `FlashEngine.kt` |
| EV-040 | RevCore: RomBinary checksum/format | E1 | `RomBinary.kt` |
| EV-041 | RevCore: MapParser untuk image FlashPro | E1 | `MapParser.kt` |
| EV-042 | Prototipe PASS=53 FAIL=0 | E1 | `13_PROTOTYPES/OUT/SELFTEST.txt` |
| EV-043 | Menu dump 5.522 B | E2 | `03_RUNTIME_ANALYSIS/menu_tree_new.txt` |
| EV-044 | Preferensi interface `Use Plug-In`, emulator `TunerPro Emulator Interface` | E2/E3 | `preferences_dataacq.png`, `STRINGS_TunerPro.exe.txt` |
| EV-045 | ELM327 plugin 0.6.0 di folder pengguna | E1/E2/E3 | `APP_INVENTORY.csv`, `PE ELM327`, `about_plugins.png` |

---

## 3. Hierarki sumber

1. **File/hash** — tidak dapat dibantah tanpa mengubah file.
2. **Runtime** — dapat berubah antar sesi; screenshot/dump adalah snapshot.
3. **String binary** — menunjukkan keberadaan kode, bukan eksekusi.
4. **Inferensi** — hanya berlaku jika didukung E1–E3.

---

## 4. Artefak yang tidak dipakai sebagai bukti tunggal

| Artefak | Alasan |
|---|---|
| `menu_tree.txt` (0 byte) | Kosong; diganti `menu_tree_new.txt` |
| Log console yang tidak tersimpan | Tidak dapat diperiksa ulang |
| Recent files di settings | Hanya menunjukkan path, bukan isi |
| Nama file dataset | Tidak membuktikan isi (mis. “KEIHIN”) |

---

## 5. Verifikasi manifest

`15_EVIDENCE/EVIDENCE_MANIFEST.csv` memuat 161 baris data `path,bytes,sha256` (dihitung ulang setelah penyuntingan akhir laporan 01, 02, dan 05) untuk:

- 19 laporan final (01–19) dan README.
- Sumber prototipe (`Program.cs`, `.csproj`) dan output (`SELFTEST.txt`, matriks).
- Skrip eksperimen (`03_RUNTIME_ANALYSIS/*.ps1`, `11_EXPERIMENTS/*.ps1`).
- Dump runtime dan screenshot.
- JSON/strings PE.

Tidak termasuk: salinan aplikasi (179 MB) dan salinan dataset, karena hash-nya sudah ada di `APP_INVENTORY.csv`/`DATASET_INVENTORY.csv`.

---

## 6. Keyakinan indeks

| Aspek | Keyakinan |
|---|---|
| Ketertelusuran klaim utama | TINGGI |
| Kelengkapan artefak | TINGGI untuk file; SEDANG untuk dialog yang tidak diuji |
| Keakuratan hash | TINGGI (dihitung ulang saat manifest) |
