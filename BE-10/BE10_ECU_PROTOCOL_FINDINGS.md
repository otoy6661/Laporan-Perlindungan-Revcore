# BE-10 — TEMUAN PROTOKOL ECU (K-LINE / FTDI)

**Sumber utama:** `SOURCES\3D_CHART_GRAPH\PROJECT\3D Chart Graph\Form1.cs`,
`Diag.cs`, `SMK.cs`
**Status keseluruhan:** **STATICALLY_ANALYZED**; validasi pada ECU fisik tetap **HARDWARE_PENDING**.

---

## 1. Lapisan fisik dan transport FTDI

Urutan inisialisasi di `Form1.cs:445–546` (`InitFtdiIso`):

| Langkah | Nilai | Baris |
|---|---|---|
| Buka perangkat | index 0 | 445 |
| Purge | mask 3 (RX+TX) | 454 |
| Reset bitmode | `(0, 0)` | 462 |
| Data characteristics | 8 data bit, parity 0, stop bit 0 (8N1) | 470 |
| Baud rate | **10.400** | 478 |
| Timeout baca | **50 ms** | 486 |
| Latency timer | **8 ms** | 494 |
| Bit-bang wake-up | bitmode `(1,1)`, tulis `0x00`, jeda, tulis `0x01` | 502–519 |
| Kembali ke UART | bitmode `(0,0)`, baud 10.400, purge | 527–543 |

Arti teknis: K-Line di sini bukan adapter ISO 9141 standar; software melakukan **wake-up bit-bang** pada pin TX lalu kembali ke UART 10.400 8N1. Ini menjelaskan mengapa kabel harus berbasis FTDI dan mengapa adapter USB-serial biasa belum tentu bekerja.

Status: **STATICALLY_ANALYZED**. Timing aktual (70 ms/130 ms) belum diukur di perangkat.

---

## 2. Format frame

Dari `SendCommand` (`Form1.cs:824–898`) dan konstruksi frame:

```
[format] [total_length] [data …] [checksum]
```

- `total_length` menghitung **seluruh frame**, bukan hanya data. Contoh `72 05 71 10 08` berarti total 5 byte.
- Checksum Honda: `(sum ^ 0xFF) + 1` (`Checksum8BitHonda`, `Form1.cs:2107`).
- Timeout perintah: `50 + 2 × commandSize` ms (`Form1.cs:833`).
- Panjang balasan diambil dari `reply[commandSize + 1]`; validasi memakai `received - commandSize == length` (`Form1.cs:865–867`), lalu checksum balasan diverifikasi (`ValidateChecksum`, `Form1.cs:872`).
- Bila timeout: purge RX/TX dan kembalikan `false` (`Form1.cs:886–892`).

Prototipe `HondaProtocol.cs` mereproduksi semantik ini; tes `CK-01` dan `FR-01` lulus.

Status: **STATICALLY_ANALYZED**; belum diuji dengan ECU.

---

## 3. Katalog perintah

Byte perintah diambil dari array di source. Semua checksum di bawah sudah dihitung ulang dan cocok dengan rumus Honda.

| Fungsi | Frame | Baris | Catatan |
|---|---|---|---|
| Wake/keepalive | `FE 04 72 8C` | 574–580 | Disimpan sebagai `array` |
| Keepalive 2 | `72 05 00 F0 99` | 581–588 | |
| Baca ECM ID | `72 07 72 00 00 05 10` | 589–598 | Balasan byte 5..9 = 5 byte ID |
| Flash count Keihin | `7D 06 01 01 03 78` | 599–607 | Balasan byte 6 |
| Flash count Shindengen | `7B 06 02 01 03 79` | 608–616 | Balasan byte 6 |
| Keepalive Keihin | `7E 06 01 01 00 7A` | 617–625 | |
| Keepalive Shindengen | `7C 06 02 01 00 7B` | 626–634 | |
| Live dat10 | `72 05 71 10 08` | 18592 | |
| Live dat11 | `72 05 71 11 07` | 18637 | |
| Live dat13 | `72 05 71 13 05` | 18681 | |
| Live dat16 | `72 05 71 16 02` | 18724 | |
| Live dat17 | `72 05 71 17 01` | 18740 | |
| Live dat20 (O2) | `72 05 71 20 F8` | 18818 | |
| Status datD1 | `72 05 71 D1 47` | (dipakai di Diag) | |

Verifikasi checksum contoh: `72+05+71+10 = F8`, `(F8^FF)+1 = 08` → `…08`; `72+05+71+20 = 108` → `08`, `(08^FF)+1 = F8` → `…F8`. Cocok.

Status: **FOUND_IN_SOURCE** + **STATICALLY_ANALYZED**.

---

## 4. Decoding live data

Offset pasti (lihat `REPORTS\BE10_SENSOR_LIVE_DATA_CATALOG.csv`, 45 kanal):

| Kanal | Rumus | Diterapkan pada |
|---|---|---|
| RPM | `(b[4]<<8)+b[5]` | dat10/11/13/16/17 |
| TPS1 | `b[6]*5/256` (V) | dat10/11/13/16/17 |
| TPS2 | `b[7]/2` (%) | dat10/11/13/16/17 |
| ECT1 | `b[8]*5/256` (V) | dat10/11/13/16 |
| ECT2 | `b[9]-40` (°C) | dat10/11/13/16 |
| IAT1/IAT2 | `b[10]*5/256`, `b[11]-40` | dat10/11/13/16 |
| MAP1/MAP2 | `b[12]*5/256`, `b[13]` | dat10/11/13/16 |
| BAT | `b[16]/10` | dat10/11/16 |
| VSS | `b[17]` (atau `b[22]` dat16, `b[19]` dat13) | sesuai varian |
| INJ | `((b[18]<<8)+b[19])/200` ms | dat10/11/16; `b[15..16]` dat13/17; `b[23]/200` dat16 |
| ADV | `b[20]/2-64`° | dat10/11; `b[17]` dat13/17; `b[24]` dat16 |

Varian penting:

- **dat17**: ECTmemakai `b[12]/b[13]` bila bukan `0xFF`, jika tidak jatuh ke `b[8]/b[9]` (`Form1.cs:18759–18761`). Byte `b[18]` memetakan MODE: 128/103→1, 102→2, 60→3, 89→4, 121→0; FIZ ON bila `b[18] < 128`; `b[2]` = table type.
- **dat16**: sensor ganda — AP1/AP2 (`b[6]/b[7]`), sudut AP (`b[8]/b[9]`), TP1/TP2 (`b[10]/b[11]`), sudut TP (`b[12]/b[13]`), COR `b[14]`, ECT `b[15]`, IAT `b[17]`, MAP `b[19]`, BAT `b[21]/10`, VSS `b[22]`, INJ `b[23]/200`, ADV `b[24]/2-64`.
- **dat20**: `Diag.cs:729–740` menghitung `O2 = UInt16(b,4)/13.142708/1000`, `STF = b[5]/128.25651`, `O2V = b[4]/50.9937`, `AFR = -5.351*O2V + 17.7`. `Form1.cs:18826–18828` memakai `O2V = b[4]/195.195195` untuk gauge; dua skala berbeda ada di source. **AFR adalah estimasi software, bukan nilai wideband ECU.**
- **datD1**: BAS/SSS/SSW/GGS dari `b[4]`, POM `b[8]` (0/4 OFF, 1/5 ON), FAN `b[9]==1`, gear dari `b[10]` (`0x80`=6, `0x10`=5, `0x08`=4, `0x04`=3, `0x02`=2, `0x01`=1, `0x20`=N).

Status: **STATICALLY_ANALYZED**; decoding belum diverifikasi terhadap kendaraan.

---

## 5. Checksum firmware

### 5.1 Keihin (`KeihinAutoChecksum`, `Form1.cs:1721`)

- Bila offset checksum = 0: jumlahkan byte 1..end.
- Bila offset > 0: jumlahkan `0..offset-1` dan `offset+1..end`.
- Tulis `0 - (byte)jumlah` (two's complement 8-bit) di offset.
- `Checksum8Bit` = `(byte)(255 - ((sum - 1) >> 8))`; `Checksum8BitHonda` = `(sum ^ 255) + 1`.

Tes `CK-02` memverifikasi total jumlah byte menjadi 0 mod 256 setelah patch.

### 5.2 Shindengen (`ShindengenAutoChecksum`, `Form1.cs:1130`)

- Cari signature `shRKeysSig` = `91 91 0D 00 9E 8D`.
- Cari `shWKeysig` = `11 12 13 14 15 15 17` (`Form1.cs:1933`).
- Pindai `D0 07`; `num` = offset marker (atau `j-6` untuk RH850B).
- Jumlahkan word 32-bit little-endian pada `[0, num-4)` dan `[num, end)`.
- Tulis `0 - total` sebagai uint32 LE di `num-4`.

Tes `CK-03` memverifikasi `sum32 == 0` setelah patch.

Status: **STATICALLY_ANALYZED**; **SAMPLE_TEST_PASSED** untuk vektor sintetis, bukan firmware asli.

---

## 6. Seed/key Shindengen

`GetShindengenRecoveryKey`/`GetShindengenWriteKey` (`Form1.cs:2023–2092`):

```
c0 = bytes[i..i+1]      (LE)
c1 = bytes[i+2..i+3]    (LE)
c2 = bytes[i+4..i+5]    (LE)
num5 = (ushort)(c1 * (seed + c0))
add  = (c2 > 0) ? seed % c2 : seed
key  = (ushort)(num5 + add)      // high byte, low byte
```

Tes `SK-01` dengan seed `0x1234`, `c0=0x0102`, `c1=0x0003`, `c2=0x0011` menghasilkan key `0x39A4`, sesuai perhitungan manual.

Status: **STATICALLY_ANALYZED**; algoritma belum diverifikasi terhadap ECU.

---

## 7. Urutan pra-tulis dan tulis flash

### 7.1 Shindengen (`ShindengenPreWriteFlash`, `Form1.cs:1174`)

Urutan frame (desimal di source, ditampilkan hex):

```
7B 08 02 02 50 19 76 9A
7B 08 02 03 25 37 86 96
7B 05 02 04 7A
7B 07 02 05 <keyHi> <keyLo> <ck>
7C 06 02 01 00 7B
7C 0B 02 0B 00 00 00 FF FF FF 6F
7C 07 02 0E 01 00 6C
7C 06 02 04 FF 79
7C 05 02 05 78
```

### 7.2 Keihin (`KeihinPreWriteFlash`, `Form1.cs:1740`)

```
7D 08 01 02 50 47 4D 94
7D 08 01 03 2D 46 49 BB
7E 05 01 02 7A
7E 07 01 03 00 00 77
7E 05 01 01 7A
7E 0B 01 0B 00 00 00 FF FF FF 6E
7E 07 01 0E 01 90 DB
7E 06 01 04 FF 78
7E 05 01 05 77
```

### 7.3 Blok tulis (`WriteFlash`, `Form1.cs:1348`)

- Probe fast-write: `FF 25 00 20 7C 00`.
- Header standar: `7E 8B 01 06` (Keihin), `7C 8B 02 06` (Shindengen).
- H8C: `7E 4B 01 06` dengan blok 64 byte.
- Data 128 byte per blok; alamat akhir; checksum jumlah 8-bit; checksum Honda; checksum frame.
- Fast write menaikkan baud ke **62.500** (`Form1.cs:1492`).

Status: **STATICALLY_ANALYZED**; seluruh urutan **HARDWARE_PENDING**. Tidak ada perintah yang dieksekusi ke ECU fisik.

---

## 8. Recovery

Dari `flas()`/`WorkerThread` dan `ShindengenPreWriteFlash`:

- Jika ID ECU berakhiran `0000`, software menganggap **recovery mode**.
- Start address dan checksum offset di-set otomatis.
- Kunci memakai `GetShindengenRecoveryKey` (bukan write key biasa).
- Untuk Shindengen RH850B, marker `D0 07` digeser 6 byte saat menghitung checksum.

Status: **STATICALLY_ANALYZED**; varian recovery lain dan perilaku ECU sebenarnya **UNKNOWN_AFTER_ANALYSIS**.

---

## 9. Smart Key / EEPROM

`SMK.cs` mengimplementasikan baca/tulis EEPROM kunci, bukan sekadar menu:

- Challenge Keihin: `27 0B E0 48 65 6C 6C 6F 48 6F 43` ("HelloHoC") dan `27 0B E0 77 41 72 65 59 6F 75 22` ("wAreYou"+`0x22`) — `SMK.cs:247`, `SMK.cs:1456`.
- Challenge Shindengen: `91 91 0D DF 9E 8D 9A 86 90 8A 8C 9B 88` dan `91 91 0D DF 92 9E 86 96 8B 8D 86 C0 6A` — `Form1.cs:19083–19084`.
- Baca per halaman:
  - Keihin: `82 82 10 06 <page> <ck>` (`SMK.cs:315`).
  - Shindengen: `91 91 07 40 <page> 00 <ck>` (`SMK.cs:428`).
- 256 halaman × 2 byte; checksum halaman dihitung dari byte-byte frame.

Status: **STATICALLY_ANALYZED**. Tindakan tulis EEPROM tidak dijalankan; ini area berisiko dan di luar otorisasi hardware.

---

## 10. Yang belum ditemukan

| Item | Status | Bukti |
|---|---|---|
| Rutin baca BIN penuh dari ECU | `NOT_FOUND_AFTER_MEANINGFUL_SEARCH` | `WorkerThread` (`Form1.cs:572`) hanya baca ECM ID + flash count; tidak ada `ReadFlash`/loop baca memori. |
| Lapisan ISO 9141/KWP/UDS | `NOT_FOUND_AFTER_MEANINGFUL_SEARCH` | Frame bersifat proprietary Honda; tidak ada header ISO. |
| Timing wake-up terukur | `HARDWARE_PENDING` | Nilai di source, belum diukur. |
| Checksum famili lain | `UNKNOWN_AFTER_ANALYSIS` | Hanya Keihin/Shindengen yang terbaca. |

---

## 11. Evidensi

- `REPORTS\BE10_SENSOR_LIVE_DATA_CATALOG.csv` — 45 kanal dengan byte index/rumus.
- `PROTOTYPES\RESULTS\BE10_PROTOTYPE_TESTS.csv` — CK-01..03, SK-01, LD-01..06, FR-01.
- `PROTOTYPES\src\BE10Tools\Protocol\HondaProtocol.cs`, `LiveData.cs`.
