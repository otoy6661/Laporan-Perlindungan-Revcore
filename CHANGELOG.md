# Changelog

Semua perubahan laporan pada repository ini. Format mengikuti Keep a Changelog secara ringkas; tanggal dalam ISO 8601.

## [Laporan Teknis RevCore] — 2026-11-20

Work order: `WORK ORDER — LAPORAN TEKNIS REVCORE` (upload laporan hasil
pekerjaan dan investigasi bug). Dokumentasi saja: tidak ada source RevCore yang
diubah, tidak ada Gate 10 yang diubah, tidak ada rahasia signing.

### Added
- `07_REVCORE_TEKNIS_2026-11-20/LAPORAN_TEKNIS_REVCORE_2026-11-20.md` — laporan utama (mode `0x5F`, disconnect, status, build/signing, regresi).
- `07_REVCORE_TEKNIS_2026-11-20/INVESTIGASI_MODE_0x5F.md` — bukti lokasi tampilan, offset dat17, decoder `1..4`, perbandingan dengan referensi 3D Chart.
- `07_REVCORE_TEKNIS_2026-11-20/INVESTIGASI_DISCONNECT_INTERMITTEN.md` — rantai USB/K-Line, timeout, backoff, state `SUSPECTED_LOSS`.
- `07_REVCORE_TEKNIS_2026-11-20/MATRIKS_STATUS_17_PEKERJAAN.md` — tabel status jujur + catatan bahwa daftar asli tidak ditemukan.
- `07_REVCORE_TEKNIS_2026-11-20/REGRESI_DAN_BUKTI.md` — regresi, batas klaim, prosedur reproduksi.
- `07_REVCORE_TEKNIS_2026-11-20/bukti/` — log fail-closed signing, log unit test, verifikasi APK resmi (161126 & Keyless), ringkasan 330 test, SHA-256.

### Changed
- `README.md` — indeks folder 07 dan tautan laporan baru.
- `PUBLICATION_MANIFEST.csv` — hash SHA-256 diperbarui dan entri folder 07 ditambahkan.

### Preserved
- Seluruh laporan Tahap 1/Tahap 2 dan riwayat Git tidak diubah.
- Tidak ada APK/ZIP yang diunggah; hanya hash dan hasil verifikasi.

## [Tahap 2] — 2026-11-19

Work order: DEEP AUTOPSY TAHAP 2 / H-Diag 2.1 & 3D Chart Graph Remap K-Line. Research only: tidak ada implementasi, patch, atau perubahan RevCore.

### Added
- `03_EVIDENCE/PROTOCOL_FRAME_VALIDATION_STAGE2.csv` — audit ulang 45 frame; semua checksum PASS.
- `03_EVIDENCE/HDIAG_STAGE2_EVIDENCE.md` — tabel 50 baris, dispatcher token-count, mekanika `setRow`, 48 call site, tabel per tipe ECU, jalur DTC.
- `03_EVIDENCE/3DCHART_STAGE2_EVIDENCE.md` — `InitFtdiIso`, `SendCommand` (echo/panjang/checksum/timeout), polling, pemetaan dat.
- `04_FINAL_REPORTS/STAGE2_HDIAG_LIVEDATA_PARSER.md` — sembilan parameter wajib: baris, jalur balasan, slot, batasan.
- `04_FINAL_REPORTS/STAGE2_3DCHART_SENSOR_PROTOCOL.md` — sensor per dat, endianness, nilai basi, validasi protokol.
- `04_FINAL_REPORTS/STAGE2_3DCHART_REMAP_DEEPDIVE.md` — signature ECU, checksum, alamat vs indeks blok, ACK, fast write, ketiadaan read-back.
- `04_FINAL_REPORTS/STAGE2_CONCLUSION_CORRECTIONS.md` — 14 koreksi klaim Tahap 1 beserta alasan.
- `04_FINAL_REPORTS/STAGE2_REVCORE_SUMMARY.md` — daftar terbukti/dugaan/unknown/hardware + relevansi kelas 1–4.
- `CHANGELOG.md` — file ini.

### Changed
- `README.md` — indeks Tahap 2, catatan supersede, dan tautan bukti baru.
- `PUBLICATION_MANIFEST.csv` — hash SHA-256 seluruh file setelah pembaruan.

### Preserved
- Seluruh laporan dan bukti Tahap 1 tidak diubah dan tetap menjadi riwayat penelitian.
- Identitas, kredit, dan riwayat commit Otoy tidak diubah; tidak ada force push.

### Corrections (ringkas)
- Nomor baris H-Diag: 30 baris (STF=0) → 50 baris (RPM=0, STF=20, IAC=32).
- Slot `0x0C` dikoreksi dari IAC ke O2; slot `0x14` dari TPSV2 ke STF; slot `0x0F/0x1B/0x1E` dari EVA/EGCV/tak dikenal ke BAS/ALT/MIL.
- `array9[2]` dari "DUGAAN tableType" menjadi byte fungsi `0x71` (A).
- Timeout: dari "tampil nol" menjadi "nilai lama bertahan" saat `b[1]==5`.
- Seed/key: dari "berbasis BIN" menjadi challenge runtime ECU.
- Fast-write frame: dari DUGAAN menjadi Source Verified (khusus `KEIHINOTHER`).
- "Bug alamat" remap dibatalkan: `startOffset/16` (alamat) vs `/128` (indeks) adalah desain.

## [Tahap 1] — 2026-11-19

Work order: REVCORE REFERENCE AUTOPSY — BAGIAN I & II.

### Added
- Struktur baru repository: inventory 869 file, ekstraksi string H-Diag, register bukti, tujuh laporan wajib, artefak lama.
- `03_EVIDENCE/PROTOCOL_FRAME_VALIDATION.csv` — 30 frame.
- `PUBLICATION_MANIFEST.csv`, `PUBLICATION_SANITIZATION.md`.
- `06_REPOSITORY/REMOVED_OLD_FILES.txt`, `06_REPOSITORY/REPOSITORY_UPDATE_REPORT.md`.

### Preserved
- Tiga screenshot unggahan pemilik dari commit `9b7037e` dipindahkan ke `05_ARTIFACTS/legacy_screens/`.
- Riwayat 136 file lama tetap tersedia melalui commit tersebut.
