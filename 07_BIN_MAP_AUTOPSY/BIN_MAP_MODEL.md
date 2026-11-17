# Model BIN & Map — Struktur Data, Offset, dan Format Simpan

**Status:** SOURCE VERIFIED (model data & operasi) · isi BIN/ROM: **NOT FOUND** (tidak ada file BIN nyata di workspace) · algoritma terenkripsi: **NOT VERIFIED**.

---

## 1. Dua hal yang harus dipisahkan

| Aktivitas | Bukti | Arti |
|---|---|---|
| **Buka/simpan file** `.bin` / `.map` | `openFileToolStripMenuItem`, `SaveBinBytesWithDialog`, `SaveBytesWithDialog` | manipulasi file di PC |
| **Baca/tulis ROM ECU** | `ReadECU.Read48`, `Form1.WriteFlash`, `CompareMemory` | komunikasi ke ECU |

Keduanya memakai buffer yang sama (`binBytes`), tetapi jalurnya berbeda. Membuka `.bin` **tidak** berarti membaca ECU; menekan Write **tidak** membuktikan tulisan berhasil (bukti keberhasilan adalah `CompareMemory` + pesan `WRITE FLASH COMPLETE`).

## 2. Buffer & undo

Field `Form1`:

```
byte[] binBytes        // buffer kerja
byte[] binBytesORI     // salinan asli (untuk compare/reset)
Stack<byte[]> undoStack, redoStack   // snapshot seluruh buffer
string openedFilePath
int selectedStartAddress, startAddress, startAddress2, startAddress3
int columnCount, rowCount
```

Undo/redo menyimpan **salinan penuh** buffer, bukan sel — konsisten dengan `SaveState()` sebelum edit.

## 3. Model tabel map

Setiap profil ECM mendefinisikan offset (Int32) untuk:

- Sumbu: `tpsh`, `rpmh`, `iaph` (breakpoint TPS/RPM/IAP)
- Bahan bakar: `feul1`, `feul2`, `feul3` (+ `iap`)
- Pengapian: `ig1`..`ig4`
- Limiter: `limit1`..`limit7`
- Switch/flag: `o2/o2mask`, `o2c/o2cmask`, `immo/immomask`, `mode0`..`mode4`, `bass`, `iacv`, `ect`, `iat`, `vss`, `mapp` (+ mask)
- Skala: `konversrpm`, `konversilmtr` (Single)

Nilai sel dikonversi 16-bit: `ConvertUShortToValue`, `ConvertValueToUShort` (dan varian `2`), dengan `Clamp`. Jadi sel map adalah **word (2 byte) little-endian** dengan skala/offset per tabel — **detail skala per parameter NOT VERIFIED**.

Tabel 3D dibentuk dari breakpoint × breakpoint; `CreateTable`, `DisplayData`, `TPSBREAK`, `RPMBREAKPOIN`, `IAPBREAK`, `ukuran/2/3` menentukan dimensi.

## 4. Operasi edit yang tersedia

| Operasi | Metode / string |
|---|---|
| Tambah/kurangi nilai | `TambahNilai`, `KurangiNilai`, `Tambah Value`, `Kurangi Value` |
| Persentase | `Tambah Value (%)`, `Kurangi Value (%)` |
| Isi/flatten | `Fill / Set Value`, `isivom` |
| Interpolasi | `TambahNilaiInterpolasi`, `Interpolasi (%)` |
| Kali/bagi | `KaliNilai`, `BagiNilai` |
| Copy/paste blok | `CopySelectedCells`, `PasteDataToSelectedCells`, Ctrl+C/V |
| Bandingkan | `COMPARE MODE ON`, `compare_Click`, `CompareValues` |
| Auto-map | `Automaping_Click_1`, `compareToDataBaseToolStripMenuItem` |
| Simpan nilai | `SaveEditedValues(2)`, `Save Value` |

`Eval` (kompilasi C# runtime) memungkinkan sel diisi ekspresi matematis — fitur produktivitas, bukan bagian protokol.

## 5. Format file `.map`

- Menu **Maping** menyimpan `.map` (`Map File (*.map)|*.map`), dengan parameter `Stride`/`MinorStride` (dari metadata Form1).
- Ada `EncryptBytes` / `DecryptBytes2`, literal `SHA256`, dan sepasang kunci AES hardcoded 16-byte.
- Kesimpulan terverifikasi: file `.map` **bukan** dump mentah; ia kontainer terenkripsi + metadata (hash). Format persisnya sudah dipetakan di sisi RevCore (`MapCrypto.kt`), tetapi untuk laporan ini cukup: **terenkripsi, tidak dapat dibaca tanpa kunci**.
- Apakah `.bin` yang disimpan juga dienkripsi: **tidak terbukti** (kedua jalur memakai `EncryptBytes`, tetapi pemanggilnya tidak dapat dipastikan tanpa IL).

## 6. Database 160 BIN

- 160 nama `FLASHPRO.*.bin` + 157 part code unik.
- `ReadEmbeddedXml` dan resource `public_encrypted` menunjukkan database/profil dibawa sebagai resource terenkripsi.
- Nama file mengikuti pola `MERK MODEL-TAHUN-PARTCODE[-STAGE].bin`; ada varian `ORIGINAL`, `STD`, `STAGE-01`, dan `read`/`READ`.
- Isi BIN **tidak ada** di workspace → ukuran image, alamat, dan checksum internal: **NOT FOUND**.

## 7. Read ECU 48 KB

`ReadECU.Form`: tombol baca, hex viewer, `READING DATA FROM MCU`, progress, simpan `.bin` (`Reading data from mcu`, `Data berhasil disimpan ke:`), log `read48k.log`.
`Read48` membaca **48 KB** dalam beberapa permintaan; `Extract14to25` mengambil 12 byte dari tiap respons (kandidat area identifikasi). Apakah 48 KB adalah seluruh flash atau sebagian: **NOT VERIFIED**.

## 8. Batas yang ditegaskan

- Tidak ada ROM/BIN nyata yang dianalisis di BE-12; seluruh pernyataan tentang isi berasal dari nama, offset, dan metode.
- Tidak ada pembacaan/penulisan ECU nyata.
- Tidak ada klaim checksum internal BIN; itu ada di `08_CHECKSUM_AUTOPSY` dan statusnya nama-saja.
