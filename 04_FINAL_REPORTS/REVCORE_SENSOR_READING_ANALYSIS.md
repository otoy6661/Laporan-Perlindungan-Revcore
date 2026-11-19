# RevCore — Sensor Reading Analysis (3D Chart Graph Remap K-Line)

Scope: hanya pembacaan sensor. Tidak mencakup remap kecuali yang diperlukan untuk konteks transport.
Source: `3D Chart Graph/Diag.cs`, `Class15.cs` (C# WinForms, FTDI D2XX).
Bukan clone, bukan basis aplikasi baru.

## 1. Ringkasan mekanisme

1. FTDI dibuka (`FT_Open(0)`), dipurge, diset 8-N-1 10400 bps, timeout 50 ms, latency 8 ms.
2. Wake K-line: bit-bang low 70 ms (`FT_Write([0x00])`), release (`0x01`), kembali ke UART, purge, settle 130 ms.
3. Setiap permintaan adalah frame 5 byte: `[0x72][len=5][fn][sub][checksum]`.
4. `SendCommand` menulis frame, mem-poll `FT_GetQueueStatus`, membaca sampai jumlah byte sesuai `replyLen`, memvalidasi checksum, lalu mempurge buffer.
5. Respons didekode per metode (`dat10`, `dat11`, `dat13`, `dat16`, `dat17`, `dat20`, `datD1`).
6. `LoopDat17` memanggil metode yang masih aktif secara berurutan; `dat20` selalu memanggil `datD1`.
7. Nilai ditampilkan pada `dataGridView2` melalui `UpdateRows2`.

## 2. Inisialisasi transport

Bukti: `Diag.cs:1139` (`InitFtdiIso`).

| Langkah | Nilai |
|---|---|
| `FT_Open` | device index 0 |
| `FT_Purge` | mask 3 (RX+TX) |
| `FT_SetBitMode` | `(0,0)` reset, lalu `(1,1)` bit-bang |
| `FT_SetDataCharacteristics` | 8 data, 0 parity, 0 stop |
| `FT_SetBaudRate` | 10400 |
| `FT_SetTimeouts` | 50 ms read, 0 write |
| `FT_SetLatencyTimer` | 8 ms |
| Wake low | `FT_Write([0x00])`, sleep 70 ms |
| Wake release | `FT_Write([0x01])`, UART mode, 10400, purge, sleep 130 ms |

## 3. Frame permintaan (SOURCE VERIFIED)

| Metode | Frame | Isi |
|---|---|---|
| `dat10` | `72 05 71 10 08` | RPM, TPS1/2, ECT, IAT, MAP, battery, VSS, injection, advance |
| `dat11` | `72 05 71 11 07` | dat10 + IAC (`b[22]/10000`) |
| `dat13` | `72 05 71 13 05` | subset; battery `b[14]`, inj `b[15..16]`, adv `b[17]` |
| `dat16` | `72 05 71 16 02` | APS/TP volt & derajat, COR, ECT/IAT/MAP, battery, VSS, inj, adv |
| `dat17` | `72 05 71 17 01` | ECT fallback, MD/MODE/FIZ, table type |
| `dat20` | `72 05 71 20 F8` | O2, O2V, STF, AFR |
| `datD1` | `72 05 71 D1 47` | BAS, SSS, SSW, gear, POM, fan, posisi gigi |
| DTC | `72 05 73 02 14`, `73 01 15`, `74 02 13`, `74 01 14` | baca/hapus DTC |
| Aux | `72 05 60 01 28`, `60 03 26` | fungsi tambahan |
| Reset | `72 05 00 F0 99` | reset ECU/sesi |
| Wake | `FE 04 72 8C` | pembuka sesi |

Semua checksum tervalidasi di `03_EVIDENCE/PROTOCOL_FRAME_VALIDATION.csv`.

## 4. Format respons (REKONSTRUKSI dari decoder)

```
b[0]  : header/checksum awal (tidak dipakai decoder)
b[1]  : panjang; 0x05 = fungsi tidak didukung / respons pendek
b[2]  : dipakai dat17 sebagai "tableType"
b[3]  : status/echo fungsi
b[4+] : data
last  : checksum
```

`SendCommand` menentukan panjang respons dengan `replyLen = buffer[commandSize + 1]`, lalu menyalin `replyLen` byte terakhir dari buffer RX. Untuk frame 5 byte, indeks 6 berada di dalam respons; mekanisme ini hanya konsisten jika ECU menggemakan frame request sebelum data. Ini adalah heuristik, bukan parsing panjang yang eksplisit.

Catatan: label "tableType" di UI berasal dari `array9[2]`, yang menurut format di atas kemungkinan adalah **echo fungsi** (`0x71`), bukan tipe tabel. Perlu verifikasi. Status: DUGAAN.

## 5. Tabel decoding

### 5.1 dat10 `Diag.cs:563`

| Field | Rumus | Satuan/komentar |
|---|---|---|
| RPM | `(b[4]<<8)+b[5]` | rpm |
| TPS1 | `b[6]*5/256` | V |
| TPS2 | `b[7]/2` | % (as coded) |
| ECT1 | `b[8]*5/256` | V |
| ECT2 | `b[9]-40` | °C |
| IAT1 | `b[10]*5/256` | V |
| IAT2 | `b[11]-40` | °C |
| MAP1 | `b[12]*5/256` | V |
| MAP2 | `b[13]` | kPa (as coded) |
| Battery | `b[16]/10` | V |
| VSS | `b[17]` | km/h |
| Injection | `((b[18]<<8)+b[19])/200` | ms |
| Advance | `b[20]/2-64` | ° BTDC |
| `b[14]`, `b[15]` | tidak dipakai | — |

### 5.2 dat11 `Diag.cs:805`

Sama dengan dat10, ditambah:

| Field | Rumus | Komentar |
|---|---|---|
| IAC | `b[22]/10000` | **tidak dikirim ke UI** |

`UpdateGridView(...)` tidak menerima parameter IAC. Jadi nilai IACV dihitung tetapi dibuang.

### 5.3 dat13 `Diag.cs:880`

| Field | Rumus |
|---|---|
| Battery | `b[14]/10` |
| Injection | `((b[15]<<8)+b[16])/200` |
| Advance | `b[17]/2-64` |
| VSS | hardcoded `0` |

### 5.4 dat16 `Diag.cs:924`

| Field | Rumus |
|---|---|
| AP1 V / AP2 V | `b[6]*5/256`, `b[7]*5/256` |
| AP1 ° / AP2 ° | `b[8]/2`, `b[9]/2` |
| TP1 V / TP2 V | `b[10]*5/256`, `b[11]*5/256` |
| TP1 ° / TP2 ° | `b[12]/2`, `b[13]/2` |
| COR | `b[14]` |
| ECT V / °C | `b[15]*5/256`, `b[16]-40` |
| IAT V / °C | `b[17]*5/256`, `b[18]-40` |
| MAP V / kPa | `b[19]*5/256`, `b[20]` |
| Battery | `b[21]/10` |
| VSS | `b[22]` |
| Injection | `b[23]/200` |
| Advance | `b[24]/2-64` |

Catatan: nilai volt/derajat dikirim ke UI setelah `Math.Round` (cast int), sehingga resolusi desimal hilang pada jalur tampilan ini.

### 5.5 dat17 `Diag.cs:973`

| Field | Rumus |
|---|---|
| ECT1 | `b[12] != 0xFF ? b[12]*5/256 : b[8]*5/256` |
| ECT2 | `b[13] != 0xFF ? b[13]-40 : b[9]-40` |
| Battery | `b[14]/10` |
| Injection | `((b[15]<<8)+b[16])/200` |
| Advance | `b[17]/2-64` |
| MD | `b[18]` |
| MODE | 1: `0x80/0x67`; 2: `0x66`; 3: `0x3C`; 4: `0x59`; 0: `0x79`; else 0 |
| FIZ | `MD < 128 ? "ON" : "OFF"` |
| VSS | `b[19]` |
| tableType | `b[2]` |

Catatan: ECT fallback hanya mengganti nilai jika byte alternatif **tidak** `0xFF`; nilai `0xFF` dianggap "tidak valid" dan memakai jalur utama.

### 5.6 dat20 `Diag.cs:717`

| Field | Rumus |
|---|---|
| O2 | `(ushort)(b[4] | b[5]<<8) / 13.142708 / 1000` |
| O2V | `(b[4] & 0xFF) / 50.9937` |
| STF | `(b[5] & 0xFF) / 128.25651` |
| AFR | `-5.351*O2V + 17.7` |

Catatan penting: STF memakai hanya `b[5]`; jika STF adalah 16-bit, formula ini salah. AFR adalah aproksimasi linier dari O2V, bukan perhitungan stoikiometri.

### 5.7 datD1 `Diag.cs:629`

| Field | Sumber | Mapping |
|---|---|---|
| BAS | `b[4]==0x01` | ON |
| SSS (side stand) | `b[4]` | 0x01 ON; 0x00 OFF |
| SSW (starter switch) | `b[4]` | 0x02 ON; 0x01/0x00 OFF |
| Gear status (ggs) | `b[4]` | 0x01 "Netral"; 0x00 "OnGear" |
| POM (fuel pump) | `b[8]` | 0x00 OFF; 0x01/0x05 ON; 0x04 OFF |
| Fan | `b[9]==0x01` | ON |
| Gear position | `b[10]` | 0x80=6, 0x10=5, 0x08=4, 0x04=3, 0x02=2, 0x01=1, 0x20=N, 0x00=- |

Nilai `b[4]` bersifat bitfield/state, bukan kombinasi bebas; hanya nilai yang tercantum yang ditangani.

## 6. Polling dan timing

`LoopDat17` (`Diag.cs:516`):

```
if tek11: dat11(); dat20();
if tek10: dat10(); dat20();
if tek13: dat13(); dat20();
if tek16: dat16(); dat20();
if tek17: dat17(); dat20();
Task.Delay(10, token);   // TIDAK di-await
```

- Metode `LoopDat17` bukan `async`; `Task.Delay` menghasilkan task yang dibuang. Tidak ada jeda eksplisit antar siklus.
- `dat20` memanggil `datD1()` di akhir, sehingga switch/fuel pump dibaca setiap kali dat20 dipanggil — hingga 5 kali per siklus.
- Tiap `SendCommand` memakai timeout `50 + 2*commandSize` ms (60 ms untuk frame 5 byte).
- Tidak ada interval polling tetap; laju ditentukan oleh waktu serial + timeout.
- `tekXX = false` ketika respons `b[1] == 0x05` (fungsi tidak didukung), sehingga polling menyesuaikan ECU.

## 7. Penanganan respons tidak valid / timeout

Fakta source:

1. `SendCommand` memvalidasi checksum; jika gagal/timeout, mengembalikan `false` dan mempurge.
2. Pemanggil (`dat10`..`datD1`) **mengabaikan** nilai balik.
3. Buffer respons dialokasikan baru dan bernilai nol setiap panggilan.
4. Tidak ada retry.
5. Tidak ada penanda "invalid"/"timeout" di UI.

Konsekuensi:

- Timeout pada `datD1` ditampilkan sebagai `POM OFF`, `SSS OFF`, `SSW OFF`, `fan OFF`, `gear "-"`.
- Timeout pada dat lain ditampilkan sebagai `0` (RPM 0, TPS 0, dan seterusnya).
- Pengguna tidak dapat membedakan nilai nol nyata dari kegagalan komunikasi. Ini risiko diagnostik yang harus diperbaiki RevCore dengan status validitas eksplisit.

## 8. Tampilan

`dataGridView2` (12 baris):

| Row | Parameter |
|---:|---|
| 0 | Oxygen Sensor |
| 1 | Oxygen Sensor Volt |
| 2 | Short term Fuel Trim |
| 3 | Air Fuel Ratio |
| 4 | Fast Idle Step |
| 5 | Bank Angle Sensor |
| 6 | Side Stand Switch |
| 7 | Switch Starter |
| 8 | Gear Status |
| 9 | Fuel Pump |
| 10 | Cooling Fan |
| 11 | Gear Position |

`dataGridView` (utama) memuat RPM, TPS, ECT, IAT, MAP, battery, injection, MODE, ignition timing, VSS, tableType, dan field APS/TP.

## 9. Cacat dan keterbatasan yang ditemukan

| ID | Temuan | Dampak | Status |
|---|---|---|---|
| S-01 | Nilai balik `SendCommand` diabaikan | data palsu nol/OFF saat timeout | SOURCE VERIFIED |
| S-02 | `Task.Delay` tidak di-await | loop tanpa jeda, beban bus tinggi | SOURCE VERIFIED |
| S-03 | IAC dihitung tetapi tidak ditampilkan | kebutuhan IACV tidak terpenuhi di UI | SOURCE VERIFIED |
| S-04 | STF hanya memakai `b[5]` | kemungkinan salah skala/tanda | SOURCE VERIFIED (formula), correctness UNVERIFIED |
| S-05 | `tableType = b[2]` | kemungkinan echo fungsi, bukan tipe tabel | DUGAAN |
| S-06 | dat13 VSS hardcoded 0 | data VSS hilang pada varian ini | SOURCE VERIFIED |
| S-07 | dat16 membulatkan nilai volt/derajat | kehilangan resolusi | SOURCE VERIFIED |
| S-08 | `replyLen = buffer[commandSize+1]` | heuristik, rapuh terhadap ECU yang tidak menggemakan frame | SOURCE VERIFIED (kode), risiko UNVERIFIED |
| S-09 | Tidak ada validasi checksum di level pemanggil | respons korup bisa lolos jika `SendCommand` false diabaikan | SOURCE VERIFIED |
| S-10 | `datD1` dipanggil 1–5× per siklus | pembacaan switch berulang, tidak efisien | SOURCE VERIFIED |

## 10. Rekomendasi untuk RevCore

1. Implementasi transport yang sama (10400 8-N-1, wake 70/130 ms, checksum Honda) tetapi dengan status validitas eksplisit per pembacaan.
2. Jangan menampilkan nilai jika checksum/timeout gagal; tampilkan `INVALID`/`TIMEOUT`.
3. Untuk setiap parameter, simpan raw bytes + formula + versi; jangan hanya hasil.
4. Verifikasi apakah STF 8-bit atau 16-bit sebelum memakai formula `/128.25651`.
5. Tampilkan IAC mentah dan hasil konversi; jangan membuang seperti aplikasi referensi.
6. Uji polling pada ECU nyata untuk menentukan interval aman dan apakah `datD1` perlu dipanggil setiap siklus.
7. Jangan menganggap `b[2]` sebagai table type tanpa verifikasi.

## 11. Status keseluruhan

| Aspek | Status |
|---|---|
| Transport & wake | SOURCE VERIFIED |
| Frame & checksum | SOURCE VERIFIED + aritmetik |
| Formula decoding | SOURCE VERIFIED (kode), ECU UNVERIFIED |
| Pemetaan row UI | SOURCE VERIFIED |
| Timeout handling | SOURCE VERIFIED (cacat) |
| Uji perangkat/ECU | TIDAK DILAKUKAN |
