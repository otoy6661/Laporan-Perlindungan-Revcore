# Katalog String — FLASHPRO (2.082 literal `#US`)

**Sumber:** heap `#US` dari metadata assembly `FLASHPRO` (runtime). Salinan lokal: `03_RUNTIME_ANALYSIS/E01_FIRST_LAUNCH/STRINGS_REDACTED.txt` (telepon/WA/email, password update, dan salt lisensi sudah disamarkan).
**Status:** SOURCE VERIFIED. Literal string membuktikan **adanya** fitur/pesan, bukan cara kerjanya.

---

## 1. Distribusi kategori

| Kategori | Contoh kunci | Jumlah/rentang baris | Catatan |
|---|---|---:|---|
| Identitas & disclaimer | `FLASHPRO ECM MANAGER`, `TEAM TECH TUNNER`, `itech © 2025`, `REMAP ECU ©2026` | 123–145, 375–391 | About + splash |
| Daftar kendaraan | `Honda VARIO 125 Series` … 29 seri | 431–487 | termasuk `Other Series` |
| Nama BIN database | `FLASHPRO.BeAT110-38770-K25-901.bin` … | 650–809 | 160 nama → `BIN_CATALOG.csv` |
| Part code | `30400-K0WA-N01` … | 1805–1838 | 157 unik di aplikasi; 333 baris di CSV |
| Map editor | `Tambah Value`, `Kurangi Value (%)`, `Fill / Set Value`, `Interpolasi (%)`, `COMPARE MODE ON`, `Save Value` | 839–905 | operasi sel tabel |
| Flash | `Konfirmasi Flash ECU`, `WRITE FLASH COMPLETE`, `WRITE FLASH FAILED!`, `Erasing flash failed`, `CompareMemory` (metode), `Verifikasi Data...` | 396–425, 2016 | pesan pipeline |
| Recovery | `Mode Recovery ECM`, `ECM Recovery Mode`, `Unknown !Please Restart ECM`, `BAD Flash ! Please Restar ECM` | 399–422 | ada alur recovery eksplisit |
| Seed/Key | `Failed challenging Seed/Key`, `Failed generating Seed/Key` | 411–412 | tidak ada nilai kunci di string |
| Checksum | `Checksum`, `TbChecksumOffset`, `TbStartOffset`, `TxtFlashCount` | 396, 916–917 | kontrol offset/checksum |
| Live data | `Response dat10:`, `Response 11/13/16/17`, satuan `RPM`, `°`, `°C`, `ms`, `km/h` | 298–330 | tabel parameter lengkap di 184–220 |
| DTC | 37 pasangan kode–deskripsi | 225–296 | `DTC_CODES.csv` |
| Diag | `Reset ECM`, `Reset ECM Berhasil`, `STOP` | 331–349 | |
| DYNO | `Simple Dyno`, `Max HP`, `RPM at Max HP`, `Max TQ`, `AFR` | 353–370 | |
| Smartkey/EEPROM | `Connect to SCU`, `COPY SCU`, `Verify done. Mismatch:`, `No ACK dev (WRITE)`, `READ ID KEYLESS`, `YAMAHA TMAX`, `SUZUKI` | 1550–1719, 1851–1963 | I2C, multi-merek |
| Kunci/konversi | `Last 6 Octal Digits:`, `After Adding 111111:`, `Reversed Result:` | 1550–1552 | langkah konversi (fungsi belum terverifikasi) |
| Lisensi | `License Activation`, `ID License`, `Register`, `Lisensi tidak valid`, `SELECT SerialNumber FROM Win32_BaseBoard`, `UNKNOWN_MB` | 1721–1781 | analisis saja |
| Registry | `Software\Win32Sub\SystemCtrl`, `SysCFG`, `Software\Win32Sub\SystemApp` | 858–862 | HKCU |
| HWID | `Win32_Processor/ProcessorId`, `Win32_BIOS/SerialNumber`, `Win32_DiskDrive` | 853–857 | |
| Read ECU | `read48k.log`, `READING DATA FROM MCU`, `RESET FLASH`, `Flash Count`, `[DEBUG] Balasan`, log `replySize <=` | 1782–1804 | 48 KB |
| Updater | URL `raw.githubusercontent.com/flashpro2025/hondaflashprokline/…json`, `FLASHPRO-Updater/1.0`, `version.txt`, `staging`, `update.zip`, `Auto Update.exe`, `runas`, pesan validasi ZIP/path traversal | 1964–2079 | |
| Pengaturan | `SkipReadIdTutorial`, `SkipAboutOnStartup`, `lblPrompt` | 2009–2010 | |
| Crypto | `SHA256`, empat literal hex hardcoded (`[REDACTED_CRYPTO_LITERAL]`), `public_encrypted` | 372–373, 850–852, 2001 | kunci hardcoded — **nilai tidak direproduksi di laporan publik** |

## 2. String yang TIDAK ada (penting)

- Tidak ada `System.IO.Ports`/`SerialPort`/`COM3`/nama port → transport bukan serial VCP.
- Tidak ada nama fungsi D2XX di string (hanya P/Invoke, lihat `PINVOKE.tsv`).
- Tidak ada URL HTTP selain feed GitHub update (tidak ada telemetri/aktivasi online).
- Tidak ada `datD1`/`dat12`/`dat14` sebagai string — `datD1` hanya nama metode `Diag.datD1`.
- Tidak ada frame contoh, seed/key literal, atau tabel checksum di string.
- Tidak ada "CAN", "ELM327", "J2534", "UDS", "KWP2000".

## 3. Batas

String menunjukkan **kosakata** aplikasi. Ia tidak membuktikan urutan frame, nilai seed/key, polinomial checksum, atau rumus konversi volt→nilai. Semua itu tetap **NOT VERIFIED** tanpa IL/hardware (lihat `08_CHECKSUM_AUTOPSY`, `04_PROTOCOL_AUTOPSY`).
