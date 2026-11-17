# 13 — FLASHING DAN RECOVERY

**Work order:** BE-12
**Status:** SOURCE VERIFIED (tahapan/pesan) · **NOT TESTED** pada ECU (penulisan fisik dilarang)
**Sumber:** `09_FLASHING_RECOVERY/FLASH_PIPELINE.md`

---

## 1. Prasyarat yang ditegakkan aplikasi

- Konfirmasi eksplisit: **"Konfirmasi Flash ECU" — "Apakah Anda yakin ingin melanjutkan proses flash ECU?"**
- Identitas ECU terisi (`TxtEcmId`, `TxtPartCode`); jika tidak → `ID tidak valid`/`Unknown Part Code`.
- Daya: `SILAHKAN HUBUNGKAN ECM KE DAYA`; instruksi ignition OFF/ON per vendor.
- Pilihan `CbFastWrite`, `TbStartOffset`, `TbChecksumOffset`.

## 2. Urutan operasi (rekonstruksi)

| # | Tahap | Bukti | Pesan |
|---:|---|---|---|
| 1 | Pra-tulis vendor | `ShindengenPreWriteFlash(2)`, `KeihinPreWriteFlash()` | `Please Wait...` |
| 2 | Seed/Key | `Failed challenging Seed/Key`, `GetShindengenWriteKey(2)` | gagal → berhenti |
| 3 | Hapus flash | `Erasing flash failed`, `DELETE FAILED, BLOCK ERROR` | `Erasing Flash Failed` |
| 4 | Tulis | `WriteFlash(3)`, `Flashing, Please Wait!` | `WRITE FLASH FAILED!` |
| 5 | Verifikasi | `CompareMemory(4)`, `Verifikasi Data...` | `WRITE FLASH COMPLETE` / `GOOD` |
| 6 | Checksum | `AutoChecksum` per vendor | tercakup GOOD/BAD |
| 7 | Hasil | `write flash completed result = BAD!!` | `BAD Flash ! Please Restar ECM` |

**Penting:** urutan 1–7 adalah rekonstruksi dari nama metode/pesan. Tanpa IL dan capture, urutan sebenarnya **NOT VERIFIED**; jangan mengutipnya sebagai diagram protokol.

## 3. Bukti keberhasilan vs klaim

Satu-satunya indikator sukses yang terlihat adalah `CompareMemory` + `WRITE FLASH COMPLETE`/`GOOD`. Tidak ada capture yang membuktikan bahwa:

- seluruh image ditulis, bukan hanya area kalibrasi;
- checksum dihitung pada rentang yang benar;
- ECU benar-benar menerima dan menjalankan image baru.

## 4. Recovery

| Mekanisme | Bukti |
|---|---|
| Mode recovery | `Mode Recovery ECM`, `ECM Recovery Mode`; `GetShindengenRecoveryKey(2)` |
| Instruksi pasca-gagal | `BAD Flash ! Please Restar ECM`, `Please restart the ECU and try to flash it again` |
| Reset flash count | form `Reset` (`reset_COUNT`), menu `Reset Count`, `Hapus Flash Count (Auto)` |
| Ulang dari awal | `Ulangi Dari Awal`, `Silahkan Restart ECM` |

Recovery Shindengen memiliki kunci terpisah dari kunci tulis normal — indikasi jalur pemulihan ada, tetapi **belum pernah diuji**.

## 5. Perbedaan vendor

| Aspek | Keihin | Shindengen |
|---|---|---|
| Pra-tulis | `KeihinPreWriteFlash` | `ShindengenPreWriteFlash` + write key |
| Recovery | reset flash count | recovery key + mode recovery |
| Init | `Please Turn OFF` | `Please Turn OFF - ON` |

## 6. Kontrol kualitas yang terlihat

- Verifikasi baca-ulang sebelum menyatakan sukses.
- Pesan GOOD/BAD eksplisit.
- Progres berbobot untuk operasi panjang.
- Konfirmasi ganda untuk flash/reset/read.

## 7. Yang tidak diketahui

- Ukuran blok tulis, alamat awal default, timeout, retry.
- Apakah `CbFastWrite` melewati verifikasi (hipotesis).
- Apakah `CompareMemory` membandingkan seluruh image atau hanya area tulis.
- Apakah aplikasi dapat memulihkan ECU yang benar-benar brick; klaim recovery hanya fitur UI/metode.

## 8. Posisi terhadap RevCore

RevCore memiliki `FlashEngine` **default-deny** (`FlashCapabilities` semua false) dan state `RECOVERY_REQUIRED` tanpa rutin. FLASHPRO memiliki jalur tulis lengkap di permukaan, tetapi tidak dapat diaudit. Untuk RevCore, menyalin urutan ini tanpa capture akan melanggar prinsip default-deny dan berisiko brick. Status yang jujur: **FLASHPRO punya fitur, bukan bukti**; **RevCore aman, bukan lengkap**.
