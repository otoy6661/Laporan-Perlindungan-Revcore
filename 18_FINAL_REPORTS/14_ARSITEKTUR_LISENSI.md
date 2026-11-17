# 14 — ARSITEKTUR LISENSI

**Work order:** BE-12
**Status:** SOURCE VERIFIED (mekanisme) + RUNTIME VERIFIED (gerbang muncul) · tidak ada bypass
**Sumber:** `11_LICENSE_ARCHITECTURE/LICENSE_ARCHITECTURE.md`

---

## 1. Dua lapis gerbang

| Lapis | Kelas | Basis | Kapan |
|---|---|---|---|
| Aktivasi awal | `MbActivationForm` + `MbAuth` | serial motherboard (WMI `Win32_BaseBoard.SerialNumber`, fallback `UNKNOWN_MB`) + nama bengkel | sebelum UI utama |
| Lisensi | `LicenseForm` + `IsLicenseValid`/`LoadLicenseDual` | HWID gabungan CPU + BIOS + disk | saat start/fitur tertentu |

`MbAuth` memakai salt (disamarkan) + registry `HKCU\Software\Win32Sub\SystemCtrl` (`SysCFG`) dan `SystemApp`; nilai tersimpan `MbAct`, `MbBeng`.

`LicenseForm` menghitung HWID dari:

```
Win32_Processor.ProcessorId
Win32_BIOS.SerialNumber
Win32_DiskDrive
→ SHA256 → ID lisensi
```

Alur pengguna: copy ID → hubungi admin (WhatsApp, nomor disamarkan) → masukkan License Key → Register.

## 2. Verifikasi kriptografis

- `PublicKeyDecryptor` (2 metode) — pola **RSA verify**; kunci publik tertanam, tidak ada private key di aplikasi.
- `AntiDebugging` + `CheckForDebugger`.
- `SHA256` untuk HWID.
- Registry `HKCU\SOFTWARE\SHINDENGEN & KEIHIN HONDA ECM` menyimpan `Key` **180 byte**, entropy 6,97 — blob terenkripsi/bertanda tangan. **SENSITIVE_OR_RESTRICTED**.

Kesimpulan: lisensi **offline**, terikat perangkat, diverifikasi lokal. Tidak ada server aktivasi; satu-satunya koneksi keluar adalah feed update.

## 3. Konsekuensi desain (netral)

| Konsekuensi | Dampak |
|---|---|
| Offline | aktivasi manual, tanpa internet |
| Hardware-bound | ganti motherboard/CPU/disk → aktivasi ulang |
| Verifikasi lokal | kekuatan bergantung obfuscation + anti-debug; tidak ada revocation |
| Tanpa server | tidak ada pencabutan/telemetri |
| Manual | bergantung respons admin |

## 4. Perilaku saat tidak valid

- `Lisensi tidak valid ! Silahkan Hubungi pengembang.`
- `Activation Key tidak valid`, `Masukkan Activation Key!`, `Exiting.`
- E01: menutup dialog aktivasi → proses keluar bersih tanpa menulis file.

## 5. Yang tidak dianalisis

- Nilai salt, kunci AES, dan isi blob 180 byte tidak direproduksi.
- Tidak ada percobaan menebak/membuat Activation Key.
- Tidak ada patch, dump memori lisensi, atau perubahan registry.
- Klaim "aman" atau "mudah dibobol" **tidak dibuat**.

## 6. Perbandingan dengan RevCore

RevCore tidak memiliki lisensi komersial; APK berjalan tanpa gerbang aktivasi. FLASHPRO membatasi akses sejak start. Ini perbedaan model bisnis, bukan kualitas teknis ECU. Bagi RevCore, lisensi hardware-bound tidak perlu ditiru; yang relevan adalah **pemisahan gerbang** dan **verifikasi lokal** sebagai konsep, bukan implementasinya.
