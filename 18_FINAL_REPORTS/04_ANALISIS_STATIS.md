# 04 — ANALISIS STATIS

**Work order:** BE-12
**Status:** RUNTIME VERIFIED (metadata) · IL/algoritma **BLOCKED**
**Sumber:** `02_STATIC_ANALYSIS/METADATA_EXTRACTION.md`, `UPDATER_AND_FEED.md`, `PROTECTION_OVERVIEW.md`, `STRING_CATALOG.md`

---

## 1. Masalah statis

Payload 33,3 MB ber-Enigma tidak memperlihatkan signature `BSJB` maupun string UI di disk. dnSpy/ILSpy pada file gagal. Enigma mendekripsi metadata/IL saat runtime, lalu menyerahkannya ke CLR. Karena itu analisis statis murni tidak cukup; dipakai **pembacaan metadata dari proses hidup**.

## 2. Metode yang dipakai

1. Jalankan **salinan kerja** payload, non-elevated, tanpa argumen.
2. Berhenti di `MbActivationForm` (CLR sudah memuat metadata).
3. `ClrProbe` (.NET 8 + ClrMD 4.2.751201) attach **read-only**:
   - enumerasi module/appdomain;
   - baca blok metadata dari `ClrModule.MetadataAddress`;
   - validasi `BSJB`;
   - simpan 235.832 B (`SHA-256 d48e216a…88a37`);
   - parse offline dengan `System.Reflection.Metadata`.
4. Turunkan `TYPE_MAP.tsv`, `METHODS_BY_TYPE.tsv`, `FIELDS.tsv`, `MEMBERREFS.txt`, `TYPEREFS.txt`, `MANIFEST_RESOURCES.txt`, dan 2.082 string `#US`.

Tidak ada injeksi, patch, dump IL paksa, atau bypass lisensi.

## 3. Hasil kuantitatif

| Artefak | Jumlah |
|---|---:|
| Tipe | 168 |
| Baris metode | 1.442 |
| Field | 1.429 |
| String `#US` | 2.082 |
| Metadata | 235.832 B |
| Assembly | `FLASHPRO` 0.0.1.6, SHA-1 |

Konsistensi silang: versi metadata = VERSIONINFO payload = `0.0.1.6`; string UI cocok dengan build `Team Tech Tunner`.

## 4. Yang tidak diperoleh

**Bytecode IL tidak dapat diambil.** `ClrMethod.GetILInfo()` mengembalikan `Address=0` untuk seluruh metode assembly ini. Konsekuensinya:

- checksum, seed/key, dan rumus volt→nilai hanya diketahui **namanya**;
- urutan pemanggilan tidak dapat dipastikan dari IL;
- klaim "algoritma FLASHPRO sama dengan X" tidak boleh dibuat.

Metadata hanya mencakup tipe yang sudah dimuat; tipe lain tetap ada di tabel, tetapi nilai runtime-nya bisa belum terisi.

## 5. Proteksi & anti-analisis

| Lapisan | Detail |
|---|---|
| Wrapper VB6 | stub 122.880 B, overlay payload, `requireAdministrator` |
| Packer | Enigma Protector 5.x, 5 seksi (4 RWX), entropi 7,9998/7,9991/7,8843 |
| Enkripsi .NET | metadata/IL terenkripsi at-rest |
| Anti-debug | `AntiDebugging`, `CheckForDebugger` |

Enigma melindungi **at-rest**, tetapi harus menyerahkan metadata plaintext ke CLR. Itulah celah metodologis yang dipakai — tanpa membongkar proteksi.

## 6. Updater & feed

Feed tetap:

```
https://raw.githubusercontent.com/flashpro2025/hondaflashprokline/refs/heads/main/hondaflashprokline.json
```

Respons live (2026-11-18): versi **0.0.1.8**, `zipUrl` release `update.zip`, notes `Update - SAVE MODE`. Terpasang 0.0.1.6 → update ditawarkan.

Alur: unduh JSON → bandingkan versi → unduh ZIP (tolak HTML/oversize) → ekstrak berpassword ke `staging/` (tolak path traversal) → jalankan `Auto Update.exe` dengan `runas`.

| Fakta | Konsekuensi keamanan |
|---|---|
| JSON tanpa signature/hash | integritas bergantung HTTPS + kontrol repo |
| ZIP berpassword, password tertanam | obfuscation, bukan PKI |
| Updater `runas` | eksekusi dengan hak administrator |

Ini karakteristik desain, bukan bukti eksploitasi.

## 7. String: yang ada dan yang tidak ada

Ada: `ECM MANAGER`, `TEAM TECH TUNNER`, pesan flash/recovery, 160 nama BIN, 157 part code, 37 DTC, label smartkey, URL updater, registry lisensi.

Tidak ada: `System.IO.Ports`/`SerialPort`, `CAN`, `ELM327`, `J2534`, `UDS`, `KWP2000`, frame contoh, seed/key literal, atau tabel checksum. Tidak ada URL selain feed update → **tidak ada telemetri/aktivasi online**.

## 8. Batas

- Semua algoritma: **NOT VERIFIED**.
- Enigma versi persis tidak dapat dibuktikan dari header (hanya pola seksi/taggant).
- Tidak ada percobaan unpacking paksa.
- `Auto Update.exe` tidak dijalankan → **NOT TESTED**.
