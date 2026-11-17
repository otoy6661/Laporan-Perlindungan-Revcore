# 09 — ANALISIS LIVE MONITOR

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Modul:** `ScannerProModule.dll` + definisi ADX
**Status:** SELESAI — arsitektur tampilan, alur data, kontrol, dan perilaku tanpa hardware dipetakan. Tidak ada data ECU nyata yang diamati.

---

## 1. Pemisahan peran

| Lapisan | Komponen | Tanggung jawab |
|---|---|---|
| Transport | `TunerPro.exe` (`MMSerial`) | Membuka port, mengatur baud/parity/stopbits, kirim/terima byte |
| Definisi | ADX | Perintah koneksi/monitor, format paket, offset, skala, lookup |
| Mesin tampilan | `ScannerProModule.dll` | Lists, Dashboards, Monitors, History, log, playback |
| Host UI | `TunerPro.exe` | Menu Acquisition, status bar, jendela induk |

`ScannerProModule.dll` tidak mengimpor API serial. Ia menerima nilai yang sudah didekode dan hanya mengurus presentasi, cache, dan ekspor. Ini terlihat dari export `SPMonitorsPopulateDataFromCache` dan `SPExportDataLog`.

---

## 2. Empat mode tampilan

### 2.1 Data Lists

- Kontrol: `MMTABSHEET` "Lists" → `SysListView32` id `1000`, header, combo id `1010`.
- 3 kolom; 11 baris untuk `keihin.adx`:

| # | Baris | Nilai tanpa scan |
|---:|---|---|
| 1 | RPM Engine | — |
| 2 | TPS Volt | — |
| 3 | TPS Open d2 tech | — |
| 4 | Engine Temp (-40) | — |
| 5 | Battery Volt | — |
| 6 | Injector Duration | — |
| 7 | ADX Arbi | — |
| 8 | Ignition (-64.0) | — |
| 9 | O2 Sensor | — |
| 10 | AFR | 19.50 |
| 11 | (baris ke-11; label tidak tertangkap) | — |

Label `(-40)`, `(-64.0)` adalah offset yang ditulis di ADX. Nilai `19.50` pada AFR adalah nilai definisi/konstanta saat tidak ada data, bukan pengukuran.

### 2.2 Dashboards

- `SysTabControl32` dengan panel `Dashboards`; combo id `1015`.
- 9 gauge: 2 `MMANALOGGAUGE` (id 10000, 10002) + 7 `MMDIGITALGAUGEREADOUT` (id 10001, 10003–10008).
- Label `D2 TECH` tampak pada dashboard.

### 2.3 Monitors

- `SysTabControl32`; 2 `MMDATACHART` (id 9000, 9001).
- Trackbar `Time Range` id `1027`.
- Grafik tidak terisi tanpa data.

### 2.4 History Tables

- Combo `History Table` id `1002`, combo `View` id `1004`, `MMGRIDCONTROL` id `1006`.
- Tombol `Clear` (1008), `Graph` (1013), `3DCHART` (1011).
- `3DCHART` adalah kontrol khusus (bukan `MMDATACHART`), dipakai untuk permukaan 3D.

---

## 3. Alur data yang tersirat

```
ADX (connection/monitor command, packet layout)
        │
        ▼
TunerPro.exe (MMSerial: tulis perintah, baca byte, timeout)
        │  frame mentah
        ▼
Decoder ADX (offset, bitmask, lookup, skala)
        │  nilai per parameter
        ▼
ScannerProModule (SPUpdateView / SPUpdateDash / SPUpdateHistogramData)
        │
        ├─ Data List
        ├─ Dashboard gauge
        ├─ Monitor chart
        └─ History grid ──► SPExportDataLog (XDL/CSV)
```

Setiap tahap memiliki bukti terpisah: perintah di ADX (skema), serial di EXE (import + string `MMSerial`), update di ScannerPro (export `SPUpdate*`), ekspor (export `SPExportDataLog`). Namun **penyambungan aktual** tidak dapat diamati tanpa hardware.

---

## 4. Kontrol transport & status

| Kontrol | ID/kelas | Fungsi |
|---|---|---|
| Status bar | `msctls_statusbar32` 1004 | 4 pane: emulation, hardware, ready, DA |
| Progress teks | `MMTEXTPROGRESS` | Progres scan/operasi |
| Rich static | `MMRICHSTATIC` | Pesan/deskripsi |
| Trackbar | `msctls_trackbar32` 1014 | Posisi playback |
| Toolbar | 20000, 10008, 10002, 10004, 10001 | File, DA transport, view |
| Tombol Send | `Button` 1024 (tersembunyi) | Kirim perintah manual |
| Combo perintah | `ComboBox` 1025 (tersembunyi) | Pilih perintah manual |
| Combo baud | `ComboBox` 2955 (disabled) | Pemilihan baud |

Status DA berubah `Not Connected` → `Connecting...` saat scan dimulai. Tanpa perangkat, tidak ada transisi ke `Connected`, tidak ada dialog error, dan trackbar tetap tidak aktif.

---

## 5. Rekaman, playback, dan ekspor

Menu Acquisition menyediakan:

- `Load Log File...` (33060), `Export Log File...` (33075), `Close Log File` (33144).
- Playback 400/200/100/50/25% (33053–33057), Custom (33058).
- `Play/Pause` (33062), `Record` (33061), `Stop` (33063), `Pause` (33064).
- Lompat ±10 sampel (33066/33065), ±1 sampel (33117/33116).
- `Toggle Data Tracing` (33069).

Ekspor memakai `SPExportDataLog`; format XDL disebut di UI logger onboard (`Export Session To XDL`). Tidak ada file log yang diekspor selama pengujian.

---

## 6. Perilaku dengan ADX terenkripsi

- `keihin.adx` termuat dan seluruh tampilan terbentuk (11 baris, 9 gauge, 2 chart, history grid).
- Ini berarti **struktur tampilan tidak dienkripsi**; yang dienkripsi adalah definisi di dalam container, tetapi runtime tetap dapat membangun view dari definisi yang didekripsi oleh aplikasi saat load.
- AFR 19.50 muncul sebagai nilai awal; tidak ada bukti nilai itu berasal dari ECU.

---

## 7. Perbandingan dengan RevCore Live Data

| Aspek | TunerPro + ADX | RevCore (`LiveDataProfile.kt`) |
|---|---|---|
| Definisi | File ADX eksternal, dapat dienkripsi | Profil hardcoded per tabel Honda |
| Format paket | Statis atau variabel (header/footer) | Panjang tetap per tabel |
| Offset | Didefinisikan ADX | Didefinisikan `LiveFieldSpec` |
| Skala | MATH/lookup ADX | `scale`/`bias` per field |
| Status nilai | Tidak ada state per parameter; nilai bisa 0 | `VALID`/`NOT_RESPONDING`/`STALE`/`UNSUPPORTED`/… |
| AFR | Baris ADX dapat menampilkan konstanta | `UNSUPPORTED` (narrowband only) |
| Timeout | `listentimeout`, `silencelen` | Tidak dimodelkan |
| Playback | Ada (log + speed) | Tidak ada |

**Kesimpulan:** TunerPro lebih fleksibel dalam definisi, tetapi tidak memiliki model status per parameter; nilai yang hilang mudah tampil sebagai 0. RevCore lebih ketat secara semantik, tetapi kurang fleksibel dan belum memiliki format definisi eksternal.

---

## 8. Batas analisis Live Monitor

- Tidak ada hardware/ECU: tidak ada frame, tidak ada nilai nyata, tidak ada timing.
- Tidak ada log XDL yang dimuat/diekspor.
- Baris ke-11 Data List tidak tertangkap namanya.
- Tidak diuji multi-monitor, dashboard custom, atau history 3D dengan data.
- Tidak ada pengukuran latensi/throughput.

---

## 9. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Struktur widget & ID | TINGGI (enumerasi) |
| Alur definisi → tampilan | SEDANG–TINGGI (export + UI) |
| Perilaku tanpa hardware | TINGGI (observasi) |
| Perilaku dengan ECU | TIDAK ADA BUKTI |
| Format log/XDL | RENDAH (hanya nama fitur) |
