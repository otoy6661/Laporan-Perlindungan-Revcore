# Investigasi Koneksi Terputus-Putus (Intermittent Disconnect)

Tanggal: 2026-11-20. Investigasi statis (source + unit test). **Tidak ada
perangkat, adapter, atau ECU yang tersambung** selama sesi ini.

Laporan utama: [LAPORAN_TEKNIS_REVCORE_2026-11-20.md](LAPORAN_TEKNIS_REVCORE_2026-11-20.md)

---

## 1. Definisi masalah

"Koneksi putus-putus" pada RevCore dapat berarti dua peristiwa berbeda:

| Peristiwa | Titik putus | Gejala |
|---|---|---|
| **USB detach** | Android ↔ adapter USB | Perangkat hilang dari daftar; transaksi dihentikan |
| **ECU link loss** | adapter ↔ ECU via K-Line | Adapter masih terbuka, tetapi tidak ada balasan valid |

Keduanya dapat terlihat sama di UI (data berhenti/link hilang). Tanpa log
bertimestamp, keduanya tidak dapat dibedakan. **[FAKTA]**

---

## 2. Jenis koneksi

- **USB/OTG serial**, bukan Bluetooth. Vendor yang didukung:
  `0x0403` (FTDI), `0x1A86` (CH34x), `0x10C4` (CP210x), `0x067B` (PL2303)
  (`core/usb/AdapterConnectionPolicy.kt:16`).
- Parameter serial: 10400 baud, 8N1, kontrol DTR/RTS, purge saat buka; FTDI
  latency 2 ms (`core/usb/UsbSerialLibraryTransport.kt`). **[FAKTA]**
- ECU: Honda K-Line, request `72 …`, timeout baca 700 ms per pembacaan
  (`core/comm/KlineWireEngine.kt:21, 182`). **[FAKTA]**

---

## 3. Mekanisme yang bekerja saat putus

### 3.1 Sisi USB

| Mekanisme | Lokasi | Perilaku |
|---|---|---|
| Broadcast ATTACHED | `MainActivity.kt:55-67` | Device diteruskan ke ViewModel atau daftar adapter di-refresh |
| Broadcast DETACHED | `MainActivity.kt:68-80` | `onUsbDeviceDetached(device)` |
| Broadcast izin USB | `MainActivity.kt:81-94` | Granted → lanjut buka; denied → ditandai |
| Registrasi receiver | `MainActivity.kt:102-111` | `RECEIVER_NOT_EXPORTED` (API 33+) |
| Keputusan teardown | `core/usb/AdapterConnectionPolicy.kt:34-41` | Teardown hanya bila adapter terpilih yang lepas (atau tidak tersisa) |
| Teardown | `MainViewModel.kt:1612-1638` | Cancel job → tutup port → reset backoff → set state tunggu/perangkat terdeteksi |
| Timeout buka adapter | `MainViewModel.kt:125, 1250-1261` | 10.000 ms; port dibersihkan bila lewat batas |
| Penanganan error I/O | `core/usb/UsbSerialLibraryTransport.kt` | `read()` mengembalikan array kosong; `write()` mengembalikan `-1` pada exception (tidak melempar ke UI) |

### 3.2 Sisi ECU (K-Line)

| Mekanisme | Lokasi | Perilaku |
|---|---|---|
| Read timeout | `KlineWireEngine.kt:21` | 700 ms; membaca sampai deadline |
| Polling Live Data | `LivePollPolicy.kt` | interval 150–1000 ms; berhenti setelah **4** kegagalan beruntun; backoff internal 300→3000 ms |
| Penanda link hidup | `HondaProtocolEngine.kt:370-377` | `markLinkAlive()` mereset penghitung kegagalan |
| Ambang link-loss | `HondaProtocolEngine.kt:379-397` | Setelah ambang: `isEcuAlive=false`, status `LINK_LOST`, telemetri diinvalidasi (STALE), timeline sniffer dicatat |
| Ambang per operasi | `HondaProtocolEngine.kt` (baris 363, 1084, 1153, 1364) | `sendCommand`=1, DTC=2, ClearDTC=2, polling Live=4 |
| Monitor kontak/recovery | `MainViewModel.kt:621-650` | Loop 2 detik saat foreground; bila `!isEcuAlive` → identifikasi ulang dengan backoff |
| Backoff pemulihan | `MainViewModel.kt:1649-1660` | 2/4/8/16/30 detik; maksimum 8 percobaan |
| Gating aktivitas | `core/comm/CommActivityPolicy.kt` | Polling hanya bila app visible + session ready + adapter open + ECU alive; recovery hanya bila visible |

### 3.3 State siklus komunikasi

`core/comm/EcuSessionManager.kt` memiliki `CommLifecycle` termasuk
`SUSPECTED_LOSS` (baris 19). `markFailure()` menetapkan `SUSPECTED_LOSS`
(baris 131), tetapi **tidak ada pembacaan/pemakaian state itu di jalur lain**.

- Status: `SUSPECTED_LOSS` adalah state mati. **[FAKTA]**
- Dampak: tidak ada jalur yang salah karena state ini, tetapi diagnosis menjadi
  lebih sulit dan state tersebut tidak memberi perilaku tambahan apa pun.
- Belum dapat dipastikan apakah ini sisa desain atau fitur yang belum selesai.
  **[TIDAK DITEMUKAN]** catatan desainnya.

---

## 4. Pola yang teramati

| Aspek | Status |
|---|---|
| Frekuensi kejadian | **TIDAK DIKETAHUI** — tidak ada pengukuran |
| Pola waktu (mis. tiap N menit) | **TIDAK DIKETAHUI** |
| Korelasi kondisi (getaran, panas, RPM, KOEO/KOER) | **TIDAK DIKETAHUI** |
| Korelasi model adapter | **TIDAK DIKETAHUI** |

Tidak ada log TX/RX, log USB, atau catatan waktu kejadian dari perangkat
pemilik. Semua pernyataan tentang pola akan menjadi karangan; karena itu tidak
dibuat.

### 4.1 Log sebelum/sesudah putus yang tersedia

**Tidak ada.** Tidak ada log sebelum atau sesudah kejadian yang dapat dilampirkan.

Kanal untuk mendapatkannya: layar **Log** memakai `CommunicationSniffer`
(ring buffer 1000 entri) dan menyediakan ekspor teks/CSV
(`core/protocol/CommunicationSniffer.kt`, `ui/screens/LogScreen.kt`). Ekspor
tersebut adalah satu-satunya cara memperoleh TX/RX nyata dari perangkat.

---

## 5. Timeout, retry, watchdog, recovery

| Komponen | Ada? | Catatan |
|---|---|---|
| Timeout baca | Ya | 700 ms per read |
| Timeout buka adapter | Ya | 10.000 ms |
| Retry | Terbatas | Ambang per operasi; polling berhenti setelah 4 kegagalan |
| Watchdog | Tidak ada timer terpisah | Deteksi berbasis kegagalan transaksi + loop monitor 2 detik |
| Recovery otomatis | Ya | Identifikasi ulang dengan backoff 2–30 detik, maks. 8 |
| Detach recovery | Ya | Menunggu adapter terpasang kembali; auto-connect dipicu ATTACHED |

Semua di atas adalah **perilaku kode dan unit test**, bukan hasil uji perangkat.
**[BELUM DIUJI]**

### 5.1 Mengapa "berhasil tersambung lagi" bukan bukti selesai

1. Recovery memang dirancang untuk menyambung ulang; keberhasilan satu kali
   hanya menunjukkan jalur recovery berjalan.
2. Penyebab putus (detach fisik, kabel, daya, timeout ECU, ECU reset) belum
   diketahui, sehingga putus dapat berulang.
3. Tanpa durasi uji dan jumlah kejadian, tidak ada dasar statistik untuk
   menyatakan stabil.

Work order §2B secara eksplisit melarang klaim selesai hanya karena satu
reconnect. Laporan ini mematuhi itu.

---

## 6. Kandidat penyebab (hipotesis, bukan kesimpulan)

| # | Kandidat | Dasar | Status |
|---|---|---|---|
| H1 | Kabel/OTG longgar atau getaran | detach USB adalah peristiwa umum di kendaraan | **DUGAAN** |
| H2 | Daya adapter tidak stabil (port OTG ponsel) | adapter serial butuh arus; MIUI dapat membatasi | **DUGAAN** |
| H3 | Respons ECU melewati 700 ms → terlihat putus | timeout 700 ms relatif ketat | **DUGAAN** |
| H4 | Interferensi/grounding K-Line | umum pada K-Line | **DUGAAN** |
| H5 | ECU berpindah state (mis. setelah starter) | belum ada bukti | **DUGAAN** |

Tidak ada hipotesis yang boleh diangkat menjadi penyebab tanpa log.

---

## 7. Uji stabilitas

**BELUM DILAKUKAN.** Tidak ada perangkat pada sesi ini.

Rencana uji yang disarankan (untuk pemilik):

1. Pasang APK uji resmi; buka dashboard; aktifkan ekspor log.
2. Sesi 1: KOEO 30 menit tanpa menyentuh kabel.
3. Sesi 2: KOER 30 menit (jika aman).
4. Sesi 3: 10 kali detach/attach terkontrol; catat waktu dan perilaku UI.
5. Ekspor log untuk setiap kejadian putus; sertakan timestamp.
6. Bandingkan `USB_DETACHED` di sniffer vs `LINK_LOST` vs `TIMEOUT`.

---

## 8. Kesimpulan

1. Rantai koneksi adalah USB/OTG → adapter serial → K-Line → ECU; putus dapat
   terjadi di USB atau di link ECU.
2. RevCore memiliki timeout, deteksi link-loss, teardown, dan recovery
   terbatas — semuanya terverifikasi di level kode/unit test.
3. Penyebab, frekuensi, dan pola disconnect **tidak diketahui**; tidak ada log
   nyata.
4. `SUSPECTED_LOSS` tidak pernah dikonsumsi — temuan kebersihan state, bukan
   bukti penyebab.
5. Masalah **tetap terbuka** sampai ada log perangkat dan uji stabilitas.
