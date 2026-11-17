# Catatan Publikasi — Apa yang Disertakan, Disamarkan, dan Dikecualikan

**Tujuan:** transparansi penuh atas proses publikasi. Tidak ada temuan, kesimpulan, metode, atau bukti analitis yang dihilangkan. Yang dikecualikan hanya materi yang memang di luar izin distribusi (biner pihak ketiga) dan data yang wajib disamarkan menurut work order (PII vendor, password, salt, literal kripto).

**Tanggal:** 2026-11-18 · **Sumber:** `C:\Users\<USER>\Documents\REVCORE_BE12_FLASHPRO_AUTOPSY` (tidak diubah)

---

## 1. Disertakan (132 file)

- 19 folder tematik (`00_SOURCE_INVENTORY` … `18_FINAL_REPORTS`), seluruh 22 laporan final, register bukti, coverage matrix, prototype + hasil uji, skrip PowerShell, dump metadata tekstual (tipe/metode/field/memberref), katalog string teredaksi, katalog BIN/DTC/part code, screenshot UI.
- `PUBLICATION_MANIFEST.csv` — ukuran dan SHA-256 setiap file lain yang dipublikasikan (termasuk catatan ini), agar isi repositori dapat diverifikasi.
- Semua hash SHA-256, timeline, tabel PE, katalog string, dan angka hasil uji tetap apa adanya.

## 2. Dikecualikan dari publikasi

| Kategori | File | Alasan |
|---|---|---|
| Biner pihak ketiga | `00_SOURCE_INVENTORY/APP_COPY/*` (8 file: 3 wrapper EXE, salinan payload, `AUTO UPDATE.exe`, `unins000.exe`, `DotNetZip.dll`, `lastimage.txt`, `unins000.dat`) | Tidak ada hak distribusi; hash & metadata tetap dipublikasikan di inventaris |
| Biner kerja | `12_EXPERIMENTS/E01_FIRST_LAUNCH/APP/FLASHPRO_original.exe`, `DotNetZip.dll`, `lastimage.txt` | Sama; hanya salinan kerja |
| Dump biner | `MOD_1_metadata.bin` (235.832 B), `02_STATIC_ANALYSIS/RESOURCES_*/*.bin` | Bukan teks; hash/ukuran sudah tercatat |
| Output build | seluruh `bin/`, `obj/` (ClrProbe, PeScope) | Artefak kompilasi, dapat direproduksi dari source yang disertakan |
| Dump string mentah | `STRINGS_FLASHPRO.exe.txt`, `STRINGS_flashpro_nbsp.exe.txt`, `STRINGS_AUTO UPDATE.exe.txt`, `MOD_1_userstrings.txt`, `US_ONLY.txt` | Memuat seluruh tabel string tanpa saring, termasuk PII vendor; digantikan `STRINGS_REDACTED.txt` + `STRING_CATALOG.md` |

## 3. Disamarkan di dalam file yang dipublikasikan

Berlaku pada `03_RUNTIME_ANALYSIS/E01_FIRST_LAUNCH/STRINGS_REDACTED.txt` (satu-satunya dump string yang dipublikasikan) dan, untuk nama pengguna host, pada seluruh file teks:

| Data | Pengganti | Alasan |
|---|---|---|
| Alamat email dukungan vendor | `[REDACTED_EMAIL]` | PII |
| Nomor WhatsApp/telepon vendor | `[REDACTED_PHONE]` | PII |
| Tautan `wa.me` | `[REDACTED_PHONE]` | PII |
| Password ZIP updater | `[REDACTED_UPDATE_PASSWORD]` | Rahasia; nilai tidak diperlukan untuk temuan |
| Salt lisensi | `[REDACTED_LICENSE_SALT]` | Rahasia |
| Empat literal kripto hardcoded | `[REDACTED_CRYPTO_LITERAL]` | Kebijakan work order: nilai tidak direproduksi; keberadaannya tetap dilaporkan |
| Nama pengguna Windows pada path bukti | `<USER>` | PII host; path relatif tetap terbaca |

Semua temuan tentang keberadaan, lokasi baris, dan fungsi data tersebut **tetap dilaporkan** (lihat `STRING_CATALOG.md`). Yang dihilangkan hanya nilai literalnya, bukan kesimpulannya.

## 4. Tidak ada yang lain

Tidak ada laporan yang dipangkas, tidak ada status bukti yang dinaikkan, tidak ada angka yang diubah. Jika sebuah klaim berstatus `NOT TESTED`/`BLOCKED`/`NOT FOUND` di workspace asli, status itu sama di repositori ini.
