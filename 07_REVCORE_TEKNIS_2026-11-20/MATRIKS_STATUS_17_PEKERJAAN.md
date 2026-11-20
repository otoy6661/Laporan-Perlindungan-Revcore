# Matriks Status Pekerjaan RevCore

Tanggal: 2026-11-20.

## 0. Catatan keterlacakan (wajib dibaca)

Work order meminta tabel 17 item pekerjaan dengan status jujur. Daftar 17 item
asli **tidak ditemukan utuh** dalam catatan/transkrip yang tersimpan. Pencarian
terhadap seluruh arsip sesi hanya menemukan rujukan ("menunggu penyelesaian dan
pengujian pekerjaan 17 poin"), bukan daftar butirnya.

Karena itu, tabel di bawah disusun **hanya** dari butir yang dapat dilacak ke
pekerjaan nyata yang tercatat:

- Work order Point A (ECM Info & Live Data) — decode flag, parameter Live Data,
  parameter tambahan, Mode/Altitude, FIS/FIZ.
- Work order Point B (stabilitas komunikasi) — gating foreground, timeout buka
  adapter, backoff recovery, link-loss, detach.
- Work order Point C (layar & loading) — keep-screen-on, loading setelah
  Gate 10, satu loading per peluncuran, loading minimum 2 detik.
- Pekerjaan Keyless ID Reader + signing resmi (sesi 2026-11-20).

Tidak ada butir yang dikarang. Bila pemilik memiliki daftar 17 item asli,
tabel ini dapat dipetakan ulang tanpa mengubah status bukti.

Label status mengikuti work order:

- **COMPLETED** — implementasi selesai dan sudah diverifikasi sesuai metode yang
  tercantum.
- **IMPLEMENTED — NOT TESTED** — kode selesai, belum diuji pada perangkat/ECU.
- **PARTIALLY IMPLEMENTED** — ada bagian yang belum lengkap atau masih
  diperdebatkan.
- **FAILED / BLOCKED / NOT STARTED** — sesuai arti harfiah.

---

## 1. Tabel status

| No. | Pekerjaan | Status Implementasi | Status Pengujian | Bukti |
|---:|---|---|---|---|
| 1 | Decode flag A (pompa bahan bakar) tanpa mengklaim relay fisik bergerak | COMPLETED | IMPLEMENTED — NOT TESTED (ECU) | `LiveActuatorDecoder` + `LiveValueText.kt:23-27`; `LiveActuatorDecoderTest` PASS; ECU tidak tersedia |
| 2 | Decode flag B (kipas pendingin) tanpa klaim aktuator | COMPLETED | IMPLEMENTED — NOT TESTED (ECU) | `LiveValueText.kt:28-32`; unit test PASS; ECU tidak tersedia |
| 3 | Delapan parameter Live Data inti tetap berfungsi (tidak diubah) | COMPLETED (tanpa perubahan) | IMPLEMENTED — NOT TESTED (ECU, sesi ini) | Pemeriksaan source; 330 unit test lulus; tidak ada ECU |
| 4 | Label ketersediaan parameter tambahan (TERSEDIA / SAAT MESIN HIDUP / BELUM TERBACA / TIDAK VALID / TIDAK TERSEDIA) | COMPLETED | IMPLEMENTED — NOT TESTED (perangkat) | `EcuInfoScreen.kt:350-369`; unit test state; perangkat tidak ada |
| 5 | Mode Mesin / Altitude (`0x5F`) | PARTIALLY IMPLEMENTED — pemetaan `1..4` tidak cocok dengan kode referensi; arti `0x5F` belum diketahui | IMPLEMENTED — NOT TESTED (ECU); investigasi statis selesai | `INVESTIGASI_MODE_0x5F.md`; `LiveActuatorDecoder.kt:43`; `LiveDataProfile.kt:384`; unit test PASS |
| 6 | FIS/FIZ ditandai tidak tersedia, tidak diklaim terbaca | COMPLETED | IMPLEMENTED — NOT TESTED (ECU) | `EcuInfoScreen.kt:408`; `LiveValueText.kt:45`; bukti referensi FIZ berbeda — lihat catatan §3 |
| 7 | Tidak ada polling/probe K-Line saat aplikasi tidak terlihat | COMPLETED | IMPLEMENTED — NOT TESTED (perangkat) | `CommActivityPolicy.kt`; `CommActivityPolicyTest` PASS; perangkat tidak ada |
| 8 | Timeout buka adapter 10 detik + pembersihan port | COMPLETED | IMPLEMENTED — NOT TESTED (perangkat) | `MainViewModel.kt:125, 1250-1261`; perangkat tidak ada |
| 9 | Recovery otomatis terbatas dengan backoff (2/4/8/16/30 dtk, maks. 8) | COMPLETED | IMPLEMENTED — NOT TESTED (perangkat) | `MainViewModel.kt:621-650, 1649-1660`; perangkat tidak ada |
| 10 | Deteksi link-loss ECU → status `LINK_LOST`, telemetri STALE | COMPLETED | IMPLEMENTED — NOT TESTED (ECU) | `HondaProtocolEngine.kt:379-397`; ambang 363/1084/1153/1364; ECU tidak ada |
| 11 | Penanganan detach USB (teardown transaksi + tutup port) | COMPLETED | IMPLEMENTED — NOT TESTED (perangkat) | `MainActivity.kt:68-80`; `MainViewModel.kt:1042-1075, 1612-1638`; `AdapterConnectionPolicy`; perangkat tidak ada |
| 12 | Layar tetap menyala hanya saat dashboard aktif & Activity started | COMPLETED | IMPLEMENTED — NOT TESTED (perangkat) | `MainActivity.kt:117-130, 254-260`; perangkat tidak ada |
| 13 | Loading setelah pemeriksaan Gate 10 (bukan sebelum) | COMPLETED | IMPLEMENTED — NOT TESTED (perangkat); build verified | `MainActivity.kt:158-187`; startup state; perangkat tidak ada |
| 14 | Satu animasi loading per peluncuran (tidak berulang saat rotasi) | COMPLETED | IMPLEMENTED — NOT TESTED (perangkat) | Startup job dimiliki ViewModel (`MainActivity.kt:113-115`); perangkat tidak ada |
| 15 | Loading minimum 2 detik | **NOT STARTED** — keputusan pemilik belum ada | NOT APPLICABLE | Point C mencatat interpretasi "2 detik sebelum loading" tidak diterapkan; menunggu keputusan |
| 16 | Keyless ID Reader (baca ID read-only) | COMPLETED | IMPLEMENTED — NOT TESTED (perangkat/ECU); 15 unit test PASS | `KeylessFrameCodecTest` 9 + `KeylessIdDecoderTest` 6; APK `RevCore-keyless-test-201126.apk` terverifikasi |
| 17 | Signing resmi fail-closed + verifikasi APK uji | COMPLETED | Build & verifikasi SELESAI; Gate 10 perangkat BLOCKED | `bukti/assembleRelease_tanpa_kredensial.log`; `bukti/verifikasi_apk_uji_keyless.txt`; `adb devices` kosong |

---

## 2. Rekap

| Status | Jumlah | Butir |
|---|---:|---|
| COMPLETED (implementasi) | 15 | 1,2,3,4,6,7,8,9,10,11,12,13,14,16,17 |
| PARTIALLY IMPLEMENTED | 1 | 5 |
| NOT STARTED | 1 | 15 |
| FAILED | 0 | — |
| BLOCKED (pengujian) | 1 | 17 (Gate 10 perangkat) |

Catatan: "COMPLETED" pada kolom implementasi **tidak** berarti tervalidasi di
kendaraan. Kolom pengujian menunjukkan bahwa hampir semua butir berstatus
IMPLEMENTED — NOT TESTED karena tidak ada perangkat/adapter/ECU.

---

## 3. Butir yang belum selesai / belum tervalidasi

1. **Butir 5 (Mode `0x5F`)** — pemetaan belum final; perlu bukti frame dan
   keputusan pemilik. Ini temuan bug, bukan pekerjaan yang diklaim selesai.
2. **Butir 15 (loading 2 detik)** — belum dikerjakan; menunggu keputusan apakah
   kebutuhan ini dipertahankan (tercatat di laporan Point C pada salinan kerja
   `REVCORE_ABC_20261120/laporan/POINT_C_SCREEN_DAN_LOADING.md`).
3. **Butir 6 (FIS/FIZ)** — RevCore sengaja menandai tidak tersedia, sedangkan
   referensi 3D Chart menurunkan FIZ dari `MD < 128`. Perbedaan ini adalah
   pilihan desain yang perlu dikonfirmasi pemilik; bukan bug yang sudah
   divalidasi.
4. **Seluruh butir perangkat/ECU** — belum diuji: tidak ada perangkat, adapter,
   atau ECU pada sesi ini.
5. **Gate 10** — belum diuji pada prosedur normal.

---

## 4. Bukti uji yang benar-benar ada

| Bukti | Nilai |
|---|---|
| Unit test JVM | 330 test, 39 suite, 0 gagal, 0 error, 0 skip |
| Suite Keyless baru | `KeylessFrameCodecTest` 9, `KeylessIdDecoderTest` 6 |
| Build | compileDebug/compileRelease/assembleDebug SUCCESSFUL |
| Release tanpa kredensial | Gagal tertutup di `:app:requireOfficialSigning` |
| APK uji resmi | v2+v3, 1 signer, cert `c649cb4f…d098`, tidak debuggable |
| Uji perangkat | **TIDAK ADA** |
| Uji ECU | **TIDAK ADA** |
| Uji Gate 10 | **TIDAK ADA** |
