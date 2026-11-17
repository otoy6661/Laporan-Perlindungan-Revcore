# 05 — ANALISIS RUNTIME TERKONTROL

**Work order:** BE-11 — TunerPro RT Complete Software Autopsy
**Lingkungan:** Windows 11 Pro 22631, x86 app, tanpa perangkat keras tuning terpasang
**Status:** SELESAI — seluruh perilaku di bawah diamati langsung. Tanda: **[R]** runtime, **[S]** statis, **[I]** inferensi.

---

## 1. Metode observasi

| Teknik | Alat | Bukti tersimpan |
|---|---|---|
| Snapshot proses & modul | PowerShell `Get-Process`/`Modules` | `modules_full.txt`, `modules_at_startup.txt` |
| Pohon window & kontrol | Win32 `EnumWindows`/`EnumChildWindows` | `*_runtime.txt`, `*_dump.out` |
| Dump menu | `GetMenu`/`GetMenuStringW` | `menu_tree_new.txt` (5.522 B) |
| Screenshot | Capture window | `*.png` |
| Perintah UI | Kirim `WM_COMMAND` berdasarkan ID menu | `ui_commands.out` |
| Ablation plug-in | Rename sementara + restore | `plugin_ablation_checksum.txt` |
| Uji file | Salinan BIN/XDF/ADX di `WORK/` | `04_BIN_AUTOPSY/WORK` |

Tidak ada perangkat keras, tidak ada koneksi ECU, tidak ada penulisan ke dataset asli. Semua file uji adalah salinan.

---

## 2. Siklus start

1. Proses membuat window utama kelas `TUNERPRO`; splash `TunerPro RT — Advanced Automobile Tuning Software`, `Version 5`, `Build 5.00.10335.00` **[R]** (`startup_window.png`).
2. Settings dibaca dari `Documents\TunerPro Files\TunerProSettings.dat`. Dengan opsi default `Load Last XDF at Startup` dan `Load Last BIN at Startup` aktif, file terakhir dibuka otomatis **[R]**.
3. Title bar menjadi `TunerPro RT - <bin> | XDF File - <xdf> | ADX File - <adx>` bila ketiganya ada **[R]**.
4. Bila path BIN tercatat tidak ada, muncul MessageBox `Error` — `Failed to open BIN file`, dan editor tidak terbuka **[R]** (`startup_corrupt.png`). Aplikasi menangani ini sebagai error terkontrol, bukan crash.
5. Status bar (id 1004) memiliki empat pane; nilai awal: `Not Emulating`, `Hardware Not Found`, `Not Ready`, `DA: Not Connected` **[R]**.
6. `Detect Hardware At Startup` aktif; tanpa adaptor, hasilnya `Hardware Not Found` **[R]**.
7. Modul akhir: 55 dengan `TPChecksumPlugin.dll`; 54 bila plug-in tersebut dihilangkan (aplikasi tetap start) **[R]**.

**Implikasi untuk RevCore:** state terakhir pengguna adalah input yang tidak dipercaya. RevCore menangani kelas masalah ini dengan validasi startup dan gerbang integritas; TunerPro hanya menampilkan error dan melanjutkan dengan state kosong.

---

## 3. Struktur UI

### 3.1 Menu utama (dump runtime lengkap)

**File:** Open Bin (32773), Import Bin → From S-Record (33005), Save Bin (32774), Save Bin As (32775), Close Bin (32784), Patch Bin → From S-Record (33142), Recent Bins, Export Data To Text File (32847), Exit (106).

**XDF:** Select XDF (32776), Save XDF (32787), Save XDF As (32788), New XDF (32789), Recent XDFs, Import → From ECU file (32921) / Delimited File (33160) / TDF (32917) / VDF (33007) / RDT (32989) / CEE (33002), View/Edit XDF Header Info (32923), View/Edit Parameter XDF Info (32783), XDF Parameter Bulk Edit (33162), Create New XDF Parameter (32786), Delete Selected XDF Parameter (32785), Open Next/Previous Bin Editor (33109/33110).

**View:** Toolbars (Basic 32906, Tools 32913, View 32914, Visibility Levels 32987, XDF Editor 32929, RT 32907, Emulation 32908, Tune Bank 32948, Data Acquisition 33045), Data Acquisition Log (33046), DA Send Command (33134), Show Parameter Tree (33082), Parameter Summary List (167), Parameter Comments (169), Show Graph (210), Floating Utility Tabs (33129), Dock/Undock Active Utility Tab (33168).

**Compare:** Load Compare Bins (32804), Bin 1–4 (32816–32819).

**Acquisition:** Load Definition File (33052), Save Definition (33164), Save Definition As (33166), Import From ADS (33079) / EFILive V4 (33080), Edit Definition (33071), New Definition (33072), Recent Definitions, Start/Stop Data Scan (33068), Toggle Data Tracing (33069), Load Log File (33060), Export Log File (33075), Close Log File (33144), Playback Speed 400/200/100/50/25% (33053–33057) + Custom (33058), Play/Pause (33062), Record (33061), Stop (33063), Pause (33064), Jump ±10/±1 sample (33066/33065/33117/33116), Show Dash/Data Lists/History/Monitors (33048/33047/33049/33050).

**Tools:** Emulation → Upload Current Bin To Hardware (32897), Download Bin From Hardware (32904), Download Bin to File (32903), Verify Hardware Against Current Bin (32899), Enable Live Tuning (32900); Hardware Utilities → AutoProm A/D Data (32835), Moates PROM I/O (32820), Address Watch Utility (33089), Moates Onboard Logging (33147); Parameter Finder (32823), Difference Tool (32841), Bin Stacker/Splitter (32777), Windows Calculator (32915), Advanced → 2D Data Viewer (32829), 3D Data Viewer (32992), Hex Editor (32832); Initialize Tuning Hardware (32854), Release Tuning Hardware (33104); Custom Tools → Windows Calculator (500), New TunerPro Instance (501), Edit Custom Tools (33125); Preferences (32778).

**Window:** Cascade (32806), Tile Vertically/Horizontally (147/148), Close All Editors (153), Save All Editors (154), Close/Save Active Editor (33154/33153).

**Help:** Help Topics (32803), Registration (32821), Website (144), Splash (32955), System Check (32991), Plug-ins (33127), Check Internet For Updates (32925), About (104).

Dump lengkap: `03_RUNTIME_ANALYSIS/menu_tree_new.txt`.

### 3.2 Panel dan kontrol

| Area | Kelas / ID | Isi teramati |
|---|---|---|
| Parameter Tree | `MMTABSHEET`, `SysTreeView32` id 20094 | Scalars/Tables/Constants/Flags/Patches; combo `View By:` id 20095 |
| Workspace | `MDIClient` id 3244 | Editor tabel/konstanta; tab dokumen |
| Lists | `MMTABSHEET`, `SysListView32` id 1000 | 11 baris parameter ADX (lihat laporan 09) |
| Dashboards | `SysTabControl32` | 9 gauge (2 analog + 7 digital), label `D2 TECH` |
| Monitors | `MMDATACHART` id 9000/9001 | 2 chart + kontrol `Time Range` |
| History Tables | combo id 1002, view 1004, `MMGRIDCONTROL` 1006 | tombol Clear/Graph/3DCHART |
| Status bar | `msctls_statusbar32` id 1004 | 4 pane status |
| Toolbar | `ToolbarWindow32` id 20000/10008/10002/10004/10001 | ReBar, tombol file/edit/emulasi/transport |

### 3.3 Preferences — enam tab **[R]**

`General`, `Colors`, `Keyboard`, `Default XDFs`, `Custom Tools`, `Data Acq./Emulation`.

**General (nilai teramati):** Load Last XDF at Startup ✔, Load Last BIN at Startup ✔, Keep Editors Open After Update ✔, Show Units In Parameter Summary ☐, Enable Edit Logging ✔, Item List Tracking ✔, Warn of Changes on Editor Close ✔, Apply Open Editor Changes on Bin Save ✔, Prompt Before Synchronizing Groups ✔, Displayed Addresses Include Offset ☐; Display Data = `Calculated`; File Associations: `.xdf` ✔, `.ecu` ✔, `.ads` ✔, `.bin` ☐, `.bsl` ☐, `.adl` ☐, `.adx` ☐, `.xdl` ☐; Table Editor Compare Mode = `Absolute`, Color Table Cells ✔, Reverse Rows/Columns ☐; Graphing: always on top ☐, Color 3D ✔, Wireframe 3D ☐, Auto-range 2D ☐, Auto-range 3D ✔, Point Selection Radius 3.

**Data Acq./Emulation:** Interface Type = `Use Plug-In` (nilai lain: `AutoProm/MAFTPro`, `TunerPro Data Acquisition I/O Interface`); Data Acq. I/O Plug-In Component = `TunerPro Data Acquisition I/O Interface` (disabled); Load Last Data Acq. Def at Start ✔; Warn of ADX/XDF Link Mismatch ✔; Tuning Hardware Plug-in = `TunerPro Emulator Interface`; Configure Plug-in Component aktif; Detect Hardware At Startup ✔; Upload Whole Tables ☐; Real-Time Graph & Slider Updates ✔; Audible Update Confirmation ✔.

---

## 4. Operasi file

| Operasi | Hasil teramati |
|---|---|
| Buka BIN 262.144 B (K1AA) | Berhasil; tree parameter muncul; tabel dapat dibuka |
| Buka BIN 65.536 B (SUPRA) | Berhasil |
| Buka XDF plaintext | Berhasil; 18 tabel numerik + 2 teks dirender |
| Buka XDF terenkripsi (K0WA) | Berhasil; tree hanya menampilkan `Scalars > [ Kompatible Ecu : K0WA ]` |
| Buka ADX terenkripsi | Berhasil; Data List, Dash, Monitors, History terisi |
| Ganti XDF saat BIN terbuka | Berhasil; title berubah, tree diganti |
| Buka BIN yang hilang | `Failed to open BIN file`; editor tidak dibuat |
| Save BIN tanpa perubahan | Menulis file; checksum dihitung ulang |
| Save As XDF | Berhasil untuk XDF tanpa checksum plug-in; gagal untuk CBR1000RR (lihat §6) |
| Import dari format lain | Menu tersedia; tidak diuji (tidak ada file sampel) |

---

## 5. Editing dan checksum (runtime)

1. Tabel 35×29 pada 0x3815E dirender; sel dapat diedit; perubahan tercermin di grid **[R]**.
2. Edit nilai menjadi 9999 pada alamat 0x3B122 menghasilkan byte `0F 27` (big-endian 16-bit) saat disimpan **[R]**.
3. Perubahan data di 0x1000 tidak menghasilkan delta checksum pada file SUPRA (checksum region 0xFFF0..0xFFF0) **[R]**.
4. Korupsi byte checksum 0x00 → Save → aplikasi menulis ulang menjadi `0xFF` (komplemen dua dari jumlah) **[R]**.
5. CBR1000RR: Save As gagal dengan `Error — One or more checksums could not be updated. Check checksum addressing, etc, for validity.` Meski `TPChecksumPlugin.dll` ada, definisi CBR memakai `pluginmoduleid` GUID `IRON-PONY-RK` yang bukan plug-in yang terpasang **[R]**.
6. Save yang gagal tidak membuat file tujuan separuh jadi; tidak ada rollback file sumber (sumber tidak disentuh) **[R]**.

---

## 6. Perintah hardware tanpa perangkat

| Perintah | Hasil |
|---|---|
| System Check (32991) | Dialog `All is well!` — `Everything I checked passed. This is good, but doesn't guarantee everything will work.` |
| Initialize Tuning Hardware (32854) | Tidak ada dialog; status tetap `Hardware Not Found` |
| Emulation Upload (32897) | `You messed up (I think.)` — `FAILURE: Bin is larger than emulation RAM! Perhaps you meant to use bank 8?` |
| Emulation Download (32904) | Pesan sama |
| Emulation Verify (32899) | Pesan sama |
| Enable Live Tuning (32900) | Tidak ada efek/dialog |
| Release Tuning Hardware (33104) | Tidak ada efek/dialog |
| Start/Stop Data Scan (33068) | Status `DA: Connecting...`; tanpa dialog; trackbar dinonaktifkan |
| About Plug-ins (33127) | Menampilkan `TPMoatesEmulatorPlugin.dll 1.0.0 — TunerPro Hardware Interface Plug-in` dan `ELM327PlugIn.dll 0.6.0 — ELM327 OBDII Parser Plug-in` |

**Catatan penting:** pesan 64 KB muncul sebelum ada percobaan komunikasi apa pun karena BIN 65.536 B dianggap melebihi RAM emulasi. Ini menunjukkan pemeriksaan ukuran dilakukan di host, bukan oleh perangkat.

---

## 7. Perilaku ADX saat runtime

- ADX `keihin.adx` dimuat; 11 baris Data List, 10 nama tertangkap: RPM Engine, TPS Volt, TPS Open d2 tech, Engine Temp (-40), Battery Volt, Injector Duration, ADX Arbi, Ignition (-64.0), O2 Sensor, AFR (19.50); satu baris tanpa label tidak tertangkap.
- Tab Dashboards: 9 gauge; tab Monitors: 2 chart; tab History: grid + Clear/Graph/3DCHART.
- Tanpa scan, nilai tidak bergerak; status DA berubah ke `Connecting...` saat scan dimulai lalu tidak ada data.
- Detail kontrol dan label ada di laporan 09.

---

## 8. Jaringan dan update

- Menu `Check Internet For Updates...` ada dan WININET diimpor.
- **Tidak** ada permintaan HTTP yang tertangkap selama sesi; menu tidak dijalankan.
- Klaim sah: kapabilitas ada di binary; perilaku jaringan aktual **tidak diverifikasi**.

---

## 9. State yang berubah selama pengujian (disclosure)

| File | Perubahan | Pemulihan |
|---|---|---|
| `TunerProSettings.dat` | Path BIN/XDF/ADX terakhir menunjuk work copy BE-11 | Hapus file atau set ulang via menu |
| `TPSPMSettings.dat` | `lastadxpath`/`recentdef` ke `06_ADX_AUTOPSY\WORK\keihin.adx`; `comport=\.\COM1`; `interfacetype=3` | Sama |
| `TPEmuPlugin.dat` | Menyimpan `\\.\COM1` | Sama |
| `TunerProSettingsFree.dat` | **Tidak berubah** | — |

Tidak ada backup otomatis. Instalasi dan dataset asli tidak diubah.

---

## 10. Batas runtime

- Tidak ada perangkat keras: semua jalur serial/emulator berhenti di validasi host.
- Tidak ada ECU: tidak ada frame yang dikirim/diterima.
- Tidak ada uji jaringan.
- Tidak ada uji import format lain (S19/TDF/VDF/RDT/CEE/ADS/EFILive).
- Urutan muat modul dapat berbeda antar sesi; hanya satu snapshot penuh yang diambil.
- Dialog yang tidak disentuh (mis. Registration, Help Topics) tidak diuji.

---

## 11. Keyakinan

| Aspek | Keyakinan |
|---|---|
| Menu & command ID | TINGGI (dump langsung) |
| Struktur window/kontrol | TINGGI (enumerasi langsung) |
| Preferences & nilai default | TINGGI (screenshot + dump) |
| Perilaku file & checksum | TINGGI (file hasil dapat diperiksa) |
| Perilaku hardware | TINGGI untuk "tanpa perangkat"; RENDAH untuk "dengan perangkat" |
| Jaringan | RENDAH (tidak diuji) |
