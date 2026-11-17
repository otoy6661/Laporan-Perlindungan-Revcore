# 05 — ANALISIS RUNTIME

**Work order:** BE-12
**Status:** RUNTIME VERIFIED (E01) · E02/E03 **NOT TESTED** (alasan di §5)
**Sumber:** `03_RUNTIME_ANALYSIS/RUNTIME_ANALYSIS.md`, `12_EXPERIMENTS/E01_FIRST_LAUNCH/`

---

## 1. Desain E01

| Aspek | Nilai |
|---|---|
| Target | salinan kerja payload (`FLASHPRO_original.exe`, sha `9fafdc8e…`) |
| Elevasi | tidak |
| Argumen | tidak ada |
| Durasi | 2026-11-17 18:49:43 → 18:50:33 UTC |
| Observasi | PID, jendela, modul, file, jaringan, UIA, hash |
| Hasil | berhenti di gerbang aktivasi; Cancel → keluar |

## 2. Hasil

- Jendela **460×400**, `ECM MANAGER - Activation`, `TEAM TECH TUNNER`.
- PID **53624**, **67 modul**.
- CLR 4.8: `clr.dll`, `mscoree.dll`, `mscorlib.ni`, `System.ni`, `System.Core.ni`, `System.Windows.Forms.ni`, `System.Drawing.ni`, `System.Management.ni`, `System.Xml.ni`.
- WMI dimuat (`wbemprox`, `wbemcomn`, `wmiutils`, `fastprox`) → konsisten dengan pembacaan serial motherboard.
- Tidak ada `ws2_32`/`wininet`/`winhttp`; `Get-NetTCPConnection` untuk PID kosong → **tidak ada koneksi**.
- UI Automation membaca label/edit/Copy/Cancel/Activate; tombol custom-drawn tidak merespons `InvokePattern`; klik fisik menutup dialog.
- Hash `FLASHPRO_original.exe`, `DotNetZip.dll`, `lastimage.txt` **identik sebelum/sesudah**.
- Tidak ada file baru di folder APP; perubahan TEMP/Roaming/Local milik proses lain (Qoder/Chrome/D3D).

## 3. Bukti negatif yang berguna

| Tidak dimuat | Implikasi |
|---|---|
| `System.IO.Ports` | bukan serial port |
| `ws2_32`/`wininet`/`winhttp` | tidak ada jaringan saat start |
| `sensapi`/`setupapi` | tidak ada deteksi perangkat via API Windows |
| `hid.dll`/`bthprops` | bukan HID/Bluetooth |

## 4. Interpretasi

Gerbang aktivasi adalah pemeriksaan **lokal** (WMI + registry + RSA), bukan panggilan server. Ini konsisten dengan arsitektur lisensi offline. Tidak ada bukti telemetri.

E01 juga membuktikan tiga hal yang sering diasumsikan salah:

1. payload **adalah** .NET (CLR + metadata);
2. aplikasi **tidak** "menelepon rumah" saat start;
3. lisensi adalah lapisan pertama, bukan fitur belakangan.

## 5. E02/E03 tidak dijalankan

| Rencana | Alasan |
|---|---|
| E02: jalankan wrapper terpasang | manifest `requireAdministrator` → UAC interaktif; wrapper mengekstrak/menjalankan payload dan berpotensi menulis ke lokasi tak diketahui; tanpa isolasi/elevasi yang disetujui, tidak aman dan tidak dapat diotomasi |
| E03: `Auto Update.exe` | butuh elevasi (`runas`) dan mengunduh/mengeksekusi paket pihak ketiga; di luar batas "jangan menjalankan executable yang belum diperiksa" |
| E04: aktivasi sah | tidak ada lisensi; membuat/menebak kunci dilarang |

Konsekuensi: perilaku **setelah** aktivasi tidak pernah diamati. Semua dokumen FASE II memakai **SOURCE VERIFIED**, bukan RUNTIME VERIFIED.

## 6. Preservasi

- Instalasi asli tidak disentuh; eksperimen memakai salinan.
- Tidak ada penulisan ECU, instalasi driver, atau perubahan registry.
- Artefak: `E01_OBSERVATION.txt`, `E01_WINDOW.png`, `E01_ACTIVATION_UI_TREE.txt`, `CLR_DUMP/`, `HASHES_BEFORE/AFTER.txt`.

## 7. Nilai dan batas

E01 cukup untuk memetakan startup, dependensi runtime, dan sifat lisensi. E01 **tidak** cukup untuk menyimpulkan apa pun tentang ECU, live data, BIN, checksum, atau flashing. Semua area itu tetap bergantung pada metadata/string dan karena itu berstatus lebih rendah.
