# Ringkasan Hasil Unit Test (JVM)

Tanggal pengambilan ringkasan: 2026-11-20 (WIB).

Sumber: `RevCore_work/app/build/test-results/testDebugUnitTest/TEST-*.xml`
(39 file XML, timestamp hasil `2026-11-19T23:45Z` = 2026-11-20 06:45 WIB).

## Agregat

```
files=39  tests=330  failures=0  errors=0  skipped=0
```

Dihitung ulang dari atribut `tests`, `failures`, `errors`, `skipped` pada setiap
`<testsuite>` XML. Skrip: PowerShell `XmlDocument` (tidak ada data yang
ditranskripsi manual).

## Baseline dan tambahan

| Kondisi | Jumlah test |
|---|---:|
| Baseline sebelum fitur Keyless | 315 |
| Sesudah fitur Keyless | 330 |
| Tambahan | 15 |

Tambahan 15 test:

| Suite | Jumlah | Cakupan |
|---|---:|---|
| `core.keyless.KeylessFrameCodecTest` | 9 | Frame init/security/read, checksum Keihin & Shindengen, posisi byte data, balasan pendek, gema, offset model |
| `core.keyless.KeylessIdDecoderTest` | 6 | PCX high-word, padding 9 digit, Keihin `000016386`, midpoint nol, negatif, routing keluarga |

## Suite yang relevan dengan laporan ini

| Suite | Relevansi |
|---|---|
| `core.comm.LiveActuatorDecoderTest` | Pemetaan Mode `1..4`; di luar itu `null` (termasuk `0` dan `5`) |
| `core.comm.CommActivityPolicyTest` | Gating polling/recovery saat foreground |
| `core.comm.LivePollPolicyTest` | Interval, ambang 4 kegagalan, backoff |
| `core.usb.AdapterConnectionPolicyTest` | Keputusan auto-connect & teardown |
| `core.comm.EcuSessionManagerTest` | Transaksi sesi & lifecycle |
| `core.comm.KlineWireEngineTest` | Timeout baca / perilaku wire |
| `security.IntegrityGateTest` dan suite `security.*` | Kode integritas tidak diubah (test lama tetap lulus) |

## Batasan

- Unit test berjalan di JVM; tidak menyentuh USB, adapter, atau ECU.
- Lulusnya unit test **bukan** bukti fitur berfungsi di kendaraan.
- Log `testDebugUnitTest.log` pada folder ini mencatat task `UP-TO-DATE`
  (tidak menjalankan ulang); angka diambil dari XML hasil eksekusi sebelumnya.
