# H-Diag 2.1 — Autopsy Report

Work order: REVCORE REFERENCE AUTOPSY — BAGIAN I
Analyst: Kodir
Date: 2026-11-19
Source: `C:\Program Files (x86)\H-Diag` (read-only reference)

## 1. Ringkasan eksekutif

H-Diag 2.1 adalah aplikasi diagnostik Windows 32-bit berbasis Qt 5 yang berkomunikasi dengan ECU Honda melalui K-line memakai chip FTDI (libusb backend). Aplikasi ini **tidak dimodifikasi, tidak dijalankan terhadap ECU, dan tidak dijadikan basis RevCore**.

Temuan utama:

1. H-Diag memakai keluarga frame K-line yang sama dengan bahan 3D Chart: `[0x72][len][fn][sub][param...][checksum]`, dengan checksum `((sum8 ^ 0xFF) + 1) & 0xFF`.
2. Tabel Live Data H-Diag memuat label yang diminta RevCore 4–10: `STF`, `POM`, `SS`, `STS`, `SSW`, `FIS`, `MOD`, `ALT`, `IAC`.
3. Loop polling live data terbukti mengirim `72 05 60 03 26` (11 kali), lalu `72 05 71 00 18`, lalu `72 05 00 F1 98`, dengan jeda 100 ms.
4. Pemetaan byte respons ke **seluruh** baris tabel belum berhasil direkonstruksi. Yang terbukti: baris IAC (row 0x0C) diambil dari teks respons offset `+0x0D` pada salah satu cabang dispatch; beberapa baris lain (0x0F, 0x1B, 0x1E) pada cabang lain.
5. Tidak ditemukan string `FID`, tidak ditemukan label `Relay`; yang ada hanya `Switch Starter` (STS/SSW). Klaim "Starter Relay" dan "FISV/FID" **belum terbukti** dari H-Diag saja.
6. Tidak ditemukan perintah penulisan/pengaturan Altitude Mode. H-Diag hanya membaca `MOD`/`ALT`.

## 2. Inventaris

| Item | Nilai |
|---|---|
| Jumlah file | 29 |
| Total byte | 53,819,379 |
| Executable utama | `HDiag.exe` 175,104 B, PE32 x86, image base `0x400000` |
| Kembar/variant | `HDiag.exe,` 313,426 B (layout PE berbeda) |
| Runtime | Qt5Core/Gui/Network/Qml/Quick/USB0/Widgets, ICU 52, MSVCP110/MSVCR110 |
| Transport | `libusb-1.0.dll`, `usb_driver/` (WinUSB + libusb INF, x86/amd64) |
| Lisensi | `login.ini` 141,022 B (daftar kode lisensi; isi tidak dipublikasikan) |
| Manifest | `asInvoker` |

Inventaris lengkap: `00_INVENTORY/SOURCE_INVENTORY.csv` (kolom source, relpath, bytes, sha256, mtime_utc).

## 3. Arsitektur aplikasi

```
MainWindow (Qt)
 ├─ select_type / setup_table        pilih model & isi tabel
 ├─ connect_clicked                 buka FTDI, handshake
 ├─ kline_command                   bangun & kirim frame
 ├─ print_data / print_table        tulis hasil ke QTableWidget
 ├─ mil_action / cleardtc_clicked   baca & hapus DTC
 └─ closeEvent                      tutup handle

UsbSerial
 ├─ findFtdi / ftdiSetDesc
 ├─ Connect / Disconnect / testConnection
 ├─ writeData / writeDataHex / writeDataBit
 ├─ readData / readDataHex
 ├─ logindialog                     validasi login.ini
 └─ delay
```

Nama fungsi di atas berasal dari string simbol/metode di binary (STATIC VERIFIED). Alamat pasti beberapa di antaranya belum dipetakan satu-per-satu.

## 4. Alur eksekusi yang berhasil direkonstruksi

1. **Login**: `login.ini` dibaca; kode lisensi 10 karakter Base62 (11.754 entri) dicocokkan. String error: `Invalid version or not a cyphertext.`, `No key set.`
2. **Pilih kendaraan**: daftar model (SCOOPY … CBR250 NEW/CRF250) mengisi tipe tabel.
3. **Connect**: buka FTDI, atur K-line, kirim handshake, tampilkan `Connected.` / `Connected-Engine Off` / `Connected-Engine On`.
4. **Live data**: loop counter 0..0x0E; 11 frame A, 1 frame B, 1 frame C; baca respons; tulis ke tabel; ulang.
5. **DTC**: tombol MIL mengirim halaman DTC 0..5, memformat kode desimal, menampilkan `DTC Code:`; clear DTC memakai frame `72 05 60 01 28` (lihat laporan protokol).
6. **Disconnect**: tutup handle.

## 5. Fakta vs rekonstruksi vs dugaan

| Tingkat | Isi |
|---|---|
| FAKTA (string/konstanta di binary) | Label tabel; frame live A/B/C; frame DTC 0..5; checksum aritmetik; `login.ini`; Qt/FTDI |
| REKONSTRUKSI (disassembly) | Urutan polling 100 ms; dispatch respons per kunci 8/0x14/0xC/7; update baris 0x0C/0x0F/0x1B/0x1E; handshake parsial |
| DUGAAN | Arti kunci dispatch (kemungkinan tipe/length respons); pemetaan baris lain |
| SIMULASI | Tidak dilakukan |
| UJI PERANGKAT | Tidak dilakukan |
| UJI ECU | Tidak dilakukan |

## 6. Keterbatasan

- Tidak ada source code; semua mekanisme internal diturunkan dari disassembly.
- Binary di-obfuscate ringan (nama class `Class15`, `Enum5`, string login terenkripsi), sehingga sebagian call graph tidak dapat dipastikan.
- `HDiag.exe,` memiliki tata letak section berbeda; pencarian pointer gagal dan tidak diulang.
- `login.ini` tidak dianalisis isinya karena merupakan data lisensi sensitif.
- Tidak ada ECU/perangkat fisik yang terhubung; tidak ada TX/RX nyata yang direkam.

## 7. Kepatuhan batas kerja

- H-Diag tidak dimodifikasi.
- Tidak ada aplikasi baru dibuat.
- Tidak ada source RevCore yang diubah.
- Tidak ada kaitan dengan FlashPro.
- Bahan asli tidak dihapus/ditimpa.
- Tidak ada credential/token yang dipublikasikan.

## 8. Artefak

- `03_EVIDENCE/HDIAG_STATIC_EVIDENCE.md` — register bukti alamat/string.
- `03_EVIDENCE/PROTOCOL_FRAME_VALIDATION.csv` — verifikasi checksum semua frame.
- `01_HDIAG/STRINGS_HDiag.exe.tsv` — 1.863 string ASCII.
- `01_HDIAG/STRINGS_HDiag.exe_comma.tsv` — 2.921 string (varian ekstraksi).
