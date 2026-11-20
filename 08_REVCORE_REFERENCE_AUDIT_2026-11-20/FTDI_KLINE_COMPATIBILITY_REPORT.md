# FTDI K-LINE COMPATIBILITY REPORT

Work order §4. Pertanyaan: kemampuan referensi mana yang realistis direalisasikan
lewat jalur

```
RevCore Android ──USB OTG──► FTDI ──UART/BREAK──► Interface K-Line ──► ECU Honda
```

Kelas bukti §7. **Tidak ada kelas D** — belum ada pengujian pada ECU.

---

## 1. Pemisahan lapisan (wajib)

Work order meminta empat lapisan dipisahkan tegas. Istilah yang dipakai:

| Lapisan | Isi | Contoh |
|---|---|---|
| **L1. PC ↔ adaptor** | USB, driver, lisensi, bit-bang vs UART, vendor ID | libFTDI H-Diag, usb-serial-for-android RevCore, FTDI Chip-ID |
| **L2. Adaptor ↔ ECU** | level tegangan, K-Line pull-up, BREAK, baud, framing waktu | 10400 8N1, BREAK 70/130 ms, echo |
| **L3. Protokol ECU** | header, panjang, service, subfungsi, checksum, alur security | `72 05 71 17 01`, `82 82 10 06 addr chk` |
| **L4. Parser aplikasi** | offset, skala, satuan, status, UI | tabel live RevCore, dictionary DTC |

Kesalahan umum: menyalin protokol L1 (mis. lisensi Chip-ID atau mode bit-bang
libFTDI) ke implementasi FTDI Android, lalu mengira itu protokol ECU. **Tidak
dilakukan di sini.** Yang dipindahkan hanya L3 dan L4 yang memang protokol ECU.

---

## 2. L1 — Host ke adaptor

### 2.1 RevCore (A. FACT)

`UsbSerialLibraryTransport.kt`:

- library `usb-serial-for-android`, driver `FtdiSerialDriver`;
- VID FTDI `0x0403`; PID FT232R/FT2232/FT4232H/FT232H dikenali;
- buka port, `setParameters(10400, 8, 1, 0)` → 8N1;
- `DTR=1`, `RTS=1`;
- FTDI latency timer 2 ms, flow control none;
- `setBreak(enable)` diteruskan ke driver;
- read/write timeout, buffer, dan log tahap `FTDI_INIT_COMPLETED`.

### 2.2 H-Diag (A. FACT)

- memakai `libFTDI` + `libusb`;
- `UsbSerial::findFtdi`, `ftdiSetDesc`, `Connect`;
- lisensi membaca FTDI Chip-ID dan memakai `SimpleCrypt`/`login.ini`.

**B. INFERENCE:** H-Diag mengikat aplikasi pada adaptor FTDI tertentu. Mekanisme ini
adalah proteksi L1, bukan protokol ECU. Tidak ada alasan teknis untuk menirunya,
dan work order melarang menyalin protokol proprietary PC–adaptor.

### 2.3 Perbedaan yang relevan

| Hal | H-Diag (PC) | RevCore (Android) | Dampak |
|---|---|---|---|
| Driver | libFTDI | usb-serial-for-android | Setara untuk UART |
| Izin USB | OS desktop | izin runtime Android + OTG | Perlu penanganan UI |
| Lisensi | Chip-ID | tidak ada | Tidak perlu ditiru |
| Kontrol BREAK | libFTDI | `setBreak` driver | Perlu uji per chip |

---

## 3. L2 — Adaptor ke ECU

### 3.1 Yang dibutuhkan ECU Honda

- K-Line satu kabel, idle tinggi, di-drive low oleh tester.
- 10400 baud, 8N1.
- Wake/BREAK: RevCore 70 ms low, 130 ms high; firmware FlashPro lebih panjang
  (40/70/130/130/70/130).
- Echo lokal: adaptor sering mengembalikan byte yang baru dikirim.

### 3.2 Antarmuka fisik

- FTDI mengeluarkan level UART (3,3 V atau 5 V), sedangkan K-Line ECU bekerja
  pada level 12 V dengan pull-up. Diperlukan rangkaian interface (transistor/
  optocoupler/level shifter) di antara keduanya. **B. INFERENCE** dari sifat
  kelistrikan; bukan hasil pengukuran.
- Jika adaptor yang dipakai sudah berlabel "K-Line", bagian ini sudah diselesaikan
  oleh vendor. RevCore hanya melihat port serial.
- **C. UNVERIFIED:** apakah FTDI tertentu (mis. FT232R) menghasilkan BREAK yang
  cukup panjang dan bersih di Android. Driver memanggil `setBreak`, tetapi durasi
  dan perilaku chip belum diukur.

### 3.3 Echo dan validasi

| Aspek | RevCore | Firmware FlashPro | H-Diag |
|---|---|---|---|
| Buang echo awal | `stripLeadingEcho` | buang sepanjang TX + pencarian frame TX | tidak terbaca |
| Tolak echo sendiri | jendela 1500 ms, byte-identik | ya | tidak terbaca |
| Validasi checksum RX | ya (`HondaFrameCodec.isWellFormed`) | tidak | tidak terbaca |
| Retry | 1 | loop handshake 60 s | baca ulang 1× |

RevCore lebih ketat daripada firmware. Untuk K-Line yang berisik, ini bisa berarti
frame valid ditolak; untuk kejujuran data, ini lebih baik daripada menerima echo.

---

## 4. L3 — Protokol ECU

### 4.1 Frame yang sudah diketahui

| Keluarga | Baca | Checksum | Sumber |
|---|---|---|---|
| Honda `0x72` | `72 len svc sub ... chk` | two's complement semua byte sebelum chk | H-Diag, RevCore, FlashPro |
| Keyless Keihin | `82 82 10 06 addr chk` | two's complement 5 byte body | FlashPro, RevCore |
| Keyless Shindengen | `91 91 07 40 addr 00 chk` | `0x100-(07+40+addr)` | FlashPro, RevCore |

Header `0x7E`/`0x7C` pada RevCore dipakai untuk menebak keluarga ECU; ini
**HYPOTHESIS**, bukan fakta. Tidak ada sumber referensi yang mengonfirmasi arti
header tersebut dalam audit ini.

### 4.2 Kemampuan per protokol

| Kemampuan | Frame tersedia? | Alur terbaca? | Realistis via FTDI? | Kelas |
|---|---|---|---|---|
| Live data `72 05 71 xx` | ya | ya | ya | B |
| Live data H-Diag `72 05 60/71/00` | ya | ya | ya, tetapi parser tidak | B |
| DTC read H-Diag (`72 07 72 D0/D1`, `73 00/01`, `74/01`) | ya | sebagian | ya | B |
| DTC clear (`72 05 60 01`) | ya | sebagian | ya, ACK belum pasti | C |
| Identifikasi `71 00` | ya | ya | ya | B |
| Keyless read | ya | ya | ya, dengan 256 langkah | B |
| Keyless auto-identify | ya | ya | ya, setelah deteksi ECM | B |
| Keyless reset/tulis | ya | sengaja tidak | **tidak diimplementasikan** | — |

---

## 5. L4 — Parser dan konversi

| Sumber | Parser | Rumus | Dapat dipindahkan? |
|---|---|---|---|
| H-Diag | teks per baris | tidak terbaca | Tidak |
| FlashPro firmware | offset + skala di literal pool | terbaca | Ya, sudah dipakai RevCore |
| RevCore | offset + skala + range | eksplisit | Sudah ada |

Karena parser H-Diag tidak menghasilkan tabel offset, "menyalin H-Diag" bukan
opsi. Yang bisa dilakukan adalah memakai frame H-Diag lalu memetakan byte dengan
pengujian sendiri.

---

## 6. Putusan kelayakan per kemampuan

| Kemampuan referensi | Putusan | Alasan |
|---|---|---|
| Live data H-Diag (3 frame) | **REALIZABLE WITH CAVEAT** | Frame jelas; arti byte belum |
| Live data FlashPro (7 tabel) | **REALIZABLE** | Frame + offset + skala lengkap |
| DTC read H-Diag | **REALIZABLE WITH CAVEAT** | Frame jelas; format ACK belum |
| DTC clear H-Diag | **REALIZABLE WITH CAVEAT** | Risiko menulis; butuh uji |
| Identifikasi ECU | **REALIZABLE WITH CAVEAT** | Hanya `71 00`; arti field belum |
| Keyless read | **REALIZABLE WITH CAVEAT** | Butuh BREAK, 256 read, deteksi vendor |
| Keyless auto-identify | **REALIZABLE WITH CAVEAT** | Butuh deteksi ECM yang belum ditiru |
| Keyless reset/tulis | **NOT REALIZABLE (SCOPE)** | Fungsi tulis; di luar etika audit |
| Lisensi Chip-ID H-Diag | **NOT REALIZABLE (IRRELEVANT)** | Proteksi L1, bukan ECU |
| Bit-bang libFTDI PC | **NOT REALIZABLE (IRRELEVANT)** | Bukan protokol ECU |
| Actuator test H-Diag | **NOT PROVEN** | Tidak ada bukti perintah |
| Coding/registration | **NOT PROVEN** | Tidak ditemukan |

"NOT REALIZABLE (SCOPE)" berarti memang tidak boleh/wajar diimplementasikan,
bukan berarti mustahil secara teknis.

---

## 7. Mengapa sebagian tidak bisa dipaksakan

1. **Parser H-Diag** bergantung pada formulir teks internal yang tidak terbaca;
   memaksakan offset akan menghasilkan angka palsu.
2. **Keyless reset** adalah operasi tulis kredensial; work order melarang
   pembobolan/penulisan, jadi tidak dianalisis dan tidak diimplementasikan.
3. **Header 0x7E/0x7C** belum terbukti; membangun routing keluarga di atasnya
   adalah hipotesis. RevCore saat ini justru selalu jatuh ke profil generik
   (lihat dokumen gap analysis).
4. **BREAK FTDI** belum diukur; bila chip tidak mendukung, wake harus memakai
   pola bit-bang, yang tidak tersedia lewat usb-serial-for-android.

---

## 8. Diagram alur yang direkomendasikan (tanpa implementasi)

```
Android
  │ USB host
  ▼
usb-serial-for-android ── FTDI (8N1, 10400, latency 2 ms, DTR/RTS)
  │
  ▼
KlineWireEngine
  ├─ purge + drain
  ├─ register TX
  ├─ write
  ├─ read window
  ├─ strip echo / tolak echo sendiri
  ├─ ekstrak frame + checksum
  └─ status: OK / LOCAL_ECHO_ONLY / TIMEOUT / CHECKSUM_FAILED
  │
  ▼
Parser per tabel (L4) ── UI (hanya VALID yang ditampilkan)
```

Jalur Keyless memakai transport yang sama, tetapi melewati KlineWireEngine dan
memakai `KeylessReadEngine` dengan frame sendiri. Ini disengaja karena frame
Keyless bukan frame `0x72` dan checksum-nya berbeda.

---

## 9. Kesimpulan

- FTDI USB OTG **cukup** untuk seluruh kemampuan baca yang terbukti (live data,
  DTC read, identifikasi, Keyless read) dengan syarat antarmuka K-Line fisik ada.
- Yang belum cukup bukan transportnya, melainkan **pengetahuan**: parser H-Diag,
  arti header keluarga, deteksi vendor Keyless, dan timing 1000 ms.
- Yang tidak boleh dilakukan: menyalin lisensi/bit-bang PC, menulis EEPROM,
  atau mengarang offset.
- Tidak ada klaim bahwa jalur ini sudah diuji pada ECU. Kelas D kosong.
