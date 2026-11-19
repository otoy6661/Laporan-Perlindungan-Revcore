# H-Diag — Function Mapping

Tujuan: memetakan komponen H-Diag ke mekanisme teknis, bukan sekadar daftar fitur.

## 1. Peta modul

| Komponen | Bukti | Fungsi | Status |
|---|---|---|---|
| `MainWindow` | String/metode `select_type`, `setup_table`, `connect_clicked`, `send_clicked`, `print_data`, `print_table`, `mil_action`, `cleardtc_clicked`, `kline_command`, `closeEvent` | UI, tabel live data, koneksi, DTC | FAKTA (nama), REKONSTRUKSI (alur) |
| `UsbSerial` | `findFtdi`, `ftdiSetDesc`, `Connect`, `Disconnect`, `testConnection`, `writeData*`, `readData*`, `sendlog`, `delay` | Transport FTDI/libusb | FAKTA |
| Login | `login.ini`, string `Login`, `No key set.`, `Invalid version or not a cyphertext.` | Lisensi offline | FAKTA |
| Frame builder | VA `0x405120` (DTC), `0x407329` (live polling) | Konstruksi frame 5/7 byte | FAKTA |
| Checksum helper | Dipanggil `0x409AF0` per potongan frame | Menambahkan checksum K-line | REKONSTRUKSI |
| Read helper | `0x409760` | Baca antrean respons | REKONSTRUKSI |
| Response parser | `0x405F90`–`0x406A91` | Dispatch respons → baris tabel | REKONSTRUKSI |
| DTC parser | `0x405120` + blok `0x405700`–`0x405F90` | Kirim halaman DTC, format kode | SEBAGIAN |
| Delay | `0x404AB0` | Delay milidetik | FAKTA (100 ms/50 ms/1000 ms) |

## 2. Model tabel Live Data

Tabel diinisialisasi pada `0x402407`–`0x40295C`. Setiap label disimpan pada `[list + 0x60 + 4*row]`, sehingga urutan baris adalah:

| Row | Label | Relevansi |
|---:|---|---|
| 0 | STF - Campuran Bahan Bakar | RevCore #9 |
| 1 | POM - Pompa Bahan Bakar | RevCore #4 |
| 2 | SS - Standar Samping | RevCore #6 |
| 3 | STS - Switch Starter | RevCore #5 |
| 4 | SSW - Switch Starter | RevCore #5 |
| 5 | FIS - Fast Idle Switch | RevCore #7 |
| 6 | MOD - Mode Altitude | RevCore #10 |
| 7 | ALT - Koreksi Altitude | RevCore #10 |
| 8 | (kosong) | — |
| 9 | SCS - Service Check Signal | — |
| 10 | MIL - Jumlah Kode Error | DTC |
| 11 | MILV | DTC |
| 12 | IAC - Katup Udara Masuk | RevCore #8 |
| 13 | VSS - Sensor Kecepatan | — |
| 14 | PUL | — |
| 15 | EVA - Status Evaporator | — |
| 16 | PR - Pair Control | — |
| 17 | TPS 1 - Posisi Throttle 1 | — |
| 18 | TPS 2 - Posisi Throttle 2 | — |
| 19 | TPSV1 | — |
| 20 | TPSV2 | — |
| 21 | APS 1 - Posisi Handle Gas 1 | — |
| 22 | APS 2 - Posisi Handle Gas 2 | — |
| 23 | APSV1 | — |
| 24 | APSV2 | — |
| 25 | APS-K - Korelasi APS 1 dan APS 2 | — |
| 26 | EOP - Sensor Tekanan Oli | — |
| 27 | EGCV - Kontrol Katup Gas Buang | — |
| 28 | EXI - Muatan eksitasi motor | — |
| 29 | GG - Gigi Transmisi | — |

Bukti: `03_EVIDENCE/HDIAG_STATIC_EVIDENCE.md` E-HD-02.

## 3. Loop Live Data

Counter global `0x421420`:

```
counter < 0x0C  -> 72 05 60 03 26
counter == 0x0C -> 72 05 71 00 18
counter == 0x0D -> 72 05 00 F1 98
setelah frame     -> delay 100 ms
                  -> read
                  -> counter++
counter == 0x0E  -> update status koneksi, pause 1000 ms, reset siklus
```

Arti fungsional tiap frame **belum terbukti**. Frame B (`fn=0x71, sub=0x00`) adalah kandidat kuat untuk snapshot live data karena fungsi `0x71` juga dipakai seluruh polling 3D Chart. Frame C (`fn=0x00, sub=0xF1/0x98`) belum diketahui; kemungkinan keep-alive atau status ECU (DUGAAN).

## 4. Parser respons

Dispatch pada nilai `edx`. Bukti terkuat:

| Key | Aksi | Baris |
|---:|---|---|
| 8 | tulis kolom 3 baris `0x0C` dari teks `edi+0x0D`; kolom 2 baris `0x14` dari `edi+1` | `0x405F90` |
| 0x14 | baris `0x0F` ← `edi+0x0D`; baris `0x1B` ← `edi+0x0B`/`+0x0C`; baris `0x1E` ← `edi` | `0x405FDF` |
| 0xC | konversi QString dari `edi` (tanpa bukti baris) | `0x4060A4` |
| 7 | konversi QString dari `edi-1` (tanpa bukti baris) | `0x4066B8` |

Karena nilai dikonversi dengan panjang 0 (string NUL-terminated), respons untuk baris-baris tersebut berisi **teks desimal ASCII**, bukan angka biner. Ini berbeda dari 3D Chart yang memakai byte biner. Implikasi untuk RevCore: jangan mengasumsikan layout respons H-Diag sama dengan 3D Chart meskipun frame request identik.

## 5. DTC

- Fungsi `0x405120` mengirim halaman DTC 0..5.
- Handler memanggil halaman berikutnya berdasarkan counter `0x421424`, dengan jeda 50 ms (`0x32`).
- Kode DTC diformat dengan konversi basis 10 dan string di `0x413488`, `0x413400`, `0x4133C4`.
- Halaman 1 (`72 05 73 00 16`) adalah request yang dipakai ulang di jalur pembacaan.

## 6. Handshake

Blok `0x405F28`–`0x406A9x` memuat rangkaian frame pendek dengan pasangan (checksum, panjang, fungsi) seperti `0x23/2`, `0x24/2`, `0x1D/2`, `0x0D/3`, `0x14/2`, `0x10/3`, `0x1B/2`, `0x1B/3`, `0x1E/2`. Ini konsisten dengan pembukaan sesi K-line, tetapi urutan final dan arti tiap state belum direkonstruksi.

## 7. Pemilihan kendaraan / tipe tabel

Daftar model mencakup SCOOPY, BEAT, VARIO, PCX, CBR, CRF, dan lainnya. Pemilihan model mengubah `setup_table` (jumlah baris/kolom). Hubungan model → set parameter yang didukung **belum** dipetakan karena tabel per model tidak tersedia sebagai data terpisah; kemungkinan dibentuk di kode (DUGAAN).

## 8. Kesimpulan pemetaan

| Pertanyaan | Jawaban |
|---|---|
| Apakah H-Diag punya modul live data? | Ya (loop + tabel) |
| Apakah parameter RevCore 4–10 ada di UI? | Ya, kecuali FID dan "Relay" (tidak ada string) |
| Apakah perintah tiap parameter terbukti? | Tidak sepenuhnya; hanya frame polling kolektif |
| Apakah parsing tiap parameter terbukti? | Sebagian (IAC, TPSV2, EVA, EGCV, satu baris tak dikenal) |
| Apakah ada set Altitude Mode? | Tidak ditemukan |
