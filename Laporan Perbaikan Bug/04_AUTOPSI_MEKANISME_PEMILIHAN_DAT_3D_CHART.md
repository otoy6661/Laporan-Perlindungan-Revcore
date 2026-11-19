# Autopsi Mekanisme Pemilihan Kelompok "dat" — 3D Chart

Dokumen ini menjawab satu pertanyaan: **bagaimana 3D Chart memilih kelompok `dat` untuk membaca dan menampilkan sensor?** Fokusnya bukan inventaris perintah, melainkan mekanisme pemilihan, aturan, prioritas, fallback, dan alur eksekusi yang benar-benar ada di source code.

| Item | Nilai |
|---|---|
| Target | Source code 3D Chart Graph Remap K-Line |
| Folder sumber | `3D Chart Graph remap kline\3D Chart Graph\` |
| File utama | `Diag.cs` (60.541 byte), `Form1.cs` (878.075 byte), `Diag.Designer.cs` |
| SHA-256 `Diag.cs` | `38c2844f6b573e646eee04f689bb4429891610cddecf34a2e945ff34efd56135` |
| SHA-256 `Form1.cs` | `01fc11d11cc3af02fbf1e8f9bc75f740c07d70fb80f0ac91fe1c1d63264d326e` |
| SHA-256 `Diag.Designer.cs` | `49a82102e5b0abe9f37d0dabe7440bf67145a1c07d5b2f59f8fbe56b200a588f` |
| Metode | Pembacaan statis source code (read-only) |
| Eksekusi program | Tidak ada |
| Koneksi ECU/adapter | Tidak ada |
| Flashing/write/erase | Tidak ada |
| Tanggal analisis | 2026-11-19 |

### Tingkat bukti

- **TERBUKTI** — terbaca langsung pada source code, disertai nama file, fungsi, dan nomor baris.
- **INDIKASI** — kesimpulan satu langkah dari kode, tetapi memerlukan asumsi tentang bentuk balasan ECU atau perilaku runtime.
- **BELUM DIKETAHUI** — tidak dapat diputuskan dari source code; memerlukan capture K-line atau dokumentasi ECU.

Tidak ada klaim hardware di dokumen ini. Semua pernyataan tentang ECU nyata diberi label **BELUM DIKETAHUI** atau **INDIKASI**.

---

## 0. Ringkasan eksekutif

3D Chart **tidak memilih kelompok `dat` berdasarkan identitas motor atau ECU**. Tidak ada permintaan ID ECU, tidak ada VIN, tidak ada pembacaan kode model, dan form diagnostik tidak menerima parameter model. Yang ada adalah **lima kelompok opsional yang selalu dipanggil** (0x10, 0x11, 0x13, 0x16, 0x17) ditambah 0x20 dan 0xD1. Kelompok dianggap "didukung" hanya jika balasannya memiliki panjang 5 byte; jika demikian, kelompok itu dimatikan secara permanen untuk sisa sesi form.

| No | Pertanyaan | Jawaban singkat | Status |
|---:|---|---|---|
| 1 | Memilih `dat` berdasarkan identitas motor/ECU? | Tidak. Tidak ada identifikasi runtime. | TERBUKTI |
| 2 | Otomatis atau manual? | Otomatis sepenuhnya; tidak ada kontrol pemilihan `dat`. | TERBUKTI |
| 3 | Satu motor bisa memakai beberapa kelompok? | Ya. Semua kelompok yang tidak menjawab 5 byte dipanggil setiap siklus, bukan dipilih salah satu. | TERBUKTI |
| 4 | Ada fallback otomatis? | Tidak ada fallback antarkelompok. Yang ada hanya fallback byte ECT di dalam `dat17` dan pemanggilan `dat20`/`datD1` tanpa syarat. | TERBUKTI |
| 5 | Syarat kelompok dianggap cocok? | Hanya `array9[1] != 0x05` untuk dat10/11/13/16/17. Tidak ada validasi identitas, panjang data, atau status di parser. | TERBUKTI |
| 6 | Sensor tidak tersedia vs kegagalan komunikasi? | Tidak dibedakan. Keduanya menghasilkan angka nol, nilai lama, atau label OFF tanpa penanda error. | TERBUKTI |
| 7 | Bagaimana parser dan rumus ditentukan? | Hardcoded per fungsi `datXX`; offset byte dan rumus ditulis tetap. Tidak ada tabel pemetaan. | TERBUKTI |
| 8 | Mekanisme yang layak jadi referensi RevCore? | Pola probe kapabilitas dan pemisahan identitas dari live-data berguna sebagai *desain*, tetapi implementasinya di 3D Chart tidak aman untuk diadopsi apa adanya. | INDIKASI |

---

## 1. Identitas motor/ECU dan urutan proses

### 1.1 Tidak ada identifikasi motor/ECU pada jalur live data (TERBUKTI)

Seluruh permintaan K-line yang ada di `Diag.cs` dan `Form1.cs` hanya berjumlah tujuh jenis:

| Frame | Fungsi |
|---|---|
| `72 05 71 10 08` | dat10 |
| `72 05 71 11 07` | dat11 |
| `72 05 71 13 05` | dat13 |
| `72 05 71 16 02` | dat16 |
| `72 05 71 17 01` | dat17 |
| `72 05 71 20 F8` | dat20 |
| `72 05 71 D1 47` | datD1 |

Sumber: `Diag.cs:566`, `809`, `864`, `915`, `976`, `720`, `631`; duplikat di `Form1.cs:18592`, `18637`, `18681`, `18724`, `18742`, `18819`.

Tidak ada frame permintaan identitas (misalnya `72 05 60 ...`, `72 05 00 ...`, atau permintaan nomor ECU) di jalur live data. `InitFtdiIso` hanya membuka perangkat, mengatur 8-N-1 10400 baud, melakukan bit-bang wake, lalu purge (`Diag.cs:1140-1269`). Tidak ada handshake, pembacaan ID, atau pencocokan model.

Perlu dibedakan: `SMK.cs` memiliki daftar model sendiri (`SMK.cs:28-39`) dan memakai frame sesi `72 05 00 F0 99` serta frame wake `FE 04 72 8C` (`SMK.cs:246`, `373`, `1454-1457`, `1644`). Daftar itu dipakai untuk membaca/mendekode EEPROM dan menamai file (`SMK.cs:531` dan seterusnya), bukan untuk memilih `dat` live. Frame sesi tersebut juga bukan pembacaan identitas motor. Jalur live data di `Diag.cs` tidak memakai daftar model mana pun.

Form `Diag` juga tidak menerima parameter apa pun:

- Konstruktor `Diag()` tanpa argumen (`Diag.cs:29`).
- `Diag_Load` langsung memanggil `InitFtdiIso()` dan menyiapkan dua grid (`Diag.cs:43-49`).
- `Diag.cs` memiliki **nol** referensi ke `Form1` (hasil pencarian `Form1` pada `Diag.cs` = 0 kecocokan).
- Form dibuka dari `Form1.button7_Click` dengan `new Diag()` tanpa argumen model (`Form1.cs:19238-19241`).
- `Diag.Designer.cs` hanya memuat empat tombol, empat panel, dan satu `ListBox`; tidak ada combo box pemilihan motor/ECU/`dat` (`Diag.Designer.cs:172-180`).

Kesimpulan: **pemilihan `dat` tidak mungkin bergantung pada model yang dipilih di form utama**, karena form diagnostik tidak menerima informasi itu dan tidak membacanya dari tempat lain.

### 1.2 Yang ada: pemilihan model untuk remap, bukan live data (TERBUKTI)

`Form1` memang memiliki daftar model/BIN yang panjang, misalnya "1. BEAT 110-30400-K25G-601" dan seterusnya (`Form1.cs:3201-3220`, dipanggil dari `Form1.cs:149`). Handler `ComboBox1_SelectedIndexChanged` memakai nama item untuk menentukan resource, visibilitas menu, dan alamat offset remap (`Form1.cs:3362` dan seterusnya).

Selain itu, `GetEcuType()` menentukan keluarga ECU dari **isi file BIN yang sudah dimuat** (`Form1.binBytes`), bukan dari ECU yang sedang terhubung (`Form1.cs:1052-1105`). Fungsi ini dipakai pada jalur tulis flash (`Form1.cs:782-805`), bukan pada `dat10`–`dat17`.

| Sumber identitas | Dipakai untuk | Dipakai untuk memilih `dat`? |
|---|---|---|
| Combo model/BIN (`Form1.cs:3362`) | Resource remap, offset, visibilitas menu | Tidak (TERBUKTI) |
| `GetEcuType()` dari `binBytes` (`Form1.cs:1052`) | Pre-write/checksum/flash | Tidak (TERBUKTI) |
| Combo model `SMK` (`SMK.cs:28-39`, handler `1759`) | Dekode EEPROM dan penamaan file | Tidak (TERBUKTI) |
| Balasan ECU saat polling | Menentukan kelompok mana yang dimatikan | Ya, tetapi hanya lewat panjang 5 byte (TERBUKTI) |
| Database kendaraan internal | Tidak ditemukan pada jalur live data; daftar model hanya dipakai remap/EEPROM | Tidak (TERBUKTI) |
| Pemilihan manual `dat` | Tidak ada kontrol di UI | Tidak (TERBUKTI) |

### 1.3 Urutan proses live data (TERBUKTI)

1. `Diag_Load` memanggil `InitFtdiIso()` lalu membuat dua `DataGridView` (`Diag.cs:43-49`).
2. Pengguna menekan tombol Start; `button2_Click` membuat `CancellationTokenSource` dan thread latar yang menjalankan `LoopDat17` (`Diag.cs:1109-1120`).
3. `LoopDat17` berulang tanpa henti selama token belum dibatalkan (`Diag.cs:516-559`).
4. Setiap iterasi memanggil, berurutan: `dat11`, `dat10`, `dat13`, `dat16`, `dat17`; masing-masing diikuti `dat20` (`Diag.cs:518-550`).
5. `dat20` selalu memanggil `datD1` di akhir (`Diag.cs:748`).
6. Setiap `datXX` memanggil `SendCommand`, lalu memeriksa `array9[1] == 0x05` (kecuali `dat20` dan `datD1`).
7. Jika balasan dianggap valid, parser menulis ke grid; jika tidak, nilai nol atau nilai lama yang tampil.
8. `Task.Delay(10, token)` dipanggil **tanpa `await`** (`Diag.cs:557`), sehingga tidak ada jeda efektif.
9. Tombol DTC dan Reset ECM membatalkan token, menjalankan urutan DTC/reset, dan **tidak** mengaktifkan kembali kelompok yang sudah dimatikan (`Diag.cs:1362-1390`).

Form utama memiliki salinan jalur yang berbeda: `Form1.LoopDat17` adalah `async void` dan menunggu `Task.Delay(50, token)` (`Form1.cs:19139-19173`), dengan urutan `dat11`, `dat10`, `dat13`, `dat16`, `dat17` (`Form1.cs:19143-19168`). `dat20` tidak dipanggil langsung dari loop, tetapi dipanggil di dalam `dat10`, `dat11`, `dat13`, dan `dat17` (`Form1.cs:18623`, `18667`, `18710`, `18775`). `dat16` di `Form1` hanya memeriksa `0x05` dan tidak mem-parsing data (`Form1.cs:18722-18735`).

---

## 2. Inventaris kelompok `dat`

Bentuk balasan yang **diasumsikan** oleh seluruh parser: `[0]=0x72`, `[1]=panjang`, `[2]=0x71`, `[3]=subfungsi`, `[4..]=data`, `[terakhir]=checksum`. Echo perintah sudah dibuang oleh `SendCommand` (`Diag.cs:1318`). Parser **tidak** memverifikasi `[0]`, `[2]`, atau `[3]`; hanya `[1]` yang dipakai sebagai sinyal dukungan.

Panjang balasan yang diharapkan **tidak dideklarasikan** sebagai konstanta. Yang ada hanya indeks tertinggi yang dibaca. Kolom "indeks tertinggi" di bawah adalah bukti tidak langsung tentang panjang minimum yang dibutuhkan agar data tidak nol.

### 2.1 Ringkasan

| Dat | TX | Checksum | Indeks tertinggi | Sensor utama | Penulis grid | Motor/ECU |
|---|---|---:|---:|---|---|---|
| dat10 | `72 05 71 10 08` | 0x08 (PASS) | b20 | RPM, TPS, ECT, IAT, MAP, baterai, VSS, injektor, advance | grid1 baris 0-27; 15-27 nol | Tidak dipetakan |
| dat11 | `72 05 71 11 07` | 0x07 (PASS) | b22 | Sama seperti dat10 + IAC b22 | grid1 baris 0-27; 15-27 nol | Tidak dipetakan |
| dat13 | `72 05 71 13 05` | 0x05 (PASS) | b17 | RPM, TPS, ECT, IAT, MAP, baterai, injektor, advance; VSS diisi 0 | grid1 baris 0-27; 15-27 nol | Tidak dipetakan |
| dat16 | `72 05 71 16 02` | 0x02 (PASS) | b24 | APS/TP, koreksi, ECT, IAT, MAP, baterai, VSS, injektor, advance | grid1 baris 0-27 (posisi salah) | Tidak dipetakan |
| dat17 | `72 05 71 17 01` | 0x01 (PASS) | b19 | RPM, TPS, ECT (dengan fallback), baterai, injektor, advance, VSS, MODE | grid1 baris 0-27; 15-27 nol | Tidak dipetakan |
| dat20 | `72 05 71 20 F8` | 0xF8 (PASS) | b5 | O2, O2V, STF, AFR | grid2 baris 0-3 | Tidak dipetakan |
| datD1 | `72 05 71 D1 47` | 0x47 (PASS) | b10 | BAS, SSS, SSW, gear, pompa, fan, GGV | grid2 baris 4-11 | Tidak dipetakan |

Status checksum mengacu pada `03_EVIDENCE/PROTOCOL_FRAME_VALIDATION_STAGE2.csv` baris dat10-datD1 (semua PASS dengan rumus Honda 8-bit).

### 2.2 dat10 — `Diag.cs:563-605`

| Parameter | Byte | Rumus | Baris grid |
|---|---:|---|---:|
| RPM | b4-b5 | `(b4 << 8) + b5` | 0 |
| TPS1 | b6 | `b6 * 5 / 256` | 1 |
| TPS2 | b7 | `b7 / 2` | 2 |
| ECT1 | b8 | `b8 * 5 / 256` | 3 |
| ECT2 | b9 | `b9 - 40` | 4 |
| IAT1 | b10 | `b10 * 5 / 256` | 5 |
| IAT2 | b11 | `b11 - 40` | 6 |
| MAP1 | b12 | `b12 * 5 / 256` | 7 |
| MAP2 | b13 | `b13` | 8 |
| Baterai | b16 | `b16 / 10` | 9 |
| VSS | b17 | `b17` | 13 |
| Injektor | b18-b19 | `((b18 << 8) + b19) / 200` | 10 |
| Advance | b20 | `b20 / 2 - 64` | 12 |
| MODE | — | diisi 0 | 11 |
| TableType | — | hardcoded `0x10` | 14 |

Pemanggilan: `UpdateGridView(..., 0x10)` (`Diag.cs:599`).

### 2.3 dat11 — `Diag.cs:806-858`

Offset dan rumus sama dengan dat10 untuk b4-b20. Tambahan:

| Parameter | Byte | Rumus | Dipakai? |
|---|---:|---|---|
| IAC | b22 | `b22 / 10000` | Dihitung (`Diag.cs:841`) tetapi **tidak** dikirim ke `UpdateGridView` |

Pemanggilan: `UpdateGridView(..., 0x11)` (`Diag.cs:845`). IAC tidak memiliki baris grid.

### 2.4 dat13 — `Diag.cs:861-909`

| Parameter | Byte | Rumus | Catatan |
|---|---:|---|---|
| RPM | b4-b5 | `(b4 << 8) + b5` | — |
| TPS1/TPS2 | b6/b7 | `b6 * 5 / 256`, `b7 / 2` | — |
| ECT1/ECT2 | b8/b9 | `b8 * 5 / 256`, `b9 - 40` | — |
| IAT1/IAT2 | b10/b11 | `b10 * 5 / 256`, `b11 - 40` | — |
| MAP1/MAP2 | b12/b13 | `b12 * 5 / 256`, `b13` | — |
| Baterai | b14 | `b14 / 10` | Berbeda dari dat10 (b16) |
| Injektor | b15-b16 | `((b15 << 8) + b16) / 200` | Berbeda dari dat10 (b18-b19) |
| Advance | b17 | `b17 / 2 - 64` | Berbeda dari dat10 (b20) |
| VSS | — | hardcoded `0` | `Diag.cs:897` |
| TableType | — | hardcoded `0x13` | `Diag.cs:897` |

### 2.5 dat16 — `Diag.cs:912-970`

Offset yang dibaca:

| Parameter | Byte | Rumus |
|---|---:|---|
| RPM | b4-b5 | `(b4 << 8) + b5` |
| AP1V | b6 | `b6 * 5 / 256` |
| AP2V | b7 | `b7 * 5 / 256` |
| AP1 | b8 | `b8 / 2` |
| AP2 | b9 | `b9 / 2` |
| TP1V | b10 | `b10 * 5 / 256` |
| TP2V | b11 | `b11 * 5 / 256` |
| TP1 | b12 | `b12 / 2` |
| TP2 | b13 | `b13 / 2` |
| COR | b14 | `b14` |
| ECTV | b15 | `b15 * 5 / 256` |
| ECT | b16 | `b16 - 40` |
| IATV | b17 | `b17 * 5 / 256` |
| IAT | b18 | `b18 - 40` |
| MAPV | b19 | `b19 * 5 / 256` |
| MAP | b20 | `b20` |
| Baterai | b21 | `b21 / 10` |
| VSS | b22 | `b22` |
| Injektor | b23 | `b23 / 200` |
| Advance | b24 | `b24 / 2 - 64` |

**Cacat pemetaan tampilan (TERBUKTI).** Pemanggilan di `Diag.cs:955-960` mengirim 20 argumen ke signature `UpdateGridView` yang memiliki 28 parameter dengan urutan berbeda (`Diag.cs:1053`). Akibatnya nilai masuk ke baris yang salah:

| Argumen ke- | Nilai yang dikirim | Parameter formal yang menerima | Baris grid |
|---:|---|---|---:|
| 1 | rpm | rpm | 0 |
| 2 | `Round(ap1_0)` | tps1 | 1 |
| 3 | `Round(ap2_0)` | tps2 | 2 |
| 4 | `Round(ap1_1)` | ect1 | 3 |
| 5 | `Round(ap2_1)` | ect2 | 4 |
| 6 | `Round(tp1_0)` | iat1 | 5 |
| 7 | `Round(tp2_0)` | iat2 | 6 |
| 8 | `Round(tp1_1)` | map1 | 7 |
| 9 | `Round(tp2_1)` | map2 | 8 |
| 10 | `cor` | bat | 9 |
| 11 | `Round(ect1)` | inj | 10 |
| 12 | `Round(ect2)` | MODE | 11 |
| 13 | `Round(iat11)` | adv | 12 |
| 14 | `Round(iat21)` | vss | 13 |
| 15 | `Round(map11)` | tableType | 14 |
| 16 | `map21` | ap1_0 | 15 |
| 17 | `Round(bat)` | ap2_0 | 16 |
| 18 | `vss` | ap1_1 | 17 |
| 19 | `Round(inj)` | ap2_1 | 18 |
| 20 | `Round(adv)` | tp1_0 | 19 |
| 21-28 | default 0 | tp2_0 .. map21 | 20-27 |

Selain salah baris, semua nilai AP/TP/ECT/IAT/MAP/baterai/injektor/advance dibulatkan ke bilangan bulat oleh `Math.Round` sebelum dikirim. Contoh: AP1V 0,98 volt menjadi 1, lalu ditampilkan sebagai "TPS1 1 Volt". **TERBUKTI** untuk mekanika.

Penting untuk prioritas: `UpdateGridView` selalu menulis seluruh 28 baris, termasuk parameter opsional yang tidak diberikan (bernilai default 0). Karena dat17 dipanggil setelah dat16 dan mengirim 15 argumen, dat17 menimpa baris 0-14 sekaligus menulis nol ke baris 15-27. Jadi cacat pemetaan dat16 **hanya terlihat jika dat17 dimatikan**; jika dat17 aktif, hasil dat16 langsung tertimpa. **TERBUKTI** dari signature dan urutan pemanggilan.

### 2.6 dat17 — `Diag.cs:973-1049`

| Parameter | Byte | Rumus | Catatan |
|---|---:|---|---|
| RPM | b4-b5 | `(b4 << 8) + b5` | — |
| TPS1/TPS2 | b6/b7 | `b6 * 5 / 256`, `b7 / 2` | — |
| ECT1 | b12, fallback b8 | `b12 != 255 ? b12 * 5 / 256 : b8 * 5 / 256` | Fallback byte (TERBUKTI) |
| ECT2 | b13, fallback b9 | `b13 != 255 ? b13 - 40 : b9 - 40` | Fallback byte (TERBUKTI) |
| Baterai | b14 | `b14 / 10` | — |
| Injektor | b15-b16 | `((b15 << 8) + b16) / 200` | — |
| Advance | b17 | `b17 / 2 - 64` | — |
| MD/MODE | b18 | 128/103→1, 102→2, 60→3, 89→4, 121→0, lainnya 0 | `Diag.cs:1000-1035` |
| FIZ | b18 | `MD < 128 ? "ON" : "OFF"` | Ditampilkan di grid2 baris 4 |
| VSS | b19 | `b19` | — |
| TableType | b2 | `array9[2]` | Selalu 0x71 pada balasan normal (lihat §4.4) |
| IAT1/IAT2/MAP1/MAP2 | — | **diisi 0** | `UpdateGridView(..., 0,0,0,0, ...)` di `Diag.cs:1043` |

Pemanggilan `Diag.cs:1043` menimpa baris 5-8 dengan nol setiap kali dat17 berhasil melewati pemeriksaan `0x05`. Karena dat17 adalah pemanggil terakhir dalam satu iterasi, nilai IAT/MAP dari dat10/dat11/dat13/dat16 **selalu terhapus** jika dat17 berhasil.

### 2.7 dat20 — `Diag.cs:717-749`

| Parameter | Byte | Rumus | Baris grid2 |
|---|---:|---|---:|
| O2 | b4-b5 | `(BitConverter.ToUInt16(array9,4) & 0xFFFF) / 13.142708 / 1000` | 0 |
| STF | b5 | `(b5 & 0xFF) / 128.25651` | 2 |
| O2V | b4 | `(b4 & 0xFF) / 50.9937` | 1 |
| AFR | — | `(-5.351 * o2v) + 17.7` | 3 |
| FIZ | — | memakai field `fiz` terakhir (hanya diisi dat17) | 4 |
| Switch | — | memakai field terakhir dari datD1 | 5-11 |

Catatan urutan: `dat20` memanggil `UpdateGridView2` pada `Diag.cs:742` **sebelum** `datD1()` pada `Diag.cs:748`. Pada panggilan itu, baris switch (5-11) masih berisi nilai dari `datD1` sebelumnya; `datD1` kemudian memperbaruinya. Jadi data O2/STF segar, sedangkan switch tertinggal satu panggilan di dalam `dat20` dan baru diperbarui setelahnya. **TERBUKTI**.

Catatan penting: `BitConverter.ToUInt16` membaca **little-endian**, sedangkan seluruh parser dat lain memakai **big-endian** `(b4 << 8) + b5`. Jadi O2 memakai `b4 + 256*b5`, bukan `256*b4 + b5`. **TERBUKTI** untuk perilaku kode; apakah ini disengaja **BELUM DIKETAHUI**.

`dat20` tidak memiliki pemeriksaan `array9[1] == 0x05`. Jika ECU menjawab 5 byte (tidak didukung), maka `array9[4]` adalah byte checksum dan `array9[5]` nol; O2/O2V/AFR akan menampilkan nilai turunan checksum, bukan status "tidak tersedia". **INDIKASI** (bergantung pada bentuk balasan ECU).

### 2.8 datD1 — `Diag.cs:629-707`

| Parameter | Byte | Aturan | Baris grid2 |
|---|---:|---|---:|
| BAS/SSS/SSW/GGS | b4 | 0x01: BAS ON, SSS ON, GGS "Netral", SSW OFF; 0x02: SSW ON; 0x00: GGS "OnGear", SSW OFF; default: SSW OFF | 5-8 |
| POM | b8 | 0x00/0x04 OFF; 0x01/0x05 ON | 9 |
| FAN | b9 | `b9 == 0x01 ? "ON" : "OFF"` | 10 |
| GGV | b10 | 0x80→6, 0x10→5, 0x08→4, 0x04→3, 0x02→2, 0x01→1, 0x20→N, 0x00/default→"-" | 11 |

Sebelum membaca, fungsi mengeset `bas = sss = ssw = ggs = pom = fan = ggv = "OFF"` dan `ggs = "Netral"` (`Diag.cs:642-643`). Artinya balasan kosong/invalid tetap menampilkan OFF/Netral/"-", bukan status error. `datD1` juga tidak memeriksa `0x05`.

---

## 3. Mekanisme pemilihan, prioritas, dan fallback

### 3.1 Seleksi berbasis kapabilitas, bukan identitas (TERBUKTI)

Lima flag dideklarasikan `true` saat form dibuat:

```csharp
private bool tek10 = true;
private bool tek11 = true;
private bool tek13 = true;
private bool tek16 = true;
private bool tek17 = true;
```

Sumber: `Diag.cs:24-28`; duplikat `Form1.cs:18583-18587`.

Setiap parser memeriksa panjang balasan. Jika `array9[1] == 0x05`, parser mematikan flag dan langsung kembali:

```csharp
if (array9[1] == 0x05)
{
    tek10 = false;
    return;
}
```

Sumber: `Diag.cs:575-579` (dat10), `818-822` (dat11), `873-877` (dat13), `924-928` (dat16), `986-990` (dat17).

Inilah satu-satunya "mekanisme pemilihan": **bukan memilih kelompok yang cocok, melainkan mematikan kelompok yang dianggap tidak mendukung**. Tidak ada tabel model, tidak ada daftar ECU, tidak ada kode identitas.

### 3.2 Sifat latch: satu arah, permanen, tidak pernah di-probe ulang (TERBUKTI)

- Setelah `tekXX = false`, tidak ada kode yang mengembalikannya ke `true`.
- Tidak ada tombol "retry" atau "probe ulang" di `Diag`.
- DTC dan Reset ECM hanya membatalkan token; keduanya tidak menyentuh flag (`Diag.cs:1362-1390`).
- Form ditutup dan dibuka lagi akan membuat instance baru dengan flag `true` lagi (`Form1.cs:19238`), tetapi selama form yang sama hidup, latch bersifat permanen.

Konsekuensi: satu balasan 5 byte — termasuk balasan yang keliru, balasan perintah lain, atau gangguan sesaat — cukup untuk mematikan kelompok sampai form ditutup. **INDIKASI** untuk kasus gangguan sesaat; mekanisme latch-nya sendiri **TERBUKTI**.

### 3.3 Prioritas tidak dideklarasikan; yang berlaku adalah "penulis terakhir" (TERBUKTI)

`LoopDat17` memakai lima `if` terpisah, bukan `else if`:

```csharp
if (tek11) { dat11(); dat20(); }
if (tek10) { dat10(); dat20(); }
if (tek13) { dat13(); dat20(); }
if (tek16) { dat16(); dat20(); }
if (tek17) { dat17(); dat20(); }
```

Sumber: `Diag.cs:518-550`.

Semua kelompok yang masih aktif dijalankan pada iterasi yang sama. Tidak ada konsep "kelompok utama" atau "kelompok alternatif". Urutan di atas hanya memengaruhi **nilai akhir** di baris grid yang dipakai bersama, karena setiap `UpdateGridView` menimpa baris yang sama.

Perlu dicatat: `UpdateGridView` selalu memanggil `UpdateRows` dengan 28 parameter. Pemanggil yang hanya memberi 15 argumen (dat10, dat11, dat13, dat17) membuat baris 15-27 ditulis sebagai nol pada setiap panggilan. Jadi baris extended bukan hanya "tidak terisi", melainkan secara aktif dikosongkan oleh pemanggil terakhir.

| Baris grid1 | Ditulis oleh (urut) | Nilai efektif jika semua aktif |
|---:|---|---|
| 0 RPM | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 1 TPS1 | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 2 TPS2 | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 3 ECT1 | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 4 ECT2 | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 5-8 IAT/MAP | dat11, dat10, dat13, dat16, dat17 | **0** (dat17 menulis nol) |
| 9 Baterai | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 10 Injektor | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 11 MODE | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 12 Advance | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 13 VSS | dat11, dat10, dat13, dat16, dat17 | dat17 |
| 14 TableType | dat11 (0x11), dat10 (0x10), dat13 (0x13), dat16 (map11), dat17 (0x71) | 0x71 |
| 15-27 | semua pemanggil menulis nilai default 0; dat16 mengisi sebagian dengan nilai tergeser | **0** (dat17 terakhir) |

Jika dat17 dimatikan (balasan 5 byte) dan dat16 masih aktif, penulis terakhir menjadi dat16, yang memiliki cacat posisi di §2.5; pada kondisi itu baris 0-19 berisi nilai tergeser dan baris 20-27 nol. Jika dat16 juga dimatikan, dat13 menjadi penulis terakhir (jika masih aktif) untuk baris 0-14, dengan VSS hardcoded 0 dan baris 15-27 nol. Jika dat13 ikut mati, dat10 atau dat11 menjadi penulis terakhir sesuai urutan.

**Kesimpulan prioritas:** tidak ada aturan kualitas data. Nilai yang tampil adalah nilai dari fungsi terakhir yang dipanggil, termasuk jika fungsi itu baru saja menulis nol karena balasan gagal. **TERBUKTI**.

### 3.4 `dat20` dan `datD1` tidak pernah dimatikan (TERBUKTI)

- Tidak ada pemeriksaan `0x05` di `dat20` (`Diag.cs:717-749`).
- Tidak ada pemeriksaan `0x05` di `datD1` (`Diag.cs:629-707`).
- `dat20` dipanggil setelah setiap kelompok yang masih aktif; `datD1` dipanggil di akhir `dat20` (`Diag.cs:748`).

Jadi bahkan ketika seluruh kelompok utama sudah dimatikan, selama setidaknya satu blok `if` masih aktif, `dat20` dan `datD1` tetap dipanggil. Setelah semua flag false, loop tidak melakukan permintaan apa pun dan UI membeku pada nilai terakhir.

### 3.5 Fallback yang benar-benar ada

| Bentuk fallback | Lokasi | Status | Cakupan |
|---|---|---|---|
| ECT byte 12/13 → 8/9 jika bernilai 255 | `Diag.cs:996-997` | TERBUKTI | Hanya dua parameter di dat17 |
| Melanjutkan ke kelompok berikutnya setelah satu kelompok gagal | `Diag.cs:518-550` | TERBUKTI | Bukan fallback sejati; semua kelompok memang selalu dijalankan |
| Mematikan kelompok setelah balasan 5 byte | `Diag.cs:575` dan seterusnya | TERBUKTI | Tidak memilih pengganti |
| `dat20` selalu memanggil `datD1` | `Diag.cs:748` | TERBUKTI | Bukan fallback; pemanggilan tanpa syarat |
| Fallback ke kelompok lain karena identitas ECU | — | **TIDAK ADA** | Tidak ditemukan di source |

Tidak ada mekanisme "jika dat10 gagal, coba dat11" karena dat11 sudah dicoba lebih dulu, dan dat10 tetap dicoba pada iterasi berikutnya selama flag-nya belum false. Tidak ada mekanisme "jika ECU model X, pakai dat Y".

### 3.6 Tidak ada pemilihan manual (TERBUKTI)

`Diag.Designer.cs` hanya mendefinisikan `button1` (Exit), `button2` (Start), `button3` (Read DTC), `button4` (Reset ECM), empat panel, dan `listBox1` (`Diag.Designer.cs:172-180`). Tidak ada `ComboBox`, `CheckBox`, `RadioButton`, atau `NumericUpDown` untuk memilih `dat`, model, atau ECU.

Satu-satunya "pilihan" pengguna adalah kapan menekan Start. Isi kelompok ditentukan sepenuhnya oleh kode dan balasan ECU.

### 3.7 Risiko konkurensi: Start dapat ditekan berkali-kali (TERBUKTI untuk kode; INDIKASI untuk dampak)

`button2_Click` tidak memeriksa apakah thread polling sudah berjalan. Setiap klik membuat `CancellationTokenSource` baru dan thread baru yang menjalankan `LoopDat17` (`Diag.cs:1109-1120`). Thread lama tidak dihentikan karena token lama tidak dibatalkan. Dua loop kemudian berbagi `ftHandle` dan lima flag yang sama. Pembacaan `SendCommand` dari dua thread dapat saling mencuri byte. Dampak runtime **BELUM DIKETAHUI** tanpa pengujian, tetapi mekanismenya **TERBUKTI** dari kode.

---

## 4. Validasi respons dan klasifikasi kegagalan

### 4.1 Validasi di lapisan transport (TERBUKTI)

`SendCommand` (`Diag.cs:1271-1350`) melakukan:

1. `FT_Write` perintah (`Diag.cs:1281`).
2. Timeout internal `50 + 2 * commandSize` milidetik (`Diag.cs:1280`); untuk frame 5 byte menjadi 60 ms.
3. Pembacaan hanya jika `FT_GetQueueStatus` melaporkan `0 < jumlah < 256` (`Diag.cs:1301`).
4. Akumulasi byte sampai `num4 >= commandSize + 2` (`Diag.cs:1306`).
5. Panjang balasan diambil dari `array2[commandSize + 1]` (`Diag.cs:1312`) — yaitu byte setelah echo.
6. Frame dianggap lengkap jika `num4 - commandSize == num5` (`Diag.cs:1314`).
7. Salinan balasan adalah `num5` byte terakhir, sehingga echo dibuang (`Diag.cs:1318`).
8. Checksum Honda divalidasi (`Diag.cs:1319`, `1346-1348`).
9. Jika checksum salah, loop membaca terus sampai timeout; lalu `FT_Purge(3)` dan `return false` (`Diag.cs:1336-1339`).

Konsekuensi penting:

- Aplikasi **membutuhkan ECU yang menggemakan perintah**. Tanpa echo, `num4 - commandSize` tidak akan pernah sama dengan `num5`, sehingga selalu timeout. **INDIKASI** kuat; bentuk echo ECU nyata **BELUM DIKETAHUI**.
- Checksum divalidasi di transport, tetapi **hasil `false` diabaikan oleh semua pemanggil** di `Diag.cs` (`dat10` sampai `datD1` memanggil `SendCommand` tanpa memeriksa nilai balik). Parser kemudian membaca `array9` yang masih nol.

### 4.2 Validasi di lapisan parser (TERBUKTI)

Yang diperiksa hanya satu hal:

```csharp
if (array9[1] == 0x05) { tekXX = false; return; }
```

Tidak ada pemeriksaan:

- `array9[0] == 0x72` (awal frame),
- `array9[2] == 0x71` (byte fungsi),
- `array9[3] == subfungsi yang diminta`,
- panjang minimum terhadap indeks yang dibaca,
- status/kelas balasan selain panjang 5,
- apakah `SendCommand` mengembalikan `true`.

Akibatnya, balasan yang valid secara checksum tetapi berasal dari perintah lain, atau balasan pendek yang valid, tetap akan diparsing. **TERBUKTI** untuk tidak adanya pemeriksaan; dampak salah-baca **INDIKASI**.

Byte khusus yang benar-benar dipakai:

| Byte/nilai | Arti dalam kode | Lokasi |
|---|---|---|
| `array9[1] == 0x05` | Kelompok dianggap tidak didukung; flag dimatikan | `Diag.cs:575`, `818`, `873`, `924`, `986` |
| `array9[12] == 255` atau `array9[13] == 255` | ECT pindah ke byte fallback 8/9 | `Diag.cs:996-997` |
| `array9[4]` 0x00/0x01/0x02 | Kombinasi BAS/SSS/SSW/GGS | `Diag.cs:646-665` |
| `array9[8]` 0x00/0x01/0x04/0x05 | Status pompa | `Diag.cs:671-689` |
| `array9[10]` 0x80/0x10/0x08/0x04/0x02/0x01/0x20/0x00 | Posisi gigi | `Diag.cs:693-704` |
| `array9[18]` 128/103/102/60/89/121 | Mode altitude | `Diag.cs:1000-1035` |

Tidak ada validasi rentang umum. Nilai di luar tabel di atas jatuh ke `default` (misalnya SSW OFF, gigi "-", MODE 0), yang tampak seperti status sah. **TERBUKTI**.

### 4.3 Tabel kegagalan dan perilaku tampilan

| Kondisi | `SendCommand` | `array9` | Parser | Tampilan |
|---|---|---|---|---|
| Balasan normal | `true` | data valid | Menulis nilai | Nilai terbaru |
| Perintah tidak didukung, balasan 5 byte | `true` | `72 05 71 sub cksum` | `tekXX=false`, return | Nilai lama dipertahankan (tidak dikosongkan) |
| Timeout / tidak ada balasan | `false` | semua nol | Tidak ada cek `0x05`; menulis nol | RPM 0, ECT -40, TPS 0, dan seterusnya |
| Checksum salah terus-menerus | `false` setelah timeout | semua nol | Sama seperti timeout | Sama seperti timeout |
| Balasan pendek tetapi checksum valid | `true` | data + nol di sisa buffer | Membaca melewati data valid | Sebagian nilai nol, tanpa error |
| Balasan kosong | `false` | nol | Menulis nol | Sama seperti timeout |
| Semua kelompok dimatikan | tidak ada permintaan | — | — | UI membeku pada nilai terakhir |

Catatan: `array9` adalah `new byte[256]` lokal di setiap fungsi, sehingga selalu dimulai nol. Ini membedakan "tidak ada balasan" (nol) dari "nilai lama" (field UI tidak disentuh). **TERBUKTI**.

### 4.4 `TableType` bukan tipe tabel (TERBUKTI)

`dat17` mengisi `tableType = array9[2]` (`Diag.cs:1040`). Karena echo sudah dibuang dan balasan normal diawali `72 len 71 sub`, `array9[2]` selalu `0x71` (113). Baris grid 14 berlabel "TableType" karena itu menampilkan 113, bukan tipe tabel ECU. `dat10`, `dat11`, dan `dat13` mengisi nilai hardcoded 0x10/0x11/0x13; `dat16` mengisi `map11` akibat pergeseran argumen. Nilai yang terlihat adalah fungsi dari `dat` terakhir yang menang, bukan informasi tabel. **TERBUKTI**.

### 4.5 Sensor tidak tersedia vs kegagalan komunikasi

Tidak ada pembedaan di source:

- "Sensor tidak tersedia" pada level kelompok → kelompok dimatikan, nilai lama tetap; tidak ada label "N/A".
- "Kegagalan komunikasi" → nol ditulis; tidak ada label "timeout" atau "error".
- "Perintah tidak didukung" pada `dat20`/`datD1` → tidak terdeteksi; nilai turunan checksum atau label OFF.
- Tidak ada indikator status koneksi, kualitas sinyal, atau jumlah timeout di UI.

**TERBUKTI** untuk tidak adanya pembedaan. Ini adalah temuan utama yang relevan untuk RevCore.

---

## 5. Tujuh skenario

### Skenario 1 — Motor A dikenali

3D Chart tidak memiliki konsep "motor dikenali". Saat Start ditekan, `InitFtdiIso` hanya membuka FTDI dan melakukan wake; tidak ada pembacaan ID atau pencocokan model (`Diag.cs:1140-1269`). Semua lima kelompok dicoba. "Dikenali" dalam praktik berarti "ECU menjawab salah satu kelompok". **TERBUKTI** bahwa tidak ada jalur identifikasi.

### Skenario 2 — Motor B dikenali

Sama seperti skenario 1. Tidak ada perbedaan jalur berdasarkan model. Perbedaan hanya muncul dari balasan ECU: kelompok mana yang menjawab 5 byte dan kelompok mana yang menjawab data. **TERBUKTI**.

### Skenario 3 — Kelompok utama tidak didukung

Karena tidak ada "kelompok utama", semua kelompok diperlakukan sama. Jika satu kelompok menjawab 5 byte:

1. `tekXX` menjadi `false`.
2. Kelompok itu tidak dipanggil lagi pada iterasi berikutnya.
3. Tidak ada kelompok pengganti yang dipilih, karena kelompok lain sudah berjalan sendiri.
4. Baris yang hanya dipasok kelompok itu akan menampilkan nilai terakhirnya (jika tidak ditimpa kelompok lain) atau nol.

**TERBUKTI** untuk mekanisme; nilai akhir bergantung pada kelompok mana yang masih aktif (**INDIKASI** untuk tampilan konkret).

### Skenario 4 — Respons ada tetapi parser tidak cocok

Tidak ada deteksi ketidakcocokan. Contoh nyata di source:

- `dat16` mengirim argumen dengan urutan yang salah ke `UpdateGridView` (§2.5), sehingga APS/TP masuk ke baris TPS/ECT/IAT/MAP dan nilai dibulatkan. Cacat ini terlihat jika dat17 tidak aktif; jika dat17 aktif, hasilnya tertimpa.
- `dat17` selalu mengisi IAT/MAP dengan nol (§2.6), sehingga nilai dari kelompok lain terhapus.
- `dat20` membaca `array9[4]` dan `[5]` tanpa memeriksa panjang; balasan 5 byte menghasilkan nilai dari byte checksum (§2.7).
- Semua parser membaca indeks tetap; balasan pendek menghasilkan nol di sisa data.

**TERBUKTI** untuk kode; apakah ECU nyata mengirim bentuk yang memicu kasus ini **BELUM DIKETAHUI**.

### Skenario 5 — Sensor tidak tersedia

Tidak ada status "tidak tersedia". Sensor yang tidak ada dalam balasan akan tampil sebagai:

- nol (jika parser menulis nol karena timeout),
- nilai lama (jika kelompoknya dimatikan setelah sempat bekerja),
- "-" atau "OFF" (untuk switch di `datD1`, karena reset label),
- nilai turunan checksum (untuk `dat20` jika balasan 5 byte).

Tidak ada cara bagi pengguna untuk membedakan "sensor tidak ada" dari "komunikasi gagal". **TERBUKTI**.

### Skenario 6 — Dua kelompok memiliki sensor yang sama

Semua kelompok yang aktif dijalankan pada iterasi yang sama. Nilai akhir ditentukan oleh urutan pemanggilan (penulis terakhir), bukan oleh kualitas atau kesegaran data. Contoh:

- RPM ada di dat10, dat11, dat13, dat16, dat17 → nilai akhir dari dat17.
- ECT ada di kelima kelompok → nilai akhir dari dat17 (dengan fallback byte 12/13 ke 8/9).
- Baterai, injektor, advance, VSS juga tumpang tindih → nilai akhir dari dat17.
- IAT/MAP ditulis oleh dat10/11/13/16, lalu **dihapus menjadi nol** oleh dat17.

**TERBUKTI**.

### Skenario 7 — Semua alternatif gagal

Jika kelima kelompok menjawab 5 byte, semua flag menjadi `false`. Loop tetap berjalan, tetapi tidak ada permintaan `dat` yang dikirim. `dat20`/`datD1` juga tidak dipanggil karena berada di dalam blok `if` yang sudah tidak aktif. UI membeku pada nilai terakhir. Tidak ada pesan error, tidak ada penanda bahwa data tidak lagi diperbarui, dan tidak ada tombol probe ulang. Satu-satunya jalan keluar adalah menutup form dan membukanya kembali. **TERBUKTI**.

---

## 6. Jawaban delapan pertanyaan wajib

### 6.1 Apakah aplikasi memilih `dat` berdasarkan identitas motor/ECU?

**Tidak.** Tidak ada permintaan ID ECU, VIN, atau kode model pada jalur live data. Tujuh frame yang ada semuanya adalah permintaan data (`0x10`, `0x11`, `0x13`, `0x16`, `0x17`, `0x20`, `0xD1`). Form `Diag` tidak menerima parameter model dan tidak mereferensikan `Form1`. Pemilihan model di form utama hanya memengaruhi remap, bukan polling. **TERBUKTI**.

### 6.2 Apakah pemilihan otomatis atau manual?

**Otomatis sepenuhnya.** Tidak ada kontrol manual untuk memilih `dat` di `Diag.Designer.cs`. Satu-satunya input pengguna adalah Start, DTC, Reset, dan Exit. Otomatisasi ini bukan "pemilihan cerdas", melainkan "coba semua, matikan yang menjawab 5 byte". **TERBUKTI**.

### 6.3 Apakah satu motor bisa memakai beberapa kelompok `dat`?

**Ya.** Selama beberapa kelompok tidak menjawab 5 byte, semuanya dipanggil setiap siklus. Mereka bukan alternatif yang saling mengecualikan; mereka berjalan bersamaan dan saling menimpa baris grid yang sama. **TERBUKTI**.

### 6.4 Apakah tersedia fallback otomatis?

**Tidak untuk level kelompok.** Tidak ada tabel kelompok alternatif dan tidak ada logika "jika A gagal, pakai B". Yang ada:

- fallback byte ECT di dalam dat17 (b12/b13 → b8/b9 jika 255),
- pemanggilan `dat20` dan `datD1` tanpa syarat,
- penghentian permanen kelompok yang menjawab 5 byte, tanpa pengganti.

**TERBUKTI**.

### 6.5 Apa syarat sebuah kelompok dianggap cocok?

Hanya `array9[1] != 0x05` untuk dat10/11/13/16/17. Tidak ada syarat identitas respons, panjang minimum, status, atau kecocokan model. `dat20` dan `datD1` tidak memiliki syarat sama sekali. **TERBUKTI**.

### 6.6 Bagaimana membedakan sensor tidak tersedia dan kegagalan komunikasi?

**Tidak dibedakan.** Tidak ada status di UI, tidak ada kode error per sensor, dan tidak ada penanda "N/A". Kegagalan komunikasi menghasilkan nol; ketidaktersediaan kelompok menghasilkan nilai lama atau OFF. Pengguna tidak dapat membedakannya dari tampilan. **TERBUKTI**.

### 6.7 Bagaimana parser dan rumus ditentukan per sensor?

Hardcoded di dalam masing-masing fungsi `datXX`. Offset byte dan rumus ditulis tetap, tanpa tabel konfigurasi. Pemetaan ke baris grid juga hardcoded di `UpdateRows`/`UpdateRows2` (`Diag.cs:1069-1104`, `776-800`). Tidak ada registry parser, tidak ada metadata sensor, dan tidak ada validasi bahwa offset cocok dengan panjang balasan. **TERBUKTI**.

### 6.8 Mekanisme apa yang layak menjadi referensi RevCore?

Yang layak diambil adalah **konsep**, bukan implementasinya:

1. **Probe kapabilitas per perintah** — 3D Chart menunjukkan bahwa ECU dapat menolak perintah tertentu, dan aplikasi harus menyesuaikan diri. RevCore memerlukan probe yang eksplisit, bukan latch diam-diam.
2. **Pemisahan identitas dari live data** — 3D Chart memisahkan deteksi keluarga ECU (untuk flash) dari polling; RevCore sebaiknya memisahkan identitas ECU, profil live data, dan parser.
3. **Prioritas yang dideklarasikan** — RevCore perlu satu sumber kebenaran per sensor (single writer), bukan "penulis terakhir menang".
4. **Validasi berlapis** — identitas respons, panjang, checksum, dan rentang nilai harus diperiksa sebelum data dipakai.
5. **Status tri-state** — tersedia / tidak tersedia / gagal komunikasi harus terlihat di UI, bukan disamarkan sebagai nol.
6. **Fallback yang eksplisit** — daftar alternatif per sensor/kelompok, dengan alasan dan batas waktu, bukan pemanggilan tanpa syarat.
7. **Re-probe saat reconnect** — latch permanen 3D Chart adalah contoh yang harus dihindari.

Semua ini adalah rekomendasi desain. **Belum ada persetujuan untuk mengimplementasikannya di RevCore.**

---

## 7. Yang belum dapat dibuktikan

| Hal | Status | Alasan |
|---|---|---|
| Bentuk balasan ECU nyata untuk perintah yang tidak didukung | BELUM DIKETAHUI | Tidak ada capture K-line; asumsi 5 byte berasal dari kode |
| Apakah ECU nyata menggemakan perintah | BELUM DIKETAHUI | Tidak ada hardware; kode mensyaratkan echo |
| Kelompok `dat` mana yang didukung tiap model Honda | BELUM DIKETAHUI | Tidak ada tabel model di source live data |
| Apakah `0x05` selalu berarti "tidak didukung" | INDIKASI | Hanya dari panjang balasan; tidak ada dokumentasi |
| Efek runtime dari `Task.Delay` tanpa `await` | BELUM DIKETAHUI | Perlu pengukuran; kode menunjukkan tidak ada jeda |
| Dampak konkurensi dua loop Start | BELUM DIKETAHUI | Perlu pengujian; mekanisme terlihat di kode |
| Apakah `dat20` sengaja memakai little-endian | BELUM DIKETAHUI | Tidak ada komentar; berbeda dari parser lain |
| Arti semantik `TableType` | TERBUKTI bukan tipe tabel; arti sebenarnya BELUM DIKETAHUI | Nilainya `array9[2]` = 0x71 |
| Apakah `dat16` memang dimaksudkan untuk APS/TP | INDIKASI | Offset dan nama variabel mendukung, tetapi pemetaan tampilan salah |
| Perilaku `Form1.dat16` yang kosong | TERBUKTI kosong; alasan BELUM DIKETAHUI | Hanya memeriksa `0x05`, tidak mem-parsing |

---

## 8. Traceability bukti

| Temuan | File | Fungsi | Baris |
|---|---|---|---|
| Lima flag kapabilitas | `Diag.cs` | field kelas | 24-28 |
| Duplikat flag | `Form1.cs` | field kelas | 18583-18587 |
| Inisialisasi FTDI tanpa identitas | `Diag.cs` | `InitFtdiIso` | 1140-1269 |
| Urutan polling | `Diag.cs` | `LoopDat17` | 516-559 |
| Delay tidak di-await | `Diag.cs` | `LoopDat17` | 557 |
| Latch dat10 | `Diag.cs` | `dat10` | 575-579 |
| Latch dat11 | `Diag.cs` | `dat11` | 818-822 |
| Latch dat13 | `Diag.cs` | `dat13` | 873-877 |
| Latch dat16 | `Diag.cs` | `dat16` | 924-928 |
| Latch dat17 | `Diag.cs` | `dat17` | 986-990 |
| Frame dat10-datD1 | `Diag.cs` | masing-masing | 566, 631, 720, 809, 864, 915, 976 |
| Rumus dat10 | `Diag.cs` | `dat10` | 584-599 |
| Rumus dat11 + IAC | `Diag.cs` | `dat11` | 827-845 |
| Rumus dat13 | `Diag.cs` | `dat13` | 882-897 |
| Rumus dat16 | `Diag.cs` | `dat16` | 933-960 |
| Rumus dat17 + fallback ECT | `Diag.cs` | `dat17` | 993-1043 |
| Rumus dat20 | `Diag.cs` | `dat20` | 728-742 |
| Switch datD1 | `Diag.cs` | `datD1` | 642-706 |
| `datD1` dipanggil dari `dat20` | `Diag.cs` | `dat20` | 748 |
| Signature `UpdateGridView` | `Diag.cs` | `UpdateGridView` | 1053 |
| Pemetaan baris grid1 | `Diag.cs` | `UpdateRows` | 1069-1104 |
| Pemetaan baris grid2 | `Diag.cs` | `UpdateRows2` | 776-800 |
| Start tanpa guard | `Diag.cs` | `button2_Click` | 1109-1120 |
| DTC/Reset tidak reset flag | `Diag.cs` | `button3_Click`, `button4_Click` | 1362-1390 |
| SendCommand echo/length/checksum | `Diag.cs` | `SendCommand` | 1271-1350 |
| Pembukaan Diag tanpa model | `Form1.cs` | `button7_Click` | 19238-19241 |
| Combo model untuk remap | `Form1.cs` | `ComboBox1_SelectedIndexChanged` | 3362 |
| Deteksi ECU dari BIN | `Form1.cs` | `GetEcuType` | 1052-1105 |
| Loop Form1 dan delay 50 ms | `Form1.cs` | `LoopDat17` | 19139-19173 |
| `Form1.dat16` kosong | `Form1.cs` | `dat16` | 18722-18735 |
| Kontrol form Diag | `Diag.Designer.cs` | deklarasi kontrol | 172-180 |

---

## 9. Batas pekerjaan

Dokumen ini hanya memahami dan mendokumentasikan arsitektur pemilihan kelompok `dat` 3D Chart. Tidak ada perubahan pada source RevCore, APK, database kendaraan, file MAP, parser, rumus, atau mekanisme fallback. Tidak ada patch, ZIP, atau publikasi binary. Tidak ada klaim verifikasi hardware. Semua keputusan pengembangan tetap menunggu persetujuan langsung dari Otoy.
