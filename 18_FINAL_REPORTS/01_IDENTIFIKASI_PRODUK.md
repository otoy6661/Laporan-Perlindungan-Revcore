# 01 — IDENTIFIKASI PRODUK

**Work order:** BE-12 — FLASHPRO.inc Full Autopsy & Three-Way Technical Comparison
**Status:** STATIC VERIFIED + RUNTIME VERIFIED (metadata/startup) · perilaku ECU **BLOCKED**
**Sumber utama:** `00_SOURCE_INVENTORY/PROVENANCE.md`, `FLASHPRO_FILE_INVENTORY.csv`, `01_APPLICATION_ANATOMY/ARCHITECTURE.md`

---

## 1. Apa yang sebenarnya terpasang

FLASHPRO yang terpasang di `C:\Program Files (x86)\FLASHPRO.inc` **bukan satu executable tunggal**. Tiga file EXE adalah **wrapper VB6** yang membawa executable asli sebagai payload di overlay:

| Lapisan | Isi | Ukuran | Status |
|---|---|---:|---|
| Wrapper | PE32 x86, VB6 (`MSVBVM60.DLL`), `TJprojMain` 1.00, `Project1`, unsigned, manifest `requireAdministrator` | 122.880 B stub | STATIC VERIFIED |
| Payload utama | PE32+ x64, 5 seksi (4 RWX), Enigma Protector 5.x, entropi ~7,9998 | 33.321.984 B | STATIC VERIFIED |
| Isi payload | .NET Framework 4.8 WinForms, assembly `FLASHPRO` v0.0.1.6 | metadata 235.832 B | RUNTIME VERIFIED |

Payload **byte-identik** dengan `{app}\FLASHPRO.exe` dari installer (SHA-256 `9fafdc8e795b2809cc02356bb2d4f5e79432fa3f72ab65ff7a8b56039bd02eb3`). Jadi yang dianalisis adalah **build vendor asli**, bukan hasil patch.

## 2. Identitas vendor

| Atribut | Nilai | Bukti |
|---|---|---|
| ProductName | `Team Tech Tunner` | VERSIONINFO payload |
| CompanyName | `itech` | VERSIONINFO payload |
| FileVersion | `0.0.1.6` | VERSIONINFO + metadata assembly |
| Deskripsi | `FLASHPRO` | VERSIONINFO |
| Timestamp PE | `2026-05-28 09:15:40 UTC` | PE header |
| Signature | **tidak ditandatangani** | Authenticode |
| DisplayVersion registry | `7` | uninstall key |
| Installer | Inno Setup 6.5.0 Unicode, AppId `{7F1E4D66-…}` | bukti instalasi |

Label folder `FLASHPRO.inc` **tidak** membuktikan bentuk badan hukum; yang terbukti hanya string vendor dan metadata registry.

## 3. Timeline yang mengubah bentuk instalasi

| Waktu (UTC) | Peristiwa |
|---|---|
| 2026-05-28 09:15:40 | Build payload x64 |
| 2026-11-13 11:53:20–21 | Instalasi dibuat (7 file) |
| **2026-11-17 11:38:51–52** | Ketiga EXE ditulis ulang sebagai wrapper VB6 |
| **2026-11-17 12:06:10** | `flashpro.exe`+U+00A0 muncul — salinan payload asli |

Kesimpulan faktual: executable yang terpasang sekarang **bukan** file yang dipasang installer pada 13 November; ketiganya diganti wrapper empat hari kemudian, dan payload asli diletakkan dengan nama berakhiran NBSP.

## 4. Mengapa ini penting untuk autopsi

1. **Dua lapisan menyesatkan.** Analisis `strings`/PE pada `FLASHPRO.exe` hanya melihat stub VB6, bukan aplikasi.
2. **Payload = build vendor.** Tidak ada modifikasi biner yang perlu dicurigai; perbedaan perilaku harus dijelaskan oleh kode, bukan patch.
3. **Enigma + lisensi.** Payload berjalan tetapi berhenti di gerbang aktivasi; seluruh fitur ECU berada di balik gerbang yang tidak boleh dilewati.
4. **Metadata tetap dapat dipulihkan.** CLR menerima metadata plaintext saat runtime; ini menjadi basis seluruh FASE I–II.

## 5. Batas identifikasi

- Tidak ada klaim bahwa produk ini "resmi", "berizin", atau "aman". Work order meminta autopsi teknis, bukan penilaian hukum.
- Hubungan antara `itech`, `Team Tech Tunner`, dan repo update `flashpro2025` hanya diketahui dari string; tidak diverifikasi sebagai entitas yang sama.
- Kemampuan ECU tidak dapat disimpulkan dari identitas produk. Semua klaim kapabilitas ada di laporan 06–13 dengan statusnya masing-masing.

## 6. Ringkasan satu paragraf

FLASHPRO.inc adalah aplikasi Windows x64 berbasis .NET 4.8 WinForms yang dibungkus Enigma Protector dan disajikan melalui wrapper VB6, dengan identitas vendor Team Tech Tunner/itech versi 0.0.1.6. Ia bukan aplikasi native tunggal, bukan aplikasi open-source, dan bukan aplikasi yang dapat diuji ujung-ke-ujung tanpa lisensi dan adaptor FTDI. Yang dapat dipastikan secara kuat adalah **struktur, metadata, string, dependensi, dan lingkungan**; yang tidak dapat dipastikan adalah **algoritma dan perilaku ECU**.
