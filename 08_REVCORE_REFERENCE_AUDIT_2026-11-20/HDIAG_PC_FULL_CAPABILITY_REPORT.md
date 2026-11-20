# H-DIAG PC — FULL CAPABILITY REPORT

Work order: `REVCORE FULL REFERENCE AUTOPSY & FTDI K-LINE COMPATIBILITY AUDIT`
Mode: READ-ONLY. Sumber tidak diubah, tidak disalin ke RevCore.
Tanggal audit: 2026-11-20.

Kelas bukti yang dipakai (sesuai §7 work order):

| Kelas | Arti |
|---|---|
| **A. FACT** | Terbaca langsung dari byte, string, konstanta, atau instruksi di file referensi. |
| **B. INFERENCE** | Simpulan logis dari beberapa fakta; belum diuji. |
| **C. UNVERIFIED** | Belum dapat dibuktikan dari file maupun perangkat. |
| **D. HARDWARE VERIFIED** | Diuji pada ECU fisik dengan kondisi dan hasil tercatat. |

**Kelas D pada dokumen ini: tidak ada.** Tidak ada ECU Honda yang terhubung selama audit.

---

## 1. Identitas dan lingkungan aplikasi

| Item | Nilai | Kelas |
|---|---|---|
| File | `C:\Program Files (x86)\H-Diag\HDiag.exe` (salinan audit: `input\HDiag.exe`) | A |
| Ukuran | 175.104 byte | A |
| SHA-256 | `10100b3491b056942aeb9e74ed604131a51c8445aea071bd0cace7270f265dcf` | A |
| Format | PE32 GUI, image base `0x400000`, 32-bit | A |
| Toolkit | Qt 5 (Core/Gui/Widgets/Network/Qml/Quick), `libusb-1.0`, `libFTDI` (`ftdi_*`), `SimpleCrypt` | A |
| Kelas fungsi | `MainWindow`, `UsbSerial`, `SimpleCrypt`, `logindialog` | A |
| Artefak | `login.ini`, pembacaan FTDI Chip-ID, enkripsi `SimpleCrypt` | A (string + fungsi), algoritma lisensi tidak didekripsi |

Catatan etika: modul lisensi tidak dibongkar dan tidak dilewati. Yang dicatat hanya
keberadaannya, karena ia menjelaskan mengapa aplikasi ini hanya mau berjalan dengan
adaptor FTDI tertentu.

---

## 2. Struktur aplikasi (A. FACT)

Fungsi utama yang ditemukan pada dump simbol/string:

- `MainWindow::connect_clicked` — membuka adaptor dan memulai sesi.
- `MainWindow::send_clicked` — mengirim perintah manual.
- `MainWindow::print_data(QString)` — menulis baris log/teks.
- `MainWindow::cleardtc_clicked` — jalur clear DTC dari UI.
- `MainWindow::closeEvent`, `MainWindow::keyPressEvent`.
- `UsbSerial::findFtdi`, `UsbSerial::ftdiSetDesc`, `UsbSerial::Connect`, `UsbSerial::logindialog`.
- `SimpleCrypt::encryptToByteArray` / `decryptToByteArray`.
- String internal: `print_data`, `kline_command`, `mil_action`, `cleardtc_clicked`.

**B. INFERENCE:** `kline_command` dan `mil_action` menunjukkan bahwa komunikasi
K-Line dipusatkan pada satu fungsi pengirim, dan ada aksi yang berkaitan dengan MIL.
Isi aksi MIL tidak dapat dipastikan hanya dari nama; tidak ada tombol actuator test
yang terbukti.

---

## 3. Daftar kendaraan (A. FACT)

Combo `Type` diisi 25 entri, urut sesuai string di `.rdata`:

1. SCOOPY
2. BEAT
3. SPACY
4. VARIO 110
5. VARIO 125
6. PCX
7. SUPRA X
8. SUPRA X AFS
9. REVO AT
10. BLADE
11. VERZA
12. CB 150 R
13. CBR 150
14. CBR 250
15. VARIO 150
16. BEAT POP
17. REVO FI
18. MEGAPRO FI
19. CB150R NEW
20. SONIC
21. SUPRA GTR
22. CBR150 K45G
23. CBR250 NEW
24. CRF150
25. CRF250

Pengamatan pemilik menyebut Beat, Scoopy, Spacy, Vario 125, Vario 150, PCX, dan
CBR 250 New. Semua nama itu ada di daftar. Nama "CBR 250 New" di binary tertulis
`CBR250 NEW`; "CBR 150" dan "CBR150 K45G" adalah dua entri berbeda.

---

## 4. Katalog label parameter (A. FACT)

Satu pembangun UI (`FUN_00401710`) membuat pasangan label/nilai. Label yang
direferensikan fungsi ini (urutan kemunculan di string table):

| Kelompok | Label |
|---|---|
| Mesin | `RPM - Putaran Mesin`, `RPMV`, `TPS - Posisi Throttle`, `TPSV`, `EOT - Suhu Oli`, `EOTV`, `ECT - Suhu Air Pendingin`, `ECTV`, `IAT - Suhu Udara Masuk`, `IATV`, `MAP - Tekanan Udara Manifold`, `MAPV`, `INJ - Lebar Pulsa Injektor`, `ADV - Sudut Pengapian`, `FAN - Kipas Pendingin`, `STF - Campuran Bahan Bakar`, `GG - Gigi Transmisi`, `IAC - Katup Udara Masuk`, `VSS - Sensor Kecepatan`, `PUL` |
| Bahan bakar / emisi | `O2 - Sensor Oksigen`, `O2V`, `POM - Pompa Bahan Bakar`, `EVA - Status Evaporator` |
| Kelistrikan | `BAT - Tegangan Baterai`, `BAS - Sensor Kemiringan`, `BASV`, `EXI - Muatan eksitasi motor` |
| Switch / status | `SS - Standar Samping`, `STS - Switch Starter`, `SSW - Switch Starter`, `FIS - Fast Idle Switch`, `SCS - Service Check Signal`, `MIL - Jumlah Kode Error`, `MILV`, `PR - Pair Control` |
| Altitude | `MOD - Mode Altitude`, `ALT - Koreksi Altitude` |
| Ride-by-wire | `TPS 1 - Posisi Throttle 1`, `TPS 2 - Posisi Throttle 2`, `TPSV1`, `TPSV2`, `APS 1 - Posisi Handle Gas 1`, `APS 2 - Posisi Handle Gas 2`, `APSV1`, `APSV2`, `APS-K - Korelasi APS 1 dan APS 2`, `EOP - Sensor Tekanan Oli`, `EGCV - Kontrol Katup Gas Buang` |

Total kandidat label: 46 baris teks (termasuk varian `*V`). Ini **katalog union**,
bukan daftar per kendaraan. Label yang dipakai tiap model dipilih saat setup model.

**Penting:** tidak ditemukan tabel parameter per model yang bisa dibaca langsung
sebagai array. Setup model memanggil `0x406ad0(row, 2, row)` (pengisi sel tabel)
dengan id baris tertentu. Konstanta `0x11`, `0x13`, `0x16` (17/19/22) muncul di
blok setup model dan **cocok** dengan hitungan pengamatan pemilik, tetapi
pemetaan baris-ke-parameter tiap model belum berhasil diekstrak satu per satu.
Status pemetaan per model: **C. UNVERIFIED** (lihat `HDIAG_LIVE_DATA_PARAMETER_MATRIX.md`).

---

## 5. Alur Live Data (A. FACT + B. INFERENCE)

Loop polling berada di `0x407329`–`0x40750f`. Perilakunya:

1. Penghitung global `[0x421420]` menentukan frame yang dikirim.
2. `counter < 0x0C` → basis frame `72 05 60` dengan word tetap `03 26`
   (hasil akhir `72 05 60 03 26`).
3. `counter == 0x0C` → basis `72 05 71` dengan word `00 18`
   (`72 05 71 00 18`).
4. `counter == 0x0D` → basis `72 05 00` dengan word `F1 98`
   (`72 05 00 F1 98`).
5. Frame dirakit saat runtime; checksum dihitung helper `0x409af0`.
6. Jeda 100 ms (`0x404ab0` dengan argumen `0x64`) sebelum membaca.
7. Baca respons lewat `0x409760`; jika kosong, satu pembacaan ulang dilakukan.
8. Penghitung naik; pada `0x0E` dicetak `Connected-Clear DTC Done.`, nilai
   direset ke 0, dan tabel dipilih ulang.
9. Respons dipecah lalu nilai dikirim ke baris UI lewat `0x403b70`/`0x406ad0`.

**B. INFERENCE:** siklus 15 langkah × 100 ms berarti satu putaran penuh sekitar
1,5 detik, dengan 12 langkah pertama berisi frame yang sama (kemungkinan polling
cepat parameter utama) dan tiga langkah terakhir untuk tabel tambahan. Pembagian
12 langkah identik ini belum dapat dipastikan maknanya.

### 5.1 Tabel request Live Data

| # | Frame | Checksum | Dipakai saat | Bukti |
|---|---|---|---|---|
| L1 | `72 05 60 03 26` | `26` | counter 0..11 | A (loop) |
| L2 | `72 05 71 00 18` | `18` | counter 12 | A (loop) |
| L3 | `72 05 00 F1 98` | `98` | counter 13 | A (loop) |

Tidak ada request per parameter. Ketiga frame ini mengembalikan satu blok data;
aplikasi memecah blok itu menjadi banyak baris. Ini berbeda dari model
"request per parameter" dan penting untuk perbandingan dengan RevCore.

### 5.2 Struktur respons dan parser

- Pembacaan dilakukan oleh `0x409760` (transport read).
- Respons dipecah dan tiap nilai diformat menjadi teks `QString`, lalu ditempel
  ke baris tabel berdasarkan id baris tetap.
- Fungsi pembagi respons (`0x403b70` / `0x405120`) menerima indeks dan parameter;
  pemetaan indeks byte → parameter **belum** berhasil diturunkan menjadi tabel
  offset yang dapat diuji.
- **C. UNVERIFIED:** rumus skala/offset per parameter (mis. RPM, ECT, MAP) tidak
  terbaca sebagai konstanta aritmetika sederhana; sebagian besar nilai tampak
  sudah berupa angka jadi dari ECU atau hasil format teks.

Konsekuensi: H-Diag **tidak** menyediakan rumus konversi yang bisa dipindahkan
begitu saja. Yang terbukti hanyalah request, urutan polling, dan bahwa nilai
ditampilkan sebagai teks.

---

## 6. DTC (A. FACT)

Frame DTC yang ditemukan di jalur baca/clear:

| Fungsi | Frame | Checksum | Catatan |
|---|---|---|---|
| Baca blok DTC | `72 07 72 D0 00 0E 37` | `37` | 7 byte, sub D0 |
| Baca blok DTC | `72 07 72 D1 00 06 3E` | `3E` | 7 byte, sub D1 |
| Baca kode | `72 05 73 00 16` | `16` | 5 byte |
| Baca kode | `72 05 73 01 15` | `15` | 5 byte |
| Baca kode | `72 05 74 01 14` | `14` | 5 byte |
| Clear (dari `cleardtc_clicked`) | `72 05 60 01 28` | `28` | service 0x60 |
| Clear (jalur DTC) | `72 07 72 D0 14 02 2F` | `2F` | sub D0 + 0x14/0x02 |

- Daftar kode error disimpan sebagai string Indonesia berformat
  `nama#kondisi#tindakan` (contoh: `Error pada TBW#Kesalahan fungsi pegas
  pengembali TBW#-`, `Error pada ECM#Kesalahan fungsi prosesor ECM#-`).
- `MainWindow::cleardtc_clicked` mengirim frame clear, lalu loop utama menandai
  `Connected-Clear DTC Done.` saat penghitung mencapai `0x0E`.
- **C. UNVERIFIED:** apakah ECU menjawab, format ACK, dan apakah clear benar-benar
  menghapus memori DTC. Tidak ada ECU saat audit.

Perbedaan penting dengan RevCore: H-Diag memakai `72 07 72 D0/D1` dan `73 00/01`,
sedangkan RevCore memakai `74/01`, `71/20`, `00/00`. Keduanya belum terbukti;
jangan saling menggantikan tanpa uji.

---

## 7. Identifikasi ECU (B. INFERENCE)

- `72 05 71 00 18` juga dipakai Loop Live Data (counter 12). Di H-Diag tidak ada
  layar "ECU Info" terpisah yang terbukti; identifikasi tampaknya menumpang pada
  data yang sama.
- Tidak ditemukan request khusus part number seperti `72 05 71 00 18` + offset
  atau `72 07 72 00 00 05 10`; yang ada hanya tiga frame loop.
- **C. UNVERIFIED:** apakah H-Diag benar-benar menampilkan ID ECU/part number.
  Label yang tersedia hanya parameter live, bukan field identitas.

---

## 8. Fungsi lain (A. FACT atas keberadaan, C untuk perilaku)

| Fungsi | Bukti | Status |
|---|---|---|
| Kirim perintah manual (`send_clicked`) | nama fungsi + `kline_command` | Ada; format input tidak dianalisis |
| Log/print (`print_data`) | nama fungsi + pemakaian di loop | Ada; tujuan (layar/file) belum dipastikan |
| Aksi MIL (`mil_action`) | string `mil_action` | Ada nama; belum terbukti mengirim perintah |
| Clear DTC | `cleardtc_clicked` + frame | Ada; hasil ECU belum terverifikasi |
| Actuator test | tidak ditemukan string/request | Tidak terbukti ada |
| Coding/registration | tidak ditemukan | Tidak terbukti ada |

Tidak ada bukti H-Diag melakukan penulisan EEPROM, registrasi smartkey, atau
fungsi immobilizer. Aplikasi ini tampaknya murni diagnostik PGM-FI.

---

## 9. Timing, retry, dan error handling

| Aspek | Nilai | Kelas |
|---|---|---|
| Jeda antar frame loop | 100 ms (`0x64`) | A |
| Siklus | 0..14, lalu reset | A |
| Retry baca | satu pembacaan ulang bila buffer kosong | A |
| Timeout serial | tidak terbaca sebagai konstanta tunggal | C |
| Retry kirim | tidak ditemukan loop retry eksplisit | C |
| Negative response 0x7F | tidak ditemukan penanganan khusus di jalur loop | C |
| Error lisensi/adaptor | `logindialog`, `SimpleCrypt`, FTDI Chip-ID | A |
| Error ECU | tidak ada string "no response" yang terbukti | C |

---

## 10. Koreksi terhadap klaim audit sebelumnya

1. **"Row count 17/19/22 adalah jumlah parameter per profil."**
   Konstanta `0x11/0x13/0x16` memang muncul dan angkanya sama dengan pengamatan
   pemilik, tetapi di disassembly nilai itu dipakai sebagai **argumen id baris**
   pada `0x406ad0`, bukan sebagai penghitung loop. Klaim "terverifikasi sebagai
   jumlah parameter" diturunkan menjadi **B. INFERENCE**. Yang pasti: tiga angka
   itu ada di blok setup model dan konsisten dengan hitungan pengamatan.
2. **"Live Data H-Diag per parameter."**
   Yang terbukti adalah satu blok respons per frame, bukan request per parameter.
3. **"Rumus konversi H-Diag dapat dipindahkan."**
   Tidak. Rumus per parameter tidak berhasil diekstrak; hanya format tampilan.
4. **"H-Diag memiliki identifikasi ECU."**
   Tidak terbukti sebagai fitur terpisah; hanya frame `71 00` di loop.

---

## 11. Ringkasan kapabilitas H-Diag

| Kapabilitas | Status | Kelas |
|---|---|---|
| Live data multi-parameter, 25 model | Terbukti ada | A |
| Request: tiga frame blok | Terbukti | A |
| Polling 100 ms, siklus 15 langkah | Terbukti | A |
| Pemetaan byte → parameter | Belum | C |
| Rumus skala/offset | Belum | C |
| DTC read (5 frame) | Terbukti ada | A |
| DTC clear (2 frame) | Terbukti ada | A |
| DTC dictionary Indonesia | Terbukti ada | A |
| Identifikasi ECU terpisah | Tidak terbukti | C |
| Actuator/registration/immobilizer | Tidak ditemukan | — |
| Lisensi berbasis FTDI Chip-ID | Terbukti ada | A |

Bukti mentah: `evidence/hdiag_full_text.txt`, `evidence/HDiag_main.ascii.txt`,
`evidence/hdiag_402000_403600.txt`, `evidence/hdiag_helper_406ad0.txt`,
`evidence/ghidra_hdiag_import.log`, `evidence/ghidra_hdiag_refs.log`.
