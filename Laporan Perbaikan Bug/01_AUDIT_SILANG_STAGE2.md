# LAPORAN AUDIT SILANG — HASIL OTOPSI TAHAP 2 vs SOURCE REVCORE

| Item | Keterangan |
|---|---|
| Tanggal audit | 2026-11-19 |
| Objek audit | Source RevCore (`com.revcore.android`, versionName 1.0) |
| Referensi pembanding | `otoy6661/Laporan-Revcore`, commit Tahap 2 `0f62d43dff59ec39072d7405380fe6a255c05082` |
| Dokumen pembanding | `STAGE2_REVCORE_SUMMARY.md`, `STAGE2_HDIAG_LIVEDATA_PARSER.md`, `STAGE2_3DCHART_SENSOR_PROTOCOL.md`, `STAGE2_3DCHART_REMAP_DEEPDIVE.md`, `STAGE2_CONCLUSION_CORRECTIONS.md`, evidence H-Diag/3D Chart, `PROTOCOL_FRAME_VALIDATION_STAGE2.csv` |
| Status | Audit selesai; belum ada implementasi |
| Pengujian hardware | Tidak dilakukan |
| Pengujian write/flash | Tidak dilakukan |

**Tingkat bukti yang dipakai:**

- **FAKTA KODE** — perilaku dapat dibuktikan langsung dari source RevCore.
- **INFERENSI** — kesimpulan logis dari kode/dokumen, belum diuji di hardware.
- **REKOMENDASI** — usulan, belum diputuskan.

---

## 1. Ringkasan Kondisi Source RevCore

RevCore adalah aplikasi Compose satu modul (`com.revcore.android`, versionName 1.0) dengan tiga lapisan yang relevan:

1. **Transport & framing** — `KlineWireEngine` menangani purge buffer, penolakan echo TX sendiri, validasi checksum/panjang, dan klasifikasi kegagalan (`LOCAL_ECHO_ONLY`, `TIMEOUT`, `CHECKSUM_FAILED`, `INCOMPLETE`, `NO_VALID_FRAME`).
2. **Protokol & data live** — `HondaProtocolEngine` dengan profil tabel di `LiveDataProfile` (dat17/13/11/10/16/20/D1), status per-parameter (VALID, NOT_RESPONDING, NOT_AVAILABLE_IN_KOEO, UNSUPPORTED, INVALID_RESPONSE, WAITING_FOR_DATA, STALE).
3. **Remap/flash** — `FlashEngine`, `RemapWorkflow`, `MapValidator` — semuanya default-deny; `WRITE_PROTOCOL_PROVEN=false`, `READBACK_PROVEN=false`, `RECOVERY_PROVEN=false`, `WRITE_IMPLEMENTED=false`.

**Kesimpulan ringkas:** jalur komunikasi dan pembacaan live sudah cukup defensif; kelemahan nyata yang terkonfirmasi terkonsentrasi di **parsing DTC**. Ketidakpastian besar ada di **semantik kanal datD1 dan sensor khusus** (butuh capture hardware) dan **algoritma checksum ROM** (butuh riset offline). Tidak ada risiko bricking karena tidak ada jalur tulis yang aktif: seluruh 489 record di `ecm_database.json` memiliki `isVerifiedRemap=false`, sehingga `remapSupported` di `TuningScreen` selalu false dan tombol WRITE BIN tidak pernah mengirim perintah.

---

## 2. BUG TERKONFIRMASI (Klasifikasi A)

### A1 — Deteksi format count-prefix DTC memakai `>=`, bukan pencocokan panjang tepat

**FAKTA KODE.** `HondaDtcDatabase.parseDtcPacket`:

```kotlin
if (firstByte in 1..10 && payload.size >= 1 + firstByte * 2) {
```

Parser strict yang tidak dipakai jalur aktif justru mensyaratkan panjang tepat: `data.size == 1 + count * 2` (`parseDtcResponse`).

Akibatnya, payload pasangan DTC yang kebetulan diawali byte 0x01–0x0A akan salah ditafsirkan sebagai daftar ber-count. Contoh sintetis yang dapat direproduksi: payload `[01 07 08 01]` dibaca sebagai "1 kode: (7,8)" padahal jika formatnya pasangan murni isinya adalah (1,7) dan (8,1). Parser juga tidak memeriksa sisa byte setelah `1 + count*2`, sehingga payload campuran tetap lolos.

- **Dampak:** kode DTC bisa salah baca atau hilang.
- **Risiko:** sedang — tidak menyentuh aktuator, tetapi menyesatkan diagnosis.
- **Rekomendasi:** gunakan pencocokan panjang tepat dan tolak payload yang tidak persis cocok dengan salah satu layout.

### A2 — Payload yang tidak terurai tetap dilaporkan sebagai "tidak ada kode" dan `DTC_READ_CONFIRMED`

**FAKTA KODE.** `HondaProtocolEngine.readDtcsInternal`: setelah frame valid, `parseDtcPacket(payload)` menghasilkan list kosong → `DtcReadState.OK_EMPTY`, `dtcReadSucceededWithCodes=false`, dan status sesi diset `DTC_READ_CONFIRMED`. Tidak ada state "respons diterima tapi tidak dapat diurai". Padahal `HondaDtcDatabase.parseDtcResponse()` sudah menyediakan hasil `null` saat struktur ambigu — tetapi fungsi itu tidak dipanggil dari jalur aktif (hanya deklarasinya).

- **Dampak:** layar dapat menyatakan "ECU tidak melaporkan kode aktif" padahal frame berisi data yang tidak berhasil diinterpretasikan. Ini persis risiko yang diperingatkan otopsi: membedakan "nol sah" dari "gagal memahami".
- **Risiko:** sedang.
- **Rekomendasi:** tambahkan state eksplisit `UNPARSED`/`AMBIGUOUS` dan hanya set `DTC_READ_CONFIRMED` jika payload benar-benar kosong secara sah atau berhasil diurai.

**Catatan (klasifikasi C):** daftar kosong itu sendiri **bukan bug** — ECU sehat memang boleh melaporkan nol DTC. Yang menjadi bug adalah ketidakmampuan membedakan nol sah dari payload tak terurai.

### A3 — Subcode di luar 0..15 dipaksa menjadi 0 dan dapat memunculkan deskripsi DTC yang salah

**FAKTA KODE.** `HondaDtcDatabase.parseDtcPacket`:

```kotlin
val rawSub = if (i + 1 < payload.size) payload[i + 1].toInt() and 0xFF else 0
val subCode = if (rawSub in 0..15) rawSub else 0
```

Subcode mentah >15 diganti 0, lalu `decode()` mencocokkan ke database. Contoh: code 7 dengan subcode mentah 0x20 akan tampil sebagai **P0115 "ECT sensor circuit malfunction"** — diagnosis spesifik yang tidak pernah dilaporkan ECU.

- **Dampak:** salah diagnosis; nilai mentah hilang dari tampilan.
- **Risiko:** sedang-rendah.
- **Rekomendasi:** pertahankan subcode mentah pada objek DTC dan tandai "tidak terverifikasi" alih-alih memetakan ke kode lain.

### Area A (komunikasi) — tidak ditemukan bug terkonfirmasi

Tidak ada temuan A-level pada timeout, checksum frame, respons tidak lengkap, buffer basi, retry, atau status adapter. Mekanisme yang memastikan hal ini ada di bagian 3.

---

## 3. MEKANISME YANG SUDAH BENAR / SUDAH DITANGANI (Klasifikasi B)

| # | Mekanisme | Bukti |
|---|---|---|
| B1 | Validasi frame: panjang 4..0xFE, header diizinkan, checksum paket | `HondaFrameCodec.isWellFormed` |
| B2 | Penolakan echo TX sendiri (jendela 1500 ms / 32 frame) + klasifikasi `LOCAL_ECHO_ONLY`, `CHECKSUM_FAILED`, `INCOMPLETE` | `KlineWireEngine.extractFrame`, `drainStaleInput` |
| B3 | Purge buffer sebelum transaksi; tidak membaca jika tidak ada byte | `KlineWireEngine.transceive` |
| B4 | Tidak ada substitusi nol: parser tidak pernah mengisi 0 saat data gagal; kartu hanya tampil untuk `isValid()`; status per-sensor di `EcuInfoScreen.SensorAvailabilityCard` | `LiveDataProfile.parse`, `LiveDataScreen`, `EcuInfoScreen` |
| B5 | Kegagalan integritas menghentikan stream dan memutus adapter | `MainViewModel.applyIntegrity`, `shutdownAfterFailure` |
| B6 | Polling digantung pada `isEcuAlive`; berhenti saat detach/manual/exit/clear DTC; restart setelah identify | `MainViewModel.startLiveStream`, `disconnectAdapter`, `openAndIdentify` |
| B7 | Backoff berbatas dan berhenti setelah 4 kegagalan beruntun | `LivePollPolicy` |
| B8 | Transaksi tidak tumpang tindih (Mutex) | `EcuSessionManager.transact` |
| B9 | Echo tabel live wajib cocok sebelum payload diurai | `HondaProtocolEngine.extractLivePayload` |
| B10 | Clear DTC: ACK + jeda + baca ulang; hasil `SUCCESS_VERIFIED` / `RE_DETECTED_ACTIVE_FAULT` / `CLEARED_UNVERIFIED` | `HondaProtocolEngine.clearDtcs` |
| B11 | Remap default-deny berlapis; tidak ada perintah tulis/erase | `FlashEngine.startWrite`, `RemapWorkflow.WRITE_IMPLEMENTED=false`, `MapValidator.flashingGate()` → `FLASHING_BLOCKED`, `uploadRomToEcu` menolak |
| B12 | Verifikasi round-trip edit MAP (SHA-256 payload asli vs hasil re-enkripsi) | `MapEditor.verifyRoundTrip()` |
| B13 | Rotasi tabel ekstensi dengan skip 15 s setelah 2 kali gagal | `HondaProtocolEngine.refreshExtensionTables` |

---

## 4. KANDIDAT PENINGKATAN (Klasifikasi D)

Bukan bug, tetapi layak dipertimbangkan.

1. **Konsolidasi parser DTC.** Satukan `parseDtcResponse()` (strict) ke jalur aktif, atau terapkan aturan yang sama pada `parseDtcPacket()`. Ini sekaligus menutup A1–A3.
2. **State UI DTC tambahan.** `DtcReadState` saat ini tidak punya nilai untuk "frame diterima, payload ambigu". Menambahkannya membuat UI jujur tanpa mengubah arsitektur.
3. **Label netral untuk kanal datD1.** `GEAR_STATE`, `FLAG_A`, `FLAG_B` posisinya konsisten dengan referensi (payload byte 0/4/5 = frame b4/b8/b9), tetapi namanya hasil rekonstruksi. Menampilkan nilai mentah + label netral sampai capture hardware tersedia akan menghindari klaim semantik yang belum terbukti.
4. **Dead code.** `KlineEchoFilter` tidak pernah diinstansiasi; `KlineTransceiver` hanya dipakai `LegacyHondaProtocolEngine`. Bukan bug, tetapi menambah beban pemeliharaan dan berpotensi menyesatkan audit berikutnya.
5. **Overhead pacing.** `nextDelayMs` memakai `transactionMs + 50` sebagai *delay*, sehingga periode efektif = durasi transaksi + delay. Pada transaksi ~300 ms, periode menjadi ~650 ms. Bukan bug (adaptif), tetapi jika target pembaruan live lebih rapat, formula ini perlu ditinjau.
6. **Gate checksum saat impor BIN.** Impor memvalidasi checksum terhadap algoritma model. Karena algoritma belum terbukti (lihat E5), file yang sah secara teori bisa ditolak. Ini keputusan pemilik: tetap tolak (konservatif) atau beri peringatan.

---

## 5. TEMUAN BELUM DAPAT DIPASTIKAN (Klasifikasi E)

| # | Hal yang belum pasti | Mengapa belum pasti | Dampak jika salah |
|---|---|---|---|
| E1 | Arti byte payload datD1: b4 (BAS/SSS/SSW vs status gigi), b8 (POM/Fuel Pump), b9 (FAN/GGV) | Laporan 3D Chart sendiri memberi grade **E** untuk pemetaan ini; RevCore memakai nama rekonstruksi | Salah label sensor; keputusan servis keliru (mis. fan dianggap mati) |
| E2 | Encoding posisi gigi (b10) dan nilai validnya | Tidak ada capture; RevCore hanya menampilkan byte | Netral/gigi salah tampil |
| E3 | Ketersediaan kanal FIS, Mode Altitude, IAC, ALT, Side Stand, Starter Switch, Fuel Pump pada ECU target | Tidak ada di profil RevCore; apakah ECU benar-benar mempublikasikan pada 10.400 baud dan dalam budget poll belum diketahui | Fitur tidak ada (bukan bug), atau klaim "tidak tersedia" yang salah |
| E4 | Skala O2 (`b4/50.9937`) dan STF (`b5/128.25651`), serta keputusan tidak menurunkan AFR | RevCore menyimpan nilai mentah/faithful dan sengaja tidak meniru derivasi AFR | Nilai O2/STF menyesatkan bila skala salah |
| E5 | Algoritma checksum ROM: RevCore `KEIHIN_16BIT_ADD` (word sum big-endian) vs referensi `Sum8Bit` + two's complement; `SHINDENGEN_CRC16` vs referensi 32-bit sum | Dokumen referensi tidak dapat diverifikasi tanpa image/ECU; semua model `isVerifiedRemap=false` | Validasi/impor BIN keliru — tetapi **tidak ada jalur tulis**, jadi tidak ada risiko bricking |
| E6 | Layout frame DTC nyata per model/family (count-prefixed vs pasangan murni, posisi echo) | A1–A3 menunjukkan parser menerima banyak layout; mana yang benar-benar dipakai ECU belum direkam | Frekuensi salah baca DTC |
| E7 | Timeout/baud per family (600/800/300/700/800 ms; 10400/9600) | Diwarisi dari rekonstruksi, belum diukur | Timeout palsu atau poll lambat |
| E8 | Kebenaran temuan otopsi H-Diag (klaim grade A/B) | Tidak ada akses ke source H-Diag; hanya laporan | Terlalu percaya pada pembanding |

**Catatan:** E1–E4 hanya dapat diselesaikan dengan capture log read-only (tanpa write). E5 dapat diselesaikan offline dengan sampel BIN dan dokumentasi publik. Tidak satu pun boleh dijadikan dasar perubahan kode sebelum ada bukti.

---

## 6. PERBANDINGAN REVCORE vs H-DIAG vs 3D CHART

| Area | H-Diag (menurut laporan) | 3D Chart (menurut laporan) | RevCore (fakta kode) | Penilaian |
|---|---|---|---|---|
| Framing/checksum | Validasi ketat | Checksum paket | `isWellFormed` + checksum + echo rejection | **Setara/lebih defensif** |
| Buffer basi | Tidak dirinci | Tidak dirinci | Purge + drain 8×512 | **RevCore unggul** |
| Status live per PID | Status per pembacaan | Sebagian | 7 state per parameter, tanpa substitusi nol | **RevCore unggul** |
| DTC | Validasi panjang + status | Tidak fokus | Heuristik longgar (A1–A3) | **RevCore lemah di sini** |
| Sensor khusus (IAC/STF/FIS/ALT/SS/STS/FAN/POM) | Sebagian | Pemetaan grade E | Sebagian dinamai, sebagian belum | **Setara-tidak pasti** |
| Remap/flash | Retry 2×, readback tidak ada | Auto checksum, seed/key, fast write | Default-deny total, tanpa write | **RevCore paling aman** |
| Verifikasi tulis | Tidak ada | Tidak ada | Diblokir eksplisit | **RevCore benar** |

RevCore tidak menyalin pemetaan 3D Chart; perbedaan checksum dan penamaan adalah implementasi sendiri yang belum diverifikasi — bukan plagiasi, tetapi juga belum terbukti benar.

---

## 7. PRIORITAS RISIKO/DAMPAK

1. **P1 — DTC (A1–A3).** Dampak diagnosis langsung; dapat diperbaiki dan diuji unit test tanpa hardware. Tidak ada risiko keselamatan aktuator, tetapi bisa menyesatkan teknisi.
2. **P2 — Semantik datD1 & sensor khusus (E1–E4).** Dampak tampilan/keputusan servis; **tidak boleh diubah tanpa capture**.
3. **P3 — Checksum ROM (E5).** Hanya memengaruhi impor/validasi offline; jalur tulis tertutup, sehingga risiko bricking nol.
4. **P4 — Dead code & pacing (D4–D5).** Kebersihan dan performa, bukan risiko.
5. **P5 — Tanpa temuan** pada area komunikasi, lifecycle polling, dan penghentian stream.

---

## 8. URUTAN PERBAIKAN YANG DISARANKAN (belum diimplementasikan)

1. **Perbaiki parser DTC** — pencocokan panjang tepat untuk count-prefix, pertahankan subcode mentah, tambahkan hasil "ambiguous/unparsed". Uji dengan frame sintetis (termasuk contoh A1).
2. **Perbaiki pelaporan status DTC** — hanya set `DTC_READ_CONFIRMED` untuk payload kosong yang sah atau hasil parse valid.
3. **Netralkan label datD1** — tampilkan nilai mentah dengan label netral sampai capture tersedia; jangan mengubah pemetaan berdasarkan dugaan.
4. **Capture hardware read-only** (tugas terpisah, perlu persetujuan) — rekam frame datD1/dat20, DTC, dan kanal sensor khusus pada satu model acuan.
5. **Riset checksum offline** — bandingkan algoritma RevCore dengan sampel BIN dan dokumentasi; tanpa write.
6. **Bersihkan dead code** setelah jalur aktif dipastikan.
7. **Tinjau pacing** hanya jika target interval live ditetapkan.

Semua langkah di atas adalah **rekomendasi**. Tidak ada implementasi sebelum pemilik membaca dan menyetujui laporan ini.

---

## 9. REFERENSI FILE/LOKASI

### Bug terkonfirmasi

| Temuan | Lokasi |
|---|---|
| A1 | `app/src/main/java/com/revcore/android/core/protocol/HondaDtcDatabase.kt` — `parseDtcPacket`, kondisi count-prefix |
| A1 pembanding | `HondaDtcDatabase.kt` — `parseDtcResponse`, syarat panjang tepat (tidak dipakai jalur aktif) |
| A2 | `app/src/main/java/com/revcore/android/core/protocol/HondaProtocolEngine.kt` — `readDtcsInternal`, `OK_EMPTY` + `DTC_READ_CONFIRMED` |
| A3 | `HondaDtcDatabase.kt` — `parseDtcPacket`, coercion subcode 0..15 |

### Mekanisme yang sudah benar

- `core/comm/HondaFrameCodec.kt`
- `core/comm/LivePollPolicy.kt`
- `core/comm/KlineWireEngine.kt` — `extractFrame`, `drainStaleInput`, `transceive`
- `core/comm/EcuSessionManager.kt` — `transact`
- `core/protocol/HondaProtocolEngine.kt` — `extractLivePayload`, `refreshExtensionTables`, `clearDtcs`
- `data/flashpro/FlashEngine.kt`, `RemapWorkflow.kt`, `MapValidator.kt`, `MapEditor.kt`
- `ui/MainViewModel.kt` — `applyIntegrity`, `startLiveStream`, `openAndIdentify`, `disconnectAdapter`

### Profil & tampilan

- `core/comm/LiveDataProfile.kt` — tabel 17/13/11/10/16/20/D1
- `ui/screens/LiveDataScreen.kt` — urutan & label sensor
- `ui/screens/EcuInfoScreen.kt` — status ketersediaan per sensor
- `ui/screens/TuningScreen.kt` — `remapSupported` / `btn_write_bin` (selalu false karena 489/489 `isVerifiedRemap=false`)

### Dead code

- `core/protocol/KlineEchoFilter.kt` — tidak diinstansiasi
- `core/protocol/KlineTransceiver.kt` — hanya dipakai `LegacyHondaProtocolEngine`

### Laporan pembanding

- `04_FINAL_REPORTS/STAGE2_REVCORE_SUMMARY.md`
- `04_FINAL_REPORTS/STAGE2_HDIAG_LIVEDATA_PARSER.md`
- `04_FINAL_REPORTS/STAGE2_3DCHART_SENSOR_PROTOCOL.md`
- `04_FINAL_REPORTS/STAGE2_3DCHART_REMAP_DEEPDIVE.md`
- `04_FINAL_REPORTS/STAGE2_CONCLUSION_CORRECTIONS.md`
- `03_EVIDENCE/HDIAG_STAGE2_EVIDENCE.md`
- `03_EVIDENCE/3DCHART_STAGE2_EVIDENCE.md`
- `03_EVIDENCE/PROTOCOL_FRAME_VALIDATION_STAGE2.csv`
