# BE-10 — RELASI BIN, XDF, DAN ADX

**Tujuan:** menjelaskan bagaimana tiga format dalam dataset berhubungan, apa yang sudah terbukti, dan apa yang masih tertutup.

---

## 1. Tiga format, tiga peran

| Format | Peran | Akses | Status BE-10 |
|---|---|---|---|
| **BIN** | Image firmware linear; tabel map berada pada offset file | Terbuka | **STATICALLY_ANALYZED** + **SAMPLE_TEST_PASSED** |
| **XDF** | Definisi tabel/axis untuk TunerPro | Terbuka (unlocked) / terkunci (locked) | **STATICALLY_ANALYZED** (struktur); isi locked **BLOCKED_BY_ACCESS_REQUIREMENT** |
| **ADX** | Kontainer definisi terkunci dengan tag famili | Tertutup | **STATICALLY_ANALYZED** (kontainer); isi **BLOCKED_BY_ACCESS_REQUIREMENT** |

---

## 2. BIN

- Ukuran yang ditemukan di aplikasi 3D: 49.152; 65.536; 262.144; 393.216 byte (154 file).
- Tidak ada header kontainer; offset tabel dipakai langsung sebagai offset file.
- Tabel bahan bakar `uint16` row-major, `rows = RPM`, `cols = TPS`; TPS `raw/10`, RPM `raw/kon`, fuel `raw/1000`.
- Default little-endian; tabel pada `0x3A804`, `0x3A258`, `0x3911C`, `0x396C8` dibaca big-endian.

Validasi BE-10: 5 BIN nyata, 5/5 `SAMPLE_TEST_PASSED` (lihat `BE10_TABLE_VALIDATION.csv`). Ini membuktikan BIN dapat dibaca **tanpa XDF/ADX**, hanya dengan database offset.

---

## 3. XDF

Dari BE-09 (baseline, tidak diulang): 161 XDF terkunci, 13 XDF terbuka; 287 tabel terdefinisi di 13 XDF terbuka; format 1.60/1.70; axis bertipe link harus dibaca dari tabel target.

BE-10 menambahkan bukti struktural:

- XDF terkunci memakai magic yang sama dengan ADX: `05 22 97 00`.
- Prefix **132 byte** (`0x000–0x083`) identik dengan ADX: magic, 127 nol, byte `0x64`.
- Empat byte nol di `0x104–0x107` juga sama.
- Di `0x108` keduanya berpisah tajam:
  - ADX: blok konstan 43 byte + tag famili.
  - XDF: data high-entropy tanpa blok konstan/tag.

Kesimpulan: **ADX dan XDF terkunci satu keluarga kontainer**, tetapi ADX bukan sekadar "XDF dengan ekstensi lain". Perbedaan blok 43 byte + tag harus diperlakukan sebagai varian format.

Status: **STATICALLY_ANALYZED**.

---

## 4. ADX

- 3 file, 2 konten unik; KEIHIN `0x03`, SHINDENGEN `0x02`.
- Blok konstan 43 byte identik; payload 39.891 / 23.472 byte; entropy ~7,99.
- Tidak ada signature kompresi di awal payload.
- Tidak ada referensi ADX di source 3D Chart Graph.

Status: kontainer **STATICALLY_ANALYZED**; isi **BLOCKED_BY_ACCESS_REQUIREMENT**.

---

## 5. Matriks relasi

| Relasi | Bukti | Status |
|---|---|---|
| BIN → tabel map | 5 BIN, offset database, termasuk BE | **SAMPLE_TEST_PASSED** |
| BIN → XDF | BE-09: contoh K1AA tervalidasi; XDF unlocked memakai offset file yang sama | **FOUND_IN_DOCUMENTATION** (BE-09) |
| XDF → ADX | Prefix 132 byte sama; divergensi `0x108` | **STATICALLY_ANALYZED** |
| ADX → BIN | Tidak ada pemetaan yang bisa dibuktikan tanpa dekripsi | **BLOCKED_BY_ACCESS_REQUIREMENT** |
| 3D app → ADX/XDF | Tidak ada referensi | **NOT_FOUND_AFTER_MEANINGFUL_SEARCH** |
| 3D app → BIN | 154 BIN tertanam + database offset | **FOUND_IN_SOURCE** |

---

## 6. Interpretasi praktis

1. **BIN adalah sumber kebenaran.** Semua tabel yang berhasil dibaca berasal dari BIN; XDF/ADX hanyalah definisi.
2. **XDF unlocked** dapat dipakai sebagai kamus offset/nama tabel; **XDF locked** tidak.
3. **ADX tidak dapat dipakai** untuk memetakan BIN tanpa kunci/dekripsi. Jangan membangun fitur yang mengasumsikan ADX terbaca.
4. **Duplikasi ADX** harus dideteksi dengan hash, bukan nama file, karena nama bisa sama di dua folder.
5. **Jangan menebak** bahwa tag `0x03`/`0x02` adalah versi format; korelasi dengan nama famili cukup untuk identifikasi, bukan untuk spesifikasi.

---

## 7. Rekomendasi untuk RevCore

- Dukung **BIN + XDF unlocked** sebagai jalur utama.
- Untuk ADX: hanya inspeksi metadata (magic, ukuran, hash, tag) dan tampilkan sebagai "opaque/unsupported".
- Pisahkan registry offset per model (dari database 3D) dari parser XDF; keduanya bisa saling melengkapi.
- Simpan hash sebelum/sesudah operasi tulis untuk audit.

---

## 8. Evidensi

- `ANALYSIS\ADX_XDF_LAYOUT_PROOF.txt`
- `PROTOTYPES\RESULTS\BE10_TABLE_VALIDATION.csv`
- `BE10_ADX_ANALYSIS.md`, `BE10_3D_CHART_SOURCE_ANALYSIS.md`
- BE-09: `BE09_FINAL_RESEARCH_REPORT.md`, `TECHNICAL_FINDINGS\BIN_XDF_MAPPING_EXAMPLES.md`
