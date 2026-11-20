# RESEARCH EVIDENCE INDEX

Work order §7–§8. Indeks sumber, hash, artefak, dan metode agar setiap temuan
dapat ditelusuri.

Semua pekerjaan **READ-ONLY**. Tidak ada file sumber yang diubah, tidak ada ZIP,
tidak ada publikasi/Git push.

---

## 1. Sumber primer

| ID | File | SHA-256 | Ukuran | Peran |
|---|---|---|---|---|
| S1 | `C:\Program Files (x86)\H-Diag\HDiag.exe` (salinan: `input\HDiag.exe`) | `10100b3491b056942aeb9e74ed604131a51c8445aea071bd0cace7270f265dcf` | 175.104 B | Aplikasi diagnostik PC |
| S2 | `C:\Users\Lord Otoy\Documents\Qoder\FLASHPRO_FTDI_MOD\00_BASE\FLASHPRO_1.0.apk` | `9fff9691225011acfc42a195cf1219cf0e1bfbae876eca2809941388c09714b0` | — | Aplikasi Android FlashPro |
| S3 | `C:\Users\Lord Otoy\Documents\Qoder\work\revcore\docs\flashpro\firmware.bin` | `fe0704fd322d2c981ab029faf63d7463a4d7521cc912e18fa411252e286b65e1` | — | Firmware ESP32 (Xtensa) |
| S4 | `…\REVCORE_FLASHPRO_RECONSTRUCTION\00_SOURCE_INVENTORY\MASTER\firmware.signed.flash` | `97ca99e9001d94cf0b16c70b684d755d490400d6cfa874c7d27341175df09508` | — | Image tertandatangani |
| S5 | `…\work\REVCORE_KEYLESS_20261120\RevCore_work` | — | — | Source RevCore yang diaudit (tidak diubah) |
| S6 | `dispatcher_full.c.txt` | — | — | Dekompilasi dispatcher FlashPro |

Salinan S4 di `work\revcore\docs\flashpro\` memiliki hash identik; tidak ada
perbedaan isi.

---

## 2. Alat dan proyek

| Alat | Lokasi | Catatan |
|---|---|---|
| Ghidra 12.2 headless | `C:\Users\Lord Otoy\Desktop\ghidra_12.2_PUBLIC\support\analyzeHeadless.bat` | Dijalankan via `powershell.exe -NoProfile -Command "& '...' "` |
| Proyek FlashPro | `C:\Users\Lord Otoy\Documents\Qoder\flashpro_ghidra\RevCoreFP` | program `firmware.elf` (Xtensa LE) |
| Proyek H-Diag | `ghidra_hdiag\HDiagProj` | program `HDiag.exe` |
| Skrip | `ghidra_scripts\DumpKeyless.java`, `DumpBytes.java`, `DumpTable.java`, `DumpHDRefs.java` | Dekompilasi fungsi, dump pointer, tabel 27 model, xref string |
| Disassembler teks | `disasm_hdiag.py` | Dump instruksi H-Diag |

Catatan Ghidra 12: `getStringAt` sudah tidak ada; skrip memakai
`getDataAt`/`getDataContaining` + `hasStringValue()`, dan import `Data` dari
`ghidra.program.model.listing`.

---

## 3. Log dan artefak bukti

| File (`evidence\`) | Isi | Dipakai di |
|---|---|---|
| `ghidra_keyless_core.log` | handler, dispatcher, gerbang fitur | FLASHPRO… |
| `ghidra_keyless_decomp.log` | dekompilasi Read/Auto/Reset | FLASHPRO… |
| `ghidra_keyless_read.log` | rutin baca 256 alamat | FLASHPRO… |
| `ghidra_smk_table.log` | tabel 27 model + konstanta | FLASHPRO… |
| `ghidra_hdiag_import.log` | import PE berhasil | HDIAG… |
| `ghidra_hdiag_refs.log` | xref string/label | HDIAG… |
| `hdiag_full_text.txt` | disassembly H-Diag | HDIAG…, matrix, FTDI |
| `hdiag_402000_403600.txt` | jendela UI/loop awal | HDIAG… |
| `hdiag_403300_404600.txt` | helper/loop | HDIAG… |
| `hdiag_helper_406ad0.txt` | fungsi pengisi baris | HDIAG… |
| `HDiag_main.ascii.txt` | simbol fungsi utama | HDIAG… |
| `HDiag_comma.ascii.txt` / `.unicode.txt` | string | HDIAG… |
| `EVIDENCE_NOTES_FLASHPRO_KEYLESS.md` | ringkasan fakta Keyless | FLASHPRO… |

---

## 4. Peta klaim → bukti

| Klaim | Bukti | Kelas |
|---|---|---|
| 25 model H-Diag | string combo `0x412ec4..0x412fac` | A |
| 46 label parameter | xref `FUN_00401710` | A |
| Tiga frame live H-Diag | loop `0x407329`, helper `0x409af0` | A |
| 100 ms / siklus 15 | `push 0x64`, `cmp eax,0xC/0xD/0xE` | A |
| DTC frames H-Diag | disassembly jalur DTC | A |
| Dictionary DTC Indonesia | string `0x4126d0` dst. | A |
| Keyless handler | dispatcher baris 926–938 | A |
| Handshake Keyless | `FUN_400e5574` | A |
| 256 alamat | `FUN_400e52d4`, `FUN_400e541c` | A |
| 27 model Keyless | `DumpTable.java` | A |
| Transform mode 0/1 | `FUN_400e4470` | A |
| RevCore 7 tabel | `LiveDataProfile.kt` | A |
| RevCore delapan field | `LiveTelemetry.kt`, `parseLiveFrame` | A |
| RevCore routing keluarga | `HondaProtocolEngine`, `EcuSessionManager` | A (kode), B (perilaku) |
| RevCore Keyless terbatas | `KeylessReadEngine` loop | A |

---

## 5. Batas metode

1. **Statis saja.** H-Diag tidak dijalankan; tidak ada observasi UI langsung.
2. **Tanpa ECU.** Tidak ada kelas D. Tidak ada klaim "audit hardware selesai".
3. **Lisensi H-Diag tidak dibongkar.** Tidak ada upaya melewati Chip-ID.
4. **Fungsi tulis Keyless tidak dianalisis.** Batas etika work order.
5. **Pemetaan per model H-Diag** tidak selesai; konstanta dan label ada, subset
   tidak.
6. **Perbandingan transform Keihin** tidak dapat diputuskan tanpa known-answer
   test.

---

## 6. Cara mereproduksi

1. Import `input\HDiag.exe` ke proyek Ghidra `HDiagProj`.
2. Jalankan `DumpHDRefs.java` untuk daftar string/xref.
3. Buka `0x407329` untuk loop live; `0x406ad0` untuk pengisi baris;
   `0x401710` untuk builder label.
4. Import `firmware.elf` ke `RevCoreFP`; jalankan `DumpKeyless.java` dan
   `DumpTable.java`.
5. Bandingkan hasil dengan log di `evidence\`.

---

## 7. Peta dokumen

| Dokumen | Isi |
|---|---|
| `REVCORE_FULL_REFERENCE_AUDIT.md` | Laporan induk |
| `HDIAG_PC_FULL_CAPABILITY_REPORT.md` | H-Diag |
| `HDIAG_LIVE_DATA_PARAMETER_MATRIX.md` | Matriks parameter H-Diag |
| `FLASHPRO_KEYLESS_ID_RESEARCH.md` | Keyless FlashPro |
| `FTDI_KLINE_COMPATIBILITY_REPORT.md` | Kelayakan FTDI per lapisan |
| `REVCORE_IMPLEMENTATION_GAP_ANALYSIS.md` | RevCore + gap matrix |
| `RESEARCH_EVIDENCE_INDEX.md` | Dokumen ini |
| `UNRESOLVED_FINDINGS_AND_RISKS.md` | Temuan terbuka dan risiko |
