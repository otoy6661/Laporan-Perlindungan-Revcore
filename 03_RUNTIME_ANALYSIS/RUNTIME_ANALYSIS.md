# Analisis Runtime Terkendali — E01 (+ status E02/E03)

**Status:** RUNTIME VERIFIED (E01) · E02/E03 **NOT TESTED** (alasan di §5).

---

## 1. Desain eksperimen E01

| Aspek | Nilai |
|---|---|
| Target | **Salinan kerja** payload (`12_EXPERIMENTS/E01_FIRST_LAUNCH/APP/FLASHPRO_original.exe`, sha `9fafdc8e…`) |
| Elevasi | Tidak (sesi pengguna biasa) |
| Argumen | Tidak ada (payload langsung, bukan wrapper) |
| Durasi | 2026-11-17 18:49:43 → 18:50:33 UTC |
| Observasi | PID, jendela, modul, perubahan file (APP/TEMP/Roaming/Local), screenshot, UIA tree, hash sebelum/sesudah |
| Hasil | Berhenti di gerbang aktivasi; Cancel → proses keluar |

## 2. Hasil

- **Jendela:** 460×400, judul kosong (custom-drawn), isi `ECM MANAGER - Activation`, `TEAM TECH TUNNER`.
- **PID:** 53624; 67 modul.
- **CLR:** `clr.dll`, `mscoree.dll`, `mscorlib.ni`, `System.ni`, `System.Core.ni`, `System.Windows.Forms.ni`, `System.Drawing.ni`, `System.Management.ni`, `System.Xml.ni` → aplikasi .NET Framework 4.8 WinForms.
- **WMI:** `wbemprox/wbemcomn/wmiutils/fastprox` dimuat → aktivasi membaca WMI (konsisten dengan `SELECT SerialNumber FROM Win32_BaseBoard`).
- **Jaringan:** tidak ada `ws2_32.dll`/`wininet`/`winhttp` dimuat, dan `Get-NetTCPConnection` untuk PID kosong → tidak ada koneksi saat gerbang aktivasi.
- **UI Automation:** kontrol terbaca (judul, label, edit ID, Copy, Cancel, Activate). Tombol custom-drawn tidak merespons `InvokePattern`; klik fisik berhasil menutup dialog.
- **File:** hash `FLASHPRO_original.exe`, `DotNetZip.dll`, `lastimage.txt` **identik sebelum/sesudah** (`HASHES_BEFORE.txt` vs `HASHES_AFTER.txt`). Tidak ada file baru di folder APP.
- **TEMP/Roaming/Local:** perubahan yang tercatat milik Qoder/Chrome/D3D, bukan aplikasi (tidak ada nama file FLASHPRO).

## 3. Yang tidak ditemukan (modul runtime / typeref) — bukti negatif berguna

| Tidak dimuat | Implikasi |
|---|---|
| `System.IO.Ports` | bukan serial port |
| `ws2_32`, `wininet`, `winhttp` | tidak ada jaringan saat start |
| `sensapi`, `setupapi` | tidak ada deteksi perangkat via API Windows |
| `hid.dll`, `bthprops` | bukan HID/Bluetooth |

## 4. Interpretasi

Gerbang aktivasi adalah **pemeriksaan lokal** (WMI + registry + RSA), bukan panggilan server. Ini konsisten dengan arsitektur lisensi offline di `11_LICENSE_ARCHITECTURE`. Tidak ada bukti telemetri.

## 5. E02/E03 — tidak dijalankan (jujur)

| Rencana | Alasan tidak dijalankan |
|---|---|
| E02: jalankan wrapper terpasang untuk melihat handoff | Manifest `requireAdministrator` → butuh UAC interaktif; wrapper mengekstrak/menjalankan payload dan berpotensi menulis ke lokasi tak diketahui. Tanpa lingkungan terisolasi dan persetujuan elevasi, eksperimen ini tidak aman dan tidak dapat diotomasi. |
| E03: jalankan `Auto Update.exe` / updater | Butuh elevasi (`runas`) dan mengunduh/mengeksekusi paket pihak ketiga. Di luar batas "jangan menjalankan executable yang belum diperiksa". |
| E04: aktivasi sah | Tidak ada lisensi; membuat/menebak kunci dilarang. |

Konsekuensi: perilaku **setelah** aktivasi tidak pernah diamati langsung. Semua dokumen FASE II karena itu memakai status SOURCE VERIFIED, bukan RUNTIME VERIFIED.

## 6. Preservasi

- Instalasi asli tidak disentuh; semua eksperimen memakai salinan.
- Tidak ada penulisan ke ECU, tidak ada instalasi driver, tidak ada perubahan registry.
- Artefak: `E01_OBSERVATION.txt`, `E01_WINDOW.png`, `E01_ACTIVATION_UI_TREE.txt`, `CLR_DUMP/`, `HASHES_BEFORE/AFTER.txt`.

## 7. Nilai bukti E01

E01 membuktikan tiga hal yang sering salah diasumsikan:
1. Payload **adalah** .NET (bukan native penuh) — dibuktikan CLR + metadata.
2. Aplikasi **tidak** "menelepon rumah" saat start.
3. Gerbang lisensi adalah lapisan pertama, bukan fitur belakangan; tanpa itu, seluruh kemampuan ECU tidak dapat diuji.
