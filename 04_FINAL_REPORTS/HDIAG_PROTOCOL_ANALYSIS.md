# H-Diag — Protocol Analysis

## 1. Transport

| Parameter | Nilai | Bukti |
|---|---|---|
| Interface | FTDI D2XX / libusb-1.0 | `libusb-1.0.dll`, `usb_driver/`, import `ftd2xx.dll` |
| Logika | ISO K-line, single wire | Frame family + bit-bang wake |
| Baud | 10400 (3D Chart); H-Diag memakai library yang sama | 3D: `FT_SetBaudRate(10400)`; H-Diag: DUGAAN kuat |
| Wake | bit-bang low 70 ms, release, settle 130 ms | 3D source `InitFtdiIso`; H-Diag handshake konsisten |
| Timeout baca | 50 ms + 2×panjang frame | 3D `SendCommand`; H-Diag menggunakan helper sendiri |

## 2. Format frame

```
[0x72] [len] [fn] [sub] [param...] [checksum]
```

- `len` = jumlah total byte frame (5 untuk frame pendek, 7 untuk frame panjang, 8 untuk prewrite 3D).
- `checksum = ((sum8(frame[0..len-2]) ^ 0xFF) + 1) & 0xFF`.
- Semua frame di `03_EVIDENCE/PROTOCOL_FRAME_VALIDATION.csv` lolos verifikasi aritmetik.

Contoh:

```
72 05 71 10 08
sum = 72+05+71+10 = F8
checksum = (F8 ^ FF)+1 = 08
```

## 3. Request live data H-Diag (STATIC VERIFIED)

Urutan per siklus (counter `0x421420`):

| Urutan | Frame | Jumlah per siklus |
|---:|---|---:|
| 1 | `72 05 60 03 26` | 11 |
| 2 | `72 05 71 00 18` | 1 |
| 3 | `72 05 00 F1 98` | 1 |

Setelah setiap frame: delay 100 ms lalu baca. Di akhir siklus: status UI + jeda 1000 ms.

Frame B memakai fungsi `0x71` yang pada 3D Chart adalah fungsi live data. Sub-fungsi `0x00` tidak ada di 3D Chart (3D memakai `0x10`..`0x20`, `0xD1`), sehingga layout respons H-Diag tidak boleh diasumsikan sama.

Frame C (`fn=0x00`) tidak memiliki padanan di 3D Chart. Kemungkinan keep-alive/status (DUGAAN).

## 4. Request DTC H-Diag (STATIC VERIFIED)

| Indeks | Frame |
|---:|---|
| 0 | `72 07 72 D0 00 0E 37` |
| 1 | `72 05 73 00 16` |
| 2 | `72 05 73 01 15` |
| 3 | `72 05 74 01 14` |
| 4 | `72 07 72 D1 00 06 3E` |
| 5 | `72 07 72 D0 14 02 2F` |

Frame 5-byte dengan `fn=0x73/0x74` sama dengan frame DTC 3D Chart, sehingga dua aplikasi ini jelas memakai dialek K-line yang sama.

## 5. Format respons (rekonstruksi)

Dari `0x405F90` dan helper baca `0x409760`:

```
[0x72?] [len] [fn] [status] [data...] [checksum]
```

- `array9[1]` = `len`; nilainya 5 atau 7 pada jalur yang diperiksa.
- `array9[3]` = status; nilai `0x00` = sukses, `0xFA`/`0xF?` = error blok (pada 3D Chart).
- Data mulai `array9[4]`.
- Checksum byte terakhir.

H-Diag meneruskan sebagian data sebagai **teks ASCII** ke tabel (QString dengan panjang 0 = NUL-terminated). 3D Chart memperlakukan data sebagai biner. Ini perbedaan penting yang belum dijelaskan oleh bukti yang ada.

## 6. Parsing dan tampilan

- Dispatch pada kunci `edx` (8, 0x14, 0xC, 7).
- Baris 0x0C (IAC) ← teks `edi+0x0D` pada key 8.
- Baris 0x14 (TPSV2) ← `edi+1` pada key 8.
- Baris 0x0F (EVA) ← `edi+0x0D`; 0x1B (EGCV) ← `edi+0x0B/0x0C`; 0x1E ← `edi` pada key 0x14.
- Baris 0..7 (STF, POM, SS, STS, SSW, FIS, MOD, ALT) **belum** ditemukan jalur update-nya.

Konsekuensi: klaim "H-Diag membaca Fuel Pump dari byte X" belum dapat dibuktikan. Yang dapat dibuktikan adalah keberadaan baris, frame polling, dan sebagian jalur update.

## 7. Timing

| Aksi | Waktu | Bukti |
|---|---|---|
| Poll antar-frame | 100 ms | `push 0x64` |
| Akhir siklus | 1000 ms | `0x3E8` |
| Antar-DTC | 50 ms | `push 0x32` |
| Timeout respons | 50 ms + 2×len | pola 3D Chart; H-Diag helper sendiri belum dipastikan |
| Wake low | 70 ms | 3D Chart; H-Diag konsisten |

## 8. Penanganan respons tidak valid

- H-Diag: belum ditemukan retry/validasi checksum eksplisit di jalur baca; respons diteruskan ke parser.
- 3D Chart: `SendCommand` memvalidasi checksum dan menghapus buffer (`FT_Purge`) pada timeout, tetapi pemanggil mengabaikan nilai balik (lihat laporan sensor).
- Tidak ada logika "nilai tidak valid" yang ditampilkan; nilai nol dapat tampil sebagai nilai nyata.

## 9. Hal yang tidak boleh diklaim

1. Bahwa H-Diag mendukung pembacaan FID — tidak ada string FID.
2. Bahwa H-Diag mendukung "Starter Relay" — hanya ada "Switch Starter".
3. Bahwa Altitude Mode 1–4 dapat **diset** — tidak ada frame tulis.
4. Bahwa layout respons H-Diag identik dengan 3D Chart — tidak didukung bukti.
5. Bahwa frame C adalah keep-alive — masih dugaan.

## 10. Rekomendasi verifikasi lanjutan

- Jalankan H-Diag pada kendaraan/ECU uji dengan K-line logger pasif, rekam TX/RX per frame.
- Cocokkan respons frame B dengan baris tabel yang berubah (screenshot + log).
- Uji Altitude Mode: cari apakah ada menu set; jika tidak ada, konfirmasi bahwa H-Diag read-only.
- Untuk RevCore, gunakan frame 3D Chart yang sudah SOURCE VERIFIED (laporan terpisah) dan verifikasi pada ECU nyata sebelum implementasi.
