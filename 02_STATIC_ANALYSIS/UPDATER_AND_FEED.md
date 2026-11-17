# Updater & Feed Update — Arsitektur

**Status:** SOURCE VERIFIED (kode/string) · RUNTIME VERIFIED (feed dibaca 2026-11-18).

---

## 1. Feed

Aplikasi membaca satu URL tetap:

```
https://raw.githubusercontent.com/flashpro2025/hondaflashprokline/refs/heads/main/hondaflashprokline.json
```

Respons yang diterima saat verifikasi (2026-11-18):

```json
{
  "version": "0.0.1.8",
  "zipUrl": "https://github.com/flashpro2025/hondaflashprokline/releases/download/hondaflashproklineupdate/update.zip",
  "notes": "Update - SAVE MODE"
}
```

Versi terpasang: **0.0.1.6** → aplikasi akan menawarkan update ke 0.0.1.8.
Tidak ada signature pada JSON; tidak ada hash file di feed.

## 2. Alur updater (`UpdaterClient`)

1. `FetchUpdateInfoAsync` — unduh JSON, validasi field `version` & `zipUrl` (`Field kosong. Wajib ada 'version' & 'zipUrl'`).
2. Bandingkan versi.
3. `DownloadFileAsync` — unduh ke `FLASHPRO_Update_…`/`update.zip` (`.part` sementara), batas ukuran (`Ukuran file melebihi batas`), tolak HTML (`zipUrl bukan link unduhan langsung`, `Server mengembalikan HTML, bukan file ZIP`), cek signature ZIP.
4. `DownloadAndExtractAsync` — buka ZIP berpassword (password disamarkan di evidence), ekstrak ke `staging/`, tolak path traversal (`Unsafe entry`, `Path traversal terdeteksi`), batas total ekstraksi.
5. Jalankan `Auto Update.exe` dari folder aplikasi dengan elevasi:
   ```
   "{0}" "{1}" "{2}" {3}
   runas
   ```
6. UI: `FormUpdatePrompt`, `FormUpdateProgress` (`Downloading… / Validating… / Extracting… / Launching Updater…`), `No updates available. Your application is up to date.`

## 3. Implikasi keamanan (observasi, bukan tuduhan)

| Fakta | Konsekuensi |
|---|---|
| Feed di GitHub publik, tanpa signature | Siapa pun yang menguasai repo/akun dapat mengubah `zipUrl` |
| ZIP berpassword, password tertanam di aplikasi | Kerahasiaan paket bergantung pada obfuscation, bukan PKI |
| Updater dijalankan `runas` | Update dieksekusi dengan hak administrator |
| Tidak ada hash di JSON | Integritas hanya dari password ZIP + HTTPS |
| URL `raw.githubusercontent.com` + release GitHub | Dua titik kontrol eksternal |

Ini bukan bukti kerentanan yang dieksploitasi; hanya karakteristik desain yang perlu diketahui RevCore bila ingin membuat updater serupa (RevCore tidak memiliki updater).

## 4. Hubungan dengan analisis

- Updater adalah satu-satunya koneksi jaringan aplikasi yang terbukti (tidak ada telemetri/aktivasi online).
- `Auto Update.exe` adalah payload terpisah (9,8 MB, wrapper + payload x64 5 seksi) — tidak dijalankan dalam BE-12 (**NOT TESTED**).
- Tidak ada update yang diunduh/dipasang selama analisis.
