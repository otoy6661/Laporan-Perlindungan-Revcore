# BE-10 — REKOMENDASI INTEGRASI REVCORE

**Basis:** temuan BE-10 yang berstatus `STATICALLY_ANALYZED` atau `SAMPLE_TEST_PASSED`.
**Larangan:** rekomendasi ini tidak mengubah proyek utama RevCore; tidak ada kode yang dimasukkan ke RevCore dalam work order ini.

---

## 1. Prinsip integrasi

1. **Offline-first.** Semua yang bisa diuji tanpa ECU harus masuk lebih dulu.
2. **Read-only secara default.** Jalur tulis tidak diaktifkan tanpa bench dan persetujuan pemilik.
3. **Bukti sebelum fitur.** Status `STATICALLY_ANALYZED` bukan `VERIFIED`; jangan memasarkan sebagai "sudah terbukti di ECU".
4. **ADX tetap opaque.** Jangan integrasikan pembaca isi ADX.
5. **Audit hash.** Setiap operasi file harus mencatat SHA-256 sebelum/sesudah.

---

## 2. Paket integrasi dan prioritas

### P0 — Dapat diintegrasikan sekarang (offline, risiko rendah)

| Kapabilitas | Sumber bukti | Status | Catatan |
|---|---|---|---|
| Pembaca tabel BIN (LE/BE) | 5 BIN nyata | `SAMPLE_TEST_PASSED` | Termasuk `0x3A804`, `0x3A258`, `0x3911C`, `0x396C8` |
| Registry 152 model + offset | `3D_MAP_DATABASE.csv` | `STATICALLY_ANALYZED` | Offset file, bukan alamat ECU |
| Export/import CSV grafik | `EX-01` | `SAMPLE_TEST_PASSED` | 35×29 |
| Bandingkan BIN | `CP-01` | `SAMPLE_TEST_PASSED` | Ukuran, jumlah beda, offset pertama/terakhir |
| Inspeksi kontainer ADX | ADX-01..03 | `SAMPLE_TEST_PASSED` | Hanya metadata/tag/hash; bukan isi |
| Evaluator formula sederhana | `FX-01` | `SAMPLE_TEST_PASSED` | Aritmetika dasar + variabel |

Rekomendasi: jadikan ini modul library RevCore dengan antarmuka stabil dan unit test yang sama.

### P1 — Siap setelah review kode (masih offline)

| Kapabilitas | Sumber bukti | Status | Risiko |
|---|---|---|---|
| Decoder live data 45 kanal | `Diag.cs`/`Form1.cs` | `STATICALLY_ANALYZED` | Skala belum diverifikasi kendaraan |
| Checksum Keihin | `Form1.cs:1721` + CK-02 | `STATICALLY_ANALYZED` | Belum pada firmware asli |
| Checksum Shindengen | `Form1.cs:1130` + CK-03 | `STATICALLY_ANALYZED` | Sama |
| Seed/key Shindengen | `Form1.cs:2023` + SK-01 | `STATICALLY_ANALYZED` | Hanya aritmetika |
| Codec frame Honda | `FR-01`, `CK-01` | `SAMPLE_TEST_PASSED` | Belum I/O nyata |
| Database 169 ECU ID | `DB-02` | `STATICALLY_ANALYZED` | Beberapa offset `auto` |

Rekomendasi: masukkan sebagai modul protokol **tanpa** transport; uji dengan golden vector dan replay log, bukan ECU.

### P2 — Memerlukan hardware dan izin

| Kapabilitas | Status | Prasyarat |
|---|---|---|
| Transport FTDI D2XX (10.400/62.500, wake bit-bang) | `HARDWARE_PENDING` | Kabel FTDI, bench, izin pemilik |
| Identifikasi ECU runtime | `HARDWARE_PENDING` | ECU + harness |
| Sinkronisasi live data | `HARDWARE_PENDING` | ECU berjalan, log pembanding |
| Timing wake-up/timeout | `HARDWARE_PENDING` | Pengukuran osiloskop/logika |

Rekomendasi: buat antarmuka `ITransport` dan `IClock` agar transport bisa diganti dan diuji dengan loopback. Jangan mengikat RevCore ke `FTD2XX_NET` secara langsung.

### P3 — Tidak direkomendasikan sekarang

| Kapabilitas | Alasan |
|---|---|
| Tulis flash / erase | Risiko bricking; butuh prosedur rollback, catu daya stabil, bench |
| Recovery | Varian belum dipetakan; hanya terbaca dari source |
| Smart Key EEPROM tulis | Risiko keamanan kendaraan dan etika |
| Bypass lisensi | Dilarang; bukan tujuan riset |
| Dekripsi ADX/XDF terkunci | `BLOCKED_BY_ACCESS_REQUIREMENT` |

---

## 3. Arsitektur yang disarankan

```
RevCore.Offline
  ├── BinImage          (read, hash, compare)
  ├── MapRegistry       (152 model, offset, endianness)
  ├── TableCodec        (read/write on copy, CSV)
  ├── XdfReader         (unlocked only)
  ├── AdxInspector      (metadata only)
  └── Formula

RevCore.Protocol
  ├── HondaFrame        (encode/decode/checksum)
  ├── LiveDataDecoder   (45 channels)
  ├── Checksums         (Keihin, Shindengen, KZR)
  └── SecurityMath      (seed/key arithmetic, test-only)

RevCore.Transport (belum diaktifkan)
  ├── ITransport
  ├── LoopbackTransport
  └── FtdiTransport      (HARDWARE_PENDING)
```

Aturan:

- `TableCodec.Write` hanya menerima **salinan** dan mengembalikan hash baru; tidak menulis file sumber.
- `LiveDataDecoder` menerima span byte + tipe perintah; tidak menyentuh I/O.
- `Checksums` adalah fungsi murni; tidak membaca file.
- `FtdiTransport` berada di paket terpisah dan tidak direferensikan oleh UI offline.

---

## 4. Guardrail yang wajib

1. **Model gating:** sebelum menampilkan tabel, cocokkan ID ECU/BIN dengan registry; jangan menebak offset.
2. **Checksum verify:** setelah setiap patch, hitung ulang dan bandingkan; tolak jika tidak nol.
3. **Hash audit:** catat SHA-256 input/output di log.
4. **Read-only default:** flag `AllowWrite` default `false`, hanya bisa diaktifkan eksplisit.
5. **Tidak ada auto-detect yang menulis:** identifikasi hanya membaca.
6. **Tidak ada kunci hardcoded** di RevCore; jangan menyalin konstanta lisensi dari source 3D.

---

## 5. Yang tidak boleh diintegrasikan

- Kunci/IV AES, isi `lic.kye`, atau mekanisme lisensi 3D.
- Logika bypass apa pun.
- Smart Key challenge/EEPROM tulis.
- Pembaca ADX yang mengklaim mendekripsi.
- Asumsi bahwa checksum sudah terbukti pada firmware; statusnya masih `STATICALLY_ANALYZED`.

---

## 6. Kriteria "siap produksi"

Sebuah modul baru boleh dianggap siap jika:

1. Memiliki unit test dengan input/hasil yang dapat direproduksi.
2. Lulus golden vector dari source.
3. Tidak menulis file sumber.
4. Memiliki batas error yang jelas (frame invalid, checksum salah, ukuran tak cocok).
5. Untuk fitur hardware: lulus uji bench dengan log dan rollback.

---

## 7. Evidensi

- `BE10_PROTOTYPE_RESULTS.md`
- `BE10_ECU_PROTOCOL_FINDINGS.md`
- `BE10_3D_CHART_SOURCE_ANALYSIS.md`
- `REPORTS\BE10_SENSOR_LIVE_DATA_CATALOG.csv`
