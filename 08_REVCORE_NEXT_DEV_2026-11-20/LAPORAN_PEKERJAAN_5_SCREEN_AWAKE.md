# LAPORAN PEKERJAAN 5 — SCREEN AWAKE

Tanggal: 2026-11-20
Pemilik proyek: otoy / Otoy Sullivan

## Status

**PARTIAL**

Mekanisme diperbaiki dan dibangun, tetapi perilaku layar pada MIUI 14/Poco X3
NFC belum diuji. Tidak ada wakelock baru.

## 1. Mekanisme yang ada

RevCore hanya memakai window flag:

```kotlin
window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
```

`AndroidManifest.xml` **tidak** meminta `WAKE_LOCK`. Jadi tidak ada wakelock
yang menahan CPU/layar di background.

## 2. Masalah yang ditemukan

Logika lama (`MainActivity.onCreate`) mengikat flag ke `StartupState.Ready`:

- selama startup, pemeriksaan integritas, persetujuan, dan izin penyimpanan,
  layar boleh tidur;
- saat pengguna masuk ke layar yang membutuhkan waktu (mis. menunggu adapter),
  status belum tentu `Ready`;
- flag dibersihkan di `onStop`, tetapi tidak dipasang kembali saat Activity
  kembali ke foreground kecuali status kembali `Ready`.

Akibatnya, pengguna dapat mengalami layar meredup/mati saat sedang memakai
aplikasi, meskipun dashboard sudah aktif.

## 3. Perbaikan

- Flag dipasang pada `onCreate` dan dipasang ulang pada setiap `onStart`
  (`MainActivity.kt:119, 217`).
- Flag dibersihkan pada `onStop` (`MainActivity.kt:230`).
- Flag berlaku selama Activity terlihat, termasuk startup, dialog izin, dan
  recovery; tidak ada biaya baterai di background karena otomatis dilepas saat
  aplikasi tidak terlihat.
- Tidak ada wakelock, tidak ada alarm, tidak ada service latar.

## 4. Alasan tidak memakai wakelock

- `PARTIAL_WAKE_LOCK` tidak menyalakan layar.
- `SCREEN_BRIGHT_WAKE_LOCK`/`FULL_WAKE_LOCK` sudah deprecated dan berlebihan.
- Window flag adalah mekanisme resmi untuk “layar tetap aktif selama halaman ini
  terlihat” dan tidak memerlukan izin.

## 5. Pengujian dan keterbatasan

- Kompilasi debug dan release Kotlin berhasil.
- Tidak ada unit test untuk window flag (memerlukan instrumentasi).
- Belum diuji pada Poco X3 NFC/MIUI 14. MIUI dapat memiliki pengaturan hemat
  daya yang mengabaikan flag; jika pemilik masih melihat layar mati, langkah
  berikutnya adalah memeriksa pengaturan baterai MIUI dan mencatat durasi serta
  layar yang aktif saat kejadian.

## 6. Risiko tersisa

- Pada beberapa perangkat, kebijakan produsen dapat menimpa window flag.
- Layar tetap aktif selama aplikasi terlihat; ini disengaja, tetapi tetap
  mengonsumsi daya lebih tinggi daripada layar yang tidur.
