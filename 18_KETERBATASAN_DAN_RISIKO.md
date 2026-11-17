# 18 — KETERBATASAN & RISIKO

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Status:** SELESAI — seluruh keterbatasan yang memengaruhi kesimpulan dinyatakan terbuka.

---

## 1. Keterbatasan bukti

| Keterbatasan | Dampak pada kesimpulan | Upaya yang dilakukan |
|---|---|---|
| Tidak ada perangkat keras tuning | Semua jalur serial/emulator berhenti di validasi host | Uji tanpa perangkat + analisis string |
| Tidak ada ECU Honda | Tidak ada frame/checksum/protokol yang tertangkap | Tidak mengklaim frame |
| 161 XDF + 3 ADX terenkripsi | Isi tidak dapat diaudit | Klasifikasi NOT_DIRECTLY_READABLE |
| Tanpa dekompilasi penuh | Logika internal hanya dari export/string/observasi | Analisis struktural + runtime |
| Tanpa uji jaringan | Update/registrasi tidak diverifikasi | Dinyatakan tidak diuji |
| Tanpa uji import format lain | S19/TDF/VDF/RDT/CEE/ADS/EFILive tidak diketahui | Tidak diklaim |
| Satu snapshot modul | Urutan muat dapat berbeda | Dinyatakan SEDANG |
| Beberapa dialog tidak diuji | Cakupan UI tidak 100% | Dicatat di laporan 19 |

---

## 2. Perubahan state yang harus diketahui owner

| File | Perubahan | Dampak | Pemulihan |
|---|---|---|---|
| `TunerProSettings.dat` | Path BIN/XDF/ADX terakhir ke work copy BE-11 | Startup membuka file work copy | Hapus file atau set ulang via Preferences |
| `TPSPMSettings.dat` | `lastadxpath`/`recentdef` ke `keihin.adx`; `comport=\.\COM1`; `interfacetype=3` | ADX terakhir berubah; port COM1 | Sama |
| `TPEmuPlugin.dat` | Menyimpan `\\.\COM1` | Emulator memakai COM1 | Sama |
| `TunerProSettingsFree.dat` | **Tidak berubah** | — | — |
| Instalasi | Tidak berubah; rename sementara dipulihkan | — | — |
| Dataset asli | Tidak berubah | — | — |

**Tidak ada backup otomatis.** Jika owner ingin mengembalikan keadaan awal, tiga file settings dapat dihapus; aplikasi akan membuat default baru.

---

## 3. Risiko teknis TunerPro (berdasarkan bukti)

| Risiko | Severity | Kemungkinan | Dasar | Mitigasi |
|---|---|---|---|---|
| Checksum tidak diperbarui karena plug-in hilang | Tinggi | Sedang | CBR gagal Save | Verifikasi plug-in sebelum edit |
| Salah pasangan BIN/XDF | Tinggi | Sedang | Tidak ada validasi saat load | Cocokkan ECM ID/SW Version manual |
| Emulator RAM terlalu kecil | Sedang | Tinggi | BIN 64 KB ditolak | Gunakan bank/mode yang benar |
| Nilai hilang tampil sebagai 0/konstanta | Tinggi (diagnostik) | Sedang | Tidak ada state per parameter | Jangan gunakan untuk diagnosa tanpa validasi |
| Plugin pengguna tanpa signature | Tinggi | Rendah–Sedang | DLL in-process | Audit hash, batasi izin folder |
| Update via HTTP | Sedang | Rendah | WININET | Jangan andalkan integritas update |
| Chip programmer salah timing | Tinggi (merusak chip) | Rendah | PromIO | Ikuti datasheet/perangkat |

---

## 4. Risiko hukum/etika

| Area | Batas yang dipatuhi |
|---|---|
| Lisensi | Tidak ada bypass registrasi; string registrasi hanya dibaca |
| Enkripsi | Tidak ada cracking/dekripsi paksa |
| Dataset | Tidak ada modifikasi/penyebaran ulang di luar laporan |
| Software | Tidak ada patching binary |
| Hardware | Tidak ada penulisan ECU |
| Pihak ketiga | ELM327 plugin hanya dianalisis statis; tidak dieksekusi di luar aplikasi |

---

## 5. Keterbatasan yang memengaruhi RevCore

1. **Tidak ada bukti frame Honda.** Perbandingan dengan `HondaFrameCodec` hanya konseptual.
2. **Checksum SUM 8-bit cocok**, tetapi belum diuji pada frame ECU; status `HARDWARE VALIDATION PENDING`.
3. **Keihin 16-bit/CRC16 tidak punya pembanding TunerPro**; klaim keunggulan harus hati-hati.
4. **XDF/ADX bukan format RevCore.** Diperlukan parser baru; belum ada.
5. **Model status RevCore lebih ketat**, tetapi belum diuji dengan data nyata.
6. **FlashEngine default-deny** adalah keputusan yang benar; TunerPro tidak memberikan bukti untuk membukanya.

---

## 6. Hal yang tidak boleh diklaim

- “TunerPro mendukung ECU Honda” — hanya jika ADX yang tepat ada; ADX tidak terbaca.
- “TunerPro melakukan flashing ECU” — tidak ada jalur.
- “Checksum Honda RevCore identik dengan TunerPro” — hanya SUM 8-bit.
- “Dataset 100% kompatibel” — hanya 13 XDF yang dapat dibaca.
- “Analisis 100% lengkap” — banyak area tidak diuji (lihat laporan 19).
- “Tidak ada malware” — tidak dilakukan analisis antivirus penuh.

---

## 7. Risiko publikasi

| Risiko | Mitigasi |
|---|---|
| Hash/path pribadi terbawa | Path pengguna sudah ada di laporan; tidak ada kredensial |
| File terenkripsi disalahartikan sebagai milik publik | Dinyatakan terenkripsi dan tidak didekripsi |
| Screenshot memuat informasi pribadi | Diperiksa; hanya window aplikasi/editor |
| Klaim berlebihan | Setiap laporan memiliki tabel keyakinan |

---

## 8. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Daftar keterbatasan | TINGGI (berbasis apa yang tidak dilakukan) |
| Efek samping settings | TINGGI (file dapat diperiksa) |
| Risiko teknis | SEDANG (inferensi dari bukti) |
| Risiko hukum | TINGGI (batas dipatuhi) |
