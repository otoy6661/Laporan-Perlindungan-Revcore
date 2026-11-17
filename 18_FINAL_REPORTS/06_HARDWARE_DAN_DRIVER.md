# 06 — HARDWARE DAN DRIVER

**Work order:** BE-12
**Status:** RUNTIME VERIFIED (lingkungan) · perilaku adaptor **BLOCKED**
**Sumber:** `10_HARDWARE_DRIVER/DRIVER_AND_ADAPTERS.md`, `04_PROTOCOL_AUTOPSY/TRANSPORT_AND_KLIN.md`

---

## 1. Kebutuhan perangkat

FLASHPRO **tidak** memakai ELM327, CAN, atau J2534. Ia membutuhkan adaptor **FTDI** yang dapat:

1. berbicara **K-Line** ke ECU (K-Line, GND, +12V), dan
2. melakukan **bit-bang I2C** untuk EEPROM/SCU smartkey (SDA, SCL, GND, VCC).

Satu adaptor melayani keduanya: `Class15` (UART/ISO) untuk ECU, `Class155` (bit-bang) untuk EEPROM.

## 2. API yang benar-benar dipanggil

`PINVOKE.tsv` hanya memuat `ftd2xx.dll` (12 fungsi unik):

```
FT_Open, FT_Close, FT_Read, FT_Write, FT_GetQueueStatus,
FT_SetBaudRate, FT_SetDataCharacteristics, FT_Purge,
FT_SetTimeouts, FT_SetLatencyTimer, FT_SetBitMode, FT_GetBitMode
```

Tidak ada `System.IO.Ports`, `SerialPort`, atau `CreateFile("\\.\COM…")`. Artinya FLASHPRO **tidak memakai COM port** meskipun driver VCP memasang COM5/COM8; semua timing dikendalikan aplikasi melalui D2XX.

## 3. Pin dan wiring

| Sinyal | Nilai | Bukti |
|---|---|---|
| `PIN_SCL` | 4 | field `Form11` |
| `PIN_SDA_DRV` | `0x10` | field `Form11` |
| `PIN_SDA_SENSE` | `0x08` | field `Form11` |
| Mode | `FT_SetBitMode`/`FT_GetBitMode` | P/Invoke |
| EEPROM | AT24C02, AT24C04 | enum `EepromType` |

Nilai pin adalah **mask bit** DB0..DB7, bukan nomor pin fisik. Pemetaan ke header bergantung produk.

Wiring yang diajarkan aplikasi:

```text
K-Line:   KUNING → K-Line ECU ; HITAM → GND ; MERAH → +12V
Smartkey: SDA, SCL, GND, VCC ; WP harus LOW saat menulis
```

String `Pastikan pin WP LOW (nonaktif)` dan `{0} byte != 0x{1:X2} (cek WP)` menunjukkan deteksi write-protect.

## 4. Lingkungan terverifikasi (2026-11-18)

| Komponen | Temuan |
|---|---|
| `ftd2xx.dll` System32/SysWOW64 | **3.2.21.1**, FTDI Ltd. |
| Layanan `ftdibus` | Manual, **Stopped** |
| FTDI historis | `VID_0403&PID_6001` `A5069RR4` (USB Serial Converter) dan `A50285BI` (FT232R, kelas `libusb-win32`) — **Present=False** |
| Adaptor terhubung | **tidak ada** |
| COM port | COM1, COM3/4/6/7 (Bluetooth), COM5/8 (sisa FTDI), COM9–16 (MediaTek) — tidak dipakai |

Kesimpulan: driver tersedia, perangkat tidak ada. Semua uji ECU **BLOCKED**.

## 5. Driver installer

Installer FLASHPRO (Inno Setup 6.5.0, AppVersion 7) memuat `REMAP CABLE DRIVER.exe` dan menjalankannya `/S` bila driver CDM belum ada. Vendor menganggap driver FTDI **prasyarat**, bukan opsional.

## 6. Perbedaan arsitektural

| Aspek | FLASHPRO | Implikasi |
|---|---|---|
| Akses perangkat | D2XX langsung | tidak bergantung nomor COM; timing milik aplikasi |
| K-Line | bit-bang + UART/ISO | dapat slow init dan fast init |
| I2C EEPROM | bit-bang pin | fitur smartkey tanpa perangkat tambahan |
| Multi-vendor | Keihin, Shindengen, Yamaha/Suzuki (smartkey) | bukan Honda-only secara fungsional |

## 7. Risiko (faktual)

- Bit-bang + +12V ECU: kesalahan wiring/polaritas dapat merusak ECU; aplikasi sendiri memperingatkan.
- Dua entri FTDI dengan driver berbeda (D2XX vs libusb-win32) berpotensi konflik; FLASHPRO memerlukan D2XX.
- Tidak ada pengujian hardware dalam BE-12; seluruh klaim fungsional perangkat tetap **NOT TESTED**.
