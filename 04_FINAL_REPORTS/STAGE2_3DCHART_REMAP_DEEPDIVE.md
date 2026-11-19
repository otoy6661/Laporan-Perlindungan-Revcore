# 3D Chart Graph — Remap Deep-Dive (Tahap 2)

Basis: source `Form1.cs` (baris dikutip), tanpa eksekusi, tanpa koneksi ECU, tanpa flashing.
Tingkat: **A** terbaca di source · **B** sangat kuat · **C** dugaan · **D** belum diketahui · **E** butuh hardware.

> Dokumen ini **tidak** memuat kunci, seed/key hasil, atau material sensitif. Hanya mekanisme dan alamat kode.

## 1. Identifikasi keluarga ECU (A)

`GetEcuType()` `Form1.cs:1052–1128`. Deteksi memakai pencocokan pola byte pada BIN yang sudah dibuka:

| SIG | Isi (byte) | Lokasi pencarian | Hasil |
|---|---|---|---|
| `shBinSig` | `5A 5A 5A 5A` ("ZZZZ") | akhir file | kandidat Shindengen |
| `shV850Sig` | `53 56 38 35 30` ("SV850") | seluruh file, loop `i < binSize-5` | `SHINDENGENV850` |
| `shRh850Sig` | `53 48 38 35 30` ("SH850") | seluruh file | `SHINDENGENRH850`; jika `A5 A5 A5 A5 00` ada di `0xA000` → `SHINDENGENRH850B` |
| `shWKeysig` | `0B 0C 0D 0E 0F 0F 11` | seluruh file | penanda kunci; jika ada → fallback `SHINDENGENV850` |
| `khH8cSig` | `FF FF AA AA` | akhir file, hanya ukuran 57344/32768 | `KEIHINH8C` |
| `khM32rSig` | `FF FF FF AA AA AA AA` | akhir file, hanya 262144 | `KEIHINM32R` |
| lainnya | | | `KEIHINOTHER` |

`GetOffsetsFromBinType()` `Form1.cs:365–434` menetapkan `startOffset` dan `checksumOffset` dari ukuran BIN:

| binSize | startOffset | checksumOffset |
|---:|---|---|
| 49152 | `4000` | `7600` |
| 57344 | `0` | `DFEF` |
| 65536 / 98304 | `8000` | `0` |
| **131072** | **`E0000`** | **`B000`** |
| ≥262144 + ZZZZ + SV850/SH850 | `auto` | `auto` |
| 262144 + khRh850/khM32r/khMpc560 | `0` | `3FFF8` |
| 524288 + khMpc560 | `0` | `7FFF8` |
| 1048576 + khSH705X | `0` | `FFFF8` |
| 1048576 lainnya | `0` | `7FFF8` |

Catatan: `131072 → E0000` adalah offset **tampilan/alamat**, bukan ukuran blok. `startOffset` = 917504 > binSize 131072; ini menunjukkan alamat flash internal ECU, bukan indeks array BIN (B, karena nilai tersebut dipakai sebagai alamat frame, lihat §3).

## 2. Checksum (A)

### 2.1 Shindengen
`ShindengenAutoChecksum()` `Form1.cs:1130–1169`:

1. Cari `shWKeysig` di seluruh BIN.
2. Setelah penanda, cari pasangan byte **`D0 07`** (`binBytes[j]==0xD0 && binBytes[j+1]==0x07`).
3. `num = j`; untuk `SHINDENGENRH850B`: `num = j - 6`.
4. checksumOffset ditulis `(num-4)`.
5. checksum 32-bit = `Sum32Bit(bin, num-4, 0) + Sum32Bit(bin, binSize-num, num)`, lalu disimpan sebagai komplemen dua (`0 - sum`) pada 4 byte di `num-4 … num-1`.

### 2.2 Keihin
`KeihinAutoChecksum()` `Form1.cs:1721–1736`:

- Jika `checksumOffset == 0`: `b = Sum8Bit(bin, binSize-1, 1)`.
- Jika tidak: `b = Sum8Bit(bin, checksumOffset, 0) + Sum8Bit(bin, binSize-(checksumOffset+1), checksumOffset+1)`.
- `binBytes[checksumOffset] = (byte)(0 - b)`.

Tidak ada verifikasi setelah checksum ditulis; nilai langsung dikirim (A).

## 3. Alamat blok vs indeks blok (A)

`WriteFlash()` `Form1.cs:1348–1719`:

| Variabel | Nilai | Baris |
|---|---|---|
| `num3` (ukuran blok) | 128; **64 untuk H8C** | 1462, 1515 |
| `num4` (langkah alamat) | 8; **4 untuk H8C** | 1463, 1516 |
| `num5` (alamat awal frame) | `startOffset / 16` | 1464 |
| `num7` (jumlah blok) | `binSize / 128`; **`binSize / 64` untuk H8C** | 1467, 1517 |
| indeks blok `i` | `startOffset / num3` | 1534, 1546, 1559 |

Jadi **`startOffset/16` = alamat**, sedangkan **`startOffset/128` = indeks blok**. Keduanya dipakai untuk tujuan berbeda; Tahap 1 sudah menyebut ini, kini dikonfirmasi dengan tiga assignment terpisah.

Header blok: default `array15 = {0x7E, 0x8B, 0x01, 0x06}` (KEIHINOTHER), `{0x7E,0x4B,0x01,0x06}` untuk H8C (`Form1.cs:1518–1521`), dan `{0x7C,0x8B,0x02,0x06}` untuk Shindengen V850/RH850/RH850B (`Form1.cs:1530–1533`, `1542–1545`, `1555–1558`). Setiap iterasi:

```
array15[4] = num5 >> 8;  array15[5] = num5;
Array.Copy(binBytes, i*num3, array15, 6, num3);
```

## 4. Lewati blok kosong (A)

`Form1.cs:1576`: blok dilewati bila isinya seluruhnya `0xFF`:

```
if (!CompareMemory(binBytes, (i+k)*num3, array16 /*0xFF x num3*/, num3))
```

Blok kosong ditandai dengan `num6 = num5 + k*num4` (alamat blok berikutnya) dan `num6 = 0` untuk blok terakhir (penanda akhir). Rantai alamat ini dikirim dalam 2 byte setelah data (`array15[6+num3]`, `[7+num3]`).

Optimalisasi ini hanya aktif saat `flag == true`, yaitu **KEIHINOTHER** dan **SHINDENGENV850** (default `flag=true` di `Form1.cs:1470`). Untuk H8C, M32R, RH850, dan RH850B `flag=false` (`1513–1560`), sehingga setiap blok dikirim berurutan (A).

## 5. Tiga checksum per frame tulis (A)

Sebelum dikirim, tiga byte checksum dihitung (`Form1.cs:1598–1600`):

```
array15[6+num3+2] = Checksum8Bit(array15, num3+4, 4)
array15[6+num3+3] = Checksum8BitHonda(array15, num3+4, 4)
array15[6+num3+4] = Checksum8BitHonda(array15, array15[1]-1, 0)
```

Frame tulis memakai **checksum Honda** (`((sum ^ 0xFF)+1)&0xFF`) untuk checksum terakhir, bukan checksum blok ECU.

## 6. Retry, ACK, status akhir (A)

Loop tulis `Form1.cs:1567–1661`:

| Kondisi balasan | Aksi |
|---|---|
| `array14[1]==7 && [4]==0 && [5]==0` | sampai 2 retry, lalu `FAILED` |
| `array14[1]==5` | `SUCCESS`; untuk H8C setiap blok ke-2 kirim `array3` lalu `Thread.Sleep(250)` (1626–1630) |
| lainnya | `FAILED` → "Writing flash failed!!" (1653) |

Sukses menaikkan `num5 = num6` dan `i++`; gagal langsung `return` tanpa rollback (A).

Finalisasi:

- **Shindengen** (`WriteFlash` akhir): kirim `array9..array13` (`7C 05 02 08/09/0A/0C/0D`), jeda 1000/1000/1000/3000 ms; sukses jika `array14[3]==15`.
- **Keihin**: (H8C: `array3` + 100 ms) `array4` → 1000 ms → `array2` → `array5` → 1000 ms → `array2` → `array6` → 1000 ms → `array2` → `array7` → 1000 ms → `array2` (cek `array14[3]==15`) → `array8` (cek `array14[3]==15`); pesan gagal: "write flash completed / result = BAD!! / Please restart the ECU…".
- Kedua jalur sukses menulis "Writing flash complete".

## 7. Seed/Key dan erase (A untuk urutan, D untuk algoritma kunci)

`ShindengenPreWriteFlash()` `Form1.cs:1174–1346`:

1. Kirim `7B 08 02 02 50 19 76 9A`, lalu `7B 08 02 03 25 37 86 96`.
2. Kirim `7B 05 02 04 7A`, `7B 07 02 05 00 00 00` (slot seed/key, checksum dihitung ulang).
3. Tunggu challenge seed hingga 10×1500 ms; sukses jika `array10[1]==7 && array10[3]==0`.
4. Kunci dihitung oleh `GetShindengenWriteKey` / `GetShindengenRecoveryKey` dari seed (algoritma tidak diuraikan di sini).
5. Urutan erase: `7C 0B 02 0B …`, `7C 07 02 0E 01 6C`, `7C 06 02 04 FF 79`, `7C 05 02 05 78`; sukses `array10[1]==5 && array10[3]==0`; `array10[3]==250` = blok error.

`KeihinPreWriteFlash()` `Form1.cs:1740+`: `7D 08 01 02 50 47 4D 94`, `7D 08 01 03 2D 46 49 BB`, `7E 05 01 02 7A`, `7E 07 01 03 00 00 77`, `7E 0B 01 0B … 6E`.

Semua checksum frame di atas PASS (lihat `PROTOCOL_FRAME_VALIDATION_STAGE2.csv`). Algoritma seed→key **tidak** dianalisis/dipublikasikan (kebijakan §7 work order).

## 8. Fast write (A)

`Form1.cs:1482–1500`:

```
if (ecuType == KEIHINOTHER && isFastWrite) {
    kirim {FF 25 00 20 7C 00}
    jika array14[1]==5 && array14[3]==0:
        FT_SetBaudRate(62500);
        Thread.Sleep(100);
}
```

- `isFastWrite` default **true** (`Form1.cs:134`), diubah oleh checkbox (`2201–2204`).
- Fast write **hanya** untuk `KEIHINOTHER`; keluarga lain tetap 10400.
- Reset baud ke 10400 terjadi pada `InitFtdiIso` berikutnya, bukan setelah tulis (A).

## 9. Verifikasi pasca-tulis: tidak ada (A)

- Tidak ada fungsi `ReadFlash` di source.
- Tidak ada pembacaan balik blok setelah tulis.
- Tidak ada perhitungan ulang checksum dari isi flash nyata.
- Satu-satunya umpan balik adalah status byte `array14[1]`/`array14[3]` di atas.
- Tidak ada rollback/backup otomatis sebelum erase.

Kesimpulan: keberhasilan tulis bergantung sepenuhnya pada ACK ECU. Aplikasi referensi **tidak** memverifikasi hasil (A).

## 10. Yang belum diketahui (D/E)

1. Apakah ECU menghasilkan ACK yang jujur; tidak dapat diuji tanpa hardware (E).
2. Arti lengkap `array14[3]` selain 0/15/250 (D).
3. Apakah `D0 07` selalu checksum marker di semua BIN Shindengen (B untuk kode; E untuk data nyata).
4. Perilaku bila listrik terputus di tengah tulis (D).
