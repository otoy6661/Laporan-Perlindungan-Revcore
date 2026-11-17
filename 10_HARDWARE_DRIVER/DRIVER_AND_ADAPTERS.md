# Perangkat Keras, Driver, dan Adaptor

**Status:** RUNTIME VERIFIED untuk lingkungan; perilaku adaptor: **BLOCKED** (tidak ada perangkat terhubung).

---

## 1. Kebutuhan perangkat

FLASHPRO tidak memakai ELM327/CAN/J2534. Ia membutuhkan adaptor **FTDI** yang dapat:

1. Berbicara **K-Line** ke ECU (3 kabel: K-Line, GND, +12V), dan
2. Melakukan **bit-bang I2C** untuk EEPROM/SCU smartkey (SDA, SCL, GND, VCC).

Satu adaptor yang sama melayani keduanya — di aplikasi, `Class155` (bit-bang) dipakai `Form11`, `Class15` (UART/ISO) dipakai jalur ECU.

## 2. Pin yang didefinisikan (dari field/metode)

| Sinyal | Nilai | Bukti |
|---|---|---|
| `PIN_SCL` | 4 | field `Form11` |
| `PIN_SDA_DRV` | 0x10 | field `Form11` |
| `PIN_SDA_SENSE` | 0x08 | field `Form11` |
| Mode | `FT_SetBitMode` / `FT_GetBitMode` | P/Invoke |
| Kecepatan I2C | dari `SetBaudRate` pada wrapper bit-bang | metode |
| Tipe EEPROM | `AT24C02`, `AT24C04` | enum `EepromType` |

Nilai pin tersebut adalah **mask bit** D2XX (DB0..DB7), bukan nomor pin fisik. Pemetaan ke header adaptor bergantung pada produk; tutorial aplikasi hanya menyebut warna kabel untuk K-Line.

## 3. Wiring yang diajarkan aplikasi

**K-Line (ECU):**
```
KUNING → K-Line ECU
HITAM  → GND ECU
MERAH  → +12V PSU → +12V ECU
```

**Smartkey/SCU (I2C):**
```
SDA, SCL, GND, VCC  (cek polaritas; WP harus LOW saat menulis EEPROM)
```

String `Pastikan pin WP LOW (nonaktif)` dan `Selesai, tapi {0} byte != 0x{1:X2} (cek WP)` menunjukkan aplikasi mendeteksi write-protect EEPROM.

## 4. Lingkungan yang terverifikasi (2026-11-18)

| Komponen | Temuan |
|---|---|
| `ftd2xx.dll` (System32 & SysWOW64) | **3.2.21.1**, FTDI Ltd. |
| Layanan `ftdibus` | Manual, **Stopped** |
| Entri perangkat FTDI | `VID_0403&PID_6001` serial `A5069RR4` (USB Serial Converter) dan `A50285BI` (FT232R USB UART, kelas `libusb-win32 devices`) — **Present=False** |
| Adaptor terhubung saat ini | **tidak ada** |
| COM port | COM1 (motherboard), COM3/4/6/7 (Bluetooth), COM5/8 (sisa FTDI), COM9–16 (MediaTek/Android) — tidak dipakai FLASHPRO |

Kesimpulan: driver D2XX tersedia, tetapi **tidak ada perangkat keras** untuk pengujian. Semua uji ECU tetap BLOCKED.

## 5. Installer & driver tambahan

- Installer FLASHPRO (Inno Setup 6.5.0, AppVersion 7) memuat `REMAP CABLE DRIVER.exe` dan menjalankannya dengan `/S` bila driver CDM belum ada.
- Berarti vendor menganggap driver FTDI prasyarat, bukan opsional.
- Lokasi instalasi: `C:\Program Files (x86)\FLASHPRO.inc`.

## 6. Catatan teknis yang membedakan FLASHPRO

| Aspek | FLASHPRO | Implikasi |
|---|---|---|
| Akses perangkat | D2XX langsung (`ftd2xx.dll`) | Tidak bergantung pada nomor COM; timing dikontrol aplikasi |
| K-Line | bit-bang + UART/ISO | Dapat melakukan slow init dan fast init |
| I2C EEPROM | bit-bang pin | Fitur smartkey/SCU tidak butuh perangkat tambahan |
| Multi-vendor | Keihin, Shindengen, Yamaha, Suzuki (smartkey) | Bukan aplikasi Honda-only secara fungsional |

## 7. Risiko yang perlu dicatat (bukan tuduhan)

- Bit-bang + +12V ECU berarti kesalahan wiring/polaritas dapat merusak ECU (aplikasi sendiri memperingatkan ini).
- Dua entri FTDI dengan driver berbeda (D2XX vs libusb-win32) berpotensi konflik bila perangkat yang sama dipakai dua tool; FLASHPRO memerlukan D2XX.
- Tidak ada pengujian hardware dalam BE-12; seluruh klaim fungsional perangkat tetap **NOT TESTED**.
