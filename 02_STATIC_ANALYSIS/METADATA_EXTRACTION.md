# Ekstraksi Metadata .NET dari Payload ber-Enigma

**Status:** RUNTIME VERIFIED (metadata) — metode dan hasil dapat direproduksi.
**Tujuan:** mendapatkan struktur internal aplikasi tanpa membongkar proteksi, tanpa menjalankan kode vendor, dan tanpa menyentuh gerbang lisensi.

---

## 1. Masalah

Payload `FLASHPRO.exe` (33.321.984 B, x64, 5 seksi RWX, Enigma Protector 5.x) menyembunyikan assembly .NET:

- di disk **tidak ada** signature `BSJB` (metadata header) maupun string UI seperti `ECM MANAGER` pada payload;
- bytecode IL dienkripsi/dekompresi saat runtime oleh Enigma, lalu diserahkan ke CLR.

Akibatnya alat statis biasa (dnSpy/ILSpy pada file) tidak dapat membaca apa pun. Namun **CLR pasti menerima metadata yang sudah didekripsi**. Itulah celah yang dipakai: membaca apa yang sudah ada di memori proses, bukan menembus proteksi.

## 2. Metode

1. Jalankan **salinan kerja** payload (bukan instalasi), non-elevated — `E01_FIRST_LAUNCH`.
2. Proses berhenti di gerbang aktivasi (`MbActivationForm`). CLR sudah dimuat, metadata sudah tinggal di heap.
3. Alat `ClrProbe` (.NET 8 + `Microsoft.Diagnostics.Runtime` 4.2.751201) attach read-only:
   - enumerasi `ClrAppDomain`/`ClrModule`;
   - baca blok metadata dari `ClrModule.MetadataAddress` (via `DataTarget.DataReader`);
   - validasi signature `BSJB` sebelum disimpan.
4. Blok 235.832 B disimpan sebagai `MOD_1_metadata.bin` (**SHA-256 `d48e216a4c14dacfb73e726da757a6315639fa4ba0f4978f8add62963ed88a37`**), lalu diparse offline dengan `System.Reflection.Metadata`.
5. Turunan: `TYPE_MAP.tsv` (168 tipe), `METHODS_BY_TYPE.tsv` (1.442 baris metode), `FIELDS.tsv` (1.429 field dengan signature), `MEMBERREFS.txt`, `TYPEREFS.txt`, `MANIFEST_RESOURCES.txt`, `ASSEMBLY_IDENTITY.txt`, dan heap `#US` → 2.082 string.

Tidak ada penulisan ke proses target, tidak ada injeksi, tidak ada patch, tidak ada bypass.

## 3. Hasil yang membuktikan keaslian

| Pemeriksaan | Hasil |
|---|---|
| Signature metadata | `BSJB` valid (offset 0) |
| Assembly | `FLASHPRO`, versi `0.0.1.6`, hash alg SHA-1 |
| Konsistensi dengan VERSIONINFO payload | cocok (0.0.1.6, Team Tech Tunner) |
| Payload vs installer | SHA-256 `9fafdc8e795b2809cc02356bb2d4f5e79432fa3f72ab65ff7a8b56039bd02eb3` — identik |
| String UI | `ECM MANAGER`, `TEAM TECH TUNNER`, `Failed challenging Seed/Key`, pesan flash lengkap |
| Modul framework yang dimuat | `System.Windows.Forms.ni`, `System.Management.ni`, `mscorlib.ni`, `clr.dll` (CLR 4.8) |

## 4. Yang TIDAK diperoleh (batas metode ini)

- **Bytecode IL tidak dapat diambil.** `ClrMethod.GetILInfo()` mengembalikan `ILInfo` dengan `Address=0` untuk seluruh metode assembly ini — Enigma men-decode IL tepat saat eksekusi. Semua klaim tentang *algoritma* (checksum, seed/key, rumus live data) karena itu hanya boleh disimpulkan dari **nama metode, konstanta, string, dan perilaku teramati**, bukan dari instruksi.
- Metadata hanya mencakup tipe yang sudah dimuat. Tipe yang tidak pernah disentuh sebelum gerbang aktivasi tetap tersedia di metadata assembly (tabel lengkap), tetapi field yang diinisialisasi runtime bisa belum berisi.
- Nama lokal, komentar, dan atribut sumber tidak ada di metadata — tidak bisa dipulihkan.
- Karena tidak ada IL, **semua algoritma berstatus "nama/konstanta terverifikasi, isi algoritma NOT VERIFIED"**.

## 5. Atribusi proteksi

- Seksi payload RWX, entropi tinggi, entry point kecil, overlay/stub loader → pola Enigma Protector.
- Artefak Enigma lokal (project berisi private key/keygen) **tidak disentuh** sesuai batas kerja; keberadaannya dicatat di `PROVENANCE.md §9` sebagai sensitif.
- Analisis ini tidak mengubah, menyalin, atau mendistribusikan artefak tersebut.

## 6. Reproduksi

```powershell
dotnet run --project tools/ClrProbe -- <pid> <outDir>
# atau offline:
dotnet run --project tools/ClrProbe -- MOD_1_metadata.bin <outDir>
```

Prasyarat: payload berjalan (gerbang aktivasi cukup), sesi tidak perlu elevated, `ClrProbe` dijalankan sebagai user yang sama.
