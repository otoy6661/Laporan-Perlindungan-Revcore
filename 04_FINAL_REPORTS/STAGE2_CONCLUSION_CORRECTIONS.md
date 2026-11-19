# Koreksi Kesimpulan Tahap 1 → Tahap 2

Aturan: laporan Tahap 1 **tidak dihapus** dan tetap menjadi riwayat penelitian. Dokumen ini mencatat setiap kesimpulan yang berubah, beserta bukti baru dan alasan revisi. Bila suatu butir hanya diperkuat tanpa berubah, disebut "diperkuat".

Basis: `03_EVIDENCE/HDIAG_STAGE2_EVIDENCE.md`, `03_EVIDENCE/3DCHART_STAGE2_EVIDENCE.md`, dan pembacaan ulang source Tahap 2.
Tingkat: **A** terbukti · **B** sangat kuat · **C** dugaan · **D** belum diketahui · **E** butuh hardware.

## Ringkasan koreksi

| ID | Klaim Tahap 1 | Kesimpulan Tahap 2 | Tingkat |
|---|---|---|---|
| C-01 | Tabel H-Diag 30 baris; baris 0 = STF | Tabel **50 baris**; baris 0 = RPM, STF = baris 20 | A |
| C-02 | `[list+0x60+4*row]` menyimpan label per baris | `[this+0x60]` = daftar **kunci**; baris berasal dari argumen `slot`; kolom dari `[this+0x5c]` | A |
| C-03 | Baris IAC ← slot `0x0C` (key 8) | Slot `0x0D` = baris 13 (O2V, key `0x0C`); IAC = baris 32 lewat jalur 7 token slot `0x20` | B |
| C-04 | Slot `0x14` = TPSV2 | Slot `0x14` = baris 20 = STF | A |
| C-05 | Slot `0x0F` = EVA, `0x1B` = EGCV, `0x1E` tak dikenal | Slot `0x10` = BASV (16, key `0x0F`), slot `0x1B` = ALT (27), slot `0x1E` = MIL (30) | A |
| C-06 | Jalur baris 0..7 "belum ditemukan" | STF/POM/SS/STS/SSW/FIS/MOD/ALT semuanya punya jalur `setRow` eksplisit | B |
| C-07 | `array9[2]` = "tableType", kemungkinan echo (DUGAAN) | `array9[2]` = byte fungsi balasan `0x71`; echo sudah dibuang `SendCommand` | A |
| C-08 | Timeout menampilkan nilai nol | Balasan gagal (`b[1]==5`) → **nilai lama tetap tampil**; nol hanya jika buffer kosong | A/B |
| C-09 | Seed/key "berbasis BIN" | Seed/key adalah **challenge runtime** dari ECU; `shWKeysig` hanya penanda area checksum di BIN | A |
| C-10 | Fast-write frame "DUGAAN" | `FF 25 00 20 7C 00` + 62500 baud, hanya `KEIHINOTHER`, default aktif | A |
| C-11 | "Bug alamat" pada remap (DUGAAN) | Bukan bug: `startOffset/16` = alamat frame, `startOffset/128` = indeks blok; dua peran berbeda | A |
| C-12 | `replyLen = buffer[commandSize+1]` heuristik | Mekanisme echo-dependent terbukti di kode; `num5` dibaca di `commandSize+1`, `num5` byte terakhir disalin | A |
| C-13 | Baris GG satu (row 29 Tahap 1) | Label GG muncul **dua kali**: baris 28 dan baris 49 (string `0x412d00` yang sama) | A |
| C-14 | `0x412FB8`/`0x4130E0` dianggap kandidat daftar nama | Keduanya blob **teks deskripsi DTC** (ECT/EOT), bukan daftar nama parameter | B |

## Detail

### C-01 — Nomor baris tabel Live Data
- **Klaim lama:** `HDIAG_FUNCTION_MAPPING.md §2`, `03_EVIDENCE/HDIAG_STATIC_EVIDENCE.md` E-HD-02: 30 baris logis, STF=0 … GG=29, baris 8 kosong.
- **Bukti baru:** `0x402010–0x40295F` membangun 50 baris berurutan; string pertama `0x412ae4` = RPM (baris 0), `0x412c40` STF = baris 20. Daftar lengkap di `HDIAG_STAGE2_EVIDENCE.md §1`.
- **Alasan:** Tahap 1 memetakan subhimpunan string tanpa menghitung 20 baris awal (RPM…FAN) dan memberi nomor sendiri.
- **Kesimpulan baru:** semua nomor baris mengikuti tabel 50 baris. Laporan Tahap 1 tetap ada, tetapi penomoran barisnya **digantikan** dokumen Tahap 2.

### C-02 — Arti `[this+0x60]`
- **Klaim lama:** label per baris disimpan di `[list+0x60+4*row]`.
- **Bukti baru:** `0x406AD0` (`setRow`) memindai `[this+0x60]` untuk mencari kunci; `[this+0x64]` menyimpan tabel offset per tipe; `QString::split(',')` memecah label; indeks baris dari `slot`; kolom dari `[ebp+0x5c]` (`HDIAG_STAGE2_EVIDENCE.md §2–3`).
- **Kesimpulan baru:** `[this+0x60]` bukan array label; ia daftar kunci yang harus cocok, jika tidak update dibatalkan.

### C-03 / C-04 / C-05 — Salah label pada jalur balasan
- **Klaim lama:** `HDIAG_PROTOCOL_ANALYSIS.md §6`: key 8 → IAC (0x0C) dan TPSV2 (0x14); key 0x14 → EVA (0x0F), EGCV (0x1B), baris 0x1E.
- **Bukti baru:** jalur 8 token: `setRow(key 0xC, kolom 3, slot 0xD)` dan `setRow(key 0x14, kolom 2, slot 0x14)` (`0x405FB1`, `0x405FD5`). Jalur 20 token: `(key 0xF, slot 0x10)`, `(key 0x1B, slot 0x1B)` dua kali, `(key 0x1E, slot 0x1E)`, `(key 0x1E, slot 0x1F)` (`0x406007`…`0x406091`). Baris 0x0D=13 O2V, 0x14=20 STF, 0x10=16 BASV, 0x1B=27 ALT, 0x1E=30 MIL, 0x1F=31 MILV (`HDIAG_STAGE2_EVIDENCE.md §1, §4`).
- **Alasan:** Tahap 1 mencampur nilai dispatch dengan nomor baris dan memakai penomoran 30 baris.
- **Kesimpulan baru:** STF terbaca dari jalur 8 token slot 0x14 (B); O2V dari slot 0x0D (B); IAC dari jalur 7 token slot 0x20 (B). EGCV (baris 47) **belum** punya jalur `setRow` yang ditemukan (D) — klaim Tahap 1 bahwa EGCV terisi dari slot 0x1B dibatalkan.

### C-06 — "Baris 0..7 belum ditemukan"
- **Klaim lama:** `HDIAG_PROTOCOL_ANALYSIS.md §6` dan `HDIAG_REVCORE_REQUIREMENTS_04_10.md`.
- **Bukti baru:** 48 pemanggilan `setRow` terinventarisasi; sembilan parameter wajib semuanya memiliki jalur (tabel di `STAGE2_HDIAG_LIVEDATA_PARSER.md §2`).
- **Kesimpulan baru:** hubungan **baris → parser** selesai (B). Yang tetap terbuka adalah **frame mana** menghasilkan tiap jalur dan **offset byte absolut** (D/E).

### C-07 — `array9[2]` / tableType
- **Klaim lama:** `REVCORE_SENSOR_READING_ANALYSIS.md §4, S-05`: mungkin echo fungsi, DUGAAN.
- **Bukti baru:** `SendCommand` menyalin `num5` byte terakhir (`Array.Copy(array2, num4-num5, ...)`), sehingga echo request tidak ikut; `array9[0]=0x72`, `[2]=0x71` (`Diag.cs:1340`, `1040`; `3DCHART_STAGE2_EVIDENCE.md §2`).
- **Kesimpulan baru:** `tableType` selalu 113 (`0x71`), yaitu byte fungsi; bukan tipe tabel, bukan echo. Baris 14 tabel praktis konstan (A).

### C-08 — Timeout vs nilai basi
- **Klaim lama:** timeout ditampilkan sebagai nol/OFF (`REVCORE_SENSOR_READING_ANALYSIS.md §7`).
- **Bukti baru:** `if (array9[1] == 0x05) { tekXX = false; return; }` — return sebelum memperbarui variabel tampilan; buffer baru memang nol, tetapi nilai lama dipertahankan (`3DCHART_STAGE2_EVIDENCE.md §4`).
- **Kesimpulan baru:** dua fenomena berbeda: (a) nilai basi saat fungsi dinyatakan tidak didukung, (b) nol/default saat buffer benar-benar kosong. Keduanya tanpa penanda validitas (A kode, B perilaku).

### C-09 — Seed/key
- **Klaim lama:** `REVCORE_REFERENCE_ANALYSIS_SUMMARY.md §5`: "Seed/key berbasis BIN".
- **Bukti baru:** `ShindengenPreWriteFlash` mengirim permintaan seed (`7B 07 02 05 …`), menunggu challenge 10×1500 ms, lalu menghitung kunci (`Form1.cs:1174–1346`). `shWKeysig` adalah pola byte di BIN untuk menemukan area checksum, bukan kunci.
- **Kesimpulan baru:** seed/key adalah pertukaran runtime dengan ECU; BIN hanya menyediakan penanda area checksum (A untuk urutan, D untuk algoritma kunci — tidak dipublikasikan).

### C-10 — Fast write
- **Klaim lama:** `REVCORE_REFERENCE_ANALYSIS_SUMMARY.md §8`: "fast-write frame" DUGAAN.
- **Bukti baru:** `Form1.cs:1482–1500`, default `isFastWrite=true` (`134`).
- **Kesimpulan baru:** frame dan baud terbukti di kode (A); perilaku ECU E.

### C-11 — "Bug alamat"
- **Klaim lama:** "bug alamat" masuk daftar DUGAAN (`REVCORE_REFERENCE_ANALYSIS_SUMMARY.md §8`).
- **Bukti baru:** `num5 = startOffset/16` (alamat), `i = startOffset/num3` (indeks blok), `num7 = binSize/128` (jumlah blok) — tiga variabel terpisah (`Form1.cs:1464`, `1534`, `1467`).
- **Kesimpulan baru:** bukan bug; perbedaan pembagi adalah desain. Klaim bug dibatalkan (A).

### C-12 — Panjang balasan
- **Klaim lama:** heuristik echo, DUGAAN.
- **Bukti baru:** `num5 = array2[commandSize+1]`; tunggu `num4-commandSize == num5`; salin `num5` byte terakhir; validasi checksum (`Diag.cs:1290–1348`).
- **Kesimpulan baru:** mekanisme **mengasumsikan** ECU menggemakan request; asumsi ini eksplisit di kode (A). Apakah semua ECU target mematuhinya: E.

### C-13 — Duplikat GG
- **Bukti baru:** string `0x412d00` dipakai dua kali (baris 28 dan 49) pada pembangun label 50 baris.
- **Kesimpulan baru:** duplikat disengaja/tidak, belum diketahui (D); jangan menganggap satu baris GG saja.

### C-14 — `0x412FB8` / `0x4130E0`
- **Klaim lama:** pernah dianggap kandidat tabel nama per tipe ECU.
- **Bukti baru:** isinya teks deskripsi DTC ECT/EOT; dipakai untuk menampilkan keterangan, bukan untuk memetakan nama parameter (`STAGE2_HDIAG_LIVEDATA_PARSER.md §5`).
- **Kesimpulan baru:** bukan daftar nama; klaim tabel nama di alamat itu dibatalkan (B).

## Yang diperkuat (tanpa perubahan kesimpulan)

| Butir | Status Tahap 2 |
|---|---|
| Frame & checksum K-line | 45 frame diaudit ulang, semua PASS (`PROTOCOL_FRAME_VALIDATION_STAGE2.csv`) |
| H-Diag read-only untuk Altitude | Tidak ada frame tulis di seluruh `.text` (A) |
| `Task.Delay` tidak di-await | Dikonfirmasi; tidak ada interval tetap (A) |
| IAC 3D Chart dihitung tetapi tidak ditampilkan | Dikonfirmasi `Diag.cs:841` vs `UpdateGridView` (A) |
| Tidak ada read-back setelah tulis | Dikonfirmasi; hanya status ACK (A) |
| H-Diag baud 10400 | **Masih D**: tidak ada konstanta divisor di `.text`; hanya konsisten dengan 3D Chart |

## Dampak ke dokumen Tahap 1

- Dokumen Tahap 1 **tidak diubah** (riwayat).
- README dan indeks Tahap 2 menandai bagian yang digantikan: nomor baris H-Diag, arti slot 0x0C/0x14/0x1B/0x1E, `array9[2]`, dan seed/key.
- Tidak ada duplikasi file: koreksi hanya hidup di dokumen ini.
