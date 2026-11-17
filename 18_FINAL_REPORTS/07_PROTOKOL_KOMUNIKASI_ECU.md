# 07 — PROTOKOL KOMUNIKASI ECU

**Work order:** BE-12
**Status:** SOURCE VERIFIED (permukaan perintah) · wire-level **NOT VERIFIED / NO RAW RX CAPTURE**
**Sumber:** `04_PROTOCOL_AUTOPSY/TRANSPORT_AND_KLIN.md`, `COMMAND_SURFACE.md`

---

## 1. Transport

- Satu jalur: **FTDI D2XX** (`ftd2xx.dll`, 12 fungsi).
- `Class15` = UART/ISO (frame dikirim sebagai byte; timing oleh FTDI).
- `Class155` = bit-bang (`FT_SetBitMode`/`FT_GetBitMode`) untuk init K-Line dan I2C.
- Tidak ada `System.IO.Ports`; tidak ada CAN/ELM327/J2534/UDS/KWP2000.

Nilai baud, parity, stop bit, timeout, dan latency **tidak terbaca** dari metadata (hanya nama setter). Semua angka wire-level berstatus **NOT VERIFIED**.

## 2. Titik masuk perintah

Tujuh kelas memanggil pengirim yang sama:

| Kelas | Metode | Param | Konteks |
|---|---|---:|---|
| `Form1` | `SendCommand` | 5 | operasi ECU dashboard |
| `Diag` | `SendCommand` | 5 | DTC & stream |
| `ReadECU` | `SendCommand10` | 5 | baca 48 KB |
| `Reset` | `SendCommand10` | 5 | reset flash count |
| `SMK` | `SendCommand`, `SendCommand6` | 5 | smartkey/EEPROM |
| `Diag` | `InitFtdiIso`, `CloseFtdiConnection` | 0 | buka/tutup kanal |
| `Form1` | `InitClass15Iso`, `CloseClass15Handle` | 0 | buka/tutup kanal |

Lima parameter konsisten → kemungkinan *(command, payload, panjang, timeout, buffer respons)*, tetapi susunan sebenarnya **NOT VERIFIED**. Jangan mengutip urutan ini sebagai fakta.

## 3. Token perintah

| Token | Bukti | Fungsi (inferensi) |
|---|---|---|
| `dat10` | metode + `Response dat10:` | stream tabel 1 |
| `dat11` | metode + `Response 11:` | stream tabel 2 |
| `dat13` | metode + `Response 13:` | stream tabel 3 |
| `dat16` | metode + `Response 16:` | stream tabel 4 |
| `dat17` | metode + `LoopDat17(delay)` + `StopLoopDat17` | polling periodik |
| `dat20` | metode | tabel tambahan |
| `datD1` | `Diag.datD1` | tabel diagnostik |
| `dtc`…`dtc4` | 4 metode `Diag` | pembacaan DTC |
| `rst`…`rst4` | 5 metode `Diag` | reset/kontrol |
| `reset_COUNT`, `reset_COUNT1` | `Reset` | reset flash count |

**Tidak ada** `dat12`, `dat14`, `dat15`, `dat18`, `dat19` — jangan mengarang.

## 4. Format log

```
[{0:F4}] 0 > [{1}]          kirim
[{0:F4}] 0 < [{1}]          terima
[DEBUG] Balasan ({0}): {1}
Response dat10: …
[{0:F4}] … replySize <= {1} at offset={2}   read48k.log
```

Timestamp 4 desimal (detik) memungkinkan pengukuran latency bila ada capture. `ReadECU.LogFrame(3)` dan `SendAndLog(1)` mencatat setiap frame; **file log aktual tidak ada** karena belum pernah membaca ECU nyata.

## 5. Perbedaan vendor

| Vendor | Sinyal | Interpretasi |
|---|---|---|
| Keihin | `Please Turn OFF`, `🔑 Keihin Access` | handshake ignition OFF |
| Shindengen | `Please Turn OFF - ON`, `🔑 Shindengen Access` | siklus OFF→ON |

Konsisten dengan dua keluarga ECU (3 varian Keihin, 3 varian Shindengen).

## 6. DTC

`Diag` membaca 4 sumber (`dtc`..`dtc4`), memvalidasi `ValidateChecksum` + `Checksum8BitHonda`, lalu menampilkan kode format `X-Y` (bukan P0xxx). 37 entri tercatat di `DTC_CODES.csv`.

## 7. Perbandingan dengan RevCore

| Elemen | FLASHPRO | RevCore |
|---|---|---|
| Transport | D2XX Windows | USB-serial Android + FTDI |
| Nama tabel | `dat10/11/13/16/17/20/D1` | `flashpro.dat10/…/D1` |
| Header frame | tidak diketahui | `0x72`/`0x02`/`0x7E`/`0x7C`/`0xFE`/`0x7D`/`0x7B` |
| Checksum frame | `Checksum8BitHonda` (nama) | dua-komplemen SUM8 (kode) |
| Timeout | `FT_SetTimeouts` (nilai tidak terbaca) | `timeoutMs=700`, retry 1 |
| Capture | tidak ada | tidak ada |

Kesamaan **nama tabel** dan **skema offset** menunjukkan keluarga protokol yang sama, tetapi **bukan** bukti byte. Tidak ada **EXACT MATCH** yang dapat diklaim.

## 8. Batas

- **NO RAW RX CAPTURE.** Tidak ada satu frame pun yang boleh ditulis sebagai "frame FLASHPRO".
- Encoding token (ASCII? byte 0xDA? header?) tidak diketahui.
- Panjang, checksum, ack/nack, dan timing init tidak diketahui.
- Semua klaim hanya tentang **permukaan** perintah.
