# Ringkasan Tahap 2 — Relevansi untuk RevCore

Work order: DEEP AUTOPSY TAHAP 2 (H-Diag 2.1 & 3D Chart Graph Remap K-Line)
Sifat: research/static analysis. Tidak ada perubahan pada RevCore.

> **Catatan metodologis:** source RevCore **tidak** dibandingkan baris-per-baris pada tahap ini (di luar lingkup otopsi referensi). Karena itu dokumen ini **tidak** menyatakan adanya bug di RevCore. Semua butir di bawah adalah kandidat/referensi desain yang harus diverifikasi terhadap source RevCore yang sebenarnya sebelum dijadikan pekerjaan implementasi.

## 1. Daftar terbukti (A/B)

### Protokol & transport

| # | Temuan | Sumber | Tingkat |
|---|---|---|---|
| P-01 | Frame `[0x72][len][fn][sub][param…][checksum]`, checksum komplemen 8-bit | keduanya | A |
| P-02 | 45 frame statis diaudit ulang; semua checksum PASS | keduanya | A |
| P-03 | 3D Chart membuang echo request sebelum parsing; `replyLen` diambil dari `commandSize+1` | 3D | A |
| P-04 | `array9[2]` = byte fungsi `0x71`, bukan table type/echo | 3D | A |
| P-05 | Buffer balasan tidak di-reset antar siklus; nilai basi bertahan saat `b[1]==5` | 3D | A/B |

### Sensor 3D Chart

| # | Temuan | Tingkat |
|---|---|---|
| P-06 | Formula lengkap dat10/11/13/16/17/20/D1 (termasuk STF hanya `b[5]`, AFR dari O2V) | A |
| P-07 | `datD1`: POM `b[8]`, fan `b[9]`, SSS/SSW/BAS/gear-status `b[4]`, gear position `b[10]` | A |
| P-08 | IAC dat11 dihitung, tidak pernah masuk UI | A |
| P-09 | `Task.Delay` tidak di-await; tidak ada interval polling efektif | A |
| P-10 | Timeout tidak ditandai; nilai nol/OFF dapat tampil sebagai data sah | A/B |

### H-Diag

| # | Temuan | Tingkat |
|---|---|---|
| P-11 | Tabel 50 baris; STF=20, POM=21, SS=22, STS=23, SSW=24, FIS=25, MOD=26, ALT=27, IAC=32 | A |
| P-12 | Mekanisme `setRow(raw,key,column,slot)`; kunci harus ada di daftar per tipe ECU | A |
| P-13 | Sembilan parameter wajib punya jalur parser eksplisit (frame/offset absolut tetap D/E) | B |
| P-14 | Altitude read-only: tidak ada frame tulis di seluruh `.text` | A |
| P-15 | Tabel offset per tipe ECU: 5/7/21 byte × 25 tipe (bukan offset statis) | B |

### Remap 3D Chart

| # | Temuan | Tingkat |
|---|---|---|
| P-16 | Identifikasi ECU via signature (V850/RH850/RH850B/H8C/M32R/OTHER) | A |
| P-17 | Alamat vs indeks blok: `startOffset/16` vs `startOffset/128` | A |
| P-18 | Checksum Shindengen 32-bit komplemen dua pada pasangan `D0 07`; Keihin 8-bit | A |
| P-19 | Blok 128 byte (64 untuk H8C); blok `FF` dilewati; rantai alamat berikut | A |
| P-20 | Retry 2×, status ACK `[1]==7/[4]==0/[5]==0` atau `[1]==5`; finalisasi `[3]==15` | A |
| P-21 | Tidak ada read-back/verifikasi checksum pasca-tulis; tidak ada rollback | A |
| P-22 | Fast write `FF 25 00 20 7C 00` + 62500 baud hanya `KEIHINOTHER`, default aktif | A |

## 2. Dugaan yang masih terbuka (C)

1. Frame C H-Diag (`72 05 00 F1 98`) = keep-alive/status ECU.
2. Hubungan frame H-Diag → jalur balasan 7/8/12/20 token.
3. Dua token ALT = nilai + status.
4. Fan dan gear position 3D Chart memakai byte yang sama (`b[9]`); mungkin tumpang tindih atau salah indeks.
5. `D0 07` selalu checksum marker pada semua keluarga Shindengen.

## 3. Belum diketahui (D)

1. Offset byte absolut H-Diag per parameter.
2. Baud H-Diag (tidak ada konstanta divisor).
3. Arti lengkap status `array14[3]` selain 0/15/250.
4. Tabel kunci efektif per tipe ECU (25 tipe, mana yang aktif per model kendaraan).
5. Duplikat baris GG (28 dan 49): disengaja atau tidak.
6. Perilaku ECU saat listrik terputus di tengah tulis.

## 4. Butuh validasi hardware (E)

1. Semua frame H-Diag dan 3D Chart terhadap ECU nyata (belum ada capture RX).
2. Apakah STF 8-bit atau 16-bit, dan arah tanda.
3. Apakah H-Diag benar-benar read-only pada semua model.
4. Apakah ACK tulis dapat dipercaya tanpa read-back.
5. Interval polling aman pada bus K-line nyata.
6. Apakah fan/gear berbagi byte pada ECU sesungguhnya.

## 5. Relevansi per temuan (kelas 1–4)

Legenda: **1** kandidat perbaikan · **2** referensi desain · **3** tidak relevan · **4** belum dapat dinilai.

| Temuan | Kelas | Alasan |
|---|---:|---|
| P-03/P-05/P-10 status validitas eksplisit | 1 | Referensi menunjukkan risiko nilai palsu; perlu cek apakah RevCore sudah punya status serupa |
| P-21 verifikasi pasca-tulis | 1 | Referensi tidak memverifikasi; kandidat kontrol mutu untuk modul remap RevCore |
| P-09 jeda polling terjadwal | 1 | Loop referensi tanpa jeda efektif; RevCore sebaiknya punya interval eksplisit |
| P-08 menampilkan IAC | 1 | Referensi membuang nilai; RevCore butuh IACV (kebutuhan #8) |
| P-06 verifikasi STF | 1 | Formula 1 byte perlu diuji sebelum dipakai |
| P-07 pemisahan fan/gear | 1 | Jika RevCore memakai byte sama, perlu pemisahan/verifikasi |
| P-01/P-02 frame & checksum | 2 | Bisa jadi acuan transport, bukan disalin identitasnya |
| P-11–P-15 pemetaan H-Diag | 2 | Menunjukkan parameter tersedia, bukan perintah per parameter |
| P-16–P-19 deteksi ECU & checksum BIN | 2 | Referensi untuk modul remap, dengan implementasi RevCore sendiri |
| P-20 status ACK | 2 | Urutan status berguna; arti status E |
| P-22 fast write | 3 | Spesifik Keihin + baud nonstandar; berisiko |
| Algoritma seed/key, license gate, keygen | 3 | Tidak boleh ditiru; kebijakan keamanan |
| Capture RX nyata | 4 | Butuh hardware; belum dapat dinilai |

## 6. Kandidat perbaikan (tanpa klaim bug RevCore)

Daftar ini adalah **hypothesis backlog**, bukan temuan bug:

1. **Status per pembacaan**: setiap nilai membawa `VALID/TIMEOUT/UNSUPPORTED/STALE`; jangan menampilkan nilai basi.
2. **Verifikasi pasca-tulis**: baca balik blok atau checksum area setelah tulis; jangan hanya ACK.
3. **Jeda polling eksplisit**: interval terjadwal dan ter-await, bukan efek samping waktu serial.
4. **IACV**: tampilkan nilai mentah + hasil konversi, jangan dibuang.
5. **STF**: konfirmasi lebar data dan skala sebelum formula `/128.25651`.
6. **Fan/gear**: pastikan tidak berbagi byte status tanpa verifikasi.
7. **Penanganan kegagalan**: checksum gagal/timeout harus terlihat di UI dan log, bukan nilai nol.

## 7. Referensi desain (bukan clone)

Yang layak diadopsi sebagai **pola**, bukan kode/identitas:

- Pemisahan jelas: transport (frame/checksum/wake) vs decoder per parameter vs UI.
- Menyimpan raw byte + formula + versi (bukan hanya hasil akhir).
- Deteksi keluarga ECU sebelum operasi tulis; checksum dihitung dari isi nyata.
- Altitude hanya baca sampai ada bukti perintah set.

Yang **tidak** boleh ditiru:

- License gate, keygen, algoritma kunci seed/key.
- Fast-write nonstandar tanpa dasar teknis yang terverifikasi.
- Penanganan timeout yang menampilkan nilai palsu.

## 8. Pernyataan identitas

RevCore tetap memiliki identitas, desain, dan arah pengembangannya sendiri. Dokumen ini tidak mengusulkan penyalinan UI, nama, string, atau alur aplikasi referensi. Tidak ada patch, implementasi, atau work order lanjutan yang dibuat.
