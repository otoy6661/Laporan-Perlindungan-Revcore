# H-Diag — Static Evidence Register

Source: `C:\Program Files (x86)\H-Diag`
Binary analysed: `HDiag.exe` (175,104 bytes, SHA-256 `10100b3491b056942aeb9e74ed604131a51c8445aea071bd0cace7270f265dcf`)
Method: PE section parsing + Capstone 32-bit disassembly, VA-corrected.
No execution, no modification, no USB/ECU interaction.

## E-HD-01 — PE layout

| Item | Value |
|---|---|
| Image base | `0x400000` |
| `.text` | VA `0x1000`, file `0x400`, size `0xF000` |
| `.rdata` | VA `0x10000`, file `0xF400`, size `0x10400` |
| Toolchain | MSVC x86, Qt 5 (Qt5Core/Gui/Widgets/Network), libusb-1.0 + FTDI backend |

## E-HD-02 — Live-data table row map (labels)

The table model is initialised at VA `0x402407`–`0x40295c`. Each label string is loaded with `push <VA>` and stored into a per-row slot at `[list + 0x60 + 4*row]`.

| Row | String VA | Label (verbatim) | RevCore need |
|---:|---|---|---|
| 0 | `0x412c40` | `STF - Campuran Bahan Bakar` | 9 |
| 1 | `0x412c5c` | `POM - Pompa Bahan Bakar` | 4 |
| 2 | `0x412c74` | `SS - Standar Samping` | 6 |
| 3 | `0x412c8c` | `STS - Switch Starter` | 5 |
| 4 | `0x412ca4` | `SSW - Switch Starter` | 5 |
| 5 | `0x412cbc` | `FIS - Fast Idle Switch` | 7 |
| 6 | `0x412cd4` | `MOD - Mode Altitude` | 10 |
| 7 | `0x412ce8` | `ALT - Koreksi Altitude` | 10 |
| 9 | `0x412d14` | `SCS - Service Check Signal` | — |
| 10 | `0x412d30` | `MIL - Jumlah Kode Error` | — |
| 11 | `0x412d48` | `MILV` | — |
| 12 | `0x412d50` | `IAC - Katup Udara Masuk` | 8 |
| 13 | `0x412d68` | `VSS - Sensor Kecepatan` | — |
| 15 | `0x412d84` | `EVA - Status Evaporator` | — |
| 19 | `0x412de8` | `TPSV1` | — |
| 20 | `0x412df0` | `TPSV2` | — |
| 27 | `0x412e80` | `EGCV - Kontrol Katup Gas Buang` | — |
| 29 | `0x412d00` | `GG - Gigi Transmisi` | — |

Row 8 is empty (separator). The first eight rows are exactly the parameter group requested by RevCore 4–10 (FISV/FID is represented only as `FIS`, not `FID`).

## E-HD-03 — Live polling loop (VA `0x407329`–`0x407410`)

Counter at `0x421420` selects the request:

| Counter | Construction | Frame |
|---:|---|---|
| `< 0x0C` | `word 0x0572`, `byte 0x60`; second call writes `word 0x2603` | `72 05 60 03 26` |
| `== 0x0C` | `word 0x0572`, `byte 0x71`; second call writes `word 0x1800` | `72 05 71 00 18` |
| `== 0x0D` | `word 0x0572`, `byte 0x00`; second call writes `word 0x98F1` | `72 05 00 F1 98` |

After construction: `push 0x64` → delay helper `0x404AB0` (100 ms), then `call 0x409760` (read), then counter increment. At counter `0x0E` the cycle closes and the UI status/connection state is updated with a 1 s pause (`0x3E8`).

## E-HD-04 — DTC / auxiliary request builder (VA `0x405120`)

The function takes an index 0..5 and sends:

| Index | Frame | Meaning (label as coded) |
|---:|---|---|
| 0 | `72 07 72 D0 00 0E 37` | DTC page 0 |
| 1 | `72 05 73 00 16` | DTC page 1 |
| 2 | `72 05 73 01 15` | DTC page 2 |
| 3 | `72 05 74 01 14` | DTC page 3 |
| 4 | `72 07 72 D1 00 06 3E` | DTC page 4 |
| 5 | `72 07 72 D0 14 02 2F` | DTC page 5 |

Index 1 is used by the response handler as the "read current DTC page" request (call at `0x405120` with `[0x421424]`, then 50 ms delay).

## E-HD-05 — Response dispatch (VA `0x405F90` onward)

Dispatch on key `edx`; response buffer in `edi`:

| Key | Table update | Evidence |
|---:|---|---|
| 8 | row `0x0C` col 3 ← text at `edi+0x0D`; row `0x14` col 2 ← `edi+1` | `0x405F90`–`0x405FDF` |
| 0x14 | row `0x0F` col 3 ← `edi+0x0D`; row `0x1B` col 2/3 ← `edi+0x0B`/`edi+0x0C`; row `0x1E` ← `edi` | `0x405FDF`–`0x4060A4` |
| 0xC | string-conversion path over `edi`, no direct byte→row evidence | `0x4060A4`–`0x4066B8` |
| 7 | string-conversion path over `edi-1` | `0x4066B8`–`0x406A91` |

Row `0x0C` is `IAC - Katup Udara Masuk`. The values are converted by a Qt string constructor that stops at NUL (`push 0` length), i.e. the response carries ASCII decimal text, not raw binary, for these rows.

**Boundary:** only the rows listed above are proven. The mapping for STF/POM/SS/STS/SSW/FIS/MOD/ALT values is not proven from this dispatch alone.

## E-HD-06 — Handshake bytes (partial)

At `0x405F28`–`0x406A9x` a state machine sends short frames whose first fields are `0x23/2`, `0x24/2`, `0x1D/2`, and for selected states `0x0D/3`, `0x14/2`, `0x10/3`, `0x1B/2`, `0x1B/3`, `0x1E/2`. These are consistent with the 3D Chart `FE 04 72 8C` wake plus session-open sequences, but the exact byte order was not fully reconstructed. Status: RECONSTRUCTED, not verified.

## E-HD-07 — Capacity / absence findings

| Search | Result |
|---|---|
| `FID` (case-sensitive, ASCII) | NOT FOUND in `HDiag.exe` |
| `Relay` (case-sensitive) | NOT FOUND as a live-data label |
| `FIS` | Found: `FIS - Fast Idle Switch` |
| `Altitude` | Found: `MOD - Mode Altitude`, `ALT - Koreksi Altitude` |
| Write/set command for altitude | NOT FOUND; the polling loop contains read requests only |
| `login.ini` | 141,022 bytes; license-code list. Contents intentionally not reproduced. |
| `ANALIST_PRO - keygen.exe` (other source folder) | Exists; not executed, not analysed, not published. |

## E-HD-08 — Files not analysed

| File | Reason |
|---|---|
| `HDiag.exe,` (313,426 bytes) | Variant copy; string extraction performed, but PE pointer search aborted due to different section layout |
| `unins000.dat` | Installer metadata, no protocol relevance |
| `usb_driver/*` | Signed vendor driver package, not analysed beyond inventory |
| `login.ini` | Sensitive license data; only size/hash recorded |
| Qt DLLs, ICU, MSVC runtime | Third-party runtime, not analysed |
