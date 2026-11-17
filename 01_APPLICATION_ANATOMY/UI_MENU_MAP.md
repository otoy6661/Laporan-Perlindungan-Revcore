# Peta UI & Menu — FLASHPRO (Windows)

**Status:** SOURCE VERIFIED untuk nama kontrol/menu (dari metadata + handler event) dan string; RUNTIME VERIFIED hanya untuk gerbang aktivasi.
**Catatan:** Nama menu diambil dari nama metode handler `*ToolStripMenuItem_Click`, nama kontrol dari string/metadata, dan label dari string UI. Tidak ada handler yang dieksekusi; perilaku tiap menu adalah **inferensi dari namanya**, bukan hasil pengamatan.

---

## 1. Jendela & form yang ada

| Form | Bukti | Isi yang terbaca |
|---|---|---|
| `Form1` | 292 metode, 334 field | Jendela utama "FLASHPRO ECM MANAGER \|" |
| `MbActivationForm` | 14 metode; UIA dump | "ECM MANAGER - Activation", "TEAM TECH TUNNER", input Nama Bengkel, Activation Key, Cancel/Activate |
| `SplashScreen` | 16 metode | splash + disclaimer ("Saya menyetujui syarat dan ketentuan", "Jangan tampilkan lagi saat startup", NEXT) |
| `AboutForm` | 26 metode | "INFORMASI APLIKASI", kontak layanan, disclaimer, "itech © 2025" |
| `LicenseForm` | 35 metode | aktivasi berbasis HWID |
| `Diag` | 51 metode | DTC, Start/Stop, Reset ECM, Exit |
| `DYNO` | 30 metode | Simple Dyno: Start/Stop/Refresh/Delete, Max HP/RPM/AFR/TQ |
| `Form11` | 89 metode | Smartkey/EEPROM: read/write/copy SCU |
| `ChartLiveMap` | 42 metode | chart live RPM/TPS/AD/AFR + pointer |
| `FormChart` | 12 metode | chart tambahan |
| `Graph3DMainForm` (Plot3D) | 27 metode | grafik 3D map, pilihan warna/raster/data source |
| `ReadECU` | 17 metode | pembacaan 48 KB |
| `Reset` | 18 metode | reset counter/recovery |
| `LogForm` | 6 metode | log |
| `FormReleaseNotes` | 6 metode | catatan rilis |
| `FormUpdatePrompt`, `FormUpdateProgress` | 5 + 7 metode | prompt update & progres |
| `TutorialReadIDForm`, `TutorialSimpleForm` | 25 + 7 metode | tutorial Smartkey/Read ID |

## 2. Menu utama (dari handler)

| Menu (inferensi nama) | Handler | Catatan |
|---|---|---|
| File → Open | `openFileToolStripMenuItem_Click` | membuka `.bin`/`.map` |
| File → Save | `saveFileToolStripMenuItem_Click` | simpan |
| File → Save As | `saveAsToolStripMenuItem_Click` | dialog simpan |
| Map → Base Map | `baseMapToolStripMenuItem_Click` | pilih base map dari database |
| Map → Auto Mapping | `Automaping_Click_1` | auto-map (async `d__417`) |
| Map → Compare to Database | `compareToDataBaseToolStripMenuItem_Click` | bandingkan dengan DB |
| View → RPM / TPS / IAP (2D) | `rpm2d_Click`, `tps2d_Click`, `iap2d_Click` | tampilan 2D per sumbu |
| View → Show All | `show_all_Click` | tampilkan semua tabel |
| View → 3D | `show3d` | grafik 3D |
| Breakpoint → RPM / TPS / IAP | `breakpoinRPM…`, `breakpointTPS…`, `breakpointIAP…` | editor breakpoint sumbu |
| Fuel (Feul) | `feulToolStripMenuItem_Click` | tabel bahan bakar |
| Ignition 1–5 | `ignition4/5ToolStripMenuItem_Click` | tabel pengapian (handler 1–3 bernama `toolStripMenuItem*`) |
| Limiter 1–7 | `limiter6/7ToolStripMenuItem_Click` | pembatas RPM per gigi/mode |
| O2 Sensor ON/OFF | `offBASSensor…`, `offMAPSensor…`, `offECT…`, `offIAT…`, `offVSS…` | toggle sensor (BAS/MAP/ECT/IAT/VSS) |
| Mode 4 OFF | `offMode4ToolStripMenuItem_Click` | mematikan mode 4 |
| RPM vs TPS 1/2, RPM vs IAP | `rpmVsTps1/2…`, `rpmVsIAP…` | grafik pembanding |
| Diagnostic | `diagnosticToolStripMenuItem_Click`, `diagnosticToolStripMenuItem1_Click` | buka `Diag` |
| Smartkey | `smartkeyToolStripMenuItem_Click`, `smartkeylessToolStripMenuItem_Click` | buka `Form11` |
| Smartkey Yamaha | `smaerkeyYamahaToolStripMenuItem_Click` | **ada entri Yamaha** meski produk diposisikan Honda |
| Smartkey Suzuki 2402 | `smartkeySuzuki2402ToolStripMenuItem_Click` | entri Suzuki (EEPROM 24C02?) |
| Reset Count | `resetcount_Click` | reset penghitung flash |
| Delete Image | `hapusGambarToolStripMenuItem_Click` | hapus gambar latar |
| Options | `optionToolStripMenuItem_Click` | pengaturan |
| Software → Update | `updateSoftwareToolStripMenuItem_Click` | updater GitHub (async `d__439`) |
| Software → Info | `infoSoftwareToolStripMenuItem_Click` | About |
| Simple Dyno | `simpleDynoToolStripMenuItem1_Click` | buka `DYNO` |

Menu bernama generik (`toolStripMenuItem5..22`) tidak dapat dipetakan ke label tanpa IL; dicatat sebagai **NOT VERIFIED**.

## 3. Kontrol jendela utama (dari string & field)

- **Editor tabel**: `DataGridView1` (klik, edit sel, keydown, copy/paste multi-sel), kolom **Parameter**/**Value**, tombol **Save Value**, input ekspresi **Eval** (fungsi `sin/cos/log/pow/…` dikompilasi runtime).
- **Live monitor**: label `RPM`, `TPS`, `AD`, `AFR`, `MAX RPM/TPS/AD/AFR`, `chkLivePointer` (pointer live di tabel), `Pause/Resume Auto-Scroll`.
- **Status/koneksi**: indikator `connececm`, `CloseClass15Handle`, `SetTombolXEnabled`, panel ECU (`flowPanelECU`), pencarian `txtSearch`.
- **Progres**: `ModernProgressBar`, `CircularProgressBar`, `WeightedProgress` (dipakai saat flashing/update).
- **Toast/notifikasi**: `ShowToast`, `CustomMessageBox`, `CustomToolTip`.
- **Chart**: `AGauge` (gauge analog), `Plot3D.Graph3D`, `ChartLiveMap`, tema warna "Warm Fire / Ice Cool / Toxic Alien / Custom Stealth".
- **Identitas ECU**: label `ECM ID`, `ECM PART CODE`, `Star`, `Checksum`, tombol baca (`button1_Click_1` → `ReadECU`), status `ID tidak valid`, `Unknown Part Code`.

## 4. Panel diagnostik (`Diag`)

Kontrol: `button1` **Start**, `button2`, `button4` **Reset ECM**, `button3` **Exit**, `listBox1` **DTC**, tombol **STOP**.
Fungsi yang terbaca: baca DTC (kode + deskripsi, 37 entri), stream data (lihat `06_LIVE_DATA_AUTOPSY`), reset ECM, hentikan thread dengan aman ("Gagal menghentikan resource").

## 5. Panel Smartkey (`Form11`)

Aksi (`Form11Action`): read/write/copy EEPROM; tipe `EepromType` AT24C02/AT24C04; pin I2C bit-bang (SCL=4, SDA drive=0x10, SDA sense=0x08); output ke `C:\READ ID SMARTKEY\`; tutorial `TutorialReadIDForm`.
Entry menu Yamaha/Suzuki menunjukkan panel ini tidak eksklusif Honda.

## 6. Alur layar (inferensi, RUNTIME sebagian)

```
Wrapper VB6 → payload (Enigma) → Splash/disclaimer → [MbActivationForm | LicenseForm]
   → Form1 (dashboard, butuh ECM terhubung untuk fitur ECM)
       ├─ Map editor (buka BIN/base map, edit, simpan .bin/.map)
       ├─ Diag (DTC, live)
       ├─ DYNO
       ├─ Smartkey (Form11)
       ├─ ChartLiveMap / Graph3D
       └─ Update (GitHub)
```

Bukti runtime: hanya sampai `MbActivationForm`; setelah itu **BLOCKED (lisensi)**.
