# 12 — ANALISIS CHECKSUM

**Work order:** BE-12
**Status:** SOURCE VERIFIED (nama & kontrol) · algoritma FLASHPRO **NOT VERIFIED** · algoritma RevCore **SIMULATION VERIFIED**
**Sumber:** `08_CHECKSUM_AUTOPSY/CHECKSUM_ALGORITHMS.md`, `13_PROTOTYPES/`

---

## 1. Fungsi yang ada di FLASHPRO

| Fungsi | Param | Dugaan peran | Algoritma |
|---|---:|---|---|
| `Checksum8Bit` | 3 | checksum 8-bit generik | NOT VERIFIED |
| `Checksum8BitHonda` | 3 | varian Honda | NOT VERIFIED |
| `Sum8Bit` | 3 | penjumlahan 8-bit | NOT VERIFIED |
| `Sum32Bit` | 3 | penjumlahan 32-bit | NOT VERIFIED |
| `ValidateChecksum` | 2 | validasi respons (DTC) | NOT VERIFIED |
| `ShindengenAutoChecksum` | 1 | checksum image Shindengen | NOT VERIFIED |
| `KeihinAutoChecksum` | 1 | checksum image Keihin | NOT VERIFIED |

Tiga parameter konsisten dengan *(buffer, offset, panjang)*, tetapi susunan sebenarnya tidak diketahui.

## 2. Kontrol pengguna

- `TbChecksumOffset` + `ChecksumOffset_Changed` → lokasi checksum dapat diatur manual.
- `TbStartOffset` + `StartOffset_Changed` → awal area hitung/tulis.
- `CbFastWrite` → mode tulis cepat (kemungkinan melewati verifikasi; hipotesis).
- `TxtFlashCount` → penghitung flash yang dapat direset.

Adanya offset manual berarti checksum **tidak selalu** otomatis dari tabel internal; untuk ECU tak dikenal pengguna memasukkan offset sendiri. Ini toleransi lapangan, bukan bukti kecerdasan algoritma.

## 3. Kapan dijalankan

Urutan nama metode (bukan urutan eksekusi terverifikasi):

```
PreWriteFlash (Keihin/Shindengen)
  → Erasing flash
  → WriteFlash
  → CompareMemory
  → AutoChecksum (Keihin/Shindengen)
```

Pesan: `Verifikasi Data...`, `Verify ...`, `WRITE FLASH COMPLETE`, `Writing Data Completed Result = GOOD`, `... BAD!!`. Tidak ada pesan "checksum mismatch" terpisah; kegagalan checksum tampaknya dilaporkan sebagai hasil tulis BAD — **inferensi**.

## 4. Untuk DTC

`Diag` memanggil `ValidateChecksum(arr, len)` + `Checksum8BitHonda(...)` sebelum menampilkan kode. Respons DTC memiliki checksum internal; bila gagal, data tidak ditampilkan (`Data kosong`/`Error decoding data`).

## 5. Yang tidak dapat diklaim

- Tidak ada polinomial, initial value, endianness, atau rentang alamat yang terbukti.
- Tidak ada sampel sebelum/sesudah dari ECU nyata.
- Tidak ada bukti `Checksum8BitHonda` FLASHPRO identik dengan implementasi RevCore.

## 6. Sisi RevCore (prototipe FASE VI)

Empat tipe checksum image RevCore ditambah checksum frame SUM8 diuji dan lulus:

| Algoritma | Vektor | Hasil |
|---|---|---|
| SUM8 dua-komplemen | `[01 02 03]` | `FA`; total frame 0 |
| Keihin 16-bit add | `[12 34 56 78]` | `68AC` |
| Inverted 8-bit | `[00]/[FF]/[01 02]` | `FF/00/FC` |
| CRC-16 (seed `FFFF`, poly `A001`) | `"123456789"` | `4B37` |
| Additive 16-bit | `[FF FF]` | `01FE` |

Ini membuktikan **implementasi RevCore** berjalan sesuai parameter, bukan bahwa FLASHPRO memakai algoritma yang sama.

## 7. Jalan menuju verifikasi

1. Siapkan ≥3 image BIN Honda valid per keluarga.
2. Hitung kandidat algoritma pada offset yang masuk akal.
3. Bandingkan dengan nilai tersimpan di image.
4. Baru setelah cocok 3/3, naikkan status ke SIMULATION VERIFIED.

Tanpa langkah ini, klaim "mendukung checksum Honda" tetap klaim permukaan.
