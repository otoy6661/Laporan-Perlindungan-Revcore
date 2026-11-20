# FLASHPRO — KEYLESS ID RESEARCH

Work order §3. Fokus: alur Keyless ID, batas Read/Identify/Service, dan bukti
teknis yang sah untuk dipahami.

Kelas bukti §7 dipakai. **Tidak ada kelas D** (tidak ada ECU/smartkey fisik).

---

## 1. Sumber dan identitas

| Artefak | SHA-256 | Peran |
|---|---|---|
| `FLASHPRO_1.0.apk` | `9fff9691…14b0` | aplikasi Android, pemanggil perintah |
| `firmware.bin` | `fe0704fd…65e1` | firmware ESP32, pelaksana K-Line |
| `firmware.signed.flash` | `97ca99e9…9508` | image tertandatangani |
| `dispatcher_full.c.txt` | — | dekompilasi dispatcher (baris 926–938) |

Ghidra 12.2 headless, program `firmware.elf` (Xtensa LE). Log:
`evidence/ghidra_keyless_core.log`, `…_decomp.log`, `…_read.log`,
`evidence/ghidra_smk_table.log`.

---

## 2. Tiga fungsi yang harus dibedakan

| Fungsi | Perintah | Handler | Arti sebenarnya | Kelas |
|---|---|---|---|---|
| Read | `Immo_read` | `FUN_400eae84` | Baca 256 alamat EEPROM setelah handshake, lalu hitung ID 9 digit dari offset model | A |
| Identify (auto) | `Immo_read_auto` | `FUN_400ec564` | Deteksi ECM lebih dulu, lalu memanggil Read yang sama | A |
| Reset | `Immo_reset` | `FUN_400e8f20` | Fungsi tulis/renew; mensyaratkan hasil Read | A (keberadaan) |

- **Bukan** tiga kemampuan UI yang setara. Identify hanyalah Read dengan
  pra-deteksi. Reset adalah fungsi tulis.
- Sesuai batas etika work order, isi rutin tulis (`FUN_400e51b8`) **tidak**
  dianalisis lebih jauh dan tidak direproduksi. Tidak ada ekstraksi kredensial
  rahasia, tidak ada bypass.
- ID 9 digit yang ditampilkan aplikasi adalah keluaran sah dari data yang dibaca;
  penelitian berhenti pada pemahaman alur, bukan pada penyalahgunaan.

Gerbang fitur: `FUN_400e813c(8, "smartkey_locked")`. Bila bit 8 = 0, handler diam
tanpa event. Kelas A.

---

## 3. Alur Read (A. FACT)

```
App ──Immo_read(model_idx)──► firmware
                               │  emit Immo_reading
                               ▼
                      handshake + probe vendor
                               │
              ┌────────────────┴────────────────┐
        KEIHIN OK                        SHINDENGEN OK
        baca 256 alamat                  baca 256 alamat
              └────────────────┬────────────────┘
                               ▼
                 data 512 byte + vendor
                               │
                 hitung ID dari 4 offset model
                               ▼
              emit Immo_read_result {key_id, ecm_id, model, hex}
              emit Immo_read (progress tiap 16 alamat)
```

Kegagalan handshake menghentikan alur dengan event status 0; tidak ada ID palsu.

---

## 4. Handshake — frame dan waktu (A. FACT)

Loop maksimum `DAT_400d10cc = 59999` ms (±60 s). Per percobaan:

| Urutan | Aksi | Byte | Waktu |
|---|---|---|---|
| 1 | wake K-Line | `FUN_400d8c1c` | pin HIGH 40, LOW 70, HIGH 130, HIGH 130, LOW 70, HIGH 130 ms |
| 2 | jeda | — | 70 ms |
| 3 | wake/test present | `FE 04 72 8C` | — |
| 4 | start comm | `72 05 00 F0 99` | — |
| 5 | Keihin hello | `27 0B E0 48 65 6C 6C 6F 48 6F 43` (`HelloHoC`) | — |
| 6 | Keihin who | `27 0B E0 77 41 72 65 59 6F 75 22` (`wAreYou`) | — |
| 7 | jeda | — | 1000 ms |
| 8 | Shindengen xor1 | `91 91 0D DF 9E 8D 9A 86 90 8A 8C 9B 88` | — |
| 9 | Shindengen xor2 | `91 91 0D DF 92 9E 86 96 8B 8D 86 C0 6A` | — |
| 10 | probe Keihin | `82 82 10 06 00 E6` | timeout 250 ms |
| 11 | cek hidup | `72 05 71 00 18` | timeout 200 ms |
| 12 | probe Shindengen | `91 91 07 40 4C 00 6D` | timeout 250 ms |

Keputusan:

- Probe Keihin dijawab > 8 byte → KEIHIN ACCESS GRANTED → baca 256 alamat.
- Bila tidak, probe Shindengen > 8 byte → SHINDENGEN ACCESS GRANTED.
- Bila probe Shindengen pendek, balasan 9..13 byte dipakai sebagai ECM ID 5 byte.
- Bila balasan ≤ 5 byte, probe diulang; gagal → pesan "MATIKAN HIDUPKAN KUNCI KONTAK".

---

## 5. Pembacaan EEPROM (A. FACT)

### 5.1 Keihin (`FUN_400e52d4`)

- 256 alamat, tanpa jeda antar-alamat.
- Frame: `82 82 10 06 <addr> <0xE6 - addr>`.
- Timeout 400 ms; balasan wajib ≥ `0x0C` byte; data = byte 10 dan 11.
- Gagal → firmware mengisi `FF FF` untuk alamat itu.

### 5.2 Shindengen (`FUN_400e541c`)

- 256 alamat.
- Frame: `91 91 07 40 <addr> 00 <0x6D - addr>`.
- Timeout 300 ms; balasan wajib ≥ `0x0D` byte; data = byte 11 dan 12.
- Gagal → `FF FF`.

Progress `Immo_read` dikirim tiap 16 alamat (0, 0x10, …). Vendor disimpan
(1=KEIHIN, 2=SHINDENGEN). Kelas A.

Catatan: checksum frame Keihin adalah two's complement dari lima byte body;
Shindengen hanya dari `07 + 40 + addr`, persis seperti yang direproduksi RevCore.

---

## 6. Tabel model (A. FACT)

27 entri × 0x14 byte di `0x3F408D74`. Format:
`nama(10) | part | off1 | off2 | off3 | off4 | mode`.

| Model | Part | off1/off2 | off3/off4 | mode |
|---|---|---|---|---|
| VARIO 150 | 30400-K59J-A71 | 144/145 | 160/161 | 0 |
| VARIO 125 | 30400-K2VG-N42 | 60/61 | 62/63 | 0 |
| VARIO 160 | 30400-K2SA-N02 | 60/61 | 62/63 | 0 |
| ADV 150 | 30400-K0WA-N01/N11 | 64/65 | 80/81 | 0 |
| ADV 160 | 30400-K0WL-NA1 | 64/65 | 76/77 | 0 |
| ADV 160 | 30400-K0WL-NB1 | 64/65 | 76/77 | 0 |
| PCX 160 | 30400-K1ZG-N21 | 64/65 | 76/77 | 0 |
| PCX 160 | 30400-K1ZG-N31 | 64/65 | 76/77 | 0 |
| PCX 160 | 30400-K1ZN-N41 | 64/65 | 76/77 | 0 |
| PCX 160 | 30400-K1ZN-N51 | 64/65 | 76/77 | 0 |
| PCX 160 ROADSYNC 2025 | 30400-K1ZV-NF1 | 64/65 | 76/77 | 0 |
| PCX 160 ABS 2025 | 30400-K1ZV-NC1 | 64/65 | 76/77 | 0 |
| PCX 160 | 30400-K1ZV-NA1 | 64/65 | 76/77 | 0 |
| PCX 150 | 30400-K97G-N01 | 64/65 | 80/81 | 0 |
| PCX 150 | 30400-K97G-N31 | 64/65 | 80/81 | 0 |
| STYLO 160 | 30400-K3VA-N01 | 60/61 | 62/63 | 0 |
| BEAT 110 | 30400-K1AL-NB1 | 60/61 | 62/63 | 0 |
| SCOOPY 110 ×4 | 30400-K2F-N11/N91/ND1/NC1 | 70/71 | 72/73 | 1 |

(Nama-nama tabel lengkap ada di `EVIDENCE_NOTES_FLASHPRO_KEYLESS.md`.)

**B. INFERENCE:** offset adalah indeks byte ke buffer 512 byte hasil 256×2 byte;
pasangan pertama = dua byte kunci, pasangan kedua = byte transformasi. RevCore
memakai konvensi `address = offset / 2`, yang konsisten dengan tabel ini (mis.
K59J 144/145 → alamat 72, 160/161 → alamat 80).

---

## 7. Transformasi ID (A. FACT, dengan peringatan)

Parser `FUN_400e4470` mengambil 4 byte pada keempat offset (b1..b4).

**Mode 0** (PCX dan mayoritas):

```
u32 = b2 | (b3 << 8) | (b1 << 16) | (b4 << 24)
ID  = format("%09lu", u32)
```

**Mode 1** (SCOOPY):

```
u = ((b3 << 8) | b2) * 0x4000 + 0xE0000000
    + (((b1 << 16 | b4 << 24) >> 16) ^ 0x8000)
ID = format("%09lu", u)
```

Bila overflow negatif, firmware meng-clamp ke 0.

RevCore `KeylessIdDecoder`:

- PCX: `(s1<<24)|(s0<<16)|(f1<<8)|f0` — struktur sama dengan mode 0, tetapi urutan
  byte bergantung pada pemetaan offset→(f0,f1)/(s0,s1). **B. INFERENCE:** cocok.
- Keihin: `((b1<<8)|b0) * 0x4000 - 0x20000000 + ((b3<<8|b2) ^ 0x8000)` lalu format
  C# `D9` dengan tanda minus bila negatif.

**C. UNVERIFIED — perbedaan yang perlu diuji:** sisi firmware mode 1 mengalikan
pasangan byte pada offset 3/4 dan mem-XOR byte pada offset 1, sedangkan RevCore
mengalikan pasangan offset 1/2 dan mem-XOR pasangan offset 3/4. Kedua rumus tidak
dapat dinyatakan identik dari dekompilasi saja. Selain itu firmware memakai
unsigned 32-bit dan clamp 0, sedangkan RevCore memakai aritmetika 64-bit dan
menampilkan tanda minus. Ini kandidat bug nyata pada SCOOPY/Keihin, tetapi baru
dapat dipastikan dengan known-answer test atau laporan pemilik. Jangan "memperbaiki"
salah satu sisi tanpa bukti.

---

## 8. Perbandingan dengan implementasi RevCore

| Aspek | Firmware FlashPro | RevCore | Status |
|---|---|---|---|
| Init frames | `FE 04 72 8C`, `72 05 00 F0 99` | sama | Cocok (A) |
| Security request/key | Keihin & Shindengen, 11/13 byte | sama | Cocok (A) |
| Jeda setelah who/hello | 1000 ms | 150 ms antar frame | **Berbeda** (A) |
| Wake | 40/70/130/130/70/130 | 70/130 | **Berbeda** (A) |
| Probe vendor | probe-K lalu probe-S | tidak ada probe; langsung baca | **Berbeda** (A) |
| Jumlah alamat | 256 | 0..alamat tertinggi model (≤ 0x50) | **Berbeda** (A) |
| Threshold | Keihin 0x0C, Shindengen 0x0D | 13 / 15 | Cocok (A) |
| Data index | 10/11 dan 11/12 | sama | Cocok (A) |
| Gagal baca | isi `FF FF` | `null` (tidak diisi) | Berbeda; RevCore lebih jujur (A) |
| Model table | 27 entri | 11 entri | Berbeda (A) |
| Status bukti | firmware + APK | PROTOCOL_ANALYZED | Jujur (A) |
| Fungsi tulis/reset | ada | tidak ada | Sesuai batas etika |

**Kesimpulan:** jalur FTDI RevCore cukup untuk mereproduksi handshake dan
pembacaan, tetapi detail timing dan deteksi vendor belum meniru firmware. Jeda
1000 ms pada firmware bukan hiasan; ini kandidat penyebab kegagalan pada ECU yang
lambat bangun. Kelas B.

---

## 9. Batas yang disengaja

- Tidak ada analisis lanjutan rutin tulis EEPROM/Reset.
- Tidak ada ekstraksi kredensial, seed/key rahasia, atau bypass immobilizer.
- Tidak ada klaim bahwa fungsi registrasi/reset "tersedia" di RevCore; memang
  tidak diimplementasikan.
- Tidak ada penyalinan kode C# atau aset referensi ke RevCore.

---

## 10. Ringkasan

1. Keyless ID = baca EEPROM 256 alamat lewat K-Line 10400, bukan membaca chip
   secara langsung.
2. Dua keluarga frame dengan security access berbeda; pemilihan vendor dilakukan
   lewat probe.
3. ID 9 digit dihitung host/firmware dari 4 byte pada offset model; dua mode
   transformasi.
4. RevCore sudah meniru kerangka besar, tetapi belum meniru deteksi vendor,
   timing 1000 ms, pembacaan 256 alamat, dan konsistensi transformasi Keihin.
5. Semua status tetap PROTOCOL_ANALYZED/UNVERIFIED sampai ada laporan perangkat
   dari pemilik.
