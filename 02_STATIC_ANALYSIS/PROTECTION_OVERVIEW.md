# Proteksi & Anti-Analisis — Karakterisasi

**Status:** STATIC VERIFIED (dari `PROVENANCE.md` + PE) · RUNTIME VERIFIED (perilaku startup).

---

## 1. Lapisan pelindung

| Lapisan | Detail | Bukti |
|---|---|---|
| Wrapper VB6 | PE32 x86, 3 seksi, 122.880 B, overlay 33 MB, `requireAdministrator`, VERSIONINFO `Project1` | `PROVENANCE.md §4`, `PE/PE_FLASHPRO.exe.json` |
| Packer payload | Enigma Protector 5.x; 5 seksi (4 RWX + `.rsrc`); entropi 7,9998 / 7,9991 / 7,8843 | `PROVENANCE.md` |
| .NET encryption | metadata & IL dienkripsi; `BSJB` tidak ada di disk; string UI tidak terbaca | pencarian `BSJB`/`ECM MANAGER` pada file = 0 hasil |
| Anti-debug | `AntiDebugging`, `CheckForDebugger` di assembly | metadata |

## 2. Efek nyata terhadap analisis

| Analisis | Hasil |
|---|---|
| `strings` pada file | tidak menghasilkan string aplikasi |
| dnSpy/ILSpy pada file | gagal (assembly terenkripsi) |
| Membaca metadata dari proses hidup | **berhasil** (CLR sudah memegang plaintext metadata) |
| Mengambil IL | **gagal** (`GetILInfo` null) |
| Runtime UI setelah aktivasi | **terblokir** lisensi |

Poin penting: Enigma melindungi **at-rest**, tetapi harus menyerahkan metadata ke CLR saat runtime. Itu sebabnya metode "baca memori" berhasil tanpa membongkar proteksi.

## 3. Wrapper sebagai mekanisme tambahan

- Wrapper mengekstrak payload ke memori/berkas lalu mengeksekusinya (stub VB6).
- Payload di dalam wrapper identik dengan file asli dari installer → tidak ada modifikasi biner.
- Wrapper menggantikan EXE asli pada 17 Nov (lihat `PROVENANCE.md` timeline). Ini pola distribusi, bukan indikasi malware; kapabilitas stub (unduh URL, ShellExecute, registry, file I/O) dicatat sebagai kapabilitas statis.

## 4. Anti-debug & lisensi

- `CheckForDebugger`/`AntiDebugging` aktif di assembly.
- Analisis dilakukan **tanpa** debugger (attach ClrMD read-only), sehingga tidak memicu perlawanan yang tidak perlu.
- Tidak ada patch memori, injeksi, atau perubahan proses.

## 5. Keterbatasan yang diakui

- Tidak dapat membuktikan Enigma versi persis dari header (hanya taggant/CRL + pola seksi).
- Tidak dapat membuktikan apakah ada lapisan virtualisasi kode (VM) di dalam Enigma tanpa IL.
- Tidak ada percobaan unpacking paksa; itu di luar batas kerja dan berisiko.
