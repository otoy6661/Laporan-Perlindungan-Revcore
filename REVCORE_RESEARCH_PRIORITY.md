# REVCORE RESEARCH PRIORITY — BE-09

**Tanggal:** 17 November 2026
**Tujuan:** menentukan urutan pekerjaan lanjutan berdasarkan nilai, risiko, dan
ketersediaan bukti. Tidak ada pekerjaan hardware yang diotorisasi oleh dokumen ini.

Skala: **P0** = dapat dikerjakan sekarang dengan bukti yang ada; **P1** = lanjutan
offline berisiko rendah; **P2** = memerlukan hardware/izin; **P3** = berisiko tinggi;
**P4** = di luar lingkup.

---

## 1. Ringkasan prioritas

| Prioritas | Paket kerja | Nilai | Risiko | Effort | Prasyarat |
|---|---|---|---|---|---|
| P0 | Validasi parser XDF pada 13 file + tabel stride | Tinggi | Rendah | S | — |
| P0 | Uji identifikasi pada 700 BIN (offline) | Tinggi | Rendah | S–M | — |
| P0 | Integrasi modul offline (parse/read/checksum) | Tinggi | Rendah | M | review kode |
| P1 | Registry checksum & dukungan famili lain | Tinggi | Sedang | M–L | IL/dump tambahan |
| P1 | Alur edit + re-checksum end-to-end | Tinggi | Sedang | M | P0 selesai |
| P1 | Audit lisensi komponen pihak ketiga | Sedang | Rendah | S | — |
| P2 | Descriptor live data + capture frame | Tinggi | Sedang | L | bench + izin |
| P2 | Identifikasi runtime & baca flash | Tinggi | Sedang | L | bench + izin |
| P2 | Transport pada platform RevCore | Tinggi | Sedang | M–L | keputusan platform |
| P3 | Write/erase ECU | Tinggi | Sangat tinggi | L | bench, catu daya, prosedur |
| P3 | Recovery ECU | Sedang | Sangat tinggi | L | bench + citra recovery |
| P4 | Smart key / HISS | Rendah | Etis tinggi | — | otorisasi khusus |

---

## 2. P0 — Sekarang (offline, tanpa hardware)

### P0.1 Validasi parser pada seluruh XDF terbuka

- **Apa:** jalankan parser pada 13 XDF; bandingkan jumlah definisi dengan
  `REPORTS/XDF_DEFINITION_INVENTORY.csv` (287 tabel, 11 konstanta, 22 flag, 5 patch).
- **Mengapa:** prototipe baru menguji 2 XDF.
- **Kriteria terima:** 13/13 terbaca tanpa exception; total definisi cocok; tabel
  dengan `mmedmajorstridebits` ≠ 0 menghasilkan nilai yang sama dengan pembacaan manual.
- **Bukti:** log + tabel hasil per file.

### P0.2 Uji identifikasi 700 BIN

- **Apa:** jalankan `identify` pada seluruh BIN; catat offset yang menghasilkan ID
  masuk akal vs tidak; bandingkan dengan nama file.
- **Mengapa:** mengukur false positive/negative sebelum masuk RevCore.
- **Kriteria terima:** laporan confusion matrix per famili; tidak ada ID yang
  dipaksakan saat marker tidak ada.
- **Catatan:** ini **tidak** membuktikan dukungan ECU; hanya konsistensi offline.

### P0.3 Integrasi modul offline

- **Apa:** pindahkan `XdfParser`, `TableReader`, `KzrChecksum`, `BinIdentifier`,
  `Scales` ke RevCore sebagai modul read-only.
- **Mengapa:** nilai tertinggi dengan risiko terendah.
- **Kriteria terima:** unit test RevCore lulus; tidak ada I/O hardware; tidak ada
  perubahan perilaku lain.

---

## 3. P1 — Lanjutan offline

### P1.1 Registry checksum

- **Apa:** desain registry `{family, size, address, algorithm, evidence}`; tambahkan
  checksum non-KZR hanya setelah algoritma terbukti.
- **Mengapa:** file hasil edit harus dapat diverifikasi.
- **Kriteria terima:** setiap entri punya sumber bukti; algoritma yang belum terbukti
  ditolak.
- **Risiko:** sedang; jangan menebak polinomial/alamat.

### P1.2 Alur edit + re-checksum

- **Apa:** edit sel → hitung ulang checksum → verifikasi → simpan salinan baru.
- **Kriteria terima:** diff byte terbatas pada sel yang diedit + field checksum;
  input asli tidak berubah; checksum verify `True`.

### P1.3 Audit lisensi

- **Apa:** pastikan tidak ada kode pihak ketiga yang disalin; dokumentasikan asal
  algoritma (IL/symbol) dan lisensi XDF/BIN.
- **Kriteria terima:** daftar komponen + lisensi + keputusan.

---

## 4. P2 — Memerlukan hardware/izin

### P2.1 Descriptor live data

- **Apa:** capture frame, stimulasi TPS/suhu/tegangan, diff byte, susun descriptor
  per profil.
- **Prasyarat:** bench ECU, adapter, izin pemilik, prosedur keselamatan.
- **Kriteria terima:** setiap kanal punya offset/tipe/skala dengan bukti capture.
- **Jika tidak ada izin:** tetap `UNKNOWN`; jangan mengisi offset.

### P2.2 Identifikasi runtime & baca flash

- **Apa:** log frame `ping`/`GetEcmid`/baca; tentukan service ID, baud, timing.
- **Kriteria terima:** log hex dapat direproduksi; tidak ada klaim sebelum berhasil
  dua kali pada bench.

### P2.3 Transport platform

- **Apa:** tentukan apakah RevCore memakai USB Host + adapter, D2XX di Windows, atau
  jalur lain.
- **Kriteria terima:** keputusan pemilik + prototipe transport pada OS target.

---

## 5. P3 — Risiko tinggi

- **Write/erase:** hanya setelah P2.2 stabil, dengan catu daya terkendali, ECU
  cadangan, dan prosedur rollback. Kriteria: verifikasi baca-balik 100%.
- **Recovery:** hanya dengan citra recovery yang tervalidasi dan pemahaman state
  `RECOVER_NEW` vs `RECOVER_OLD`.

---

## 6. P4 — Di luar lingkup

- Smart key/HISS: `NOT_FOUND`; tidak ada dasar untuk fitur.
- Unlock XDF terkunci, bypass lisensi, atau cloning key: dilarang.

---

## 7. Urutan eksekusi yang disarankan

```text
P0.1 ─┬─> P0.3 ─> P1.2 ─> P1.1
P0.2 ─┘
                 └─> P1.3
P2.3 (keputusan platform) ─> P2.1/P2.2 ─> P3
```

P0.1 dan P0.2 dapat berjalan paralel karena keduanya offline dan tidak saling
bergantung.

---

## 8. Kriteria berhenti

Hentikan pekerjaan dan minta keputusan pemilik bila:

1. Diperlukan akses hardware tanpa izin tertulis.
2. Diperlukan dekripsi XDF/ADX terkunci.
3. Diperlukan seed-key atau material imobilizer.
4. Data uji menunjukkan checksum/offset tidak konsisten pada famili yang sama.
5. Ada permintaan menulis ke ECU tanpa prosedur verifikasi dan rollback.
