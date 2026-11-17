# 02 — INVENTARIS FILE

**Work order:** BE-12
**Status:** STATIC VERIFIED
**Sumber:** `00_SOURCE_INVENTORY/FLASHPRO_FILE_INVENTORY.csv`, `PROVENANCE.md`, `WRAPPER_LAYOUT_VERIFIED.csv`

---

## 1. Tujuh file terpasang

| File | Ukuran (B) | SHA-256 (ringkas) | Peran |
|---|---:|---|---|
| `FLASHPRO.exe` | 33.460.372 | `bf56b69a…` | Wrapper VB6 + payload 33.321.984 B |
| `AUTO UPDATE.exe` | 9.810.157 | `5b6eac0b…` | Wrapper VB6 + payload 9.671.680 B |
| `unins000.exe` | 3.831.646 | `2c8bb3dc…` | Wrapper VB6 + uninstaller Inno 3.693.285 B |
| `flashpro.exe`+U+00A0 | 33.321.984 | `9fafdc8e…` | Payload asli (salinan) |
| `DotNetZip.dll` | 472.064 | `8e9c0362…` | Ionic DotNetZip 1.16, MSIL, unsigned |
| `unins000.dat` | 5.537 | `26150ebf…` | Data uninstaller Inno |
| `lastimage.txt` | 67 | `f39f9ba6…` | Path PNG background |

Catatan nama: `flashpro.exe` sebenarnya berakhiran **U+00A0 (NBSP)**, bukan spasi biasa. Win32 menormalkan nama sehingga file perlu diakses melalui salinan kerja `flashpro_nbsp.exe`.

## 2. Format wrapper (terverifikasi pada 3 EXE)

```text
[0 .. 122.880)         stub PE32 VB6 (3 seksi)
[122.880 .. +N)        filler periodik 256 B
[+0 .. +25)            header 25 B: u16 N, 0x0000, 0x0E10, 19 B data
[+25 .. +25+payload)   executable asli (MZ/PE)
[+25+payload .. +25)   trailer 25 B: u32 panjang, 0x0E10, 20 B data
```

Invarian yang diuji dan cocok untuk ketiga file:

- `payload_offset = 122.880 + N + 25`;
- filler tepat periodik 256 B;
- `u16` header +4 = `0x0E10`; `u16` trailer +4 = `0x0E10`;
- `u32` trailer +0 = panjang payload;
- `file_size = 122.880 + N + 25 + payload + 25`.

| File | N | Payload (B) | Payload SHA-256 | vs installer |
|---|---:|---:|---|---|
| `FLASHPRO.exe` | 15.458 | 33.321.984 | `9fafdc8e…` | EXACT MATCH |
| `AUTO UPDATE.exe` | 15.547 | 9.671.680 | `181db74b…` | EXACT MATCH |
| `unins000.exe` | 15.431 | 3.693.285 | `7392f14a…` | N/A (installer tidak tersedia) |

Verifikasi otomatis: `verify_wrapper.ps1` → `WRAPPER_LAYOUT_VERIFIED.csv` (semua boolean `True`).

## 3. Apa yang tidak ada di folder

Tidak ditemukan:

- file BIN/ROM Honda;
- file `.map` contoh;
- log `read48k.log` aktual;
- konfigurasi ECU pengguna;
- database terpisah (database tampaknya berada di resource `public_encrypted` di dalam payload);
- private key, keygen, atau aktivator (dan tidak dicari/dibuat).

## 4. Artefak sensitif yang dikecualikan

Di luar folder instalasi terdapat artefak Enigma lokal (project berisi private key, keygen, salinan termodifikasi). Artefak itu **tidak disalin, tidak dianalisis, dan tidak akan dipublikasikan**. Keberadaannya hanya dicatat di `PROVENANCE.md §9`.

## 5. Peringatan distribusi

`00_SOURCE_INVENTORY/APP_COPY` berisi binary pihak ketiga (FLASHPRO, payload, uninstaller) dan **tidak boleh dipublikasikan**, tidak boleh dimasukkan ZIP final, dan tidak boleh dipindahkan ke repositori. Laporan publik hanya memuat hash, metadata, dan temuan.

## 6. Integritas

- Hash ketujuh file dicatat pada FASE 0.
- E01 mencatat hash `FLASHPRO_original.exe`, `DotNetZip.dll`, dan `lastimage.txt` sebelum/sesudah; ketiganya **identik**.
- Tidak ada file instalasi yang diubah selama BE-12; semua eksperimen memakai salinan kerja.
