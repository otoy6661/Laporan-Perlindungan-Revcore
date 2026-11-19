# REKOMENDASI SANITASI RILIS v0.3.0

> **DOKUMEN INTERNAL — JANGAN DIPUBLIKASIKAN.** Dokumen ini memuat pola pencarian yang
> menyebut materi terlarang. Gunakan hanya untuk verifikasi lokal.

Status: **usulan, belum dijalankan.** Audit tidak mengubah dokumen terbit.

## Temuan

| Lokasi | Masalah | Dampak |
|---|---|---|
| `CHANGELOG.md:96` | Menyebut nama folder sumber eksternal | Melanggar aturan kerahasiaan asal-usul |
| `CHANGELOG.md:97` | Menyebut nama komponen keamanan internal | Melanggar larangan publikasi komponen internal |
| Catatan rilis GitHub `v0.3.0`, baris 41 | Mengulang kedua hal di atas | Terlihat publik di halaman Release |
| `RevCore_Developer_Repository_v0.3.0.zip` → `CHANGELOG.md` | Memuat baris yang sama | ZIP yang diunduh juga memuatnya |

Tidak ada detail mekanisme keamanan yang bocor. Yang perlu dihapus adalah nama dan
rujukan struktur, bukan penjelasan teknis.

## Usulan teks pengganti

`CHANGELOG.md:96` — ganti seluruh baris dengan:

```text
- Modul pihak ketiga dan jalur flash/remap tidak dipublikasikan.
```

`CHANGELOG.md:97` — ganti seluruh baris dengan:

```text
- UI/Application Layer dan Security/Integrity tidak dipublikasikan.
```

Catatan rilis baris 41 — ganti kalimat yang menyebut nama folder/gate dengan:

```text
ZIP repository developer tidak memuat UI/Application Layer, Security/Integrity, alur
flash/remap, materi pihak ketiga, database ECM dan MAP nyata, katalog Live Data
proprietary, serta kredensial/keystore. APK di atas adalah aplikasi lengkap dan memuat
komponen tersebut dalam bentuk terkompilasi.
```

## Urutan kerja yang disarankan

1. Otoy menyetujui perubahan teks.
2. Edit `CHANGELOG.md` di repository.
3. Edit catatan rilis GitHub (tidak menyentuh aset APK).
4. Buat ZIP koreksi dari repository yang sudah disanitasi.
5. Unggah ZIP koreksi sebagai aset rilis; jangan mengganti APK.
6. Tentukan apakah versi tetap `v0.3.0` atau naik ke `v0.3.1`.

## Verifikasi setelah sanitasi

```bash
# Repo
git grep -niE "flashpro|flash pro" -- . ':!*.zip'
git grep -n "Gate 10" -- .

# ZIP
unzip -p <zip-koreksi> CHANGELOG.md | grep -niE "flashpro|flash pro|Gate 10"

# Release
gh release view v0.3.0 -R otoy6661/Revcore-Project --json body -q .body | grep -niE "flashpro|gate 10"

# APK tidak berubah
sha256sum RevCore_161126.apk
```

Hash APK yang benar:

```text
b2b6c5bd68cc9c727c2babe0c510b928a6135fa7ef5e9d8847275887c8647432
```

## Catatan

- Jangan mengubah, membangun ulang, atau menandatangani ulang APK.
- Jangan memakai force-push atau menulis ulang riwayat Git.
- ZIP koreksi tidak boleh memuat cache, build, APK, AAR, keystore, atau database nyata.
