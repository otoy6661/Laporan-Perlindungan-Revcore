# RINGKASAN WORK ORDER — REVCORE NEXT DEVELOPMENT

Tanggal: 2026-11-20
Pemilik: otoy / Otoy Sullivan
Pelaksana: Kodir melalui Qoder
Work order: `WORK ORDER — REVCORE NEXT DEVELOPMENT`

## Status keseluruhan

| Pekerjaan | Status | Ringkas |
|---|---|---|
| 1. Keyless ID Reader | **PARTIAL** | Investigasi selesai; tidak ada transaksi Keyless di log; celah logging diperbaiki; ID belum pernah terbaca. |
| 2. Live Monitor | **PARTIAL** | Audit 19 parameter selesai; tidak ada parser baru tanpa bukti; dukungan ECU per parameter belum diuji. |
| 3. Fitur Log | **PARTIAL** | Filter error, Open Location, dan Share file diperbaiki; perangkat belum diuji. |
| 4. Kestabilan Adapter | **PARTIAL** | Audit lifecycle selesai; `isOpen` volatile dan `close()` idempoten; kondisi fisik belum diuji. |
| 5. Screen Awake | **PARTIAL** | Flag dipasang selama Activity terlihat; tanpa wakelock; MIUI belum diuji. |

Tidak ada status PASS penuh untuk pekerjaan yang memerlukan bukti perangkat.
Status PASS hanya dipakai untuk bagian yang benar-benar dapat diverifikasi di
JVM/build.

## 1. Perubahan source

| File | Perubahan |
|---|---|
| `core/protocol/SnifferLogEvent.kt` | Predikat tunggal `isError` untuk statistik + filter. |
| `core/protocol/CommunicationSniffer.kt` | Riwayat error 500 entri; ekspor hex lengkap + bagian `ERROR HISTORY`. |
| `core/protocol/HondaProtocolEngine.kt` | Frame TX/RX/ERROR/STATE Keyless juga masuk ke log ekspor. |
| `ui/MainViewModel.kt` | `retainedErrorEvents`; `createLogShareFile()` via cache + FileProvider. |
| `ui/screens/LogScreen.kt` | Filter error baru; key unik; Open Location aman; Share lampiran file; pesan kosong informatif. |
| `MainActivity.kt` | Keep-screen-on selama Activity terlihat (onCreate/onStart/onStop). |
| `core/usb/UsbSerialLibraryTransport.kt` | `isOpen` volatile; `close()` synchronized dan idempoten. |
| `AndroidManifest.xml` | Provider `androidx.core.content.FileProvider`. |
| `res/xml/file_paths.xml` | Path `cache/share/` (baru). |
| `test/.../SnifferEventClassificationTest.kt` | 5 test baru (baru). |

Tidak ada perubahan pada:

- identitas, nama pemilik, branding, UI identity, atau kredit;
- algoritma/frame Keyless;
- offset/skala live data;
- signing key, credential, atau rahasia;
- Gate 10 atau mekanisme internalnya;
- data kendaraan/konfigurasi yang sudah ada.

## 2. Bukti build dan pengujian

Folder `bukti/`:

- `testDebugUnitTest.log` — `:app:testDebugUnitTest` berhasil.
- `build_debug_release.log` — `:app:assembleDebug` dan
  `:app:compileReleaseKotlin` berhasil.
- `verifikasi_hasil.txt` — jumlah test, ukuran/hash APK debug, cuplikan provider.
- `manifest_apk_debug.xmltree.txt` — dump manifest APK debug.

Angka:

- Total unit test: **335**
- Gagal: **0**
- APK debug: **57.213.202 byte**
- SHA-256 APK debug:
  `1d1566ba97b3a38b28751d36141fec96bdcff19e3742ced6cd33261c953acf37`
- Provider di APK:
  `androidx.core.content.FileProvider`,
  authority `com.revcore.android.fileprovider`, `exported=false`,
  `grantUriPermissions=true`.

Catatan: APK debug **tidak dipublikasikan** dan bukan artefak rilis resmi.
`assembleRelease` tidak dijalankan karena kredensial signing tidak tersedia pada
sesi ini; hanya `compileReleaseKotlin` yang diverifikasi.

## 3. Perubahan dokumentasi/metadata

- Dokumen baru di folder ini: laporan Pekerjaan 1–5 dan ringkasan ini.
- `CHANGELOG.md` repository laporan diperbarui.
- `README.md` dan `PUBLICATION_MANIFEST.csv` diperbarui untuk indeks/hash.
- `versionCode`/`versionName` aplikasi **tidak diubah**. Alasannya: tidak ada
  rilis publik pada pekerjaan ini, dan kebijakan integritas build mengikat
  `versionCode=1`/`versionName=1.0`; menaikkannya tanpa rilis resmi hanya
  menambah risiko ketidakcocokan. Perubahan ini adalah pengembangan lokal.

## 4. Batasan hardware

Belum diuji pada perangkat:

- pembacaan Keyless dan Security Access pada Vario 150 SmartKey;
- parameter live data `dat16`/`dat11`/`dat13`/`dat10`;
- Sharesheet dan pembacaan file oleh aplikasi lain;
- file manager saat “Open Location”;
- detach/attach USB, OTG, dan dialog izin pada MIUI 14;
- perilaku layar tetap aktif pada Poco X3 NFC.

Tidak ada hasil hardware yang dikarang.

## 5. Risiko tersisa

1. Keberhasilan Keyless tetap tidak diketahui sampai ada log baru dari
   kendaraan; frame security kini ikut terekspor, jadi log perlu diperlakukan
   sebagai data diagnostik.
2. Ring buffer 1000 event membatasi riwayat ekspor; error dipertahankan, tetapi
   trafik lama hilang. Perekam sesi penuh adalah pekerjaan terpisah.
3. Share bergantung pada FileProvider dan grant URI; beberapa aplikasi penerima
   mungkin meminta izin tambahan.
4. `read()` masih menelan exception menjadi array kosong; deteksi port mati
   bergantung pada detach receiver dan timeout.
5. Window flag dapat diabaikan oleh kebijakan hemat daya produsen.

## 6. Prinsip

RevCore tetap menjadi jembatan untuk belajar, bukan pagar yang membatasi
pengetahuan. Semua klaim di laporan ini dipisahkan antara:

- **terbukti dari source/log**,
- **terimplementasi tetapi belum diverifikasi**, dan
- **belum diuji pada hardware**.
