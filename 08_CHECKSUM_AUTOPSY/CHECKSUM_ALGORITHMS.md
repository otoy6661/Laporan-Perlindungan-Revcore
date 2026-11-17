# Checksum — Permukaan Fungsi dan Batas Bukti

**Status:** SOURCE VERIFIED (nama fungsi & kontrol) · **algoritma: NOT VERIFIED** (bytecode IL tidak dapat diambil).

---

## 1. Fungsi yang ada

| Fungsi | Param | Dugaan peran (dari nama) | Status algoritma |
|---|---:|---|---|
| `Checksum8Bit` | 3 | checksum 8-bit generik | NOT VERIFIED |
| `Checksum8BitHonda` | 3 | varian khusus Honda | NOT VERIFIED |
| `Sum8Bit` | 3 | penjumlahan 8-bit | NOT VERIFIED |
| `Sum32Bit` | 3 | penjumlahan 32-bit | NOT VERIFIED |
| `ValidateChecksum` | 2 | validasi hasil baca (dipakai `Diag` untuk DTC) | NOT VERIFIED |
| `ShindengenAutoChecksum` | 1 | hitung/terapkan checksum image Shindengen | NOT VERIFIED |
| `KeihinAutoChecksum` | 1 | hitung/terapkan checksum image Keihin | NOT VERIFIED |

Parameter `3` pada fungsi checksum konsisten dengan *(buffer, offset, panjang)* atau *(buffer, start, end)* — **susunan sebenarnya tidak diketahui**.

## 2. Kontrol pengguna

- `TbChecksumOffset` + `ChecksumOffset_Changed` → pengguna dapat menentukan **lokasi** checksum.
- `TbStartOffset` + `StartOffset_Changed` → awal area yang dihitung/ditulis.
- `CbFastWrite` → mode tulis cepat (kemungkinan melewati verifikasi per blok; **NOT VERIFIED**).
- `TxtFlashCount` → penghitung flash yang dapat direset.

Adanya offset manual berarti checksum **tidak selalu** dihitung otomatis dari tabel internal; untuk ECU yang tidak dikenali, pengguna memasukkan offset sendiri. Ini fitur lapangan yang penting: aplikasi mentolerir ECU di luar database.

## 3. Kapan dijalankan

Urutan nama metode di `Form1` (bukan urutan eksekusi terverifikasi):

```
ShindengenPreWriteFlash / KeihinPreWriteFlash
  → Erasing flash
  → WriteFlash
  → CompareMemory
  → ShindengenAutoChecksum / KeihinAutoChecksum
```

Pesan UI yang menyertainya: `Verifikasi Data...`, `Verify ...`, `WRITE FLASH COMPLETE`, `Writing Data Completed Result = GOOD`, `write flash completed result = BAD!!`.
Tidak ada pesan "checksum mismatch" terpisah; kegagalan checksum tampaknya dilaporkan sebagai hasil tulis BAD. **Inferensi, bukan bukti.**

## 4. Untuk DTC

`Diag` memanggil `ValidateChecksum(arr, len)` + `Checksum8BitHonda(...)` sebelum menampilkan kode. Artinya respons DTC memiliki checksum internal; bila gagal, data tidak ditampilkan (string `Data kosong`/`Error decoding data`).

## 5. Yang tidak dapat diklaim

- Tidak ada polinomial, initial value, endianness, atau rentang alamat yang terbukti.
- Tidak ada sampel "sebelum/sesudah" checksum dari ECU nyata.
- Tidak ada bukti bahwa `Checksum8BitHonda` di FLASHPRO identik dengan implementasi RevCore — kecocokan hanya bisa diuji dengan image nyata (FASE VI).
- Klaim "mendukung checksum Honda" adalah klaim **permukaan**, bukan hasil verifikasi.

## 6. Rencana verifikasi (FASE VI)

1. Siapkan ≥3 image BIN Honda (Keihin & Shindengen) yang diketahui valid.
2. Hitung checksum dengan kandidat algoritma (sum8, sum32, Honda 8-bit) pada offset yang dibaca dari aplikasi/DB.
3. Bandingkan dengan nilai tersimpan di image.
4. Baru setelah cocok 3/3, status naik menjadi SIMULATION VERIFIED.
