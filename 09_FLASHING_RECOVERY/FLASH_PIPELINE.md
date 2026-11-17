# Flashing & Recovery — Pipeline yang Terbaca

**Status:** SOURCE VERIFIED (tahapan, pesan, kontrol) · **RUNTIME: NOT TESTED** (tidak ada ECU; penulisan ke ECU fisik dilarang).

---

## 1. Prasyarat yang ditegakkan aplikasi

- Konfirmasi eksplisit: **"Konfirmasi Flash ECU" — "Apakah Anda yakin ingin melanjutkan proses flash ECU?"**
- Identitas ECU harus terisi: `TxtEcmId`, `TxtPartCode`; jika tidak → `ID tidak valid` / `Unknown Part Code`.
- Daya: `SILAHKAN HUBUNGKAN ECM KE DAYA`; instruksi ignition OFF/ON per vendor.
- Pilihan `CbFastWrite` (mode tulis cepat) dan offset (`TbStartOffset`, `TbChecksumOffset`).

## 2. Urutan operasi (dari nama metode + pesan)

| # | Tahap | Bukti | Pesan sukses/gagal |
|---:|---|---|---|
| 1 | Pra-tulis vendor | `ShindengenPreWriteFlash(2)`, `KeihinPreWriteFlash()` | `Please Wait...` |
| 2 | Seed/Key challenge | `Failed challenging Seed/Key`, `Failed generating Seed/Key`; `GetShindengenWriteKey(2)` | gagal → berhenti |
| 3 | Hapus flash | `Erasing flash failed`, `Erasing flash failed, block error`, `DELETE FAILED, BLOCK ERROR`, UI `Erase` | `Erasing Flash Failed` |
| 4 | Tulis | `WriteFlash(3)`, `Flashing, Please Wait!` | `WRITE FLASH FAILED!` |
| 5 | Verifikasi | `CompareMemory(4)`, `Verifikasi Data...`, `Verify` | `WRITE FLASH COMPLETE` / `Writing Data Completed Result = GOOD` |
| 6 | Checksum | `ShindengenAutoChecksum(1)`, `KeihinAutoChecksum(1)` | tercakup hasil GOOD/BAD |
| 7 | Hasil | `write flash completed result = BAD!!`, `Writing Data Completed Result = GOOD` | `BAD Flash ! Please Restar ECM` |

**Penting:** urutan 1–7 adalah rekonstruksi dari nama metode/pesan. Tanpa IL dan tanpa capture, urutan sebenarnya **NOT VERIFIED**; jangan mengutipnya sebagai diagram protokol.

## 3. Recovery

| Mekanisme | Bukti |
|---|---|
| Mode recovery eksplisit | string `Mode Recovery ECM`, `ECM Recovery Mode`; `GetShindengenRecoveryKey(2)` |
| Instruksi pasca-gagal | `BAD Flash ! Please Restar ECM`, `Please restart the ECU and try to flash it again`, `Unknown !Please Restart ECM` |
| Reset flash count | form `Reset` (`reset_COUNT`, `reset_COUNT1`), menu `Reset Count`, dialog `Reset Flash Count Keihin/Shindengen`, `Hapus Flash Count (Auto)` |
| Ulang dari awal | `Ulangi Dari Awal`, `Silahkan Restart ECM` |

Recovery Shindengen punya jalur kunci sendiri (recovery key), terpisah dari kunci tulis normal — indikasi ECU dapat dipulihkan setelah flash gagal, tetapi **belum pernah diuji** dalam BE-12.

## 4. Perbedaan vendor

| Aspek | Keihin | Shindengen |
|---|---|---|
| Pra-tulis | `KeihinPreWriteFlash` | `ShindengenPreWriteFlash` + write key |
| Recovery | reset flash count | recovery key + mode recovery |
| Init | `Please Turn OFF` | `Please Turn OFF - ON` |

## 5. Kontrol kualitas yang terlihat

- Verifikasi baca-ulang (`CompareMemory`) **sebelum** menyatakan sukses.
- Pesan hasil eksplisit GOOD/BAD (bukan hanya "selesai").
- Progres berbobot (`WeightedProgress`, `ModernProgressBar`) — tidak relevan teknis, tetapi menunjukkan operasi panjang.
- Konfirmasi ganda untuk operasi berisiko (flash, reset count, read memory).

## 6. Yang tidak dilakukan / tidak diketahui

- **Tidak ada penulisan ke ECU fisik** dalam seluruh BE-12 (batasan kerja).
- Ukuran blok tulis, alamat awal default, timeout per blok, dan jumlah retry: **NOT VERIFIED**.
- Apakah `CbFastWrite` melewati verifikasi: **hipotesis**.
- Apakah `CompareMemory` membandingkan seluruh image atau hanya area tulis: **tidak diketahui**.
- Tidak ada bukti bahwa aplikasi dapat memulihkan ECU yang benar-benar "brick"; klaim recovery hanya fitur yang ada di UI/metode.
