# Gap Analysis RevCore — Prioritas Berbasis Bukti

**Basis:** perbandingan `REVCORE_vs_FLASHPRO.md` + bukti FASE I–II. RevCore diverifikasi pada `work/revcore` (`versionName 1.0`, `versionCode 1`); repo publik `v0.3.0` = `4160763`.
**Arti prioritas:** P0 = kebenaran/keselamatan atau bukti yang wajib ada; P1 = parity fungsional inti; P2 = nilai tambah; P3 = opsional.
**Kolom:** Evidence (status) · Impact · Effort (S/M/L) · Risk · Dependency.

---

## P0 — Wajib sebelum klaim apa pun tentang ECU advance

| # | Gap | Evidence | Impact | Effort | Risk | Dependency |
|---:|---|---|---|---|---|---|
| P0-1 | Protokol tulis/erase/verify ECU **belum terbukti** (FLASHPRO pun tidak dapat diaudit) | FLASHPRO `09_FLASHING_RECOVERY` (SOURCE VERIFIED, NOT VERIFIED); RevCore `FlashEngine` default-deny | Tidak boleh mengklaim flash; kesalahan = brick ECU | L | Kritis | Adaptor + ECU donatur + capture logic analyzer |
| P0-2 | Algoritma checksum belum divalidasi dengan vektor | FLASHPRO nama fungsi (NOT VERIFIED); RevCore 4 tipe (IMPLEMENTED) | Salah checksum = ECU menolak/brick | M | Tinggi | ≥3 image BIN valid per keluarga |
| P0-3 | Database DTC RevCore 15 entri vs FLASHPRO 37 | `HondaDtcDatabase.kt` (15); `DTC_CODES.csv` (37) | Diagnostik tidak lengkap | S | Rendah | Pemetaan `X-Y` → P-code lewat manual servis |
| P0-4 | Parameter live data belum lengkap | FLASHPRO 36 label; RevCore 33 `LiveSensor` (tidak ada Fuel Pump, Cooling Fan, Bank Angle, Starter, Side Stand, Fast Idle Step) | Diagnostik aktuator/safety tidak terlihat | M | Sedang | Offset harus dikonfirmasi lewat capture |
| P0-5 | Recovery ECU hanya state, tanpa rutin | FLASHPRO `GetShindengenRecoveryKey` (nama saja); RevCore `RECOVERY_REQUIRED` | Tidak ada pemulihan bila gagal | L | Kritis | Sama dengan P0-1 |

## P1 — Parity inti

| # | Gap | Evidence | Impact | Effort | Risk | Dependency |
|---:|---|---|---|---|---|---|
| P1-1 | Baca ROM penuh / 48 KB + log | FLASHPRO `ReadECU.Read48`, `read48k.log`; RevCore tidak punya rutin baca penuh | Backup sebelum tuning | M | Sedang | P0-1 (protokol baca) |
| P1-2 | UI live setara (gauge, max-hold, chart multi-channel) | FLASHPRO `ChartLiveMap`, `AGauge`; RevCore `LiveDataScreen` minimal | Pengalaman tuning | M | Rendah | Tidak ada |
| P1-3 | Compare/auto-map/2D-3D map | FLASHPRO `Automaping`, `Graph3D`, `tps2d/rpm2d/iap2d`; RevCore punya heatmap + line chart | Produktivitas edit | M–L | Rendah | Definisi tabel lengkap |
| P1-4 | Mode 0–4, limiter 1–7, switch sensor di UI | FLASHPRO menu `MODE 0..4`, `Limiter 1..7`, `off*`; RevCore MapEditor mendukung switch/scalar | Fitur tuning yang diminta pasar | M | Sedang | Verifikasi offset per profil |

## P2 — Nilai tambah / di luar inti

| # | Gap | Evidence | Impact | Effort | Risk | Dependency |
|---:|---|---|---|---|---|---|
| P2-1 | Smartkey/EEPROM I2C + copy SCU | FLASHPRO `Form11`, `SMK` (SOURCE VERIFIED) | Pasar bengkel kunci | L | Tinggi (hardware) | Adaptor I2C, EEPROM donor |
| P2-2 | Multi-merek smartkey (Yamaha/Suzuki) | Menu FLASHPRO | Cakupan pasar | L | Tinggi | Lisensi/legal + dataset |
| P2-3 | Dyno internal | FLASHPRO `DYNO` | Nilai jual | S–M | Rendah | Data RPM/TPS akurat |
| P2-4 | Update aplikasi | FLASHPRO updater (tanpa signature) | Distribusi | M | **Tinggi keamanan** | Desain update bertanda tangan |

## P3 — Opsional / tidak disarankan

| # | Gap | Alasan |
|---:|---|---|
| P3-1 | Lisensi hardware-bound | Model bisnis berbeda; menambah friksi tanpa nilai teknis |
| P3-2 | 3D graph interaktif | Nilai visual, bukan kapabilitas ECU |
| P3-3 | Meniru updater FLASHPRO | Feed tanpa signature + ZIP berpassword = permukaan serangan; RevCore sebaiknya memakai update bertanda tangan bila perlu |

## 1. Urutan eksekusi yang disarankan

1. **P0-2** (checksum vectors) — bisa dikerjakan tanpa hardware, hasil cepat, mengurangi risiko.
2. **P0-3** (DTC) — murah, langsung terlihat.
3. **P0-1/P0-5** (protokol tulis/recovery) — harus dengan hardware dan prosedur keselamatan; jangan dipercepat.
4. **P0-4** (parameter live) — setelah capture.
5. **P1-1** (baca ROM) — langkah antara menuju flash yang aman.
6. P1-2/P1-3/P1-4 → P2.

## 2. Yang tidak boleh dilakukan

- Menyalin urutan flash dari nama metode FLASHPRO.
- Menganggap checksum "sama" karena namanya mirip.
- Menambah DTC tanpa sumber manual/ECU.
- Mengadopsi updater berpassword tanpa signature.
- Mengubah `FlashCapabilities` menjadi true tanpa bukti bench.

## 3. Ketergantungan tunggal terbesar

Semua P0 (kecuali checksum & DTC) bergantung pada **satu hal**: adaptor FTDI + ECU donor + capture. Tanpa itu, prioritas P0 hanya bisa diselesaikan sebagian, dan status RevCore harus tetap default-deny.
