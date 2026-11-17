# 13 — MATRIKS KOMPATIBILITAS DATASET

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Dataset:** `C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX`
**Status:** SELESAI — 930 file dihitung dan diklasifikasikan. Tidak ada file dataset yang diubah.

---

## 1. Ringkasan dataset

| Ekstensi | Jumlah | Total byte |
|---|---:|---:|
| `.bin` | 700 | — |
| `.xdf` | 174 | — |
| `.log` | 32 | — |
| `.zip` | 10 | — |
| `.rar` | 5 | — |
| `.txt` | 5 | — |
| `.adx` | 3 | — |
| `.7z` | 1 | — |
| **Total** | **930** | **159.940.598** |

Sumber: `00_SOURCE_INVENTORY/DATASET_INVENTORY.csv` (930 baris + header).

---

## 2. Klasifikasi keterbacaan

| Kategori | Definisi | Jumlah | Persentase |
|---|---|---:|---:|
| **DIRECTLY_READABLE** | Teks/XML/biner dengan struktur terbaca tanpa kunci | 13 XDF + 700 BIN (byte) | — |
| **READABLE_WITH_LIMITATIONS** | Dapat dibuka aplikasi, tetapi isi tidak dapat diaudit | 161 XDF + 3 ADX | — |
| **NOT_DIRECTLY_READABLE** | Container terenkripsi tanpa kunci | 161 XDF + 3 ADX (dari sudut pandang analis) | — |
| **SENSITIVE_OR_RESTRICTED** | Tidak ada kredensial/secret; tidak ada file sensitif | 0 | 0% |

Catatan: XDF terenkripsi termasuk READABLE_WITH_LIMITATIONS untuk TunerPro (dapat dimuat) dan NOT_DIRECTLY_READABLE untuk analis (isi tidak terbaca). Dua klasifikasi ini bukan kontradiksi; keduanya menyatakan hal berbeda.

---

## 3. XDF

| Kategori | Jumlah |
|---|---:|
| Total | 174 |
| Plaintext XML | 13 |
| Terenkripsi | 161 |
| Dengan checksum | 2 (keduanya plaintext) |
| Tanpa checksum | 11 plaintext |

13 plaintext = 12 definisi unik + 1 salinan (`XDF SPECIAL RACE K2VG-N32` ada di dua folder).

### 3.1 Cakupan tabel XDF plaintext

| Definisi | Tabel | Checksum |
|---|---:|---:|
| ADV 150 K0WF-T01 | 44 | 0 |
| BEAT K1AA-N03 | 20 | 0 |
| BEAT POP K61-601 | 13 | 0 |
| CBR150 K45A N01 | 24 | 0 |
| CBR500R MGZ-A03 | 19 | 0 |
| CBR500R MGZ-C02 | 19 | 0 |
| CBR1000RR MGP-A01 | 39 | 1 |
| SUPRA K41-NC1 | 14 | 1 |
| Supra 125 KVL-N21 | 19 | 0 |
| VARIO 150 K59A-A11 | 20 | 0 |
| K2VG-N32 (2 salinan) | 20 | 0 |
| VERZA K18-902 | 16 | 0 |

---

## 4. ADX

| File | Ukuran | Plaintext | Pair |
|---|---:|---|---|
| `ADX KEIHIN BE.adx` | 40.199 | Tidak | NO_BIN |
| `ADX KEIHIN BE.adx` (salinan) | 40.199 | Tidak | NO_BIN |
| `ADX SHINDENGEN BE.adx` | 23.780 | Tidak | NO_BIN |

Ketiga ADX tidak memiliki BIN pasangan di direktori yang sama. ADX adalah definisi datastream, bukan pasangan BIN; `NO_BIN` adalah status yang benar, bukan cacat dataset.

---

## 5. Pasangan BIN ↔ XDF

| Status | Jumlah | Arti |
|---|---:|---|
| `SAME_DIR` | 174 | Ada BIN di direktori yang sama dengan XDF |
| `NO_BIN` | 3 | Tidak ada BIN; semuanya ADX |

**Penting:** `SAME_DIR` hanya menyatakan kedekatan lokasi, bukan kompatibilitas. Tidak ada verifikasi bahwa BIN di direktori itu cocok secara kalibrasi dengan XDF; TunerPro juga tidak memvalidasi hal ini saat load.

Distribusi direktori terbesar: ADV K0WA (4), VARIO K59J-A71 (4), K2VG-N32 (3+3), BEAT K81A-N12 (3), BEAT K81H-N62 (3).

---

## 6. Matriks lengkap

File: `13_PROTOTYPES/OUT/DATASET_COMPATIBILITY_MATRIX.csv` (177 baris data).

Kolom:

| Kolom | Arti |
|---|---|
| `kind` | XDF/ADX |
| `file` | Nama file |
| `bytes` | Ukuran |
| `plaintext` | True/False |
| `magic` | Magic byte terbaca |
| `tables` | Jumlah `XDFTABLE` (plaintext saja) |
| `constants` | Jumlah `XDFCONSTANT` |
| `checksums` | Jumlah `XDFCHECKSUM` |
| `nearest_bin` | BIN terdekat di direktori |
| `pair_state` | SAME_DIR / NO_BIN |
| `directory` | Path relatif |

---

## 7. Kompatibilitas dengan TunerPro

| Objek | Status | Bukti |
|---|---|---|
| BIN 49–1.048 KB | Dapat dibuka | Runtime |
| XDF plaintext | Dapat dibuka; tabel dirender | Runtime + verifikasi 5.338 sel |
| XDF terenkripsi | Dapat dibuka; tree terbatas | Runtime K0WA |
| ADX terenkripsi | Dapat dibuka; view terbentuk | Runtime keihin |
| XDF dengan plug-in checksum hilang | Gagal Save | CBR |
| ADX tanpa BIN | Tetap dapat dimuat | Runtime |

**TunerPro tidak memerlukan BIN untuk membuka ADX**, dan tidak memerlukan ADX untuk membuka BIN/XDF.

---

## 8. Kompatibilitas dengan RevCore

| Objek | Status | Dasar |
|---|---|---|
| BIN mentah + XDF | **TIDAK DIDUKUNG** | `MapParser` mem-parse image FlashPro, bukan XDF; tidak ada parser XDF di RevCore |
| XDF plaintext | **TIDAK DIDUKUNG** | Tidak ada parser XDF |
| XDF terenkripsi | **TIDAK DIDUKUNG** | Tidak ada dekripsi |
| ADX | **TIDAK DIDUKUNG** | Live data RevCore hardcoded |
| BIN mentah tanpa XDF | **INSUFFICIENT EVIDENCE** | `RomBinary` ada, tetapi model/offset ECU Honda spesifik belum lengkap |
| FlashPro image | DIDUKUNG | `MapParser` |

**Kesimpulan:** dataset ini adalah dataset TunerPro, bukan dataset RevCore. RevCore memerlukan parser XDF dan/atau konversi ke model internal sebelum dapat memakai 174 XDF dan 700 BIN secara aman.

---

## 9. Klasifikasi per area (untuk publikasi)

| Area | Klasifikasi | Alasan |
|---|---|---|
| APP_INVENTORY.csv | DIRECTLY_READABLE | CSV |
| DATASET_INVENTORY.csv | DIRECTLY_READABLE | CSV (hash + path) |
| 13 XDF plaintext | DIRECTLY_READABLE | XML |
| 161 XDF terenkripsi | NOT_DIRECTLY_READABLE | Ciphertext |
| 3 ADX | NOT_DIRECTLY_READABLE | Ciphertext |
| 700 BIN | READABLE_WITH_LIMITATIONS | Byte dapat dibaca; makna butuh XDF |
| PE JSON/STRINGS | DIRECTLY_READABLE | Teks |
| Screenshot | DIRECTLY_READABLE (visual) | PNG |
| File `.log`, `.zip`, `.rar`, `.7z`, `.txt` | Tidak dianalisis | Di luar cakupan BE-11 |

---

## 10. Batas

- `nearest_bin` hanya berbasis direktori, bukan pencocokan checksum/ID.
- Tidak ada verifikasi bahwa pasangan BIN/XDF benar-benar berasal dari ECU yang sama.
- 161 XDF dan 3 ADX tidak dapat diperiksa isinya.
- File log/arsip tidak dibuka; jumlahnya hanya dihitung.
- Persentase “kompatibel” tidak diberikan karena tidak ada uji coba pada ECU.

---

## 11. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Jumlah & ukuran file | TINGGI (hash + enumerasi) |
| Split plaintext/encrypted | TINGGI (magic) |
| Pairing direktori | TINGGI (path) |
| Kompatibilitas fungsional BIN↔XDF | RENDAH (tidak diuji) |
| Dukungan RevCore | TINGGI untuk “tidak ada parser XDF/ADX” |
