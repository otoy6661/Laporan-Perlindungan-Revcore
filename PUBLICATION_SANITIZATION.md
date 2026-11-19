# Publication Sanitization

Tanggal: 2026-11-19
Repository: `otoy6661/Laporan-Revcore` (branch `main`)
Tindakan: mengganti seluruh isi laporan lama dengan hasil analisis terbaru, tanpa force push dan tanpa menulis ulang sejarah.

## 1. Prinsip

1. Hanya hasil analisis yang dipublikasikan.
2. Binary pihak ketiga tidak dipublikasikan.
3. Source lengkap pihak ketiga tidak dipublikasikan; hanya potongan pendek sebagai bukti teknis.
4. Data lisensi/kredensial tidak dipublikasikan.
5. Bahan asli di PC tidak diubah.

## 2. Yang tidak dipublikasikan

| Item | Alasan |
|---|---|
| `HDiag.exe` dan DLL Qt/ICU/MSVC | Binary pihak ketiga |
| `login.ini` (141.022 B) | Daftar kode lisensi sensitif |
| Isi kode lisensi H-Diag | Kredensial |
| AES key/IV lisensi 3D Chart | Rahasia lisensi |
| `ANALIST_PRO - keygen.exe` dan variannya | Alat bypass lisensi |
| Source lengkap `Form1.cs` / `Diag.cs` | Bahan pihak ketiga; hanya kutipan pendek |
| File BIN/ROM | Data pihak ketiga |
| Token/credential/PII | Kebijakan |

## 3. Redaksi/penghilangan

| Lokasi | Item | Perlakuan |
|---|---|---|
| Laporan remap | Nilai AES key/IV | Tidak dimuat; disebut sebagai "hardcoded" |
| Laporan H-Diag | Isi `login.ini` | Hanya ukuran + SHA-256 |
| Laporan H-Diag | Kode lisensi individual | Tidak dimuat |
| Laporan | Nama pengguna/telepon/email | Tidak ada dalam bahan yang dianalisis |

## 4. File lama yang diganti

136 file lama dihapus dari kondisi repository terbaru (lihat `06_REPOSITORY/REMOVED_OLD_FILES.txt`). Riwayat Git tetap utuh; file lama masih dapat diakses dari commit sebelumnya.

Tiga screenshot yang diunggah pemilik repository pada commit `9b7037e` dipertahankan dan dipindahkan ke `05_ARTIFACTS/legacy_screens/` agar tidak hilang.

## 5. Verifikasi

- Semua file publikasi di-hash di `PUBLICATION_MANIFEST.csv`.
- Pemeriksaan pola sensitif dilakukan sebelum commit (lihat laporan pembaruan repository).
- Tidak ada file biner baru yang ditambahkan selain screenshot lama yang sudah ada di repository.

## 6. Batas

Dokumen ini tidak menjamin bahwa kutipan kode pendek bebas dari klaim pihak ketiga; kutipan digunakan untuk membuktikan mekanisme dan hanya sepanjang yang diperlukan.
