# 10 — ANALISIS PROTOKOL KOMUNIKASI

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Cakupan:** transport serial, model perintah/paket ADX, checksum, timeout, error perangkat
**Status:** SELESAI DENGAN KETERBATASAN — arsitektur protokol direkonstruksi dari definisi ADX dan string biner. **Tidak ada frame ECU yang ditangkap.**

---

## 1. Lapisan transport

| Aspek | Bukti | Keterangan |
|---|---|---|
| API | `SetCommState`, `SetCommTimeouts`, `GetCommState`, `GetCommTimeouts`, `PurgeComm` | Serial port Win32 |
| Pembuka | `MMSerial: Successfully opened %s` / `Open Port %s Failed` | Nama port dari setelan (`\\.\COM1`) |
| Baud | default di header ADX; dapat diubah per perintah (`baud=0` → default) | Deskripsi field ADX |
| Parity / stop bits / byte size | field ADX | Dikonfigurasi per definisi |
| Echo | `RS232 Echo` di ADX | Untuk kabel TX/RX yang disatukan |
| Pembersihan buffer | `Purge the receive FIFO buffer`, `Purge the transmit FIFO buffer` per perintah | Deskripsi ADX |

TunerPro tidak menetapkan satu baud Honda. Baud adalah properti definisi. Ini berbeda dari RevCore yang menetapkan 10.400 (kandidat 9.600/10.400) di `HondaEcuProfiles`.

---

## 2. Model paket ADX (deskripsi resmi dari binary)

Kutipan berikut berasal dari string deskripsi `ADXEditor.dll` (UTF-16), sehingga merupakan penjelasan yang dipakai editor sendiri:

- **Tipe paket:** “Static size means each packet is the same size, variable uses the distance between header or footer to determine packet size, and GM 160 baud is a special packet type specific to certain GM vehicles.”
- **Header/footer:** “Reply header byte string for the scanner to either listen for or verify.” / “Reply footer byte string…”
- **Body vs payload:** “This is the total size of the body of the reply, not including header or footer.” / “This is the size of the payload alone… contains parametric data.”
- **Offset payload:** “This is the offset to the first byte of the payload in the reply body.”
- **Timeout:** “This is the maximum time the scanner should spend listening for this reply.”
- **Reply processing:** “Select this to have the reply processed and the results sent to the other ADX items. The reply is discarded if this is not set.”
- **Static + header:** “If the payload type is of static size, and a reply header is specified, select this to specify that the scanner should listen for the header and, once identified, read the body and footer of specified sizes.”
- **Silence:** “The engine will monitor for a gap in data that lasts this amount of time. Set to 0 to pause for `<timeout>` milliseconds.”
- **Echo:** “Select if the cable or interface being used has the transmit and receive lines tied together, such that sent command also appears in the receive buffer.”

**Implikasi:** protokol TunerPro adalah **mesin transaksi generik**: kirim byte, tunggu header, baca body/footer, ekstrak payload, hitung nilai. Ia tidak mengandung pengetahuan Honda; semua kekhususan ada di ADX.

---

## 3. Perintah kirim

| Field/perilaku | Bukti |
|---|---|
| Byte string hex | “The byte string to send. Enter hex bytes separated by spaces.” |
| Checksum perintah | `SNDCMDCHECKSUM`; debug string `bChecksumCommand =%i;` |
| Purge sebelum kirim | checkbox RX/TX FIFO |
| Proses balasan | checkbox “reply processed…” |
| Perintah koneksi/monitor/disconnect | field header ADX; dapat berupa macro |
| Pause/unpause | field ADX; dapat berupa macro |
| Pengulangan | `Macro Repeat Count`; “The number of times to repeat this entire macro.” |
| Break on failure/success | “If the entry fails, stop executing commands…” |

Algoritma checksum perintah **tidak diekspos** oleh string; yang ada hanya flag. Tidak dapat diklaim sama dengan checksum Honda tanpa bukti.

---

## 4. Mode passthrough & tracing

String `TunerPro.exe`:

- `MMAutoProm: Software data passthrough mode entry SUCCESS: %i baud`
- `FAILURE: AutoProm passthrough requires send commands to be followed immediately by listenpacket commands`
- `Trace mode entered. Monitoring addresses %X -> %X`

Mode ini adalah jalur **emulator/perangkat Moates**, bukan jalur diagnostik Honda. Persyaratan “send immediately followed by listenpacket” menunjukkan passthrough bersifat half-duplex dan timing-sensitive.

---

## 5. Model kesalahan

| Kelas | Contoh string |
|---|---|
| Port | `MMSerial: Open Port %s Failed`, `GetCommState Failed`, `SetCommState Failed` |
| Paket perangkat | `MMAutoProm Read Error - invalid packet checksum. Expected %.2X, Received %.2X.` |
| Checksum firmware | `AP_E_BAD_CHECKSUM`, `AP_E_EXTERNAL_CS_INVALID`, `AP_E_INTERNAL_CS_INVALID` |
| Firmware/ID | `AP_E_INVALID_FIRMWARE_IMAGE`, `AP_E_INVALID_HARDWARE_ID`, `AP_E_INVALID_VERSION` |
| Lisensi perangkat | `AP_E_TRIALS_EXPIRED` |
| Operasi | `AP_E_OPERATION_CANCELED`, `... Operation Canceled` |

Kesalahan ini milik perangkat Moates, bukan ECU Honda. Tidak ada kode error KWP/OBD di string utama.

---

## 6. Warisan ALDL

`TunerPro.exe` memuat nama kelas C++: `ALDLValue`, `ALDLItem`, `ALDLBit`, `ALDLTroubleCode`, `ALDLLookupTable`, `ALDLDash`, serta string `New ALDL Datastream Definition`, `New ALDL Data Command`, `New ALDL Value`, `New ALDL Bit`, `ALDL Dash`, `GM 160 Baud`.

**Kesimpulan:** format ADX berevolusi dari ALDL (GM). Ini menjelaskan tipe paket 160 baud, header/footer, dan model bitmask. Ia generik, bukan Honda-specific.

---

## 7. Yang tidak ditemukan

- Tidak ada konstanta frame Honda (`0x72`, `0x71`, `0x7E`, `0x7C`) di string TunerPro.
- Tidak ada string `KWP2000`, `ISO 9141`, `K-line`, atau `Honda` di executable utama.
- Tidak ada tabel perintah live data Honda; itu ada di ADX (terenkripsi).
- Tidak ada capture wire, tidak ada timing, tidak ada baud aktual yang terukur.

---

## 8. Perbandingan langsung dengan RevCore

| Elemen | TunerPro/ADX | RevCore |
|---|---|---|
| Framing | Statis/variabel, header/footer | Tetap: header, length, service, params, checksum |
| Checksum | Flag `SNDCMDCHECKSUM`, algoritma tidak terbaca | `HondaChecksum` dua-komplemen, terverifikasi |
| Baud | Per definisi/per perintah | 10.400 (kandidat 9.600/10.400) |
| Timeout | `listentimeout`, `silencelen` | Tidak dimodelkan |
| Echo | `RS232 Echo` | `stripLeadingEcho` menangani padding/echo |
| Perintah | Macro, trigger, pause/unpause | Urutan tetap per tabel |
| Endianness nilai | Opsi LSB first | Big-endian per `LiveFieldSpec` |
| Penanganan nilai hilang | Tidak ada state; nilai bisa 0 | State eksplisit, tidak pernah 0 palsu |
| Pengetahuan Honda | Di ADX (tidak terbaca) | Di kode (`LiveDataProfile.kt`) |

**Klasifikasi:** TunerPro dan RevCore berada pada **SAME FRAME FAMILY** hanya pada level konsep (frame biner + checksum), tetapi **DIFFERENT IMPLEMENTATION** pada detail. Tidak ada bukti **EXACT MATCH** karena ADX Honda tidak dapat dibaca dan tidak ada capture.

---

## 9. Batas & keyakinan

| Aspek | Keyakinan |
|---|---|
| Transport serial | TINGGI |
| Model paket ADX | TINGGI (deskripsi resmi binary) |
| Checksum perintah | SEDANG (flag ada; algoritma tidak) |
| Protokol Honda aktual | RENDAH–TIDAK ADA |
| Error perangkat Moates | TINGGI (string) |
| Kesesuaian dengan RevCore | SEDANG (perbandingan konsep) |

Tidak ada klaim bahwa TunerPro “berbicara Honda”. Yang terbukti: TunerPro dapat menjalankan definisi ADX yang, jika definisi itu benar, akan menghasilkan transaksi serial.
