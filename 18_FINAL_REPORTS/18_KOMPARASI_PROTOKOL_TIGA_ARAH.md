# 18 — KOMPARASI PROTOKOL TIGA ARAH

**Work order:** BE-12
**Status:** wire-level **NOT CAPTURED** untuk ketiga aplikasi
**Sumber:** `16_THREE_WAY_COMPARISON/PROTOCOL_MATRIX.md`

---

## 1. Peringatan metodologis

Tidak ada satu pun capture ECU nyata di BE-11 atau BE-12. Kolom FLASHPRO dan TunerPro karena itu **tidak memuat frame**; kolom RevCore memuat struktur dari kode, bukan hasil pengukuran. Semua baris berstatus `NOT CAPTURED` kecuali dinyatakan lain.

## 2. Transport

| Lapisan | FLASHPRO | TunerPro | RevCore | Klasifikasi |
|---|---|---|---|---|
| API | `ftd2xx.dll` (D2XX) | `SetCommState`/`ReadFile` | USB-serial + FTDI Android | DIFFERENT IMPLEMENTATION |
| Mode K-Line | bit-bang + UART | UART dari ADX | USB-serial break/wake | DIFFERENT IMPLEMENTATION |
| Baud | tidak terbaca | properti ADX | 10.400 (kandidat 9.600) | INSUFFICIENT EVIDENCE |
| Echo | tidak terbaca | `RS232 Echo` | `KlineEchoFilter` + TX window | SAME FAMILY |
| Timeout | `FT_SetTimeouts` (nilai tidak terbaca) | `listentimeout`/`silencelen` | `timeoutMs=700`, retry 1 | DIFFERENT IMPLEMENTATION |

## 3. Framing

| Elemen | FLASHPRO | TunerPro | RevCore | Status |
|---|---|---|---|---|
| Header request | tidak diketahui | dari ADX | `0x72` (`HEADER_BASELINE`) | RevCore SOURCE; lain NOT FOUND |
| Header respons | tidak diketahui | dari ADX | `0x72/0x02/0x7E/0x7C/0xFE/0x7D/0x7B` | RevCore SOURCE |
| Panjang | tidak diketahui | field ADX | byte `[1]` | RevCore SOURCE |
| Service | tidak diketahui | payload ADX | byte `[2]`; `0x7F` negatif | RevCore SOURCE |
| Checksum frame | `Checksum8BitHonda` (nama) | flag + plugin | `(256 - sum) & 0xFF` | RevCore SOURCE; FP NOT VERIFIED |
| Echo removal | tidak diketahui | opsi ADX | `recentTxWindowMs` + filter | RevCore SOURCE |
| Capture | tidak ada | tidak ada | tidak ada | NOT CAPTURED |

Bentuk frame RevCore (**dari kode, bukan capture**):

```
request : 72 | LEN | SVC | DATA... | CS
response: HDR | LEN | SVC | DATA... | CS    HDR ∈ {72,02,7E,7C,FE,7D,7B}
```

## 4. Perintah & tabel

| Perintah | FLASHPRO | TunerPro | RevCore | Klasifikasi |
|---|---|---|---|---|
| Pemilihan tabel live | `dat10/11/13/16/17/20/D1` | item ADX | `forTable("10".."D1")` | SAME FAMILY (nama identik) |
| Polling | `LoopDat17(delay)` | macro repeat | `startLiveDataStream` + policy | DIFFERENT IMPLEMENTATION |
| DTC | `dtc..dtc4` + checksum | ALDL via ADX | `parseDtcResponse` (4 layout) | DIFFERENT COMMAND |
| Identifikasi | `GetEcuType`, `Extract14to25` | tidak ada | `HondaIdentifierParser` | DIFFERENT COMMAND |
| Tulis flash | `WriteFlash`, `CompareMemory` | tidak ada | tidak ada | NOT FOUND di TP/RevCore |
| Recovery | recovery key | tidak ada | `RECOVERY_REQUIRED` | INSUFFICIENT EVIDENCE |

## 5. Kesimpulan

1. **Tidak ada EXACT MATCH yang dapat dibuktikan** karena tidak ada capture.
2. FLASHPRO dan RevCore berbagi **nama tabel** dan **skema VomConfig** — indikasi keluarga protokol sama, bukan bukti byte.
3. TunerPro berada di keluarga konsep yang sama (frame + checksum) dengan implementasi generik; tidak ada pengetahuan Honda di executable.
4. Satu-satunya checksum yang dapat dibandingkan secara algoritmik adalah SUM 8-bit dua-komplemen (RevCore vs CBR `0xEF` di BE-11) — **EXACT MATCH pada algoritma**, belum terbukti dipakai pada frame ECU Honda.

## 6. Yang menaikkan status

| Langkah | Perubahan status |
|---|---|
| Capture TX/RX dengan adaptor + ECU (logic analyzer/sniffer) | NOT CAPTURED → RUNTIME VERIFIED |
| Uji checksum pada 3 image valid | NOT VERIFIED → SIMULATION VERIFIED |
| Bandingkan frame FLASHPRO vs RevCore pada ECU sama | SAME FAMILY → EXACT/DIFFERENT |
| Uji tulis pada ECU donor | NOT VERIFIED → HARDWARE VERIFIED |

Tanpa langkah ini, klaim "protokol sama" tetap **INSUFFICIENT EVIDENCE**.
