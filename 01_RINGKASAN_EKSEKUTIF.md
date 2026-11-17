# 01 — RINGKASAN EKSEKUTIF
## BE-11 — TUNERPRO RT COMPLETE SOFTWARE AUTOPSY

**Status:** SELESAI DENGAN KETERBATASAN YANG DINYATAKAN  
**Tanggal analisis:** 17–18 November 2026  
**Aplikasi:** TunerPro RT 5.0.10335.0 (x86, unsigned) — `C:\Program Files (x86)\TunerPro RT`  
**Dataset:** 930 file (700 BIN, 174 XDF, 3 ADX, 32 LOG, arsip) — salinan kerja di `00_SOURCE_INVENTORY\DATASET_COPY`  
**Prinsip:** *fish autopsy* — membedah mekanisme internal, bukan mendaftar menu.

---

### 1. Apa yang dibuktikan

1. **Arsitektur aplikasi.** TunerPro RT adalah aplikasi native x86 (PE32, image base `0x400000`, 5 section, 1.324.544 byte) dengan kelas window MFC-style (`TUNERPRO`, `MMTABSHEET`, `MMGRIDCONTROL`). Inti editor XDF/ADX berada di `TunerPro.exe` + `XDFEditor.dll` + `ADXEditor.dll`; akuisisi data di `ScannerProModule.dll`; jalur hardware di `PromIO.dll` dan plug-in.
2. **Model plug-in nyata.** Plug-in antarmuka hardware memakai ekspor `TPCreatePlugin`/`TPReleasePlugin` dan dimuat dari direktori aplikasi serta `%USERPROFILE%\Documents\TunerPro Files\Plugins`. Plug-in checksum memakai API terpisah `MMCS*` dan **tidak** muncul di About Plug-ins. Ablasi `TPChecksumPlugin.dll` menurunkan jumlah modul runtime 55 → 54 tanpa membuat aplikasi gagal start.
3. **Format XDF terbaca penuh untuk plaintext.** Dari 174 XDF, 13 plaintext dan 161 memakai kontainer terenkripsi TunerPro (magic `05 22 97 00`, penanda `0x64` di offset `0x83`, ciphertext mulai `0x84`, entropi ±7,994). XDF terenkripsi **dapat dibuka** aplikasi, tetapi pohon parameter hanya menampilkan header/`Kompatible Ecu`; isi tabel tidak diekspos dan tidak dapat diekspor tanpa kunci.
4. **Kebenaran parser independen.** Prototipe `TpFormatKit` membaca XDF K1AA-N03 dan mereproduksi **5.338 sel numerik dari 18 tabel** yang diekspor TunerPro **tanpa satu pun selisih**, ditambah 2 tabel teks (SW Version `SH850T01R100_PV10`, ECM ID `01 03 7A 00 AC`). Total **53/53 tes lulus**.
5. **Alamat, stride, dan axis terverifikasi.** Tabel 35×29 16-bit di `0x3815E`; axis TPS di `0x39BFE` (29 nilai) dan axis RPM di `0x39C38` (35 nilai), keduanya memakai `mmedmajorstridebits=-32` dengan elemen 8-bit sehingga urutan alamat berjalan 4 byte ke belakang per indeks; nilai axis terbaca 0..74,3 (TPS) dan 900..9200 (RPM). Perubahan satu sel 9999 mengubah tepat 2 byte (`0x0F 0x27` di `0x3B122`).
6. **Perilaku checksum berbeda per definisi.** XDFCHECKSUM tanpa `pluginmoduleid` (SUPRA K41-NC1) disimpan ulang dengan byte checksum dinormalisasi `0x00 → 0xFF`; perubahan byte data di `0x1000` **tidak** mengubah byte checksum. XDF dengan `pluginmoduleid = 49524f4e-504f-4e59-524b-000000000000` ("IRON-PONY-RK") **menolak Save As** dengan pesan *"Error - One or more checksums could not be updated. Check checksum addressing, etc, for validity."* Ini bukti bahwa checksum Honda ditangani plug-in, bukan inti aplikasi.
7. **ADX adalah resep datalogging, bukan firmware.** ADX terenkripsi membentuk 11 baris Data List (10 nama terbaca: RPM Engine, TPS Volt, TPS Open d2 tech, Engine Temp, Battery Volt, Injector Duration, ADX Arbi, Ignition, O2 Sensor, AFR), dashboard (D2 TECH), monitor, dan history table. ADX Editor hanya menampilkan "ADX Header Data" untuk file terenkripsi — keterbatasan UI, bukan bukti isi kosong.
8. **Batas emulasi 64 KB.** Perintah Emulation Upload/Download/Verify pada BIN 64 KB menghasilkan *"FAILURE: Bin is larger than emulation RAM! Perhaps you meant to use bank 8?"* pada konfigurasi tanpa hardware. Tidak ada penulisan ke ECU fisik.
9. **Tidak ada jalur reflash ECU Honda di inti.** `PromIO.dll` (StartPromUI), `MoatesOnboardLogger.dll`, dan plug-in emulator Moates adalah jalur pemrograman chip/emulator, bukan reflash ECU. Klaim flashing/recovery hanya dapat dibuat untuk perangkat Moates; untuk ECU Honda: **tidak ditemukan**.
10. **Perbandingan RevCore level implementasi.** RevCore memiliki parser K-line eksplisit, checksum packet two's-complement, dan profil ECU; TunerPro mendelegasikan frame ke plug-in/ADX. Tidak ada kode RevCore yang disalin; klasifikasi lengkap ada di laporan 14.

### 2. Yang TIDAK dibuktikan

- Tidak ada adaptor fisik, ECU, atau kendaraan; seluruh status runtime adalah "Hardware Not Found"/"DA: Not Connected".
- Tidak ada capture frame K-line Honda yang nyata; isi perintah ADX dan urutan inisialisasi tidak dapat direkonstruksi dari UI saja.
- Algoritma dekripsi kontainer TunerPro tidak direkonstruksi; hanya struktur dan perilaku akses yang dipetakan.
- Tidak ada ADX plaintext; parser ADX XML tidak divalidasi terhadap sampel asli.
- Mekanisme update online (WININET) tidak dipanggil/capture.
- Edit grid otomatis tidak selalu berhasil; pembuktian edit memakai berkas hasil edit yang sudah ada dan diff byte.

### 3. Dampak bagi RevCore

- Model "definition-driven" (XDF/ADX) milik TunerPro adalah pembeda utama: RevCore memakai profil ECU tertanam, bukan definisi pengguna.
- Checksum Honda perlu diperlakukan sebagai **algoritma per-ECU/per-definisi**, bukan satu fungsi global. Bukti CBR1000RR: byte tersimpan `0xEF` konsisten dengan two's complement dari seluruh 256 KB di luar byte checksum.
- Keamanan: TunerPro memblokir Save As jika checksum tidak dapat diperbarui — pola yang layak ditiru RevCore (default-deny).
- Batas 64 KB emulator dan absennya reflash ECU menegaskan bahwa "live tuning" TunerPro bukan jalur flashing yang aman untuk Honda.

### 4. Deliverable

19 laporan di root repositori, prototipe + 53 tes di `13_PROTOTYPES`, log eksperimen di `16_LOG_EKSPERIMEN.md`, indeks bukti di `17_INDEKS_BUKTI.md`, dan manifest SHA-256 di `15_EVIDENCE` serta `PUBLICATION_MANIFEST.csv`.
