# 15 — KOMPARASI TUNERPRO

**Work order:** BE-12
**Status:** analisis komparatif · tidak ada hardware di kedua sisi
**Sumber:** `14_TUNERPRO_COMPARISON/TUNERPRO_vs_FLASHPRO.md` + BE-11 `14_FINAL_REPORTS/10`, `14`

---

## 1. Posisi masing-masing

| Aspek | FLASHPRO | TunerPro RT |
|---|---|---|
| Jenis | aplikasi **Honda-specific** + smartkey | **platform generik** definisi-driven |
| Transport | FTDI D2XX (K-Line bit-bang/UART) | serial Win32, port dari ADX |
| Pengetahuan | kode + 160 BIN + offset per ECM | ADX/XDF (pengguna/vendor) |
| Flash ECU | pipeline ada (NOT VERIFIED) | **tidak ada** |
| Chip/emulator | tidak ada | Moates AutoProm/PromIO |
| Lisensi | offline hardware-bound | tidak dianalisis di BE-11 |

## 2. Matriks teknis

| Area | FLASHPRO | TunerPro | Klasifikasi |
|---|---|---|---|
| Model perintah | token `dat10/11/13/16/17/20/D1`, `SendCommand(5)`; wire tidak diketahui | ADX: kirim hex, header/footer, body/payload, timeout | DIFFERENT IMPLEMENTATION |
| Framing | tetap per vendor (inferensi) | statis/variabel + header/footer | INSUFFICIENT EVIDENCE |
| Baud | tidak terbaca | properti ADX | DIFFERENT IMPLEMENTATION |
| Checksum frame | nama fungsi | flag `SNDCMDCHECKSUM` + plugin | INSUFFICIENT EVIDENCE |
| Checksum image | auto per vendor | XDF deklaratif + plugin | DIFFERENT IMPLEMENTATION |
| Live data | tabel tetap per ECU (36 label) | datastream ADX bebas | DIFFERENT IMPLEMENTATION |
| Nilai hilang | tanpa state | tanpa state | SAME (keduanya lemah) |
| Edit BIN | offset VomConfig | XDF absolut/stride + MATH | SAME FAMILY |
| Format map | `.map` AES | XDF XML | DIFFERENT IMPLEMENTATION |
| Database | 160 BIN, 157 part | 174 XDF, 700 BIN (dataset BE-11), 3 ADX | DIFFERENT IMPLEMENTATION |
| Identifikasi ECU | K-Line + EEPROM keyless | tidak ada | NOT FOUND di TunerPro |
| DTC | 37 kode Honda | ALDL DTC via definisi | DIFFERENT COMMAND |
| Dyno | Simple Dyno | tidak ada | NOT FOUND di TunerPro |
| Smartkey | I2C, copy SCU, multi-merek | tidak ada | NOT FOUND di TunerPro |
| Hardware | FTDI FT232 + adaptor K-Line | Moates + serial | DIFFERENT IMPLEMENTATION |

## 3. Perbedaan paling menentukan

1. **Pengetahuan vs definisi.** FLASHPRO membawa offset/tabel/checksum di kode; TunerPro menyerahkan semuanya ke ADX/XDF. FLASHPRO langsung jalan untuk Honda yang didukung, tetapi menambah ECU = update aplikasi. TunerPro fleksibel untuk apa pun yang punya definisi, tetapi tidak tahu Honda tanpa ADX benar.
2. **Flash vs non-flash.** Hanya FLASHPRO punya jalur tulis ECU. TunerPro unggul di pemrograman chip/emulator, bukan flash via K-Line.
3. **Live data.** FLASHPRO memakai tabel polling tetap; TunerPro punya mesin transaksi generik dengan kontrol timeout/echo lebih eksplisit.
4. **Bukti protokol.** Keduanya **tidak** memberikan frame Honda yang dapat diaudit: FLASHPRO di IL terenkripsi, TunerPro di ADX terenkripsi.

## 4. Yang tidak boleh disimpulkan

- "FLASHPRO lebih lengkap" hanya benar untuk fitur Honda-specific yang terlihat; TunerPro punya emulator, XDF, dan plugin yang FLASHPRO tidak punya.
- Tidak ada bukti frame FLASHPRO = ADX Honda mana pun.
- Tidak ada pengujian hardware di kedua sisi.

## 5. Nilai bagi RevCore

- Dari FLASHPRO: model offset VomConfig, alur identifikasi, dan daftar perangkat keras realistis.
- Dari TunerPro: pemisahan definisi dari engine dan model timeout/echo. RevCore saat ini menaruh pengetahuan Honda di kode — lebih aman, kurang fleksibel.
- Dari keduanya: jangan mengklaim kompatibilitas protokol tanpa capture.

## 6. Kesimpulan

FLASHPRO dan TunerPro bukan pesaing langsung. Yang satu adalah **aplikasi vertikal Honda dengan jalur flash**, yang lain adalah **platform definisi generik dengan perangkat chip**. Perbandingan yang adil hanya pada area yang sama: edit BIN, live data, dan transport — dan di area itu detail implementasinya berbeda tanpa bukti keunggulan menyeluruh.
