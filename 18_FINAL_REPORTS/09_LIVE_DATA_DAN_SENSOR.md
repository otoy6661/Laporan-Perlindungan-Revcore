# 09 — LIVE DATA DAN SENSOR

**Work order:** BE-12
**Status:** SOURCE VERIFIED (label & metode) · pengukuran **BLOCKED** · **NO RAW RX CAPTURE**
**Sumber:** `06_LIVE_DATA_AUTOPSY/LIVE_DATA_PARAMETERS.md`

---

## 1. Daftar parameter (36 label UI)

| # | Parameter | Satuan | Kelompok |
|---:|---|---|---|
| 1 | Engine RPM | RPM | mesin |
| 2 | Throttle Position Volt | Volt | TP |
| 3 | Throttle Position | ° / % | TP |
| 4 | Engine Temp Volt | Volt | ECT |
| 5 | Engine Temp | °C | ECT |
| 6 | Intake Air Temperartur Volt *(sic)* | Volt | IAT |
| 7 | Intake Air Temperartur | °C | IAT |
| 8 | Manifold Absolute Pressure Volt | Volt | MAP |
| 9 | Manifold Absolute Pressure | kPa (inferensi) | MAP |
| 10 | Voltage Battery | Volt | listrik |
| 11 | Injection Duration | ms | injeksi |
| 12 | MODE | 0–4 | mode map |
| 13 | Ignition Timming *(sic)* | ° | pengapian |
| 14 | Vehicle Speed Sensor | km/h | VSS |
| 15 | TableType | — | meta tabel |
| 16–19 | Handle grip 1/2 Volt & ° | Volt, ° | DBW |
| 20–23 | Throttle Position 1/2 Volt & ° | Volt, ° | DBW twin |
| 24 | COR | — | cut-off |
| 25 | Oxygen Sensor | status | O2 |
| 26 | Oxygen Sensor Volt | Volt | O2 |
| 27 | Short term Fuel Trim | % | bahan bakar |
| 28 | Air Fuel Ratio | :1 | turunan |
| 29 | Fast Idle Step | step | IACV |
| 30 | Bank Angle Sensor | status | safety |
| 31 | Switch Starter | ON/OFF | input |
| 32 | Side Stand Switch | ON/OFF | safety |
| 33 | Gear Status | N/1..6 | transmisi |
| 34 | Fuel Pump | ON/OFF | aktuator |
| 35 | Cooling Fan | ON/OFF | aktuator |
| 36 | Gear Position | N/1..6 | transmisi |

Label adalah **kosakata UI**, bukan hasil pengukuran.

## 2. Aliran data

```text
LoopDat17(delay) → SendCommand("dat17"/byte) → respons
  → parse offset per ECM
  → UpdateGridView/UpdateRows (Diag, 28 parameter)
  → ChartLiveMap (RPM/TPS/AD/AFR) + AGauge
  → pointer live di tabel map (chkLivePointer)
  → DYNO (HP/TQ)
```

`diag.UpdateGridView(28)`/`UpdateRows(28)` dan versi `2` (12) menunjukkan jumlah field per tabel tidak seragam; FLASHPRO memilih tabel sesuai `TableType` ECU.

## 3. Konversi volt → nilai

Metode yang ada: `MapVoltageToValue`, `MapVoltageToValueig`, `Clamp`, `ConvertByteToValue(2)`, `FindClosestIndex`, `FindAndPrintClosestValues(2)`.

Ini membuktikan **adanya** pemetaan dan pencarian titik terdekat, tetapi rumus/koefisien **tidak dapat diambil** (tanpa IL). Status: **NOT VERIFIED**.

## 4. Tampilan

- **ChartLiveMap**: RPM/TPS/AD/AFR, max-hold, pause/resume auto-scroll, pointer live, screenshot PNG, tema warna.
- **AGauge**: gauge analog.
- **Diag**: grid `Parameter`/`Value`, DTC list.
- **DYNO**: `Max HP`, `RPM at Max HP`, `Max TQ`, `AFR`, Start/Stop/Refresh/Delete.

## 5. DTC

37 pasangan kode–deskripsi format `X-Y` (Honda-specific). Contoh: `7-1` ECT low, `8-2` TP high, `12-1` injector #1, `33-2` ECM EEPROM, `54-1/2` bank angle, `86-1` serial communication. Metode: `dtc`..`dtc4`, `ValidateChecksum`, `Checksum8BitHonda`.

## 6. Yang tidak boleh disimpulkan

- Kecepatan polling (`LoopDat17(delay)`), timeout, jumlah byte respons **tidak diketahui**.
- RPM dari periode pulsa atau field 16-bit **tidak diketahui**.
- AFR dari wideband, perhitungan O2 sempit, atau kurva pengguna **tidak diketahui**. Karena itu baris AFR tidak boleh dianggap dukungan wideband.
- Semua nilai adalah label, bukan pengukuran.

## 7. Perbandingan dengan RevCore

RevCore memiliki **33** `LiveSensor` dengan state eksplisit (`VALID`/`NOT_RESPONDING`/`STALE`/…). FLASHPRO memiliki **36** label tetapi **tidak** memiliki state; nilai hilang dapat tampil sebagai 0. Kelebihan FLASHPRO: Fuel Pump, Cooling Fan, Bank Angle, Starter, Side Stand, Fast Idle Step — yang tidak ada di RevCore. Offset dan rumus semuanya masih menunggu capture.
