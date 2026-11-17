# BE-10 — Deep Technical Research: ADX + 3D Chart Graph + ECU Software

Workspace: `C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH`
Work order: BE-10 (17 November 2026, authorized for analysis)
Predecessor: BE-09 (`C:\Users\Lord Otoy\Documents\REVCORE_EXTERNAL_ECU_RESEARCH`)

## Purpose

BE-10 continues the BE-09 baseline with mechanism-level research, not another inventory. It covers:

1. Every ADX file in `REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX\ADX-D2 TECH` (and the duplicate in the parent folder).
2. The complete source tree of `3D Chart Graph remap kline`, including recursively extracted ZIPs, source code, embedded BIN resources, and the 152-model map database.
3. Unfinished BE-09 areas: FTDI/K-Line transport, live-data decoding, checksums, read/write/recovery, ECU identification, Smart Key EEPROM, and protection/licensing.

All work is static. No researched EXE, installer, BAT, CMD, VBS, DLL, or OCX was executed. No physical ECU was contacted. No file in the original dataset or in the RevCore project was modified.

## Folder map

| Path | Contents |
|---|---|
| `SOURCES/ADX_D2_TECH/` | Two unique ADX files, unmodified copies |
| `SOURCES/3D_CHART_GRAPH/` | Solution, project source (208 files), and two ZIP archives |
| `EXTRACTED_ZIPS/` | Both ZIPs extracted independently, 37 files each |
| `EXTRACTED_ARCHIVES/` | The ADX 7z archive extracted separately (1 file) |
| `SOURCES/ADX_D2_TECH/ARCHIVE/` | Original ADX 7z archive, unmodified copy |
| `ANALYSIS/` | Extraction/parse/verification scripts and intermediate CSVs |
| `PROTOTYPES/src/BE10Tools/` | .NET 8 prototype (ADX inspector, map reader/editor, checksums, live-data decoders, frame parser, tests) |
| `PROTOTYPES/testdata/` | Read-only test copies (2 ADX, 5 BIN, 2 CSV) |
| `PROTOTYPES/RESULTS/` | Self-test log, test register, table validation, graph export |
| `REPORTS/` | Sensor catalog and SHA-256 manifest (the other 13 mandatory outputs are at the workspace root) |

## Status vocabulary

Only these statuses are used in registers:

`FOUND_IN_SOURCE`, `FOUND_IN_DOCUMENTATION`, `STATICALLY_ANALYZED`, `PROTOTYPE_CREATED`, `SAMPLE_TEST_PASSED`, `SAMPLE_TEST_FAILED`, `HARDWARE_PENDING`, `UNKNOWN_AFTER_ANALYSIS`, `NOT_FOUND_AFTER_MEANINGFUL_SEARCH`, `BLOCKED_BY_ACCESS_REQUIREMENT`.

`IMPLEMENTED` is never treated as `VERIFIED`. A decoder that is written but not tested against a physical ECU is `STATICALLY_ANALYZED` or `HARDWARE_PENDING`, never "working".

## Reproduce the prototype results

Requires .NET SDK 8 (present: 8.0.204).

```
cd PROTOTYPES/src/BE10Tools
dotnet build -c Release
dotnet run -c Release --no-build -- selftest
dotnet run -c Release --no-build -- validate
dotnet run -c Release --no-build -- catalog
dotnet run -c Release --no-build -- adx "..\..\testdata\ADX KEIHIN BE.adx"
```

Outputs:

- `PROTOTYPES/RESULTS/SELFTEST.txt` — 26/26 tests passed, with input, method, expected, actual, hashes.
- `PROTOTYPES/RESULTS/BE10_PROTOTYPE_TESTS.csv` — machine-readable test register.
- `PROTOTYPES/RESULTS/BE10_TABLE_VALIDATION.csv` — 5 sample BINs validated against the 152-model map database.
- `PROTOTYPES/RESULTS/BE10_K1AA_FUEL_GRAPH.csv` — 35 × 29 exported fuel surface.
- `REPORTS/BE10_SENSOR_LIVE_DATA_CATALOG.csv` — 45 live-data channels with formulas and evidence.

## What is proven, what is not

Proven statically and by sample tests:

- ADX container layout, sizes, family tag bytes, entropy, duplicate relationship.
- Map extraction from BIN using the researched app's own offsets/scalings, for 5 real samples including one big-endian table.
- K-Line frame format, length semantics, checksum vectors, Keihin/Shindengen checksum algorithms, Shindengen seed/key arithmetic.
- Live-data byte offsets and conversion formulas, including the fact that AFR is a software estimate.
- Bilateral edit round-trip on a copy; source hashes unchanged.

Not proven / not attempted:

- ADX payload contents. The payload is encrypted; decryption/key recovery is prohibited and was not attempted (`BLOCKED_BY_ACCESS_REQUIREMENT`).
- Any behavior against a physical ECU (`HARDWARE_PENDING`).
- The internal code of packed executables (PRO Remap_BE, SCANNER HONDA, HondaECU payloads) beyond metadata/strings/dependencies (`UNKNOWN_AFTER_ANALYSIS` where applicable).
- License keys, machine-binding values, and `lic.kye` contents (not copied, not printed).

## Safety rules observed

1. No EXE/installer/BAT/CMD/VBS/foreign script executed.
2. No DLL/OCX loaded or executed.
3. Static analysis first; dynamic analysis or emulation is not performed and would require separate owner approval.
4. Windows Defender was not disabled or modified.
5. No foreign driver installed.
6. No remote access used.
7. Original source files were never modified.
8. The RevCore main project was never modified.
9. No files were deleted from the source dataset.
10. Nothing was uploaded to the public internet.
11. No credential, password, private key, or license value was copied into any report.
12. No command that writes to a physical ECU was executed.

## Key deliverables

| File | Purpose |
|---|---|
| `BE10_EXECUTIVE_SUMMARY.md` | One-page result summary |
| `BE10_FINAL_RESEARCH_REPORT.md` | Full report answering the nine required questions |
| `BE10_ADX_ANALYSIS.md` | ADX container research |
| `BE10_3D_CHART_SOURCE_ANALYSIS.md` | Source/architecture/protection analysis |
| `BE10_ECU_PROTOCOL_FINDINGS.md` | K-Line, checksums, security, write/recovery |
| `REPORTS/BE10_SENSOR_LIVE_DATA_CATALOG.csv` | 45 decoded channels |
| `BE10_BIN_XDF_ADX_RELATIONSHIP.md` | Cross-format relationship and validation |
| `BE10_SOFTWARE_DEEP_ANALYSIS.md` | The 14 BE-09 targets, deepened |
| `BE10_PROTOTYPE_RESULTS.md` | Prototype design and 26 test results |
| `BE10_REVCORE_INTEGRATION_RECOMMENDATIONS.md` | What RevCore can adopt, under which gates |
| `BE10_TECHNICAL_GAP_ANALYSIS.md` | Specific remaining gaps |
| `BE10_RESEARCH_STATUS.csv` | Status register |
| `BE10_ARTIFACT_INDEX.md` | Every artifact with hash |
| `REPORTS/BE10_SHA256_MANIFEST.csv` | 552-entry provenance manifest |
| `README.md` | This file |

