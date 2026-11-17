# RevCore vs FLASHPRO — Perbandingan Teknis

**Sumber RevCore:** `C:\Users\<USER>\Documents\Qoder\work\revcore` (read-only). Versi source `versionName 1.0`/`versionCode 1`; APK rilis 161126; repo publik v0.3.0 (commit 4160763).
**Sumber FLASHPRO:** dokumen FASE I–II BE-12.
**Label:** IMPLEMENTED / PARTIAL / STUB / ABSENT / NOT VERIFIED / HARDWARE PENDING.

---

## 1. Ringkasan posisi

| Dimensi | FLASHPRO (Windows) | RevCore (Android) |
|---|---|---|
| Bentuk | .NET 4.8 WinForms, Enigma, lisensi hardware | Kotlin/Compose, APK, integritas 10-gate |
| Transport | FTDI D2XX (bit-bang + UART) | USB-serial + driver FTDI Android |
| Pengetahuan ECU | 160 BIN, 157 part code, 29 seri | 489 ECM, 163 profil VomConfig, 162 map |
| Live data | 7 tabel (`dat10/11/13/16/17/20/D1`) + 36 parameter UI | 7 tabel yang sama, 33 sensor, state validitas |
| Edit map | Offset VomConfig, 2D/3D, auto-map, ekspresi | Offset VomConfig, tabel heatmap, undo/redo, import `.map` |
| Flash ECU | Pipeline + recovery (tidak dapat diaudit) | Default-deny, **tanpa** rutin tulis/erase/verify |
| Smartkey | I2C EEPROM, copy SCU, Honda/Yamaha/Suzuki | **Absent** |
| DTC | 37 kode | 15 entri database |
| Dyno/3D | Ada | Absent |
| Lisensi | Offline hardware-bound | Tidak ada |
| Update | GitHub + ZIP berpassword | Tidak ada (integritas APK) |

## 2. Kesamaan yang terverifikasi

1. **Skema VomConfig identik.** Field `tpsh/rpmh/iaph/feul1..3/iap/ig1..4/limit1..7/konversrpm/konversilmtr/o2/o2c/immo/mode0..4/bass/iacv/ect/iat/vss/mapp` + mask ada di kedua sisi. RevCore membacanya dari APK FLASHPRO Android; FLASHPRO Windows memakai urutan field yang sama.
2. **Tabel live data sama.** RevCore mendefinisikan `flashpro.dat10/11/13/16/17/20/D1`; FLASHPRO Windows memiliki metode `dat10/11/13/16/17/20` dan `Diag.datD1`. Ini **SAME FRAME FAMILY** pada level tabel, bukan bukti frame byte.
3. **Keluarga ECU sama.** Keihin/Shindengen dengan varian H8C/M32R/V850/RH850.
4. **Checksum keluarga sama.** RevCore: `KEIHIN_16BIT_ADD`, `KEIHIN_8BIT_INVERTED`, `SHINDENGEN_ADDITIVE`, `SHINDENGEN_CRC16` (poly `0xA001`). FLASHPRO: `Checksum8Bit`, `Checksum8BitHonda`, `Sum8Bit`, `Sum32Bit` + auto-checksum per vendor. **Nama tidak membuktikan algoritma identik.**

## 3. Keunggulan FLASHPRO yang nyata (bukan klaim)

| Fitur | Bukti | Catatan |
|---|---|---|
| Tulis ECU end-to-end | `WriteFlash`, `CompareMemory`, auto-checksum, pesan GOOD/BAD | Rutin ada; kualitas **NOT VERIFIED** (tanpa uji) |
| Recovery Shindengen | `GetShindengenRecoveryKey`, `Mode Recovery ECM` | Ada jalur; belum terbukti |
| Baca 48 KB + log | `ReadECU.Read48`, `read48k.log`, hex viewer | Fitur konkret |
| Smartkey/SCU | I2C bit-bang, copy SCU, verify per page | Di luar cakupan RevCore saat ini |
| Live UI | gauge, chart, max-hold, pointer di tabel | RevCore punya state lebih aman, UI lebih minimal |
| 2D/3D map & auto-map | `Graph3D`, `tps2d/rpm2d/iap2d`, `Automaping` | RevCore: heatmap tabel + line chart |
| Multi-merek di smartkey | Yamaha/Suzuki | Honda-only untuk ECU |

## 4. Keunggulan RevCore yang nyata

| Fitur | Bukti | Catatan |
|---|---|---|
| Database lebih besar | `ecm_database.json` 489; profil 163 | FLASHPRO 160/157 |
| Integritas aplikasi | 10-gate, trust record, APK manifest | FLASHPRO hanya lisensi vendor |
| State live data eksplisit | `LiveParameterState` (VALID/STALE/…), tidak pernah 0 palsu | FLASHPRO tidak punya |
| Keamanan flash | default-deny, `FlashCapabilities` semua false | FLASHPRO langsung menulis |
| Map crypto & round-trip | `MapCrypto`, `MapEditor.verifyRoundTrip` | FLASHPRO punya enkripsi, tanpa verifikasi round-trip publik |
| Audit trail | `CommunicationSniffer`, log terstruktur | FLASHPRO hanya `read48k.log` |
| Cross-check identitas | `HondaIdentifierParser`, canonicalizer | FLASHPRO menampilkan ID tanpa normalisasi terdokumentasi |

## 5. Gap yang tidak boleh ditutup dengan menyalin

- **Protokol tulis.** FLASHPRO tidak dapat diaudit (IL terenkripsi, tanpa capture). Menyalin perilakunya tanpa bukti akan melanggar prinsip default-deny RevCore.
- **Recovery.** Sama: nama fungsi bukan bukti urutan/kunci.
- **Checksum.** Perlu vektor uji, bukan asumsi kesamaan nama.

## 6. Status per area (ringkas)

| Area | FLASHPRO | RevCore |
|---|---|---|
| Identifikasi ECU | SOURCE VERIFIED, runtime BLOCKED | IMPLEMENTED, HARDWARE PENDING |
| Live data | SOURCE VERIFIED, no capture | IMPLEMENTED, HARDWARE PENDING |
| DTC | 37 kode (string) | 15 entri (kode) |
| Baca ROM | 48 KB (kode) | PARTIAL (RomBinary, tanpa rutin baca penuh) |
| Edit map | IMPLEMENTED | IMPLEMENTED |
| Flash tulis | Ada, NOT VERIFIED | ABSENT by design |
| Recovery | Ada, NOT VERIFIED | STUB state only |
| Smartkey | IMPLEMENTED | ABSENT |
| Dyno | IMPLEMENTED | ABSENT |
| Update | IMPLEMENTED | ABSENT |

## 7. Kesimpulan komparatif

FLASHPRO adalah **aplikasi lengkap untuk alur kerja bengkel Honda** (identifikasi → live → edit → flash → recovery → smartkey), tetapi bukti internalnya tertutup. RevCore adalah **platform yang lebih ketat dan lebih luas database-nya**, dengan protokol live yang sudah sejajar, namun sengaja belum menulis ECU. Selisih utama bukan jumlah fitur, melainkan **kesiapan bukti untuk operasi berisiko**.
