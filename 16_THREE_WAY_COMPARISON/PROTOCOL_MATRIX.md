# Matriks Protokol Tiga Arah — Wire Level

**Peringatan metodologis:** tidak ada satu pun capture ECU nyata di BE-11 atau BE-12. Kolom FLASHPRO dan TunerPro karena itu **tidak memuat frame**; kolom RevCore memuat struktur dari kode, bukan hasil pengukuran. Semua baris berstatus `NOT CAPTURED` kecuali dinyatakan lain.

---

## 1. Lapisan transport

| Lapisan | FLASHPRO | TunerPro | RevCore | Klasifikasi |
|---|---|---|---|---|
| API | `ftd2xx.dll` (D2XX) | `SetCommState`/`ReadFile` | USB-serial + FTDI Android | DIFFERENT IMPLEMENTATION |
| Mode K-Line | bit-bang (`FT_SetBitMode`) + UART (`FT_SetBaudRate`) | UART dari ADX | USB-serial break/wake pulse | DIFFERENT IMPLEMENTATION |
| Baud | tidak terbaca | properti ADX | 10.400 (kandidat 9.600) | INSUFFICIENT EVIDENCE |
| Echo | tidak terbaca | `RS232 Echo` | `KlineEchoFilter`, window TX | SAME FAMILY |
| Timeout | `FT_SetTimeouts` (nilai tidak terbaca) | `listentimeout`/`silencelen` | `timeoutMs=700`, retry 1 | DIFFERENT IMPLEMENTATION |

## 2. Framing

| Elemen | FLASHPRO | TunerPro | RevCore | Status |
|---|---|---|---|---|
| Header request | tidak diketahui (token `dat…`) | dari ADX | `0x72` (`HEADER_BASELINE`) | RevCore: SOURCE; lain: NOT FOUND |
| Header respons | tidak diketahui | dari ADX | `0x72/0x02/0x7E/0x7C/0xFE/0x7D/0x7B` | RevCore SOURCE |
| Panjang | tidak diketahui | field ADX (body/payload) | byte `[1]` = panjang frame | RevCore SOURCE |
| Service | tidak diketahui | payload ADX | byte `[2]`; `0x7F` = negative | RevCore SOURCE |
| Checksum frame | `Checksum8BitHonda` (nama) | flag + plugin | `(256 - sum) & 0xFF` dua-komplemen | RevCore SOURCE; FP NOT VERIFIED |
| Echo removal | tidak diketahui | opsi ADX | `recentTxWindowMs` + filter | RevCore SOURCE |
| Capture | **tidak ada** | **tidak ada** | **tidak ada** | NOT CAPTURED (ketiganya) |

Bentuk frame RevCore (dari kode, **bukan** capture):

```
request : 72 | LEN | SVC | DATA... | CS
response: HDR | LEN | SVC | DATA... | CS    HDR ∈ {72,02,7E,7C,FE,7D,7B}
```

## 3. Perintah & tabel

| Perintah | FLASHPRO | TunerPro | RevCore | Klasifikasi |
|---|---|---|---|---|
| Pemilihan tabel live | `dat10/11/13/16/17/20/D1` (metode) | item ADX | `LiveDataProfile.forTable("10".."D1")` | SAME FAMILY (nama tabel identik) |
| Polling | `LoopDat17(delay)` | macro repeat | `startLiveDataStream` + `LivePollPolicy` | DIFFERENT IMPLEMENTATION |
| DTC | `dtc..dtc4` + `Checksum8BitHonda` | ALDL DTC via ADX | `parseDtcResponse` (4 layout) | DIFFERENT COMMAND |
| Identifikasi | `GetEcuType`, `Extract14to25` | tidak ada | `HondaIdentifierParser` | DIFFERENT COMMAND |
| Tulis flash | `WriteFlash`, `CompareMemory` | tidak ada | tidak ada | NOT FOUND di TP/RevCore |
| Recovery | `GetShindengenRecoveryKey` | tidak ada | state `RECOVERY_REQUIRED` | INSUFFICIENT EVIDENCE |

## 4. Kesimpulan wire-level

1. **Tidak ada EXACT MATCH yang dapat dibuktikan** antara ketiganya, karena tidak ada capture.
2. FLASHPRO dan RevCore berbagi **nama tabel** (`dat10/11/13/16/17/20/D1`) dan **skema VomConfig** — indikasi keluarga protokol yang sama, tetapi bukan bukti byte.
3. TunerPro berada di keluarga konsep yang sama (frame + checksum) dengan implementasi generik; tidak ada pengetahuan Honda di executable.
4. Satu-satunya checksum yang bisa dibandingkan secara algoritmik adalah SUM 8-bit dua-komplemen (RevCore vs CBR `0xEF` di BE-11) — **EXACT MATCH pada algoritma**, tetapi belum terbukti dipakai pada frame ECU Honda.

## 5. Yang harus dilakukan untuk menaikkan status

| Langkah | Mengubah status |
|---|---|
| Capture TX/RX dengan adaptor + ECU (logic analyzer atau sniffer RevCore) | NOT CAPTURED → RUNTIME VERIFIED |
| Uji checksum pada 3 image valid | NOT VERIFIED → SIMULATION VERIFIED |
| Bandingkan frame FLASHPRO (Windows) vs RevCore pada ECU yang sama | SAME FAMILY → EXACT MATCH / DIFFERENT |
| Uji tulis pada ECU donor | NOT VERIFIED → HARDWARE VERIFIED |

Tanpa langkah-langkah ini, klaim "protokol sama" tetap **INSUFFICIENT EVIDENCE**.
