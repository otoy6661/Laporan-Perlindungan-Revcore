# REVCORE — FINAL 10-GATE INTEGRITY EXAMINATION, ANOMALY DIAGNOSTICS & STRICT FAIL-CLOSED

## FINAL COMPLIANCE REPORT

Report ID: `REVCORE-FINAL-INTEGRITY-COMPLIANCE`
Date: 2026-11-16
Project: `C:\Users\Lord Otoy\Documents\Qoder\work\revcore`
Instruction executed: owner master instruction "REVCORE — MASTER EXECUTION INSTRUCTION / FINAL
10-GATE INTEGRITY EXAMINATION, ANOMALY DIAGNOSTICS & STRICT FAIL-CLOSED".

---

## 1. AUTHORIZATION AND SCOPE

The owner authorized **source implementation and testing only**. This work executed exactly:

| Action | Executed? |
|---|---|
| Application source changes | Yes |
| Test source changes | Yes |
| JVM unit tests (`:app:testDebugUnitTest`) | Yes |
| `:app:compileDebugKotlin` | Yes |
| `:app:compileReleaseKotlin` | Yes |
| Build an official APK | **No** |
| Sign an APK | **No** |
| Export a release APK | **No** |
| Publish an APK | **No** |
| Change `applicationId` | **No** |
| Regenerate/modify the nine operational keys | **No** |
| Change the release signing key or certificate identity | **No** |
| Modify ECU protocol or verified transport | **No** |
| Upload keys/passwords to any service | **No** |

**No APK was built, signed, exported, or published under this authorization.** The only APK in
`dist/` is the pre-existing `RevCore build 151126.apk` (mtime 2026-11-15 19:51,
SHA-256 `1128af1ff7bc15f1f614e6e177fd2a24bb0ef3783eed0373d5687eb6adfa86aa`). It does not contain
the changes in this report.

Status vocabulary below is restricted to: `NOT_STARTED`, `IN_PROGRESS`, `IMPLEMENTED`,
`VERIFIED`, `BLOCKED`, `NOT_IMPLEMENTED`. Evidence classes: SRC (source inspection), UT (JVM test
executed), COMPILE, IT (instrumented — none), EMU (none), DEV (none), HW (none), DOC, PROCESS.

`IMPLEMENTED` is never used as a synonym for `VERIFIED`.

---

## 2. CAPABILITY ASSESSMENT

| Area | Capability in this environment | Consequence |
|---|---|---|
| Gate logic, report model, diagnostics text | Full JVM test capability | L1 and diagnostics rules are VERIFIED by executed tests |
| Kotlin compilation | Both variants compile offline | No signature/API mismatch in debug or release |
| Compose UI rendering, dialogs, buttons | No `androidTest` source set; no Compose UI-test artifacts in the offline Gradle cache | All UI behavior is SRC only; instrumented tests BLOCKED |
| Marker/record store, Keystore, `Context` flows | No Robolectric/Keystore harness available | Container logic JVM-tested; lifecycle flows BLOCKED |
| Rotation, process death, Clear Data | Requires device/emulator | BLOCKED |
| APK mutation, MT Manager repack, timing | Requires a built signed APK | BLOCKED (not authorized) |
| FTDI/K-Line/ECU/Live Data/DTC/MAP | Requires physical adapter and motorcycle | BLOCKED |

---

## 3. REQUIREMENT-BY-REQUIREMENT COMPLIANCE

### 3.1 Part 1 — Visible examination

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| MI-01 | The examination is shown at launch whenever a FULL examination is required, in every build. | IMPLEMENTED | SRC: `MainViewModel.launchStartup` always publishes `StartupState.Examining(initialPhases())`; `RevCoreIntegrity` debug branch passes the observer. No hidden FULL exists. |
| MI-02 | Exact title `PEMERIKSAAN INTEGRITAS REVCORE`. | IMPLEMENTED | SRC: `IntegrityExaminationScreen.kt:57`. Not instrumented. |
| MI-03 | Exactly ten rows, initial text `GERBANG n - MENUNGGU`. | IMPLEMENTED | SRC: `GateId.entries` → `initialPhases()` all `WAITING`; row text built from number + `phaseLabel`. |
| MI-04 | Real states only: `MENUNGGU`, `MEMERIKSA`, `TERVERIFIKASI`, `GAGAL` (plus debug-only `BYPASS`). | IMPLEMENTED | SRC + UT: `phaseLabel` exact for all six phases; `SKIPPED` renders `GAGAL`. |
| MI-05 | No gate names, algorithms, hashes, or technical detail in the examination rows. | IMPLEMENTED | SRC: row renders only `GERBANG n - <state>`; no subtitle, source, counter. |
| MI-06 | No fabricated progress and no artificial delay. | IMPLEMENTED | SRC: rows change only on `GateObserver` events; no `delay()` in the examination path. |
| MI-07 | Gate 8 is the final aggregate displayed last. | VERIFIED | UT: `IntegrityDiagnosticsTest.only failed gates are reported and gate eight is last`; `GateStagingTest` aggregation cases. |
| MI-08 | Staged order `1,2,3,4,5,6,7,9,10,8` preserved. | VERIFIED | UT: existing `GateStagingTest` order tests pass in the 308-test run. |
| MI-09 | UI observes real evaluator events; observer never null on a FULL. | IMPLEMENTED | SRC: `launchStartup` creates `GateObserver` unconditionally and passes it to `evaluateStartup`; `RevCoreIntegrity` forwards it to `runStagedEvaluation`. |

### 3.2 Part 2 — Success outcome

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| MI-10 | Success only after a genuine 10/10 (`report.passed`). | IMPLEMENTED | SRC: `handleStartupOutcome` requires `report.passed`; `passed` requires all gates PASS and Gate 8 PASS (UT-pinned). |
| MI-11 | Separate window with exact text `Pemeriksaan Integritas Berhasil` and one `LANJUTKAN` button. | IMPLEMENTED | SRC: `IntegritySuccessDialog.kt`; non-dismissible; only one button. |
| MI-12 | No auto-continue. | IMPLEMENTED | SRC: only `acknowledgeIntegrity` advances; state stays `AwaitingAcknowledgement`. |
| MI-13 | Marker and record committed only after `LANJUTKAN`. | IMPLEMENTED | SRC: evaluation returns an in-memory `InstallationCommit`; write occurs only inside `acknowledgeIntegrity`. No commit-order test executed (needs `Context`). |
| MI-14 | After `LANJUTKAN`, continue the existing loading/initialization. | IMPLEMENTED | SRC: `runInitialization` reuses `LoadingScreen`, DB/storage/USB setup. |

### 3.3 Part 2 — Failure outcome

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| MI-15 | Separate window titled exactly `PEMERIKSAAN INTEGRITAS GAGAL`. | IMPLEMENTED | SRC: `IntegrityFailureScreen.kt:56`. |
| MI-16 | List every failed gate. | VERIFIED | UT: `forReport` returns exactly the FAIL/BYPASS gates in display order. |
| MI-17 | Dynamic anomaly headings, exact strings, only for detected categories. | VERIFIED | UT: all seven headings asserted verbatim; gate→category mapping asserted; Gate 8 has no category. |
| MI-18 | Never the generic combined sentence `DITEMUKAN PERUBAHAN PADA SUSUNAN UI / SIGNING APK / SUSUNAN FILE / ISI DATABASE`. | IMPLEMENTED | SRC + UT: no such string exists in source; per-gate blocks replace it; aggregate gate prints only `Hasil keseluruhan tidak memenuhi seluruh syarat pemeriksaan.` |
| MI-19 | Show actual evidence (paths, expected/actual hashes). | IMPLEMENTED | SRC + UT: Gate 1 detail embeds official and actual SHA-256; sanitizer preserves paths and SHA-256 values (asserted). |
| MI-20 | Never invent details. | VERIFIED | UT: empty detail ⇒ `Perubahan terdeteksi, detail tidak dapat diidentifikasi.`; aggregate line is fixed. |
| MI-21 | Never expose AES/HMAC/private keys/passwords/Keystore/internal mechanism terms. | VERIFIED | UT: sanitizer removes `policy`, `HMAC`, `AES`, `GCM`, `Keystore`, `DEX`, `Golden vector` from a mixed diagnostic string. SRC: no key material enters `GateResult.detail`. |
| MI-22 | Only one action: `KELUAR`. | IMPLEMENTED | SRC: single button `btn_exit_integrity`; no retry/bypass/loading/dashboard path. |
| MI-23 | `KELUAR` cancels work, stops Live Data, disconnects USB/FTDI/K-Line, prevents DB/ECU init, closes task, terminates process. | IMPLEMENTED | SRC: `shutdownAfterFailure()` cancels startup/monitor/ignition/stream/identify/adapter jobs, stops streaming, `disconnect()` closes the transport driver, clears `pendingCommit`; Activity then `finishAndRemoveTask()` + `exitProcess(0)`; `onDestroy` unregisters the USB receiver. Not device-tested. |
| MI-24 | No automatic retry and no silent recovery. | IMPLEMENTED | SRC: `recheckIntegrity()` removed; `Failed` is terminal until a new launch. |

### 3.4 Part 3 — Debug behavior

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| MI-25 | Debug builds also show the visible examination. | IMPLEMENTED | SRC: debug branch calls `runStagedEvaluation(context, observer)`. Not device-tested. |
| MI-26 | BYPASS displayed as `BYPASS`, never `TERVERIFIKASI`. | VERIFIED | UT: `phaseLabel(BYPASS) == "BYPASS"`; diagnostics label `GERBANG n - BYPASS`, no category. SRC: `toGatePhase` maps BYPASS to BYPASS. |
| MI-27 | If ten successful results are not established, show the failure outcome. | IMPLEMENTED | SRC: `FullVerified` with `!report.passed` ⇒ `StartupState.Failed`. |
| MI-28 | Debug must not create a release trust record. | IMPLEMENTED | SRC: debug returns `FullVerified(report, null)`; commit requires non-debug ten PASS. |

### 3.5 Part 3 — Sentinel, monitoring, lifecycle, ECU

| ID | Requirement | Status | Evidence |
|---|---|---|---|
| MI-29 | Preserve marker path/format/HMAC/Keystore alias, record path/RVCR2/AES-256-GCM/installId/marker digest, commit order, marker-first invalidation. | IMPLEMENTED | SRC: files and calls unchanged; existing `InstallationMarkerTest`, `TrustRecordTest` pass. Real Keystore/atomic rename not device-tested. |
| MI-30 | Lightweight startup validation remains; full current-APK verification remains for FULL. | IMPLEMENTED | SRC: `loadTrustedRecord` still runs signer pin, signed policy, digests, archive identity, assets, XML, DB schema, core vectors; `report.passed` gate added. |
| MI-31 | Runtime monitoring must not secretly run a new FULL; failure marks untrusted, disables sensitive ops, stops Live Data, disconnects safely, invalidates the pair, shows failure, no retry. | IMPLEMENTED | SRC: `startIntegrityMonitor` calls `verifyRuntimeIdentity` only; on failure revokes the pair, `applyIntegrity(runtimeFailure)` stops streaming/disconnects, `StartupState.Failed`. No `evaluateStartup` call. |
| MI-32 | Lifecycle: no dashboard from `rememberSaveable`; new ViewModel re-validates; state authoritative; no pre-authorization hardware; rotation no fabrication; no incomplete commit on death. | IMPLEMENTED | SRC: rendering derives from `startupState`; commit payload is memory-only; no integrity `rememberSaveable`. Not lifecycle-tested. |
| MI-33 | Preserve ECU functionality (FTDI, K-Line, identification incl. K1AA-N02, Live Data, DTC, MAP, tuning, USB permission); no root/ROM/debugger/internet/login requirement. | IMPLEMENTED | SRC: no protocol, database, transport, or permission change; only integrity/startup/UI files edited. Hardware regression BLOCKED. |
| MI-34 | Run relevant tests; do not weaken/delete/skip existing tests. | VERIFIED | UT + COMPILE: 308/308 pass, 0 skipped; no test was removed or modified to pass, except the new test's own input ordering. |
| MI-35 | L1 gate evaluator tests. | VERIFIED | UT: `GateStagingTest`, `IntegrityGateTest`, `SecurityGsonModelTest`, plus the 308-test suite. |
| MI-36 | L2 UI tests (instrumented). | BLOCKED | No `androidTest` source set; Compose UI-test artifacts absent from the offline cache. Diagnostics logic is UT-covered; rendering is not. |
| MI-37 | L3 failure behavior at gates 1/2/5/8/10 (instrumented). | BLOCKED | Category mapping and gate-8 behavior are UT-covered; the failure screen itself has no instrumented assertion. |
| MI-38 | L4 marker/record tests. | BLOCKED (partial) | Container/marker JVM tests pass; commit-after-ack, invalidation refusal, pair lifecycle need `Context`/filesystem and were not executed. |
| MI-39 | L5 lifecycle tests. | BLOCKED | Rotation, process death, Clear Data, update, duplicate start require instrumented/emulator runs. |
| MI-40 | L6 ECU regression. | BLOCKED | No adapter, motorcycle, or ECU available; source untouched by this task. |
| MI-41 | No build/sign/export/publish; identity, keys, certificate unchanged. | VERIFIED | PROCESS: only compile and unit-test tasks ran; no new artifact; `applicationId`, signing config, and key material untouched. |

---

## 4. FILES CHANGED

Modified:

- `app/src/main/java/com/revcore/android/security/GateEvaluator.kt` — Gate 1 detail now embeds
  official and actual certificate SHA-256 and the verification verdict; Gate 4 states that row/field
  detail cannot be identified.
- `app/src/main/java/com/revcore/android/security/IntegrityModels.kt` — `IntegrityReport.runtimeFailure(...)`
  factory (Gate 7 + Gate 8 FAIL, others NOT_CHECKED).
- `app/src/main/java/com/revcore/android/security/RevCoreIntegrity.kt` — debug startup runs the
  staged evaluation with the observer (visible exam); comment corrected (no retry path).
- `app/src/main/java/com/revcore/android/ui/MainViewModel.kt` — observer always wired; strict
  `report.passed` handling; `acceptTrustedReport` fails closed; `shutdownAfterFailure()`;
  `startIntegrityMonitor` rewritten to lightweight check only; `recheckIntegrity()` removed.
- `app/src/main/java/com/revcore/android/MainActivity.kt` — failure branch renders the new window
  and exits via `shutdownAfterFailure()` + `finishAndRemoveTask()` + `exitProcess(0)`.
- `app/src/main/java/com/revcore/android/ui/screens/IntegrityExaminationScreen.kt` — single exact
  title; ten bare rows; BYPASS color; no subtitle/counter/technical detail.
- `app/src/main/java/com/revcore/android/ui/screens/IntegrityFailureScreen.kt` — full rewrite:
  exact title, per-gate dynamic headings, sanitized evidence, single `KELUAR`.

New:

- `app/src/main/java/com/revcore/android/security/IntegrityDiagnostics.kt` — anomaly categories,
  gate→category mapping, failure-window model, sanitizer, exact phase labels.
- `app/src/test/java/com/revcore/android/security/IntegrityDiagnosticsTest.kt` — 13 tests.

Documentation updated:

- `REVCORE_SENTINEL_REQUIREMENTS_TRACEABILITY.md` — revision 4: D-1/D-2 resolved, retry removed,
  failure-window rows superseded, test totals, release boundary.
- This report.

No Gradle, signing, manifest, database, protocol, or asset file was changed.

---

## 5. TESTS EXECUTED

Commands (from `C:/Users/Lord Otoy/Documents/Qoder/work/revcore`):

```
gradle.bat :app:testDebugUnitTest --offline --console=plain
gradle.bat :app:compileReleaseKotlin --offline --console=plain
```

Results:

| Item | Result |
|---|---|
| JVM tests | **308 tests, 0 failures, 0 errors, 0 skipped** (35 test classes) |
| `:app:compileDebugKotlin` | BUILD SUCCESSFUL (up-to-date at test run) |
| `:app:compileReleaseKotlin` | BUILD SUCCESSFUL |
| Instrumented tests | **0 executed** (BLOCKED: no harness) |
| Emulator / device | **0** |
| Physical ECU | **0** |

New test coverage (`IntegrityDiagnosticsTest`, 13 tests): exact seven headings; gate→category
mapping; only failed gates and Gate 8 last; startup failure lists only Gate 8; BYPASS label and no
category; aggregate gate has no counter and no invented category; sanitizer removes internal terms;
sanitizer keeps path and SHA-256 evidence; empty-detail fallback; bounded lines/length; exact phase
labels; `runtimeFailure` yields gates 7 and 8; source line appended.

Mapping to the requested levels:

- **L1 gate evaluator** — VERIFIED by the existing suite.
- **L2 UI** — diagnostics model VERIFIED; Compose rendering BLOCKED.
- **L3 failure at gates 1/2/5/8/10** — mapping and Gate 8 VERIFIED; screen behavior BLOCKED.
- **L4 marker/record** — container tests VERIFIED; commit/lifecycle BLOCKED.
- **L5 lifecycle** — BLOCKED.
- **L6 ECU regression** — BLOCKED.

---

## 6. UI AND LIFECYCLE EVIDENCE

Source-level evidence only, except the pure diagnostics model:

- Examination: title, ten bare rows, state labels, Gate 8 last, real event wiring, no delay.
- Success: exact text, single `LANJUTKAN`, non-dismissible, commit inside the ack handler.
- Failure: exact title, per-gate blocks, seven dynamic headings, sanitized evidence, single
  `KELUAR`, process termination.
- Lifecycle: state machine in `viewModelScope`; no integrity `rememberSaveable`; pending commit is
  memory-only; failure path cannot reach DB/ECU initialization.

None of the above was observed on a screen. No screenshot, emulator trace, or device run exists.

---

## 7. BLOCKED TESTS

1. Instrumented examination rendering (title, ten rows, states, tags) — no `androidTest` harness.
2. Success dialog dismissal blocking and `LANJUTKAN` commit — same.
3. Failure window rendering, headings, and `KELUAR` teardown — same.
4. Gate-1/2/5/8/10 end-to-end failure display — same.
5. Commit-only-after-ack, invalidation refusal, commit failure — need `Context`.
6. Marker/record pair lifecycle: update, Clear Data, reinstall, force stop — need device.
7. Rotation, process death before/after ack, duplicate-start prevention — need instrumented run.
8. Real FULL and TRUST_RECORD duration measurement — needs a built APK.
9. APK mutation matrix and MT Manager repack — needs a built signed APK (not authorized).
10. Keystore HMAC/GCM behavior and atomic rename on real storage — needs device.
11. ECU regression: FTDI, K-Line 10400 bps, identification incl. K1AA-N02, Live Data, DTC, MAP,
    tuning, USB permission — needs hardware.

---

## 8. LIMITATIONS AND RESIDUAL RISK

1. **No artifact contains this code.** Both variants compile, but the Sentinel pipeline has never
   run inside a signed APK.
2. **Sanitizer is pattern-based.** It rewrites the known internal phrases; a future evaluator
   message could introduce an unreplaced term. The failure window would then show it until the
   replacement list is extended (fail-visible, not fail-silent).
3. **The failure window depends on evaluator detail quality.** Gates that fail without a detail
   show the fixed fallback line; nothing is invented.
4. **Debug runtime flow untested on a device.** The code path is shared with release but has no
   execution evidence.
5. **Runtime monitor untested.** Its failure path is source-reviewed only; revocation failure is
   logged, and the session still ends untrusted.
6. **Real tamper resistance unproven.** A rooted or repackaged device can patch any in-app check;
   this design is ROM/root-agnostic in policy, not a hardware root of trust.

---

## 9. AUTHORIZATION CONFIRMATION

**DO NOT BUILD, SIGN, EXPORT, OR PUBLISH ANY APK UNDER THIS AUTHORIZATION — and none was.**

- No `.apk` was produced, modified, signed, or copied in this task.
- No signing key, certificate, keystore, or operational key was read, regenerated, or exported.
- No password, secret, or key material appears in any file, log, or this report.
- The only APK present remains the pre-existing `dist/RevCore build 151126.apk` (2026-11-15
  19:51, SHA-256 `1128af1f…fa86aa`), which does not contain this code and is not a deliverable of
  this task.

This report does not claim the task is fully verified on a device. It claims exactly what §3 and
§5 record.
