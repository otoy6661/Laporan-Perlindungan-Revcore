# LAPORAN PEKERJAAN 1 — KEYLESS ID READER (INVESTIGASI)

Tanggal: 2026-11-20
Pemilik proyek: otoy / Otoy Sullivan
Work order: `WORK ORDER — REVCORE NEXT DEVELOPMENT`
Sumber log: `https://github.com/otoy6661/Laporan-Revcore/tree/main/Log`, khususnya `Log/RevCore_Log_2026-11-20_2.txt`

## Status

**PARTIAL**

Investigasi selesai dan kesimpulan bukti dapat dipertanggungjawabkan, tetapi
tujuan akhir “ID berhasil dibaca” **belum tercapai dan tidak dapat diklaim**:
tidak ada transaksi Security Access Keyless di dalam log, dan belum ada
pembacaan ID yang berhasil pada kendaraan fisik.

| Tahap | Status | Bukti |
|---|---|---|
| ECU teridentifikasi | **YA** | Database match `VARIO 150 SMARTKEY (2018-2019)`, `30400-K59J-A71`; log menandai entri database belum diverifikasi hardware. |
| Protokol Keyless teranalisis | **YA (sumber referensi)** | `KeylessFrameCodec` + `KeylessReadEngine`; seluruh nilai berasal dari referensi 3D Chart, bukan pengukuran RevCore. |
| Security Access diterima | **TIDAK ADA BUKTI** | Tidak ada frame security/Keyless di log. |
| ID berhasil dibaca | **TIDAK ADA BUKTI** | Tidak ada ID, tidak ada balasan baca alamat. |
| Transaksi Keyless terjadi pada jendela log | **TIDAK** | Hanya polling live data dan query identitas `0x71`. |
| Transaksi Keyless direkam oleh versi yang menghasilkan log | **TIDAK** | Celah logging ditemukan dan sudah diperbaiki pada pekerjaan ini. |

## 1. Inventaris seluruh file log

Isi folder `Log/` pada repository laporan:

| File | Ukuran | Keterangan |
|---|---:|---|
| `RevCore_Log_2026-11-20_2.txt` | 135.252 byte | Satu-satunya file log yang tersedia pada saat pemeriksaan. |

Tidak ada file log lain untuk dipilah. Log ini adalah ekspor ring buffer, bukan
rekaman penuh sesi.

## 2. Identitas sesi dan batas jendela bukti

Header log (baris 1–10):

- Target: `VARIO 150 SMARTKEY (2018-2019)` / `30400-K59J-A71`
- Waktu ekspor: `2026-11-20 08:43:49.140`
- Statistik kumulatif: `Total Events=7906 | TX=2012 B | RX=9417 B | Errors=3`
- Status tertinggi: `LIVE_DATA_VALID`
- Port: FTDI FT232R, `10400 8N1`, DTR=1, RTS=1, latency 2 ms
- `TX frames=402`, `RX frames valid=399`, `RX frames invalid=1`
- `Timeouts=0`, `USB errors=0`, `Parse failures=0`

Baris event pertama: `08:43:41.582`; baris terakhir: `08:43:49.123`. Jendela
bukti hanya **±7,54 detik**, yaitu 1000 event terakhir dari 7906 event
kumulatif. Konsekuensinya, ketiadaan suatu transaksi di dalam file ini hanya
berlaku untuk jendela tersebut, kecuali diperkuat oleh statistik kumulatif.

## 3. Metode identifikasi transaksi

Transaksi dikenali dari pasangan request/response K-Line:

- Request RevCore: `72 <len> <fn> <sub> <chk>`
- Balasan ECU: `02 <len> <svc> <data...> <chk>`
- Negative response: service `0x7F`
- Keyless mentah memakai frame yang berbeda: `FE 04 72 8C`, `72 05 00 F0 99`,
  pasangan `27 0B E0 ...`, `82 82 ...` (Keihin), atau `91 91 ...` (Shindengen).

Pencarian dilakukan untuk seluruh varian di atas, termasuk kata kunci
`KEYLESS`, `SECURITY`, `IMMO`, `SECURITY_REJECTED`, serta service `0x27`.

## 4. Hasil inventaris transaksi

### 4.1 Frame TX yang benar-benar dikirim

| Frame | Jumlah | Fungsi menurut log |
|---|---:|---|
| `72 05 71 17 01` | 34 | Live data tabel `0x17` |
| `72 05 71 20 F8` | 16 | Live data tambahan tabel `0x20` |
| `72 05 71 D1 47` | 1 | Live data tambahan tabel `0xD1` |

Total 51 frame TX di jendela log. Statistik kumulatif menyebut 402 frame TX;
sisanya sudah keluar dari ring buffer.

### 4.2 Balasan yang di-parse

87 balasan `PARSED_RESPONSE`, **seluruhnya service `0x71`**. Contoh:

- `02 08 71 20 BF 80 00 26` — balasan query identitas/live `0x20`
- `02 0B 71 D1 00 00 00 00 00 00 B1` — balasan tabel `0xD1`

Query `72 05 71 20 F8` adalah **query identitas/live data**, bukan Security
Access. Tidak ada service `0x27`, tidak ada frame inisialisasi Keyless, dan
tidak ada frame baca `82 82`/`91 91` di log.

### 4.3 Kata kunci

Pencarian `keyless|security|immob|0x27|82 82|91 91|FE 04 72 8C` tidak menemukan
transaksi. Satu-satunya kecocokan angka `27` berasal dari teks
`total buffer 27 byte`, bukan service `0x27`.

**Kesimpulan jendela log:** pada ±7,54 detik yang terekam, tidak ada transaksi
Keyless sama sekali. Yang terjadi hanya polling live data dan query identitas.

## 5. Apakah transaksi tidak terjadi, atau tidak direkam?

Ini dua kemungkinan yang harus dipisahkan. Bukti menunjukkan **keduanya tidak
dapat dibedakan dari log lama**, dan celah logging terbukti ada.

Alur logging Keyless sebelum pekerjaan ini:

1. `KeylessReadEngine.exchange()` memanggil logger untuk setiap TX/RX
   (`core/keyless/KeylessReadEngine.kt`, fungsi `exchange`).
2. Logger tersebut diarahkan ke `HondaProtocolEngine.log()`
   (`core/protocol/HondaProtocolEngine.kt:62-67`).
3. `log()` hanya menulis ke `_commLogs`, yaitu buffer layar 500 entri yang
   **tidak diekspor** (`HondaProtocolEngine.kt:185-190`).
4. `runKeylessRead()` hanya mengirim tiga event ke `CommunicationSniffer`:
   `KEYLESS_READ_START`, lalu `KEYLESS_READ_OK` atau `KEYLESS_READ_FAILED`
   (`HondaProtocolEngine.kt:1875-1895`).

Akibatnya, pada versi yang menghasilkan log ini:

- TX/RX mentah Keyless tidak pernah masuk ke log yang diekspor.
- Hanya awal dan akhir percobaan yang akan terlihat.
- Jika file log berasal dari versi tersebut dan tidak memuat
  `KEYLESS_READ_START`, maka **tidak ada bukti percobaan Keyless pada sesi
  itu**; tetapi file ini juga tidak dapat membuktikan bahwa percobaan tidak
  pernah dilakukan di luar jendela 1000 event.

Kesimpulan yang jujur:

- **Tidak terjadi di jendela log:** terbukti.
- **Tidak direkam oleh sistem logging versi lama:** terbukti dari kode.
- **Tidak pernah terjadi sepanjang sesi:** **tidak dapat dibuktikan** dari file
  ini.

## 6. Perbaikan logging yang dilakukan

Agar pertanyaan ini dapat dijawab pada pengujian berikutnya, logger Keyless kini
juga menulis ke `CommunicationSniffer`:

- TX → `CommEventCategory.TX`, stage `RAW_USB_OUT`, status `KEYLESS_TX`
- RX → `CommEventCategory.RX`, stage `RAW_USB_IN`, status `KEYLESS_RX`
- Kesalahan → `CommEventCategory.ERROR`, status `KEYLESS_ERROR`
- Status lain → `CommEventCategory.SYSTEM`, status `KEYLESS_STATE`

Implementasi: `HondaProtocolEngine.kt:63-67` dan fungsi
`logKeylessToSniffer()` pada `HondaProtocolEngine.kt:197-243`.

Konsekuensi: log berikutnya akan memuat setiap frame Keyless beserta panjang dan
hex-nya, sehingga keberhasilan Security Access dan pembacaan ID dapat dinilai
langsung dari log. Tidak ada perubahan protokol, urutan frame, timeout, atau
algoritma.

## 7. Perbandingan dengan implementasi Keyless saat ini

Model yang relevan: `vario150-k59j`, `VARIO 150`, `30400-K59J-A71`.

| Aspek | Nilai saat ini | Bukti sumber |
|---|---|---|
| Family frame | `SHINDENGEN` (`0x91 0x91`) | `KeylessModels.kt` |
| Offset pertama / kedua | `0x90` / `0xA0` → alamat `0x48` / `0x50` | `KeylessModels.kt` |
| Status dukungan | `PROTOCOL_ANALYZED`; UI juga menampilkan `FIELD_TEST_PENDING` | `KeylessModels.kt`, `KeylessScreen.kt:401-410` |
| Wake | BREAK LOW 70 ms, HIGH 130 ms, purge | `KeylessReadEngine.kt` |
| Init | `FE 04 72 8C`, jeda 150 ms, lalu `72 05 00 F0 99`, jeda 150 ms | `KeylessFrameCodec.kt` |
| Security | Request/key Shindengen `0x91 0x91 0D DF ...`; ambang balasan **15 byte** | `KeylessFrameCodec.kt`, `KeylessReadEngine.securityThreshold()` |
| Arti `SECURITY_REJECTED` | Balasan key ada tetapi **kurang dari 15 byte** (Shindengen) | `KeylessReadEngine.runHandshake()` |
| Baca ID | Frame `91 91 07 40 <addr> 00 <chk>`; data di indeks 11/12 | `KeylessFrameCodec.kt` |
| Decode | Gaya PCX untuk Shindengen: `(s1<<24)|(s0<<16)|(f1<<8)|f0`, 9 digit | `KeylessIdDecoder.kt` |
| Penulisan ke ECU | Tidak ada; hanya baca | `KeylessReadEngine` (read-only) |

Ambang 15 byte adalah **kriteria implementasi berdasarkan referensi**, bukan
bukti bahwa ECU Vario 150 SmartKey menerima security access. Tidak ada bukti
penerimaan pada log.

## 8. Pemisahan status kendaraan / ECM / family / dukungan

| Kendaraan | Tahun/variant | ECM | Family frame | ECU teridentifikasi | Protokol dianalisis | Security diterima | ID dibaca | Status dukungan |
|---|---|---|---|---|---|---|---|---|
| Vario 150 SmartKey | 2018–2019 | `30400-K59J-A71` | Shindengen | Ya (database, belum diverifikasi hardware) | Ya (referensi) | Tidak ada bukti | Tidak ada bukti | `PROTOCOL_ANALYZED` / `FIELD_TEST_PENDING` |

Daftar model lain di `KeylessModels.kt` **tidak boleh** dibaca sebagai daftar
kendaraan yang didukung. Semua entri berstatus analisis protokol; tidak ada
entri `FIELD_VERIFIED` di sumber.

## 9. Kekurangan bukti dan langkah berikutnya

1. Jalankan pembacaan Keyless pada Vario 150 SmartKey dengan build yang sudah
   memiliki logging baru, lalu ekspor log.
2. Periksa urutan `KEYLESS_TX`/`KEYLESS_RX`: apakah `FE 04 72 8C` dijawab,
   apakah balasan security ≥15 byte, dan apakah alamat `0x48`/`0x50` dijawab.
3. Jangan menyimpulkan ID valid hanya karena ECU teridentifikasi atau karena
   layar menampilkan 9 digit. ID harus berasal dari dua balasan baca yang
   panjangnya memenuhi ambang dan konsisten.
4. Jika security ditolak, dokumentasikan panjang balasan dan hex-nya; jangan
   mengubah algoritma berdasarkan dugaan.
5. Jika ECU tidak menjawab sama sekali, periksa kontak ON, koneksi K-Line, dan
   grounding sebelum menyimpulkan model salah.

## 10. Perubahan source

- `app/src/main/java/com/revcore/android/core/protocol/HondaProtocolEngine.kt`
  — logger Keyless juga menulis TX/RX/ERROR/STATE ke sniffer.
- Tidak ada perubahan pada `KeylessFrameCodec`, `KeylessReadEngine`,
  `KeylessIdDecoder`, atau `KeylessModels`.

## 11. Pengujian

- `:app:testDebugUnitTest`: **335 test, 0 gagal** (termasuk 5 test baru untuk
  klasifikasi/retensi error).
- `:app:assembleDebug`: berhasil.
- `:app:compileReleaseKotlin`: berhasil.
- Pembacaan Keyless pada kendaraan: **belum diuji**; tidak ada klaim hardware.

## 12. Risiko tersisa

- Frame security Keyless kini ikut terekspor ke log. Nilainya adalah nilai
  referensi tetap dan fitur tetap baca-saja; tetap perlu kehati-hatian saat
  membagikan log ke publik.
- Keberhasilan pembacaan ID tetap tidak diketahui sampai ada laporan perangkat.
- Batas 1000 event membuat percobaan lama dapat hilang; retensi error tidak
  menyimpan frame Keyless yang bukan error.
