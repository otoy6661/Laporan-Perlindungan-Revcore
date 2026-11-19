# KNOWLEDGE BASE REVCORE — DRAFT PUBLIK

Status: **DRAFT untuk ditinjau Otoy.** Dokumen ini disusun agar dapat dipublikasikan
tanpa materi terlarang: tanpa identitas sumber eksternal, tanpa detail komponen keamanan
internal, tanpa susunan layer UI, dan tanpa kredensial.

Tujuan: menjadi jembatan belajar K-Line Honda PGM-FI, dari adapter sampai nilai sensor,
dengan batas bukti yang jujur.

## 1. Peta pengetahuan

```text
Adapter USB
  → Transport serial (8N1)
  → Wake-up K-Line
  → Identifikasi ECU
  → Transaksi TX/RX
  → Validasi frame
  → Ekstraksi payload
  → Pemetaan sensor / DTC
  → Parser
  → Konversi
  → Validasi
  → Output
```

Setiap tahap dijelaskan dengan file/class publik di repository developer. Layer aplikasi
dan komponen keamanan internal tidak dibahas.

## 2. K-Line dan adapter

### 2.1 Frame

```text
[header][declared length][service][params...][checksum]
```

- `declared length` mencakup header sampai checksum; nilai ini harus sama dengan ukuran
  frame. Tidak ada toleransi "ukuran − 1".
- Checksum adalah komplemen dua dari jumlah byte sebelum checksum:
  `(256 - (sum & 0xFF)) & 0xFF`.
- Ukuran minimum 4 byte; batas body 254 byte (`0xFE`).
- Service `0x7F` adalah respons negatif.
- Header yang terlihat di kode: `0x72`, `0x02`, `0x7E`, `0x7C`, `0x7D`, `0x7B`, `0xFE`.
  Header yang diterima ditentukan oleh konfigurasi pemanggil; jangan menganggap semua
  header berlaku untuk semua ECU.

Contoh frame valid (sintetis):

```text
72 05 74 01 14
72 05 71 20 F8
72 05 00 00 89
```

### 2.2 Baud dan timing

| Parameter | Nilai | Catatan |
|---|---|---|
| Baud identifikasi utama | 10400 | 8N1 |
| Baud fallback | 9600 | Dicoba bila 10400 tidak menghasilkan frame |
| Timeout transaksi default | 700 ms | Dapat diubah pemanggil |
| Retry default | 1 | Single-flight mencegah transaksi bersamaan |
| Wake LOW / HIGH | 70 ms / 130 ms | Waktu host, bukan pengukuran bus |
| Buffer RX maksimum | 1024 byte | Buffer dipertahankan 512 byte |

Angka ini adalah perilaku implementasi host. ECU dapat memiliki toleransi timing berbeda.

### 2.3 Alur TX/RX

1. Frame ditulis sebagai satu blok.
2. Engine membaca sampai timeout.
3. Echo lokal dibuang bila berada di awal RX setelah padding `0x00`.
4. Frame dipindai: header dikenal, length cocok, checksum valid.
5. Respons negatif tidak dianggap data.
6. Bila tidak ada frame valid, hasilnya `null`/`Failure`, bukan nilai palsu.

## 3. Wake-up dan inisialisasi

| Metode | Urutan | Status |
|---|---|---|
| Wake pulse baseline | Purge, BREAK LOW 70 ms, BREAK HIGH 130 ms, purge | `RECONSTRUCTED` |
| Fallback baud | Identifikasi pada 9600 bila 10400 gagal | `RECONSTRUCTED` |
| Wake ulang | Pulsa diulang dengan force BREAK sebelum query terakhir | `RECONSTRUCTED` |
| Query `0x1A` | Hanya setelah seluruh baseline gagal | `REFERENCE` |

Tidak ada bukti bahwa satu metode berlaku untuk semua ECU Honda. Wake pulse yang
"terkirim" hanya membuktikan waktu host; ia tidak membuktikan ECU bangun.

## 4. Identifikasi ECU

Urutan baseline:

| Urutan | Request | Tujuan |
|---:|---|---|
| 0 | `FE 04 72 8C` | Tester present |
| 1 | `72 05 00 F0 99` | Query ID 00/F0 |
| 2 | `72 07 72 00 00 05 10` | Query ID 72/00 |
| 3 | `72 05 71 00 18` | Query ID 71/00 |
| Fallback | Service `0x1A` | ID alternatif setelah baseline gagal |

Contoh layout `72/00` (sintetis):

```text
request : 72 07 72 00 00 05 10
response: 72 0B 72 00 00 01 03 7A 0F 02 <checksum>
payload : 00 00 01 03 7A 0F 02
          selector   ECM ID 5 byte
```

Aturan:

- ID lengkap: 5 byte (10 hex) atau 6 byte (12 hex).
- Tidak ada pemotongan sewenang-wenang.
- ID tidak lengkap disimpan sebagai kandidat, bukan model.
- Model hanya diterbitkan untuk pencocokan `EXACT` tunggal; lebih dari satu kandidat =
  `AMBIGUOUS`.
- ECU yang menjawab tetapi ID tidak terbaca tetap ditandai belum terverifikasi.

## 5. Live Data

### 5.1 Kebijakan katalog

Repository developer **tidak** membawa katalog tabel Live Data proprietary. Tanpa profil
yang disediakan pemanggil:

- `queryLiveData()` mengembalikan `null`;
- state menjadi `UNSUPPORTED_PROFILE`;
- tidak ada frame yang dikirim.

Ini adalah keputusan hak penggunaan dan bukti, bukan kegagalan komunikasi.

### 5.2 Delapan parameter yang dikonfirmasi pemilik

Konfirmasi Otoy (19 November 2026): RPM, TPS, EOT, tegangan baterai, ignition advance,
injector pulse, vehicle speed, dan O2 pernah tampil. TPS memiliki laporan bug: persentase
saat gas tertutup tidak 0%.

Status pengetahuan publik:

| Parameter | Ditampilkan (owner) | Jalur publik yang terdokumentasi | Catatan |
|---|---|---|---|
| RPM | Ya | contoh 0x7A / PID 0x21 | 2 byte big-endian |
| TPS | Ya | contoh 0x7A / PID 0x21 | bug gas tertutup; formula belum universal |
| EOT | Ya | tidak ada PID EOT khusus | hanya tipe sensor/label; jalur aktual belum diketahui |
| Baterai | Ya | contoh 0x7A / PID 0x21 | skala berbeda antarjalur |
| Ignition advance | Ya | PID 0x21 | `raw − 64` |
| Injector pulse | Ya | contoh 0x7A / PID 0x21 | satuan berbeda antarjalur |
| Vehicle speed | Ya | contoh 0x7A / PID 0x21 | 1 byte |
| O2 | Ya | PID 0x21 | hanya saat mesin berputar |

Jalur yang menampilkan parameter tersebut di APK berada di luar repository publik. Jangan
menyimpulkan bahwa katalog kosong berarti Live Data gagal.

### 5.3 Formula contoh 0x7A (sintetis)

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

### 5.4 Formula PID 0x21 (fallback)

| PID | Sensor | Formula | Catatan |
|---|---|---|---|
| `0x01` | RPM | `raw`; >15000 → `raw × 50/6` | valid 0..15000 |
| `0x02` | TPS | `raw × 100/255` | tanpa offset; tidak universal |
| `0x03` | MAP | `raw` | kPa |
| `0x04` | IAT | `raw − 40` | °C |
| `0x05` | ECT | `raw − 40` | °C |
| `0x06` | Battery | `raw × 0.0625` | V |
| `0x07` | Injector | `raw × 0.001` | ms |
| `0x08` | Ignition | `raw − 64` | derajat |
| `0x09` | Speed | `raw` | km/h |
| `0x0C` | O2 | `raw × 4.882/1000` | V; mesin berputar |

Peringatan: fallback PID 0x21 bukan jalur default dan belum diuji dengan tangkapan
perangkat keras. Jangan mencampur skala 0x7A dan 0x21.

### 5.5 Mengapa TPS tidak 0% saat gas tertutup

Kandidat penyebab yang harus dibedakan:

1. ADC gas tertutup tidak 0, sedangkan formula menganggap 0 = 0%.
2. Tidak ada offset/kalibrasi nol per kendaraan.
3. Karakteristik ECU berbeda.
4. Byte yang dibaca bergeser (jika jalur fallback dipakai).

Langkah diagnosis yang benar: catat frame TX/RX, ambil byte TPS mentah saat gas tertutup,
bandingkan dengan tegangan sensor, lalu tentukan offset. Jangan mengubah formula menjadi
"lebih kecil" tanpa data.

## 6. DTC

### 6.1 Query

| Operasi | Urutan |
|---|---|
| Baca | `72 05 74 01 14` → `72 05 71 20 F8` → `72 05 00 00 89` |
| Clear | `72 05 60 01 28` → `72 05 74 02 13` → `72 04 04 86` |

Engine berhenti pada query pertama yang menghasilkan frame valid dan payload yang dapat
diparse. Respons negatif melanjutkan ke query berikutnya.

### 6.2 Payload

Count-prefixed: `[count][code][sub]...`. Contoh:

```text
frame   : 72 0A 74 01 02 01 01 07 01 03
payload : 02 01 01 07 01
          count  P0107 P0117
```

Pair stream dipakai bila count-prefixed tidak valid; byte `0x00`, `0xFF`, dan header
protokol dilewati. Echo service dibuang lebih dulu.

### 6.3 Empat keadaan yang harus dibedakan

| Keadaan | Arti |
|---|---|
| Respons valid, ada kode | `OK_CODES` |
| Respons valid, tidak ada kode | `OK_EMPTY` |
| Tidak ada respons | `NO_RESPONSE` |
| Respons ada, paket tidak dapat diurai | **harus terpisah**; jangan disamakan dengan `OK_EMPTY` |

Clear tidak dianggap berhasil sebelum pembacaan ulang tidak menemukan DTC. Clear tidak
menjamin lampu MIL padam.

## 7. Tabel 17 — pengetahuan yang belum terverifikasi

Request yang pernah dicatat: `72 05 71 17 01`.

Sensor yang tercantum dalam catatan: SPEED, RPM, TPS1, TPS2, ECT1, ECT2, IAT1, IAT2,
MAP1, MAP2, BAT, INJ, IGT, DTC1–DTC4.

Yang **belum** diketahui:

- posisi byte setiap sensor;
- panjang data dan endian;
- formula dan satuan;
- urutan DTC;
- ECU/kendaraan yang menjawab.

Repository tidak memuat payload atau fixture Tabel 17. Tidak ada posisi byte yang ditebak
di dokumen ini. Status: `UNKNOWN`.

## 8. Decoder

```text
Raw Byte → Offset → Data Type → Endian → Formula → Validation → Converted Value
```

- Offset dihitung dari awal payload.
- Panjang 1 atau 2 byte; 2 byte big-endian.
- `0xFF` bukan angka; alternate offset hanya dipakai bila byte utama `0xFF`.
- `scale` dan `bias` diterapkan setelah raw.
- Validasi memakai rentang nilai akhir.
- Sensor yang hanya bermakna saat mesin berputar diberi status khusus (mis. O2 saat KOEO).

Contoh:

```text
raw 0x80, length 1, scale 100/255, bias 0
→ 128 × 100/255 = 50,196%
```

## 9. Failure & troubleshooting (ringkas)

| Kasus | Gejala | Pemeriksaan pertama | Jangan dilakukan |
|---|---|---|---|
| ECU tidak merespons | Tidak ada frame valid | Kontak, pin K-Line, ground, adapter, baud | Menyimpulkan kontak OFF |
| Live Data kosong | `UNSUPPORTED_PROFILE` | Apakah pemanggil menyediakan profil? | Mengirim request proprietary |
| TPS tidak nol | Persentase > 0 saat idle | Raw TPS, tegangan, offset | Mengubah formula tanpa data |
| Adapter putus | Sesi berhenti | Log USB attach/detach, kabel, daya | Menyembunyikan error sebagai "selesai" |
| DTC kosong | `OK_EMPTY` | Apakah paket benar-benar kosong? | Menganggap tidak ada kode tanpa parse valid |
| APK tidak ada | `assembleDebug` di root | Root adalah library; build `samples/01-hello-android` | Menganggap build gagal |

## 10. Batas bukti

| Label | Arti |
|---|---|
| `SYNTHETIC` | Diuji dengan data buatan |
| `RECONSTRUCTED` | Disusun dari analisis, belum diuji hardware |
| `REFERENCE` | Referensi perilaku, bukan jalur utama |
| `UNVERIFIED` | Belum ada bukti yang cukup |
| `VERIFIED` | Diuji ulang dan hasilnya diperiksa |

Repository ini tidak mengklaim kompatibilitas kendaraan. Build berhasil membuktikan
kompilasi dan pengemasan, bukan perilaku ECU.

## 11. Cara berkontribusi

1. Jangan menambahkan data kendaraan nyata, firmware, MAP, atau kredensial.
2. Tandai setiap frame dengan status bukti.
3. Jangan mengubah `UNKNOWN` menjadi `FAILED` tanpa bukti.
4. Jangan mengubah `OWNER_REPORTED` menjadi `VERIFIED` tanpa pengujian yang sesuai.
5. Sertakan cara reproduksi dan hasil yang diharapkan pada setiap contoh.
6. Jangan menyalin source produksi menjadi contoh; tulis contoh terpisah.
