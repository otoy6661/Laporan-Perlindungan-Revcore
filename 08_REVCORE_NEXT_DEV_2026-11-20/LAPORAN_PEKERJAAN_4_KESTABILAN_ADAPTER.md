# LAPORAN PEKERJAAN 4 — KESTABILAN ADAPTER USB/SERIAL

Tanggal: 2026-11-20
Pemilik proyek: otoy / Otoy Sullivan

## Status

**PARTIAL**

Audit siklus hidup selesai dan dua perbaikan kecil diterapkan. Perilaku
perangkat fisik (detach saat transaksi, OTG, MIUI, FTDI latency) **belum diuji**
dan tidak diklaim selesai. Work order secara eksplisit melarang menyatakan
masalah selesai hanya berdasarkan unit test.

## 1. Rantai yang diaudit

| Lapisan | File / fungsi | Temuan |
|---|---|---|
| Deteksi USB | `MainActivity` receiver `ATTACHED/DETACHED/PERMISSION` | Terdaftar dengan `RECEIVER_NOT_EXPORTED` pada API 33+; detach memanggil jalur teardown. |
| Izin USB | `MainViewModel` + `UsbSerialLibraryTransport.open()` | Izin diperiksa sebelum open; penolakan dicatat `USB_PERMISSION_MISSING` dan tidak membuka port. |
| Open adapter | `openAndIdentify()` | Dibatasi `ADAPTER_OPEN_TIMEOUT_MS = 10_000`; timeout memanggil `disconnect()` agar port tidak tertinggal. |
| Race open vs detach | generation + `isActive` | Job yang selesai setelah detach tidak membiarkan port terbuka: `if (!isActive) { disconnect(); return }`. |
| Transaksi | `commLock` + `EcuSessionManager.gate` | Keyless, identifikasi, live data, DTC berbagi kunci; tidak ada dua transaksi bersamaan. |
| Baca | `UsbSerialLibraryTransport.read()` | Exception ditangkap, dicatat `FAILED` + `recordUsbError()`, lalu mengembalikan array kosong. Pemanggil melihat timeout, bukan kegagalan port. |
| Tulis | `UsbSerialLibraryTransport.write()` | Exception mengembalikan `-1`; `KlineWireEngine` menganggapnya gagal dan menaikkan jalur link failure. |
| Tutup | `disconnect()` → `driver.close()` | Dipanggil dari 6 titik; `driver = null` setelah close. |
| Recovery | `scheduleRecoveryBackoff()` | 2/4/8/16/30 detik, maksimal 8 kegagalan; tidak ada loop tanpa batas. |
| Monitor kontak | `startIgnitionMonitor()` + `CommActivityPolicy` | Polling berhenti saat aplikasi tidak terlihat; status link diperbarui. |

## 2. Perbaikan yang diterapkan

1. `isOpen` pada `UsbSerialLibraryTransport` diberi `@Volatile`
   (`UsbSerialLibraryTransport.kt:33`). Status port dibaca dari thread I/O dan
   UI; tanpa volatile, status bisa tampak terbuka sesaat setelah ditutup.
2. `close()` dibuat `@Synchronized` dan idempoten
   (`UsbSerialLibraryTransport.kt:481-499`). Penutupan kedua tidak memanggil
   `serialPort.close()` lagi dan tidak menulis event “port closed” palsu.
   Ini mengurangi risiko double-close saat teardown dan exception path
   berjalan berdekatan.

Tidak ada perubahan pada timeout, baud rate, DTR/RTS, purge, atau urutan
inisialisasi K-Line.

## 3. Perilaku yang sengaja tidak diubah

- `read()` tetap mengembalikan array kosong pada exception. Mengubahnya menjadi
  exception akan mengubah kontrak seluruh pemanggil dan berisiko memutus sesi
  pada gangguan singkat. Exception sudah tercatat sebagai ERROR dan dihitung
  sebagai USB error.
- `_isConnected` pada `HondaProtocolEngine` berarti **port adapter terbuka**,
  bukan “ECU menjawab”. Status ECU dipisahkan melalui `isEcuAlive`,
  `isEcuIdentified`, dan `LIVE_DATA_VALID`. Ini sudah tercermin di UI.
- `CommLifecycle.SUSPECTED_LOSS` tetap dipakai sebagai penanda kegagalan
  berulang; `markAlive()` mengembalikannya ke status operasional saat balasan
  valid datang. Tidak dihapus karena masih menjadi bagian model sesi.

## 4. Kondisi yang belum dapat diuji

Semua item berikut memerlukan perangkat dan tidak ada klaim hasil:

- USB detach fisik tepat saat `read()`/`write()` berjalan.
- Perilaku OTG dan suplai daya pada Poco X3 NFC.
- Dialog izin USB pada MIUI 14 dan timing receiver.
- Kualitas kabel/transceiver K-Line dan error parity/framing.
- FTDI latency 2 ms dan purge pada driver Android.
- Reconnect setelah kabel goyang berulang.
- Perilaku saat aplikasi di-background tepat di tengah transaksi.

## 5. Pengujian

- `:app:testDebugUnitTest`: 335 test, 0 gagal.
- `:app:assembleDebug`: berhasil.
- `:app:compileReleaseKotlin`: berhasil.
- Tidak ada unit test baru untuk lifecycle USB karena `UsbDevice`,
  `UsbDeviceConnection`, dan `UsbSerialPort` adalah kelas Android yang tidak
  tersedia di JVM test tanpa mocking framework tambahan.
- Tidak ada pengujian perangkat.

## 6. Risiko tersisa

- `read()` yang menelan exception dapat membuat sesi tampak “timeout” padahal
  port sudah mati; detach receiver biasanya menutup jalur ini, tetapi belum
  diuji pada MIUI.
- Penutupan port dari thread lain saat transaksi berjalan masih mungkin terjadi;
  `cancel`-sebelum-`close` dan `commLock` mengurangi, bukan menghilangkan,
  jendela race.
- Belum ada mekanisme yang membedakan kabel buruk dari ECU diam; log baru
  membantu, tetapi diagnosis tetap memerlukan pengukuran fisik.
