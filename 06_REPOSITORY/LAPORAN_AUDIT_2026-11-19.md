# LAPORAN AUDIT MENYELURUH — REVCORE

Tanggal audit: 19 November 2026
Repository: `otoy6661/Revcore-Project` (lokal: `C:\Users\Lord Otoy\Documents\Qoder\work\Revcore-Project`)
Commit audit: `e2d74e954359bb7aeac2d993c6ff2f166f432e90`
Tag: `v0.3.0`
Branch: `main` (sinkron dengan `origin/main`)
Pemilik: `otoy`

> **DOKUMEN INTERNAL.** Dokumen ini memuat lokasi temuan batas publikasi dan
> ketidakpastian teknis. Sebelum dipublikasikan, bagian 16 dan 19 harus disanitasi.
> Versi pengetahuan yang siap dipublikasikan ada di `KB_REVCORE_PUBLIK_DRAFT.md`.

## 0. Metode dan batas audit

Audit dilakukan dengan membaca source, test, dokumentasi, riwayat Git, aset rilis, dan
menjalankan ulang build, test, validator, serta seluruh contoh Java. Tidak ada source
produksi yang diubah. Repository tetap bersih pada commit audit.

Label bukti yang dipakai:

| Label | Arti |
|---|---|
| `VERIFIED` | Dijalankan ulang pada sesi audit ini dan hasilnya diperiksa |
| `SOURCE` | Dibaca langsung dari source/test dengan rujukan file dan baris |
| `SYNTHETIC` | Diuji dengan fixture/data sintetis |
| `OWNER` | Konfirmasi Otoy 19 November 2026 |
| `UNKNOWN` | Belum ada bukti yang cukup; tidak diisi dengan tebakan |

---

## 1. Ringkasan kondisi repository

| Aspek | Nilai | Bukti |
|---|---|---|
| Berkas terlacak | 170 | `git ls-files` |
| Source Kotlin | 53 berkas, 9.791 baris | hitung langsung |
| Test Kotlin | 19 berkas, 2.517 baris, 153 `@Test` | XML hasil test |
| Dokumen Markdown | 64 (24 `docs/`, 11 `education/`, 6 `audit/`, 23 akar/lain) | `git ls-files` |
| Contoh dapat dijalankan | 13 (01–13); 14–16 panduan | `samples/` |
| Fixture/contoh data | 6 berkas JSON sintetis | `examples/` |
| Unit test dijalankan ulang | **153 test, 0 gagal, 0 error, 0 dilewati** | `gradle --offline test --rerun-tasks` |
| AAR dibangun ulang | 540.282 byte, SHA-256 `afac4d22ba8d7668ffbd75b62dc58a2b2156c38bcfe45f67e0599d5d1e53fe37` | `gradle --offline assembleDebug` |
| Validator fixture | LULUS, 14 frame valid | `py tools/validate_fixtures.py --verbose` |
| Validator dataset | LULUS, 5 pemeriksaan, bilinear 1,34 | `py tools/validate_datasets.py --verbose --demo` |
| APK referensi | 39.689.642 byte, SHA-256 `b2b6c5bd68cc9c727c2babe0c510b928a6135fa7ef5e9d8847275887c8647432` | `sha256sum`, sama dengan aset rilis GitHub |
| Rilis GitHub | `v0.3.0`, publik, 17 Nov 2026; 91 unduhan APK, 101 unduhan ZIP (per 19 Nov 2026) | `gh api` |
| Perubahan source saat audit | Tidak ada | `git status` bersih |

Catatan: AAR tidak reproducible byte-per-byte. Snapshot audit 17 Nov 2026 mencatat
540.273 byte / `9b5f478b…11ee`; build ulang 19 Nov 2026 menghasilkan 540.282 byte /
`afac4d22…3fe37`. Perbedaan ini sudah dicatat di `FINAL_PUBLICATION_READINESS.md` §7 dan
bukan kegagalan build.

---

## 2. Inventaris keberhasilan enam menu

Konfirmasi Otoy dan temuan source dipisahkan, tidak ada yang dihapus. Empat kelompok
status memakai nilai yang ditetapkan work order.

| Menu | Implementasi | Pengujian | Hasil | Kualitas | Bukti dan catatan |
|---|---|---|---|---|---|
| Dashboard | `IMPLEMENTED` (di APK) | `OWNER_REPORTED` | `SUCCESS` | `NO_KNOWN_BUG` | Konfirmasi Otoy; layer aplikasi tidak ada di repo publik sehingga tidak dapat diaudit source |
| Live Data | `IMPLEMENTED` | `OWNER_REPORTED`, `UNIT_TESTED` | `PARTIAL_SUCCESS` | `BUG_REPORTED` | 8 parameter tampil menurut Otoy; TPS saat gas tertutup tidak 0%; parser/profile diuji unit; jalur katalog bawaan kosong (lihat §10–§11) |
| Diagnostic | `IMPLEMENTED` | `OWNER_REPORTED`, `UNIT_TESTED` | `SUCCESS` | `NO_KNOWN_BUG` (owner); 3 risiko source `UNDER_INVESTIGATION` | Owner tidak melaporkan bug; audit source menemukan E5/E6/subcode>15 (§5) |
| Tuning | `IN_DEVELOPMENT` | `NOT_TESTED` | `UNKNOWN` | `UNDER_INVESTIGATION` | Owner menyatakan masih dikembangkan; tidak diberi label gagal |
| Pengaturan | `IMPLEMENTED` (di APK) | `OWNER_REPORTED` | `SUCCESS` | `NO_KNOWN_BUG` | Konfirmasi Otoy; layer aplikasi di luar repo publik |
| Log Komunikasi | `IMPLEMENTED` | `OWNER_REPORTED` | `SUCCESS` | `NO_KNOWN_BUG` | Konfirmasi Otoy; model log publik tersedia di `core.comm.CommunicationSniffer` |

### 2.1 Tahap 0 — tabel inventaris pencapaian

| Fitur | Implementasi | Keberhasilan | Masalah | Bukti | Status |
|---|---|---|---|---|---|
| Dashboard | `IMPLEMENTED` | `SUCCESS` | Tidak ada laporan | `OWNER` | `OWNER_REPORTED_SUCCESS` |
| Live Data: RPM | `IMPLEMENTED` | `SUCCESS` | Tidak ada | `OWNER` | `OWNER_REPORTED_SUCCESS` |
| Live Data: TPS | `IMPLEMENTED` | `PARTIAL_SUCCESS` | Gas tertutup bukan 0% | `OWNER` + `SOURCE` | `BUG_REPORTED` |
| Live Data: EOT | `IMPLEMENTED` | `SUCCESS` | Jalur publik tidak memiliki PID EOT khusus | `OWNER` + `SOURCE` | `OWNER_REPORTED`, jalur `UNKNOWN` |
| Live Data: tegangan baterai | `IMPLEMENTED` | `SUCCESS` | Skala berbeda antarjalur | `OWNER` + `SOURCE` | `OWNER_REPORTED` |
| Live Data: ignition advance | `IMPLEMENTED` | `SUCCESS` | Tidak ada | `OWNER` | `OWNER_REPORTED` |
| Live Data: injector pulse | `IMPLEMENTED` | `SUCCESS` | Satuan berbeda antarjalur | `OWNER` + `SOURCE` | `OWNER_REPORTED` |
| Live Data: vehicle speed | `IMPLEMENTED` | `SUCCESS` | Tidak ada | `OWNER` | `OWNER_REPORTED` |
| Live Data: O2 | `IMPLEMENTED` | `SUCCESS` | Hanya tampil saat mesin berputar pada jalur fallback | `OWNER` + `SOURCE` | `OWNER_REPORTED` |
| Diagnostic (baca/clear DTC) | `IMPLEMENTED` | `SUCCESS` | E5/E6/subcode>15 belum diperbaiki | `OWNER` + `SOURCE` | `OWNER_REPORTED_SUCCESS`, risiko terbuka |
| Tuning | `IN_DEVELOPMENT` | `UNKNOWN` | Belum selesai | `OWNER` | `IN_DEVELOPMENT` |
| Pengaturan | `IMPLEMENTED` | `SUCCESS` | Tidak ada laporan | `OWNER` | `OWNER_REPORTED_SUCCESS` |
| Log Komunikasi | `IMPLEMENTED` | `SUCCESS` | Tidak ada laporan | `OWNER` | `OWNER_REPORTED_SUCCESS` |
| APK rilis 161126 | `IMPLEMENTED` | `SUCCESS` | Tidak ada laporan | `VERIFIED` hash | Rilis publik apa adanya |

---

## 3. Inventaris pencapaian lain

| Kelompok | Pencapaian | Bukti |
|---|---|---|
| Wire engine | Framing, checksum, echo filter, scan frame, timeout, wake pulse | `HondaFrameCodec`, `KlineWireEngine`, test |
| Transport | USB serial library + driver FTDI native, kebijakan attach/permission/detach | `core.usb`, `core.ftdi` |
| Sesi | Single-flight gate, lifecycle, generation guard, link-loss detection | `EcuSessionManager`, `SingleFlightGate` |
| Identifikasi | Parser, kanonikalisasi, pencocokan exact/prefix, ambiguity | `HondaIdentifierParser`, `EcuIdCanonicalizer`, `EcmDatabase` |
| DTC | 3 query baca, 3 query clear, 15 kode referensi, verifikasi baca ulang | `HondaDtcDatabase`, `HondaProtocolEngine` |
| Live Data generik | Profil, field spec, parser, validasi, cache, rotasi extension | `LiveDataProfile`, `LiveDataFrameParser` |
| MAP | Parser JSON mini, validasi, interpolasi bilinear, contoh sintetis | `core.data.map`, 5 pemeriksaan validator |
| ROM read-only | Word, checksum, diff blok; tanpa jalur tulis | `core.data.rom` |
| Storage/log | Layout penyimpanan, session log, progress terukur | `core.storage`, `core.tuning` |
| Dataset | 3 record ECM sintetis, template kendaraan, 6 contoh JSON | `core/src/main/assets`, `examples/` |
| Dokumentasi | 24 dokumen teknis, 11 dokumen edukasi, 6 audit | `docs/`, `education/`, `audit/` |
| Contoh | 13 program berjalan + 3 panduan lanjutan | `samples/` |
| Validator | Fixture frame dan dataset | `tools/` |
| Rilis | ZIP developer + APK asli di GitHub Releases | `v0.3.0` |

---

## 4. Inventaris bug pengguna

| ID | Gejala | Komponen | Bukti | Status |
|---|---|---|---|---|
| U-01 | Persentase TPS saat gas tertutup tidak menunjukkan 0% | Live Data / TPS | `OWNER` | `BUG_REPORTED`; TPS tetap dianggap pernah berhasil |
| U-02 | Adapter terputus intermiten | USB lifecycle / serial | `OWNER` (work order) | `UNDER_INVESTIGATION`; detail kondisi belum diberikan |
| U-03 | Layar tidur saat digunakan | Lifecycle aplikasi | `OWNER` (work order) | `UNKNOWN`; layer aplikasi tidak ada di repo publik |
| U-04 | Backlog keamanan internal | Gate internal | Internal | Hanya keberadaan yang dicatat; detail tidak didokumentasikan |

Tidak ada bukti yang cukup untuk menyebut U-02 atau U-03 sebagai kegagalan perangkat
lunak tertentu. Keduanya memerlukan log aplikasi dan kondisi reproduksi.

---

## 5. Temuan bug dari audit source

Semua temuan di bawah berasal dari pembacaan source; tidak ada yang diubah.

| ID | Tingkat | Lokasi | Temuan | Bukti | Status |
|---|---|---|---|---|---|
| LIVE-01 | Tinggi (cakupan) | `HondaProtocolEngine.kt:1194–1205` | `queryLiveData()` langsung `return null` + `UNSUPPORTED_PROFILE` bila `hasLiveDataCatalog == false`. Katalog bawaan kosong (`LiveDataProfile.kt`), sehingga `readPidFallback()` di baris 1310 tidak pernah tercapai pada baseline publik | `SOURCE` | Terbuka (informasi) |
| LIVE-02 | Tinggi (kandidat bug) | `HondaProtocolEngine.kt:1577–1578`, `1592`, `1600` | Fallback membaca `frame[2]` sebagai byte data dan menolak bila `frame[2]` = `0x61`/`0x21`. Padahal service berada di indeks 2 (`HondaFrameCodec.kt:65`); respons positif normal `0x61` akan ditolak, respons lain akan terbaca bergeser satu byte | `SOURCE` | `UNDER_INVESTIGATION`; butuh tangkapan RX |
| LIVE-03 | Tinggi (bug pengguna) | `HondaProtocolEngine.kt:1631`; `LegacyHondaProtocolEngine.kt:939, 1068` | TPS dihitung `raw × 100 / 255` tanpa offset/zero-calibration. ADC gas tertutup yang tidak nol menghasilkan persentase > 0 | `SOURCE` + `OWNER` | `BUG_REPORTED` |
| LIVE-04 | Rendah | `HondaProtocolEngine.kt:1701` | TPS tidak tersedia tetap dilaporkan `0.0f`; `parameterStates` membedakan `UNSUPPORTED`, tetapi nilai numerik tidak | `SOURCE` | Terbuka (UX/data honesty) |
| DTC-E5 | Sedang | `HondaDtcDatabase.kt:117` | Validasi count-prefixed memakai `payload.size >= 1 + firstByte*2` (longgar), bukan sama dengan; byte ekor dapat diterima | `SOURCE` | Terbuka, belum diperbaiki |
| DTC-E6 | Sedang | `HondaProtocolEngine.kt:1030–1040` | Payload yang gagal diurai menghasilkan daftar kosong, lalu state `OK_EMPTY` dan `DTC_READ_CONFIRMED`; "tidak ada DTC" dan "paket tidak terbaca" tidak terpisah di jalur ini | `SOURCE` | Terbuka, belum diperbaiki |
| DTC-SUB | Sedang | `HondaDtcDatabase.kt:143` | Subcode di luar 0..15 dipaksa menjadi 0; kode berbeda dapat bertabrakan | `SOURCE` | Terbuka, belum diperbaiki |
| DOC-01 | Rendah | `docs/SENSOR_DECODING.md:95` vs `HondaProtocolEngine.kt:1643` | Injector: contoh 0x7A memakai skala 0.01 ms; fallback 0x21 memakai 0.001 ms. Dua jalur berbeda, tetapi pembaca dapat menganggapnya kontradiksi | `SOURCE` | Risiko dokumentasi |
| DOC-02 | Rendah | `docs/SENSOR_DECODING.md:93` vs `HondaProtocolEngine.kt:1640` | Baterai: contoh 0x7A memakai 0.05 V; fallback 0x21 memakai 0.0625 V | `SOURCE` | Risiko dokumentasi |
| EOT-01 | Sedang | `TempSensorType.kt:10`; `HondaProtocolEngine.kt:1634–1642` | EOT ada sebagai tipe sensor dan label DTC, tetapi jalur publik hanya membaca ECT (PID 0x05). Tidak terbukti EOT ditampilkan dari kanal terpisah | `OWNER` + `SOURCE` | `UNKNOWN` |
| T17-01 | Tinggi (pengetahuan) | Tidak ada di repository | Request `72 05 71 17 01` hanya tercatat di work order; tidak ada implementasi, offset, atau fixture di repository. Tidak ada posisi byte yang ditebak | `SOURCE` + work order | `UNKNOWN` |
| REC-01 | Sedang | `HondaProtocolEngine.kt:362–386`; `core.usb.AdapterConnectionPolicy` | `:core` mendeteksi link loss dan menyediakan keputusan attach/permission; reconnection otomatis ada di layer aplikasi yang tidak disertakan | `SOURCE` | `UNKNOWN` untuk perilaku aplikasi |
| REL-01 | Rendah | `core/build/outputs/aar` | AAR tidak reproducible byte-per-byte | `VERIFIED` dua build | Sudah didokumentasikan |

Catatan penting untuk LIVE-02: temuan ini **tidak** membuktikan fallback gagal pada
kendaraan, karena (a) fallback tidak terjangkau pada baseline publik, dan (b) belum ada
tangkapan RX. Ini kandidat kuat yang harus diuji dengan log sebelum source diubah.

---

## 6. Fitur selesai, parsial, dan belum diimplementasikan

### 6.1 Selesai (dengan bukti test)

- Framing, checksum, echo filter, validasi frame.
- Transport USB serial dan FTDI native.
- Wake pulse baseline 70/130 ms dan urutan identifikasi baseline.
- Identifikasi baseline generik dan kanonikalisasi ID.
- Baca/clear DTC baseline dengan verifikasi baca ulang.
- Parser Live Data generik + interpolasi MAP + analisis ROM read-only.
- Storage, session log, sniffer, status model.
- 153 unit test, 14 fixture, 5 pemeriksaan dataset.
- Dokumentasi developer, edukasi, 13 contoh berjalan.

### 6.2 Parsial

- DTC: alur utama ada; E5/E6/subcode>15 belum dikeraskan.
- Live Data: parser lengkap, katalog bawaan kosong; 8 parameter owner berasal dari jalur
  yang tidak dapat direproduksi dengan baseline publik.
- TPS: nilai tampil, tetapi belum terkalibrasi terhadap gas tertutup.
- Identifikasi: baseline generik; family Keihin/Shindengen/Denso `UNRESOLVED`.
- Adapter: deteksi link loss ada; reconnection di layer aplikasi.
- AAR: build lulus, tidak reproducible byte-per-byte.

### 6.3 Belum diimplementasikan di repository publik

- Katalog Live Data proprietary dan Tabel 17.
- EOT sebagai kanal sensor terpisah.
- Flash/remap, kripto kontainer, tulis ROM.
- Database kendaraan nyata dan MAP nyata.
- UI/Application Layer dan Security/Integrity.

---

## 7. End-to-end flow komunikasi

Alur aktual yang dapat ditelusuri di repository publik:

| # | Tahap | File / class / fungsi | Input | Output | Kondisi gagal dan penanganan |
|---:|---|---|---|---|---|
| 1 | Adapter | `HondaProtocolEngine.connect()`; `UsbSerialLibraryTransport` / `FtdiSerialDriver` | `UsbDevice`, preferensi driver | Port terbuka, 8N1 | `transport.open()` false → `false`, log error, status `USB_OPEN` tidak tercapai |
| 2 | K-Line | `KlineWireEngine`; `UsbTransport` | Baud 10400 | Jalur TX/RX siap | Port tertutup / write gagal → `CommandOutcome.Failure` |
| 3 | Inisialisasi | `connect()` → `performKlineWakeup()` | Port terbuka | `_connectionStep = TRANSFER_LAYER_ACTIVE` | Wake gagal → tetap `false`; identifikasi tidak dijalankan otomatis |
| 4 | Wake-up | `wakeupInternal()` → `KlineWireEngine.wakePulse()` | BREAK LOW 70 ms, HIGH 130 ms, baud 10400 | Pulsa terkirim, `LINE_READY` | Adapter menolak BREAK → log error; waktu terukur adalah waktu host |
| 5 | TX | `legacyTransceive()` → `EcuSessionManager.transact()` | Frame lengkap + `KlineWireConfig` | Frame terkirim | Retry 1, timeout 700 ms default; single-flight mencegah transaksi bersamaan |
| 6 | RX | `KlineWireEngine` read loop | Byte dari transport | Buffer RX | Timeout → `TIMEOUT`; buffer maksimum 1024 |
| 7 | Validasi frame | `HondaFrameCodec.isWellFormed()` | Buffer RX | Frame valid atau `null` | Header tidak diterima, length ≠ ukuran, checksum salah → gagal; echo lokal dibuang |
| 8 | Ekstraksi payload | `HondaFrameCodec.payload()`; DTC `readDtcsInternal()`; Live `extractLivePayload()` | Frame valid | Payload | Ukuran/format tidak sesuai → `INVALID_PAYLOAD` |
| 9 | Pemetaan sensor | `LiveTableProfile.fields`; `LiveSensor`; PID fallback map | Payload / PID | Field dan offset | Field di luar payload → dilewati; tidak ada tebakan offset |
| 10 | Parser | `LiveDataFrameParser.parse()`; `HondaDtcDatabase.parseDtcPacket()` | Payload + profil | Nilai mentah / DTC | 0xFF tanpa alternate → `INVALID_RESPONSE`; paket DTC aneh → daftar kosong (E6) |
| 11 | Konversi | `LiveDataField` scale/bias; PID fallback | Raw | Nilai fisik | Scale per profil; jalur PID memakai formula sendiri (§10) |
| 12 | Validasi | `validMin/validMax`; `engineRunningOnly`; cek rentang PID | Nilai fisik | State per sensor | Di luar rentang → `INVALID`/`STALE`; O2 KOEO → `NOT_AVAILABLE_IN_KOEO` |
| 13 | Output | `LiveTelemetry`, `StateFlow`, `CommunicationSniffer` | Nilai valid | UI pemanggil / log | UI dan lifecycle bukan bagian `:core` |

---

## 8. Knowledge Base protokol ECU (ringkasan)

### 8.1 Frame K-Line

```text
[header][declared length][service][params...][checksum]
```

- `declared length` mencakup header sampai checksum; harus sama dengan ukuran frame.
- Checksum: komplemen dua dari jumlah seluruh byte sebelum checksum:
  `(256 - (sum & 0xFF)) & 0xFF`.
- Ukuran minimum 4 byte; batas body 254 byte.
- Service negatif `0x7F`.
- Header yang diterima ditentukan `DEFAULT_ACCEPTED_HEADERS`; header yang terlihat:
  `0x72`, `0x02`, `0x7E`, `0x7C`, `0x7D`, `0x7B`, `0xFE`.
- Contoh valid: `72 05 74 01 14`, `72 05 71 20 F8`, `72 05 00 00 89`.

### 8.2 Baud, timing, timeout

| Parameter | Nilai | Sumber |
|---|---|---|
| Baud identifikasi utama | 10400 | `FtdiConstants.BAUD_KLINE_DEFAULT` |
| Baud fallback | 9600 | `FtdiConstants.BAUD_STANDARD` |
| Baud fast/reprogram (konstanta, tidak dipakai baseline) | 38400 / 57600 | `FtdiConstants` |
| Timeout transaksi default | 700 ms | `KlineWireConfig` |
| Retry default | 1 | `KlineWireConfig` |
| Wake LOW / HIGH | 70 ms / 130 ms | `HondaEcuProfiles.baselineWake` |
| Echo window | 0 ms | `KlineWireConfig` |
| Buffer RX maksimum | 1024 byte | `KlineWireConfig` |

### 8.3 Identifikasi ECU baseline

| Urutan | Request | Label | Status bukti |
|---:|---|---|---|
| 0 | `FE 04 72 8C` | Tester present | `RECONSTRUCTED` |
| 1 | `72 05 00 F0 99` | Query ID 00/F0 | `RECONSTRUCTED` |
| 2 | `72 07 72 00 00 05 10` | Query ID 72/00 (layout terdokumentasi) | `RECONSTRUCTED` |
| 3 | `72 05 71 00 18` | Query ID 71/00 | `RECONSTRUCTED` |
| Fallback | Service `0x1A`, dengan/tanpa parameter | ID alternatif setelah baseline gagal | `REFERENCE` |

Contoh respons layout `id.7200` (sintetis):

```text
request : 72 07 72 00 00 05 10
response: 72 0B 72 00 00 01 03 7A 0F 02 <checksum>
payload : 00 00 01 03 7A 0F 02
          selector   ECM ID 5 byte
```

Tidak ada pemotongan field secara sewenang-wenang. ID yang tidak lengkap disimpan
sebagai kandidat, bukan diterbitkan sebagai model.

### 8.4 DTC

| Operasi | Urutan request |
|---|---|
| Baca | `72 05 74 01 14` → `72 05 71 20 F8` → `72 05 00 00 89` |
| Clear | `72 05 60 01 28` → `72 05 74 02 13` → `72 04 04 86` |

Payload count-prefixed: `[count][code][sub]...`. Contoh sintetis:
`02 01 01 07 01` → P0107, P0117. Pair stream dipakai bila count-prefixed tidak valid.
Echo service dibuang sebelum parsing. `OK_EMPTY` dimaksudkan hanya untuk frame valid
tanpa kode; audit menemukan jalur yang dapat menyamakan paket gagal-urai dengan kosong.

### 8.5 Live Data

Katalog bawaan kosong. Pemanggil harus menyediakan `LiveTableProfile`; jika tidak,
`queryLiveData()` mengembalikan `UNSUPPORTED_PROFILE` tanpa mengirim frame. Contoh
sintetis 0x7A memakai request `72 05 71 7A 9E` dan payload 12 byte. Fallback PID 0x21
ada di source tetapi tidak terjangkau pada baseline publik dan belum teruji dengan
tangkapan perangkat keras.

---

## 9. Referensi TX/RX dan pemetaan sensor yang boleh dipublikasikan

Semua frame di bawah berlabel sintetis/rekonstruksi; tidak ada klaim ECU fisik.

| Keperluan | Frame | Status |
|---|---|---|
| Tester present | `FE 04 72 8C` | `RECONSTRUCTED` |
| Baca DTC 74/01 | `72 05 74 01 14` | `RECONSTRUCTED` |
| Baca DTC 71/20 | `72 05 71 20 F8` | `RECONSTRUCTED` |
| Baca DTC 00/00 | `72 05 00 00 89` | `RECONSTRUCTED` |
| Clear 60/01 | `72 05 60 01 28` | `RECONSTRUCTED` |
| Clear 74/02 | `72 05 74 02 13` | `RECONSTRUCTED` |
| Clear 04 | `72 04 04 86` | `RECONSTRUCTED` |
| Live data contoh | `72 05 71 7A 9E` | `SYNTHETIC` |
| Respons DTC | `72 0A 74 01 02 01 01 07 01 03` | `SYNTHETIC` |
| Respons negatif | `72 06 7F 74 12 83` | `SYNTHETIC` |

Pemetaan sensor contoh 0x7A (payload sintetis) ada di `docs/SENSOR_DECODING.md` dan
`examples/sensor_data/live_data.json`. Pemetaan PID 0x21 di source berbeda jalur dan
tidak boleh dicampur dengan tabel 0x7A.

Tabel 17 (`72 05 71 17 01`): tidak ada payload, offset, atau fixture di repository.
Daftar sensor dari work order (SPEED, RPM, TPS1/2, ECT1/2, IAT1/2, MAP1/2, BAT, INJ, IGT,
DTC1–4) dicatat sebagai pengetahuan yang belum terverifikasi. Tidak ada posisi byte yang
ditebak.

---

## 10. Formula dan decoder

### 10.1 Alur decoder

`Raw Byte → Offset → Data Type → Endian → Formula → Validation → Converted Value`

- Offset dihitung dari awal payload (bukan awal frame).
- Panjang 1 atau 2 byte; 2 byte big-endian (`LiveDataProfile.kt:236–239`).
- `0xFF` bukan nilai; alternate offset hanya dipakai bila byte utama `0xFF`.
- `scale` dan `bias` diterapkan setelah raw; validasi memakai rentang nilai akhir.

### 10.2 Formula jalur contoh 0x7A (sintetis)

| Sensor | Offset | Len | Formula | Satuan |
|---|---:|---:|---|---|
| RPM | 0 | 2 | `raw` | rpm |
| TPS_ADC | 2 | 1 | `raw` | count |
| TPS_PERCENT | 2 | 1 | `raw × 100/255` | % |
| TPS_VOLTAGE | 2 | 1 | `raw × 5/255` | V |
| ECT | 4 | 1 | `raw − 40` | °C |
| IAT | 5 | 1 | `raw − 40` | °C |
| MAP | 6 | 2 | `raw` | kPa |
| BATTERY | 8 | 1 | `raw × 0.05` | V |
| SPEED | 9 | 1 | `raw` | km/h |
| INJECTOR | 11 | 1 | `raw × 0.01` | ms |

### 10.3 Formula jalur PID 0x21 (fallback, tidak terjangkau baseline)

| PID | Sensor | Formula | Catatan |
|---|---|---|---|
| `0x01` | RPM | `raw`; jika >15000 → `raw × 50/6` | valid 0..15000 |
| `0x02` | TPS | `raw × 100/255` | tanpa offset |
| `0x03` | MAP | `raw` | kPa |
| `0x04` | IAT | `raw − 40` | °C |
| `0x05` | ECT | `raw − 40` | °C |
| `0x06` | Battery | `raw × 0.0625` | V |
| `0x07` | Injector | `raw × 0.001` | ms |
| `0x08` | Ignition | `raw − 64` | derajat |
| `0x09` | Speed | `raw` | km/h |
| `0x0C` | O2 | `raw × 4.882 / 1000` | V; hanya saat mesin berputar |

Jalur 0x7A dan 0x21 memakai skala baterai/injector yang berbeda. Ini bukan kontradiksi
otomatis karena formatnya berbeda, tetapi wajib dijelaskan dalam KB agar pembaca tidak
mencampur keduanya.

---

## 11. Kendaraan dan ECU yang diketahui

| Item | Status | Bukti |
|---|---|---|
| Database ECM publik | 3 record sintetis `SAMPLE-ECM-001..003` | `core/src/main/assets/ecm_database.json` |
| Template kendaraan | 1 record `SAMPLE-VEHICLE-001` | `examples/vehicle_db/vehicle_template.json` |
| MAP publik | 1 contoh sintetis 8×11 | `examples/maps/synthetic_map.json` |
| Honda PGM-FI baseline generik | `RECONSTRUCTED`, belum diuji ECU fisik | `HondaEcuProfiles.genericBaseline` |
| Keihin H99B / KWP | `UNRESOLVED` | katalog kosong |
| Shindengen H99B | `UNRESOLVED` / `HYPOTHESIS` | tidak ada modul khusus |
| Denso H99B | `UNRESOLVED` | frame belum direkonstruksi |
| Kendaraan nyata | Tidak disertakan | audit aset |
| Kompatibilitas kendaraan | Tidak diklaim | README, `FINAL_PUBLICATION_READINESS.md` |

Tidak ada bukti publik untuk menyebut satu model kendaraan tertentu kompatibel.

---

## 12. Metode alternatif

| Metode | Kapan dipakai | Status | Batas |
|---|---|---|---|
| Baud 10400 | Percobaan pertama | `RECONSTRUCTED` | Diuji sintetis, bukan ECU fisik |
| Fallback 9600 | Tidak ada frame valid pada 10400 | `RECONSTRUCTED` | Bukan bukti ECU memakai 9600 |
| Wake pulse diulang dengan force BREAK | Setelah 10400/9600 gagal | `RECONSTRUCTED` | Waktu host, bukan pengukuran bus |
| Query `0x1A` | Setelah seluruh baseline gagal | `REFERENCE` | Hanya setelah kegagalan; bukan jalur utama |
| PID `0x21` | Setelah tabel Live Data tidak menjawab | `RECONSTRUCTED` | Tidak terjangkau baseline; parsing bermasalah (LIVE-02) |
| Driver FTDI native vs usb-serial library | Preferensi saat connect | `VERIFIED` build | Perilaku hardware tidak diuji di audit ini |

Tidak ada metode yang boleh dianggap berlaku untuk semua ECU Honda.

---

## 13. Failure & Troubleshooting Library

Setiap kasus memakai 12 field yang diminta.

### F-01 — ECU tidak merespons saat identifikasi

1. **ID kasus:** F-01
2. **Gejala:** Tidak ada frame valid setelah wake pulse dan seluruh query baseline.
3. **Kondisi pemicu:** Kontak OFF, pin K-Line salah, adapter/transceiver tidak aktif, baud tidak cocok.
4. **Komponen terkait:** `HondaProtocolEngine`, `KlineWireEngine`, `UsbTransport`, adapter.
5. **Penyebab diketahui:** Port gagal dibuka, BREAK ditolak adapter, atau tidak ada balasan pada 10400/9600.
6. **Penyebab diduga:** Pengkabelan/transceiver, bukan protokol.
7. **Log/bukti:** Status `NO_RESPONSE`, timeline `PROTOCOL_INIT_COMPLETED=false`.
8. **Cara reproduksi:** Buka adapter tanpa kontak ON, jalankan identifikasi.
9. **Solusi dicoba:** Wake ulang, fallback 9600, probe presence, query `0x1A`.
10. **Hasil solusi:** Tidak ada frame → status jujur "tidak merespons", bukan "kontak OFF".
11. **Alternatif:** Periksa pin K-Line, ground, dan adapter.
12. **Status pengujian:** `SOURCE`; belum diuji ECU fisik pada audit ini.

### F-02 — Live Data `UNSUPPORTED_PROFILE`

1. **ID kasus:** F-02
2. **Gejala:** Live Data kosong; tidak ada frame dikirim.
3. **Kondisi pemicu:** Profil aktif tidak memiliki `liveDataTables`.
4. **Komponen terkait:** `HondaEcuProfiles`, `HondaLiveDataProfiles`, `queryLiveData()`.
5. **Penyebab diketahui:** Katalog bawaan kosong; hak penggunaan belum jelas.
6. **Penyebab diduga:** Parameter owner ditampilkan oleh profil yang disediakan layer aplikasi.
7. **Log/bukti:** `LiveDataState.UNSUPPORTED_PROFILE`; guard baris 1194–1205.
8. **Cara reproduksi:** Panggil `queryLiveData()` dengan `genericBaseline`.
9. **Solusi dicoba:** Fallback PID 0x21 — tidak tercapai karena guard.
10. **Hasil solusi:** Tidak ada query; status jujur, bukan nilai palsu.
11. **Alternatif:** Pemanggil mendaftarkan profil sendiri; perlu verifikasi hardware.
12. **Status pengujian:** `UNIT_TESTED` untuk profil/parser; jalur owner `UNKNOWN`.

### F-03 — TPS tidak 0% saat gas tertutup

1. **ID kasus:** F-03
2. **Gejala:** Persentase TPS > 0 saat throttle tertutup.
3. **Kondisi pemicu:** Mesin idle, gas tertutup.
4. **Komponen terkait:** TPS ADC, offset, formula, kalibrasi, karakteristik ECU.
5. **Penyebab diketahui:** Formula `raw × 100 / 255` tanpa offset; tidak ada nilai nol terkalibrasi.
6. **Penyebab diduga:** ADC gas tertutup tidak 0; atau (jika memakai fallback) service byte terbaca sebagai data (LIVE-02).
7. **Log/bukti:** `OWNER`; source `HondaProtocolEngine.kt:1631`, legacy `939/1068`.
8. **Cara reproduksi:** Baca TPS saat idle dan catat raw/ADC.
9. **Solusi dicoba:** Belum ada perubahan source (audit-only).
10. **Hasil solusi:** Belum diuji.
11. **Alternatif:** Kalibrasi zero per kendaraan; offset di profil; validasi terhadap tegangan TPS.
12. **Status pengujian:** `BUG_REPORTED`; butuh log raw.

### F-04 — Adapter terputus intermiten

1. **ID kasus:** F-04
2. **Gejala:** Sesi berhenti di tengah pembacaan.
3. **Kondisi pemicu:** Belum diketahui; dilaporkan owner.
4. **Komponen terkait:** USB lifecycle, permission, serial port, transport, sesi.
5. **Penyebab diketahui:** Belum ada.
6. **Penyebab diduga:** Kabel/OTG, chip adapter, daya, atau lifecycle aplikasi.
7. **Log/bukti:** `:core` menandai `LINK_LOST` setelah ambang kegagalan; log aplikasi belum tersedia.
8. **Cara reproduksi:** Belum ada langkah pasti.
9. **Solusi dicoba:** Deteksi link loss, single-flight, generation guard.
10. **Hasil solusi:** Tidak diketahui; reconnection ada di layer aplikasi.
11. **Alternatif:** Audit lifecycle aplikasi, log USB attach/detach, uji adapter lain.
12. **Status pengujian:** `OWNER` + `SOURCE`; `UNDER_INVESTIGATION`.

### F-05 — DTC kosong padahal ada kode

1. **ID kasus:** F-05
2. **Gejala:** Daftar DTC kosong setelah pembacaan.
3. **Kondisi pemicu:** Payload tidak dapat diurai / format tidak dikenal.
4. **Komponen terkait:** `readDtcsInternal`, `parseDtcPacket`, `HondaDtcDatabase`.
5. **Penyebab diketahui:** E6: payload kosong hasil gagal-urai dipetakan ke `OK_EMPTY`.
6. **Penyebab diduga:** E5: count-prefix longgar; subcode>15 menjadi 0.
7. **Log/bukti:** `HondaProtocolEngine.kt:1037–1040`; `HondaDtcDatabase.kt:117, 143`.
8. **Cara reproduksi:** Kirim fixture payload cacat/berlebih; periksa state.
9. **Solusi dicoba:** Belum ada perubahan; temuan dipertahankan.
10. **Hasil solusi:** Belum diperbaiki.
11. **Alternatif:** Pisahkan state `PARSE_FAILED`; validasi panjang ketat; pertahankan subcode mentah.
12. **Status pengujian:** `SOURCE`; perlu test regresi sebelum perubahan.

### F-06 — Build APK tidak ada di root / Gradle Wrapper tidak tersedia

1. **ID kasus:** F-06
2. **Gejala:** `assembleDebug` di root tidak menghasilkan APK; `./gradlew` gagal.
3. **Kondisi pemicu:** Root adalah library `:core`; wrapper jar di-ignore `.gitignore`.
4. **Komponen terkait:** `settings.gradle.kts`, `samples/01-hello-android`, Gradle 9.6.0.
5. **Penyebab diketahui:** Repository pustaka, bukan aplikasi; wrapper tidak disertakan.
6. **Penyebab diduga:** Pembaca mengira root menghasilkan APK.
7. **Log/bukti:** `settings.gradle.kts` hanya `include(":core")`; README sample 01.
8. **Cara reproduksi:** Jalankan `assembleDebug` di root, lalu cari APK.
9. **Solusi dicoba:** Build `samples/01-hello-android` dengan Gradle 9.6.0.
10. **Hasil solusi:** APK 844.858 byte, SHA-256 `9c3763af…5da01d` (`VERIFIED`).
11. **Alternatif:** Android Studio membuat wrapper saat impor.
12. **Status pengujian:** `VERIFIED`.

---

## 14. Dokumentasi pemula dan kontribusi

| Kelompok | Isi | Status | Catatan |
|---|---|---|---|
| `education/00–01` | Mulai, dasar Android/Kotlin/Gradle/Git | Selesai | Bahasa Indonesia, jalur bertahap |
| `education/02` | Membangun APK | Selesai, sudah dikoreksi | Menjelaskan AAR vs APK dan ketiadaan wrapper |
| `education/03–04` | Konsep diagnostik, referensi protokol | Selesai | Frame sintetis, batas jelas |
| `education/05` | Katalog kegagalan | Selesai | 5 kasus A–E + panduan menambah kasus |
| `education/06` | Pengembangan dengan AI | Selesai | Larangan menyentuh layer terlarang |
| `education/07` | Kontributor dan kemandirian | Selesai | Identitas, atribusi, distribusi |
| `education/08` | 16 contoh progresif | Selesai | Peta status sesuai isi `samples/` |
| `education/09` | Inventaris dan klasifikasi | Selesai | Batas publikasi |
| `docs/` 24 dokumen | Arsitektur, protokol, engine, MAP, ROM, build, testing | Selesai | Rujukan source dan batas bukti |
| `samples/README` | Indeks 13 contoh | Selesai | Status build/logika dicantumkan |

Kekurangan yang tercatat:

- Pembaca perlu diberi tahu bahwa contoh 02–13 hanya membuktikan logika, bukan ECU.
- Perbedaan skala 0x7A vs 0x21 (baterai, injector) belum dijelaskan eksplisit.
- Tidak ada contoh yang mendemontrasikan kalibrasi TPS.
- Panduan 14–16 adalah `REFERENCE`, bukan hasil eksekusi.

---

## 15. Hasil audit sample

| Sample | Tujuan | Cara jalan | Hasil audit 19 Nov 2026 | Status |
|---|---|---|---|---|
| 01 | Activity/manifest/APK | `gradle assembleDebug` | APK 844.858 byte, hash terverifikasi | Build `VERIFIED` |
| 02 | Java/Kotlin dasar | `javac` + `java` | exit 0, `HASIL: OK` | `VERIFIED` |
| 03 | Checksum | `javac` + `java` | exit 0, `HASIL: OK` | `VERIFIED` |
| 04 | Frame builder | `javac` + `java` | exit 0, `HASIL: OK` | `VERIFIED` |
| 05 | Frame parser | `javac` + `java` | exit 0, `HASIL: OK` | `VERIFIED` |
| 06 | DTC parser | `javac` + `java` | exit 0, `HASIL: OK` | `VERIFIED` |
| 07 | Live data decoder | `javac` + `java` | exit 0, `HASIL: OK` | `VERIFIED` |
| 08 | JSON mini parser | `javac` + `java` | exit 0, `HASIL: OK` | `VERIFIED` |
| 09 | Profil ECU | `javac` + `java` | exit 0, `HASIL: OK` | `VERIFIED` |
| 10 | ECU simulasi | `javac` + `java` | exit 0, `HASIL: OK (simulasi)` | `VERIFIED` |
| 11 | Transport interface | `javac` + `java` | exit 0, `HASIL: OK (simulasi)` | `VERIFIED` |
| 12 | Sesi DTC | `javac` + `java` | exit 0, `HASIL: OK (simulasi)` | `VERIFIED` |
| 13 | Database kendaraan | `javac` + `java` | exit 0, `HASIL: OK (sintetis)` | `VERIFIED` |
| 14 | Integrasi AAR | Panduan | Tidak dieksekusi | `REFERENCE` |
| 15 | Uji adapter nyata | Panduan | Tidak dieksekusi; butuh hardware | `NOT_TESTED` |
| 16 | Aplikasi diagnostik sendiri | Panduan | Tidak dieksekusi | `REFERENCE` |

Semua contoh 02–13 memakai data sintetis. Tidak ada contoh yang membuktikan kompatibilitas
ECU, timing hardware, atau perilaku kendaraan.

---

## 16. Pemeriksaan batas publikasi

> Bagian ini adalah temuan internal. Lokasi ditulis; isi terlarang tidak diulang di
> laporan ini agar dokumen dapat disanitasi.

| Pemeriksaan | Hasil | Bukti | Tingkat |
|---|---|---|---|
| Detail mekanisme gate keamanan internal | Tidak ditemukan di source publik | `docs/SECURITY_AND_INTEGRITY.md` hanya batas | Aman |
| **Nama komponen gate internal di dokumen publik** | **Ditemukan** | `CHANGELOG.md:97`, release notes baris 41 | **Pelanggaran §3.2** |
| **Nama folder sumber eksternal di dokumen publik** | **Ditemukan** | `CHANGELOG.md:96`, release notes baris 41, ZIP `CHANGELOG.md` | **Pelanggaran §3.3** |
| Klaim provenance netral di `LICENSE-DEPENDENCIES.md` §5 | Ada | "referensi internal proyek dan pembanding pihak ketiga" | Aman |
| Alamat binary dan frasa "reference analysis image" | Ada di source publik | `Evidence.kt:41–107`, `HondaFrameCodec.kt:10–11`, `HondaEcuProfiles.kt:234–254`, `audit/RECONSTRUCTION_STATUS.md` | Risiko sedang §3.3 |
| Nama aset security/integrity di audit | Ada | `audit/APK_COMPONENT_INVENTORY.md` §6, `docs/APK_ANALYSIS.md:128` | Risiko rendah–sedang §3.2 |
| Susunan/layer UI RevCore | Tidak ada | tidak ada paket `ui`/`security`; `find` kosong | Aman |
| Kredensial/private key/token | Tidak ada | `git grep` hanya menemukan nama variabel/penolakan | Aman |
| APK/AAB/AAR/JAR/SO/DEX terlacak | Tidak ada | `git ls-files` | Aman |
| Database/MAP nyata | Tidak ada | hanya `SAMPLE-*` dan 1 map sintetis | Aman |
| ZIP rilis memuat materi terlarang | Ya, `CHANGELOG.md` yang sama | unduh ZIP, baca `CHANGELOG.md` | **Pelanggaran** |
| Release notes menyebut `data/<nama eksternal>` dan gate internal | Ya | `gh release view v0.3.0` | **Pelanggaran** |
| APK diunggah apa adanya | Ya | hash aset = hash lokal | Aman |

Kesimpulan: klaim `FINAL_PUBLICATION_READINESS.md` §8 "tidak ada materi terlarang" dan
`README.md` "isi ZIP diperiksa" **tidak akurat** untuk dua baris `CHANGELOG.md` dan teks
release notes. Tidak ada detail mekanisme gate yang bocor, tetapi nama gate dan nama
folder sumber eksternal termasuk materi yang dilarang.

Perbaikan memerlukan keputusan Otoy karena menyentuh dokumen yang sudah terbit dan ZIP
rilis. APK tidak perlu diubah.

---

## 17. Status kesiapan GitHub Release

| Item | Status | Bukti |
|---|---|---|
| APK rilis terakhir | `RevCore_161126.apk`, 39.689.642 byte, SHA-256 `b2b6c5bd…7432` | aset rilis + file lokal identik |
| Repack/rebuild/re-sign APK | Tidak dilakukan | hash sama |
| Release `v0.3.0` | Publik sejak 17 Nov 2026 | `gh api` |
| Aset ZIP | `RevCore_Developer_Repository_v0.3.0.zip`, 276.656 byte | `gh api` |
| Unduhan | 91 APK, 101 ZIP (19 Nov 2026) | `gh api` |
| Catatan rilis | Memuat dua item terlarang (§16) | `gh release view` |
| ZIP | Memuat `CHANGELOG.md` bermasalah | unduh + grep |
| Kesiapan APK | Siap dipakai apa adanya | `VERIFIED` |
| Kesiapan dokumen rilis | **Belum bersih** | temuan §16 |

Release sudah ada dan APK sudah benar. Yang belum bersih adalah teks catatan rilis,
`CHANGELOG.md` di repository, dan `CHANGELOG.md` di dalam ZIP.

---

## 18. Rekomendasi pekerjaan berikutnya

| Prioritas | Masalah | Lokasi | Penyebab | Dampak | Solusi | Risiko | Cara uji |
|---|---|---|---|---|---|---|---|
| P0 | Nama gate internal dan nama folder sumber eksternal di dokumen terbit | `CHANGELOG.md:96–97`; release notes baris 41; ZIP | Teks changelog ditulis untuk pembaca internal | Melanggar §3.2/§3.3; dapat dianggap membocorkan struktur | Sanitasi dua baris; edit catatan rilis; terbitkan ZIP koreksi (APK tetap) | Perubahan dokumen terbit; butuh persetujuan Otoy | Grep ulang repo/ZIP/release; bandingkan hash APK tetap |
| P1 | TPS tidak 0% saat gas tertutup | `HondaProtocolEngine.kt:1631`; legacy `939/1068` | Formula tanpa offset/kalibrasi | Nilai TPS menyesatkan saat idle | Tambah offset/zero-calibration per profil setelah data raw tersedia | Kalibrasi salah dapat menggeser seluruh rentang | Log raw TPS idle + uji fixture beberapa nilai |
| P1 | Fallback PID tidak terjangkau & indeks byte | `HondaProtocolEngine.kt:1194–1205, 1310, 1577–1600` | Guard katalog + pembacaan `frame[2]` | 8 parameter owner tidak dapat direproduksi dari baseline publik | Tangkap RX nyata; perbaiki indeks dan tambah test | Perubahan menyentuh jalur komunikasi | Fixture respons 0x61; uji hardware |
| P1 | DTC E5/E6/subcode>15 | `HondaDtcDatabase.kt:117, 143`; engine `1030–1040` | Validasi longgar; state kosong menyatu | "Tidak ada DTC" palsu; kode bertabrakan | Validasi panjang ketat; state `PARSE_FAILED`; simpan subcode mentah | Dapat mengubah perilaku pembacaan yang sudah jalan | Test fixture cacat/berlebih + regresi 153 test |
| P1 | Adapter terputus | layer aplikasi; `HondaProtocolEngine.kt:362–386` | Belum diketahui | Sesi berhenti | Audit lifecycle + reconnect + log USB | Tidak dapat diuji tanpa perangkat | Log attach/detach + reproduksi |
| P2 | EOT tidak jelas | `TempSensorType.kt:10`; PID fallback | EOT hanya label/tipe | Salah tafsir parameter | Dokumentasikan kanal EOT aktual setelah konfirmasi | Klaim salah | Bandingkan log aplikasi dan label |
| P2 | Perbedaan skala 0x7A vs 0x21 | `docs/SENSOR_DECODING.md`; engine | Dua format berbeda | Pembaca mencampur satuan | Tambah peringatan eksplisit di KB | Rendah | Review dokumen |
| P2 | Tabel 17 tidak terdokumentasi | di luar repo | Data asli belum tersedia | Pengetahuan hilang | Minta referensi asli; jangan menebak byte | Implementasi salah | Validasi dengan capture |
| P2 | Alamat binary di source publik | `Evidence.kt`, `HondaFrameCodec.kt`, `HondaEcuProfiles.kt` | Provenance ditulis mentah | Risiko §3.3 | Ganti dengan deskripsi netral atau pindahkan ke catatan internal | Kehilangan traceability | Review teks |
| P3 | AAR tidak reproducible | build | Metadata arsip | Hash build ulang berbeda | Dokumentasikan; jangan jadikan gate | Rendah | Build dua kali, bandingkan |
| P3 | Contoh belum mencakup kalibrasi TPS | `samples/` | Fokus logika dasar | Pembaca tidak melihat solusi TPS | Tambah contoh sintetis setelah keputusan formula | Rendah | Jalankan contoh baru |

---

## 19. Pertanyaan yang membutuhkan keputusan Otoy

1. **Jalur Live Data:** build/aplikasi versi mana yang menampilkan 8 parameter? Apakah
   memakai profil Live Data milik aplikasi (bukan katalog `:core`)? Ini menentukan apakah
   LIVE-01/LIVE-02 relevan dengan bug TPS.
2. **Log TPS:** dapatkah Otoy menyertakan log Komunikasi saat idle (frame TX/RX dan nilai
   TPS mentah)? Tanpa raw/ADC, penyebab TPS tidak dapat dipastikan.
3. **EOT:** apakah EOT di layar berasal dari sensor ECT yang sama (model berpendingin
   udara) atau kanal terpisah? Model kendaraan apa yang dipakai saat pengujian?
4. **Tabel 17:** apakah referensi asli (payload/offset) tersedia untuk diaudit secara
   internal? Jika tidak, status tetap `UNKNOWN` dan tidak ada byte yang ditebak.
5. **Sanitasi rilis:** apakah Otoy menyetujui (a) edit catatan rilis `v0.3.0`,
   (b) koreksi `CHANGELOG.md`, dan (c) ZIP koreksi tanpa mengubah APK? Jika ya, perlu
   keputusan apakah tetap `v0.3.0` atau `v0.3.1`.
6. **Adapter:** chip adapter apa yang dipakai saat putus intermiten, dan apakah putus
   terjadi saat idle, saat polling, atau saat layar mati?
7. **Screen awake:** apakah masalah layar terjadi di semua perangkat atau model tertentu?
   Layer aplikasi tidak ada di repo publik sehingga perlu log/source terpisah.
8. **Publikasi KB:** apakah `KB_REVCORE_PUBLIK_DRAFT.md` boleh diterbitkan setelah
   review, atau perlu disimpan internal dulu?

---

## Lampiran — pernyataan status

- Tidak ada source produksi yang diubah selama audit.
- Tidak ada APK yang diubah, dibangun ulang, atau di-re-sign.
- Tidak ada unggahan baru ke GitHub selama audit ini.
- Semua angka test/build berasal dari eksekusi 19 November 2026 dan dapat direproduksi.
- Temuan yang belum terbukti tetap berlabel `UNKNOWN` atau `UNDER_INVESTIGATION`.
