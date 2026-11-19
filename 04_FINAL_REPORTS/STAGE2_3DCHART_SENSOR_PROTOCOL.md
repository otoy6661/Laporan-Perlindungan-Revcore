# 3D Chart Graph — Pembacaan Sensor & Validasi Protokol (Tahap 2)

Basis: `03_EVIDENCE/3DCHART_STAGE2_EVIDENCE.md` (source `Diag.cs`).
Tingkat: **A** source terbaca · **B** sangat kuat · **C** dugaan · **D** belum diketahui · **E** butuh hardware.

## 1. Peta byte per sensor

Semua balasan berbentuk `72 <len> 71 <param> <data…> <checksum>` (A; echo perintah dibuang oleh `SendCommand`). Endianness multi-byte = **big-endian** (byte tinggi lebih dulu), terbukti dari `(b4<<8)+b5` dan `BitConverter.ToUInt16` + pemakaian `b4` sebagai LSB? Perhatikan: `BitConverter.ToUInt16(array9,4)` pada x86 membaca **little-endian**, lalu `& 0xFFFF`; sementara `rpm` memakai big-endian manual. Kedua gaya dipakai di aplikasi yang sama — perbedaan ini dicatat, bukan diseragamkan (A).

### dat10 (`Diag.cs:563`)
| Sensor | Offset | Ukuran | Tipe | Formula | Satuan | Presisi |
|---|---:|---:|---|---|---|---|
| RPM | 4–5 | 2 | unsigned BE | `(b4<<8)+b5` | RPM | integer |
| TPS1 | 6 | 1 | unsigned | `b6*5/256` | Volt | float 32-bit |
| TPS2 | 7 | 1 | unsigned | `b7/2` | ° | 0,5° |
| ECT1 | 8 | 1 | unsigned | `b8*5/256` | Volt | float |
| ECT2 | 9 | 1 | unsigned | `b9-40` | °C | 1° |
| IAT1 | 10 | 1 | unsigned | `b10*5/256` | Volt | float |
| IAT2 | 11 | 1 | unsigned | `b11-40` | °C | 1° |
| MAP1 | 12 | 1 | unsigned | `b12*5/256` | Volt | float |
| MAP2 | 13 | 1 | unsigned | `b13` | (tanpa satuan) | integer |
| BAT | 16 | 1 | unsigned | `b16/10` | Volt | 0,1 V |
| VSS | 17 | 1 | unsigned | `b17` | km/h | integer |
| INJ | 18–19 | 2 | unsigned BE | `((b18<<8)+b19)/200` | ms | 0,005 ms |
| ADV | 20 | 1 | unsigned | `b20/2-64` | ° | 0,5° |

### dat11 (`Diag.cs:806`)
Sama dengan dat10 untuk field utama; tambahan `iac = array9[22]/10000f` (baris 841). **IAC dihitung tetapi tidak diteruskan** ke `UpdateGridView` (A). Artinya baris IAC di UI tidak pernah menerima nilai dari dat11 pada versi source ini.

### dat13 (`Diag.cs:861`)
BAT `b14/10`; INJ `((b15<<8)+b16)/200`; ADV `b17/2-64`; VSS dipaksa `0` (A). Tipe tampilan `0x13`.

### dat16 (`Diag.cs:912`)
AP1/AP2/TP1/TP2 dari `b6..b13`; `cor=b14`; ECT `b15/b16`; IAT `b17/b18`; MAP `b19/b20`; BAT `b21/10`; VSS `b22`; INJ `b23/200`; ADV `b24/2-64`. Nilai dibulatkan dengan `Math.Round` (A). Perhatikan INJ di sini hanya 1 byte sedangkan di dat10/dat13 2 byte — perbedaan layout antar-frame (A).

### dat17 (`Diag.cs:973`)
ECT memakai `b12` jika `b12 != 255`, jika tidak `b8`; ECT2 memakai `b13 != 255 ? b13-40 : b9-40` (logika fallback eksplisit) (A). BAT `b14/10`; INJ `((b15<<8)+b16)/200`; ADV `b17/2-64`; MD `b18`; VSS `b19`.

### dat20 (`Diag.cs:717`)
| Sensor | Offset | Ukuran | Formula | Satuan |
|---|---:|---:|---|---|
| O2 | 4–5 | 2 (LE via BitConverter) | `u16/13.142708/1000` | λ atau V? tidak diberi label |
| STF | 5 | 1 | `b5/128.25651` | tanpa satuan |
| O2V | 4 | 1 | `b4/50.9937` | Volt |
| AFR | — | turunan | `-5.351*o2v + 17.7` | AFR |

STF hanya memakai `b[5]` — sesuai syarat validasi work order (A).

### datD1 (`Diag.cs:629`)
| Baris | Sumber | Pemetaan |
|---|---|---|
| BAS | `b4 == 1` | ON |
| SSS | `b4 == 1` | ON |
| SSW | `b4 == 2` | ON |
| BAS/SSS/SSW OFF | `b4 == 0` | OFF |
| GGS | `b4 == 0` | "OnGear" |
| POM | `b8` | 0/4 OFF, 1/5 ON |
| FAN | `b9` | `==1` ON |
| GGV | `b9` per bit | `0x80→6, 0x10→5, 0x08→4, 0x04→3, 0x02→2, 0x01→1, 0x20→N, 0x00→"-"` |

Catatan: `fan = array9[9]==1` dan `ggv` juga memakai `array9[9]` — kemungkinan fan dan gigi berbagi byte status (B); perlu verifikasi hardware (E). Nilai default semua field = 0.0/"-" sebelum balasan pertama (A, `Diag.cs:614–627`).

## 2. Penanganan data invalid & nilai basi

| Kondisi | Perilaku | Tingkat |
|---|---|---|
| `array9[1] == 0x05` (balasan gagal/timeout) | polling untuk dat tersebut dimatikan, `return` **tanpa mengosongkan nilai** → nilai lama tetap tampil | A |
| Checksum salah | `SendCommand` timeout + purge; parser tetap membaca buffer (nol) | A |
| Balasan kosong | `array9` nol → RPM 0, ECT -40, AFR 17.7, dsb. tampil sebagai nilai nyata | B |
| Overflow konversi | `(b<<8)+b` di `int`, aman untuk 16-bit | A |
| `255` pada ECT | dat17 punya fallback; dat10 tidak | A |
| Desimal | string concat tanpa format tetap; `float.ToString()` = presisi umum (hingga 7 digit signifikan), tidak ada pembulatan eksplisit kecuali dat16 | A |

Kesimpulan: aplikasi referensi **tidak membedakan** timeout dari nilai valid di UI, dan tidak ada flag kualitas data (A untuk kode).

## 3. Validasi protokol

| Aspek | Temuan | Tingkat |
|---|---|---|
| Wake-up | `FT_SetBitMode(1,1)` → tulis `00` → 70 ms → `FT_SetBitMode(0,0)`; baud 10400; purge; settle 130 ms | A |
| Baud | 10400 8-N-1, latency timer 8 ms, timeout baca 50 ms | A |
| Format frame | `72 len fn sub data chk`; `len` = panjang total | A |
| Echo | Diperlukan; `SendCommand` menunggu `commandSize+2` byte lalu membaca panjang balasan di `array2[commandSize+1]` | A (kode) / E (perilaku ECU) |
| Panjang balasan | Diambil dari byte `[1]` frame balasan; frame lengkap bila `num4-commandSize==len` | A |
| Checksum | `((sum8(n-1) ^ 0xFF)+1)&0xFF`; balasan invalid tidak dipakai | A |
| Timeout | `50 + 2*commandSize` ms; `FT_Purge(3)` | A |
| Buffer | RX 256; akumulasi 256; tanpa penanganan overflow eksplisit | A |
| Retry | Tidak ada retry di `SendCommand`; retry hanya di loop tulis flash | A |
| Balasan tidak lengkap | loop terus sampai timeout | A |
| Perbedaan per keluarga | blok tulis 128 (H8C/Shindengen) vs 64 (lain); baud fast-write 62500 hanya KEIHINOTHER | A |
| `array9[2]` | byte fungsi balasan (0x71), **bukan** echo dan bukan tipe tabel | A |
| `72 05 00 F1 98` | frame sesi; H-Diag memakai frame identik; arti tiap byte D | A (frame) / C (arti) |

## 4. Sinkronisasi & stabilitas

| Aspek | Temuan | Tingkat |
|---|---|---|
| Urutan | dat10/11/13/16/17 bergantung flag `tekXX`; dat20+datD1 setelah setiap dat | A |
| Frekuensi | tanpa jeda efektif (`Task.Delay` tidak di-await) | A |
| Duplikasi | dat20/datD1 berjalan ~5× lipat; beberapa frame menimpa baris yang sama | A |
| Request tumpang tindih | tidak ada; satu thread loop, `SendCommand` blocking | A |
| Return `SendCommand` | diabaikan semua pemanggil `datXX` (kecuali jalur tulis) | A |
| Buffer baru vs lama | `array9` lokal baru tiap panggilan; nilai tampilan tidak di-reset | A |
| Timeout tampil sebagai nilai | ya (lihat §2) | B |

## 5. Kesimpulan Tahap 2

1. Protokol baca 3D Chart **terbukti di level source**: frame, checksum, echo, timeout, purge, dan struktur balasan (A).
2. Seluruh formula sensor pada laporan Tahap 1 dikonfirmasi ulang baris-per-baris; tidak ada kontradiksi formula (A).
3. Temuan baru: `Task.Delay` tidak di-await, nilai basi saat timeout, `array9[2]` bukan tipe tabel, IAC dihitung tetapi tidak ditampilkan (A).
4. Yang masih butuh hardware: perilaku echo ECU, timing nyata, apakah `b9` benar-benar menggabungkan FAN dan GGV (E).
