# 07 — AUTOPSI XDF

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Sampel:** `30400-k1aa-n03.xdf`, `SUPRA-K41NC1.xdf`, `CBR1000RR.xdf`, `ADV 150 -- 30400-K0WA-N01.xdf` (terenkripsi)
**Status:** SELESAI — struktur XML, model objek, alamat/stride, checksum, dan container terenkripsi dianalisis dari file nyata dan perilaku runtime.

---

## 1. Populasi XDF

| Kategori | Jumlah | Bukti |
|---|---:|---|
| Total XDF | 174 | `DATASET_INVENTORY.csv` |
| Plaintext (XML) | 13 | Magic `3C 21 2D 2D` (`<!--`) |
| Terenkripsi | 161 | Magic `05 22 97 00` |
| XDF dengan checksum | 2 dari 13 plaintext | SUPRA K41-NC1, CBR1000RR MGP-A01 |
| XDF tanpa checksum | 11 dari 13 plaintext | — |

13 file plaintext mencakup 12 definisi unik (XDF SPECIAL RACE K2VG-N32 ada dua salinan).

**Implikasi:** 92,5% definisi dalam dataset tidak dapat dibaca tanpa dekripsi. Analisis format karena itu bertumpu pada 13 file plaintext + perilaku editor terhadap file terenkripsi.

---

## 2. Struktur XDF plaintext

Contoh header nyata (`30400-k1aa-n03.xdf`):

```xml
<!-- Written 10/10/2023 23:34:25 -->
<XDFFORMAT version="1.70">
  <XDFHEADER>
    <flags>0x1</flags>
    <deftitle>BEAT 110 ESP K1AA-N03</deftitle>
    <author>dedot</author>
    <BASEOFFSET offset="0" subtract="0" />
    <DEFAULTS datasizeinbits="8" sigdigits="2" outputtype="1" signed="0" lsbfirst="0" float="0" />
    <REGION type="0xFFFFFFFF" startaddress="0x0" size="0x3FFF0" ... />
    <CATEGORY index="0x0" name="BEAT ESP 110 -K1AAN 03 DEDOT TECH" />
    ...
  </XDFHEADER>
  <XDFTABLE uniqueid="0x50A" flags="0x0">
    <title>TPS vs RPM Fast Idle #1</title>
    ...
  </XDFTABLE>
</XDFFORMAT>
```

### 2.1 Elemen tingkat atas

| Elemen | Fungsi (terbukti dari isi/atribut) |
|---|---|
| `XDFFORMAT version` | Versi skema; sampel = `1.70` |
| `XDFHEADER` | Metadata: `flags`, `deftitle`, `description`, `author` |
| `BASEOFFSET` | Offset dasar dan `subtract` untuk semua alamat |
| `DEFAULTS` | Default lebar data, digit signifikan, output type, signed, `lsbfirst`, float |
| `REGION` | Rentang file yang diedit (contoh `0x0`..`0x3FFF0`) |
| `CATEGORY` | Kategori tampilan pohon parameter |
| `XDFTABLE` | Tabel 1D/2D/3D |
| `XDFCONSTANT` | Nilai tunggal |
| `XDFFLAG` | Nilai bit/boolean |
| `XDFFUNCTION` | Fungsi/ekspresi |
| `XDFPATCH` | Patch byte |
| `XDFCHECKSUM` | Definisi checksum |

Token lengkap juga muncul di string `XDFEditor.dll`: `XDFTABLE`, `XDFAXIS`, `XDFCONSTANT`, `XDFFLAG`, `XDFFUNCTION`, `XDFPATCH`, `XDFCHECKSUM`, `EMBEDDEDDATA`.

### 2.2 `XDFAXIS` dan `EMBEDDEDDATA`

Setiap tabel memiliki axis `x`, `y`, dan `z` (z = data; x/y = breakpoint). Contoh nyata:

```xml
<XDFAXIS id="x">
  <EMBEDDEDDATA mmedaddress="0x39BFE" mmedelementsizebits="8"
                mmedmajorstridebits="-32" mmedminorstridebits="0" />
  <indexcount>29</indexcount>
  <MATH equation="X"><VAR id="X" /></MATH>
</XDFAXIS>
<XDFAXIS id="z">
  <EMBEDDEDDATA mmedtypeflags="0x02" mmedaddress="0x3815E"
                mmedelementsizebits="16" mmedrowcount="35" mmedcolcount="29"
                mmedmajorstridebits="0" mmedminorstridebits="0" />
  <min>0.000000</min><max>5000.000000</max>
  <outputtype>1</outputtype>
</XDFAXIS>
```

**Aturan alamat yang terbukti:**
- Alamat absolut = `BASEOFFSET + mmedaddress` (pada sampel base 0).
- `mmedelementsizebits` menentukan lebar sel (8/16 bit).
- `mmedmajorstridebits="-32"` dengan elemen 8-bit berarti langkah **4 byte ke belakang** per indeks (32 bit = 4 byte, tanda negatif = mundur). Ini menjelaskan mengapa breakpoint TPS/RPM berada di alamat yang lebih tinggi daripada tabel data dan dibaca menurun.
- `mmedrowcount`/`mmedcolcount` menentukan dimensi; `mmedmajorstridebits=0` pada z berarti layout kontinu (row-major) untuk sampel ini.
- Tidak ada header per sel; semua offset eksplisit.

### 2.3 MATH dan output type

Sampel K1AA memuat 55 ekspresi `X` (identitas), 2 ekspresi `X*1000`, serta `X/9.72`, `X/9.5`, dan `X/10` pada tabel tertentu. `outputtype` yang teramati: `1` (numerik), `3` (hex), `4` (teks). Ini menjelaskan mengapa SW Version tampil sebagai string dan ECM ID sebagai hex.

### 2.4 Cakupan tabel per XDF plaintext

| XDF | Jumlah objek | Checksum |
|---|---:|---|
| ADV 150 K0WF-T01 | 44 | — |
| BEAT 30400-K1AA-N03 | 20 | — |
| BEAT POP K61-601 | 13 | — |
| CBR150 38770 K45A N01 | 24 | — |
| CBR500R MGZ-A03 | 19 | — |
| CBR500R MGZ-C02 | 19 | — |
| CBR1000RR MGP-A01 | 39 | 1 |
| SUPRA X 125 K41-NC1 | 14 | 1 |
| Supra 125 Old KVL-N21 | 19 | — |
| VARIO 150 K59A-A11 Ind | 20 | — |
| XDF SPECIAL RACE K2VG-N32 (2 salinan) | 20 | — |
| VERZA-150 K18-902 | 16 | — |

---

## 3. Model checksum XDF

Blok checksum berisi region bersarang:

```xml
<XDFCHECKSUM uniqueid="0x1AA5">
  <title>asia_online_shop_38770-K41-NC1</title>
  <REGION>
    <datastart>0xFFF0</datastart>
    <dataend>0xFFF0</dataend>
    <storesizebits>0x8</storesizebits>
    <storeaddress>0xFFF1</storeaddress>
    <calculationmethod>0x0</calculationmethod>
  </REGION>
</XDFCHECKSUM>
```

| Field | Arti |
|---|---|
| `datastart`/`dataend` | Rentang byte yang dijumlahkan |
| `storesizebits` | Lebar nilai checksum (8/16 bit) |
| `storeaddress` | Lokasi penyimpanan |
| `calculationmethod` | Metode; `0` = SUM |
| `pluginmoduleid` | GUID plug-in yang wajib tersedia (opsional) |

Dua kasus:

1. **SUPRA K41-NC1** — region 1 byte (`0xFFF0`), simpan di `0xFFF1`, metode 0, tanpa plug-in. TunerPro dapat menghitung sendiri; Save berhasil.
2. **CBR1000RR MGP-A01** — region 0..`0x3FFFF`, simpan di `0x3FFF8`, metode 0, tetapi `pluginmoduleid = 49524f4e-504f-4e59-524b-000000000000` (`IRON-PONY-RK`). Plug-in tidak terpasang → Save As gagal.

**Kesimpulan:** XDF checksum adalah deklarasi data, bukan algoritma universal. Perilaku aktual bergantung pada ketersediaan plug-in yang dirujuk. Ini penting untuk RevCore: membaca `XDFCHECKSUM` saja tidak cukup; harus ada registry plug-in dan fallback yang eksplisit.

Nilai `0xEF` pada CBR adalah komplemen dua dari jumlah seluruh byte lain; `0xFF` pada SUPRA adalah komplemen dua dari satu byte region. Keduanya konsisten dengan "SUM" dua-komplemen, bukan CRC.

---

## 4. Container XDF terenkripsi

| Properti | Nilai teramati |
|---|---|
| Magic | `05 22 97 00` |
| Marker | Byte `0x83` = `0x64` |
| Awal ciphertext | `0x84` (132) |
| Header terbaca | 132 byte; seluruhnya nol kecuali magic dan marker |
| Nama file/tipe di header | Tidak ada (0 string ASCII) |
| Ukuran contoh | `ADV 150 -- 30400-K0WA-N01.xdf` = 40.088 B |
| Entropy keseluruhan | 7,9937 |
| Entropy setelah 132 B | 7,9954 |
| Panjang ciphertext | size − 132 |

Entropy ~7,99 menunjukkan ciphertext terkompresi/enkripsi penuh; tidak ada pola XML yang tersisa. Container yang sama dipakai ADX (magic identik), sehingga format container bersifat umum untuk definisi.

### 4.1 Perilaku runtime

- XDF terenkripsi **dapat dibuka** TunerPro dan diretribusikan ke UI.
- Pohon parameter hanya menampilkan `Scalars > [ Kompatible Ecu : K0WA ]`; objek internal tidak diekspos.
- Editor menyediakan `Encrypt File`, `Open Password`, `Edit Password` (string XDFEditor), menunjukkan enkripsi berbasis password.
- Tidak ada upaya menebak password atau mendekripsi container dalam BE-11.

### 4.2 Implikasi

- Definisi terenkripsi adalah **fitur distribusi**, bukan kerusakan file.
- Tanpa kunci, isi 161 XDF tidak dapat diaudit; klaim tentang tabel di dalamnya harus ditolak.
- RevCore tidak boleh mengklaim kompatibel dengan XDF terenkripsi tanpa jalur dekripsi yang sah.

---

## 5. Hubungan XDF ↔ BIN

1. XDF menunjuk alamat absolut di BIN; tidak ada validasi ukuran BIN terhadap `REGION` saat load (terbukti: XDF 256 KB dapat dipasangkan ke BIN 64 KB tanpa peringatan langsung; tabel di luar ukuran akan gagal saat dibaca).
2. XDF menentukan endianness per sel; sampel Honda memakai big-endian untuk 16-bit.
3. XDF menentukan checksum; BIN tidak menyimpan metadata checksum.
4. XDF dapat menyimpan `DALINK`/`objidhash` untuk menautkan parameter ke ADX, tetapi tautan tidak divalidasi ketat saat load.

---

## 6. Batas autopsi XDF

- 161 XDF terenkripsi tidak didekripsi.
- Tidak ada dokumentasi resmi skema XDF 1.70; semantik field disimpulkan dari nama tag, nilai nyata, dan perilaku editor. Field yang tidak muncul di sampel tidak diklaim.
- Tidak diuji XDF dengan `XDFCONSTANT`, `XDFFLAG`, `XDFFUNCTION`, atau `XDFPATCH` (sampel plaintext tidak memuatnya, kecuali yang tersembunyi).
- Tidak diuji file XDF yang rusak/terpotong selain kasus checksum.

---

## 7. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Struktur XML & elemen utama | TINGGI (file nyata) |
| Alamat, dimensi, endianness | TINGGI (verifikasi silang 5.338 sel) |
| Aturan stride negatif | TINGGI untuk sampel; SEDANG untuk generalisasi |
| Model checksum | TINGGI (dua kasus + uji kausal) |
| Container terenkripsi | TINGGI untuk header; RENDAH untuk isi |
| Semantik seluruh field skema | SEDANG |
