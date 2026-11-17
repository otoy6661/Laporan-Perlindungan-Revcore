# Permukaan Perintah (Command Surface) — FLASHPRO

**Status:** SOURCE VERIFIED untuk nama perintah/metode dan format log · **frame byte: NOT FOUND / NO RAW RX CAPTURE**.

---

## 1. Titik masuk perintah

Tujuh kelas memanggil pengirim yang sama (nama metode + jumlah parameter):

| Kelas | Metode | Param | Konteks |
|---|---|---:|---|
| `Form1` | `SendCommand` | 5 | semua operasi ECU dari dashboard |
| `Diag` | `SendCommand` | 5 | DTC & stream data |
| `ReadECU` | `SendCommand10` | 5 | baca 48 KB |
| `Reset` | `SendCommand10` | 5 | reset flash count |
| `SMK` | `SendCommand`, `SendCommand6` | 5 | smartkey/EEPROM & K-Line |
| `Diag` | `InitFtdiIso`, `CloseFtdiConnection` | 0 | buka/tutup kanal |
| `Form1` | `InitClass15Iso`, `CloseClass15Handle` | 0 | buka/tutup kanal |

Lima parameter konsisten di semua pemanggil → kemungkinan besar *(command, payload, panjang, timeout, buffer respons)* atau sejenisnya, tetapi **susunan sebenarnya NOT VERIFIED** (tanpa IL). Jangan mengutip urutan ini sebagai fakta.

## 2. Token perintah yang terbaca

Token berikut diketahui dari **nama metode** atau **label log**, bukan dari byte di kabel:

| Token | Bukti | Fungsi (inferensi dari konteks) |
|---|---|---|
| `dat10` | metode `Form1/Dig.dat10`; string `Response dat10: ` | stream data tabel 1 |
| `dat11` | metode; string `Response 11: ` | stream data tabel 2 |
| `dat13` | metode; string `Response 13: ` | stream data tabel 3 |
| `dat16` | metode; string `Response 16: ` | stream data tabel 4 |
| `dat17` | metode + `LoopDat17(delay)` + `StopLoopDat17` | stream periodik (polling) |
| `dat20` | metode `Form1/Dig.dat20` | tabel tambahan |
| `datD1` | metode `Diag.datD1` | tabel diagnostik khusus |
| `dtc`…`dtc4` | 4 metode `Diag` | pembacaan DTC (mungkin 4 bank/format) |
| `rst`…`rst4` | 5 metode `Diag` | reset/perintah kontrol |
| `reset_COUNT`, `reset_COUNT1` | `Reset` | reset flash count (Keihin/Shindengen) |

**Yang tidak ada:** `dat12`, `dat14`, `dat15`, `dat18`, `dat19` — tidak ditemukan sebagai metode maupun string. Jangan mengarangnya.

## 3. Format log yang dipakai aplikasi

```
[{0:F4}] 0 > [{1}]          ← kirim
[{0:F4}] 0 < [{1}]          ← terima
[DEBUG] Balasan ({0}): {1}
Response dat10: …
[{0:F4}] … replySize <= {1} at offset={2}   ← read48k.log (teks Thai "หยุด" = berhenti)
```

Kolom `{0:F4}` adalah timestamp 4 desimal (detik) — berguna untuk mengukur latency bila ada capture.

`ReadECU.LogFrame(3)` dan `SendAndLog(1)` menegaskan setiap frame dicatat; `read48k.log` ditulis ke folder aplikasi. **File log aktual tidak ada** di workspace karena belum pernah membaca ECU nyata.

## 4. Perbedaan alur per vendor

| Vendor | Sinyal UI | Interpretasi |
|---|---|---|
| Keihin | `Please Turn OFF`, `🔑 Keihin Access` | handshake dengan kondisi ignition OFF |
| Shindengen | `Please Turn OFF - ON`, `🔑 Shindengen Access` | handshake butuh siklus OFF→ON |

Ini konsisten dengan dua keluarga ECU di `ECUTYPE` (KEIHINOTHER/H8C/M32R vs SHINDENGEN V850/RH850/RH850B).

## 5. DTC

`Diag` membaca 4 sumber (`dtc`..`dtc4`) lalu memvalidasi dengan `ValidateChecksum(array, len)` dan `Checksum8BitHonda(...)`. Format kode yang ditampilkan adalah `X-Y` (mis. `7-1`), bukan kode P0xxx OBD-II — 37 entri tercatat di `05_ECU_IDENTIFICATION/extract/DTC_CODES.csv`.

## 6. Batas bukti

- Tidak ada capture RX/TX → **NO RAW RX CAPTURE**.
- Encoding token (`"dat10"` sebagai ASCII? byte 0xDA 0x10? dengan header?) **tidak diketahui**.
- Panjang frame, checksum frame, dan ack/nack **tidak diketahui**.
- Semua klaim di atas hanya tentang *permukaan* perintah, bukan protokol wire-level.
