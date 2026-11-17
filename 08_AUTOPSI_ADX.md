# 08 — AUTOPSI ADX

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Sampel:** `ADX KEIHIN BE.adx` (40.199 B), `ADX SHINDENGEN BE.adx` (23.780 B), salinan kedua KEIHIN
**Status:** SELESAI — container, skema, model perintah/paket, dan perilaku runtime dipetakan. Isi terenkripsi tidak didekripsi.

---

## 1. Populasi ADX

| File | Ukuran | SHA-256 (awalan) | Container |
|---|---:|---|---|
| `ADX KEIHIN BE.adx` | 40.199 | `6b1d9b97…` | Terenkripsi |
| `ADX KEIHIN BE.adx` (salinan) | 40.199 | `6b1d9b97…` | Terenkripsi |
| `ADX SHINDENGEN BE.adx` | 23.780 | `c3df2e78…` | Terenkripsi |
| **Total** | 3 file (2 unik) | — | 3/3 terenkripsi |

Tidak ada ADX plaintext dalam dataset. Berbeda dari XDF (13 plaintext), seluruh pengetahuan ADX berasal dari:

1. Container dan entropi file nyata.
2. Token skema di `ADXEditor.dll` dan `TunerPro.exe`.
3. Dump UI editor ADX saat file terenkripsi dibuka (label kontrol tetap dirender).
4. Dump runtime Data List/Dash/Monitor/History.

---

## 2. Container

| Properti | Nilai |
|---|---|
| Magic | `05 22 97 00` |
| Marker | `0x64` pada offset `0x83` |
| Awal ciphertext | `0x84` |
| Ukuran header | 132 byte |
| Entropy KEIHIN | 7,995 (setelah header) |
| Entropy SHINDENGEN | 7,993 |
| Ciphertext KEIHIN | 40.067 B |
| Ciphertext SHINDENGEN | 23.648 B |

Container identik dengan XDF terenkripsi (magic, marker, offset). Ini menunjukkan satu rutin enkripsi/dekripsi bersama di aplikasi, bukan format terpisah per jenis definisi. Header tidak menyimpan nama, judul, atau tipe yang dapat dibaca.

---

## 3. Model skema ADX (dari token dan UI)

### 3.1 Elemen tingkat atas

| Token | Peran |
|---|---|
| `ADXFORMAT` / `ADXHEADER` | Pembungkus dan metadata |
| `ADXVALUE` | Definisi satu nilai |
| `ADXBITMASK` | Ekstraksi bit |
| `ADXLOOKUPTABLE` | Pemetaan nilai → label/skala |
| `ADXLISTVIEW` | Tampilan daftar |
| `ADXMONITOR` | Chart monitor |
| `ADXDASHBOARD` | Dashboard gauge |
| `ADXHISTOGRAM` | Histogram |
| `ADXCLISTENPACKET` | Perintah "dengarkan paket" |
| `ADXCSENDCOMMAND` | Perintah kirim |
| `ADXCLISTENSILENCE` | Dengarkan jeda/silence |
| `ADXCLISTEN160BAUD` | Mode 160 baud (GM) |
| `ADXCTRIGGER` | Trigger logging |
| `ADXMACRO` | Urutan perintah |

### 3.2 Field kunci

| Field | Arti |
|---|---|
| `packetoffset` | Offset byte dalam paket |
| `packetoffsetinbody` | Offset relatif terhadap body |
| `packetbodylength` | Panjang body |
| `headerstring` / `footerstring` | Penanda awal/akhir paket variabel |
| `packetsize` | Ukuran paket statis |
| `listentimeout` | Timeout menunggu paket |
| `silencelen` | Durasi silence |
| `baud`, `parity`, `stopbits` | Parameter serial |
| `monitorcmd`, `unpausecmd` | Perintah mode monitor |
| `SNDCMDCHECKSUM` | Flag checksum untuk perintah kirim |
| `lookupmode`, `lookupidhash` | Mode dan ID tabel lookup |
| `triggertype` | Jenis trigger |

### 3.3 Tipe item yang dapat dibuat (dari UI)

- **Send Command** — mengirim frame, opsional dengan checksum, opsional `Purge Before Sending`, `Tx/Rx`.
- **Listen for Packet** — menunggu paket dengan ukuran statis atau variabel (header/footer), timeout, `While monitoring`/`While not monitoring`.
- **Listen for Silence** — menunggu jeda.
- **Trigger** — memulai/menghentikan logging berdasarkan kondisi; `Break On Failure/Success`.
- **Macro Command** — urutan item dengan `Macro Repeat Count`.

### 3.4 Tab General editor ADX

`Author`, `Version`, `Description`, `Default Baud`, `Connection Command`, `Monitor Command`, `Disconnect Command`, `RS232 Echo`, `Encrypt File`, `Open Password`, `Edit Password`, `Stop Bits`, `Parity`, `Byte Size (Bits)`, `Pause/Unpause Command`.

**Kesimpulan:** ADX adalah **bahasa definisi transaksi serial** (kirim/dengar/timeout/macro), bukan protokol ECU tertentu. Protokol Honda hanya ada jika definisi ADX menyatakannya.

---

## 4. Perilaku runtime ADX

Saat `keihin.adx` dimuat tanpa hardware:

| Area | Isi |
|---|---|
| Data List | 11 baris: RPM Engine, TPS Volt, TPS Open d2 tech, Engine Temp (-40), Battery Volt, Injector Duration, ADX Arbi, Ignition (-64.0), O2 Sensor, AFR (19.50) |
| Dashboards | 9 gauge (2 analog + 7 digital), label `D2 TECH` |
| Monitors | 2 `MMDATACHART` (id 9000/9001) + `Time Range` |
| History Tables | combo id 1002, view 1004, `MMGRIDCONTROL` 1006, tombol Clear/Graph/3DCHART |
| Scan | status `DA: Connecting...`; tanpa dialog; trackbar dinonaktifkan |

Arti label (mis. `Engine Temp (-40)`, `Ignition (-64.0)`) adalah **offset/skala yang didefinisikan ADX**, bukan bukti ECU mengirim nilai tersebut. Tanpa scan sukses, tidak ada nilai yang bergerak.

**Catatan AFR:** baris `AFR (19.50)` berasal dari definisi ADX (kemungkinan lookup/konstanta). Ini tidak membuktikan ECU menyediakan AFR; pada Honda yang dianalisis RevCore, AFR justru ditandai `UNSUPPORTED` karena hanya ada O2 narrowband. Perbedaan ini dibahas di laporan 14.

---

## 5. Alur datalogging yang tersirat

Berdasarkan model perintah dan perilaku runtime:

1. ADX memuat parameter serial (baud/parity/stopbits).
2. `Connection Command` dikirim (jika ada), lalu `Monitor Command`.
3. `Listen for Packet` menunggu frame; `packetsize`/header/footer menentukan batas.
4. `ADXVALUE` mengekstrak byte pada offset, menerapkan bitmask, skala, dan lookup.
5. Nilai dikirim ke ScannerPro untuk Lists/Dash/Monitor/History.
6. `Pause/Unpause`, `Trigger`, `Macro` mengatur siklus.
7. `Disconnect Command` dikirim saat berhenti.

Langkah 1–7 adalah **model dari definisi**, bukan capture wire. Tidak ada frame nyata yang terlihat.

---

## 6. Mengapa ADX penting untuk RevCore

1. **Definisi terpisah dari kode.** TunerPro tidak memiliki driver Honda; ADX-lah yang mendeskripsikan permintaan/respons. RevCore saat ini meng-hardcode profil live data Honda di `LiveDataProfile.kt`.
2. **Format dapat memodelkan checksum perintah.** `SNDCMDCHECKSUM` menunjukkan checksum dihitung untuk frame keluar, konsisten dengan `HondaFrameCodec` (checksum dua-komplemen).
3. **Variabel vs statis.** Dukungan header/footer dan timeout adalah hal yang tidak dimiliki RevCore; RevCore mengasumsikan frame panjang tetap.
4. **Enkripsi menghalangi audit.** ADX Keihin/Shindengen yang disediakan tidak dapat dibaca, sehingga tidak bisa dijadikan bukti protokol. RevCore tidak boleh mengklaim kompatibel hanya karena nama file mengandung "KEIHIN".

---

## 7. Batas autopsi ADX

- Tidak ada ADX plaintext; skema disusun dari token + UI, bukan dari instance.
- Tidak ada capture serial; tidak ada verifikasi bahwa ADX mengirim frame yang valid.
- Tidak ada dekripsi; password tidak dicoba.
- Tidak diuji ADX buatan sendiri (authoring) karena risiko mengubah state dan tidak ada hardware.
- Istilah `D2 TECH`, `ADX Arbi` tidak dijelaskan oleh bukti; tidak ditafsirkan.

---

## 8. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Container & enkripsi | TINGGI (byte nyata) |
| Daftar token skema | TINGGI (string binary) |
| Semantik field | SEDANG (nama + UI) |
| Model alur datalogging | SEDANG (inferensi konsisten) |
| Isi ADX KEIHIN/SHINDENGEN | RENDAH (tidak dapat dibaca) |
