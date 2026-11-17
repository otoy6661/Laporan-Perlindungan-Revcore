# FLASHPRO vs TunerPro RT — Perbandingan Fungsional-Teknis

**Sumber:** FLASHPRO (BE-12, dokumen FASE I–II) · TunerPro RT (BE-11, `REVCORE_BE11_TUNERPRO_AUTOPSY/14_FINAL_REPORTS`).
**Prinsip:** membandingkan mekanisme, bukan jumlah menu. Label: EXACT MATCH / SAME FAMILY / DIFFERENT IMPLEMENTATION / NOT FOUND / INSUFFICIENT EVIDENCE.

---

## 1. Posisi masing-masing

| Aspek | FLASHPRO | TunerPro RT |
|---|---|---|
| Jenis produk | Aplikasi **Honda-specific** (Keihin/Shindengen) + smartkey | **Platform generik** definisi-driven |
| Transport | FTDI D2XX langsung (K-Line bit-bang/UART) | Serial Win32 (`SetCommState`), port dari ADX |
| Pengetahuan kendaraan | Di kode + database 160 BIN + offset per ECM | Di ADX/XDF (definisi pengguna/vendor) |
| Flash ECU | Ada pipeline (erase/tulis/verify/checksum/recovery) | **Tidak ada** |
| Pemrogram chip/emulator | Tidak ada | Ada (Moates AutoProm/PromIO) |
| Lisensi | Aktivasi offline hardware-bound | (tidak dianalisis di BE-11) |

## 2. Matriks teknis

| Area | FLASHPRO | TunerPro | Klasifikasi |
|---|---|---|---|
| Model perintah | Token metode `dat10/11/13/16/17/20/D1`, `SendCommand(5)`; wire **tidak diketahui** | ADX: kirim hex, header/footer, body/payload, timeout | DIFFERENT IMPLEMENTATION |
| Framing | Tetap per vendor (inferensi), detail NOT VERIFIED | Statis/variabel + header/footer (didefinisikan ADX) | INSUFFICIENT EVIDENCE |
| Baud | Tidak terbaca | Properti ADX/per perintah | DIFFERENT IMPLEMENTATION |
| Checksum frame | `Checksum8Bit`, `Checksum8BitHonda`, `Sum8Bit`, `Sum32Bit` (nama) | Flag `SNDCMDCHECKSUM`; algoritma via plugin | INSUFFICIENT EVIDENCE |
| Checksum image | `ShindengenAutoChecksum`, `KeihinAutoChecksum` (auto) | XDF deklaratif + plugin | DIFFERENT IMPLEMENTATION |
| Live data | Tabel tetap per ECU (36 parameter UI) | Datastream ADX bebas (item/bit/lookup) | DIFFERENT IMPLEMENTATION |
| Nilai hilang | Tidak ada state eksplisit | Tidak ada state; nilai bisa 0 | SAME (keduanya lemah) |
| Edit BIN | Offset per profil VomConfig + operasi sel | XDF absolut/stride + MATH | SAME FAMILY, beda format |
| Format map | `.map` terenkripsi AES + hash | XDF (XML) | DIFFERENT IMPLEMENTATION |
| Database | 160 BIN embedded, 157 part code | 174 XDF, 700 BIN (dataset BE-11), 3 ADX | DIFFERENT IMPLEMENTATION |
| Identifikasi ECU | K-Line + EEPROM keyless | Tidak ada; pengguna memilih definisi | NOT FOUND di TunerPro |
| DTC | 37 kode Honda `X-Y`, 4 sumber | ALDL DTC (definisi) | DIFFERENT COMMAND |
| Dynamometer | Simple Dyno internal | Tidak ada (data log saja) | NOT FOUND di TunerPro |
| Smartkey/EEPROM | I2C bit-bang, copy SCU, multi-merek | Tidak ada | NOT FOUND di TunerPro |
| Update | Feed GitHub + ZIP berpassword | (tidak dianalisis) | INSUFFICIENT EVIDENCE |
| Hardware | FTDI FT232 + adaptor K-Line | Moates AutoProm/PromIO, serial | DIFFERENT IMPLEMENTATION |

## 3. Perbedaan yang paling menentukan

1. **Pengetahuan vs definisi.** FLASHPRO membawa offset, tabel live, dan checksum di dalam kode/database; TunerPro menyerahkan semuanya ke ADX/XDF. Konsekuensi: FLASHPRO "langsung jalan" untuk Honda yang didukung, tetapi menambah ECU baru berarti update aplikasi; TunerPro fleksibel untuk apa pun yang punya definisi, tetapi tidak tahu Honda tanpa ADX yang benar.
2. **Flash vs non-flash.** Hanya FLASHPRO yang memiliki jalur tulis ECU (dengan segala risikonya). TunerPro unggul di pemrograman chip/emulator, bukan flash via K-Line.
3. **Live data.** FLASHPRO memakai tabel polling tetap; TunerPro memakai mesin transaksi generik dengan kontrol timeout/echo yang lebih eksplisit. Untuk diagnostik Honda, definisi FLASHPRO lebih langsung; untuk eksperimen protokol, TunerPro lebih terbuka.
4. **Bukti protokol.** Keduanya **tidak** memberikan frame Honda yang dapat diaudit: FLASHPRO menyembunyikan di IL terenkripsi; TunerPro menyembunyikan di ADX terenkripsi. Klaim kompatibilitas silang tidak dapat dibuat.

## 4. Yang tidak boleh disimpulkan

- "FLASHPRO lebih lengkap" hanya benar pada fitur Honda-specific yang terlihat; TunerPro memiliki kemampuan (emulator, XDF, plugin) yang FLASHPRO tidak punya.
- Tidak ada bukti bahwa frame FLASHPRO sama dengan ADX Honda mana pun.
- Tidak ada pengujian hardware untuk keduanya di BE-12/BE-11.

## 5. Nilai bagi RevCore

- Dari FLASHPRO: model offset VomConfig, alur identifikasi, dan daftar perangkat keras yang realistis.
- Dari TunerPro: model timeout/echo dan pemisahan definisi dari engine — RevCore saat ini menaruh pengetahuan Honda di kode, yang lebih aman tetapi kurang fleksibel.
