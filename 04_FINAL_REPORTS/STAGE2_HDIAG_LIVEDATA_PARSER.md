# H-Diag 2.1 — Peta Parser Live-Data (Tahap 2)

Laporan ini menjawab §3A work order: struktur permintaan/balasan, offset, panjang, fungsi parser, konversi, satuan, pemetaan ON/OFF, dan relasi permintaan ↔ balasan ↔ baris Live-Data untuk STF, POM, SS, STS, SSW, FIS, MOD, ALT, IAC.

Basis bukti: `03_EVIDENCE/HDIAG_STAGE2_EVIDENCE.md` (SHA-256 `10100b34…5dcf`).
Tingkat: **A** terbukti · **B** sangat kuat · **C** dugaan · **D** belum diketahui · **E** butuh hardware.

> Prinsip: kesamaan nama label **tidak** dianggap bukti parser. Setiap baris di bawah hanya dinyatakan terhubung bila ada jalur kode `setRow` yang eksplisit.

## 1. Ringkasan mekanisme

1. Permintaan dikirim lewat helper baca (libusb control/bulk) dengan format frame `[0x72][len][fn][sub][checksum]` (A, Tahap 1 + konsisten di 3D Chart).
2. Balasan dikonversi menjadi string hex berpasangan koma, dipecah, lalu **dispatcher menghitung jumlah token** dan memilih jalur: 7, 8, 12, 20, atau 5 token (DTC) (A).
3. Setiap jalur memanggil `setRow(raw, key, column, slot)`. `slot` menunjuk daftar baris per tipe (tabel di stack, 5/7/21 byte per tipe); `key` harus ada di daftar kunci per tipe, jika tidak update dibatalkan (A untuk mekanika, B untuk peran tiap tabel).
4. Offset byte tiap parameter **tidak konstan**; diambil dari tabel `[this+0x64]` dengan pola `byte [tabel + slot*4 + 0x1x]` lalu `add eax, ebp` (A). Karena itu angka byte absolut per parameter adalah **E** (butuh capture).
5. Gerbang `[this+0x50] == 1` harus terpenuhi; jika tidak, seluruh update dilewati dan string debug `login_error_else=0` muncul (A).

Tabel baris (indeks) dan seluruh 48 pemanggilan `setRow` ada di dokumen bukti §1 dan §4.

## 2. Tabel sembilan parameter wajib

| Parameter | Baris | Jalur balasan | Token/offset | Konversi | Satuan | ON/OFF | Tingkat | Catatan |
|---|---:|---|---|---|---|---|---|---|
| **STF** | 20 | 8 token | token `edi+1`, span 2; offset dasar dari tabel tipe | `format()` (tipe konversi dari `[this+0x5c]`) | tidak tertulis di label | tidak ada pemetaan ON/OFF di jalur ini | B | update hanya terjadi bila `key 0x14` ada di daftar kunci tipe |
| **POM** | 21 | 12 token (status) | `key 0x15`, slot `0x15`; offset dari tabel | `format()` | — | pemetaan ON/OFF **tidak** ditemukan di H-Diag (D) | B | — |
| **SS** | 22 | 12 token | `key 0x16` | `format()` | — | idem (D) | B | — |
| **STS** | 23 | 12 token | `key 0x17` | `format()` | — | idem (D) | B | "Switch Starter", bukan "Starter Relay" |
| **SSW** | 24 | 12 token | `key 0x18` | `format()` | — | idem (D) | B | nama sama dengan STS; dua baris berbeda |
| **FIS** | 25 | 12 token | `key 0x19` | `format()` | — | idem (D) | B | nilai numerik FIS **tidak** terbukti; hanya baris & jalur |
| **MOD** | 26 | 7 token (standar) | slot `0x1A`; token dasar `ebp+…` | `format()` | — | Mode Altitude 1–4 hanya label; **tidak ada frame tulis** (A) | B | pada 3D Chart MODE dipetakan dari `MD` (§3) |
| **ALT** | 27 | 20 token | dua panggilan: span 2 dan span 3, slot `0x1B` | `format()` | — | — | B | dua token kemungkinan nilai + status (C) |
| **IAC** | 32 | 7 token (standar) | slot `0x20`, token `ebp+…` | `format()` | — | — | B | — |

Keterangan "B": jalur baris→parser terbukti dari kode; nomor byte absolut dan formula skala H-Diag **tidak** dapat dipastikan tanpa capture (E). H-Diag memakai formatter generik berbasis nibble (fungsi `0x4043B0`, tabel 50 entri di `0x4049DC`) sehingga konversi bergantung pada tipe konversi per baris, bukan rumus tetap.

## 3. Pembanding: apa yang *terbukti* di 3D Chart

| Parameter | 3D Chart | Formula | Tingkat |
|---|---|---|---|
| STF | dat20 | `b[5]/128.25651`, hanya `b[5]` | A |
| O2/O2V/AFR | dat20 | `o2=(u16(b4,b5))/13.142708/1000`; `o2v=b4/50.9937`; `afr=-5.351*o2v+17.7` | A |
| MODE | dat17 | dari `MD=b18`: 128/103→1, 102→2, 60→3, 89→4, 121→0 | A |
| FIZ | dat17 | `MD < 128 ? "ON" : "OFF"` | A |
| POM | datD1 | `b8`: 0/4 → OFF, 1/5 → ON | A |
| FAN | datD1 | `b9 == 1` | A |
| SS/SSS | datD1 | `b4==1` → SSS ON; `b4==0` → OFF | A |
| SSW | datD1 | `b4==2` → ON | A |
| GGS/GGV | datD1 | gigi dari `b4`: 0→OnGear; `b9`? (lihat laporan sensor) | A |
| IAC | dat11 | `b22/10000` dihitung tetapi tidak ditampilkan | A |

Untuk SS/SSS/SSW 3D Chart memakai **satu byte state** `b4`, sedangkan H-Diag memakai baris terpisah. Ini perbedaan desain, bukan bukti kesamaan protokol (A).

## 4. Siklus polling H-Diag (Tahap 1, dipertahankan)

| Urutan | Frame | Jumlah/siklus |
|---:|---|---:|
| 1 | `72 05 60 03 26` | 11 |
| 2 | `72 05 71 00 18` | 1 |
| 3 | `72 05 00 F1 98` | 1 |

Jeda antar-frame 100 ms; akhir siklus 1000 ms; antar-DTC 50 ms (Tahap 1, A). Pemetaan frame mana menghasilkan jalur 7/8/12/20 token **belum terbukti** (D). Frame B (`fn 0x71 sub 0x00`) tidak punya padanan di 3D Chart; layout balasannya tidak boleh diasumsikan sama (A).

## 5. DTC

- Permintaan DTC: enam frame (Tahap 1) — semua checksum PASS (lihat `PROTOCOL_FRAME_VALIDATION_STAGE2.csv`).
- Balasan DTC: 5 token dengan `edx == 0xC`; 12 token dipasangkan (0-1, 2-3, …), tiap nilai hex diubah ke desimal, digabung dengan pemisah `0x413490`, lalu dimasukkan ke daftar DTC via `0x405400` (A untuk mekanika, C untuk arti).
- Deskripsi DTC dibaca dari blob teks internal (`0x412FB8` varian ECT, `0x4130E0` varian EOT); aplikasi **tidak** mengambil teks dari ECU (B).
- Tidak ada fungsi penghapus DTC di H-Diag? `0x4040F0` hanya mereset tampilan (`[esi+0x50]=-1`, setValue(0)) — bukan perintah ECU (A: tidak ada frame tulis DTC ditemukan).

## 6. Altitude Mode

- Tidak ada frame dengan fungsi tulis/`set` untuk Mode 1–4 maupun ALT di seluruh `.text` (A: semua frame yang ditemukan adalah `0x72 05 …` baca, ditambah DTC).
- Baris MOD/ALT hanya menerima data dari balasan (B).
- Kesimpulan: H-Diag **read-only** untuk altitude; klaim "dapat diset" tidak didukung bukti (A).

## 7. Batasan

1. Nomor byte per parameter: **E** (butuh capture K-line).
2. Satuan dan tipe konversi per baris: **D** (formatter generik; tabel konversi belum dipetakan penuh).
3. Pemetaan frame → tipe balasan: **D**.
4. Perilaku nilai invalid: tidak ada penanganan eksplisit; nilai dapat tampil sebagai 0 (B).
