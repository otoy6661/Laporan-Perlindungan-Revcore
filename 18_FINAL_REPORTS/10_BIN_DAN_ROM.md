# 10 — BIN DAN ROM

**Work order:** BE-12
**Status:** SOURCE VERIFIED (model & operasi) · isi BIN/ROM **NOT FOUND** · algoritma **NOT VERIFIED**
**Sumber:** `07_BIN_MAP_AUTOPSY/BIN_MAP_MODEL.md`

---

## 1. Dua aktivitas yang harus dipisahkan

| Aktivitas | Bukti | Arti |
|---|---|---|
| Buka/simpan file `.bin`/`.map` | `openFileToolStripMenuItem`, `SaveBinBytesWithDialog` | manipulasi file di PC |
| Baca/tulis ROM ECU | `ReadECU.Read48`, `WriteFlash`, `CompareMemory` | komunikasi ke ECU |

Keduanya memakai buffer yang sama (`binBytes`), tetapi jalurnya berbeda. Membuka `.bin` **bukan** membaca ECU; menekan Write **bukan** bukti tulisan berhasil. Bukti keberhasilan tulis adalah `CompareMemory` + `WRITE FLASH COMPLETE`.

## 2. Buffer & undo

```text
byte[] binBytes        buffer kerja
byte[] binBytesORI     salinan asli
Stack<byte[]> undoStack, redoStack
string openedFilePath
int selectedStartAddress, startAddress/2/3
int columnCount, rowCount
```

Undo/redo menyimpan **salinan penuh** buffer, bukan per sel — konsisten dengan `SaveState()` sebelum edit.

## 3. Baca 48 KB

`ReadECU.Read48` membaca blok **48 KB** dari MCU dalam beberapa permintaan; `Extract14to25` mengambil 12 byte dari tiap respons (kandidat area identifikasi). UI: tombol baca, hex viewer, `READING DATA FROM MCU`, progres, simpan `.bin` (`Data berhasil disimpan ke:`), log `read48k.log`.

Apakah 48 KB adalah seluruh flash atau sebagian: **NOT VERIFIED**. Ukuran flash ECU Honda umumnya lebih besar; 48 KB mungkin hanya region kalibrasi, tetapi ini hipotesis.

## 4. Model offset

Setiap profil ECM mendefinisikan offset Int32 untuk:

- sumbu: `tpsh`, `rpmh`, `iaph`;
- bahan bakar: `feul1..3` (+ `iap`);
- pengapian: `ig1..4`;
- limiter: `limit1..7`;
- switch/flag: `o2/o2mask`, `o2c/o2cmask`, `immo/immomask`, `mode0..4`, `bass`, `iacv`, `ect`, `iat`, `vss`, `mapp`;
- skala: `konversrpm`, `konversilmtr`.

Sel map adalah **word 16-bit little-endian** (`ConvertUShortToValue`, `ConvertValueToUShort`), dengan skala/offset per tabel. Detail skala per parameter **NOT VERIFIED**.

## 5. Database 160 BIN

- 160 nama `FLASHPRO.*.bin`; 157 part code unik.
- Pola nama: `MERK MODEL-TAHUN-PARTCODE[-STAGE].bin`, varian `ORIGINAL`, `STD`, `STAGE-01`, `read`/`READ`.
- `ReadEmbeddedXml` + resource `public_encrypted` menunjukkan database dibawa sebagai resource terenkripsi.
- **Isi BIN tidak ada di workspace** → ukuran image, alamat, dan checksum internal **NOT FOUND**.

## 6. Batas

- Tidak ada ROM/BIN nyata yang dianalisis di BE-12.
- Tidak ada pembacaan/penulisan ECU nyata.
- Tidak ada klaim checksum internal BIN; itu dibahas di laporan 12 dan statusnya nama-saja.
- Membuka dan menyimpan file **tidak sama** dengan membaca dan menulis ROM ECU.
