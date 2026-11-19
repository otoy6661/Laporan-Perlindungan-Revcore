# H-Diag 2.1 — Bukti Statis Tahap 2

File: `C:\Program Files (x86)\H-Diag\HDiag.exe`
SHA-256: `10100b3491b056942aeb9e74ed604131a51c8445aea071bd0cace7270f265dcf`
Ukuran: 175.104 byte · PE32 (x86) · Qt 5 · MSVC 2012 · import `libusb-1.0.dll`
Metode: pembacaan header PE, ekstraksi tabel `.rdata`, disassembly 32-bit (Capstone), tanpa menjalankan program.

Catatan tingkat bukti: **A** = terbukti dari byte/kode; **B** = sangat kuat (satu langkah interpretasi); **C** = dugaan; **D** = belum diketahui; **E** = butuh validasi hardware.

---

## 1. Model tabel Live-Data: 50 baris (A)

Fungsi pada `0x402010–0x40295F` membangun daftar label baris secara berurutan (setiap label disalin ke slot `+0x10`, `+0x14`, … `+0xd4` milik objek daftar; pola `push <ptr>; … call QString::operator=(char*)` via IAT `0x41029c`). Lebar kolom diatur di awal fungsi: kolom 0 = 50 px, kolom 1 = 200 px, kolom 2–4 = 100 px (`QTableView::setColumnWidth`, IAT `0x4107bc`), lalu `QAbstractItemView::setEditTriggers` (IAT `0x4107ec`).

Urutan baris dan alamat string (`.rdata`):

| # | Label | Alamat | # | Label | Alamat |
|---:|---|---|---:|---|---|
| 0 | RPM - Putaran Mesin | `0x412ae4` | 25 | FIS - Fast Idle Switch | `0x412cbc` |
| 1 | RPMV | `0x412af8` | 26 | MOD - Mode Altitude | `0x412cd4` |
| 2 | TPS - Posisi Throttle | `0x412b00` | 27 | ALT - Koreksi Altitude | `0x412ce8` |
| 3 | TPSV | `0x412b18` | 28 | GG - Gigi Transmisi | `0x412d00` |
| 4 | EOT - Suhu Oli | `0x412b20` | 29 | SCS - Service Check Signal | `0x412d14` |
| 5 | EOTV | `0x412b30` | 30 | MIL - Jumlah Kode Error | `0x412d30` |
| 6 | ECT - Suhu Air Pendingin | `0x412b38` | 31 | MILV | `0x412d48` |
| 7 | ECTV | `0x412b54` | 32 | IAC - Katup Udara Masuk | `0x412d50` |
| 8 | IAT - Suhu Udara Masuk | `0x412b5c` | 33 | VSS - Sensor Kecepatan | `0x412d68` |
| 9 | IATV | `0x412b74` | 34 | PUL | `0x412d80` |
| 10 | MAP - Tekanan Udara Manifold | `0x412b7c` | 35 | EVA - Status Evaporator | `0x412d84` |
| 11 | MAPV | `0x412b9c` | 36 | PR - Pair Control | `0x412d9c` |
| 12 | O2 - Sensor Oksigen | `0x412ba4` | 37 | TPS 1 - Posisi Throttle 1 | `0x412db0` |
| 13 | O2V | `0x412bb8` | 38 | TPS 2 - Posisi Throttle 2 | `0x412dcc` |
| 14 | BAT - Tegangan Baterai | `0x412bbc` | 39 | TPSV1 | `0x412de8` |
| 15 | BAS - Sensor Kemiringan | `0x412bd4` | 40 | TPSV2 | `0x412df0` |
| 16 | BASV | `0x412bec` | 41 | APS 1 - Posisi Handle Gas 1 | `0x412df8` |
| 17 | INJ - Lebar Pulsa Injektor | `0x412bf4` | 42 | APS 2 - Posisi Handle Gas 2 | `0x412e14` |
| 18 | ADV - Sudut Pengapian | `0x412c10` | 43 | APSV1 | `0x412e30` |
| 19 | FAN - Kipas Pendingin | `0x412c28` | 44 | APSV2 | `0x412e38` |
| 20 | STF - Campuran Bahan Bakar | `0x412c40` | 45 | APS-K - Korelasi APS 1 dan APS 2 | `0x412e40` |
| 21 | POM - Pompa Bahan Bakar | `0x412c5c` | 46 | EOP - Sensor Tekanan Oli | `0x412e64` |
| 22 | SS - Standar Samping | `0x412c74` | 47 | EGCV - Kontrol Katup Gas Buang | `0x412e80` |
| 23 | STS - Switch Starter | `0x412c8c` | 48 | EXI - Muatan eksitasi motor | `0x412ea0` |
| 24 | SSW - Switch Starter | `0x412ca4` | 49 | GG - Gigi Transmisi (duplikat) | `0x412d00` |

Indeks baris di atas dipakai konsisten oleh seluruh jalur parsing di bawah ini (mis. `0x29` = 41 = APS 1). Baris 49 duplikat `GG`; belum diketahui apakah baris ini dipakai atau hanya sisa urutan antarmuka (C).

## 2. Dispatcher balasan (A)

Fungsi inti: `0x4056E0–0x406A5C` (dipanggil dari `MainWindow::print_data`, `0x407CE0`).
Ringkas alur:

1. Respons mentah dikonversi menjadi string hex berpasangan koma (0x4097E0), lalu di-`split(',')`.
2. Jumlah token dihitung (`[eax+0xC] - [eax+8]`). Nilai `[esp+0x1c]` adalah **jumlah token**.
3. `0x405793`: `cmp eax, 7` → jalur frame 7 token.
4. Jika `[esp+0x24] != byte[+0x64][0]` → `0x405DED`: `cmp edx, 0xC` → jalur 12 token; selain itu `0x405F90`: `cmp edx, 8` → jalur 8 token; selain itu `cmp edx, 0x14` → jalur 20 token.
5. `0x40609B`: `cmp eax, 5` → jalur 5 token; di dalamnya `cmp edx, 0xC` → jalur **DTC**.
6. Jika tidak ada yang cocok → `0x406A91` (selesai, tanpa update).
7. `0x406A5C`: `cmp [ebx+0x50], 1; jne ret` — gerbang status "terhubung/mesin hidup"; jika gagal, string debug `login_error_else=0` (`mainwindow.cpp:0x301`).

Catatan: jalur 7 token memilih dua dialek berbeda berdasarkan akses byte pertama tabel `+0x64` (`0x4057C4`). Jalur ini yang membedakan "frame APS/TPS" (`0x29`) dari "frame standar".

## 3. `setRow` — mekanisme tampilan (A untuk mekanika, B untuk makna argumen)

Fungsi `0x406AD0`. Signature kerja (hasil rekonstruksi): `setRow(QString raw, int key, int column, int slot)`.

- `[this+0x60]` = daftar byte kunci per-tipe (dibangun dari tabel 7-bita, lihat §5). Jika `key` tidak ada dalam daftar → fungsi keluar tanpa perubahan (semua panggilan menjadi no-op).
- `raw` dipecah dengan `QString::split(QChar(0x2C))` (IAT `0x4102b4`).
- Elemen ke-`slot` diambil, lalu diformat oleh `0x4043B0` (`format(convType, token)`).
- `QTableWidgetItem` dialokasikan (`0x40DCFC`), lalu `QTableWidget::setItem` dipanggil dengan indeks kolom dari `[this+0x5c]` (daftar byte per-tipe, diindeks oleh `slot`) dan kolom tujuan dari argumen.

Konsekuensi penting: **pemetaan byte → baris bersifat tabel-driven per tipe balasan**, bukan konstanta tetap. Inilah sebabnya analisis Tahap 1 tidak menemukan "byte X untuk STF": H-Diag memakai offset relatif dari tabel `[this+0x64]`, mis. `movsx eax, byte [tabel + slot*4 + 0x1x]; add eax, ebp` (`0x405B83`, `0x405C5A`, `0x405CC6`, `0x406C00`). Nilai `ebp` adalah indeks token dasar frame.

## 4. Inventaris pemanggilan `setRow` per cabang (A)

Semua 48 pemanggilan `call 0x406AD0` berhasil diekstrak beserta tiga argumennya `(key, kolom, slot)`.

### 4.1 Cabang 7 token, dialek APS/TPS (key `0x29`)

| slot | kolom | baris |
|---:|---:|---|
| `0x29` | 2 | 41 APS 1 |
| `0x2A` | 2 | 42 APS 2 |
| `0x2B` | 3 | 43 APSV1 |
| `0x2C` | 3 | 44 APSV2 |
| `0x25` | 2 | 37 TPS 1 |
| `0x26` | 2 | 38 TPS 2 |
| `0x27` | 3 | 39 TPSV1 |
| `0x28` | 3 | 40 TPSV2 |
| `0x2D` | 2 | 45 APS-K |

### 4.2 Cabang 7 token, dialek standar

Baris yang diperbarui berurutan: `0` RPM, `2` TPS, `3` TPSV, `4` EOT, `5` EOTV, `6` ECT, `7` ECTV, `8` IAT, `9` IATV, `0xA` MAP, `0xB` MAPV, `0xE` BAT, `0x21` VSS, `0x11` INJ, `0x12` ADV, `0x22` PUL, `0x20` IAC, `0x1A` MOD, `0x1B` ALT.

### 4.3 Cabang 12 token (switch/status)

`0x16` SS, `0x0F` BAS, `0x1C` GG, `0x31` GG(dup), `0x15` POM, `0x17` STS, `0x18` SSW, `0x19` FIS, `0x13` FAN, `0x23` EVA, `0x24` PR, `0x1D` SCS.

### 4.4 Cabang 8 token (O2/STF)

`0x0D` O2V dari grup `0x0C` (token `edi+1`, span 3); `0x14` STF (token `edi+1`, span 2).

### 4.5 Cabang 20 token (BAS/ALT/MIL)

`0x10` BASV dari grup `0x0F` (token `edi+0xD`, span 3); `0x1B` ALT dua kali (span 2 dan 3); `0x1E` MIL (span 2); `0x1F` MILV (span 3).

### 4.6 Cabang 5 token

Digunakan untuk DTC (`edx == 0xC`), lihat §6.

## 5. Tabel per-tipe yang dibangun di stack (A untuk isi, C untuk peran)

Pada prolog `print_data` (`0x407CE0`, `sub esp, 0x364`) tiga set tabel diisi dan disalin ke anggota objek:

- Tabel 5 byte × 25 tipe pada `esp+0x34`. Disalin ke `[this+0x64]` (loop `0x408684–0x4086A6`, `lea eax,[esp+0x34]; add eax,edi; lea ebp,[eax+edi*4]`), byte `>= 0x80` dilewati (`jl`).
- Tabel 7 byte × 25 tipe pada `esp+0xB4` (loop `0x4086B5–0x4086D5`, `edi*7`), disalin ke anggota daftar berikutnya.
- Tabel 21 byte × 25 tipe pada `esp+0x164` (diisi `0x408280–0x4083F9`), berisi daftar baris per tipe, mis. tipe 22: `00 29 2A 25 26 06 08 0A 11 12 0E 0C 0F 14 15 13 31 24 2D 21 1E` (0, 41, 42, 37, 38, 6, 8, 10, 17, 18, 14, 12, 15, 20, 21, 19, 49, 36, 45, 33, 30).

Isi ketiga tabel sudah diekstrak utuh (lihat `01_HDIAG/` untuk dump string; tabel byte tercatat pada log analisis). Peran pasti tiap tabel (kunci vs baris vs offset) masih **C** — petunjuk kuat: 5 byte = kunci per frame, 7 byte = daftar baris utama, 21 byte = daftar baris lengkap.

## 6. Jalur DTC (A untuk mekanika, C untuk arti kode)

`0x40609B–0x4062DF` (cabang 5 token, `edx == 0xC`):

1. Token ke-`i` dan ke-`i+1` dikonversi dengan `QString::toInt(...,16)`.
2. Keduanya diubah ke desimal dengan `QString::number(int,10)` (IAT `0x4102a8`).
3. Digabung dengan pemisah pada `0x413490`, lalu ditambahkan ke daftar lewat `0x405400`.
4. Pasangan diproses berulang untuk 12 token → 6 pasangan.

Deskripsi DTC disimpan sebagai blob ASCII panjang di `0x412FB8` ("Error pada sensor air pendingin (ECT)…") dan `0x4130E0` ("Error pada sensor oli mesin (EOT)…"), berisi banyak entri yang dipisah `\n` dan `#`. Pemilihan blob ECT vs EOT terjadi di `0x4088C6`. Interpretasi: H-Diag menampilkan deskripsi DTC dari tabel teks internal, bukan dari ECU (B).

## 7. Koreksi terhadap Tahap 1

| Klaim Tahap 1 | Bukti baru | Koreksi |
|---|---|---|
| `0x406AD0` argumen ketiga = row / convType | Argumen ketiga = `slot`; kolom berasal dari tabel `[this+0x5c]`, baris dari `slot` | Mekanisme `setRow(raw,key,column,slot)` |
| Pemilihan nama `0x412FB8` vs `0x4130E0` = set nama kolom | Keduanya blob teks DTC (ECT vs EOT), bukan nama kolom | Bukan set nama; tabel DTC |
| Offset byte tiap parameter tetap | Offset berasal dari tabel per-tipe (`movsx byte [tabel+…]; add eax,ebp`) | Offset bersifat dinamis per tipe ECU |
| Baris 0..7 = STF..ALT tidak ditemukan jalur update | Jalur ditemukan: STF (8 token), POM/SS/STS/SSW/FIS (12 token), MOD/ALT (7/20 token) | Terjawab sebagian besar |

## 8. Yang tetap belum diketahui

- Nilai `typeList` (25 tipe) yang sebenarnya; pemetaan tipe balasan ke model motor belum terbaca (D).
- Baud H-Diag: tidak ada konstanta divisor baud standar (`0x120`, `0x1207`) di `.text`; kemungkinan dihitung atau berasal dari konfigurasi (D).
- Apakah `[this+0x50]` di-set oleh timer atau oleh balasan valid (B: oleh alur koneksi; D: titik pasti).
- Arti semantik tiap posisi argumen `setRow` di level Qt (row vs column) — memengaruhi tampilan, bukan protokol (C).
- Semua nomor byte riil per parameter: **E** (butuh capture K-line pada ECU nyata).
