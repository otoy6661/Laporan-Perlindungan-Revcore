# BE-10 — ANALISIS MENDALAM ADX

**Work Order:** BE-10 — Deep Technical Research (ADX + 3D Chart Graph + ECU Software)
**Tanggal:** 17 November 2026
**Ruang kerja:** `C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH`
**Sumber:** `...\REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX\ADX-D2 TECH` (2 file), `...\FILE BIN XDF ADX` (duplikat + arsip 7z)

---

## 1. Ringkasan

Folder `ADX-D2 TECH` berisi **dua file ADX yang berbeda**, bukan salinan satu sama lain:

| File | Ukuran | SHA-256 | Tag keluarga |
|---|---:|---|---|
| `ADX KEIHIN BE.adx` | 40.199 | `6b1d9b97d1db76fc6e600bba305230991628008cad57edf9276816bb5dda7a85` | `0x03` |
| `ADX SHINDENGEN BE.adx` | 23.780 | `c3df2e7817e890c27a40cca32ead33c3e6cb7affae5a6d96a9cfe867cc51e249` | `0x02` |

Di luar folder itu ditemukan:

- `FILE BIN XDF ADX\ADX KEIHIN BE.adx` — **byte-identical** dengan file KEIHIN di `ADX-D2 TECH` (hash sama).
- `FILE BIN XDF ADX\ADX KEIHIN BE.7z` — arsip 7-Zip (LZMA2) berisi satu file `ADX KEIHIN BE.adx` 40.199 byte; setelah diekstrak ke `EXTRACTED_ARCHIVES\ADX_KEIHIN_7Z`, hash-nya juga `6b1d9b97…`.

Kesimpulan identifikasi: **3 file ADX + 1 arsip = 2 konten unik**. Tidak ada ADX ketiga yang tersembunyi di folder yang diminta.

Status: **STATICALLY_ANALYZED** untuk struktur kontainer; **BLOCKED_BY_ACCESS_REQUIREMENT** untuk isi terenkripsi.

---

## 2. Tata letak kontainer (terbukti dari byte)

Kedua ADX memiliki tata letak yang sama sampai batas tag; yang berbeda hanya nilai tag dan panjang payload.

| Offset | Panjang | Isi | Bukti |
|---|---:|---|---|
| `0x000` | 4 | Magic `05 22 97 00` | Kedua file |
| `0x004` | 127 | Nol | Kedua file; byte nonnol pertama di `0x083` |
| `0x083` | 129 | Metadata terenkripsi (high-entropy) | `0x083` = `0x64` pada kedua file |
| `0x104` | 4 | Nol | `00 00 00 00` |
| `0x108` | 43 | Blok konstan 43 byte | Identik pada kedua file |
| `0x133` | 1 | Tag keluarga | `0x03` KEIHIN, `0x02` SHINDENGEN |
| `0x134` | sisa | Payload terenkripsi | 39.891 byte (KEIHIN), 23.472 byte (SHINDENGEN) |

Blok konstan 43 byte (`0x108–0x132`), identik pada kedua file:

```
25 A5 9E 70 F5 74 90 15 B9 D0 45 60 38 BE 47 C5
29 51 79 36 F5 89 52 EB 9C 85 DC 0F 61 A6 A5 77
06 43 C2 C5 6F A1 75 67 33 70 15
```

Perbedaan byte di rentang `0x108–0x132` antara kedua file: **tidak ada** (`BLOCK_DIFF_OFFSETS=` kosong pada `ANALYSIS\ADX_XDF_LAYOUT_PROOF.txt`). Perbedaan pertama setelah blok adalah tag di `0x133`.

### 2.1 Bukti perhitungan

- Entropy payload KEIHIN: **7,9954 bit/byte** (maksimum 8,0).
- Entropy payload SHINDENGEN: **7,993** (dari test `ADX-02`).
- Printable ratio payload KEIHIN: **0,3752** — konsisten dengan data acak/terenkripsi, bukan teks.
- Tidak ada signature kompresi di awal payload: zlib (`78 9C/DA/01`), gzip (`1F 8B`), ZIP (`50 4B 03 04`) semuanya **false**.

Catatan metodologis: pemeriksaan kompresi **hanya** dilakukan pada awal payload. Pemindaian seluruh file pernah menghasilkan positif palsu karena ciphertext acak dapat memuat urutan `78 9C`; cara itu dibuang. Ini penting agar tidak melaporkan "terkompresi" tanpa dasar.

---

## 3. Hubungan ADX dengan XDF terkunci

Dibandingkan dengan XDF terkunci `BIN & XDF\ADV\30400-K0WA-N01.xdf` (57.721 byte):

- **Prefix 132 byte identik** (`0x000–0x083`): magic `05 22 97 00`, 127 byte nol, lalu byte `0x64` di `0x083`.
- Keduanya memiliki empat byte nol di `0x104–0x107`.
- Di `0x108` keduanya **berpisah**:
  - ADX: blok konstan 43 byte di atas.
  - XDF: langsung data high-entropy `25 C5 F7 05 93 6C B0 31 8C F0 00 78 7D FC 00 83 …`; tidak ada blok konstan dan tidak ada tag keluarga.

Ini membuktikan ADX dan XDF terkunci **berasal dari keluarga kontainer TunerPro yang sama** (magic dan header awal sama), tetapi ADX menambahkan blok konstan + tag famili sebelum payload. XDF terkunci tidak memiliki penanda famili tersebut.

Status: **STATICALLY_ANALYZED** (hubungan struktural). Isi kedua format tetap tidak didekripsi.

---

## 4. Apa yang tidak diketahui

| Pertanyaan | Status | Alasan |
|---|---|---|
| Cipher yang dipakai | `UNKNOWN_AFTER_ANALYSIS` | Tidak ada kode dekripsi di sumber yang dianalisis; payload tidak menunjukkan struktur plaintext. |
| Asal kunci | `BLOCKED_BY_ACCESS_REQUIREMENT` | Tidak ada key material yang boleh/sempat dianalisis; menebak kunci = fabrikasi. |
| Format metadata 129 byte | `UNKNOWN_AFTER_ANALYSIS` | High-entropy; tidak ada field yang dapat diverifikasi. |
| Arti tag `0x03`/`0x02` | `FOUND_IN_SOURCE` (korelasi) | Berkorelasi dengan nama file KEIHIN/SHINDENGEN, tetapi tidak ada dokumentasi resmi. |
| Apakah payload berisi XDF di dalamnya | `UNKNOWN_AFTER_ANALYSIS` | Tidak dapat dibuktikan tanpa dekripsi. |
| Apakah ADX dipakai oleh 3D Chart Graph | `NOT_FOUND_AFTER_MEANINGFUL_SEARCH` | Tidak ada referensi `.adx`/`.xdf` di seluruh source dan project file. |

Yang **tidak** dilakukan: dekripsi, brute force, key recovery, menjalankan tool berlisensi, atau mengklaim isi ADX. Semua di luar batas work order dan etika.

---

## 5. Prototipe dan pengujian

Prototipe: `PROTOTYPES\src\BE10Tools\Adx\AdxInspector.cs` — inspektur statis, tanpa dekripsi.

Yang dihitung: magic, batas header, offset/length payload, blok 43 byte, tag, entropy, printable ratio, signature kompresi di awal payload, SHA-256.

Hasil (`PROTOTYPES\RESULTS\SELFTEST.txt`, `BE10_PROTOTYPE_TESTS.csv`):

| ID | Hasil | Ringkas |
|---|---|---|
| ADX-01 | `SAMPLE_TEST_PASSED` | KEIHIN: magic true, header `0x83`, payload 39.891, tag `0x03`, entropy 7,995, printable 0,3752, prefix43 sama dengan SHINDENGEN, tanpa kompresi |
| ADX-02 | `SAMPLE_TEST_PASSED` | SHINDENGEN: payload 23.472, tag `0x02`, entropy 7,993 |
| ADX-03 | `SAMPLE_TEST_PASSED` | SHA-256 kedua file tidak berubah sebelum/sesudah seluruh pekerjaan |

Hash input dan output identik pada ketiga tes — tidak ada file sumber yang dimodifikasi.

---

## 6. Implikasi untuk RevCore

1. **Perlakukan ADX sebagai opaque.** Jangan menambahkan parser ADX yang mengklaim membaca isi. Yang aman hanya inspeksi kontainer (magic/tag/ukuran/hash) untuk identifikasi dan provenance.
2. **Deteksi duplikat** dapat dilakukan dengan SHA-256; ini sudah terbukti (3 file → 2 unik).
3. **Jangan campur ADX dengan XDF.** ADX bukan XDF terenkripsi sederhana; ia punya blok konstan dan tag famili. Menebak sebaliknya akan menghasilkan bug.
4. **Jika pemilik ingin membuka ADX**, itu memerlukan keputusan terpisah, alat resmi/berlisensi, dan izin tertulis. Work order ini berhenti di batas kontainer.

---

## 7. Evidensi

- `ANALYSIS\ADX_XDF_LAYOUT_PROOF.txt` — dump offset, blok 43 byte, tag, payload, perbandingan prefix XDF.
- `ANALYSIS\ADX_BYTE_SCAN.txt` — entropy, string scan, header 512 byte.
- `ANALYSIS\adx_block.ps1` — skrip pembuktian blok/tag/entropy.
- `PROTOTYPES\RESULTS\BE10_PROTOTYPE_TESTS.csv` — ADX-01..03.
- `REPORTS\BE10_SHA256_MANIFEST.csv` — hash sumber ADX dan salinan uji.
