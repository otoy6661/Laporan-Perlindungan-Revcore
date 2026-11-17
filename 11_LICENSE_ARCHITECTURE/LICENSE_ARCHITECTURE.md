# Arsitektur Lisensi — Analisis Struktur (tanpa bypass)

**Status:** SOURCE VERIFIED (mekanisme & lokasi) · RUNTIME VERIFIED (gerbang aktivasi muncul; tidak diaktifkan).
**Batas:** dokumen ini **tidak** memuat kunci, salt, algoritma pembangkit kunci, atau langkah melewati lisensi. Tidak ada crack/keygen/bypass yang dibuat atau diuji.

---

## 1. Dua lapis gerbang

| Lapis | Kelas | Basis | Kapan |
|---|---|---|---|
| Aktivasi awal | `MbActivationForm` + `MbAuth` | **serial motherboard** (WMI `Win32_BaseBoard.SerialNumber`, fallback `UNKNOWN_MB`) + nama bengkel | sebelum UI utama |
| Lisensi | `LicenseForm` + `Form1.IsLicenseValid/LoadLicenseDual` | **HWID gabungan** CPU + BIOS + disk | saat start / fitur tertentu |

`MbAuth` memakai salt (disamarkan di evidence) + registry `HKCU\Software\Win32Sub\SystemCtrl` (`SysCFG`) dan `SystemApp`. Nilai tersimpan `MbAct`, `MbBeng`.

`LicenseForm` menghitung HWID dari:

```
Win32_Processor.ProcessorId
Win32_BIOS.SerialNumber
Win32_DiskDrive
```

lalu `SHA256` → ID lisensi yang ditampilkan/di-copy. Alur pengguna: copy ID → hubungi admin via WhatsApp (`wa.me`, nomor disamarkan) → masukkan License Key → `Register`.

## 2. Verifikasi kriptografis

- `PublicKeyDecryptor` (2 metode, 2 field) — pola **RSA verify** (kunci publik tertanam; tidak ada private key di aplikasi).
- `AntiDebugging` + `CheckForDebugger` — deteksi debugger.
- `SHA256` untuk hash HWID.
- Registry `HKCU\SOFTWARE\SHINDENGEN & KEIHIN HONDA ECM` menyimpan nilai biner `Key` **180 byte** dengan entropy 6,97 — blob terenkripsi/bertanda tangan, bukan teks. **SENSITIVE_OR_RESTRICTED**.

Kesimpulan arsitektural: lisensi **offline**, terikat perangkat, diverifikasi lokal dengan kunci publik. Tidak ada server aktivasi; satu-satunya koneksi keluar adalah feed update.

## 3. Konsekuensi desain (netral)

| Konsekuensi | Dampak |
|---|---|
| Offline | Pengguna tanpa internet tetap bisa aktivasi (manual) |
| Hardware-bound | Ganti motherboard/CPU/disk → aktivasi ulang |
| Verifikasi lokal | Kekuatan proteksi bergantung pada obfuscation + anti-debug; tidak ada revocation |
| Tanpa server | Tidak ada pencabutan lisensi, tidak ada telemetri penggunaan |
| Manual | Aktivasi bergantung pada respons admin (WhatsApp) |

## 4. Perilaku saat tidak valid

- `Lisensi tidak valid ! Silahkan Hubungi pengembang.` / `Lisensi tidak valid. Silahkan hubungi pengembang.`
- `Activation Key tidak valid`, `Masukkan Activation Key!`, `Exiting.`
- Pada E01, menutup dialog aktivasi membuat proses keluar bersih tanpa menulis file.

## 5. Yang tidak dianalisis

- Nilai salt, kunci AES, dan isi blob 180 byte tidak direproduksi.
- Tidak ada percobaan menebak/membuat Activation Key.
- Tidak ada patch, dump memori lisensi, atau perubahan registry.
- Klaim "aman" atau "mudah dibobol" **tidak dibuat** — keduanya butuh pengujian ofensif yang dilarang work order.

## 6. Perbandingan dengan RevCore (fakta, bukan penilaian)

RevCore tidak memiliki lisensi komersial; APK berjalan tanpa gerbang aktivasi. FLASHPRO membatasi akses fitur sejak start. Ini perbedaan model bisnis, bukan perbedaan kualitas teknis ECU. Detail ada di laporan 14/16.
