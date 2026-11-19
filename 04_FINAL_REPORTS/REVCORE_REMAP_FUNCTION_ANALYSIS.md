# RevCore — Remap Function Analysis (3D Chart Graph Remap K-Line)

Scope: hanya fungsi remap (baca/tulis ECU), bukan clone dan bukan basis aplikasi.
Source utama: `3D Chart Graph/Form1.cs` (C# WinForms, FTDI D2XX, K-line).

## 1. Ringkasan alur

```
License gate
  -> InitFtdiIso (wake)
  -> FE 04 72 8C
  -> 72 05 00 F0 99 (reset)
  -> GetEcuType (signature scan)
  -> AutoChecksum (Shindengen / Keihin)
  -> PreWriteFlash (handshake + seed/key + erase)
  -> WriteFlash (block write + checksum per block)
  -> finalize sequence (status 0x0F)
  -> probe loop until ECU stops answering
  -> FT_Close
```

Bukti: `Form1.cs:742` (`flas`), `1130`, `1174`, `1348`, `1721`, `1740`.

## 2. Identifikasi ECU

`GetEcuType()` (`Form1.cs:1042`):

| Kondisi | Tipe | Start offset |
|---|---|---|
| `shBinSig` (`90 90 90 90`) di EOF | Shindengen | — |
| `shV850Sig` ditemukan | `SHINDENGENV850` | `0x10000` |
| `shRh850Sig` ditemukan | `SHINDENGENRH850` | `0x10000` |
| `shRh850Sig` + `shStart0` di `0xA000` | `SHINDENGENRH850B` | `0xA000` |
| `khH8cSig` di EOF (57.344/32.768 B) | `KEIHINH8C` | dari UI |
| `khM32rSig` di EOF (262.144 B) | `KEIHINM32R` | dari UI |
| lainnya | `KEIHINOTHER` | dari UI |

`GetOffsetsFromBinType()` (`Form1.cs:365`):

| Ukuran | Start | Checksum |
|---:|---|---|
| 49.152 | `4000` | `7600` |
| 57.344 | `0` | `DFEF` |
| 65.536 / 98.304 | `8000` | `0` |
| 131.072 | `E0000` | `B000` |
| 262.144 (Keihin H8C/M32R/MPC560) | `0` | `3FFF8` |
| 524.288 (MPC560) | `0` | `7FFF8` |
| 1.048.576 (SH705x) | `0` | `FFFF8` |
| Shindengen auto | dari `GetEcuType` | auto |

Catatan: `131072 -> E0000` berada di luar ukuran file (`0x20000`). Ini **dugaan bug/typo** dan harus diverifikasi sebelum dipakai.

## 3. Checksum BIN

### 3.1 Shindengen (`Form1.cs:1130`)

1. Scan `shWKeysig`; setelahnya cari pola `D0 07`.
2. `num` = posisi pola; untuk `SHINDENGENRH850B`, `num -= 6`.
3. `checksumOffset = num - 4`.
4. `sum = Sum32(bin, 0 .. num-4) + Sum32(bin, num .. EOF)`.
5. Tulis `0 - sum` little-endian 4 byte di `num-4`.

### 3.2 Keihin (`Form1.cs:1721`, `2094`, `2107`)

```
if checksumOffset == 0:
    sum = sum8(bin, size-1, 1)          // byte 1..EOF
else:
    sum = sum8(bin, checksumOffset, 0) + sum8(bin, size-(checksumOffset+1), checksumOffset+1)
bin[checksumOffset] = 0 - sum
```

`Checksum8Bit` = `255 - ((sum - 1) >> 8)`; `Checksum8BitHonda` = `((sum ^ 255) + 1) & 255`.

## 4. Pre-write dan seed/key

### 4.1 Shindengen (`Form1.cs:1174`)

Urutan frame (semua checksum valid):

```
7B 08 02 02 50 19 76 9A
7B 08 02 03 25 37 86 96
(tunggu 10 detik, progress bar)
7B 05 02 04 7A                  -> minta seed
7B 07 02 05 <k0> <k1> <sum>     -> kirim key
7C 06 02 01 00 7B               -> erase
7C 0B 02 0B 00 00 00 FF FF FF 6F
7C 07 02 0E 01 00 6C
7C 06 02 04 FF 79
7C 05 02 05 78
```

Respons challenge dianggap valid jika `resp[1] == 7` dan `resp[3] == 0`. Key dihitung dari 2 byte seed dan tiga word 16-bit dari BIN.

### 4.2 Keihin (`Form1.cs:1740`)

```
7D 08 01 02 50 47 4D 94
7D 08 01 03 2D 46 49 BB
7E 05 01 02 7A
7E 07 01 03 00 00 77
7E 0B 01 0B 00 00 00 FF FF FF 6E
7E 07 01 0E 01 90 DB
7E 06 01 04 FF 78
7E 05 01 05 77
7E 06 01 01 00 7A              -> probe
```

### 4.3 Algoritma seed/key (`Form1.cs:2023`, `2055`)

```
seed16 = seed[0]<<8 | seed[1]
w1,w2,w3 = little-endian 16-bit words at matched signature
key16 = w3 * (seed16 + w1) + (w2 != 0 ? seed16 % w2 : seed16)
key = big-endian 2 byte
```

Tidak ada konstanta rahasia; material kunci berasal dari BIN. `shRKeysig` dipakai untuk recovery, `shWKeysig` untuk normal.

## 5. Penulisan blok (`Form1.cs:1348`)

### 5.1 Ukuran dan header

| Tipe | Blok | Header | Jumlah blok |
|---|---:|---|---|
| `KEIHINOTHER`, Shindengen | 128 B | `7E` / `7C`, len `0x8B`, family `01`/`02`, sub `06` | `binSize/128` |
| `KEIHINH8C` | 64 B | `7B 4B 01 06` | `binSize/64` |
| `KEIHINM32R` | — | — | tidak ditulis |

### 5.2 Layout frame tulis (128 B)

| Offset | Isi |
|---:|---|
| 0 | `7E` (Keihin) / `7C` (Shindengen) |
| 1 | `0x8B` (139) |
| 2 | `01` / `02` |
| 3 | `06` |
| 4..5 | alamat (big-endian) |
| 6..133 | 128 byte data |
| 134..135 | alamat blok berikutnya |
| 136 | `Checksum8Bit(bytes 4..135)` |
| 137 | `Checksum8BitHonda(bytes 4..135)` |
| 138 | `Checksum8BitHonda(bytes 0..137)` |

Untuk blok 64 B, header `4B` (75) dan layout mengikuti ukuran 64.

Alamat awal: `startOffset/16` untuk jalur default; untuk H8C/Shindengen `i = startOffset/64` atau `/128`, tetapi `num5` tetap `startOffset/16`. **DUGAAN inkonsistensi** yang harus diverifikasi.

### 5.3 Blank-block skipping

Untuk `flag=true` (default), aplikasi memindai blok berikutnya yang seluruhnya `0xFF` dan melompatinya (`num6` = alamat blok non-blank). Tujuannya mempercepat penulisan. Untuk blok terakhir, `num6=0`.

### 5.4 Fast write

Hanya `KEIHINOTHER`: setelah respons `FF 25 00 20 7C 00` valid (`resp[1]==5 && resp[3]==0`), baud dinaikkan ke **62.500**. Literal frame ini tidak mengikuti checksum K-line standar; kemungkinan perintah khusus (DUGAAN).

## 6. Verifikasi hasil tulis

| Tahap | Verifikasi |
|---|---|
| Setiap blok | respons harus `resp[1] == 5`; jika `resp[1] == 7` dengan word nol berulang → gagal |
| Akhir tulis | Shindengen `7C 05 02 08..0D`; Keihin `7E 05 01 07..0D`; sukses jika `resp[3] == 0x0F` |
| Read-back | **TIDAK ADA** |
| Checksum pasca-tulis | **TIDAK ADA** (hanya checksum sebelum tulis) |

Artinya keberhasilan hanya berarti ECU mengakui setiap blok dan urutan final. Tidak ada bukti isi flash sama dengan BIN. Ini risiko utama untuk RevCore.

## 7. Penghentian dan error

- Jika satu blok gagal: `"Writing flash failed!!"`, progress reset, `TxtConnStat = "?"`, return.
- Jika finalisasi gagal: `"write flash completed result = BAD!! Please restart the ECU..."`.
- `ShindengenPreWriteFlash` menampilkan pesan spesifik untuk `resp[3] == 250` (block error).
- `KeihinPreWriteFlash` menampilkan `"DELETE FAILED, BLOCK ERROR"` / `"GAGAL HAPUS"`.

## 8. License gate (tidak dipublikasikan detail rahasianya)

- `BtnWrite_Click_1` (`Form1.cs:18406`) membentuk `processorId + "_" + diskSerial`, memprosesnya, lalu membandingkan dengan kunci dari `DecryptKeyFromFile()`.
- `flas()` mengulang pemeriksaan dengan `ProcessDiskSerial(processorId)`.
- Jika tidak cocok, `BtnWrite_Click_1` tidak menampilkan pesan dan tidak memulai thread; `button3_Click` menampilkan error dan keluar.
- File lisensi didekripsi dengan AES; **key/IV hardcoded sengaja tidak dimuat dalam laporan ini**.
- Folder sumber juga berisi `ANALIST_PRO - keygen.exe`; file tersebut **tidak dijalankan, tidak dianalisis, dan tidak dipublikasikan**. RevCore tidak boleh memakai bypass lisensi.

## 9. Inkonsistensi dan risiko

| ID | Temuan | Dampak | Status |
|---|---|---|---|
| R-01 | Tidak ada read-back/verify setelah tulis | klaim sukses tidak membuktikan isi flash | SOURCE VERIFIED |
| R-02 | `KEIHINM32R` terdeteksi tetapi tidak ditulis | dead end untuk ECU tersebut | SOURCE VERIFIED |
| R-03 | `131072 -> start E0000` di luar ukuran file | kemungkinan gagal/alamat salah | DUGAAN BUG |
| R-04 | Alamat `startOffset/16` vs indeks `startOffset/blok` | potensi alamat salah pada H8C/Shindengen | DUGAAN |
| R-05 | `tableType`/echo tidak diverifikasi | tidak relevan untuk tulis, relevan untuk diagnosa | DUGAAN |
| R-06 | Fast-write frame `FF 25 00 20 7C 00` bukan frame standar | perilaku khusus, belum dipahami | DUGAAN |
| R-07 | Seed/key memakai data BIN, bukan rahasia terpisah | keamanan bergantung pada kalibrasi | SOURCE VERIFIED |
| R-08 | `khRh850Sig`/`khMpc560Sig` dipakai untuk offset, tidak untuk tipe | ketidaksesuaian klasifikasi | SOURCE VERIFIED |
| R-09 | Checksum Shindengen hanya mencari pola `D0 07` pertama | bisa salah offset jika ada pola lain | SOURCE VERIFIED (algoritma), risiko UNVERIFIED |
| R-10 | Tidak ada verifikasi checksum ECU setelah erase | kegagalan dapat baru terlihat saat start | SOURCE VERIFIED |

## 10. Rekomendasi untuk RevCore

1. Tambahkan **read-back verify** per blok atau per region setelah tulis; bandingkan hash.
2. Tampilkan status per blok (alamat, kirim, ack, verify).
3. Jangan meniru license gate; RevCore memakai mekanisme lisensi sendiri.
4. Verifikasi alamat start/checksum untuk setiap ukuran BIN pada ECU nyata.
5. Tangani `KEIHINM32R` secara eksplisit (ditolak dengan pesan jelas) sampai protokol tulisnya diketahui.
6. Simpan checksum sebelum/sesudah dan tampilkan ke pengguna.
7. Uji pada ECU cadangan; jangan gunakan ECU pelanggan untuk validasi awal.

## 11. Status keseluruhan

| Aspek | Status |
|---|---|
| Deteksi ECU & offset | SOURCE VERIFIED (dengan 2 dugaan bug) |
| Checksum BIN | SOURCE VERIFIED |
| Pre-write/erase | SOURCE VERIFIED (frame & urutan) |
| Seed/key | SOURCE VERIFIED |
| Penulisan blok | SOURCE VERIFIED |
| Verifikasi tulis | TIDAK ADA (cacat desain) |
| Uji ECU nyata | TIDAK DILAKUKAN |
