# LAPORAN PEKERJAAN 3 — FITUR LOG (ERROR FILTER, OPEN LOCATION, SHARE)

Tanggal: 2026-11-20
Pemilik proyek: otoy / Otoy Sullivan

## Status

**PARTIAL**

Ketiga cacat diperbaiki di source dan diverifikasi dengan unit test/build.
Verifikasi pada perangkat (khususnya Sharesheet MIUI dan file manager) masih
menunggu pengujian pemilik; tidak ada klaim hardware.

| Sub-pekerjaan | Status | Verifikasi |
|---|---|---|
| A. Filter Error | **PASS (kode + unit test)** | 335 test lulus; predikat filter kini identik dengan penghitung error |
| B. Open Location | **PARTIAL** | Try/catch, cek izin/folder, cek activity; belum diuji di MIUI |
| C. Share file | **PARTIAL** | File `.txt` + URI + grant + chooser; belum diuji antar-aplikasi di perangkat |

## A. Filter Error tidak menampilkan apa pun

### Penyebab

Ada dua penyebab yang saling memperkuat:

1. **Predikat berbeda.** Penghitung “Errors” memakai `isErr` yang mencakup
   status seperti `FAILED`, `PARSE_FAILED`, `TIMEOUT`, `REJECT`, dan
   `errorDetails`, walaupun kategorinya `RX` atau `SYSTEM`. Filter lama hanya
   memeriksa `category == ERROR` atau `direction == ERR`, sehingga event error
   berkategori RX/SYSTEM tidak pernah lolos filter.
2. **Ring buffer 1000 event.** Log yang diperiksa menunjukkan
   `Errors=3` di header, tetapi **tidak ada satu pun baris error** di 1000 event
   terakhir (jendela hanya ±7,54 detik). Event error sudah terlempar dari buffer
   sebelum log diekspor. Filter yang benar sekalipun akan kosong.

Bukti log:

```text
Statistics  : Total Events=7906 | TX=2012 B | RX=9417 B | Errors=3
```

Pencarian `FAIL|ERROR|TIMEOUT|REJECT` pada 1000 baris event tidak menemukan
hasil.

### Perbaikan

1. Predikat tunggal `SnifferLogEvent.isError`
   (`core/protocol/SnifferLogEvent.kt:37-52`) dipakai oleh penghitung statistik
   dan filter. Predikat mencakup kategori ERROR, `errorDetails`, dan status
   gagal/ditolak/timeout/negatif/denied/lost.
2. Riwayat error terpisah, maksimal 500 entri, disimpan di
   `CommunicationSniffer` (`CommunicationSniffer.kt:12, 127-142`). Error tidak
   ikut terhapus saat trafik biasa berputar.
3. Filter ERROR menggabungkan event aktif + riwayat error, deduplikasi berdasarkan
   `id`, lalu menyortir (`ui/screens/LogScreen.kt:93-104`).
4. Jika tetap kosong, pesan menjelaskan jumlah error kumulatif dan batas riwayat
   (`LogScreen.kt:369-388`).
5. Key Compose daftar diubah dari kombinasi timestamp+pesan+direction menjadi
   `id` unik (`LogScreen.kt:361`), menghilangkan risiko crash duplicate key.
6. Ekspor teks tidak lagi memotong hex >32 karakter; hex lengkap ditulis
   (`CommunicationSniffer.kt:298-303`). Riwayat error yang sudah keluar buffer
   ditambahkan sebagai bagian `ERROR HISTORY` (`CommunicationSniffer.kt:305-316`).

### Bukti pengujian

Test baru `core/protocol/SnifferEventClassificationTest.kt`:

- status gagal berkategori RX tetap dianggap error;
- `errorDetails` menandai error;
- trafik normal tidak dianggap error;
- jumlah error statistik = jumlah riwayat error;
- error bertahan setelah 1001 event trafik dan diekspor tanpa pemotongan hex.

## B. Open Location crash setelah “Simpan File”

### Penyebab

`LogScreen` memanggil `context.startActivity(intent)` tanpa pemeriksaan.
Intent memakai URI `content://com.android.externalstorage.documents/...` dengan
MIME direktori. Pada perangkat yang tidak memiliki activity yang dapat menangani
URI tersebut (atau yang menolak grant), panggilan dapat melempar
`ActivityNotFoundException`, `SecurityException`, atau `IllegalArgumentException`.
Tidak ada folder/izin yang diperiksa lebih dulu.

### Perbaikan

Fungsi `openLogsFolder()` (`LogScreen.kt:395-451`):

1. `RevCoreStorage.ensure(context)` memastikan izin dan folder ada.
2. Jika izin belum ada, buka layar izin yang tepat; jika gagal, tampilkan alasan.
3. `resolveActivity()` diperiksa sebelum `startActivity`.
4. `startActivity` dibungkus `try/catch` untuk `ActivityNotFoundException`,
   `SecurityException`, dan exception lain; pengguna mendapat pesan, bukan crash.

### Keterbatasan

Perilaku file manager MIUI/Android 12 belum diuji pada perangkat. Kode tidak
lagi dapat crash karena exception activity, tetapi apakah file manager menerima
URI direktori tetap perlu dibuktikan di perangkat.

## C. Share hanya menyalin teks

### Penyebab

Tombol Share membuat `ACTION_SEND` dengan `EXTRA_TEXT` saja. Tidak ada file,
tidak ada URI, dan teks berasal dari ekspor yang memotong hex >32 karakter.
Aplikasi penerima karena itu hanya menerima teks, bukan lampiran.

### Perbaikan

1. `MainViewModel.createLogShareFile()` (`MainViewModel.kt:2896-2919`) menulis
   log lengkap ke `cacheDir/share/<nama>.txt` dengan UTF-8.
2. File diekspos lewat `FileProvider`:

   - provider di `AndroidManifest.xml` (authority
     `com.revcore.android.fileprovider`, `exported=false`,
     `grantUriPermissions=true`);
   - path `cache/share/` di `res/xml/file_paths.xml`.

3. Share memakai `ACTION_SEND` + `EXTRA_STREAM` + `type="text/plain"` +
   `ClipData` + `FLAG_GRANT_READ_URI_PERMISSION`
   (`LogScreen.kt:453-489`).
4. Chooser juga diberi flag grant; kegagalan pembuatan file, tidak adanya
   aplikasi, dan exception lain ditangani dengan pesan.
5. Isi file adalah hasil `exportAsText()` yang kini memuat hex lengkap dan
   riwayat error.

### Batas isi log

Ekspor tidak lagi memotong field. Namun sumber datanya tetap ring buffer 1000
event; event yang sudah keluar dari buffer tidak dapat dihidupkan kembali oleh
fitur Share. Error tetap dipertahankan (hingga 500) dan disertakan. Untuk
“seluruh sesi” secara penuh diperlukan perekam persisten terpisah; itu di luar
perubahan ini dan tidak diklaim sudah ada.

### Keterbatasan pengujian

- Sharesheet, penerima Gmail/WhatsApp/Files, dan URI grant belum diuji di
  perangkat.
- Nama file memakai timestamp; file lama di cache dapat tertimpa bila share
  dilakukan pada detik yang sama.

## File source yang diubah

- `core/protocol/SnifferLogEvent.kt`
- `core/protocol/CommunicationSniffer.kt`
- `ui/MainViewModel.kt`
- `ui/screens/LogScreen.kt`
- `AndroidManifest.xml`
- `res/xml/file_paths.xml` (baru)
- `core/protocol/HondaProtocolEngine.kt` (logging Keyless, terkait Pekerjaan 1)
- `core/usb/UsbSerialLibraryTransport.kt` (Pekerjaan 4)
- `MainActivity.kt` (Pekerjaan 5)

## Pengujian dan regresi

- Unit test: **335 test, 0 gagal**.
- `:app:assembleDebug`: berhasil; APK debug 57.213.202 byte.
- Provider terverifikasi di APK hasil build melalui `aapt2 dump xmltree`.
- `:app:compileReleaseKotlin`: berhasil.
- Tidak ada pengujian UI instrumentasi/perangkat.
