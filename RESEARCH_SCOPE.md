# BE-12 — RESEARCH SCOPE

## 1. Tujuan

Autopsi menyeluruh FLASHPRO.inc dan perbandingan teknis berbasis bukti dengan TunerPro RT dan RevCore: identitas, anatomi, struktur internal, komunikasi ECU/hardware, pengolahan BIN/ROM/MAP, identifikasi ECU, Live Data, checksum, flashing/recovery, arsitektur lisensi; lalu gap analysis dan prioritas pengembangan RevCore.

## 2. Objek

| Objek | Lokasi | Akses |
|---|---|---|
| FLASHPRO.inc | `C:\Program Files (x86)\FLASHPRO.inc` | Salinan kerja di `00_SOURCE_INVENTORY/APP_COPY`; instalasi asli tidak diubah |
| TunerPro RT | `C:\Program Files (x86)\TunerPro RT` | Baseline BE-11 (`REVCORE_BE11_TUNERPRO_AUTOPSY`) |
| RevCore | Source lokal terbaru yang tersedia | Akan diverifikasi versi/commit saat FASE IV–V |

## 3. Ruang lingkup yang dapat diakses

- 7 file terpasang (77.239.034 B termasuk duplikat payload U+00A0).
- 3 executable = wrapper VB6; 3 payload asli (2 tersedia sebagai file, 1 di ekstraksi installer).
- Installer asli tidak tersedia di mesin; bukti installer memakai hasil ekstraksi sebelumnya (`Qoder\flashpro_analysis\embedded_2026`), dengan hash dihitung ulang.
- Payload dikemas Enigma Protector 5.x → pembacaan kode statis terbatas.
- Tidak ada ECU, adapter, atau hardware komunikasi yang terhubung.

## 4. Di luar lingkup / dilarang

- Menulis ke ECU fisik.
- Membuat/menjalankan crack, keygen, activator, atau bypass lisensi.
- Membuka material kunci privat atau artefak sensitif Enigma.
- Mengubah instalasi FLASHPRO.inc, TunerPro RT, atau source RevCore.
- Publikasi/push/ZIP final tanpa persetujuan eksplisit pemilik.

## 5. Standar bukti

Setiap klaim diberi status: SOURCE VERIFIED, STATIC VERIFIED, RUNTIME VERIFIED, SIMULATION VERIFIED, HARDWARE VERIFIED, NOT FOUND, NOT TESTED, BLOCKED. Klaim tanpa salah satu status tersebut tidak dimasukkan sebagai temuan. Data sintetis diberi label `SYNTHETIC TEST DATA`.

## 6. Urutan pelaksanaan (mengikuti work order §13)

1. Identifikasi & inventarisasi — **selesai**
2. Pemeriksaan integritas & preservasi — **selesai (baseline)**
3. Autopsi statis — berjalan
4. Analisis struktur internal — berjalan
5. Runtime analysis — belum
6. Eksperimen BIN/data — belum
7. Komunikasi & hardware — belum
8. Pendalaman kemampuan ECU — belum
9. Komparasi TunerPro RT — belum
10. Komparasi RevCore — belum
11. Gap analysis — belum
12. Prototipe & automated test — belum
13. Audit bukti & coverage — belum
14. Laporan final — belum

## 7. Batas yang diketahui sejak awal

| Batas | Konsekuensi | Status |
|---|---|---|
| Enigma packing | Nama fungsi/alur/protokol tidak terbaca statis | Dinyatakan; runtime & observasi eksternal dipakai |
| Tanpa hardware/ECU | Klaim protocol/ECU/flashing tidak dapat diverifikasi hardware | Pending; tidak akan diklaim |
| Installer tidak ada | Verifikasi installer memakai artefak ekstraksi sebelumnya | Dinyatakan |
| Artefak lisensi sensitif | Tidak dianalisis | Dikecualikan sesuai work order |
