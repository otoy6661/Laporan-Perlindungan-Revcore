# Investigasi Mode Mesin `0x5F`

Tanggal: 2026-11-20. Investigasi statis (source + bukti referensi). Tidak ada
ECU/kendaraan yang tersambung; tidak ada frame mentah dari perangkat.

Laporan utama: [LAPORAN_TEKNIS_REVCORE_2026-11-20.md](LAPORAN_TEKNIS_REVCORE_2026-11-20.md)

Tingkat bukti yang dipakai (sesuai `README.md` repository ini):
FAKTA / SOURCE VERIFIED, REKONSTRUKSI, DUGAAN, TIDAK DITEMUKAN, BELUM DIUJI.

---

## 1. Pertanyaan yang dijawab

1. Di mana nilai Mode Mesin ditampilkan?
2. Dari data mentah apa nilai itu berasal?
3. Bagaimana alur parsing/konversinya?
4. Bagaimana pemetaan ke nama mode?
5. Apakah `0x5F` valid, mentah, atau error parsing?
6. Apakah pemetaan tersedia per model/ECU?
7. Bukti uji sebelum/sesudah perbaikan?

---

## 2. Lokasi tampilan

| Layar | Elemen | File |
|---|---|---|
| Live Data | Kartu "MODE MESIN" / "ENGINE MODE" | `ui/screens/LiveDataScreen.kt:440-442` |
| Informasi Kendaraan | Baris "Mode Mesin" / "Engine Mode" | `ui/screens/EcuInfoScreen.kt:387` |

Subjudul kartu Live Data saat ini:

> `Byte 18 dat17; MODE 1-4 = altitude (rekonstruksi)`

(Label ini sendiri dicatat sebagai risiko dokumentasi/UI pada laporan utama B8.)

---

## 3. Data mentah dan alur

### 3.1 Profil Live Data

`core/comm/LiveDataProfile.kt` — `table17`:

- Request: `72 05 71 17 01`
- `payloadStart = 4`
- `minPayload = 16`
- Field Mode:

```kotlin
field(LiveSensor.MODE, 14, min = 0.0, max = 255.0)
```

`LiveDataProfile.kt:384` — offset 14 dari payload = **byte 18 frame**.
Komentar profil: "Byte 18 adalah mode, byte 19 VSS." **[FAKTA]**

### 3.2 Decoder

`core/comm/LiveActuatorDecoder.kt:43`:

```kotlin
fun altitudeMode(raw: Double?): Int? = raw?.toInt()?.takeIf { it in 1..4 }
```

Komentar di file: nilai `1..4` dipetakan ke altitude mode oleh decoder publik;
kode lain dibiarkan tanpa nama. **[FAKTA]**

### 3.3 Format tampilan

`ui/screens/LiveValueText.kt:40-42`:

```kotlin
LiveSensor.MODE -> LiveActuatorDecoder.altitudeMode(raw)?.let {
    if (isId) "MODE $it" else "MODE $it"
} ?: code()
```

dengan:

```kotlin
fun code(): String = "0x%02X".format(raw.toInt() and 0xFF)
```

**[FAKTA]** Nilai di luar `1..4` → fallback heksadesimal byte mentah.

### 3.4 Alur lengkap

```
ECU → respons dat17 (frame 72 .. 17 ..)
     → payload mulai byte 4
     → payload[14] = MD (byte 18 frame)
     → readings[LiveSensor.MODE] = MD (Double 0..255)
     → altitudeMode(): MD in 1..4 ? MODE MD : null
     → UI: "MODE n" atau "0xNN"
```

Tidak ada aritmetika (tidak ada pembagian, offset, atau faktor skala) pada jalur
Mode. Nilai `0x5F` yang tampil **adalah byte yang dikirim ECU**. **[FAKTA]**

---

## 4. `0x5F`: valid, mentah, atau error?

| Kemungkinan | Kesimpulan | Dasar |
|---|---|---|
| Error parsing | **Bukan** | Decoder mengembalikan `null` dengan sengaja; tidak ada exception/flag error |
| Nilai hasil konversi | **Bukan** | Jalur Mode tidak mengonversi; fallback menampilkan byte mentah |
| Nilai mentah | **Ya** | `code()` memformat `raw and 0xFF` |
| Kode mode yang sah | **TIDAK DIKETAHUI** | Tidak ada bukti protokol/ECU untuk `0x5F` |

`0x5F` = 95 desimal. Tidak termasuk `1..4`, sehingga UI menampilkannya sebagai
`0x5F`, bukan sebagai nama mode. **[FAKTA]**

### 4.1 Perbandingan dengan bukti referensi 3D Chart

Bukti referensi (`03_EVIDENCE/3DCHART_SOURCE_EVIDENCE.md`, blok `dat17`,
`Diag.cs:973`) menyatakan:

```
MD   = b[18]
MODE = 1 if MD in {0x80,0x67}; 2 if 0x66; 3 if 0x3C; 4 if 0x59; 0 if 0x79; else 0
fiz  = MD < 128 ? "ON" : "OFF"
```

[**SOURCE VERIFIED** pada referensi]

Implikasi untuk `0x5F`:

1. `0x5F` **tidak ada** dalam daftar kode yang dinamai. Referensi akan
   menampilkan MODE 0 untuk nilai ini — bukan nama mode tertentu.
2. Karena `0x5F < 0x80`, referensi akan menandai FIZ = "ON". Ini **tidak** boleh
   dipakai untuk menyimpulkan arti `0x5F`; FIZ adalah flag terpisah yang
   diturunkan dari ambang byte yang sama.
3. Tidak ada dasar untuk menyebut `0x5F` sebagai "mode tertentu" (misalnya mode
   servis, mode limp, atau mode altitude tertentu). **[TIDAK DITEMUKAN]**

### 4.2 Ketidaksesuaian pemetaan RevCore vs referensi

| Sumber | Nilai MD yang dipetakan | Hasil |
|---|---|---|
| RevCore | `1, 2, 3, 4` (desimal) | `MODE 1..4` |
| Referensi 3D Chart | `0x80/0x67`, `0x66`, `0x3C`, `0x59`, `0x79` | `MODE 1,1,2,3,4,0` |

Kedua pemetaan **tidak ekuivalen**. Pada kendaraan yang mengirim kode referensi
(mis. `0x66` = 102), RevCore akan menampilkan `0x66` (fallback), bukan
`MODE 2`. Sebaliknya, pada kendaraan yang mengirim `1..4` mentah, RevCore
menampilkan `MODE 1..4` sementara referensi akan menampilkan MODE 0.

Status: **temuan source-verified; belum diperbaiki** (perbaikan adalah perubahan
source, di luar scope pelaporan). **[FAKTA]**

Kemungkinan penjelasan (bukan kesimpulan): pemetaan RevCore dibangun dari
rekonstruksi awal "MODE 1-4" tanpa tabel kode MD referensi, sehingga angka 1..4
diperlakukan sebagai nilai langsung. **[DUGAAN]**

---

## 5. Pemetaan per model/ECU

- RevCore: satu fungsi global `altitudeMode()`; **tidak ada** tabel per-model
  atau per-ECU untuk Mode. **[FAKTA]**
- Tidak ditemukan kode yang mengubah arti Mode berdasarkan `connectedModel` /
  `ecuIdentity`. **[TIDAK DITEMUKAN]**
- Referensi juga memakai satu pemetaan dat17 global; tidak ada pembedaan model
  pada blok yang diperiksa. **[FAKTA terbatas pada referensi]**

---

## 6. Bukti pengujian

| Uji | Status | Bukti |
|---|---|---|
| Unit test pemetaan | **PASS** | `LiveActuatorDecoderTest.altitudeModeIsNamedOnlyForTheDocumentedCodes`: `1→1`, `4→4`, `0→null`, `5→null`, `null→null`; termasuk dalam 330 test yang lulus |
| Uji UI (tampilan `MODE n` / `0xNN`) | BELUM DIUJI perangkat | tidak ada perangkat |
| Uji ECU dengan dat17 nyata | BELUM DIUJI | tidak ada ECU |
| Tangkapan `0x5F` dari kendaraan pemilik | TIDAK ADA | tidak ada log/frame |
| Uji setelah perbaikan | Tidak berlaku | belum ada perbaikan |

Artefak: hasil XML unit test tersimpan di salinan kerja
`RevCore_work/app/build/test-results/testDebugUnitTest/`
(timestamp `2026-11-19T23:45Z` = 2026-11-20 06:45 WIB).

---

## 7. Kesimpulan investigasi `0x5F`

1. `0x5F` adalah **byte mentah** `MD` dat17, ditampilkan karena tidak masuk
   pemetaan `1..4`. Bukan error parsing. **[FAKTA]**
2. Arti `0x5F` pada ECU pemilik **tidak diketahui**; tidak ada bukti protokol
   atau validasi kendaraan. Tidak ada arti yang dikarang dalam laporan ini.
3. Pemetaan Mode RevCore **berbeda** dari pemetaan referensi dan berisiko
   menampilkan nilai mentah pada kendaraan yang memakai kode referensi.
   **[FAKTA]**
4. Diperlukan: (a) ekspor log TX/RX + frame dat17 saat `0x5F` muncul,
   (b) catatan kondisi (KOEO/KOER, model/ECU), (c) keputusan pemilik mengenai
   pemetaan yang diinginkan.
