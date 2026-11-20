# LAPORAN PEKERJAAN 2 — LIVE MONITOR (AUDIT PARAMETER)

Tanggal: 2026-11-20
Pemilik proyek: otoy / Otoy Sullivan
Referensi kelengkapan: H-Diag 2.1 (laporan Tahap 2 di repository ini)

## Status

**PARTIAL**

Audit parameter selesai dan dipetakan ke source. Tidak ada parser/tampilan baru
yang ditambahkan, karena work order melarang penambahan berdasarkan dugaan:
beberapa parameter hanya memiliki bukti parsial (BAS) atau belum pernah terlihat
pada ECU ini (dual throttle `dat16`). Klaim dukungan per parameter pada Vario 150
SmartKey tetap menunggu pengujian perangkat.

## 1. Metode

1. Membaca daftar parameter work order.
2. Menelusuri tabel live data RevCore di
   `app/src/main/java/com/revcore/android/core/comm/LiveDataProfile.kt`.
3. Menelusuri tampilan kartu live di
   `app/src/main/java/com/revcore/android/ui/screens/LiveDataScreen.kt` dan
   daftar ketersediaan di `EcuInfoScreen.kt`.
4. Membandingkan dengan baris/offset H-Diag pada
   `04_FINAL_REPORTS/STAGE2_HDIAG_LIVEDATA_PARSER.md` dan
   `03_EVIDENCE/HDIAG_STAGE2_EVIDENCE.md`.
5. Mencocokkan dengan log `Log/RevCore_Log_2026-11-20_2.txt`: hanya tabel
   `0x17`, `0x20`, dan `0xD1` yang benar-benar dipolling pada jendela log.

## 2. Matriks parameter

Keterangan status:

- **Parse + kartu** = nilai dihitung dan ditampilkan sebagai kartu live.
- **Parse + daftar** = nilai dihitung, tampil di daftar ketersediaan parameter,
  tetapi bukan kartu live.
- **Tidak didukung** = tidak ada jalur data yang terbukti; tidak dihitung.

| Parameter work order | Implementasi RevCore | Tabel / offset | Status tampilan | Bukti / catatan |
|---|---|---|---|---|
| RPM | `LiveSensor.RPM` | dat17/13/11/10 offset 0, 2 byte | Parse + kartu | Log: `RPM=0`; H-Diag punya RPM. |
| TPS | `TPS_PERCENT`, `TPS_ADC`, `TPS_VOLTAGE`, `TPS_DEGREES` | dat17/13/11/10 offset 1–3 | Persen + ADC kartu; volt/derajat di daftar | Log: `TPS=9.375%`. Skala 100/256, ADC 5/256, derajat 0.5. |
| ECT | `ECT`, `ECT_VOLTAGE` | dat17 offset 12/13 utama, 8/9 alternatif; dat13/11/10; dat16 11/12 | Parse + kartu | Bias −40 °C. Fallback hanya saat byte utama `0xFF`. |
| IAT | `IAT`, `IAT_VOLTAGE` | dat17/13/11/10 offset 7; dat16 14 | Parse + kartu | Bias −40 °C. |
| MAP | `MAP`, `MAP_VOLTAGE` | dat13/11/10 offset 9; dat16 16 | Parse + kartu | Tidak ada di dat17; log sesi ini tidak memuat dat11/13/10. |
| Battery voltage | `BATTERY` | dat17 offset 10; dat13/11/10 10/12; dat16 17 | Parse + kartu | Skala 0.1 V. |
| Injector duration | `INJECTOR` | dat17 11; dat13/11/10 11/14; dat16 19 (1 byte) | Parse + kartu | Skala 1/200 ms. |
| Ignition timing | `IGNITION_ADVANCE` | dat17 13; dat13/11/10 13/16; dat16 20 | Parse + kartu | `0.5 × byte − 64` derajat. |
| IAC | `IACV` | dat11/dat10 byte 18 (respons byte 22) | Parse + kartu | Nilai mentah; referensi membagi 10000 tanpa satuan terbukti. |
| Dual throttle | `AP1/AP2` dan `TP1/TP2` (volt + derajat) | dat16 offset 2–9 | Parse + daftar; bukan kartu | Format jelas dari referensi, tetapi `dat16` **tidak pernah dipolling** di log ini; dukungan ECU belum terbukti. |
| O2 | `O2`, `O2_RAW` | dat20 byte 0 | O2 kartu; O2_RAW daftar | Skala 1/50.993698; hanya narrowband. |
| Fuel trim | `STF` | dat20 byte 1 | Parse + daftar; bukan kartu | Skala 1/128.256516; hanya valid saat mesin berjalan. |
| AFR/lambda | `AFR` | — | **Tidak didukung** | ECU hanya mengirim tegangan O2; AFR tidak diturunkan. Ditampilkan sebagai pesan “tidak didukung”. |
| BAS (bank angle sensor) | Tidak ada sensor terpisah | datD1 byte 4 (rekonstruksi) | Tidak ditampilkan | 3D Chart memakai byte yang sama: `b4==1` berarti BAS ON **dan** SSS ON. Arti fisik bersama ini belum cukup untuk sensor terpisah. H-Diag memakai jalur BASV sendiri. |
| Side stand | `SIDE_STAND` (SSS) | datD1 byte 0 bit 0 | Parse + kartu | Rekonstruksi; UI menampilkan peringatan mismatch. |
| Gear position | `GEAR_POSITION`, `GEAR_STATE` | datD1 byte 6 dan byte 0 | Parse + daftar | Nilai mentah; bukan kartu. |
| Fuel pump status | `FLAG_A` (POM) | datD1 byte 4 | Parse + kartu | Nama fisik direkonstruksi; byte 8 pada respons. |
| Fan status | `FLAG_B` (FAN) | datD1 byte 5 | Parse + kartu | Nama fisik direkonstruksi; byte 9 pada respons. |
| Actuator status | Tidak ada perintah aktuator | — | **Tidak didukung** | RevCore tidak memiliki jalur baca status aktuator terpisah; hanya flag POM/FAN hasil rekonstruksi. |
| FIS/FIZ | `FIS` | — | **Tidak didukung** | Nilai numerik FIS tidak terbukti; sudah dinyatakan `UNSUPPORTED`. |
| COR | `COR` | dat16 byte 10 | Parse + daftar | Tidak dipolling pada log ini. |

## 3. Parameter yang sudah diimplementasikan tetapi tidak menjadi kartu

Nilai berikut dihitung dan muncul di daftar ketersediaan (`EcuInfoScreen`),
tetapi tidak memiliki kartu di dashboard live:

- `AP1/AP2` dan `TP1/TP2` (volt dan derajat)
- `STF`
- `COR`
- `GEAR_STATE`
- `GEAR_POSITION`
- `O2_RAW`

Tidak ditambahkan sebagai kartu karena:

- `dat16` belum pernah terbukti dikirim oleh ECU pada sesi ini;
- `STF`/O2 hanya valid saat mesin berjalan dan belum ada bukti nilai pada
  kendaraan ini;
- status gigi masih rekonstruksi dan dapat menyesatkan jika ditampilkan tanpa
  verifikasi.

## 4. Parameter yang tidak di-parse / tidak didukung

- **BAS** sebagai sensor terpisah: tidak ada bukti pemisahan dari SSS.
- **AFR/lambda**: tidak disediakan ECU; tidak boleh diturunkan dari O2.
- **Actuator status** (mis. status relay/injector per aktuator): tidak ada
  jalur baca yang terbukti.
- **FIS/FIZ**: nilai tidak terbukti.

## 5. Bukti dari log sesi 2026-11-20

- Request yang dikirim hanya `dat17`, `dat20`, dan `datD1`.
- Tidak ada request `dat11`, `dat13`, `dat10`, atau `dat16` pada jendela log.
- Karena itu, parameter MAP/IACV/dual throttle **tidak dapat dinyatakan
  tersedia atau tidak tersedia** hanya dari log ini. Statusnya adalah
  “terimplementasi di source, belum teramati pada kendaraan”.

## 6. Perubahan source

Tidak ada. Audit ini tidak mengubah parser, offset, skala, atau tampilan.

## 7. Pengujian dan regresi

- `:app:testDebugUnitTest`: 335 test, 0 gagal.
- `:app:assembleDebug` dan `:app:compileReleaseKotlin`: berhasil.
- Tidak ada pengujian parameter pada kendaraan; tidak ada klaim hardware.

## 8. Rekomendasi

1. Uji satu per satu di Vario 150 SmartKey: poll `dat11`, `dat13`, `dat10`,
   `dat16`, catat apakah ECU menjawab dan berapa panjang payload.
2. Bandingkan nilai dual throttle dengan posisi handle fisik sebelum
   menambahkannya sebagai kartu.
3. Verifikasi BAS dengan memiringkan kendaraan; jangan menyimpulkan dari satu
   byte yang juga membawa SSS.
4. Pertahankan AFR sebagai tidak didukung sampai ECU benar-benar mengirim
   kanal AFR/lambda.
