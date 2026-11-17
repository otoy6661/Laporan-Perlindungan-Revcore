# 02 — ANATOMI APLIKASI
## TunerPro RT 5.0.10335.0

**Basis bukti:** PE header/import/export (`02_STATIC_ANALYSIS\PE`), string table, runtime window dump (`03_RUNTIME_ANALYSIS`), screenshot. Tingkat bukti ditandai: **[S]** statis, **[R]** runtime, **[I]** inferensi.

---

## 1. Identitas dan bentuk executable

| Atribut | Nilai | Bukti |
|---|---|---|
| Nama | TunerPro.exe | [S] `PE_TunerPro.exe.json` |
| Versi file | 5.0.10335.0 | [S] metadata file sistem |
| Arsitektur | x86 (PE32, bukan PE32+) | [S] |
| Ukuran | 1.324.544 byte | [S] |
| Image base | `0x400000` | [S] |
| Section | 5 | [S] |
| Entry point RVA | `0x00013749` | [S] |
| Subsystem | GUI | [S] |
| Authenticode | tidak ada (offset/size 0) | [S] |
| Overlay | 0 byte | [S] |
| Build timestamp PE | 2026-10-15 02:21:43 UTC | [S] |
| Bahasa/kerangka | native C++ dengan kelas window MFC-style (`TUNERPRO`, `MMTABSHEET`, `MMGRIDCONTROL`, `MMRICHSTATIC`) | [S]/[R] |

Tidak ada CLR/.NET. Aplikasi bergantung pada VC++ runtime (`MSVCP140`, `VCRUNTIME140`, `api-ms-win-crt-*`) dan modul internal.

## 2. Peta modul inti

```
TunerPro.exe
├─ XDFEditor.dll          editor definisi BIN (XDF)
├─ ADXEditor.dll          editor definisi datastream (ADX)
├─ ScannerProModule.dll   mesin datalogging / view / dashboard / monitor
├─ PromIO.dll             UI pemrograman chip (Prom)
├─ MoatesOnboardLogger.dll UI onboard logging Moates
├─ TPChecksumPlugin.dll   kalkulator checksum (API MMCS*)
├─ TPMoatesEmulatorPlugin.dll plug-in emulator (TPCreatePlugin)
└─ ELM327PlugIn.dll       plug-in pengguna di Documents\TunerPro Files\Plugins
```

Detail ekspor/impor ada di laporan 03 dan 12.

## 3. Siklus start

Urutan yang teramati [R]:

1. Proses membuat window utama kelas `TUNERPRO`.
2. Aplikasi memuat setelan terakhir dari `%USERPROFILE%\Documents\TunerPro Files\TunerProSettings.dat`.
3. Bila setelan menunjuk BIN/XDF/ADX yang masih ada, ketiganya dibuka otomatis. Title bar menjadi:
   `TunerPro RT - <bin> | XDF File - <xdf> | ADX File - <adx>`.
4. Bila berkas yang tercatat sudah tidak ada, muncul kegagalan membuka BIN dan aplikasi dapat berhenti pada status `APP_INIT_ERROR` (teramati saat uji awal).
5. Status bar default: `Hardware Not Found`, `Not Ready`, `DA: Not Connected` (atau `DA: Connecting...` sesaat setelah perintah scan).
6. `Detect Hardware At Startup` aktif secara default; dengan tidak ada adaptor, deteksi berakhir `Hardware Not Found`.

**Implikasi:** aplikasi tidak "self-contained"; state terakhir pengguna adalah input tak terpercaya yang dapat membuat startup gagal. Ini persis kelas masalah yang RevCore tangani dengan gerbang integritas/startup.

## 4. Kerangka UI

### 4.1 Menu utama
`File`, `XDF`, `View`, `Compare`, `Acquisition`, `Tools`, `Window`, `Help` [R, screenshot].

### 4.2 Toolbar
Toolbar ReBar dengan tombol buka/simpan, edit, upload/download emulator, transport datalogging, dan indikator status [R].

### 4.3 Panel
- **Parameter Tree** (`MMTABSHEET`) — pohon objek XDF: Scalars/Tables/Constants/Flags/Patches; combo `View By`.
- **Workspace** (`MDIClient`) — grid/grafik dokumen.
- **Lists** (`MMTABSHEET`) — tab `Lists`, `Dashboards`, `Monitors`, `History Tables`; `SysListView32` id 1000 menampilkan parameter ADX.
- **Status bar** id 1004 — empat pane: emulation, hardware, kesiapan, DA.

### 4.4 Dialog penting (ID perintah Windows)

| Perintah | ID | Perilaku teramati |
|---|---|---|
| Open BIN | 32773 | dialog file; path harus backslash |
| Save Bin | 32774 | menyimpan BIN hasil edit; memicu update checksum |
| Save Bin As | 32775 | menulis salinan BIN; memicu update checksum |
| Select XDF | 32776 | memuat definisi |
| Save XDF | 32787 | menyimpan definisi |
| Save XDF As | 32788 | menyimpan definisi ke file baru |
| Open ADX (Load Definition File) | 33052 | memuat datastream |
| About Plug-ins | 33127 | daftar plug-in antarmuka hardware |
| System Check | 32991 | "All is well!" + peringatan |
| Initialize Hardware | 32854 | tanpa dialog saat hardware absen |
| Emulation Upload | 32897 | error 64 KB |
| Emulation Download | 32904 | error 64 KB |
| Emulation Verify | 32899 | error 64 KB |
| Enable Live Tuning | 32900 | tanpa efek tanpa hardware |
| Release Hardware | 33104 | tanpa efek |
| Preferences | 32778 | 6 tab, termasuk Data Acq./Emulation |

ID ini adalah kontrak UI internal; berguna untuk otomasi uji regresi, bukan API publik.

## 5. Persistensi dan state

Lokasi: `%USERPROFILE%\Documents\TunerPro Files\`

| Berkas | Ukuran | Fungsi |
|---|---|---|
| `TunerProSettings.dat` | 71.304 | setelan utama, path terakhir, preferensi |
| `TunerProSettingsFree.dat` | 71.304 | salinan/varian setelan (timestamp lama) |
| `TPSPMSettings.dat` | 580 | setelan ScannerPro |
| `TPEmuPlugin.dat` | 48 | setelan plug-in emulator |
| `Plugins\ELM327PlugIn.dll` | — | plug-in pengguna |
| `Bin Definitions`, `Bins`, `DataStreams`, `Layouts` | — | folder definisi/data pengguna |

**Tidak ditemukan setelan aplikasi di registry**; yang ada hanya entri uninstall Corel PCU (bukan bagian TunerPro). [S/R]

**Catatan integritas:** probes BE-11 mengubah `TunerProSettings.dat`, `TPSPMSettings.dat`, `TPEmuPlugin.dat` (path terakhir dan status koneksi). Tidak ada backup otomatis. Perubahan ini didokumentasikan di laporan 16/18; instalasi dan dataset asli tidak diubah.

## 6. Kemampuan jaringan/update

- Impor `WININET.dll`: `InternetOpenA`, `InternetConnectA`, `HttpOpenRequestA`, `HttpSendRequestA`, `InternetReadFile`, `InternetCloseHandle`. [S]
- String: `http://www.tunerpro.net`, `http://www.tunerpro.net/registration.htm`, pesan "Invalid Key / key for a previous version". [S]
- **Tidak** dilakukan pemanggilan update atau registrasi; tidak ada capture HTTP. Klaim yang sah: *kemampuan* update/registrasi ada; perilaku jaringan aktual **tidak diuji**.

## 7. Penanganan kesalahan

Pola yang teramati:
- MessageBox berjudul `Error` atau `You messed up (I think.)` untuk kegagalan operasi.
- Contoh: checksum gagal → `Error - One or more checksums could not be updated. Check checksum addressing, etc, for validity.`
- Contoh: emulator → `FAILURE: Bin is larger than emulation RAM! Perhaps you meant to use bank 8?`
- System Check → `Everything I checked passed. This is good, but doesn't guarantee everything will work.`

Aplikasi tidak melakukan rollback otomatis pada Save As yang gagal; berkas tujuan tidak dibuat (terverifikasi CBR). Ini perilaku aman secara default.

## 8. Kesimpulan anatomi

TunerPro RT adalah **editor definisi + runner datalogging + lapisan plug-in hardware**, bukan flasher ECU. Inti bernilai tinggi ada pada model XDF/ADX dan kontrak plug-in; jalur ECU sepenuhnya bergantung pada plug-in/ADX dan tidak terlihat di inti.
