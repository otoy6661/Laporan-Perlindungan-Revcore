# File Tidak Dapat Dianalisis / Dibatasi

## H-Diag

| File | Alasan | Tindakan |
|---|---|---|
| `login.ini` (141.022 B) | Data lisensi sensitif; berisi daftar kode akses | Hanya ukuran/SHA-256 dicatat; isi tidak dibaca/dipublikasikan |
| `HDiag.exe,` (313.426 B) | Salinan varian dengan tata letak PE berbeda | Ekstraksi string dilakukan; pencarian pointer gagal (`struct.error`) dan tidak diulang |
| `unins000.dat` | Metadata uninstaller | Tidak relevan protokol |
| `usb_driver/*` | Driver pihak ketiga (WinUSB/libusb) | Tidak dianalisis; tidak dipublikasikan |
| Qt5*.dll, ICU, MSVCR110 | Runtime pihak ketiga | Tidak dianalisis |
| Resource PNG tertanam | Aset UI | Tidak diperlukan untuk protokol |

## 3D Chart Graph Remap K-Line

| Item | Alasan | Tindakan |
|---|---|---|
| `ANALIST_PRO - keygen.exe` (762.084 B) | Alat keygen/lisensi; di luar lingkup dan berisiko | Tidak dijalankan, tidak dianalisis, tidak dipublikasikan |
| `analist_pro - keygen.exe\xa0` (623.616 B) | Duplikat/varian | Sama seperti di atas |
| `bin/`, `obj/`, `packages/` | Build artefak/dependensi | Tidak dianalisis |
| Database/model kendaraan | Tidak diperlukan untuk dua fokus | Tidak dianalisis |
| Gambar/screenshot aplikasi | Bukan mekanisme internal | Tidak dianalisis |
| Lisensi AES key/IV | Rahasia lisensi | Nilai tidak dimuat dalam laporan |

## Keterbatasan umum

- Tidak ada ECU atau perangkat fisik yang terhubung; tidak ada TX/RX capture.
- Tidak ada eksekusi aplikasi; semua temuan bersifat statis.
- H-Diag tidak memiliki source; mekanisme internal diturunkan dari disassembly.
- Binary 3D Chart dapat dibaca sebagai source, tetapi perilaku runtime tetap belum diuji.
