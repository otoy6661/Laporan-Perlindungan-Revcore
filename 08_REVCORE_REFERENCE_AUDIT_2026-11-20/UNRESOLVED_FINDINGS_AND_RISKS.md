# UNRESOLVED FINDINGS AND RISKS

Work order §7, §10. Daftar hal yang belum dapat dibuktikan, risiko yang terlihat,
dan bukti yang diperlukan. Tidak ada item di sini yang boleh dibaca sebagai
"berhasil".

---

## 1. Temuan terbuka (unresolved)

| ID | Pertanyaan | Mengapa belum selesai | Bukti yang diperlukan | Risiko bila diabaikan |
|---|---|---|---|---|
| U1 | Subset parameter tiap model H-Diag (17/19/22) | Konstanta 0x11/0x13/0x16 ada, tetapi dipakai sebagai id baris; tabel per model tidak statis | Jalankan H-Diag dengan adaptor FTDI asli, catat baris per model | Matriks profil salah dikutip |
| U2 | Offset dan skala tiap parameter H-Diag | Respons dipecah menjadi teks oleh fungsi internal | Log serial + rekaman layar + uji byte | Angka palsu bila dipaksakan |
| U3 | Timeout/retry H-Diag | Tidak ada konstanta tunggal yang terbaca | Uji waktu respons / instrumentasi | Ekspektasi timing salah |
| U4 | Arti header `0x7E`/`0x7C` di RevCore | Hanya hipotesis internal RevCore | Dokumentasi/protokol atau uji ECU | Routing keluarga salah |
| U5 | Transform Keihin/SCOOPY | Rumus C# dan firmware mode 1 berbeda struktur; belum ada known-answer | ID yang sudah diketahui dari kendaraan nyata | ID 9 digit salah |
| U6 | Deteksi vendor Keyless | Firmware punya probe-K/S; RevCore tidak | Uji dua ECU (Keihin & Shindengen) | Handshake gagal pada satu keluarga |
| U7 | Jeda handshake 1000 ms | RevCore memakai 150 ms; alasan firmware tidak terdokumentasi | Uji dengan ECU lambat | Gagal security access |
| U8 | Jumlah alamat Keyless 256 vs subset | RevCore berhenti di alamat tertinggi model | Bandingkan data model & hasil | Data model tertentu tidak lengkap |
| U9 | Apakah DTC RevCore (`74/01`, `71/20`, `00/00`) dijawab ECU | Tidak ada ECU | Uji baca DTC | DTC kosong dianggap "tidak ada kode" |
| U10 | Format ACK clear DTC | Kode hanya mencocokkan header | Uji clear pada ECU | Klaim sukses tanpa dasar |
| U11 | Durasi/validitas BREAK FTDI di Android | Hanya panggilan `setBreak` | Osiloskop atau log ECU | Wake gagal |
| U12 | Apakah `72 05 71 17 01` menjawab semua motor | Layout dari firmware, bukan respons | Uji per model | Live data kosong |
| U13 | Apakah H-Diag punya identifikasi ECU terpisah | Tidak ada request khusus | Observasi UI | Klaim fitur berlebih |
| U14 | Kelengkapan dictionary DTC H-Diag | String ada, jumlah entri belum dihitung | Ekstraksi seluruh string | Matriks DTC tidak lengkap |

---

## 2. Risiko pada RevCore (source-level)

| # | Risiko | Dampak | Level | Catatan |
|---|---|---|---|---|
| R1 | Profil keluarga kosong + routing 0x7E/0x7C | Live data/DTC mati setelah header tertentu | Tinggi | Perilaku belum teramati |
| R2 | Transform Keihin berbeda | ID salah pada SCOOPY | Tinggi | Butuh known-answer |
| R3 | Keyless tanpa probe vendor | Gagal pada salah satu keluarga | Tinggi | Firmware sudah membuktikan perlunya |
| R4 | Jeda 150 ms vs 1000 ms | Security access ditolak | Sedang–tinggi | Perlu uji |
| R5 | Tanpa pacing inter-byte | Frame rusak pada adaptor tertentu | Sedang | Firmware memberi delay |
| R6 | Label `VERIFIED` pada layout | Tafsir "fitur terverifikasi" | Sedang | Bukan bug kode, bug komunikasi |
| R7 | DTC clear tanpa ACK terbukti | Klaim berhasil palsu | Sedang | Sudah ada peringatan di kode |
| R8 | MAP raw kPa | Nilai tidak sesuai tekanan fisik | Sedang | Perlu dokumentasi |
| R9 | TPS% derivasi | Pengguna mengira nilai ECU | Rendah | Sudah dikomentari |
| R10 | Keyless hanya subset alamat | Model dengan offset tinggi tidak lengkap | Sedang | Bergantung model |

Tidak ditemukan risiko: penulisan EEPROM tak sengaja, zero-fill nilai hilang,
atau klaim clear sukses tanpa verifikasi di UI.

---

## 3. Risiko tafsir laporan

1. **"Delapan parameter tersedia"** benar sebagai "delapan field terpetakan",
   bukan "delapan nilai terbukti dari ECU". Laporan harus memakai frasa pertama.
2. **"Layout VERIFIED"** berarti offset berasal dari decoder firmware, bukan
   respons ECU. Jangan diterjemahkan menjadi "fitur terverifikasi".
3. **"Keyless PROTOCOL_ANALYZED"** berarti alur dan byte terbaca, bukan berhasil
   di motor.
4. **"H-Diag 17/19/22"** berasal dari pengamatan pemilik + konstanta; subset belum
   dipetakan.
5. **Tidak ada kelas D.** Semua pernyataan "berhasil" pada perangkat adalah klaim
   yang belum diuji.

---

## 4. Batas etika dan hukum

- Tidak ada pembobolan immobilizer, ekstraksi kredensial, atau bypass keamanan.
- Rutin tulis Keyless (`FUN_400e51b8`) tidak dianalisis dan tidak direproduksi.
- Lisensi H-Diag tidak dilewati.
- Tidak ada source/aset referensi yang disalin ke RevCore.
- Keyless ID yang dibaca adalah data yang memang ditampilkan aplikasi referensi;
  penelitian berhenti pada pemahaman alur.

---

## 5. Yang harus dilakukan sebelum status berubah

| Status sekarang | Menjadi | Syarat |
|---|---|---|
| IMPLEMENTED BUT UNVERIFIED (live) | ECU RESPONSE VERIFIED | Log frame + nilai cocok dengan alat lain |
| IMPLEMENTED BUT UNVERIFIED (DTC) | ECU RESPONSE VERIFIED | DTC terbaca dan cocok dengan kode fisik |
| IMPLEMENTED BUT UNVERIFIED (clear) | ECU RESPONSE VERIFIED | ACK + pembacaan ulang bersih |
| IMPLEMENTED BUT UNVERIFIED (Keyless) | FIELD_VERIFIED | ID cocok pada motor nyata |
| UNKNOWN (transform) | FACT | Known-answer test |
| UNKNOWN (routing) | FACT | Bukti header dari ECU |

Tanpa bukti di atas, status tidak boleh dinaikkan. Ini aturan §7 work order.

---

## 6. Rekomendasi urutan pembuktian (bukan work order implementasi)

1. Uji live data satu model dengan log mentah; bandingkan RPM/TPS dengan alat lain.
2. Uji baca DTC; cocokkan jumlah kode.
3. Uji Keyless read pada satu model Keihin dan satu Shindengen; catat ID.
4. Uji ulang SCOOPY untuk known-answer transform.
5. Uji clear DTC terakhir, setelah baca terbukti.

Work order implementasi tidak dibuat di sini; menunggu laporan audit ditinjau
oleh otoy.
