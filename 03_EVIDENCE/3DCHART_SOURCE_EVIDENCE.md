# 3D Chart Graph Remap K-Line — Source Evidence Register

Source: `C:\Users\Lord Otoy\Downloads\Mobile Devices\3D Chart Graph remap kline\3D Chart Graph remap kline`
Language: C# / .NET Framework 4.7.2–4.8, WinForms
Projects: `Kline_Remap.sln`, namespace `_3D_Chart_Graph` and `SPECIALIST_PH_TUNER`
Transport: FTDI D2XX (`ftd2xx.dll`), ISO K-line 10400 bps, bit-bang wake pulse

Key files (SHA-256 from `00_INVENTORY/SOURCE_INVENTORY.csv`):

| File | Bytes | SHA-256 |
|---|---:|---|
| `3D Chart Graph/Diag.cs` | 60,541 | `38c2844f6b573e646eee04f689bb4429891610cddecf34a2e945ff34efd56135` |
| `3D Chart Graph/Form1.cs` | 878,075 | `01fc11d11cc3af02fbf1e8f9bc75f740c07d70fb80f0ac91fe1c1d63264d326e` |
| `3D Chart Graph/Class15.cs` | 2,189 | `13956e6e554ef8907ea5e5df7b3b9e8532104778e376972742b08ede1e6abf85` |

All line references below are relative to these files.

## E-3D-01 — Transport initialisation (`Diag.cs:1139`)

```
FT_Open(0, ref ftHandle)
FT_Purge(3)
FT_SetBitMode(0,0)
FT_SetDataCharacteristics(8,0,0)
FT_SetBaudRate(10400)
FT_SetTimeouts(50,0)
FT_SetLatencyTimer(8)
FT_SetBitMode(1,1)          // bit-bang mode
FT_Write([0x00]); Sleep(70)
FT_Write([0x01]); FT_SetBitMode(0,0)
FT_SetBaudRate(10400); FT_Purge(3); Sleep(130)
```
This is the K-line wake pulse: drive low 70 ms, release, settle 130 ms.

## E-3D-02 — Request/response primitive (`Diag.cs:1271`, `1346`)

```
SendCommand(command, commandSize, ref reply, ref replySize, sleepMs)
  FT_Write(command)
  FT_SetLatencyTimer(8)
  poll FT_GetQueueStatus/FT_Read
  replyLen = buffer[commandSize + 1]     // second byte of echoed frame
  when received - commandSize == replyLen: copy tail and ValidateChecksum
  timeout = 50 + 2*commandSize ms
  FT_Purge(3) on success and on timeout
```

```
ValidateChecksum(data,n) => Checksum8BitHonda(data, n-1, 0) == data[n-1]
Checksum8BitHonda: sum bytes, return ((sum ^ 0xFF) + 1) & 0xFF
```

Verified arithmetically for every frame in `PROTOCOL_FRAME_VALIDATION.csv`.

## E-3D-03 — Live-data frames

| Method | Frame | Request |
|---|---|---|
| `dat10` | `72 05 71 10 08` | RPM, TPS, ECT, IAT, MAP, battery, VSS, injection, advance |
| `dat11` | `72 05 71 11 07` | same as dat10 plus `iac = array9[22]/10000` |
| `dat13` | `72 05 71 13 05` | reduced set with battery at `[14]` |
| `dat16` | `72 05 71 16 02` | APS/TP dual tracks, COR, ECT/IAT/MAP, battery, VSS, injection, advance |
| `dat17` | `72 05 71 17 01` | ECT fallback, MD/MODE/FIZ, table type |
| `dat20` | `72 05 71 20 F8` | O2, O2 voltage, STF, AFR; then calls `datD1()` |
| `datD1` | `72 05 71 D1 47` | BAS, SSS, SSW, gear, POM, fan, gear position |

## E-3D-04 — Decoding (verbatim formulas)

`dat10` (`Diag.cs:563`):

```
rpm   = (b[4]<<8)+b[5]
tps1  = b[6]*5/256      tps2 = b[7]/2
ect1  = b[8]*5/256      ect2 = b[9]-40
iat1  = b[10]*5/256     iat2 = b[11]-40
map1  = b[12]*5/256     map2 = b[13]
bat   = b[16]/10        vss  = b[17]
inj   = ((b[18]<<8)+b[19])/200
adv   = b[20]/2 - 64
```

`dat11` adds `iac = b[22]/10000` but does **not** pass `iac` to the grid update.

`dat17` (`Diag.cs:973`):

```
ect1 = b[12] != 255 ? b[12]*5/256 : b[8]*5/256
ect2 = b[13] != 255 ? b[13]-40   : b[9]-40
bat  = b[14]/10
inj  = ((b[15]<<8)+b[16])/200
MD   = b[18]
MODE = 1 if MD in {0x80,0x67}; 2 if 0x66; 3 if 0x3C; 4 if 0x59; 0 if 0x79; else 0
fiz  = MD < 128 ? "ON" : "OFF"
adv  = b[17]/2 - 64
vss  = b[19]
tableType = b[2]
```

`dat20` (`Diag.cs:717`):

```
o2  = (BitConverter.ToUInt16(b,4) & 0xFFFF) / 13.142708 / 1000
stf = b[5] / 128.25651
o2v = b[4] / 50.9937
afr = -5.351*o2v + 17.7
```

`datD1` (`Diag.cs:629`):

```
b[4]: 0x01 -> BAS ON, SSS ON, SSW OFF, gear "Netral"
      0x02 -> SSW ON
      0x00 -> gear "OnGear", SSW OFF, SSS OFF
b[8]: 0x00 -> POM OFF; 0x01/0x05 -> POM ON; 0x04 -> POM OFF
b[9]==1 -> fan ON
b[10]: 0x80=6 0x10=5 0x08=4 0x04=3 0x02=2 0x01=1 0x20=N 0x00="-"
```

## E-3D-05 — Polling loop and display

`LoopDat17` (`Diag.cs:516`) sequentially calls enabled `datXX` then `dat20`; `dat20` unconditionally calls `datD1()` at `Diag.cs:749` (the loop's own `datD1()` call is commented out).
`Task.Delay(10, token)` at `Diag.cs:557` is **not awaited** in a non-async method, so the loop has no explicit inter-cycle delay.

`UpdateRows2` (`Diag.cs:776`) writes 12 rows:

| Row | Parameter |
|---:|---|
| 0 | Oxygen Sensor |
| 1 | Oxygen Sensor Volt |
| 2 | Short term Fuel Trim |
| 3 | Air Fuel Ratio |
| 4 | Fast Idle Step |
| 5 | Bank Angle Sensor |
| 6 | Side Stand Switch |
| 7 | Switch Starter |
| 8 | Gear Status |
| 9 | Fuel Pump |
| 10 | Cooling Fan |
| 11 | Gear Position |

## E-3D-06 — Timeout / invalid-response behaviour

- `SendCommand` returns `false` on timeout or checksum failure, but `dat10/dat11/dat13/dat16/dat17/dat20/datD1` ignore the return value.
- Each method allocates a fresh zero-filled `array9`; on failure the decode still runs, producing `0` values. For `datD1` this maps to `POM OFF`, `SSS OFF`, `fan OFF`, `gear "-"` — i.e. **a timeout is displayed as a valid OFF state**.
- `array9[1] == 0x05` is treated as "function not supported" and disables the poller for that dat.
- No retry of a failed request exists beyond the single call.

## E-3D-07 — Remap flow (`Form1.cs`)

`flas()` at `Form1.cs:742`:

1. License gate (processor/disk-derived string vs `lic.kye` contents).
2. `InitFtdiIso()` then wake `FE 04 72 8C` and reset `72 05 00 F0 99`.
3. `GetEcuType()` by signature scan.
4. Shindengen: `ShindengenAutoChecksum()` then `ShindengenPreWriteFlash()` then `WriteFlash()`.
5. Keihin: `KeihinAutoChecksum()` then `KeihinPreWriteFlash()` then `WriteFlash()`.
6. Loop `SendCommand(probe)` until the ECU stops answering; close FTDI.

`GetEcuType()` (`Form1.cs:1042`):

```
shBinSig at EOF (90 90 90 90) -> Shindengen family
  shV850Sig  -> SHINDENGENV850   start 0x10000
  shRh850Sig -> SHINDENGENRH850  start 0x10000
               unless shStart0 at 0xA000 -> SHINDENGENRH850B
khH8cSig at EOF (57,344 or 32,768 B) -> KEIHINH8C
khM32rSig at EOF (262,144 B)         -> KEIHINM32R
otherwise                             -> KEIHINOTHER
```

`GetOffsetsFromBinType()` (`Form1.cs:365`) maps size to start/checksum offsets:

| Size | Start | Checksum |
|---:|---|---|
| 49,152 | `0x4000` | `0x7600` |
| 57,344 | `0x0` | `0xDFEF` |
| 65,536 / 98,304 | `0x8000` | `0x0` |
| 131,072 | `0xE0000` | `0xB000` |
| 262,144 Keihin H8C/M32R/MPC560 | `0x0` | `0x3FFF8` |
| 524,288 MPC560 | `0x0` | `0x7FFF8` |
| 1,048,576 SH705x | `0x0` | `0xFFFF8` |
| Shindengen (auto) | auto | auto |

## E-3D-08 — Checksums (`Form1.cs:1130`, `1721`, `2094`, `2107`)

- Shindengen: locate `... D0 07` marker, for RH850B shift `-6`; write 32-bit `0 - (sum32(0, num-4) + sum32(num, EOF))` little-endian at `num-4`.
- Keihin: `sum8(bytes, checksumOffset) + sum8(bytes, EOF-(checksumOffset+1), checksumOffset+1)`, then store `0 - sum` at `checksumOffset`.
- `Checksum8Bit`: `255 - ((sum - 1) >> 8)`.
- `Checksum8BitHonda`: `((sum ^ 255) + 1) & 255`.

## E-3D-09 — Seed/key (`Form1.cs:2023`, `2055`)

Seed is 2 bytes from the ECU response. Three 16-bit little-endian words are read from the BIN at the matched key signature:

```
key16 = (w3 * (seed16 + w1)) + (w2 != 0 ? seed16 % w2 : seed16)
```

`shRKeysig` / `shWKeysig` select recovery vs normal key. No hardcoded secret constant is involved; the "secret" is the calibration data itself.

## E-3D-10 — Erase and write

Shindengen prewrite (`Form1.cs:1174`):

```
7B 08 02 02 50 19 76 9A
7B 08 02 03 25 37 86 96
(wait 10 s)
7B 05 02 04 7A              -> challenge
7B 07 02 05 <k0> <k1> <sum>
7C 06 02 01 00 7B           -> erase
7C 0B 02 0B 00 00 00 FF FF FF 6F
7C 07 02 0E 01 00 6C
7C 06 02 04 FF 79
7C 05 02 05 78
```

Keihin prewrite (`Form1.cs:1740`):

```
7D 08 01 02 50 47 4D 94
7D 08 01 03 2D 46 49 BB
7E 05 01 02 7A
7E 07 01 03 00 00 77
7E 0B 01 0B 00 00 00 FF FF FF 6E
7E 07 01 0E 01 90 DB
7E 06 01 04 FF 78
7E 05 01 05 77
```

Write block (`Form1.cs:1348`):

- KeihinOTHER/SHINDENGEN: block 128 B, header `7E/7C`, len `0x8B`, family byte `01/02`, sub `06`, 16-bit address.
- KEIHINH8C: block 64 B, header `7B 4B 01 06`.
- KEIHINM32R: not written (`flag=false`, no address advance logic).
- Block tail: next address (2 B), `Checksum8Bit` (1 B), `Checksum8BitHonda` (1 B), frame `Checksum8BitHonda` (1 B).
- Fast write (`KEIHINOTHER` only): after `FF 25 00 20 7C 00`, switch baud to 62,500.

## E-3D-11 — Write verification

- Per block: success only if response length is 5 (`array14[1] == 5`); a 7-byte response with non-zero words is failure; two consecutive zero-word 7-byte responses also fail.
- End of write: Shindengen sends `7C 05 02 08..0D` sequence and accepts status `array14[3] == 0x0F`; Keihin sends `7E 05 01 07..0D` and accepts `0x0F`.
- **No read-back of flash contents exists.** The only integrity check is the pre-write checksum computation and the ECU's block acknowledgements.
