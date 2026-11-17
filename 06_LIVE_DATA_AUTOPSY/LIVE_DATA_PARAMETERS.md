# Live Data & Sensor — Parameter, Aliran, dan Batas

**Status:** SOURCE VERIFIED (daftar parameter & metode) · **RUNTIME: BLOCKED** (tanpa ECU) · **NO RAW RX CAPTURE**.

---

## 1. Daftar parameter (dari string UI, urutan tampil)

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
| 16–19 | Handle grip position 1/2 Volt & ° | Volt, ° | DBW |
| 20–23 | Throttle Position 1/2 Volt & ° | Volt, ° | DBW (TWIN) |
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

Catatan: 29 string seri `Gear Status` + `Netral/OnGear/ONGear` dan angka `6 5 4 2 N` menunjukkan tampilan gigi.

## 2. Aliran data

```text
LoopDat17(delay)  → SendCommand("dat17"/byte) → respons
                  → parse (offset tabel per ECM)
                  → UpdateGridView / UpdateRows (Diag) 28 parameter
                  → ChartLiveMap (RPM, TPS, AD, AFR) + AGauge
                  → pointer live di tabel map (chkLivePointer)
                  → DYNO (HP/TQ dari RPM & torsi terhitung)
```

- `dat10`, `dat11`, `dat13`, `dat16`, `dat17`, `dat20`, `datD1` adalah tabel berbeda (lihat `COMMAND_SURFACE.md`).
- `Diag.UpdateGridView(28)` / `UpdateRows(28)` dan versi `2` (12) menunjukkan jumlah field per tabel tidak seragam → FLASHPRO memilih tabel sesuai `TableType` ECU.
- `StopLoopDat17` + `CloseFormResources` menghentikan polling dengan aman.

## 3. Konversi volt → nilai

Tersedia metode: `MapVoltageToValue`, `MapVoltageToValueig`, `Clamp`, `ConvertByteToValue(2)`, `FindClosestIndex`, `FindAndPrintClosestValues(2)`.
Ini membuktikan **ada** pemetaan voltase ke nilai fisis dan pencarian titik terdekat di tabel, tetapi **rumus/koefisiennya tidak dapat diambil** (tanpa IL). Status: **NOT VERIFIED**.

## 4. Tampilan

- **ChartLiveMap**: channel RPM/TPS/AD/AFR (checkbox), max-hold (`MAX RPM/TPS/AD/AFR`), pause/resume auto-scroll, pointer live, screenshot PNG, tema warna.
- **AGauge**: gauge analog (RPM dll.).
- **Diag**: grid dua kolom `Parameter` / `Value`, DTC list.
- **DYNO**: `Max HP`, `RPM at Max HP`, `Max TQ`, `AFR`, tombol Start/Stop/Refresh/Delete.

## 5. DTC

37 kode format `X-Y` (Honda-specific, bukan P0xxx). Contoh: `7-1` ECT low, `8-2` TP high, `12-1` injector #1, `33-2` ECM EEPROM, `54-1/2` bank angle, `86-1` serial communication.
Metode: `dtc`, `dtc2`, `dtc3`, `dtc4`, `ValidateChecksum`, `Checksum8BitHonda`.
Daftar lengkap: `05_ECU_IDENTIFICATION/extract/DTC_CODES.csv`.

## 6. Apa yang tidak boleh disimpulkan

- Kecepatan polling (`LoopDat17(delay)`), timeout, dan jumlah byte respons **tidak diketahui**.
- Apakah RPM dihitung dari periode pulsa atau field 16-bit **tidak diketahui**.
- AFR: parameter "Air Fuel Ratio" ada, tetapi apakah dari sensor wideband, perhitungan dari O2 sempit, atau kurva pengguna **tidak diketahui**.
- Semua nilai di atas adalah **label UI**, bukan hasil pengukuran.
