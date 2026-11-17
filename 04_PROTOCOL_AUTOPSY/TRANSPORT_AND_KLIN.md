# Transport & K-Line — Apa yang Benar-Benar Dipakai FLASHPRO

**Status:** SOURCE VERIFIED (API P/Invoke + kelas pembungkus) · RUNTIME VERIFIED (driver terpasang) · **HARDWARE: BLOCKED** (tidak ada adaptor terhubung).

---

## 1. Satu-satunya jalur I/O perangkat: FTDI D2XX

`PINVOKE.tsv` hanya memuat `ftd2xx.dll` (12 fungsi unik) ditambah `user32/gdi32` untuk efek UI:

```
FT_Open, FT_Close, FT_Read, FT_Write, FT_GetQueueStatus,
FT_SetBaudRate, FT_SetDataCharacteristics, FT_Purge,
FT_SetTimeouts, FT_SetLatencyTimer, FT_SetBitMode, FT_GetBitMode
```

Tidak ada `System.IO.Ports`, tidak ada `SerialPort`, tidak ada `CreateFile("\\.\COM…")`. Artinya:

- FLASHPRO **tidak** memakai COM port meskipun driver VCP memasang COM5/COM8 (lihat §4).
- Semua trafik K-Line/ISO melewati D2XX langsung (bit-bang atau UART), sehingga aplikasi mengendalikan timing sendiri.

## 2. Dua pembungkus, dua mode

| Kelas | Fungsi yang diekspos | Mode | Dipakai oleh |
|---|---|---|---|
| `Class15` (12 metode) | Open/Close/Read/Write/QueueStatus/SetBaudRate/SetDataCharacteristics/Purge/SetTimeouts/SetLatencyTimer/SetBitMode | **UART/ISO** (frame dikirim sebagai byte; timing oleh FTDI) | `Form1.InitClass15Iso`, `Diag.InitFtdiIso`, `ReadECU.InitFtdiIso`, `Reset.InitFtdiIso`, `SMK.InitFtdiIso` |
| `Class155` (15 metode) | Open/Close/SetBitMode/SetBaudRate/Write/**GetBitMode**, `OpenByIndex`, `GetPinStates`, `Dispose` | **bit-bang** (pin digerakkan manual) | `Form11` (I2C EEPROM/SCU), inisialisasi awal K-Line |

Nama metode di `Class155` (`GetPinStates`, `SetBitMode`) menunjukkan pembacaan level pin langsung — pola khas K-Line *slow init* 5-baud dan I2C SCL/SDA.

## 3. Parameter yang tidak terbaca (jujur)

Nama metode membuktikan **adanya** set baud, data characteristics, timeout, latency, dan bit mode — tetapi **nilai**-nya (mis. 10400 baud? 8N1? invert?) tidak ada di metadata dan IL tidak dapat diambil. Semua angka baud/format/tegangan berstatus **NOT VERIFIED**.

## 4. Bukti lingkungan (runtime)

| Item | Hasil | Status |
|---|---|---|
| `C:\Windows\System32\ftd2xx.dll` | versi **3.2.21.1**, FTDI Ltd. | RUNTIME VERIFIED |
| `C:\Windows\SysWOW64\ftd2xx.dll` | versi 3.2.21.1 | RUNTIME VERIFIED |
| Layanan `ftdibus` | Manual, **Stopped** (normal saat tidak ada perangkat) | RUNTIME VERIFIED |
| Perangkat FTDI historis | `USB\VID_0403&PID_6001\A5069RR4` (USB Serial Converter) dan `A50285BI` (**FT232R USB UART**, terikat kelas `libusb-win32 devices`) — keduanya `Present=False` | RUNTIME VERIFIED |
| Adaptor terhubung saat analisis | **tidak ada** | RUNTIME VERIFIED |

Catatan penting: keberadaan entri `libusb-win32` pada salah satu FT232R menunjukkan perangkat yang sama pernah dipakai oleh tool lain. FLASHPRO sendiri hanya memanggil `ftd2xx.dll`, jadi ia memerlukan driver D2XX (bukan libusb) pada perangkat yang dipakai.

## 5. K-Line: bukti tidak langsung yang kuat

- String tutorial: "KUNING ➜ K-Line ECU", "HITAM ➜ GND ECU", "MERAH +12V PSU ➜ +12V ECU" → adaptor 3 kabel, tanpa RX/TX terpisah.
- Prosedur "MATIKAN KUNCI KONTAK OFF / HIDUPKAN OFF-ON" → sinkronisasi ECU saat init.
- `Please Turn OFF` (Keihin) vs `Please Turn OFF - ON` (Shindengen) → dua urutan init berbeda per vendor ECU.
- `Response dat10:` / `Response 11/13/16/17` → pertukaran frame request–response.

## 6. Yang tidak dapat diklaim

- **Tidak ada RAW RX CAPTURE.** Tidak ada log byte dari ECU pada workspace ini (file `read48k.log` hanya ditulis saat operasi nyata).
- Oleh karena itu **tidak ada satu frame pun** yang boleh ditulis di laporan sebagai "frame FLASHPRO" tanpa label simulasi/ referensi silang.
- Kecepatan, header, checksum frame, dan timing init tetap **NOT TESTED** sampai ada adaptor + ECU.

## 7. Implikasi untuk RevCore

RevCore sudah memiliki transport Android USB-serial + framing Honda (BE-11). Perbedaan arsitektural yang terbukti: FLASHPRO memakai **D2XX langsung dari Windows**, termasuk bit-bang; RevCore memakai jalur USB-serial Android. Ini bukan keunggulan fungsional, melainkan konsekuensi platform — dicatat sebagai perbedaan, bukan nilai.
