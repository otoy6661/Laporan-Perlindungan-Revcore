# 19 — GAP ANALYSIS REVCORE

**Work order:** BE-12
**Status:** analisis prioritas berbasis bukti
**Sumber:** `15_REVCORE_COMPARISON/GAP_ANALYSIS.md`

---

## 1. Arti prioritas

P0 = kebenaran/keselamatan atau bukti yang wajib ada; P1 = parity fungsional inti; P2 = nilai tambah; P3 = opsional/tidak disarankan.

## 2. P0 — wajib sebelum klaim ECU advance

| # | Gap | Bukti | Dampak | Usaha | Risiko | Dependensi |
|---:|---|---|---|---|---|---|
| P0-1 | Protokol tulis/erase/verify belum terbukti | FLASHPRO SOURCE/NOT VERIFIED; RevCore default-deny | tidak boleh klaim flash; salah = brick | L | Kritis | adaptor + ECU donor + capture |
| P0-2 | Checksum belum divalidasi dengan vektor | FLASHPRO nama; RevCore 4 tipe | salah checksum = ECU menolak/brick | M | Tinggi | ≥3 image valid per keluarga |
| P0-3 | DTC RevCore 15 vs FLASHPRO 37 | `HondaDtcDatabase.kt` 15; CSV 37 | diagnostik tidak lengkap | S | Rendah | pemetaan `X-Y` → P-code via manual |
| P0-4 | Parameter live belum lengkap | FLASHPRO 36 label; RevCore 33 sensor | aktuator/safety tidak terlihat | M | Sedang | offset via capture |
| P0-5 | Recovery hanya state | FLASHPRO recovery key (nama); RevCore `RECOVERY_REQUIRED` | tidak ada pemulihan saat gagal | L | Kritis | sama dengan P0-1 |

## 3. P1 — parity inti

| # | Gap | Bukti | Dampak | Usaha | Risiko |
|---:|---|---|---|---|---|
| P1-1 | Baca ROM penuh/48 KB + log | `Read48`, `read48k.log`; RevCore belum punya rutin baca penuh | backup sebelum tuning | M | Sedang |
| P1-2 | UI live setara | `ChartLiveMap`, `AGauge`; RevCore minimal | pengalaman tuning | M | Rendah |
| P1-3 | Compare/auto-map/2D-3D | `Automaping`, `Graph3D`; RevCore heatmap/line | produktivitas edit | M–L | Rendah |
| P1-4 | Mode 0–4, limiter 1–7, switch sensor | menu FLASHPRO; RevCore mendukung switch/scalar | fitur tuning | M | Sedang |

## 4. P2 — nilai tambah

| # | Gap | Bukti | Dampak | Usaha | Risiko |
|---:|---|---|---|---|---|
| P2-1 | Smartkey/EEPROM I2C + copy SCU | `Form11`, `SMK` | pasar bengkel kunci | L | Tinggi (hardware) |
| P2-2 | Multi-merek smartkey | menu Yamaha/Suzuki | cakupan pasar | L | Tinggi (legal/dataset) |
| P2-3 | Dyno internal | `DYNO` | nilai jual | S–M | Rendah |
| P2-4 | Updater aplikasi | updater tanpa signature | distribusi | M | **Tinggi keamanan** |

## 5. P3 — opsional/tidak disarankan

| # | Item | Alasan |
|---:|---|---|
| P3-1 | Lisensi hardware-bound | model bisnis berbeda, friksi tanpa nilai teknis |
| P3-2 | 3D graph interaktif | nilai visual, bukan kapabilitas ECU |
| P3-3 | Meniru updater FLASHPRO | feed tanpa signature + ZIP berpassword = permukaan serangan |

## 6. Urutan eksekusi

1. **P0-2** checksum vectors — tanpa hardware, hasil cepat.
2. **P0-3** DTC — murah, langsung terlihat.
3. **P0-1/P0-5** protokol tulis/recovery — dengan hardware & prosedur keselamatan; jangan dipercepat.
4. **P0-4** parameter live — setelah capture.
5. **P1-1** baca ROM — langkah antara menuju flash aman.
6. P1-2/P1-3/P1-4 → P2.

## 7. Yang tidak boleh dilakukan

- Menyalin urutan flash dari nama metode FLASHPRO.
- Menganggap checksum "sama" karena namanya mirip.
- Menambah DTC tanpa sumber manual/ECU.
- Mengadopsi updater berpassword tanpa signature.
- Mengubah `FlashCapabilities` menjadi true tanpa bukti bench.

## 8. Ketergantungan tunggal terbesar

Semua P0 (kecuali checksum & DTC) bergantung pada **satu hal**: adaptor FTDI + ECU donor + capture. Tanpa itu, prioritas P0 hanya bisa diselesaikan sebagian, dan status RevCore harus tetap default-deny.
