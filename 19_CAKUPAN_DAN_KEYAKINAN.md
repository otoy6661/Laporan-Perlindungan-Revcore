# 19 — CAKUPAN & KEYAKINAN

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Status:** SELESAI — cakupan per area diukur terhadap pertanyaan yang diajukan, bukan terhadap seluruh kemungkinan.

---

## 1. Cara membaca angka

- **Cakupan** = seberapa banyak pertanyaan area yang berhasil dijawab dengan bukti.
- **Keyakinan** = seberapa kuat bukti untuk jawaban yang diberikan.
- Angka **bukan** ukuran kualitas software atau jumlah fitur.
- Tidak ada area yang diberi 100%; selalu ada pertanyaan yang tidak diuji.

---

## 2. Cakupan per area

| No | Area | Cakupan | Keyakinan | Yang terjawab | Yang belum |
|---:|---|---:|---|---|---|
| 1 | Identitas & provenance aplikasi | 98% | Tinggi | Versi, arsitektur, build, hash, signature | Asal build/rilis resmi |
| 2 | Inventaris komponen & dependensi | 95% | Tinggi | 24 file, import/export, runtime modules | Isi `TunerProPu.dat` |
| 3 | Analisis statis | 85% | Tinggi–Sedang | PE, string, resource, menu ID | Dekompilasi fungsi |
| 4 | Analisis runtime UI | 90% | Tinggi | Startup, menu, preferences, dialog utama | Help/Registration, import format lain |
| 5 | Autopsi BIN | 75% | Tinggi (sampel) | Format, offset, endian, checksum | Seluruh 700 BIN, arti fisik tabel |
| 6 | Autopsi XDF plaintext | 90% | Tinggi | Skema, alamat, stride, MATH, checksum | Semantik semua field |
| 7 | Autopsi XDF terenkripsi | 5% | Rendah | Header container | Seluruh isi |
| 8 | Autopsi ADX | 45% | Sedang | Container, skema, UI, alur | Isi definisi, frame nyata |
| 9 | Live Monitor | 60% | Sedang–Tinggi | Widget, alur, perilaku tanpa data | Data nyata, timing, log |
| 10 | Protokol komunikasi | 55% | Sedang | Model paket, timeout, checksum flag | Frame Honda, algoritma checksum perintah |
| 11 | Flashing & recovery | 85% | Tinggi (absen) | Tidak ada jalur ECU; jalur chip/emulator | Perilaku perangkat nyata |
| 12 | Plugin/driver/hardware | 85% | Tinggi | 3 ekosistem, lokasi, perangkat | Plugin pihak ketiga mendalam |
| 13 | Dataset | 90% (hitungan) / 20% (fungsional) | Tinggi / Rendah | 930 file, split, pairing | Kompatibilitas nyata |
| 14 | Perbandingan RevCore | 70% | Sedang | Checksum, bias, arsitektur | Frame Honda, uji hardware |
| 15 | Prototipe & tes | 80% | Tinggi | 53 cek, reproduksi tabel | ADX parser, dekripsi |
| 16 | Log eksperimen | 95% | Tinggi | Semua langkah utama | Beberapa output console |
| 17 | Indeks bukti | 95% | Tinggi | Pemetaan klaim→artefak | — |
| 18 | Keterbatasan & risiko | 95% | Tinggi | Daftar terbuka | Risiko hardware nyata |
| 19 | Cakupan & keyakinan | 95% | Tinggi | Laporan ini | — |

**Rata-rata cakupan (tidak berbobot): ±72%.** Angka ini bukan “72% dari seluruh isi TunerPro”; ia mengukur jawaban atas pertanyaan BE-11.

---

## 3. Area dengan keyakinan terendah

| Area | Alasan | Dampak |
|---|---|---|
| XDF terenkripsi | Tidak ada kunci | 161 definisi tidak dapat diaudit |
| ADX | Tidak ada plaintext | Protokol Honda tidak dapat dipastikan |
| Live Monitor dengan data | Tidak ada hardware | Tidak ada bukti nilai/timing |
| Protokol | Tidak ada capture | Klaim hanya konseptual |
| Kompatibilitas dataset | Tidak ada uji ECU | `SAME_DIR` bukan bukti cocok |

---

## 4. Yang akan menaikkan keyakinan

1. **Perangkat keras + ECU di meja uji** — capture serial untuk membandingkan ADX/RevCore.
2. **ADX plaintext** (dari pembuat definisi) — memungkinkan verifikasi frame.
3. **Kunci dekripsi resmi** — memungkinkan audit 161 XDF.
4. **Dekompilasi terfokus** pada `MMSerial`, `MMAutoProm`, `ScannerProModule` — memastikan perilaku internal.
5. **Uji jaringan terisolasi** — memverifikasi update/registrasi.
6. **Uji import format lain** — S19/TDF/VDF/RDT/CEE/ADS/EFILive.
7. **Uji 700 BIN** — memetakan seluruh keluarga dan checksum.

---

## 5. Pernyataan cakupan

- **Tidak** diklaim bahwa seluruh fitur TunerPro telah diuji.
- **Tidak** diklaim bahwa seluruh file dataset telah dibaca isinya.
- **Tidak** diklaim bahwa protokol Honda telah direkonstruksi.
- **Diklaim** bahwa struktur aplikasi, model XDF/ADX, checksum SUM, tidak adanya flashing ECU, dan perbedaan utama dengan RevCore telah dibuktikan sesuai tingkat yang dinyatakan.

---

## 6. Ringkasan satu paragraf

TunerPro RT 5.0.10335.0 adalah aplikasi native x86 berbasis editor definisi XDF dan runner ADX, dengan lapisan plug-in checksum dan hardware. Ia dapat mengedit BIN mentah, menghitung checksum SUM sesuai definisi, menjalankan datalogging jika ADX dan hardware tersedia, dan memprogram chip/emulator. Ia **tidak** memiliki jalur flashing ECU Honda, tidak memiliki protokol Honda di kode, dan tidak dapat memulihkan ECU. Dataset 174 XDF/3 ADX sebagian besar terenkripsi; hanya 13 XDF yang dapat diaudit. RevCore memiliki checksum SUM 8-bit yang identik secara algoritma, model status live data yang lebih ketat, dan FlashEngine default-deny yang lebih aman, tetapi belum memiliki parser XDF/ADX atau Live Monitor setara. Semua klaim di atas dibatasi oleh tidak adanya hardware, ECU, dan kunci dekripsi.
