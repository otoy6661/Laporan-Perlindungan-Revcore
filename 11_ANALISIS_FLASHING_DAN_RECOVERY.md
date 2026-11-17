# 11 — ANALISIS FLASHING & RECOVERY

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Pertanyaan inti:** apakah TunerPro RT dapat menulis/reflash ECU Honda, dan bagaimana recovery-nya?
**Status:** SELESAI — jawaban berbasis bukti struktur, string, dan uji runtime tanpa perangkat.

---

## 1. Kesimpulan utama

**TunerPro RT bukan ECU flasher.** Tidak ada jalur erase/write/verify ECU di executable utama, tidak ada bootloader, dan tidak ada rutin recovery ECU. Yang disebut “flash” di produk ini adalah:

1. **Pemrograman chip** PROM/EEPROM/Flash memori lepas (via `PromIO.dll` dan programmer Moates).
2. **Upload ke emulator RAM** (Ostrich/Quarterhorse/RoadRunner) untuk live tuning.
3. **Upload firmware/perangkat** ke AutoProm (bukan ECU).

Tidak ada bukti bahwa salah satu jalur tersebut mengirim perintah erase/write ke ECU Honda.

---

## 2. Bukti tidak adanya jalur ECU flash

| Bukti | Sumber |
|---|---|
| Tidak ada string `recover`, `brick`, `bootloader`, `boot mode` | Pencarian string `TunerPro.exe` |
| Tidak ada perintah ECU erase/write; `EraseDataFlash` adalah data flash perangkat | `MMAutoProm: EraseDataFlash requested` |
| Operasi verify hanya “emulator contents”/“hardware against current bin” | `Verify Emulator Contents Against Current Bin`, `Verify Hardware Against Current Bin` |
| Menu Emulation hanya Upload/Download/Verify/Live Tuning | Dump menu runtime |
| Tidak ada state machine flashing di UI | Tidak ada dialog progres write/erase ECU |
| Tidak ada timeout/retry ECU, tidak ada seed-key | Tidak ada string terkait |

Sebagai pembanding, RevCore memiliki `FlashEngine` dengan state `IDLE → … → WRITE_ENABLED → WRITING → VERIFYING → COMPLETE/FAILED/RECOVERY_REQUIRED`, tetapi semua `FlashCapabilities` bernilai `false` dan tidak ada metode transmit. TunerPro bahkan tidak memiliki state machine tersebut.

---

## 3. Jalur pemrograman chip (`PromIO.dll`)

### 3.1 Operasi yang tersedia

Dari string UI dan pesan:

| Operasi | Bukti |
|---|---|
| Erase Chip / Sector / Bank | `Erase Succeeded`, `Sector Erase Succeeded`, `Bank Erase Succeeded` + pesan FAILED |
| Blank Check | `Chip is blank` / `Chip NOT blank`; sector/bank |
| Program dari buffer | `Programming Device from buffer...` |
| Read device ke buffer | Operasi baca perangkat |
| Verify terhadap buffer | `Verifying device against buffer...`; `Chip Verify failed at offset 0x%.6X. Local Buffer: 0x%.2X. Chip: 0%.2X` |
| Proteksi alignment | `Chip start address must be divisible by 64`, `Chip memory range must be divisible by 64`, `Source memory range should be divisible by 64` |
| Dukungan hardware | `Hardware does not support burning!` |

### 3.2 Perangkat yang didukung

`29F010`, `29F020`, `29F040`, `2732A`, `27C010`, `27C128`, `27C256`, `27C512` (Read-Only), serta programmer `BoostedNW Burner`, `Flash & Burn`, `Destiny Programmer`, `F2E Ford EEC-IV/V Reader`.

**Risiko:** operasi ini dapat merusak chip memori lepas jika tegangan/timing salah. Tidak ada hubungan dengan ECU tertutup; chip harus dicabut atau memakai soket.

---

## 4. Jalur emulator (live tuning)

| Operasi | Perilaku terbukti |
|---|---|
| Upload Current Bin To Hardware (32897) | Ditolak lebih awal: `FAILURE: Bin is larger than emulation RAM! Perhaps you meant to use bank 8?` untuk BIN 65.536 B |
| Download Bin From Hardware (32904) | Pesan sama (ditolak karena ukuran) |
| Verify Hardware Against Current Bin (32899) | Pesan sama |
| Download Bin to File (32903) | Tersedia di menu; tidak diuji |
| Enable Live Tuning (32900) | Tanpa efek/dialog tanpa hardware |

**Ambang ukuran:** BIN tepat 65.536 B sudah ditolak, sehingga emulation RAM yang dapat dialamatkan < 64 KB untuk konfigurasi default (atau bank 0). Opsi “bank 8” menunjukkan mode banking, bukan RAM lebih besar.

### 4.1 Mode perangkat

String mengungkap mode: `Quarterhorse`, `RoadRunner` (`Set Emulation Mode Succeeded: Mode %c`), `Ostrich`, `Ostrich II`, `Demon2`, `FlashOnline`, `Superlogger`, `AutoProm`.

**Penting:** emulator menggantikan chip memori ECU, bukan menulis flash ECU. Salah upload dapat membuat engine berperilaku salah, tetapi tidak “membrick” ECU—cukup lepaskan emulator.

---

## 5. Logger onboard

`MoatesOnboardLogger.dll`:

- Membaca sesi dari dump memori flash perangkat.
- Menampilkan memori terpakai %, nomor sesi.
- Sesi korup → `session parse failed/corrupt`.
- Syarat: ADX harus memiliki perintah loggable dengan ukuran paket cocok.
- Aksi: `Export Session To XDL`, `Erase Onboard Memory`, `Begin Logging on Powerup`, `Headless Logging`, `Output Log Path`.

Ini logging, bukan flashing ECU.

---

## 6. Recovery

| Skenario | Kemampuan TunerPro | Bukti |
|---|---|---|
| Chip salah program | Program ulang/erase jika chip masih dikenali | Operasi PromIO |
| Emulator salah upload | Upload ulang dari BIN | Menu Emulation |
| Perangkat tidak terdeteksi | Tidak ada recovery; hanya error port | `MMSerial` error |
| ECU brick saat reflash | **Tidak ada** jalur recovery | Tidak ada bootloader/string recovery |
| Checksum ECU salah | Hanya menghitung ulang checksum file, bukan memulihkan ECU | XDF checksum |

**Kesimpulan:** TunerPro tidak dapat menjadi jalur pemulihan ECU. Klaim recovery ECU harus ditolak.

---

## 7. Uji runtime tanpa perangkat

Semua perintah hardware diuji dengan BIN 65.536 B dan tanpa adaptor:

1. Upload/Download/Verify → pesan 64 KB (validasi host).
2. Initialize/Release → senyap, status `Hardware Not Found`.
3. Live Tuning → senyap.
4. System Check → “All is well!” (hanya memeriksa konfigurasi internal, bukan hardware).

Tidak ada percobaan komunikasi yang terlihat; tidak ada dialog progres.

---

## 8. Perbandingan dengan RevCore

| Aspek | TunerPro RT | RevCore |
|---|---|---|
| Tulis ECU | Tidak ada | `FlashEngine` default-deny, belum terbukti |
| Verifikasi ECU | Hanya emulator | Direncanakan, belum ada |
| Recovery | Tidak ada | State `RECOVERY_REQUIRED`, tanpa rutin |
| Chip programming | Ya (PromIO) | Tidak ada |
| Emulator RAM | Ya (Moates) | Tidak ada |
| Checksum file | Ya (XDF) | Ya (`RomBinary`/HondaChecksum) |
| Gerbang bukti | Tidak ada | `FlashCapabilities` semua false |

**Klasifikasi:** **NOT FOUND** untuk flashing ECU di TunerPro; **DIFFERENT IMPLEMENTATION** untuk checksum file; **SAME FRAME FAMILY** hanya pada konsep upload/verify emulator (bukan ECU).

---

## 9. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Tidak ada ECU flash di core | TINGGI (string + menu + runtime) |
| Operasi chip PromIO | TINGGI (string UI) |
| Ambang emulation RAM | TINGGI untuk penolakan 65.536 B; SEDANG untuk angka pastinya |
| Recovery ECU | TINGGI (tidak ada bukti) |
| Perilaku dengan perangkat nyata | RENDAH (tidak diuji) |
