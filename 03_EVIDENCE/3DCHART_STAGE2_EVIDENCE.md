# 3D Chart Graph Remap K-Line — Bukti Statis Tahap 2

Sumber: source C# `Form1.cs` (878.075 byte) dan `Diag.cs` (60.541 byte) pada folder `3D Chart Graph remap kline\3D Chart Graph`.
Tidak ada eksekusi program, tidak ada koneksi ECU/adapter, tidak ada flashing.

Tingkat: **A** = terbaca langsung di source; **B** = sangat kuat; **C** = dugaan; **D** = belum diketahui; **E** = butuh hardware.

---

## 1. `InitFtdiIso` — inisialisasi transport (A)

`Diag.cs:1140–1269`

| Langkah | Baris | Nilai |
|---|---|---:|
| Buka perangkat | 1147 | `FT_Open(0)` |
| Purge | 1156 | `FT_Purge(3)` (purge RX+TX) |
| Bit mode reset | 1164 | `FT_SetBitMode(0,0)` |
| Data characteristics | 1172 | `FT_SetDataCharacteristics(8,0,0)` = 8-N-1 |
| Baud | 1180 | `FT_SetBaudRate(10400)` |
| Timeout | 1188 | `FT_SetTimeouts(50,0)` |
| Latency | 1196 | `FT_SetLatencyTimer(8)` |
| Bit-bang wake | 1204–1220 | `FT_SetBitMode(1,1)`, tulis 1 byte `00`, tunggu 70 ms |
| Lepas bit-bang | 1229 | `FT_SetBitMode(0,0)` |
| Baud ulang | 1237 | 10400 |
| Purge ulang | 1245 | `FT_Purge(3)` |
| Settle | 1253 | 130 ms |

## 2. `SendCommand` — pertukaran frame (A)

`Diag.cs:1271–1345`

- Buffer RX 256 byte, buffer akumulasi 256 byte.
- Timeout internal: `num6 = 50 + 2 * commandSize` milidetik (baris 1280).
- Kirim via `FT_Write` (1281).
- Opsional `Thread.Sleep(sleepMs)` sebelum membaca (1292–1296).
- Loop baca: `FT_GetQueueStatus` → hanya jika `0 < num2 < 256` → `FT_Read` (1301).
- Akumulasi sampai `num4 >= commandSize + 2` (1306). Artinya: **ECU diasumsikan menggemakan perintah**; dua byte setelah echo adalah awal frame balasan.
- Saat pertama kali ambang tercapai: `num5 = array2[commandSize + 1]` (1312) = byte panjang balasan (posisi `[1]` frame balasan, tepat setelah byte `0x72`).
- Frame dianggap lengkap jika `num4 - commandSize == num5` (1314).
- Salinan balasan = `num5` byte terakhir (1318) — echo dibuang.
- Validasi checksum `Checksum8BitHonda(reply, num5)` (1319, 1346–1348): `((sum8(reply[0..n-2]) ^ 0xFF) + 1) & 0xFF == reply[n-1]`.
- Timeout → `FT_Purge(3)` dan return `false` (1336–1339).

Konsekuensi terverifikasi:

1. `array9[0]` = `0x72`, `[1]` = panjang, `[2]` = byte fungsi (0x71), `[3]` = parameter, `[4..]` = data. **`array9[2]` bukan echo** — echo sudah dibuang oleh `Array.Copy(array2, num4-num5, reply, 0, num5)` (A).
2. Karena itu `tableType = array9[2]` (`Diag.cs:1040`) selalu bernilai `0x71` (113), yaitu byte fungsi balasan, bukan "tipe tabel". Nilai yang ditampilkan di baris 14 tabel praktis konstan (A).
3. Aplikasi ini **membutuhkan ECU yang melakukan echo**; ECU tanpa echo tidak akan pernah memenuhi `num4 - commandSize == num5` dan selalu timeout (B).
4. Balasan dengan checksum salah tidak diterima sebagai valid → loop terus sampai timeout (A).

## 3. Polling (A untuk kode, B untuk perilaku runtime)

`Diag.cs:516–559` — `LoopDat17`:

```
while (!token.IsCancellationRequested) {
  if (tek11) { dat11(); dat20(); }
  if (tek10) { dat10(); dat20(); }
  if (tek13) { dat13(); dat20(); }
  if (tek16) { dat16(); dat20(); }
  if (tek17) { dat17(); dat20(); }
  Task.Delay(10, token);        // tidak di-await
}
```

- `Task.Delay(10, token)` **tidak di-await** (baris 556) → tidak ada jeda efektif; loop berputar secepat IO.
- `dat20()` dipanggil setiap kali salah satu dat lain dipanggil, dan `dat20()` memanggil `datD1()` di akhir (baris 748 ff.).
- Akibat: O2/STF/AFR dan seluruh switch (BAS/SSS/SSW/POM/FAN/GGV) diperbarui ~5× lebih sering daripada RPM/TPS/ECT.
- Setiap `datXX` memanggil `SendCommand` tanpa memeriksa nilai balik (`bool` diabaikan), sehingga timeout tidak terdeteksi oleh pemanggil.
- Penanda timeout: `if (array9[1] == 0x05) { tekXX = false; return; }` — lihat §4.

## 4. Nilai basi saat timeout (A)

Setiap parser memeriksa `array9[1]` (panjang balasan). Jika `0x05`, perintah berikutnya mematikan polling (`tekXX=false`) dan **return tanpa mengosongkan nilai**. Karena `array9` adalah `new byte[256]` lokal per panggilan, buffer yang tidak terisi tetap nol, tetapi variabel tampilan tidak diperbarui → nilai lama tetap tampil. Tidak ada penanda "invalid"/"timeout" di UI (A untuk kode; B untuk perilaku).

## 5. Peta balasan

| Dat | Baris permintaan | Balasan (byte) | Sumber |
|---|---|---|---|
| dat10 | 563 `72 05 71 10 08` | `[1]=0x05` deteksi; data mulai `[4]` | A |
| dat11 | 806 `72 05 71 11 07` | `iac = array9[22]/10000f` (841) dihitung tetapi **tidak dikirim** ke `UpdateGridView` (0x11) | A |
| dat13 | 861 `72 05 71 13 05` | bat `[14]/10`, inj `[15..16]/200`, adv `[17]/2-64`, vss=0 | A |
| dat16 | 912 `72 05 71 16 02` | AP/TP `[6..13]`, cor `[14]`, ECT `[15..16]`, IAT `[17..18]`, MAP `[19..20]`, bat `[21]/10`, vss `[22]`, inj `[23]/200`, adv `[24]/2-64` | A |
| dat17 | 973 `72 05 71 17 01` | ECT `[12]` fallback `[8]`, bat `[14]/10`, inj `[15..16]/200`, adv `[17]/2-64`, MD `[18]`, vss `[19]` | A |
| dat20 | 717 `72 05 71 20 F8` | o2/stf/o2v/afr dari `[4..5]` | A |
| datD1 | 629 `72 05 71 D1 47` | switch dari `[4]`, `[8]`, `[9]` | A |

## 6. Formula dat20 (A)

`Diag.cs:717–760`

```
o2  = (BitConverter.ToUInt16(array9,4) & 0xFFFF) / 13.142708f / 1000
stf = (array9[5] & 0xFF) / 128.25651f          // HANYA b[5]
o2v = (array9[4] & 0xFF) / 50.9937f
afr = (float)((-5.351 * o2v) + 17.7f)
```

Alternatif yang dikomentari di source (bukan yang dipakai): `o2v = b4/195.195195`, `afr = stf*14.76`.

Penting: `o2` memakai 16-bit `b4..b5`, sedangkan `stf` hanya `b[5]` dan `o2v` hanya `b[4]`. Ini konsisten dengan permintaan work order untuk memvalidasi STF memakai `b[5]` saja (A).

## 7. Setiap kali balasan dianggap "normal"

Tidak ada pemeriksaan status/checksum di level parser. `SendCommand` memvalidasi checksum, tetapi bila gagal hasilnya hanya timeout; parser tetap membaca `array9` (yang masih nol). Nilai 0 kemudian tampil sebagai nilai nyata (mis. RPM 0, ECT -40 dari `0-40`) (B).

## 8. Yang belum diketahui (D/E)

- Apakah ECU nyata menggemakan perintah (E).
- Apakah `array9[2]` dapat berubah pada model ECU tertentu; dari kode selalu 0x71 (B).
- Frekuensi polling efektif pada perangkat nyata (E).
- Apakah `Task.Delay` tanpa await memang disengaja; tidak ada komentar (D).
