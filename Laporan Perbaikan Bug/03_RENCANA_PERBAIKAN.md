# RENCANA PERBAIKAN BUG — REVCORE

| Item | Keterangan |
|---|---|
| Tanggal | 2026-11-19 |
| Dasar | `01_AUDIT_SILANG_STAGE2.md` dan `02_DAFTAR_TEMUAN.csv` |
| Status | Usulan; **belum diimplementasikan** |
| Perubahan source | Tidak ada |
| Pengujian write/flash | Tidak dilakukan dan tidak direncanakan dalam dokumen ini |

Dokumen ini adalah urutan perbaikan yang disarankan. Setiap langkah memerlukan persetujuan pemilik sebelum dikerjakan. Tidak ada patch, build, atau perubahan UI yang dibuat berdasarkan dokumen ini.

---

## Prinsip pelaksanaan

1. Perbaikan bersifat lokal pada logika yang terbukti salah; arsitektur tidak diubah.
2. Tidak menghapus atau mengganti UI yang ada; perubahan tampilan hanya menambah kejujuran status.
3. Tidak mengubah nama aplikasi, identitas, atau kredit.
4. Tidak menyalin pemetaan sensor dari aplikasi referensi tanpa bukti capture.
5. Tidak menyentuh jalur tulis/flash; seluruh gate default-deny dipertahankan.
6. Setiap perbaikan harus memiliki uji regresi yang dapat dijalankan tanpa hardware bila memungkinkan.

---

## Prioritas

| Prioritas | Item | Alasan |
|---|---|---|
| P1 | A1, A2, A3 | Kesalahan diagnosis DTC; dapat diuji tanpa hardware |
| P2 | E1–E4, E6 | Salah label/nilai sensor; wajib capture read-only sebelum diubah |
| P3 | E5 | Checksum ROM; hanya memengaruhi impor/validasi offline |
| P4 | D3–D5 | Kebersihan label, dead code, pacing |

---

## Langkah 1 — Perbaiki parser DTC (A1, A3)

**Tujuan:** satu aturan parsing yang ketat dan dapat diprediksi.

**Perubahan yang diusulkan:**

1. Terapkan pencocokan panjang tepat untuk format count-prefix: `payload.size == 1 + count * 2`. Jika tidak tepat, jangan gunakan interpretasi count-prefix.
2. Hapus penerimaan sisa byte; payload yang tidak persis cocok dengan layout yang didukung dikembalikan sebagai "tidak dapat diurai", bukan daftar kosong.
3. Pertahankan subcode mentah pada objek DTC. Jangan mengganti subcode di luar 0..15 menjadi 0.
4. Jika subcode tidak dikenal, tampilkan kode mentah dan status "belum terverifikasi"; jangan memetakan ke deskripsi DTC lain.

**Lokasi:** `app/src/main/java/com/revcore/android/core/protocol/HondaDtcDatabase.kt` (`parseDtcPacket`, `parseDtcResponse`, `decode`).

**Uji yang harus ada (tanpa hardware):**

| Kasus | Input sintetis | Hasil yang diharapkan |
|---|---|---|
| Pasangan murni diawali 0x01 | `[01 07 08 01]` | Tidak dibaca sebagai count-prefix; hasil sesuai layout pasangan atau ditolak sebagai ambigu |
| Count-prefix tepat | `[02 07 01 08 01]` | Dua kode: (7,1), (8,1) |
| Count-prefix dengan sisa byte | `[01 07 01 FF]` | Ditolak sebagai ambigu, bukan satu kode |
| Subcode >15 | `[07 20]` | Kode 7 dengan subcode mentah 0x20 ditandai belum terverifikasi; tidak menjadi P0115 |
| Payload kosong | `[]` | Daftar kosong sah (bukan ambigu) |

**Kriteria penerimaan:**

- Tidak ada payload yang menghasilkan daftar kode berbeda hanya karena perubahan heuristik.
- Seluruh uji lama yang relevan tetap lulus.
- Tidak ada perubahan pada perintah yang dikirim ke ECU.

---

## Langkah 2 — Perbaiki pelaporan status DTC (A2)

**Tujuan:** UI tidak menyatakan "tidak ada kode" ketika respons tidak berhasil diurai.

**Perubahan yang diusulkan:**

1. Tambahkan hasil eksplisit `UNPARSED`/`AMBIGUOUS` pada hasil pembacaan DTC.
2. Mapping status:
   - payload kosong yang sah → `OK_EMPTY`;
   - payload berhasil diurai → `OK_CODES`;
   - frame valid tetapi payload tidak cocok layout mana pun → `UNPARSED`, bukan `OK_EMPTY`.
3. `DTC_READ_CONFIRMED` hanya diset untuk `OK_EMPTY` atau `OK_CODES`.
4. Pesan UI untuk `UNPARSED` harus menyatakan bahwa respons diterima tetapi belum dapat diinterpretasikan, dan menyarankan pengulangan pembacaan.

**Lokasi:** `core/protocol/HondaProtocolEngine.kt` (`readDtcsInternal`, `DtcReadState`), serta layar DTC yang menampilkan status.

**Kriteria penerimaan:**

- Frame valid dengan payload tak dikenal tidak pernah menampilkan "tidak ada kode aktif".
- Tidak ada perubahan pada format frame yang dikirim.

---

## Langkah 3 — Netralkan label kanal datD1 (D3, parsial)

**Tujuan:** menghindari klaim semantik yang belum diverifikasi tanpa menghilangkan data.

**Perubahan yang diusulkan:**

1. Pertahankan pembacaan byte apa adanya.
2. Ganti label `GEAR_STATE`, `FLAG_A`, `FLAG_B` menjadi label netral berbasis posisi byte (mis. "datD1 byte 4", "datD1 byte 8", "datD1 byte 9") sampai capture tersedia.
3. Jangan menambahkan pemetaan FAN/POM/FIS/IAC/ALT/SS/STS sebelum capture.

**Lokasi:** `core/comm/LiveDataProfile.kt` (`tableD1`), label di `LiveDataScreen.kt` dan `EcuInfoScreen.kt` bila diperlukan.

**Kriteria penerimaan:**

- Tidak ada label yang menyatakan fungsi fisik tertentu tanpa bukti.
- Nilai mentah tetap dapat dilihat.

**Catatan:** langkah ini opsional dan menunggu keputusan pemilik; jika dianggap terlalu mengubah tampilan, tunda sampai capture selesai.

---

## Langkah 4 — Capture hardware read-only (E1–E4, E6, E7)

**Tujuan:** mendapatkan bukti sebelum mengubah pemetaan atau nilai skala.

**Batasan:**

- Hanya membaca; tidak ada write, erase, atau flashing.
- Satu model acuan, kondisi kontak ON, mesin mati dan mesin hidup (sesuai izin pemilik).
- Data yang direkam: frame datD1, dat20, respons DTC, dan kanal sensor khusus yang tersedia.
- Tidak mengubah source untuk capture; gunakan logging yang sudah ada atau alat eksternal.

**Keluaran:**

- Tabel byte → nilai untuk datD1 (b4, b8, b9, b10) pada kondisi netral, gigi masuk, side stand, starter switch.
- Konfirmasi skala O2/STF.
- Daftar kanal yang benar-benar dipublikasikan ECU.

**Kriteria penerimaan:**

- Setiap klaim pemetaan didukung minimal satu capture yang dapat direproduksi.
- Tidak ada keputusan yang diambil dari dugaan laporan pihak lain.

---

## Langkah 5 — Riset checksum offline (E5)

**Tujuan:** memastikan algoritma checksum yang dipakai RevCore sebelum impor BIN diandalkan.

**Langkah:**

1. Kumpulkan sampel BIN yang legal dan dapat diverifikasi.
2. Bandingkan `KEIHIN_16BIT_ADD` (word sum big-endian) dengan referensi `Sum8Bit` + two's complement.
3. Bandingkan `SHINDENGEN_CRC16` dengan referensi 32-bit sum.
4. Dokumentasikan hasil; jika tidak cocok, jangan ubah algoritma tanpa keputusan pemilik.

**Batasan:** offline; tidak ada write ke ECU.

---

## Langkah 6 — Kebersihan kode dan pacing (D4, D5)

1. `KlineEchoFilter` dan `KlineTransceiver` legacy: tandai atau hapus hanya setelah dipastikan tidak dipakai jalur aktif. Perubahan ini tidak mengubah perilaku.
2. `LivePollPolicy.nextDelayMs`: tinjau hanya jika pemilik menetapkan target interval live. Jangan mengubah tanpa target yang jelas.

---

## Verifikasi umum

- Jalankan seluruh unit test yang ada sebelum dan sesudah perubahan.
- Tambahkan uji regresi untuk setiap bug yang diperbaiki (lihat tabel Langkah 1).
- Tidak ada pengujian yang mengirim perintah write/erase.
- Tidak ada perubahan pada database model (`isVerifiedRemap` tetap false).
- Tidak ada perubahan pada gate flash.

## Rollback

Setiap langkah harus berupa commit terpisah agar dapat di-revert tanpa memengaruhi langkah lain. Tidak ada migrasi data atau perubahan format penyimpanan yang direncanakan.

---

## Keputusan yang diperlukan dari pemilik

1. Setujui perbaikan DTC (Langkah 1–2).
2. Setujui atau tunda netralisasi label datD1 (Langkah 3).
3. Setujui sesi capture hardware read-only (Langkah 4), termasuk model acuan dan kondisi pengujian.
4. Tetapkan kebijakan impor BIN bila checksum belum terbukti (Langkah 5, D6).
5. Tetapkan target interval live bila pacing akan ditinjau (Langkah 6).

---

## Di luar ruang lingkup dokumen ini

- Implementasi write/flash ECU.
- Perubahan arsitektur.
- Perubahan nama aplikasi, identitas, atau kredit.
- Penggabungan pekerjaan dari proyek lain.
- Pembuatan patch, ZIP, atau APK.
