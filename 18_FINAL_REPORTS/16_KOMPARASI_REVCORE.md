# 16 — KOMPARASI REVCORE

**Work order:** BE-12
**Status:** verifikasi source RevCore (read-only) + bukti FLASHPRO FASE I–II
**Sumber:** `15_REVCORE_COMPARISON/REVCORE_vs_FLASHPRO.md`; RevCore `work/revcore` (versionName 1.0, versionCode 1; repo publik v0.3.0 = `4160763`)

---

## 1. Ringkasan posisi

| Dimensi | FLASHPRO (Windows) | RevCore (Android) |
|---|---|---|
| Bentuk | .NET 4.8 WinForms, Enigma, lisensi hardware | Kotlin/Compose, APK, integritas 10-gate |
| Transport | FTDI D2XX (bit-bang + UART) | USB-serial + driver FTDI Android |
| Pengetahuan ECU | 160 BIN, 157 part, 29 seri | 489 ECM, 163 profil, 162 map |
| Live data | 7 tabel + 36 label | 7 tabel sama, 33 sensor, state validitas |
| Edit map | offset VomConfig, 2D/3D, auto-map, ekspresi | offset VomConfig, heatmap, undo/redo, `.map` |
| Flash ECU | pipeline + recovery (NOT VERIFIED) | default-deny, tanpa rutin tulis |
| Smartkey | I2C EEPROM, copy SCU, Honda/Yamaha/Suzuki | tidak ada |
| DTC | 37 baris | 15 entri |
| Dyno/3D | ada | tidak ada |
| Lisensi | offline hardware-bound | tidak ada |
| Update | GitHub + ZIP berpassword | tidak ada |

## 2. Kesamaan terverifikasi

1. **Skema VomConfig identik.** Field `tpsh/rpmh/iaph/feul1..3/iap/ig1..4/limit1..7/konversrpm/konversilmtr/o2/o2c/immo/mode0..4/bass/iacv/ect/iat/vss/mapp` + mask ada di kedua sisi.
2. **Tabel live data sama.** RevCore mendefinisikan `flashpro.dat10/11/13/16/17/20/D1`; FLASHPRO punya metode `dat10/11/13/16/17/20` dan `Diag.datD1`. **SAME FRAME FAMILY** pada level tabel, bukan byte.
3. **Keluarga ECU sama.** Keihin/Shindengen dengan varian H8C/M32R/V850/RH850.
4. **Keluarga checksum sama.** RevCore: `KEIHIN_16BIT_ADD`, `KEIHIN_8BIT_INVERTED`, `SHINDENGEN_ADDITIVE`, `SHINDENGEN_CRC16` (poly `0xA001`). FLASHPRO: `Checksum8Bit`, `Checksum8BitHonda`, `Sum8Bit`, `Sum32Bit`. Nama tidak membuktikan algoritma identik.

## 3. Keunggulan FLASHPRO yang nyata

| Fitur | Bukti | Catatan |
|---|---|---|
| Tulis ECU end-to-end | `WriteFlash`, `CompareMemory`, auto-checksum, GOOD/BAD | rutin ada; kualitas NOT VERIFIED |
| Recovery Shindengen | recovery key + mode recovery | belum terbukti |
| Baca 48 KB + log | `Read48`, `read48k.log`, hex viewer | konkret |
| Smartkey/SCU | I2C bit-bang, copy SCU, verify per page | di luar cakupan RevCore |
| Live UI | gauge, chart, max-hold, pointer tabel | RevCore lebih aman, UI minimal |
| 2D/3D + auto-map | `Graph3D`, `Automaping` | RevCore heatmap + line chart |
| Multi-merek smartkey | Yamaha/Suzuki | ECU tetap Honda |

## 4. Keunggulan RevCore yang nyata

| Fitur | Bukti | Catatan |
|---|---|---|
| Database lebih besar | 489 ECM; 163 profil | FLASHPRO 160/157 |
| Integritas aplikasi | 10-gate, trust record | FLASHPRO hanya lisensi vendor |
| State live eksplisit | `LiveParameterState` | FLASHPRO bisa 0 palsu |
| Keamanan flash | default-deny | FLASHPRO langsung menulis |
| Map crypto + round-trip | `MapCrypto`, `verifyRoundTrip` | FLASHPRO tanpa verifikasi publik |
| Audit trail | `CommunicationSniffer` | FLASHPRO hanya `read48k.log` |
| Cross-check identitas | `HondaIdentifierParser`, canonicalizer | FLASHPRO tanpa normalisasi terdokumentasi |

## 5. Gap yang tidak boleh ditutup dengan menyalin

- **Protokol tulis:** FLASHPRO tidak dapat diaudit (IL + tanpa capture); menyalin perilakunya melanggar default-deny.
- **Recovery:** nama fungsi bukan bukti urutan/kunci.
- **Checksum:** perlu vektor uji, bukan asumsi kesamaan nama.

## 6. Status per area

| Area | FLASHPRO | RevCore |
|---|---|---|
| Identifikasi ECU | SOURCE, runtime BLOCKED | IMPLEMENTED, HARDWARE PENDING |
| Live data | SOURCE, no capture | IMPLEMENTED, HARDWARE PENDING |
| DTC | 37 baris | 15 entri |
| Baca ROM | 48 KB (kode) | PARTIAL (RomBinary) |
| Edit map | IMPLEMENTED | IMPLEMENTED |
| Flash tulis | ada, NOT VERIFIED | ABSENT by design |
| Recovery | ada, NOT VERIFIED | STUB state |
| Smartkey | IMPLEMENTED | ABSENT |
| Dyno | IMPLEMENTED | ABSENT |
| Update | IMPLEMENTED | ABSENT |

## 7. Kesimpulan

FLASHPRO adalah aplikasi lengkap untuk alur kerja bengkel Honda (identifikasi → live → edit → flash → recovery → smartkey), tetapi bukti internalnya tertutup. RevCore adalah platform yang lebih ketat dan lebih luas database-nya, dengan protokol live yang sudah sejajar, tetapi sengaja belum menulis ECU. Selisih utama bukan jumlah fitur, melainkan **kesiapan bukti untuk operasi berisiko**.
