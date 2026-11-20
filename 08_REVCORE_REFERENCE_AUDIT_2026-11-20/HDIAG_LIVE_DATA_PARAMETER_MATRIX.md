# H-DIAG LIVE DATA PARAMETER MATRIX

Work order §2: daftar parameter per profil, request per parameter, struktur respons,
rumus, polling, dan koreksi label/unit.

Sumber: `HDiag.exe` SHA-256 `10100b3491b056942aeb9e74ed604131a51c8445aea071bd0cace7270f265dcf`.
Kelas bukti mengikuti §7 (A/B/C/D). **Tidak ada kelas D** — tidak ada ECU fisik.

---

## 1. Ringkasan yang terbukti vs belum

| Pertanyaan work order | Jawaban | Kelas |
|---|---|---|
| Berapa profil kendaraan? | 25 entri combo `Type` | A |
| Apakah daftar parameter tiap profil sama? | Tidak; label dipilih saat setup model. Jumlah yang tampak: 17/19/22 menurut pengamatan pemilik; konstanta 0x11/0x13/0x16 ada di blok setup | B |
| Apakah ada request per parameter? | Tidak. Tiga frame blok | A |
| Struktur respons? | Satu blok per frame, dipecah ke baris UI | A (keberadaan), C (pemetaan byte) |
| Rumus/skala/offset? | Tidak terbaca sebagai konstanta; nilai tampak diformat sebagai teks | C |
| Polling/interval? | 100 ms per langkah, siklus 15 langkah | A |
| Timeout/retry? | Retry baca 1×; timeout tidak terbaca | A / C |
| Urutan? | `60 03` ×12 → `71 00` → `00 F1` → selesai | A |
| DTC | 5 frame baca + 2 frame clear | A |
| Identifikasi ECU | Tidak ada request khusus | C |

---

## 2. Katalog label (union, bukan per profil)

Label dibangun oleh `FUN_00401710`. Angka `*V` adalah baris nilai tambahan
(mis. `TPSV` = tegangan TPS). Semua label berikut **ada** di binary.

### 2.1 Mesin dan bahan bakar

| Label | Arti | Satuan tertulis | Rumus |
|---|---|---|---|
| `RPM - Putaran Mesin` | putaran mesin | tidak tertulis di label | C |
| `RPMV` | baris nilai RPM | — | C |
| `TPS - Posisi Throttle` | posisi throttle | tidak tertulis | C |
| `TPSV` | tegangan TPS | C | C |
| `EOT - Suhu Oli` | suhu oli | C | C |
| `EOTV` | tegangan EOT | C | C |
| `ECT - Suhu Air Pendingin` | suhu coolant | C | C |
| `ECTV` | tegangan ECT | C | C |
| `IAT - Suhu Udara Masuk` | suhu udara masuk | C | C |
| `IATV` | tegangan IAT | C | C |
| `MAP - Tekanan Udara Manifold` | tekanan manifold | C | C |
| `MAPV` | tegangan MAP | C | C |
| `INJ - Lebar Pulsa Injektor` | lebar pulsa injektor | C | C |
| `ADV - Sudut Pengapian` | sudut pengapian | C | C |
| `STF - Campuran Bahan Bakar` | fuel trim | C | C |
| `O2 - Sensor Oksigen` | sensor O2 | C | C |
| `O2V` | tegangan O2 | C | C |
| `BAT - Tegangan Baterai` | tegangan baterai | `Volt` (string terpisah) | C |
| `IAC - Katup Udara Masuk` | IACV | C | C |
| `VSS - Sensor Kecepatan` | kecepatan | C | C |
| `PUL` | pulsa kecepatan | C | C |
| `GG - Gigi Transmisi` | gigi | C | C |

### 2.2 Switch, status, dan aktuator

| Label | Arti | Nilai | Rumus |
|---|---|---|---|
| `POM - Pompa Bahan Bakar` | status pompa | ON/OFF? | C |
| `FAN - Kipas Pendingin` | status fan | ON/OFF? | C |
| `SS - Standar Samping` | side stand | ON/OFF? | C |
| `STS - Switch Starter` | starter switch | ON/OFF? | C |
| `SSW - Switch Starter` | starter switch (kedua) | ON/OFF? | C |
| `FIS - Fast Idle Switch` | fast idle | ON/OFF? | C |
| `SCS - Service Check Signal` | SCS | ON/OFF? | C |
| `MIL - Jumlah Kode Error` | jumlah kode MIL | angka | C |
| `MILV` | baris nilai MIL | — | C |
| `EVA - Status Evaporator` | evaporator | C | C |
| `PR - Pair Control` | pair control | C | C |
| `BAS - Sensor Kemiringan` | bank angle | C | C |
| `BASV` | tegangan BAS | C | C |
| `EXI - Muatan eksitasi motor` | eksitasi | C | C |

### 2.3 Altitude dan ride-by-wire

| Label | Arti | Rumus |
|---|---|---|
| `MOD - Mode Altitude` | mode altitude | C |
| `ALT - Koreksi Altitude` | koreksi altitude | C |
| `TPS 1 - Posisi Throttle 1` | TPS1 | C |
| `TPS 2 - Posisi Throttle 2` | TPS2 | C |
| `TPSV1` / `TPSV2` | tegangan TPS1/2 | C |
| `APS 1 - Posisi Handle Gas 1` | APS1 | C |
| `APS 2 - Posisi Handle Gas 2` | APS2 | C |
| `APSV1` / `APSV2` | tegangan APS1/2 | C |
| `APS-K - Korelasi APS 1 dan APS 2` | korelasi APS | C |
| `EOP - Sensor Tekanan Oli` | tekanan oli | C |
| `EGCV - Kontrol Katup Gas Buang` | EGCV | C |

Catatan: kolom "Satuan" hanya terisi bila string satuan benar-benar ditemukan.
Selain `Volt`, satuan tidak berdiri sendiri; kemungkinan menempel pada format
nilai, sehingga tidak dapat diekstrak sebagai tabel.

---

## 3. Matriks profil (sejauh bukti mengizinkan)

Pengamatan pemilik (bukan hasil binary, dicatat sebagai B):

| Profil | Jumlah parameter (pemilik) | Kelompok parameter (pemilik) |
|---|---|---|
| BEAT | 17 | RPM, TPS, EOT, INJ, ADV, BAT, O2, POM, SS, STS, SSW, FIS, MOD, STF, ALT, SCS, MIL |
| SCOOPY | 17 | sama |
| SPACY | 17 | sama |
| VARIO 125 | 17 | sama |
| VARIO 150 | 17 | sama |
| PCX | 19 | 17 + 2 (tidak dirinci) |
| CBR 250 NEW | 22 | 19 + 3 (tidak dirinci) |

Verifikasi terhadap binary:

| Item | Hasil | Kelas |
|---|---|---|
| 25 entri model | Cocok | A |
| Label 17/19/22 parameter kelompok di atas | Semua label ada di katalog union | A |
| Konstanta 0x11/0x13/0x16 | Ada di blok setup; cocok dengan 17/19/22 | A |
| Arti konstanta sebagai "jumlah" | Tidak konsisten dengan pemakaian sebagai id baris di `0x406ad0` | B |
| Subset tepat per model | Tidak berhasil diekstrak | C |
| Dua parameter tambahan PCX | Tidak teridentifikasi | C |
| Tiga parameter tambahan CBR 250 New | Tidak teridentifikasi | C |

**Kesimpulan matriks:** katalog union dan jumlah profil dapat dipertanggungjawabkan;
sub-set per model **tidak**. Work order meminta "temukan seluruh perbedaannya" —
jawaban jujurnya: perbedaan itu ada, tetapi binary belum menyerahkannya sebagai
tabel yang dapat dibaca tanpa menjalankan aplikasi atau menguji UI-nya satu per satu.
Langkah lanjut yang sah: menjalankan H-Diag dengan adaptor FTDI asli dan mencatat
baris yang tampil per model. Itu memerlukan perangkat keras, di luar mode READ-ONLY
audit ini.

---

## 4. Request dan respons

### 4.1 Request (A. FACT)

| Nama | Frame | Panjang | Kapan |
|---|---|---|---|
| R1 | `72 05 60 03 26` | 5 | counter 0..11 |
| R2 | `72 05 71 00 18` | 5 | counter 12 |
| R3 | `72 05 00 F1 98` | 5 | counter 13 |

Header `0x72`, panjang `0x05`, checksum two's complement. Semua frame lima byte.
Tidak ada parameter yang punya request sendiri.

### 4.2 Respons (A untuk alur, C untuk isi)

```
PC ──(R1/R2/R3)──► adaptor FTDI ──K-Line──► ECU
PC ◄──(blok byte)── adaptor ◄──K-Line────── ECU
        │
        ├─ 0x409760  baca buffer
        ├─ pemecah    indeks → QString
        └─ 0x406ad0   tempel ke baris UI
```

- Panjang blok, jumlah field, dan indeks byte tidak terbaca sebagai struktur
  statis. Pemecah menerima indeks dan mengembalikan teks.
- **C. UNVERIFIED:** offset tiap parameter, endianness, dan apakah ECU mengirim
  biner atau teks.

### 4.3 Perbandingan dengan model request RevCore

| Aspek | H-Diag | RevCore |
|---|---|---|
| Gaya | 3 frame blok | 7 tabel (`17/13/11/10/16/20/D1`) |
| Request per parameter | tidak | tidak |
| Polling | 100 ms | 300 ms per tabel + 2 ms jeda |
| Pemetaan field | tidak terbaca | tabel offset eksplisit (dari firmware FlashPro) |
| Verifikasi field | UI saja | unit test + provenance firmware |

Perbedaan ini wajar: H-Diag adalah aplikasi PC tertutup, sedangkan RevCore dibangun
dari dekompilasi firmware FlashPro. Jangan menyamakan frame H-Diag dengan frame
RevCore tanpa uji.

---

## 5. Koreksi label, unit, dan format

| Isu | Temuan | Kelas |
|---|---|---|
| `EOT` vs `ECT` | Keduanya ada; profil tertentu memakai EOT (suhu oli) | A |
| Dua label starter (`STS`, `SSW`) | Keduanya ada; arti fisik berbeda belum pasti | A/C |
| `MIL` | Berupa "jumlah kode error", bukan lampu | A |
| `STF` | Fuel trim, bukan AFR | A |
| Satuan | Hanya `Volt` yang berdiri sendiri | A |
| Desimal/koma | Tidak terbaca; format `QString` runtime | C |
| Indikator ON/OFF | Tidak terbaca; kemungkinan teks | C |

---

## 6. DTC — tabel request

| Tahap | Frame | Kelas |
|---|---|---|
| Blok D0 | `72 07 72 D0 00 0E 37` | A |
| Blok D1 | `72 07 72 D1 00 06 3E` | A |
| Kode 73/00 | `72 05 73 00 16` | A |
| Kode 73/01 | `72 05 73 01 15` | A |
| Kode 74/01 | `72 05 74 01 14` | A |
| Clear 60/01 | `72 05 60 01 28` | A |
| Clear D0/14/02 | `72 07 72 D0 14 02 2F` | A |

Format dictionary: `nama#kondisi#tindakan`, Bahasa Indonesia. Contoh yang terbaca:
`Error pada TBW#Kesalahan fungsi pegas pengembali TBW#-`.
Jumlah entri dictionary belum dihitung tuntas; kelas A untuk keberadaan, C untuk
kelengkapan.

---

## 7. Yang tidak dapat disimpulkan

1. Subset parameter per model (17/19/22) — C.
2. Dua parameter tambahan PCX dan tiga tambahan CBR 250 New — C.
3. Offset dan skala setiap parameter — C.
4. Timeout dan retry ECU — C.
5. Apakah `72 05 60 03 26` adalah "polling cepat" parameter utama — B.
6. Apakah clear DTC benar-benar di-ACK — C.

Butir 1–4 memerlukan eksekusi aplikasi dengan adaptor asli atau uji ECU; tidak
dapat diselesaikan dengan membaca file saja. Karena itu tidak ada klaim "audit
hardware selesai".
