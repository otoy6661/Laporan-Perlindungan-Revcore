# Regresi, Bukti, dan Batas Klaim

Tanggal: 2026-11-20. Dokumen ini memisahkan **hasil pengujian aktual** dari
**pemeriksaan source code** dan **asumsi**.

Laporan utama: [LAPORAN_TEKNIS_REVCORE_2026-11-20.md](LAPORAN_TEKNIS_REVCORE_2026-11-20.md)

---

## 1. Metode yang dipakai

| Metode | Arti dalam laporan ini |
|---|---|
| Unit test JVM | Dijalankan di salinan kerja; hasil XML tersedia |
| Build | Gradle compile/assemble di salinan kerja |
| Pemeriksaan source | Membaca kode; **bukan** bukti perilaku runtime |
| Uji perangkat | **Tidak dilakukan** |
| Uji ECU | **Tidak dilakukan** |
| Uji Gate 10 | **Tidak dilakukan** |

---

## 2. Regresi per area

| Area | Perubahan terkait fitur (bukan pekerjaan pelaporan ini) | Metode | Hasil | Status |
|---|---|---|---|---|
| ECM Info / Informasi Kendaraan | Tidak ada perubahan | Pemeriksaan source | Kode dan label tidak berubah | SOURCE VERIFIED; perangkat BELUM DIUJI |
| Live Data — 8 parameter inti | Tidak ada perubahan | Source + unit test | Tidak ada perubahan pada profil/decoder inti | SOURCE VERIFIED; ECU BELUM DIUJI |
| Live Data — parameter tambahan | Penambahan Mode, SSS, SSW, IACV, gigi, FIS | Source + unit test | Terdaftar di profil dan diterjemahkan ke UI | BELUM DIUJI perangkat/ECU |
| Diagnostics / DTC | Tidak ada perubahan | Pemeriksaan source | Alur tidak disentuh | SOURCE VERIFIED; ECU BELUM DIUJI |
| Koneksi adapter USB | Penambahan timeout & detach handling (Point B) | Source + unit test policy | Terverifikasi kode | BELUM DIUJI perangkat |
| Koneksi & identifikasi ECU | Tidak ada perubahan inti | Pemeriksaan source | — | BELUM DIUJI ECU |
| Navigasi drawer | Entri baru (Keyless, Log, dsb.) | Build + source | Build sukses; route terdaftar | BUILD VERIFIED; tampilan BELUM DIUJI |
| Rotasi / lifecycle layar Keyless | Layar baru | Source | State di ViewModel | BELUM DIUJI perangkat |
| Gate 10 normal | Tidak ada perubahan | — | — | BLOCKED (tidak ada perangkat) |
| Fungsi sebelumnya (unit) | Tambahan suite Keyless | Unit test | 330 lulus | PASS (JVM) |

---

## 3. Klaim statis yang boleh dibuat

Hal-hal berikut dapat dinyatakan dari pemeriksaan source, dengan label yang
sesuai:

1. Driver USB tidak diubah pada pekerjaan Keyless. **[SOURCE VERIFIED]**
2. `HondaProtocolEngine` hanya mendapat method baru untuk Keyless; alur lama
   tidak diubah. **[SOURCE VERIFIED]**
3. Layar Live Data dan Diagnostics tidak diubah selain penambahan tampilan
   parameter/entri Keyless. **[SOURCE VERIFIED]**
4. `runKeylessRead` memakai lock sesi yang sama dengan transaksi lain, sehingga
   tidak menambah jalur akses transport paralel. **[SOURCE VERIFIED]**
5. Kode integritas/Gate 10 tidak disentuh (diff baseline). **[SOURCE VERIFIED]**
6. Tidak ada polling K-Line saat aplikasi tidak terlihat.
   **[SOURCE VERIFIED + unit test `CommActivityPolicyTest`]**
7. Polling Live Data berhenti setelah 4 kegagalan beruntun.
   **[SOURCE VERIFIED + unit test `LivePollPolicy`]**
8. Release tanpa kredensial resmi gagal tertutup; tidak ada APK release
   dihasilkan. **[UJI BUILD — log tersedia]**

Klaim yang **tidak** boleh dibuat: "fitur stabil", "disconnect sudah beres",
"Gate 10 lulus", "Mode `0x5F` berarti X", "berfungsi di kendaraan".

---

## 4. Bukti unit test

Sumber: `RevCore_work/app/build/test-results/testDebugUnitTest/*.xml`
(39 file, timestamp hasil `2026-11-19T23:45Z` = 2026-11-20 06:45 WIB).

| Metrik | Nilai |
|---|---:|
| Suite (file XML) | 39 |
| Total test | 330 |
| Gagal | 0 |
| Error | 0 |
| Dilewati | 0 |

Suite baru untuk Keyless:

| Suite | Jumlah |
|---|---:|
| `KeylessFrameCodecTest` | 9 |
| `KeylessIdDecoderTest` | 6 |

Suite terkait investigasi:

| Suite | Relevansi |
|---|---|
| `LiveActuatorDecoderTest` | Pemetaan Mode `1..4` → `MODE n`; di luar itu `null` |
| `CommActivityPolicyTest` | Gating foreground |
| (suite `LivePollPolicy`, `AdapterConnectionPolicy`, dsb.) | Kebijakan komunikasi |

Catatan: baris perintah `testDebugUnitTest` terakhir tercatat `UP-TO-DATE`
(tidak menjalankan ulang), sehingga bukti angka diambil dari XML hasil eksekusi
sebelumnya, bukan dari status task terakhir.

---

## 5. Bukti build dan signing

### 5.1 Fail-closed

Log: [`bukti/assembleRelease_tanpa_kredensial.log`](bukti/assembleRelease_tanpa_kredensial.log)

```
> Task :app:requireOfficialSigning FAILED
...
* What went wrong:
Execution failed for task ':app:requireOfficialSigning'.
> Official Release signing is not configured: REVCORE_STORE_PASSWORD is not set;
  REVCORE_KEY_PASSWORD is not set. ...
```

Tidak ada `app-release.apk`. **[UJI BUILD]**

### 5.2 APK uji resmi

File: [`bukti/verifikasi_apk_uji_keyless.txt`](bukti/verifikasi_apk_uji_keyless.txt)

| Item | Hasil |
|---|---|
| Skema | v2 true, v3 true, 1 signer |
| DN | `CN=RevCore Official, OU=Release, O=RevCore, L=Jakarta, ST=DKI Jakarta, C=ID` |
| Cert SHA-256 | `c649cb4fd7e67686a99c1df31936a489b89e62a877b8d6b358f64d027a18d098` |
| SHA-256 APK | `3b68fe6a4129c7d49a4721990de03bf7d73b2154af170a247d9889bb4345306e` |
| Ukuran | 39.722.410 byte |
| Package | `com.revcore.android` 1.0 (versionCode 1), targetSdk 36 |
| Debuggable | tidak |
| Material kunci | tidak ada (p12/jks/keystore/pem/key) |
| Fitur Keyless di DEX | string `btn_keyless_read` ditemukan |
| `dist/` | tidak tersentuh |

Verifikasi dijalankan ulang dengan `apksigner`/`aapt2` build-tools 36.0.0,
bukan hanya output skrip build. **[UJI VERIFIKASI]**

### 5.3 APK resmi sebelumnya (161126)

File: [`bukti/verifikasi_apk_161126.txt`](bukti/verifikasi_apk_161126.txt)

- SHA-256 `b2b6c5bd68cc9c727c2babe0c510b928a6135fa7ef5e9d8847275887c8647432`
- Cert SHA-256 sama (`c649cb4f…d098`)
- v2+v3, 1 signer

Ini dipakai sebagai pembanding bahwa pin sertifikat konsisten antar-rilis.

---

## 6. Yang tidak dapat diuji dan alasannya

| Uji | Alasan |
|---|---|
| Koneksi adapter fisik | Tidak ada adapter USB/OTG |
| Koneksi ECU & identifikasi | Tidak ada ECU/kendaraan |
| Live Data nyata | Idem |
| Diagnostics/DTC | Idem |
| Keyless read nyata | Idem |
| Gate 10 prosedur normal | Tidak ada perangkat tersambung (`adb devices` kosong) |
| Rotasi/lifecycle UI | Perlu perangkat |
| Uji stabilitas disconnect | Perlu perangkat + waktu uji |

---

## 7. Prosedur reproduksi bukti

Untuk auditor yang memiliki salinan kerja:

1. Unit test:
   ```
   gradle --offline --no-daemon :app:testDebugUnitTest
   ```
   Hasil XML di `app/build/test-results/testDebugUnitTest/`.
2. Verifikasi APK:
   ```
   apksigner verify --verbose --print-certs RevCore-keyless-test-201126.apk
   sha256sum RevCore-keyless-test-201126.apk
   ```
3. Build release tanpa kredensial (dijalankan di lingkungan tanpa
   `REVCORE_STORE_PASSWORD`/`REVCORE_KEY_PASSWORD`) harus gagal di
   `:app:requireOfficialSigning`.
4. Pemeriksaan source Mode: `LiveDataProfile.kt:384`,
   `LiveActuatorDecoder.kt:43`, `LiveValueText.kt:40-42`.

Tidak ada perintah yang memerlukan atau mencetak password.
