# REVCORE SENTINEL — PHASE A TRACEABILITY, PHASE B PLAN, PHASE C COMPLIANCE AUDIT

Document ID: `REVCORE-SENTINEL-PHASE-ABC-AUDIT`
Revision: 4 (final ten-gate examination, anomaly diagnostics, strict fail-closed, 2026-11-16)
Date: 2026-11-16
Project baseline: `C:\Users\Lord Otoy\Documents\Qoder\work\revcore`
State at time of writing: **source + JVM tests changed under the master execution instruction
of 2026-11-16. Debug and release Kotlin compile; 308 JVM tests pass. No APK was built, signed,
exported, or published.**
Approval: Phase A/B approved with required corrections; Phase C source and tests authorized.
Master instruction "REVCORE — FINAL 10-GATE INTEGRITY EXAMINATION, ANOMALY DIAGNOSTICS &
STRICT FAIL-CLOSED" supersedes the earlier retry/exemption assumptions and resolves D-1 and D-2.
No release APK build/sign is authorized. Predecessor audit: `REVCORE_VISIBLE_GATE_EXAMINATION_AUDIT.md` (findings F-1 … F-12).

This document now serves three purposes in one place: §1 is the authoritative requirement
compliance table (one row per REQ ID), §4 is the Phase B implementation plan, and §6 is the
Phase C compliance summary. Phase C source and tests exist; **Phase C is not fully verified.**
Section 6 states exactly what was executed and what was not.

---

## 0. READING RULES

### 0.1 Status vocabulary (fixed by contract)

| Status | Meaning used in this document |
|---|---|
| `NOT_STARTED` | No work performed for this requirement in the current task. |
| `IN_PROGRESS` | Work for this requirement is underway (this document or active analysis). |
| `IMPLEMENTED` | Source behavior exists and was located by audit, but the requirement's acceptance evidence for this task is not complete. |
| `VERIFIED` | Acceptance evidence exists: a unit test, archive/signature inspection, emulator/device run, a documented source-level proof where runtime proof is impossible, or, for process requirements, direct evidence that a forbidden action did not happen (no artifact, no upload, no identity change). The evidence class is named in the row. |
| `BLOCKED` | Cannot progress without owner decision, authorization, or unavailable hardware/environment. |
| `NOT_IMPLEMENTED` | The audit established that the required behavior is absent or contradicted by current source. |

`VERIFIED` on a *process* requirement (for example "no APK was built") is not evidence that any
gate, screen, or lifecycle behavior works. Runtime behavior is only `VERIFIED` when the row names
an executed test or a device/emulator observation.

`IMPLEMENTED` is never used as a synonym for `VERIFIED`. Source inspection is never presented as
runtime proof. A unit test is never presented as proof of real-world tamper resistance.

### 0.2 Evidence classes

- **SRC** — source inspection only. Never proof of runtime behavior.
- **UT** — unit test executed on the JVM (or Robolectric). Not a device proof.
- **IT** — instrumented Android test. **None were executed in Phase C.**
- **APK** — archive/signature inspection of a built artifact. Only prior-phase artifacts exist.
- **EMU** — emulator runtime evidence. **None was produced in Phase C.**
- **DEV** — physical installed-device evidence. **None exists.**
- **HW** — physical motorcycle/ECU/adapter evidence. **None exists.**
- **COMPILE** — both build variants compiled (debug and release Kotlin compilation only).
- **DOC** — the evidence is this document or a named companion report.
- **NONE** — no evidence of any class exists yet.

A requirement may carry `SRC, UT (partial)` when only part of its acceptance surface has a test.
That notation is always accompanied by the missing part named in the last column.

### 0.3 Gate identity baseline (must not change)

| ID | GateId | Display order |
|---|---|---|
| 1 | `APK_IDENTITY` | 1 |
| 2 | `UI_IDENTITY` | 2 |
| 3 | `RESOURCE_PROTECTION` | 3 |
| 4 | `ECU_DATABASE` | 4 |
| 5 | `MANIFEST` | 5 |
| 6 | `NATIVE_CODE` | 6 |
| 7 | `RUNTIME` | 7 |
| 9 | `CORE_PROTECTION` | 8 |
| 10 | `ASSET_INVENTORY` | 9 |
| 8 | `FINAL_TRUST` | 10 (final aggregate, never renumbered) |

Evaluation sequence is `1 → 2 → 3 → 4 → 5 → 6 → 7 → 9 → 10 → 8`.

---

## 1. REQUIREMENT COMPLIANCE TABLE (AUTHORITATIVE)

One row per individual REQ ID, in the original order. Requirement text is preserved from the
Phase A checklist; only the status/evidence columns are updated for Phase C. Status uses only
`NOT_STARTED`, `IN_PROGRESS`, `IMPLEMENTED`, `VERIFIED`, `BLOCKED`, `NOT_IMPLEMENTED`.
Evidence class is a separate column and uses the vocabulary in §0.2 (`UT` = JVM-executed unit
test). A row marked `IMPLEMENTED` means the source exists but its acceptance evidence was not
executed; it must never be read as verified.

| REQ | Requirement (unchanged) | Status | Evidence | Evidence detail / missing evidence |
|---|---|---|---|---|
| 001 | Audit the real source before modifying anything. | VERIFIED | SRC | `REVCORE_VISIBLE_GATE_EXAMINATION_AUDIT.md`; findings F-1…F-12 in §2 |
| 002 | Use the current source as baseline; do not replace the security architecture wholesale. | IMPLEMENTED | SRC | Additive/refactor changes only in the files listed in the implementation report §5. No VCS baseline exists in this workspace, so "no wholesale replacement" is a source-review judgment, not a diff proof. |
| 003 | Preserve valid cryptographic verification and TRUST_RECORD checks. | VERIFIED | SRC, UT | Check inventory in `REVCORE_TEN_GATE_MAPPING.md` §5; `verifyStartupRecord` intact; existing suite green |
| 004 | Do not build, sign, export, or publish an official release APK during this task. | VERIFIED | SRC | Commands executed were compile + `testDebugUnitTest` only (`REVCORE_TEST_REPORT.md` §1); no `dist/` artifact produced in Phase C |
| 005 | Produce Phase A checklist and Phase B plan before source changes; wait for approval. | VERIFIED | DOC | This document §1/§4; Phase A/B approval with required corrections recorded in §5 |
| 006 | Never silently skip, substitute, or reduce a requirement. | IMPLEMENTED | DOC | Every ID has a row; not independently audited by a second reviewer |
| 007 | Distinguish IMPLEMENTED from VERIFIED; no invented evidence. | IMPLEMENTED | DOC | Separate evidence column; missing tests named per row |
| 008 | Stop and ask when blocked, impossible, or unsafe. | IMPLEMENTED | DOC | Blockers in §3.3 and §7; Phase C stopped at the review boundary |
| 009 | Assign unique REQ IDs and keep them immutable. | VERIFIED | DOC | IDs 001–253 unchanged since Phase A |
| 010 | Ten gates must perform real checks; identities/responsibilities preserved. | VERIFIED | SRC, UT | `GateId` unchanged; `IntegrityGateTest`, `GateStagingTest` |
| 011 | Gate 8 is the final aggregate gate and is not renumbered. | VERIFIED | UT | `GateStagingTest` (order, Gate 8 number/last, aggregation) |
| 012 | Real staged sequence `1,2,3,4,5,6,7,9,10,8`; no batch-then-fake-progress. | IMPLEMENTED | SRC, UT (partial) | `STAGED_GATE_ORDER` executed at `RevCoreIntegrity.kt:622`; JVM pins the list. Per-gate evidence steps are not executed by any test (need `Context`). |
| 013 | Observer reports real gate state. | IMPLEMENTED | SRC | `GateEvent`/`GateObserver` and `emit()` exist (`:381`); no executed event-sequence test |
| 014 | Gate lifecycle `WAITING → RUNNING → PASSED/FAILED`. | IMPLEMENTED | SRC | RUNNING before `acquire()`, terminal after `evaluateSingle` (`:386-402`); not executed |
| 015 | Never manufacture PASS; exceptions/missing evidence/unsupported checks are not PASS. | VERIFIED | UT | No-false-PASS tests (unreadable archive, invalid signature, missing policy, injected native lib) |
| 016 | A dependent gate must not PASS after its prerequisite failed. | VERIFIED | UT | `invalidPolicySignatureFailsEveryPolicyConsumer`, `invalidUiSignatureFailsItsConsumersButNotApkIdentity` |
| 017 | Independent checks may continue after a failure, but overall stays FAILED. | VERIFIED | UT | `tamperedDatabaseFailsResourceAndDatabaseGates` shows gates 3 and 4 both evaluated in one report |
| 018 | Debug BYPASS is visibly distinct from PASS. | IMPLEMENTED | SRC, UT (partial) | Master instruction resolved D-1: debug builds now run the same visible staged examination (`RevCoreIntegrity` calls `runStagedEvaluation(context, observer)`); diagnostics render BYPASS as `BYPASS`, never `TERVERIFIKASI`. JVM pins the BYPASS label and the "no anomaly heading" rule; the debug runtime flow is not device-tested. |
| 019 | Release build fails closed if any mandatory gate fails. | VERIFIED | UT | `passed`/`allowsRuntime` tests |
| 020 | No artificial delays, fake progress, prefilled results. | IMPLEMENTED | SRC | No delay/fake fill in the pipeline or `LoadingScreen`; UI rendering not instrumented |
| 021 | Gate 8 PASS only if all nine genuinely passed. | VERIFIED | UT | Four aggregation tests in `GateStagingTest` |
| 022 | Ten rows show actual per-gate states. | IMPLEMENTED | SRC | Screen maps `GatePhase` per row; instrumented assertion not executed |
| 030 | Signed UI/resource integrity manifest exists. | IMPLEMENTED | SRC, APK (prior) | Mechanism unchanged; prior APK verified. No Phase C artifact exists to re-verify. |
| 031 | Protect `AndroidManifest.xml`, `resources.arsc`, compiled XML, `res/**` strings/labels/About/credits/icons/mipmaps/logos/themes/colors/layouts/menus/config XML. | IMPLEMENTED | SRC, APK (prior) | Coverage code unchanged; inventory rerun on a new artifact missing |
| 032 | Do not protect filenames only. | IMPLEMENTED | SRC, UT | Per-entry SHA-256; one-byte cases in `UiIntegrityManifestTest` |
| 033 | Read actual installed APK bytes and compare to trusted signed manifest. | IMPLEMENTED | SRC, UT | `ApkArchiveSet` + synthetic base/split archives; real installed APK not read in Phase C |
| 034 | Reject missing, unexpected, duplicate/ambiguous entries and one-byte changes. | IMPLEMENTED | UT (partial), APK (prior) | JVM covers one-byte/missing/injected/duplicate; real mutation matrix not rerun |
| 035 | Verify manifest authenticity before trusting expected hashes. | IMPLEMENTED | SRC, UT | Signature prerequisite per consuming gate; manifest signature tests |
| 036 | No filename-only, size-only, timestamp-only substitutes. | IMPLEMENTED | SRC, UT | Digest comparison mandatory in every path |
| 037 | Structural compiled-XML checks supplement hashes. | IMPLEMENTED | UT | `changedStructureTokensFailEvenWithMatchingBytes` |
| 038 | Do not decrypt compiled XML and feed arbitrary encrypted XML to Android. | VERIFIED | SRC | No such scheme introduced |
| 039 | Resource-only modification detected even when DEX unchanged. | IMPLEMENTED | UT | `oneByteResourceChangeFailsUiResourceVerification` (DEX fixture unchanged) |
| 040 | UI protection failure denies trust, dashboard, and shows generic failure. | IMPLEMENTED | SRC, UT | Evaluator FAIL denies runtime (UT); generic screen (SRC); instrumented flow not run |
| 041 | Preserve `applicationId = com.revcore.android`. | VERIFIED | SRC | `app/build.gradle.kts` unchanged |
| 042 | Preserve official signing identity and certificate. | VERIFIED | SRC | Signing config/certificate unchanged |
| 043 | Confirm recorded fingerprint `c649cb4f…18d098` against official release configuration. | VERIFIED | SRC, APK (prior) | Pin constant unchanged; earlier APK certificate matches |
| 044 | Verify installed signer via supported package-signing APIs. | IMPLEMENTED | SRC, APK (prior) | `apkSigners` unchanged; Phase C did not execute it against an installed APK |
| 045 | Do not trust package name, versionCode/Name, local config, unsigned manifest, untrusted fingerprint alone. | IMPLEMENTED | UT | Re-signed / wrong-pin / unsigned-policy negative tests |
| 046 | Bind trusted policy and protected asset inventory to official signer. | IMPLEMENTED | SRC, UT | Signature checked before digest consumption; prerequisite tests |
| 050 | External record exact path `Android/data/com.revcore.android/files/.revcore/gptqdr.rvc`, external, `.rvc` binary, not renamed/moved. | VERIFIED | SRC, EMU (prior) | Path/container unchanged; prior emulator evidence |
| 051 | Internal marker exact path `filesDir/.revcore/installation.state`. | IMPLEMENTED | SRC | `InstallationStateStore.markerFile()`; store not executed |
| 052 | Both files share/authenticate same `installId`, bound to package, versionCode, versionName, APK/build identity, signer fingerprint, policy digest, protected asset-set digest, format version, verification metadata. | IMPLEMENTED | SRC, UT (partial) | Payload schema JVM; pair comparison needs `Context` |
| 053 | Build identity must distinguish builds with identical version numbers. | IMPLEMENTED | SRC | `buildIdentity` + `archiveFingerprint` in both files; same-version-different-build test not executed |
| 054 | Files must be authenticated; Keystore-backed device-local key; no static secret; handle unavailable/invalidated keys. | IMPLEMENTED | SRC | Record GCM + marker HMAC code; real Keystore behaviour not exercised |
| 055 | AES encryption alone is not authenticity. | IMPLEMENTED | SRC, UT | GCM tag check; marker MAC verified before JSON parse |
| 056 | Do not reuse K1–K9; do not create fictitious K10. | VERIFIED | SRC | Dedicated marker alias; no K1–K9 reference |
| 057 | Document cryptographic design and limitations. | IMPLEMENTED | DOC | `REVCORE_TRUST_RECORD_LIFECYCLE_REPORT.md` §2 and §8 |
| 060 | Fresh installation runs FULL verification. | IMPLEMENTED | SRC | Missing pair ⇒ FULL; no Phase C device run (prior emulator run used the older design) |
| 061 | Do not create marker/record before all ten gates pass. | IMPLEMENTED | SRC | Evaluation has no write; commit guard rejects any non-FULL-PASS report; no executed test |
| 062 | After ten genuine PASS, show success acknowledgement dialog. | IMPLEMENTED | SRC | Dialog composable rendered from `AwaitingAcknowledgement`; instrumented test not executed |
| 063 | Wait for `LANJUTKAN`. | IMPLEMENTED | SRC | Only the button handler calls the commit; no executed test |
| 064 | Commit marker and record only after `LANJUTKAN`; delete/verify absence before any release FULL; remove auto-persist; hold payload in memory. | IMPLEMENTED | SRC | **Required test not executed.** Path: `evaluateStartup` → in-memory `InstallationCommit` → VM `pendingCommit` → `acknowledgeIntegrity`. Missing evidence: no-commit-before-ack and commit-after-ack tests; both need `Context` and are not written. |
| 065 | Write both files safely and consistently. | IMPLEMENTED | SRC, UT (partial) | Marker temp+atomic rename (SRC); marker container JVM; interrupted/partial write not tested |
| 066 | Process death before `LANJUTKAN` ⇒ next launch FULL. | IMPLEMENTED | SRC | Nothing written before ack; pair invalidated before FULL; process death not simulated |
| 067 | Missing/corrupt/unauthenticated/inconsistent either file ⇒ reject TRUST_RECORD. | IMPLEMENTED | UT (marker), SRC (record) | Tamper/truncate/wrong-key JVM; record path needs Keystore/`Context` |
| 068 | `installId` mismatch ⇒ reject. | IMPLEMENTED | SRC | `pairMatches` compares `installId` and marker digest; no executed test |
| 069 | Different APK/build identity ⇒ reject. | IMPLEMENTED | SRC, APK (prior) | Record binding retained; marker side SRC only |
| 070 | Different signer/policy/asset-set digest ⇒ reject. | IMPLEMENTED | SRC, UT (partial) | Digest comparison SRC; marker schema JVM |
| 071 | New build after update creates fresh installation identity and binds both files. | IMPLEMENTED | SRC, UT (partial) | Fresh random id per commit (UT uniqueness); update flow not executed |
| 072 | Do not silently accept old record after update; detect stale records. | IMPLEMENTED | SRC, EMU (prior) | Version/build mismatch rejection; not rerun in Phase C |
| 073 | Clear App Data removes marker; surviving external record must not bypass FULL. | IMPLEMENTED | SRC | Depends on Keystore key loss; not executed |
| 074 | Deleted file ⇒ FULL, never assumed trust. | IMPLEMENTED | SRC | Missing-file branch; not executed |
| 075 | Verified invalidation before FULL: marker first, then record; if either remains, no gates and generic failure. | IMPLEMENTED | SRC | **Required test not executed.** `invalidatePersistentTrust` deletes marker-first and verifies absence, then refuses FULL on failure. Missing evidence: no undeletable-file/refusal test (needs a filesystem/`Context` fake). |
| 076 | No trusted pair may authorize a new process while a FULL examination is pending. | IMPLEMENTED | SRC | Startup path: invalidation before the first gate. The runtime-monitor portion no longer re-enters FULL (D-2 resolved): it performs the lightweight identity check and, on failure, revokes the persistent pair and ends the session untrusted. |
| 077 | Commit failure must not publish persistent trust. | IMPLEMENTED | SRC | **Required test not executed.** `failCommit` deletes both; VM continues only with an in-memory FULL ten-PASS. Missing evidence: commit-failure and session-continuation tests. |
| 078 | Marker digests are bindings, never independent trust anchors. | IMPLEMENTED | SRC, UT (partial) | `verifyStartupRecord` still runs all bindings; no digest-only acceptance path. No direct negative test. |
| 079 | Do not simplify lightweight validation to marker/installId/file existence. | IMPLEMENTED | SRC, UT (partial) | Check inventory preserved; several bindings covered by UT, not all individually |
| 080 | Preserve existing TRUST_RECORD checks: signer pin, signed policy, policy digest, UI/resource digests, archive fingerprint, APK length/metadata, protected assets, XML structure, DB schema, core vectors. | IMPLEMENTED | SRC | 20 check families listed in the mapping report §5; not individually unit-tested |
| 081 | Do not reduce to `fileExists` or `installId` comparison. | IMPLEMENTED | SRC | Source review: no such path |
| 082 | If current APK cannot be authenticated, fall back to FULL. | IMPLEMENTED | SRC | Null lightweight result ⇒ FULL; not executed |
| 090 | `forceFull=true` must never consult the trust record. | IMPLEMENTED | SRC | Skips `lastReport` (`:148`) and `loadTrustedRecord` (`:161`). **Required test not executed** (REQ-092). |
| 091 | Retry button invokes real FULL. | NOT_IMPLEMENTED | SRC | **Superseded by the owner master instruction (2026-11-16): no retry, no `PERIKSA ULANG`.** `recheckIntegrity()` was removed; the failure screen has only `KELUAR`. Row kept for ID immutability. |
| 092 | Regression tests prove forceFull never accepts the record as substitute. | BLOCKED | NONE | Required UT (valid record + spy observer/counter) still not written; pipeline needs `Context`. Unrelated to the retry removal. |
| 100 | Process-scoped startup state machine owned by ViewModel (`viewModelScope`). | IMPLEMENTED | SRC | `StartupState` seven states; no JVM test |
| 101 | Critical integrity job must not depend solely on a composable `LaunchedEffect`. | IMPLEMENTED | SRC | `startStartup()` from `onCreate` before `setContent` |
| 102 | Rotation/Activity recreation must not cancel verification or skip init. | IMPLEMENTED | SRC | Job in `viewModelScope`; rotation not tested |
| 103 | Restored UI state must not bypass verification. | IMPLEMENTED | SRC | Rendering derives only from `startupState`; no integrity `rememberSaveable` |
| 104 | Process-alive app switching must not repeat FULL. | IMPLEMENTED | SRC, EMU (prior) | No startup call in `onResume`; prior evidence predates Phase C |
| 105 | Recreated process may use TRUST_RECORD only after all lightweight validations. | IMPLEMENTED | SRC | Marker + record + full `verifyStartupRecord`; not executed |
| 106 | Failed validation fails closed. | VERIFIED | UT | `startupFailure` report denies runtime |
| 107 | No duplicate verification jobs. | IMPLEMENTED | SRC | Single-flight job + ack flag; no duplicate test |
| 108 | Do not initialize ECU functions before trust is established. | IMPLEMENTED | SRC | DB/storage/USB init only in `runInitialization`; not executed |
| 109 | Distinguish Activity recreation from new process. | IMPLEMENTED | SRC | New process ⇒ new VM ⇒ `Idle`; not executed |
| 110 | User switches apps; process alive — no repeated FULL examination. | IMPLEMENTED | SRC, EMU (prior) | Cache reuse path |
| 111 | Activity recreation, same process — reuse process-scoped result. | IMPLEMENTED | SRC | VM survives; not tested |
| 112 | Android kills process; reopen — lightweight marker+record validation. | IMPLEMENTED | SRC | Not executed |
| 113 | Back/exit then reopen — lightweight if record valid. | IMPLEMENTED | SRC | Not executed |
| 114 | Swipe away then reopen — same as above. | IMPLEMENTED | SRC | Not executed |
| 115 | Force Stop then reopen — lightweight if valid record survives. | IMPLEMENTED | SRC | Not executed |
| 116 | Clear App Data — FULL ten-gate examination. | IMPLEMENTED | SRC | Not executed |
| 117 | Uninstall/reinstall — FULL. | IMPLEMENTED | SRC | Not executed |
| 118 | APK update — FULL. | IMPLEMENTED | SRC | Not executed |
| 119 | Missing/corrupt/mismatched marker — FULL. | IMPLEMENTED | SRC, UT (marker) | Marker container JVM; startup path needs `Context` |
| 120 | Missing/corrupt/mismatched trust record — FULL. | IMPLEMENTED | SRC, EMU (prior) | Not rerun in Phase C |
| 121 | Measure actual FULL and TRUST_RECORD times; report, never invent. | BLOCKED | NONE | No build/device authorized; no timing measured. The report contains no invented numbers. |
| 130 | Exact title `PEMERIKSAAN INTEGRITAS REVCORE`. | IMPLEMENTED | SRC | `IntegrityExaminationScreen.kt:64`; instrumented assertion not executed |
| 131 | Exactly ten rows, statuses `MENUNGGU`, `MEMERIKSA`, `TERVERIFIKASI`, `GAGAL`. | IMPLEMENTED | SRC | One row per `GateId`; labels at `:138-147`; not instrumented |
| 132 | Actual gate numbering; Gate 8 not renumbered and displayed last. | IMPLEMENTED | SRC, UT (partial) | `GATE_DISPLAY_ORDER` sorts Gate 8 last; JVM pins execution order; screen not instrumented |
| 133 | Connected to real verification events; no simulation; no TERVERIFIKASI before PASS. | IMPLEMENTED | SRC | Rows update only from observer events; not instrumented |
| 134 | Existing RevCore visual language. | IMPLEMENTED | SRC | Theme colors/typography reused; screenshot/visual review not performed (missing) |
| 135 | Stable tags `integrity_examination`, `gate_row_1`…`gate_row_10`. | IMPLEMENTED | SRC | Tags applied at `:61`, `:111`; not asserted |
| 136 | Show examination only when startup policy requires FULL. | IMPLEMENTED | SRC | TRUST_RECORD/reuse go straight to `Starting`; not instrumented |
| 137 | Do not disclose what gates inspect, internal component/asset names, hashes, algorithms, keys, architecture, failure details. | IMPLEMENTED | SRC | Text audit: rows contain only `GERBANG n` + state |
| 140 | After ten PASS show non-dismissible dialog, title `Pemeriksaan Integritas Berhasil`, success icon, button `LANJUTKAN`. | IMPLEMENTED | SRC | `onDismissRequest = {}`, no negative button; instrumented test not executed. (Success icon not added; see deviation D-3.) |
| 141 | Commit marker/record only after LANJUTKAN. | IMPLEMENTED | SRC | Commit inside `acknowledgeIntegrity`; no executed test |
| 142 | After LANJUTKAN continue existing LoadingScreen and DB/storage/USB init; no new loading screen; no ECU init change. | IMPLEMENTED | SRC | `runInitialization()` reuses `LoadingScreen`; not executed |
| 143 | Do not open dashboard before the decision. | IMPLEMENTED | SRC | Dashboard only in `Ready`; not instrumented |
| 144 | Success dialog only for FULL with ten PASS; never for BYPASS or TRUST_RECORD. | IMPLEMENTED | SRC | `handleStartupOutcome` requires `report.passed` (ten PASS, Gate 8 PASS); debug `FullVerified` skips the dialog and runs initialization with `pendingCommit = null`; TRUST_RECORD never produces the dialog. Not instrumented. |
| 150 | Exact title `Integritas Aplikasi Tidak Dapat Diverifikasi`. | NOT_IMPLEMENTED | SRC | **Superseded by the owner master instruction (2026-11-16): the failure window title is exactly `PEMERIKSAAN INTEGRITAS GAGAL`.** |
| 151 | Exact message `RevCore tidak dapat memastikan keaslian atau kelengkapan instalasi ini. Silakan instal ulang menggunakan APK resmi RevCore.` | NOT_IMPLEMENTED | SRC | **Superseded**: the failure window now lists every failed gate with its dynamic anomaly heading and actual evidence, plus the sub-line `Sesi dihentikan. Aplikasi tidak dapat dilanjutkan.` |
| 152 | Button `PERIKSA ULANG`. | NOT_IMPLEMENTED | SRC | **Superseded**: the only action is `KELUAR`, which cancels work, disconnects hardware and terminates the process. |
| 153 | No internal gate names, keys, expected hashes, paths, or detailed evidence in public UI. | NOT_IMPLEMENTED | SRC | **Superseded**: the owner now requires actual evidence (asset paths, expected/actual SHA-256) and forbids only internal mechanism terms (AES/HMAC/Keystore/key material), which `IntegrityDiagnostics.sanitizeDetail` strips. Paths and fingerprints are retained deliberately. |
| 154 | No success dialog, no new marker/record, no trusted dashboard, ECU disabled on failure. | IMPLEMENTED | SRC, UT (partial) | `allowsRuntime` false (UT); dialog/commit/dashboard paths SRC; not instrumented |
| 160 | Runtime monitor separate from startup examination; silent; no second examination screen. | IMPLEMENTED | SRC | D-2 corrected: every 60 s the monitor calls `verifyRuntimeIdentity` only; no `evaluateStartup`, no observer, no gate rows. Not runtime-tested. |
| 161 | No duplicate startup jobs from monitor. | IMPLEMENTED | SRC | The monitor no longer enters `launchStartup`/`evaluateStartup`; on failure it cancels its own job and stops. No duplicate-job test. |
| 162 | No unnecessary USB/K-Line interruption during normal transitions. | IMPLEMENTED | SRC | The monitor acts only on a genuine lightweight-validation failure; a passing check touches no transport |
| 163 | On genuine failure mark untrusted, disable sensitive ops, stop/close diagnostics safely, prevent ECU writes, preserve evidence, no random crash. | IMPLEMENTED | SRC | `startIntegrityMonitor` failure path: revoke persistent pair, `pendingCommit = null`, `IntegrityReport.runtimeFailure(...)` (gates 7 and 8 FAIL, rest NOT_CHECKED), `applyIntegrity` denies hardware, `StartupState.Failed` renders the exit-only window. Not runtime-tested. |
| 170 | Offline-first; no login/license/subscription/cloud/remote auth. | VERIFIED | SRC | No network dependency added |
| 171 | Never block for root, KernelSU, custom ROM, unlocked bootloader, USB debugging, developer options. | VERIFIED | SRC | No such checks in the integrity path |
| 172 | No broad anti-root checks as substitute for integrity. | VERIFIED | SRC | None present |
| 180 | Preserve FTDI/USB OTG/K-Line/10400 bps/init timing/ECU ID + database matching/content/DTC read+clear/Live Data/MAP/Tuning/screens/USB permissions+reconnect. | IMPLEMENTED | SRC, EMU (prior) | No protocol/DB/UI change; full regression not rerun on current source or hardware |
| 181 | No hardcoded universal ECU identity; no invented protocol/AFR. | VERIFIED | SRC | No protocol change |
| 182 | Narrowband O2 remains voltage; AFR unsupported. | VERIFIED | SRC | Unchanged |
| 183 | Do not change donation/About content unless a security dependency requires it. | VERIFIED | SRC | Unchanged |
| 190 | Do not regenerate/print/upload/commit/copy K1–K9 values. | VERIFIED | SRC | Process compliance |
| 191 | No passwords in Gradle or source. | VERIFIED | SRC | No secret added |
| 192 | No secrets in prompts, logs, reports. | VERIFIED | DOC | Reports contain no key material |
| 193 | No reuse of operational keys for unrelated purposes. | VERIFIED | SRC | Dedicated marker alias |
| 194 | Gates do not each need an AES key. | VERIFIED | SRC | One anchor, no per-gate keys |
| 195 | Static manifests verified by digital signatures. | VERIFIED | SRC, UT | Detached-signature tests |
| 196 | Local state uses authenticated encryption or MAC. | IMPLEMENTED | SRC, UT (partial) | Record GCM container UT; marker HMAC UT with injected key; real Keystore/key-loss not run |
| 197 | Public key is not a secret. | VERIFIED | SRC | Pin is a public fingerprint |
| 198 | Do not encrypt DEX and claim it remains executable. | VERIFIED | SRC | Not attempted |
| 199 | No unused key slots or fictitious K10. | VERIFIED | SRC | None created |
| 200 | Official signing key separate and never handled here. | VERIFIED | SRC | No signing operation |
| 201 | Do not ask owner to paste passwords in chat. | VERIFIED | SRC | Process compliance |
| 202 | Do not transmit private keys or signing passwords to cloud services. | VERIFIED | SRC | No transmission |
| 210 | Audit single-boolean/function/file bypass paths. | IMPLEMENTED | DOC | Implementation report §7 lists five paths and their guards |
| 211 | Add independent verification paths only where real value exists. | IMPLEMENTED | DOC | Design review documented |
| 212 | No circular checks. | IMPLEMENTED | DOC | Evidence DAG in implementation report §7 |
| 213 | Failed prerequisite cannot yield PASS. | VERIFIED | UT | Prerequisite tests |
| 214 | Document residual risk of fully controlled/rooted device. | IMPLEMENTED | DOC | Implementation report §7 and §7.4 below |
| 220 | Gate lifecycle: RUNNING before terminal; no PASS without RUNNING; staged order. | IMPLEMENTED | UT (partial) | Order pinned by `GateStagingTest`; RUNNING-before-terminal is SRC only |
| 221 | No false PASS: exceptions, missing evidence, unreadable archive, null policy ⇒ FAILED. | VERIFIED | UT | Existing fault-injection tests green |
| 222 | Prerequisite dependency: dependent gate cannot PASS after prerequisite failure. | VERIFIED | UT | `GateStagingTest` prerequisite cases |
| 223 | Gate 8 aggregation: PASS only when all nine PASS; FAIL if any FAIL/BYPASS/NOT_CHECKED. | VERIFIED | UT | Four aggregation tests |
| 224 | Debug BYPASS: BYPASS never equals PASS; no success dialog. | VERIFIED | UT | `statusToPhaseNeverTurnsABypassOrASkipIntoAPass` + debug tests |
| 225 | Failure denies runtime: `allowsRuntime=false`; ECU guard. | VERIFIED | UT | Evaluator tests |
| 226 | UI integrity mutations: one-byte resource, icon, label, credits, XML, `resources.arsc`, missing entry, unexpected/duplicate entry, unchanged DEX with changed resource, invalid manifest signature. | IMPLEMENTED | UT (partial), APK (prior) | JVM subset (one-byte, `resources.arsc`, missing/injected, XML, identity, manifest signature); full APK mutation matrix not rerun |
| 227 | Trust record lifecycle: valid pair ⇒ TRUST_RECORD; missing/corrupt files; different installId/build/signer/policy; clear data; no commit before LANJUTKAN; process death before ack ⇒ FULL; verified invalidation refuses examination; commit failure never publishes trust. | IMPLEMENTED | SRC, UT (partial) | Marker container cases JVM; all store/pair/commit lifecycle cases need `Context` and were not executed |
| 228 | Lifecycle: rotation doesn't cancel; same process no rerun; new process no dashboard pre-trust; restored state no bypass; duplicate prevention; failed startup no ECU. | IMPLEMENTED | SRC | No lifecycle test executed |
| 229 | Runtime monitor: no duplicate exam; failure disables; no false PASS; normal transitions don't interrupt USB. | IMPLEMENTED | SRC | D-2 corrected; direct tests for this row remain absent |
| 230 | Full existing suite: run all existing tests; do not delete/weaken; report counts. | VERIFIED | UT, COMPILE | 308/308 pass (0 failed, 0 skipped, 35 classes); 295 pre-existing + 13 `IntegrityDiagnosticsTest`; `:app:compileDebugKotlin` and `:app:compileReleaseKotlin` green |
| 231 | Invalidation verification: marker-first deletion; absence required before gates; undeletable file ⇒ no gates, generic failure, retry. | IMPLEMENTED | SRC | Marker-first deletion and absence check unchanged; the failure window is now terminal (`KELUAR`) per the master instruction, so "retry" is superseded. No invalidation-refusal test executed. |
| 232 | Commit failure: no persistent trust; session continuation only with valid ten-PASS decision; otherwise Failed; next launch FULL. | IMPLEMENTED | SRC | No commit-failure test executed |
| 233 | Digest non-anchor: marker digests cannot authorize startup without full record/current-APK verification. | IMPLEMENTED | SRC | No digest-only acceptance test executed |
| 240 | `REVCORE_SENTINEL_IMPLEMENTATION_REPORT.md` | VERIFIED | DOC | Present at repository root |
| 241 | `REVCORE_TEN_GATE_MAPPING.md` | VERIFIED | DOC | Present |
| 242 | `REVCORE_UI_INTEGRITY_REPORT.md` | VERIFIED | DOC | Present |
| 243 | `REVCORE_TRUST_RECORD_LIFECYCLE_REPORT.md` | VERIFIED | DOC | Present |
| 244 | `REVCORE_STARTUP_LIFECYCLE_REPORT.md` | VERIFIED | DOC | Present |
| 245 | `REVCORE_TEST_REPORT.md` | VERIFIED | DOC | Present |
| 246 | Source diff summary + modified/new file list | VERIFIED | DOC | Implementation report §5 |
| 247 | Remaining risks and unverified scenarios | VERIFIED | DOC | Implementation report §8, test report §5, §7.4 here |
| 248 | Reports state before/repaired/added/removed, tests run/passed/failed/not possible, measured time, limitations | VERIFIED | DOC | Reports contain these sections; no time is reported because none was measured |
| 250 | Do not build/sign/export/publish official APK before owner approval. | VERIFIED | SRC | Only compile + unit tests were run |
| 251 | Preserve applicationId, certificate, signing config, versioning, naming. | VERIFIED | SRC | No change |
| 252 | Future authorized build named `RevCore build DDMMYY.apk` in `dist/`; preserve older builds; never leave debug APK as sole deliverable. | NOT_STARTED | NONE | No build authorized in this phase; naming convention not exercised |
| 253 | No GitHub/external uploads. | VERIFIED | SRC | No upload performed |

**Group T (device/emulator matrix):** defines no individual REQ IDs. Its 24 scenarios remain
`NOT_STARTED` / `BLOCKED` because no APK or device run is authorized. See §7.3 and §7.5.

---

## 2. AUDIT FINDINGS MAPPED TO REQUIREMENTS

This table maps audit findings to requirement IDs; it is not a compliance table. Ranges here are
finding references only. Every ID referenced by a range has its own status row in §1.

| Finding | Description | Requirement IDs |
|---|---|---|
| F-1 | No examination UI exists at all. | REQ-130…137 |
| F-2 | Gates evaluated as one batch after all facts collected; no observable sequence. | REQ-012…014 |
| F-3 | `forceFull=true` bypasses `lastReport` but still accepts a valid record. | REQ-090…092 |
| F-4 | No internal `installation.state`; external record alone can authorize TRUST_RECORD. | REQ-051…052, 068, 119 |
| F-5 | Startup coroutine owned by `LoadingScreen`'s `LaunchedEffect`; recreation can cancel init while `sessionInitialized` stays true. | REQ-100…102 |
| F-6 | Surface selection uses `rememberSaveable` splash/terms flags. | REQ-103 |
| F-7 | Failure screen discloses gate names/categories/sources/details. | REQ-150…153 |
| F-8 | Gate 8 computed last already, but no UI ordering guarantee. | REQ-132 |
| F-9 | TRUST_RECORD is substantial (not a bare token). | REQ-080…082 |
| F-10 | Debug builds cannot produce PASS; success-dialog runtime proof needs official build. | REQ-018, 144, blocker B-1 |
| F-11 | Trust record is persisted automatically inside `runFullEvaluation`, before any acknowledgement. | REQ-061, 064, 066 |
| F-12 | No shared `installId` between record and any internal state. | REQ-052, 068 |

---

## 3. DEPENDENCIES, CONFLICTS, AND BLOCKERS

### 3.1 Dependency graph (implementation order)

1. Gate observer + gate-phase model (no behavior change).
2. Split UI manifest verification into signature / UI resources / structure+identity / DEX.
3. Staged pipeline with per-gate evidence acquisition and observer events.
4. Prerequisite enforcement (Gate 8 mandatory; evidence prerequisites per gate).
5. `InstallationStateStore` + record format 2 with `installId`.
6. Move record persistence out of evaluation; add pending-installation payload.
7. `RevCoreIntegrity` startup decision: forceFull fix, marker+record lightweight path, no-record FULL.
8. ViewModel startup state machine + acknowledgement commit + init continuation.
9. Examination screen, success dialog, generic failure screen; MainActivity rendering from state.
10. Runtime monitor separation. **Achieved (D-2 corrected): lightweight identity check only.**
11. Tests (unit → instrumented), then reports.

Steps 1–3 are the largest change and must land together because the pipeline shape changes.

### 3.2 Conflicts requiring resolution

| Conflict | Resolution status |
|---|---|
| Current code writes `gptqdr.rvc` during FULL evaluation vs requirement “commit only after LANJUTKAN”. | Resolved in source: evaluation no longer writes; commit happens in `commitInstallation` after `LANJUTKAN`. Covered by REQ-064 (IMPLEMENTED — commit-order unit test not executed). |
| Failure screen currently exposes gate details vs non-disclosure. | **Superseded.** The master instruction requires per-gate evidence with dynamic anomaly headings while forbidding internal mechanism terms; `IntegrityDiagnostics.sanitizeDetail` enforces the split. JVM-tested. |
| Runtime monitor calls `evaluateStartup(forceFull=true)` vs “no second examination screen”. | **Resolved (D-2).** Monitor now runs `verifyRuntimeIdentity` only; on failure it revokes the pair, denies hardware and renders the terminal failure window. No silent FULL remains. |
| Debug BYPASS vs four visible states / success dialog. | **Resolved (D-1).** Debug builds run the same visible staged examination; BYPASS renders as `BYPASS`; no success dialog and no record write in debug. |
| Gate 2/3/9 consume manifest evidence before Gate 5 verifies signature. | Resolved in source: each consuming gate requires `signatureValid` as its own precondition; Gate 5 re-verifies independently. Unit-tested (REQ-035, REQ-016). |
| Android/data survives updates vs fresh identity. | Resolved in source: identity mismatch forces FULL and a new `installId`; stale record rejects to FULL. |

### 3.3 Blockers / owner decisions

| ID | Blocker | Impact | Status |
|---|---|---|---|
| B-1 | Success dialog, real FULL/TRUST_RECORD timing, MT Manager/resource mutation tests on the **new** code require a built/signed APK, which is prohibited until approval. | REQ-092, REQ-121, matrix 3–6 and 17–23, REQ-226 rerun cannot be verified now. | **BLOCKED.** Deferred until the owner authorizes a build. |
| B-2 | No physical motorcycle/ECU adapter connected. | Group T scenario 24, diagnostic regression hardware evidence. | **BLOCKED.** No hardware evidence exists. |
| B-3 | Rooted-device/MT Manager repack tests need an artifact. | Real-world tamper evidence. | **BLOCKED**, follows B-1. |
| B-4 | Choice of marker authentication primitive. | Design detail. | Resolved: HMAC-SHA256 with dedicated Keystore alias, approved. |
| B-5 | Behavior if marker/record commit fails after LANJUTKAN. | UX vs strictness. | Resolved in design: no persistent trust; continue only with a still-valid ten-PASS session decision; otherwise Failed; next launch FULL. Implementation is IMPLEMENTED; no commit-failure test executed (REQ-077). |
| B-6 | Whether the examination screen is shown in debug builds. | Dev experience vs four-state contract. | **Resolved by the master instruction (D-1): shown in debug, BYPASS visible, no success dialog, no record.** |

B-1/B-2/B-3 block final acceptance evidence only. B-6 is now resolved by the owner instruction;
no owner decision remains open for the examination/failure design.

---

## 4. PHASE B — IMPLEMENTATION PLAN

### 4.1 Architecture overview

```
MainActivity (viewModels<MainViewModel>)
   onCreate → viewModel.startStartup()
        │
        ▼
MainViewModel (viewModelScope)
   StartupState: Idle → Examining → AwaitingAcknowledgement → Starting → AwaitingTerms → Ready
                              └──────────────→ Failed
   gatePhases: StateFlow<Map<GateId, GatePhase>>
        │
        ▼
RevCoreIntegrity
   evaluateStartup(context, forceFull, observer) → StartupOutcome
       ├─ process reuse (no forceFull)
       ├─ marker + record lightweight validation
       └─ FULL staged pipeline (observer events)
   commitInstallation(context, pending)   ← only after LANJUTKAN
        │
        ├─ InstallationStateStore (filesDir/.revcore/installation.state)
        └─ TrustRecordStore (external .revcore/gptqdr.rvc)
```

UI renders strictly from `StartupState`; no `rememberSaveable` gate flags.

### 4.2 Staged pipeline (REQ-012…014)

New internal types:

```kotlin
enum class GatePhase { WAITING, RUNNING, PASSED, FAILED }

data class GateEvent(val gate: GateId, val phase: GatePhase, val detail: String? = null)

fun interface GateObserver { fun onGateEvent(event: GateEvent) }
```

`RevCoreIntegrity.runFullEvaluation(context, observer)` executes steps in order. Each step:

1. observer emits `RUNNING` for the gate;
2. performs that gate's real evidence acquisition and evaluation;
3. observer emits `PASSED`/`FAILED` with a non-secret detail (logs only);
4. continues to the next gate regardless of failure.

Step-to-evidence mapping:

| Step | Gate | Evidence actually acquired in that step |
|---|---|---|
| 1 | 1 APK_IDENTITY | Open archives; read/parse policy; read signer certificates; actual package/version/label/icon; policy signature validity; evaluate Gate 1. |
| 2 | 2 UI_IDENTITY | Read signed UI manifest; verify its signature under pin; inventory UI entries; structure tokens; manifest identity claims; evaluate Gate 2. |
| 3 | 3 RESOURCE_PROTECTION | SHA-256 of `AndroidManifest.xml`, `resources.arsc`, all `res/**` entries; protected assets bytes/hashes; policy binding; evaluate Gate 3. |
| 4 | 4 ECU_DATABASE | Read/hash `ecm_database.json`; schema validation; evaluate Gate 4. |
| 5 | 5 MANIFEST | Re-verify policy + UI manifest signatures; policy presence; evaluate Gate 5. |
| 6 | 6 NATIVE_CODE | Read `lib/**` inventory; compare to policy; evaluate Gate 6. |
| 7 | 7 RUNTIME | Signer pin + policy/manifest re-verification on the installed archive; evaluate Gate 7. |
| 8 | 9 CORE_PROTECTION | SHA-256 of `classes*.dex`; identity strings; core protocol vectors; evaluate Gate 9. |
| 9 | 10 ASSET_INVENTORY | Full asset inventory (extra/missing/duplicates/sources); evaluate Gate 10. |
| 10 | 8 FINAL_TRUST | Aggregate; any non-PASS blocks; emit last. |

No `delay`, no pre-filled statuses, no batch-then-replay.

### 4.3 Gate prerequisite rules (REQ-016, 213)

- Gate 8 requires all nine gates `PASSED`. `BYPASS` and `NOT_CHECKED` never count.
- Gates 2, 3, 9 require a valid UI-manifest signature as their own evidence precondition.
- Gates 1, 3, 4, 6, 10 require a valid policy signature as their own evidence precondition.
- No other gate-to-gate prerequisites exist; the pipeline documents this explicitly instead of
  inventing dependencies. A prerequisite failure downgrades that gate to `FAILED` with a
  non-secret reason; independent gates still run.

### 4.4 Two-file design — detailed marker specification (REQ-051…057, 064…074)

#### 4.4.1 Purpose and non-guarantees

`installation.state` is an **internal, authenticated installation marker**. It answers one question:
*“Does this external `gptqdr.rvc` belong to this installed copy of RevCore, on this device, for this
exact build?”* It does not, by itself, prove that the APK is authentic. It is not a secret, not a
license, and not a substitute for any gate. It exists to:

1. prevent a valid external record from being reused after Clear App Data;
2. prevent a record copied from another installation or device from being accepted;
3. bind the record to one `installId`, build identity, signer, policy, and asset set;
4. make “process died before LANJUTKAN” observable as “no trusted pair” on next launch;
5. give the external record an internal counterpart that survives process death but not data clear.

It deliberately does **not** contain gate results, trust decisions, hashes of expected APK entries,
paths, keys, or any evidence that could be replayed as proof of integrity. Trust is decided by the
FULL gates or by re-validating the current APK against the signed manifest and policy, never by the
marker alone.

#### 4.4.2 Threat model the marker addresses

| Threat | Marker behavior |
|---|---|
| Attacker copies `gptqdr.rvc` from another device | Marker HMAC fails under this device's Keystore key ⇒ FULL |
| Attacker copies both files from another install on the same device | `installId` and/or marker digest mismatch, or Keystore key gone after clear data ⇒ FULL |
| Attacker keeps a stale record across an APK update | Marker build identity/version mismatch ⇒ FULL; new pair only after ack |
| User clears app data; external record survives | Internal marker and Keystore key are deleted ⇒ FULL |
| Attacker edits marker bytes | HMAC verification fails ⇒ FULL |
| Attacker deletes marker only | Missing marker ⇒ FULL |
| Attacker deletes record only | Missing record ⇒ FULL |
| Process dies during a FULL examination | Existing pair is invalidated before gates start ⇒ next launch FULL |

Residual risk is documented in 4.4.11: a fully rooted/instrumented device can patch the app, and no
software-only marker can defeat that.

#### 4.4.3 File location and container format

Path (exact):

```
<filesDir>/.revcore/installation.state
```

- Directory created with `mkdirs()`; creation failure is a commit failure, never a silent success.
- Internal storage, private to the app by default.
- Not backed up as a trust source: if Android restores it without the Keystore key, authentication
  fails and startup runs FULL.

Binary layout (little-endian):

| Offset | Size | Field | Value |
|---|---|---|---|
| 0 | 4 | magic | ASCII `RVIS` |
| 4 | 2 | containerVersion | `1` |
| 6 | 2 | payloadLength | unsigned, 1…3072 |
| 8 | N | payload | UTF-8 JSON, schema version 1 |
| 8+N | 32 | mac | HMAC-SHA256 |

- Total file size bounded (8 + 3072 + 32 = 3112 bytes); larger files are rejected before allocation.
- HMAC input: `"REVCORE-INSTALLATION-V1\0"` + header bytes (offsets 0…7) + payload bytes.
- MAC compared with `MessageDigest.isEqual` (constant time).
- Payload is parsed **only after** the MAC verifies. Parsing unauthenticated bytes is forbidden.
- JSON is used for the payload because the MAC covers the exact stored bytes; canonicalization is
  irrelevant. Field order is fixed by the writer for readability only.

#### 4.4.4 Payload schema (schema version 1)

| Field | Type | Source / meaning |
|---|---|---|
| `format` | int | Marker schema = `1` |
| `installId` | string | 16 random bytes from `SecureRandom`, lowercase hex (32 chars) |
| `package` | string | `context.packageName` at commit (`com.revcore.android`) |
| `versionCode` | long | Installed versionCode |
| `versionName` | string | Installed versionName |
| `signerSha256` | string | Installed signer certificate SHA-256, lowercase hex |
| `buildIdentity` | string | Build identity from the verified signed UI manifest |
| `policyDigest` | string | SHA-256 of `assets/integrity_policy.json` |
| `uiManifestDigest` | string | SHA-256 of the signed UI/DEX manifest bytes |
| `protectedAssetsDigest` | string | Protected asset-set digest from the verified manifest |
| `assetsDigest` | string | Full asset-set digest from the verified manifest |
| `archiveFingerprint` | string | APK archive fingerprint already used by the record |
| `recordFormat` | int | Trust-record format this marker is bound to (`2`) |
| `createdAtMs` | long | Informational only; never used for trust or expiry |

No field is secret. No gate status, PASS/FAIL, score, file path, or expected hash is stored.

**Digest semantics (owner correction, mandatory):** `policyDigest`, `uiManifestDigest`,
`protectedAssetsDigest`, and `assetsDigest` are *bindings to previously verified evidence*. They are
copied from a FULL evaluation that already validated the current APK against the signed manifests and
policy. They must never become independent trust anchors, never be accepted on their own, and never
replace verification against the signed manifests and the current installed APK. The lightweight
path still performs the complete `verifyStartupRecord` examination; the marker only adds cross-file
consistency and installation linkage.

#### 4.4.5 Key management

- Alias: `revcore.installation.marker.v1` (reserved for this purpose only).
- Algorithm: `HMAC-SHA256` in `AndroidKeyStore`; purposes `SIGN`/`VERIFY`; digest `SHA-256`.
- Generated lazily on first commit with `KeyGenParameterSpec`; no user-authentication requirement, so
  ordinary app restarts and screen-lock changes do not invalidate it.
- The key is never exported, printed, logged, backed up, or reused for the record cipher, policy,
  manifest, protocol, or any K1–K9 slot.
- A missing, invalidated, or unusable key means “marker cannot be authenticated” ⇒ FULL. A new key
  is generated only during a later commit, together with a new `installId`.
- All marker load/save/commit operations are serialized under one lock to avoid generate/use races.

#### 4.4.6 Record linkage (format 2)

`TrustRecord` format 2 adds exactly two fields and keeps every existing field:

| New field | Meaning |
|---|---|
| `installId` | Must equal the marker's `installId` |
| `installationStateDigest` | SHA-256 of the complete marker file bytes (header + payload + MAC) |

The link is bidirectional in effect:

- the record is authenticated by AES-256-GCM under the existing record key;
- the marker is authenticated by HMAC under a different key;
- the record commits to the exact marker bytes, so a marker from another install cannot be paired
  with this record even if `installId` were somehow equal.

No circular dependency: the marker does not contain the record digest, so write order is simple.

Format rules:

- New code writes format `2`.
- Format `1` records are rejected as `invalid` ⇒ FULL. They are never silently upgraded in place.
- Old code reading a format `2` record rejects it by format ⇒ FULL. Downgrade is fail-closed.
- External path, filename, RVCR container, and AAD (`REVCORE-GPTQDR-V1|<package>`) stay unchanged.
- AAD does not include `installId` (it is inside the authenticated ciphertext; using it as AAD would
  require decrypting before knowing it).

#### 4.4.7 Validation algorithm (startup, release, `forceFull=false`)

Executed before any lightweight acceptance:

1. **Marker presence**: file exists, readable, size in bounds. Otherwise ⇒ FULL.
2. **Marker authentication**: magic/version/length valid; HMAC verifies under the Keystore key;
   otherwise ⇒ FULL. Do not parse the payload before this step.
3. **Marker schema**: `format == 1`, required fields present, hex lengths correct, no unknown
   mandatory semantics. Otherwise ⇒ FULL.
4. **Cheap installation identity**: `package == context.packageName`,
   `versionCode/versionName == installed`, signer in the marker equals the installed signer pin.
   Otherwise ⇒ FULL.
5. **Record presence and authentication**: `gptqdr.rvc` exists, RVCR header valid, AES-GCM tag
   verifies, JSON parses, `format == 2`. Otherwise ⇒ FULL.
6. **Cross-file identity**: `record.installId == marker.installId` and
   `record.installationStateDigest == SHA-256(marker bytes)`. Otherwise ⇒ FULL.
7. **Shared bindings**: record and marker agree on package, versionCode, versionName, signer,
   buildIdentity, policyDigest, UI-manifest digest, protected/full asset digests, archive
   fingerprint. Otherwise ⇒ FULL.
8. **Existing record validation**: the current `verifyStartupRecord` checks — current APK archive
   identity/length/metadata, signer pin, policy signature, manifest signature, UI/resource/DEX
   digests, protected assets, compiled XML structure, database schema, core vectors. Any failure ⇒
   FULL.
9. Only if 1–8 pass: return `TrustedRecord` evidence. No marker write occurs on this path.

Every failure is logged as a non-secret reason code (for example `marker=missing`,
`marker=bad-mac`, `record=invalid`, `binding=installId`) and never shown in the public UI.

#### 4.4.8 Verified invalidation before FULL (process-death rule)

To satisfy “process dies before LANJUTKAN ⇒ next launch FULL” for every FULL path, not only fresh
installs:

1. Before the first gate starts on a release FULL examination, call `invalidatePersistentTrust()`:
   - delete `installation.state` first;
   - then delete `gptqdr.rvc`.
2. **Verify absence**: check that both files no longer exist (`exists() == false` for each).
3. If either file still exists, or absence cannot be established, **do not begin the examination**:
   - do not run any gate;
   - publish a fail-closed `Failed` state with no trusted dashboard and no ECU initialization;
   - show the failure window, whose only action is `KELUAR` (no retry; master instruction).
4. Only after verified absence may the staged gates run.

Rationale: deleting the marker first removes the link, so a surviving record cannot authorize
lightweight trust. Refusing to examine while an older valid pair may still exist guarantees that
process death before `LANJUTKAN` can never fall back to a previous trusted pair.

Consequences:

- The pair exists only while it represents a completed, acknowledged installation. During an
  examination the record is intentionally absent; it reappears only after `LANJUTKAN`.
- This covers any forced FULL path: the old pair is removed before the real FULL run.
- A crash at any point leaves either nothing or a marker without a record, both of which force
  FULL.

The monitor path is separate: it never writes the pair, and on a genuine runtime failure it marks
the session untrusted, revokes the pair and ends the session. **Implemented** (`startIntegrityMonitor`
→ `verifyRuntimeIdentity` → `revokePersistentTrust` → `StartupState.Failed`); see §4.8.

#### 4.4.9 Commit algorithm (only after LANJUTKAN)

Triggered exactly once by `acknowledgeIntegrity()`, guarded by the state machine:

1. Preconditions: evidence is `FULL`, `report.passed == true` (all ten PASS), not debug, archives
   were readable, and the pending payload exists in memory. Otherwise abort (no files written).
2. Generate a fresh `installId` with `SecureRandom` (16 bytes). A new acknowledged installation
   always gets a fresh identity; after an update this is mandatory, and after a re-verification it
   keeps the pair unambiguous.
3. Build the marker payload from the pending evidence; serialize; compute HMAC.
4. Write `installation.state.tmp` in `.revcore`, flush, atomically move to `installation.state`
   (`Files.move(..., ATOMIC_MOVE, REPLACE_EXISTING)`).
5. Compute `SHA-256` of the final marker file bytes.
6. Build record format 2 with `installId` and `installationStateDigest`; encrypt with AES-256-GCM.
7. Write `gptqdr.rvc.tmp`, flush, atomically move to `gptqdr.rvc`.
8. Reload both files and repeat the cheap checks (HMAC, GCM tag, installId, marker digest,
   package/version/signer/build/policy/asset bindings).
9. On success: publish `Starting`, then run the existing DB/storage/USB/monitor initialization.
10. On any failure: best-effort delete both files, log `commit=failed`, and **never publish a
    persistent TRUST_RECORD**. Continue the current session only if the in-memory FULL report is
    still valid, all ten gates passed, and the session trust decision remains valid. If session
    trust cannot be established, remain `Failed` with all sensitive ECU functionality disabled. The
    next launch always performs FULL.

**Fresh `installId` (owner correction, mandatory):** every acknowledged FULL commit generates a new
cryptographically random `installId`; the previous value is never reused.

Ordering rationale: marker first, record second. A crash between steps leaves a marker without a
record (⇒ FULL) or nothing; a record can never exist without a valid marker. A second
`LANJUTKAN` press cannot commit twice because the state leaves `AwaitingAcknowledgement` on the
first invocation.

#### 4.4.10 Lifecycle matrix

| Event | Marker | Record | Next startup |
|---|---|---|---|
| Fresh install | absent | absent | FULL |
| Full PASS, before LANJUTKAN | absent (invalidated) | absent | FULL |
| Full PASS, after LANJUTKAN | written | written | TRUST_RECORD |
| Full PASS, commit fails | deleted | deleted | FULL |
| FULL required, invalidation cannot be verified | unchanged | unchanged | Examination refused; failure window; terminal `KELUAR` |
| Normal restart, process killed | unchanged | unchanged | TRUST_RECORD |
| Activity rotation | unchanged | unchanged | process reuse; no scan |
| Clear App Data | deleted | maybe survives | FULL (marker/key gone) |
| Uninstall/reinstall | deleted | deleted | FULL |
| APK update | old (mismatched) | old (mismatched) | FULL; new pair after ack |
| Record deleted by cleaner | present | absent | FULL |
| Marker deleted | absent | present | FULL |
| One byte changed in marker | bad HMAC | — | FULL |
| One byte changed in record | — | bad GCM tag | FULL |
| Pair copied from another device | bad HMAC | undecryptable | FULL |
| Pair copied within same device after data clear | absent | present | FULL |
| Force Stop only | unchanged | unchanged | TRUST_RECORD |
| Forced FULL (`forceFull=true`) | invalidated before gates | invalidated before gates | FULL if process dies |

#### 4.4.11 Limitations (must appear in the lifecycle report)

- A rooted, instrumented, or repackaged app can bypass or patch these checks; the marker is not a
  hardware root of trust and cannot make a fully controlled device trustworthy.
- The Android Keystore protects key material, not the app's own code. Runtime hooking is out of
  scope for this design.
- `Android/data` is user-visible and may be deleted by the user or an OEM cleaner; availability is
  not guaranteed. Deletion correctly causes FULL, never assumed trust.
- Android backup/restore may restore the marker without the Keystore key; authentication then fails
  and FULL runs. Backup rules are left unchanged because the manifest is itself protected; changing
  it would require regenerating the signed UI manifest.
- Atomic rename on external storage is best-effort at the filesystem level; the reload-and-verify
  step is the authority. A detected inconsistency deletes the pair and forces FULL.
- There is no anti-rollback counter within the same build. Replaying an old pair for the same build
  yields the same trusted state and provides no additional capability; pairs for other builds are
  rejected by build identity.
- Timestamps are informational only; no trust decision depends on the device clock.
- The marker deliberately does not prove APK integrity. Only the gates and the signed evidence do.

#### 4.4.12 Required marker tests

| Test | Expected |
|---|---|
| Commit after ack | Exact paths exist; record format 2; installId equal; digest equal |
| No ack | Neither file created; next startup FULL |
| Marker one-byte mutation | FULL; reason `marker=bad-mac` |
| Record one-byte mutation | FULL; reason `record=invalid` |
| Marker truncated / bad magic / oversized | FULL |
| Marker missing | FULL |
| Record missing | FULL |
| installId mismatch (crafted pair) | FULL |
| marker digest mismatch (crafted pair) | FULL |
| Pair copied from another device | FULL |
| Clear data (keystore key gone) | FULL |
| APK update (version/build mismatch) | FULL; fresh installId after ack |
| Process death before ack (simulated) | FULL |
| Invalidation leaves either file present | No gates run; Failed; terminal exit (`KELUAR`) |
| Commit IO failure | No trusted pair; session-trusted only if ten PASS; next launch FULL |
| Digest bindings used without current verification | Must fail: record verification still mandatory |
| Double LANJUTKAN | Single commit; no duplicate files |
| Debug build | Visible examination runs; BYPASS shown as BYPASS; no success dialog; no marker/record written. |

### 4.5 Startup decision (REQ-090, 105, 119)

```kotlin
sealed interface StartupOutcome {
    data class Reuse(val report: IntegrityReport) : StartupOutcome
    data class TrustedRecord(val report: IntegrityReport) : StartupOutcome
    data class FullVerified(val report: IntegrityReport, val pending: InstallationCommit?) : StartupOutcome
    data class Failed(val report: IntegrityReport) : StartupOutcome
}
```

`evaluateStartup(context, forceFull, observer)`:

- `forceFull=true`: skip `lastReport`; do not load or consult marker/record; invalidate the
  persistent pair (marker first, then record) and verify both are absent before running the staged
  FULL. If absence cannot be verified, return `Failed` without running any gate.
- `forceFull=false`:
  1. return `lastReport` if present;
  2. debug build ⇒ FULL (BYPASS). The owner resolved D-1: debug builds run the **same visible
     examination**; BYPASS is rendered as `BYPASS`, never as `TERVERIFIKASI`; no success dialog and
     no record write occur. If ten successful results are not established, the failure window is
     shown;
  3. marker load/validate; failure ⇒ FULL (after verified invalidation);
  4. record load/decrypt; failure ⇒ FULL (after verified invalidation);
  5. `installId` equality; failure ⇒ FULL (after verified invalidation);
  6. existing `verifyStartupRecord` bindings; failure ⇒ FULL (after verified invalidation);
  7. success ⇒ `TrustedRecord`.

Before any of these FULL paths runs its first gate, `invalidatePersistentTrust()` deletes the
marker then the record and verifies both are absent. If either remains, the outcome is `Failed`
with no gate execution.

### 4.6 ViewModel state machine (REQ-100…109, 141…144)

States:

```kotlin
sealed interface StartupState {
    data object Idle : StartupState
    data class Examining(val phases: Map<GateId, GatePhase>) : StartupState
    data class AwaitingAcknowledgement(val report: IntegrityReport) : StartupState
    data class Starting(val progress: Float) : StartupState
    data object AwaitingTerms : StartupState
    data object Ready : StartupState
    data class Failed(val report: IntegrityReport) : StartupState
}
```

- `startStartup()` idempotent; launched in `viewModelScope` from `MainActivity.onCreate`.
- FULL: set `Examining`; observer updates `phases` via `MutableStateFlow.update`.
- All PASS ⇒ `AwaitingAcknowledgement`; pending commit kept in a private field.
- `acknowledgeIntegrity()`: commit; `Starting`; run existing DB/storage/USB/monitor init;
  `AwaitingTerms` if terms not accepted else `Ready`.
- TRUST_RECORD: straight to `Starting` (no dialog, no exam).
- Failure: `Failed`; no commit; no init; `shutdownAfterFailure()` stops work and hardware.
- No retry path exists (master instruction).
- Rotation: VM survives; no new job. Process death: new VM ⇒ decision again.

`LoadingScreen` becomes presentational: receives `progress`; no longer triggers initialization.

### 4.7 UI changes

New `IntegrityExaminationScreen.kt`:

- exact title; ten rows in display order; row text only `GERBANG n` + one of the four exact states;
- no gate titles, sources, categories, hashes, paths, or failure details;
- tags `integrity_examination`, `gate_row_<gateNumber>` (`gate_row_8` is the last row);
- RevCore theme colors/typography.

New `IntegritySuccessDialog.kt`:

- exact title/icon/button; non-dismissible; tags `integrity_success_dialog`,
  `btn_continue_integrity`.

Rewrite `IntegrityFailureScreen.kt`:

- exact title `PEMERIKSAAN INTEGRITAS GAGAL`;
- one block per failed gate with its dynamic anomaly heading and sanitized evidence;
- single `KELUAR` action (tags `integrity_failure_screen`, `btn_exit_integrity`);
- no retry, no BYPASS, no dashboard.

`MainActivity`: collect `startupState`; render exam / exam+dialog / LoadingScreen / failure /
terms / dashboard. Remove integrity-relevant `rememberSaveable` flags; keep terms state in VM.

### 4.8 Runtime monitor (REQ-160…163) — implemented behavior

The monitor is **not** a second examination pipeline. It is a separate, lightweight runtime
identity check that runs while a session is already trusted.

Implemented behavior on a genuine monitor failure (non-transient, evidence-backed):

1. Mark the current session untrusted immediately in memory (`pendingCommit = null`,
   `integrityAllowsHardware = false`).
2. Disable sensitive ECU functionality via the existing integrity gate on ECU operations.
3. Safely disconnect the ECU transport and stop Live Data collection.
4. Revoke the persistent trust pair (marker first, then `gptqdr.rvc`) through
   `RevCoreIntegrity.revokePersistentTrust`; a failure is logged, never thrown.
5. Publish a `runtimeFailure` report (Gate 7 and Gate 8 FAIL, remaining gates NOT_CHECKED) and the
   exit-only failure window listing both failed gates.
6. Stop the monitor job. There is no retry and no silent FULL.

Explicitly forbidden and now absent: running the complete ten-gate FULL evaluation silently with
`observer = null`, and re-publishing a trusted state from a silent pass. Transient USB/IO errors
are not promoted into an integrity failure; they stay with the transport layer.

Source: `MainViewModel.startIntegrityMonitor`. Evidence class: SRC only.

### 4.9 Files expected to change / be created

Modified:

- `security/IntegrityModels.kt` — `GatePhase`, `GateEvent`, observer types, report helpers.
- `security/GateEvaluator.kt` — expose per-gate evaluation; signature prerequisites; aggregate.
- `security/RevCoreIntegrity.kt` — staged pipeline, startup outcome, forceFull, pending commit,
  debug visible examination, remove auto-persist.
- `security/TrustRecord.kt` — format 2 `installId`, loader compatibility rejection.
- `security/UiIntegrityManifest.kt` — split signature / UI resources / structure+identity / DEX.
- `ui/MainViewModel.kt` — state machine, ack commit, init continuation, exit-only shutdown,
  lightweight monitor.
- `MainActivity.kt` — state-driven rendering, start from Activity, `shutdownAfterFailure`.
- `ui/screens/LoadingScreen.kt` — presentational progress.
- `ui/screens/IntegrityFailureScreen.kt` — dynamic anomaly failure window.
- tests under `app/src/test/...`.

New:

- `security/GateObserver.kt` (or inside `IntegrityModels.kt`).
- `security/InstallationStateStore.kt`.
- `security/InstallationCommit.kt` (if not nested).
- `security/IntegrityDiagnostics.kt` — anomaly categories, sanitizer, phase labels.
- `ui/screens/IntegrityExaminationScreen.kt`.
- `ui/screens/IntegritySuccessDialog.kt`.
- test files listed in 4.10.

### 4.10 Test plan

This is the Phase B **plan**. It is not evidence that the listed tests exist. Phase C execution
status is in §6.2, and every planned-but-unwritten test is named as missing evidence in §1 and
§7.3.

Unit (JVM):

- gate observer ordering, RUNNING-before-terminal, staged order, Gate 8 last;
- no false PASS on thrown exception/unreadable archive/missing manifest/invalid signature;
- prerequisite downgrade;
- debug BYPASS ≠ PASS;
- forceFull with valid record ⇒ FULL (spy/counter);
- marker/record: valid pair, missing/corrupt marker, missing/corrupt record, installId mismatch,
  build/signer/policy/asset digest mismatch, format 1 rejected;
- commit only after acknowledgement (no files before ack; files after ack);
- state machine transitions (fresh, record, failure, rotation idempotence);
- monitor failure does not emit examination events.

Instrumented (debug; synthetic states for UI) — **BLOCKED, not written** (no `androidTest`
source set and no Compose UI-test artifacts in the offline Gradle cache):

- screen title, ten rows, exact states, tags, Gate 8 last, no disclosure text;
- dialog non-dismissible (back/outside don't close), LANJUTKAN triggers ack;
- failure screen exact strings, dynamic headings, and single `KELUAR`;
- rotation during examination keeps VM job and state;
- restored Activity does not show dashboard without state.

APK/device (deferred, blocker B-1):

- full mutation matrix rerun on new build (resource, icon, label, credits, XML, arsc, missing,
  extra, duplicate, DEX-unchanged);
- real FULL/TRUST_RECORD timing;
- Clear Data, update, missing/corrupt files, force stop;
- MT Manager repack scenarios.

### 4.11 Execution order after approval

1. Add observer/model + split UI manifest verification; run existing suite (expect green).
2. Staged pipeline + prerequisites; add gate unit tests.
3. Installation marker + record format 2; add store tests.
4. Move persistence to commit; startup outcome + forceFull; tests.
5. ViewModel state machine + Activity/LoadingScreen changes; tests.
6. Exam screen + success dialog + failure rewrite; UI tests.
7. Runtime monitor separation; tests. **Achieved (D-2 corrected).**
8. Full regression suite; instrumentation; report generation.
9. Stop. Present evidence. No APK build/sign.

### 4.12 Rollback

Changes are additive/refactor-level within the security package and startup UI. No Gradle,
signing, database, protocol, or asset changes. Rollback is a source-level revert of the listed
files; the existing `gptqdr.rvc` format 1 remains readable by the old code if the new code is
reverted, and format 2 files are simply rejected by old code (⇒ FULL), which is safe.

---

## 5. APPROVAL GATE — CURRENT STATE

| # | Item requiring approval | Status |
|---|---|---|
| 1 | Phase A requirement checklist and Phase B implementation plan. | APPROVED (with corrections 1–5). |
| 2 | Marker authentication choice (HMAC-SHA256, dedicated Keystore alias `revcore.installation.marker.v1`). | APPROVED (B-4). |
| 3 | Commit-failure behavior (B-5: no persistent trust; session continues only on a still-valid ten-PASS decision). | APPROVED. |
| 4 | Debug-build exemption from the visible examination and success dialog (B-6). | **RESOLVED by the owner master instruction (2026-11-16): no exemption. Debug builds show the examination; BYPASS is visible; no success dialog; no record.** |
| 5 | Phase C source implementation plus tests inside the stated boundary. | AUTHORIZED AND EXECUTED (including the 2026-11-16 visible-examination / diagnostics / fail-closed task). |
| 6 | Release build, signing, export, publication, or replacement of any APK. | **NOT AUTHORIZED.** No artifact was produced in Phase C or in any later revision. |
| 7 | Device, emulator, MT Manager, and physical ECU evidence for the new code. | **NOT AUTHORIZED → BLOCKED** (B-1, B-2, B-3). |

Revision 4 aligns this document with the master instruction: D-1 and D-2 are resolved, retry is
removed, the failure window is evidence-bearing and exit-only, and debug runs the visible
examination. Source and JVM tests changed; no Gradle, signing, or APK change was made.

---

## 6. PHASE C COMPLIANCE SUMMARY

**Phase C is not fully verified.** Source and JVM tests exist for most of the design; no
instrumented, emulator, device, APK, or hardware evidence was produced for the new code.

### 6.1 Individual requirements by status

| Status | Count | What it means here |
|---|---|---|
| `VERIFIED` | 56 | Acceptance evidence exists and is named in the row. For process requirements the evidence is the absence of a forbidden action (no build, no upload, no change to identity/signing); for gate logic it is executed JVM tests; for deliverables it is the presence of the named report. |
| `IMPLEMENTED` | 105 | Source behavior exists and was located, but the requirement's acceptance evidence was not executed. Never read as verified. |
| `BLOCKED` | 2 | REQ-092 (forceFull record-substitution test) and REQ-121 (real timing measurement). Both need a built APK or `Context`-bearing harness that is not authorized/available. |
| `NOT_IMPLEMENTED` | 5 | REQ-091, REQ-150, REQ-151, REQ-152, REQ-153 — deliberately superseded by the master instruction (no retry; failure window retitled and evidence-bearing). Rows retained for ID immutability. |
| `NOT_STARTED` | 1 | REQ-252 — future authorized build naming; no build authorized. |
| `IN_PROGRESS` | 0 | Nothing is claimed as in progress. |
| **Total** | **169** | Individual REQ IDs 001–253 as originally assigned, gaps preserved. Group T defines no REQ IDs and is tracked separately in §7.5. |

Counts above are mechanical, taken from the §1 table, not estimated.

### 6.2 Test accounting

| Class | Executed in Phase C | Detail |
|---|---|---|
| JVM unit tests | **308 tests, 0 skipped, 0 failures, 0 errors (35 classes)** | 295 earlier + 13 new `IntegrityDiagnosticsTest` (anomaly headings, category mapping, gate ordering, BYPASS rendering, sanitizer, runtimeFailure, source line). |
| Kotlin compilation | 2 variants | `:app:compileDebugKotlin` and `:app:compileReleaseKotlin` both succeeded after the change. |
| Instrumented tests (`IT`) | **0 executed, 0 written in Phase C** | Every UI, lifecycle, and `Context`-dependent claim is source-only. |
| Emulator runs (`EMU`) | **0 for the new code** | Prior-phase emulator evidence belongs to the pre-Sentinel build and is labeled "prior" wherever it appears. |
| Device runs (`DEV`) | **0** | — |
| APK inspection (`APK`) | **0 new artifacts** | No build was authorized. The current official artifact `RevCore build 151126.apk` (SHA-256 `1128af1f…`) predates every Sentinel change; it cannot verify this code. |
| Physical ECU/adapter (`HW`) | **0** | No hardware evidence exists. |

Test command: `gradle.bat :app:testDebugUnitTest --offline --console=plain` → `BUILD SUCCESSFUL`.

### 6.3 Requirements whose required test was not executed

These rows are `IMPLEMENTED` or `BLOCKED`, with the missing evidence named in §1. They are the
ones most likely to be mistaken for done:

- **REQ-064** (commit only after `LANJUTKAN`): source path only; no test proves nothing is
  persisted before acknowledgement, and no test proves the commit happens after it.
- **REQ-075** (refuse FULL when invalidation cannot be verified): source path only; no
  undeletable-file/refusal test.
- **REQ-077** (commit failure never publishes trust): source path only; no commit-failure or
  session-continuation test.
- **REQ-090 / REQ-092** (`forceFull` never consults the record): source reviewed; the required
  regression test is not written, so REQ-092 is `BLOCKED`.
- **REQ-227 / REQ-228** (store and pair lifecycle; rotation, process death, restored state):
  marker container cases are JVM-tested; everything needing `Context` or an Activity is not.
- **REQ-229 / REQ-160 / REQ-161 / REQ-163** (runtime monitor): now `IMPLEMENTED`; source-only
  evidence, no executed monitor test.
- **REQ-121** (measured FULL vs TRUST_RECORD timing): `BLOCKED`; no number is reported because
  none was measured.
- **REQ-022, REQ-130…137, REQ-140, REQ-144** (examination screen, dialog): composables exist;
  `IntegrityDiagnosticsTest` pins labels/order/sanitization, but no instrumented UI assertion ran.
- **REQ-150…153**: superseded by the master instruction; the new failure window has no
  instrumented assertion either.
- **REQ-226** (UI mutation matrix): only the JVM subset; the APK matrix was not rerun.

### 6.4 Owner decisions outstanding

1. **Build/hardware authorization (B-1, B-2, B-3).** Needed for REQ-092, REQ-121, REQ-226, the
   Group T matrix, and all device/ECU evidence. Not granted.
2. **Instrumented UI/lifecycle coverage.** No `androidTest` source set exists and the offline
   Gradle cache has no Compose UI-test artifacts; adding them needs a dependency decision that is
   outside this task.

D-1 and D-2 are closed by the owner master instruction and are no longer open.

### 6.5 Deviations from the original requirements

| ID | Deviation | Requirement impact |
|---|---|---|
| D-1 | **Resolved.** Debug builds show the same visible examination; BYPASS is rendered as `BYPASS`; no success dialog and no record write in debug. | REQ-018 `IMPLEMENTED`; REQ-224 unchanged |
| D-2 | **Resolved.** The runtime monitor no longer runs a silent FULL; it performs the lightweight identity check and, on failure, revokes the pair and ends the session untrusted. | REQ-160, 161, 163, 229 `IMPLEMENTED` |
| D-3 | The success dialog has no success icon; the earlier requirement named one. The master instruction does not require an icon. | REQ-140 `IMPLEMENTED` with the visual gap stated |
| D-4 | Retry (`PERIKSA ULANG`) and the generic failure wording were deliberately removed by the owner master instruction. | REQ-091, REQ-150…153 recorded `NOT_IMPLEMENTED` as superseded, not silently deleted |

No gate identity, gate order, or release rule was altered to fit the implementation.

### 6.6 Residual risks

1. **Failure-window disclosure.** Sanitization is regex/ordering based and JVM-tested against the
   current diagnostic phrases; a new unrubbed phrase could leak an internal term.
2. **Untested failure paths.** Invalidation refusal, commit failure, stale-pair handling, and the
   monitor failure path are reviewed but never executed; a regression there would fail closed in
   design, not in proof.
3. **Device behavior unproven.** Compose rendering of ten rows, rotation, process death before
   and after `LANJUTKAN`, Clear Data, and update flows have no runtime evidence.
4. **Keystore behavior unproven.** HMAC alias creation, non-exportability, and atomic file
   replacement on real app storage were not exercised on a device.
5. **No artifact contains this code.** The Sentinel pipeline has never executed inside a signed
   APK; only unit-tested production classes compiled.
6. **Tamper resistance unproven in the real world.** MT Manager repack, rooted ROM, and physical
   ECU scenarios remain untested; no unit test substitutes for them.

### 6.7 Release boundary

- No APK was built, signed, exported, published, or replaced in Phase C or in revision 4.
- Revision 4 changed application source and JVM tests only under the master instruction.
- The current distributable remains `dist/RevCore build 151126.apk`
  (SHA-256 `1128af1ff7bc15f1f614e6e177fd2a24bb0ef3783eed0373d5687eb6adfa86aa`), which predates
  the Sentinel changes and must be re-verified before any distribution decision.
- **No statement in this document may be read as "Phase C fully verified".**

---

## 7. UNRESOLVED ITEMS AND REVIEW REQUEST

### 7.1 Owner decisions (open)

| ID | Decision | Effect of leaving it open |
|---|---|---|
| B-1/B-3 | Whether to authorize a build for APK mutation and MT Manager evidence. | REQ-092, REQ-226, REQ-121 stay `BLOCKED`. |
| B-2 | Whether to authorize device/hardware testing. | Group T and all `DEV`/`HW` evidence stay `BLOCKED`. |
| I-1 | Whether to add Compose UI-test dependencies for instrumented coverage. | All UI/lifecycle rows stay source-only. |

D-1 and D-2 are closed by the owner master instruction.

### 7.2 Deviations

Summarized in §6.5 (D-1 resolved, D-2 resolved, D-3 icon gap, D-4 superseded retry wording).
Full requirement-level consequences are in the §1 rows for REQ-018, REQ-091, REQ-140,
REQ-150…153, REQ-160, REQ-161, REQ-163, and REQ-229.

### 7.3 Blocked tests (complete list)

1. `forceFull` record-substitution regression (REQ-092).
2. Real FULL and TRUST_RECORD timing (REQ-121).
3. Commit-order and no-persist-before-acknowledgement (REQ-061, REQ-063, REQ-064).
4. Invalidation-refusal with an undeletable file (REQ-075).
5. Commit failure and session continuation (REQ-077).
6. Store/pair lifecycle across update, Clear Data, and reinstall (REQ-227).
7. Rotation, process death, restored state, duplicate-start prevention (REQ-228).
8. Examination screen rows and states (REQ-022, REQ-130…137).
9. Success dialog, dismissal blocking, `LANJUTKAN` commit (REQ-062, REQ-140, REQ-141, REQ-144).
10. Failure window dynamic headings, evidence lines, and single `KELUAR` (supersedes REQ-150…153).
11. APK UI mutation matrix rerun on a new build (REQ-226).
12. Keystore HMAC and atomic replacement on real storage (REQ-193, REQ-196 region).
13. Group T scenarios 1–24 (emulator/device/hardware).
14. Physical ECU, K-Line, Live Data, DTC, and flash regression (diagnostic preservation).

### 7.4 Residual risks

See §6.6 items 1–6. The former R-1 (silent monitor FULL) no longer exists; the highest
remaining risk is disclosure drift in the sanitizer (item 1).

### 7.5 Device/emulator/physical matrix (Group T)

Group T defines 24 scenarios, not individual REQ IDs. All 24 are unevaluated for the new code:
`NOT_STARTED` where no attempt was made, `BLOCKED` where an APK or hardware is required. Prior
emulator results (API 37, x86_64) describe the pre-Sentinel build and are not evidence for this
work.

### 7.6 Request to the owner

1. Accept or reject this revision as the authoritative record.
2. Decide when to authorize a build and device/hardware evidence run.
3. Decide whether to add Compose UI-test dependencies for instrumented coverage.

No APK build, signing, export, or publication occurs under the current authorization.
