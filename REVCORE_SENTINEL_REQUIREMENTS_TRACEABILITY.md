# REVCORE SENTINEL — PHASE A REQUIREMENT TRACEABILITY & PHASE B IMPLEMENTATION PLAN

Document ID: `REVCORE-SENTINEL-PHASE-AB`
Date: 2026-11-15
Project baseline: `C:\Users\Lord Otoy\Documents\Qoder\work\revcore`
State at time of writing: **source unchanged for this task; no APK built, signed, exported, or published.**
Approval: **Phase A/B approved with required corrections; Phase C source and tests authorized.**
No release APK build/sign is authorized. Predecessor audit: `REVCORE_VISIBLE_GATE_EXAMINATION_AUDIT.md` (findings F-1 … F-10).

This document is the Phase A checklist required by the execution compliance contract and the
Phase B implementation plan. Implementation does not begin until the owner approves this document.

---

## 0. READING RULES

### 0.1 Status vocabulary (fixed by contract)

| Status | Meaning used in this document |
|---|---|
| `NOT_STARTED` | No work performed for this requirement in the current task. |
| `IN_PROGRESS` | Work for this requirement is underway (this document or active analysis). |
| `IMPLEMENTED` | Source behavior exists and was located by audit, but the requirement's acceptance evidence for this task is not complete. |
| `VERIFIED` | Acceptance evidence exists: unit test, APK/archive inspection, emulator/device run, or a documented source-level proof where runtime proof is impossible. The evidence class is named in the row or in the referenced report. |
| `BLOCKED` | Cannot progress without owner decision, authorization, or unavailable hardware/environment. |
| `NOT_IMPLEMENTED` | The audit established that the required behavior is absent or contradicted by current source. |

`IMPLEMENTED` is never used as a synonym for `VERIFIED`. Source inspection is never presented as
runtime proof. A unit test is never presented as proof of real-world tamper resistance.

### 0.2 Evidence classes

- **SRC** — source inspection only.
- **UT** — JVM/Robolectric unit test.
- **IT** — instrumented Android test.
- **APK** — archive/signature inspection of a built artifact.
- **EMU** — emulator runtime evidence.
- **DEV** — physical installed-device evidence.
- **HW** — physical motorcycle/ECU/adapter evidence.

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

## 1. PHASE A — IMMUTABLE REQUIREMENT CHECKLIST

### Group A — Process, authorization, and evidence discipline

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-001 | Audit the real source before modifying anything. | Read the existing gates, evaluator, trust record, archive verification, UI manifest, lifecycle, runtime monitor; map facts to files; report F-1…F-10. | Whole `security/` package, `MainActivity`, `MainViewModel`, `LoadingScreen` | SRC | `REVCORE_VISIBLE_GATE_EXAMINATION_AUDIT.md` | VERIFIED (SRC) |
| REQ-002 | Use the current source as baseline; do not replace the security architecture wholesale. | Refactor in place; preserve gate identities, policy format, manifest signature scheme, Keystore record container. | `GateEvaluator`, `RevCoreIntegrity`, `UiIntegrityManifest`, `TrustRecord` | SRC review of diff | Diff summary showing additive/refactor changes only | NOT_STARTED |
| REQ-003 | Preserve valid cryptographic verification and TRUST_RECORD checks. | Do not delete or weaken existing bindings; extend record format compatibly (old format rejected → FULL). | `RevCoreIntegrity.verifyStartupRecord`, `TrustRecord` | SRC + UT | Existing checks enumerated in `REVCORE_TEN_GATE_MAPPING.md`; record tests | VERIFIED (SRC, existing suite) |
| REQ-004 | Do not build, sign, export, or publish an official release APK during this task. | No Gradle `assembleRelease`, no signing, no `dist/` artifact for this change. | Build configuration | Process audit | No new APK in `dist/`; no signing invocation | VERIFIED (compliance to date) |
| REQ-005 | Produce Phase A checklist and Phase B plan before source changes; wait for approval. | Publish this document; no code edits until owner approval. | This document | Process | Owner approval message | IN_PROGRESS |
| REQ-006 | Never silently skip, substitute, or reduce a requirement. | Every requirement in this checklist is either implemented or explicitly marked BLOCKED/NOT_IMPLEMENTED with reason. | All | Phase D/E audit | Requirement-by-requirement final table | IN_PROGRESS |
| REQ-007 | Distinguish IMPLEMENTED from VERIFIED; no invented evidence. | Evidence class recorded per requirement; untested scenarios marked NOT TESTED. | All | Phase E audit | `REVCORE_TEST_REPORT.md` | IN_PROGRESS |
| REQ-008 | Stop and ask when blocked, impossible, or unsafe. | Surface blockers in Section 3 instead of improvising. | All | Process | Blockers list | IN_PROGRESS |
| REQ-009 | Assign unique REQ IDs and keep them immutable. | This checklist is the single source of truth; later changes append, never renumber. | This document | Review | Stable IDs in final compliance table | VERIFIED |

### Group B — Ten real gates and staged orchestration

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-010 | Ten gates must perform real checks; identities/responsibilities preserved. | Keep GateId titles and existing evidence per gate; do not invent gates. | `IntegrityModels.GateId`, `GateEvaluator` | SRC + UT | `REVCORE_TEN_GATE_MAPPING.md` | VERIFIED (SRC, existing tests) |
| REQ-011 | Gate 8 is the final aggregate gate and is not renumbered. | `FINAL_TRUST` remains number 8; evaluated last; PASS only when all nine others PASS. | `GateEvaluator.evaluate` | UT | Gate-8 aggregation tests | VERIFIED (SRC/UT) |
| REQ-012 | Real staged sequence `1,2,3,4,5,6,7,9,10,8`; no batch-then-fake-progress. | Evidence acquisition and evaluation for each gate execute in its own step, in order, after its RUNNING event. | `RevCoreIntegrity.runFullEvaluation`, new pipeline | UT (event order), IT | Ordered event log transcript | NOT_IMPLEMENTED |
| REQ-013 | Observer reports real gate state. | `GateObserver` receives WAITING/RUNNING/PASSED/FAILED; RUNNING emitted immediately before that gate's verification begins; terminal state only after its result exists. | New `GateObserver`/`GatePhase`; `GateEvaluator` | UT | Event sequence tests | NOT_IMPLEMENTED |
| REQ-014 | Gate lifecycle `WAITING → RUNNING → PASSED/FAILED`. | No gate receives PASSED without RUNNING; no terminal state before verification. | Observer + evaluator | UT | Lifecycle tests | NOT_IMPLEMENTED |
| REQ-015 | Never manufacture PASS; exceptions/missing evidence/unsupported checks are not PASS. | Gate functions fail closed; pipeline converts thrown errors into FAILED for that gate and overall FAILED. | `GateEvaluator`, pipeline try/catch | UT (fault injection) | No-false-PASS tests | IMPLEMENTED (SRC) |
| REQ-016 | A dependent gate must not PASS after its prerequisite failed. | Explicit prerequisite map; result downgraded to FAILED when prerequisite is not PASSED. | New prerequisite map in evaluator/pipeline | UT | Prerequisite tests | NOT_IMPLEMENTED |
| REQ-017 | Independent checks may continue after a failure, but overall stays FAILED. | Pipeline continues remaining steps after a FAIL; Gate 8 FAIL. | Pipeline | UT | Continued-execution test | IMPLEMENTED (evaluator runs all) |
| REQ-018 | Debug BYPASS is visibly distinct from PASS. | `GateStatus.BYPASS` label `DEBUG`; never counted as PASS; success dialog never shown. | `IntegrityModels`, UI | UT + UI test | BYPASS≠PASS tests | VERIFIED (SRC/UT) |
| REQ-019 | Release build fails closed if any mandatory gate fails. | `IntegrityReport.passed` requires all PASS; `allowsRuntime` false on any FAIL. | `IntegrityModels` | UT | Fail-closed tests | VERIFIED (SRC/UT) |
| REQ-020 | No artificial delays, fake progress, prefilled results. | No `delay()` in evaluation; UI reflects real events only. | Pipeline/UI | SRC + review | No-simulation review | NOT_IMPLEMENTED (UI absent; constraint recorded) |
| REQ-021 | Gate 8 PASS only if all nine genuinely passed. | Aggregate counts only PASS; BYPASS/FAIL/NOT_CHECKED blocks. | `GateEvaluator` | UT | Aggregation tests | VERIFIED (SRC; strengthen tests) |
| REQ-022 | Ten rows show actual per-gate states. | UI binds to observer state map. | `IntegrityExaminationScreen` | IT | `gate_row_1…10` state tests | NOT_IMPLEMENTED |

### Group C — Byte-level UI/resource integrity

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-030 | Signed UI/resource integrity manifest exists. | Detached signed manifest over UI entries and DEX; signature verified under pinned official certificate. | `assets/ui_integrity_manifest.json`, `UiIntegrityManifest` | APK + UT | Signature verification tests | VERIFIED (APK/UT) |
| REQ-031 | Protect `AndroidManifest.xml`, `resources.arsc`, compiled XML, `res/**` strings/labels/About/credits/icons/mipmaps/logos/themes/colors/layouts/menus/config XML. | Inventory covers all `res/**` entries plus manifest and resource table; byte digests for each. | `UiIntegrityManifest.isUiEntry`, `runFullEvaluation` | APK + UT | Entry inventory, digest tests | VERIFIED (APK/UT) |
| REQ-032 | Do not protect filenames only. | Per-entry SHA-256 over actual bytes; size only as auxiliary. | UI verification | UT | Hash coverage tests | VERIFIED |
| REQ-033 | Read actual installed APK bytes and compare to trusted signed manifest. | `ApkArchiveSet` reads base + splits; hashes computed from archive bytes. | `ApkArchiveSet`, `UiIntegrityManifest` | SRC + UT | Byte-hash tests | VERIFIED |
| REQ-034 | Reject missing, unexpected, duplicate/ambiguous entries and one-byte changes. | Explicit inventory comparison; duplicates detected; digest mismatch fails. | UI verification | UT + APK mutation (prior) | Mutation test results | VERIFIED (prior matrix; must rerun after change) |
| REQ-035 | Verify manifest authenticity before trusting expected hashes. | Signature must validate under pinned certificate before digest comparison is accepted; each gate that consumes manifest evidence must require a valid signature. | `UiIntegrityManifest.verify`, `GateEvaluator` | UT | Invalid-signature tests | IMPLEMENTED (signature checked; per-gate prerequisite ordering to be hardened) |
| REQ-036 | No filename-only, size-only, timestamp-only substitutes. | Digest comparison is mandatory. | UI verification | SRC | Review | VERIFIED |
| REQ-037 | Structural compiled-XML checks supplement hashes. | Structure tokens (label, icon, activity, navigation/resource relationships) verified in addition to digest. | `UiIntegrityManifest` structure checks | UT | Structure tests | VERIFIED (SRC/UT) |
| REQ-038 | Do not decrypt compiled XML and feed arbitrary encrypted XML to Android. | No encrypted XML scheme introduced; standard archive/resource parsing only. | Design | SRC | Review | VERIFIED |
| REQ-039 | Resource-only modification detected even when DEX unchanged. | UI resource digests are independent of DEX digests. | Gate 2/3 | UT + APK mutation | Unchanged-DEX mutation test | VERIFIED (prior matrix; rerun planned) |
| REQ-040 | UI protection failure denies trust, dashboard, and shows generic failure. | Gate FAILED; `allowsRuntime=false`; generic failure screen; forensic detail only in logs. | Gate + UI | UT + IT | Failure flow test | IMPLEMENTED (denial yes; generic screen NOT_IMPLEMENTED — see REQ-140) |

### Group D — APK identity and signer authenticity

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-041 | Preserve `applicationId = com.revcore.android`. | No namespace/applicationId change. | `app/build.gradle.kts` | Build config inspection | Diff shows no change | VERIFIED |
| REQ-042 | Preserve official signing identity and certificate. | No new certificate, no signing config change, no key exposure. | Gradle signing config | Config inspection | Diff shows no change | VERIFIED |
| REQ-043 | Confirm recorded fingerprint `c649cb4f…18d098` against official release configuration. | Compare to `BuildConfig.EXPECTED_SIGNER_SHA256` and project records before relying on it. | `BuildConfig`, signing records | SRC + APK | Fingerprint match evidence | VERIFIED (prior APK verification) |
| REQ-044 | Verify installed signer via supported package-signing APIs. | Use `PackageManager` signing info / archive signer verification, not manifest text. | `RevCoreIntegrity.apkSigners` | UT/APK | Signer tests | VERIFIED |
| REQ-045 | Do not trust package name, versionCode/Name, local config, unsigned manifest, untrusted fingerprint alone. | Signer pin and signed policy are mandatory for release trust. | Gate 1/5 | UT | Negative tests | VERIFIED |
| REQ-046 | Bind trusted policy and protected asset inventory to official signer. | Policy and UI manifest signatures validated under pinned signer; digests derived only after signature acceptance. | Gates 1/2/5 | UT | Binding tests | IMPLEMENTED (strengthen per REQ-035) |

### Group E — Two-file trust design

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-050 | External record exact path `Android/data/com.revcore.android/files/.revcore/gptqdr.rvc`, external, `.rvc` binary, not renamed/moved. | Keep `getExternalFilesDir(null)/.revcore/gptqdr.rvc`; versioned binary container `RVCR`. | `TrustRecordStore` | SRC + DEV | Path and header evidence | VERIFIED (current code/prior device) |
| REQ-051 | Internal marker exact path `filesDir/.revcore/installation.state`. | New store writes exactly this filename under `filesDir/.revcore/`. | New `InstallationStateStore` | SRC + DEV | File existence/path test | NOT_IMPLEMENTED |
| REQ-052 | Both files share/authenticate same `installId`, bound to package, versionCode, versionName, APK/build identity, signer fingerprint, policy digest, protected asset-set digest, format version, verification metadata. | Add `installId` to record (format 2); marker stores/authenticates the same ID and bindings; startup rejects mismatch. | `TrustRecord`, new marker | UT | Binding/mismatch tests | NOT_IMPLEMENTED |
| REQ-053 | Build identity must distinguish builds with identical version numbers. | Use archive fingerprint / signed-policy+asset digest / buildIdentity, not versionCode alone. | Record + binding | UT | Same-version-different-build test | VERIFIED (record has buildIdentity/archiveFingerprint) |
| REQ-054 | Files must be authenticated; Keystore-backed device-local key; no static secret; handle unavailable/invalidated keys. | Record: AES-256-GCM Keystore key. Marker: HMAC-SHA256 with separate Keystore key or GCM; missing/invalid key ⇒ marker invalid ⇒ FULL. | `TrustRecordStore`, new marker | UT + SRC | Authentication tests | IMPLEMENTED (record); NOT_IMPLEMENTED (marker) |
| REQ-055 | AES encryption alone is not authenticity. | Use AEAD (GCM) and/or MAC; verify tag before parsing. | Record | SRC | Review | VERIFIED |
| REQ-056 | Do not reuse K1–K9; do not create fictitious K10. | Marker uses a new dedicated Keystore alias, not protocol key slots. | New marker | SRC | Key inventory review | VERIFIED (design constraint) |
| REQ-057 | Document cryptographic design and limitations. | Write design section in trust-record lifecycle report. | Reports | Review | `REVCORE_TRUST_RECORD_LIFECYCLE_REPORT.md` | NOT_STARTED |

### Group F — Marker and record lifecycle

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-060 | Fresh installation runs FULL verification. | No marker/record ⇒ FULL with examination UI. | Startup decision | UT/EMU | Fresh-install test | VERIFIED (current behavior; marker adds strictness) |
| REQ-061 | Do not create marker/record before all ten gates pass. | Commit path only callable with a PASSED report; no write inside evaluation. | `RevCoreIntegrity`, VM | UT | No-write-on-failure/evaluation test | IMPLEMENTED (record); needs move out of evaluation (see REQ-064) |
| REQ-062 | After ten genuine PASS, show success acknowledgement dialog. | FULL + all PASS ⇒ non-dismissible dialog. | UI/VM | IT | Dialog test | NOT_IMPLEMENTED |
| REQ-063 | Wait for `LANJUTKAN`. | No commit and no dashboard until button press. | UI/VM | IT | No-commit-before-ack test | NOT_IMPLEMENTED |
| REQ-064 | Commit marker and record only after `LANJUTKAN`. | Before any release FULL, delete marker then record and verify both are absent; refuse the examination if absence is not verified. Remove automatic persist from `runFullEvaluation`; hold a pending installation payload in memory; commit in `acknowledgeIntegrity()`. | `RevCoreIntegrity.persistRecord`, VM | UT | Commit-after-ack and verified-invalidation tests | NOT_IMPLEMENTED |
| REQ-065 | Write both files safely and consistently. | Atomic temp+rename; marker then record; reload and re-verify; on partial failure remove both and force FULL next launch. | New commit routine | UT/EMU | Interrupted-write tests | IMPLEMENTED (record atomic); marker NOT_IMPLEMENTED |
| REQ-066 | Process death before `LANJUTKAN` ⇒ next launch FULL. | Nothing persisted before ack; existing pair invalidated and verified absent before gates; no marker/record ⇒ FULL. | Commit design | UT | Process-death test (simulated by no-commit state) | NOT_IMPLEMENTED |
| REQ-067 | Missing/corrupt/unauthenticated/inconsistent either file ⇒ reject TRUST_RECORD. | Loader validates container, MAC/tag, structure, bindings; any failure ⇒ FULL. | Stores | UT | Corruption tests | IMPLEMENTED (record); marker NOT_IMPLEMENTED |
| REQ-068 | `installId` mismatch ⇒ reject. | Compare marker vs record before accepting. | Startup validation | UT | Mismatch test | NOT_IMPLEMENTED |
| REQ-069 | Different APK/build identity ⇒ reject. | Keep existing archive/build binding; add marker binding. | `verifyStartupRecord` | UT | Build-identity test | VERIFIED (record); marker NOT_IMPLEMENTED |
| REQ-070 | Different signer/policy/asset-set digest ⇒ reject. | Keep existing checks; marker carries same fields and is compared. | `verifyStartupRecord` | UT | Mismatch tests | VERIFIED (record); marker NOT_IMPLEMENTED |
| REQ-071 | New build after update creates fresh installation identity and binds both files. | Build mismatch ⇒ FULL ⇒ new random `installId` at every acknowledged commit; never reuse the previous ID. | Commit path | UT/EMU | Update test | NOT_IMPLEMENTED |
| REQ-072 | Do not silently accept old record after update; detect stale records. | Build/version identity mismatch rejects even though Android/data survives. | Startup validation | UT/EMU | Stale-record test | IMPLEMENTED (needs retest) |
| REQ-073 | Clear App Data removes marker; surviving external record must not bypass FULL. | Keystore keys die with data clear ⇒ record undecryptable; missing marker ⇒ FULL. | Stores | EMU | Clear-data test | IMPLEMENTED (record key loss); marker NOT_IMPLEMENTED |
| REQ-074 | Deleted file ⇒ FULL, never assumed trust. | Missing either file ⇒ FULL. | Startup decision | UT | Missing-file tests | VERIFIED (record); marker NOT_IMPLEMENTED |
| REQ-075 | Verified invalidation before FULL: marker first, then record. | If either file remains, do not begin gates; publish generic failure and require `PERIKSA ULANG`. | New invalidation routine | UT | Refusal test with undeletable file | NOT_IMPLEMENTED |
| REQ-076 | No trusted pair may authorize a new process while a FULL examination is pending. | Delete and verify absence before the first gate on every release FULL, including retries. | Startup decision | UT | Process-death/invalidation tests | NOT_IMPLEMENTED |
| REQ-077 | Commit failure must not publish persistent trust. | Continue only with a still-valid in-memory ten-PASS FULL decision; otherwise `Failed`; next launch FULL. | VM/commit | UT | Commit-failure tests | NOT_IMPLEMENTED |
| REQ-078 | Marker digests are bindings, never independent trust anchors. | Digests copied from verified evidence; lightweight path still runs full `verifyStartupRecord` against the current APK and signed manifests. | Record/marker validation | SRC + UT | Digest-only acceptance must fail | NOT_IMPLEMENTED |
| REQ-079 | Do not simplify lightweight validation to marker/installId/file existence. | Preserve every existing record check; marker is additive. | `verifyStartupRecord` | SRC + UT | Check inventory + negative tests | VERIFIED (existing); must remain after changes |

### Group G — TRUST_RECORD strength

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-080 | Preserve existing TRUST_RECORD checks: signer pin, signed policy, policy digest, UI/resource digests, archive fingerprint, APK length/metadata, protected assets, XML structure, DB schema, core vectors. | Keep `verifyStartupRecord` bindings; add marker/installId; do not reduce. | `RevCoreIntegrity` | SRC + UT | Check inventory in mapping doc | VERIFIED (SRC) |
| REQ-081 | Do not reduce to `fileExists` or `installId` comparison. | Lightweight path re-verifies signatures, digests, archive metadata. | `verifyStartupRecord` | SRC + UT | Bypass tests | VERIFIED |
| REQ-082 | If current APK cannot be authenticated, fall back to FULL. | Null/failed lightweight verification ⇒ `evaluate` FULL. | `evaluateStartup` | UT | Fallback test | VERIFIED |

### Group H — `forceFull` defect

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-090 | `forceFull=true` must never consult the trust record. | Skip `lastReport` **and** skip record loading when true. | `RevCoreIntegrity.evaluateStartup` | UT | forceFull test with valid record present | NOT_IMPLEMENTED (defect confirmed: `forceFull` only bypasses `lastReport`) |
| REQ-091 | Retry button invokes real FULL. | `recheckIntegrity` uses forceFull and shows examination UI. | VM | IT | Retry flow test | NOT_IMPLEMENTED |
| REQ-092 | Regression tests prove forceFull never accepts the record as substitute. | Unit test with a valid record file and a spy observer/counter. | Tests | UT | Test result | NOT_IMPLEMENTED |

### Group I — Startup lifecycle

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-100 | Process-scoped startup state machine owned by ViewModel (`viewModelScope`). | Explicit states: `Examining`, `AwaitingAcknowledgement`, `Starting`, `AwaitingTerms`, `Ready`, `Failed`, `Idle`. | `MainViewModel` | SRC + UT | State machine tests | NOT_IMPLEMENTED |
| REQ-101 | Critical integrity job must not depend solely on a composable `LaunchedEffect`. | Start from Activity/VM lifecycle, not `LoadingScreen`. | `MainActivity`, VM | SRC | Review | NOT_IMPLEMENTED |
| REQ-102 | Rotation/Activity recreation must not cancel verification or skip init. | Job survives in VM; UI re-collects state; init progress is VM state. | VM | IT | Rotation tests | NOT_IMPLEMENTED (current init coroutine can be cancelled mid-way while `sessionInitialized=true`) |
| REQ-103 | Restored UI state must not bypass verification. | Remove `rememberSaveable` gating of splash/terms/integrity; render only from VM state. | `MainActivity` | SRC + IT | Restored-state test | IMPLEMENTED (null-report guard exists; structural fix pending) |
| REQ-104 | Process-alive app switching must not repeat FULL. | No startup call on resume; monitor is lightweight. | Activity/VM | EMU | Background/foreground test | VERIFIED |
| REQ-105 | Recreated process may use TRUST_RECORD only after all lightweight validations. | Marker + record + existing bindings must all pass. | Startup decision | UT/EMU | Lightweight test | IMPLEMENTED (marker pending) |
| REQ-106 | Failed validation fails closed. | State `Failed`; no dashboard, no ECU. | VM/UI | UT | Failure test | VERIFIED |
| REQ-107 | No duplicate verification jobs. | Single-flight gate in VM; idempotent `startStartup`. | VM | UT | Duplicate test | IMPLEMENTED |
| REQ-108 | Do not initialize ECU functions before trust is established. | DB/storage/USB init only in `Starting` after accepted decision. | VM | SRC + IT | Ordering test | VERIFIED (current ordering) |
| REQ-109 | Distinguish Activity recreation from new process. | State lives in VM; new process = new VM ⇒ decision re-established. | VM | IT | Process-death test | IMPLEMENTED (architecture supports; explicit tests absent) |

### Group J — Startup performance matrix

| ID | Situation | Required behavior | Status |
|---|---|---|---|
| REQ-110 | User switches apps; process alive | No repeated FULL examination | VERIFIED (current; preserve) |
| REQ-111 | Activity recreation, same process | Reuse process-scoped result | IMPLEMENTED (VM survives; callback weakness to fix) |
| REQ-112 | Android kills process; reopen | Lightweight marker+record validation | IMPLEMENTED (record only; marker pending) |
| REQ-113 | Back/exit then reopen | Lightweight if process destroyed and record valid | IMPLEMENTED |
| REQ-114 | Swipe away then reopen | Same as above | IMPLEMENTED |
| REQ-115 | Force Stop then reopen | Lightweight if valid record survives | IMPLEMENTED |
| REQ-116 | Clear App Data | FULL ten-gate examination | IMPLEMENTED |
| REQ-117 | Uninstall/reinstall | FULL | IMPLEMENTED |
| REQ-118 | APK update | FULL | IMPLEMENTED |
| REQ-119 | Missing/corrupt/mismatched marker | FULL | NOT_IMPLEMENTED |
| REQ-120 | Missing/corrupt/mismatched trust record | FULL | VERIFIED |
| REQ-121 | Measure actual FULL and TRUST_RECORD times; report, never invent. | Timing logs + report | NOT_STARTED (new code not runnable without build; see blockers) |

### Group K — Visible examination UI

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-130 | Exact title `PEMERIKSAAN INTEGRITAS REVCORE`. | Header text verbatim. | New screen | IT | UI assertion | NOT_IMPLEMENTED |
| REQ-131 | Exactly ten rows, statuses `MENUNGGU`, `MEMERIKSA`, `TERVERIFIKASI`, `GAGAL`. | One row per GateId; exact labels; no extra rows. | New screen | IT | Row count/state assertions | NOT_IMPLEMENTED |
| REQ-132 | Actual gate numbering; Gate 8 not renumbered and displayed last. | Display order 1…7, 9, 10, 8 with labels `GERBANG <n>`. | New screen | IT | Order assertions | NOT_IMPLEMENTED |
| REQ-133 | Connected to real verification events; no simulation; no TERVERIFIKASI before PASS. | State map updated only by observer. | VM/screen | UT + IT | Event-driven UI test | NOT_IMPLEMENTED |
| REQ-134 | Existing RevCore visual language. | Reuse theme colors/typography/components; no unrelated theme. | Theme/components | Visual review | Screenshot | NOT_IMPLEMENTED |
| REQ-135 | Stable tags `integrity_examination`, `gate_row_1`…`gate_row_10`. | Apply exact `testTag`s to root and each row (tag number = gate number, including `gate_row_8` last). | New screen | IT | Tag assertions | NOT_IMPLEMENTED |
| REQ-136 | Show examination only when startup policy requires FULL. | TRUST_RECORD/reuse paths do not show it. | VM decision | IT | Mode tests | NOT_IMPLEMENTED |
| REQ-137 | Do not disclose what gates inspect, internal component/asset names, hashes, algorithms, keys, architecture, failure details. | Rows contain only `GERBANG n` + status; logs hold detail. | New screen | SRC/IT | UI text audit | NOT_IMPLEMENTED |

### Group L — Success acknowledgement and continuation

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-140 | After ten PASS show non-dismissible dialog, title `Pemeriksaan Integritas Berhasil`, success icon, button `LANJUTKAN`. | Dialog with `dismissOnBackPress=false`, `dismissOnClickOutside=false`; only button dismisses. | New dialog | IT | Dialog behavior test | NOT_IMPLEMENTED |
| REQ-141 | Commit marker/record only after LANJUTKAN. | Ack handler commits, then continues. | VM | UT | Commit-order test | NOT_IMPLEMENTED |
| REQ-142 | After LANJUTKAN continue existing LoadingScreen and DB/storage/USB init; no new loading screen; no ECU init change. | Reuse `LoadingScreen` visuals; VM runs existing init sequence. | VM/Activity | IT | Flow test | NOT_IMPLEMENTED |
| REQ-143 | Do not open dashboard before the decision. | Rendering driven by state; `Ready` only after trust + init. | Activity | IT | Pre-decision dashboard test | IMPLEMENTED (current) / strengthen |
| REQ-144 | Success dialog only for FULL with ten PASS; never for BYPASS or TRUST_RECORD. | Guard on evidence + report.passed. | VM | UT | Mode tests | NOT_IMPLEMENTED |

### Group M — Failure screen

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-150 | Exact title `Integritas Aplikasi Tidak Dapat Diverifikasi`. | Verbatim. | Failure screen | IT | Text assertion | NOT_IMPLEMENTED (current title differs) |
| REQ-151 | Exact message `RevCore tidak dapat memastikan keaslian atau kelengkapan instalasi ini. Silakan instal ulang menggunakan APK resmi RevCore.` | Verbatim. | Failure screen | IT | Text assertion | NOT_IMPLEMENTED |
| REQ-152 | Button `PERIKSA ULANG`. | Verbatim; runs real FULL. | Failure screen | IT | Text/click test | NOT_IMPLEMENTED |
| REQ-153 | No internal gate names, keys, expected hashes, paths, or detailed evidence in public UI. | Remove per-gate rows/details from failure screen; log only. | Failure screen | SRC + IT | UI disclosure audit | NOT_IMPLEMENTED (current screen lists gate titles/details) |
| REQ-154 | No success dialog, no new marker/record, no trusted dashboard, ECU disabled on failure. | Fail-closed state. | VM/UI | UT | Failure tests | VERIFIED |

### Group N — Runtime monitor separation

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-160 | Runtime monitor separate from startup examination; silent; no second examination screen. | Monitor calls lightweight runtime identity check; on failure silent FULL decision, no observer UI. | `MainViewModel` monitor | SRC + IT | Monitor failure test | IMPLEMENTED (currently silent; must stay silent after refactor) |
| REQ-161 | No duplicate startup jobs from monitor. | Use separate job/flag; never re-enter startup pipeline. | VM | SRC | Review | IMPLEMENTED |
| REQ-162 | No unnecessary USB/K-Line interruption during normal transitions. | Monitor only acts on genuine failure. | VM | SRC | Review | VERIFIED |
| REQ-163 | On genuine failure mark untrusted, disable sensitive ops, stop/close diagnostics safely, prevent ECU writes, preserve evidence, no random crash. | `applyIntegrity` failure path: stop live data, cancel monitor, disconnect; no crash. | VM | SRC + UT | Failure-path tests | VERIFIED |

### Group O — Offline and owner-device compatibility

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-170 | Offline-first; no login/license/subscription/cloud/remote auth. | No network dependency introduced. | App | SRC | Review | VERIFIED |
| REQ-171 | Never block for root, KernelSU, custom ROM, unlocked bootloader, USB debugging, developer options. | No such checks anywhere in integrity path. | Security code | SRC + grep | Review | VERIFIED |
| REQ-172 | No broad anti-root checks as substitute for integrity. | Root checks not used. | Security code | SRC | Review | VERIFIED |

### Group P — Diagnostic preservation

| ID | Exact requirement | Required implementation behavior | Source / component | Verification method | Expected evidence | Status |
|---|---|---|---|---|---|---|
| REQ-180 | Preserve FTDI/USB OTG/K-Line/10400 bps/init timing/ECU ID + database matching/content/DTC read+clear/Live Data/MAP/Tuning/screens/USB permissions+reconnect. | No changes to protocol, database, or UI functionality except gated startup. | App modules | Regression tests + EMU/HW | Test report | VERIFIED (baseline; rerun planned) |
| REQ-181 | No hardcoded universal ECU identity; no invented protocol/AFR. | No protocol changes. | Protocol | SRC | Review | VERIFIED |
| REQ-182 | Narrowband O2 remains voltage; AFR unsupported. | No change. | Live data | SRC | Review | VERIFIED |
| REQ-183 | Do not change donation/About content unless a security dependency requires it. | Leave donation section untouched. | Settings screen | SRC | Diff review | VERIFIED |

### Group Q — Cryptographic and key rules

| ID | Exact requirement | Required behavior | Status |
|---|---|---|---|
| REQ-190 | Do not regenerate/print/upload/commit/copy K1–K9 values. | Compliance; no key access. | VERIFIED (compliance) |
| REQ-191 | No passwords in Gradle or source. | No secret added. | VERIFIED |
| REQ-192 | No secrets in prompts, logs, reports. | Redaction; no key material in docs. | VERIFIED (compliance) |
| REQ-193 | No reuse of operational keys for unrelated purposes. | Marker uses dedicated alias. | VERIFIED (design) |
| REQ-194 | Gates do not each need an AES key. | No per-gate keys. | VERIFIED |
| REQ-195 | Static manifests verified by digital signatures. | Existing detached signature. | VERIFIED |
| REQ-196 | Local state uses authenticated encryption or MAC. | Record AEAD; marker MAC (planned). | IMPLEMENTED (record) / NOT_IMPLEMENTED (marker) |
| REQ-197 | Public key is not a secret. | Pin is a public fingerprint. | VERIFIED |
| REQ-198 | Do not encrypt DEX and claim it remains executable. | Not attempted. | VERIFIED |
| REQ-199 | No unused key slots or fictitious K10. | None created. | VERIFIED |
| REQ-200 | Official signing key separate and never handled here. | No signing operations. | VERIFIED |
| REQ-201 | Do not ask owner to paste passwords in chat. | No such request. | VERIFIED (compliance) |
| REQ-202 | Do not transmit private keys or signing passwords to cloud services. | No transmission. | VERIFIED (compliance) |

### Group R — Failure resistance and residual risk

| ID | Exact requirement | Required implementation behavior | Verification | Status |
|---|---|---|---|---|
| REQ-210 | Audit single-boolean/function/file bypass paths. | Document paths: `lastReport`, report construction, record acceptance, UI gating. | SRC + report | NOT_STARTED |
| REQ-211 | Add independent verification paths only where real value exists. | Avoid circular/duplicated checks with no threat-model value. | Design review | NOT_STARTED |
| REQ-212 | No circular checks. | Document evidence flow as DAG. | Mapping doc | NOT_STARTED |
| REQ-213 | Failed prerequisite cannot yield PASS. | Prerequisite engine + tests. | UT | NOT_IMPLEMENTED |
| REQ-214 | Document residual risk of fully controlled/rooted device. | Explicit limitations in final report. | Report | NOT_STARTED |

### Group S — Required automated tests

| ID | Test family | Required coverage | Status |
|---|---|---|---|
| REQ-220 | Gate lifecycle | RUNNING before terminal; no PASS without RUNNING; staged order 1…7,9,10,8. | NOT_IMPLEMENTED |
| REQ-221 | No false PASS | Exceptions, missing evidence, unreadable archive, null policy ⇒ FAILED. | IMPLEMENTED (existing) / extend |
| REQ-222 | Prerequisite dependency | Dependent gate cannot PASS after prerequisite failure. | NOT_IMPLEMENTED |
| REQ-223 | Gate 8 aggregation | PASS only when all nine PASS; FAIL if any FAIL/BYPASS/NOT_CHECKED. | IMPLEMENTED / extend |
| REQ-224 | Debug BYPASS | BYPASS never equals PASS; no success dialog. | IMPLEMENTED / extend |
| REQ-225 | Failure denies runtime | `allowsRuntime=false`; ECU guard. | VERIFIED (existing) |
| REQ-226 | UI integrity mutations | One-byte resource, icon, label, credits, XML, `resources.arsc`, missing entry, unexpected/duplicate entry, unchanged DEX with changed resource, invalid manifest signature. | VERIFIED (prior matrix on built APK) / rerun against new manifest pipeline |
| REQ-227 | Trust record lifecycle | Valid marker+record ⇒ TRUST_RECORD; missing/corrupt marker; missing/corrupt record; different installId/build/signer/policy; clear data; no commit before LANJUTKAN; process death before ack ⇒ FULL; verified invalidation refuses examination when a file remains; commit failure never publishes trust. | NOT_IMPLEMENTED |
| REQ-231 | Invalidation verification | Marker-first deletion; absence required before gates; undeletable file ⇒ no gates, generic failure, retry. | NOT_IMPLEMENTED |
| REQ-232 | Commit failure | No persistent trust; session continuation only with valid ten-PASS decision; otherwise Failed; next launch FULL. | NOT_IMPLEMENTED |
| REQ-233 | Digest non-anchor | Marker digests cannot authorize startup without full record/current-APK verification. | NOT_IMPLEMENTED |
| REQ-228 | Lifecycle | Rotation doesn't cancel; same process no rerun; new process no dashboard pre-trust; restored state no bypass; duplicate prevention; failed startup no ECU. | NOT_IMPLEMENTED |
| REQ-229 | Runtime monitor | No duplicate exam; failure disables; no false PASS; normal transitions don't interrupt USB. | NOT_IMPLEMENTED |
| REQ-230 | Full existing suite | Run all existing tests; do not delete/weaken; report counts. | VERIFIED (270 tests baseline) / rerun required |

### Group T — Device/emulator matrix

All 24 scenarios from the Sentinel specification are recorded in Section 4. Status: `NOT_STARTED`;
honest evidence class will be assigned per scenario. Physical ECU scenarios will remain `NOT TESTED`
unless hardware is connected.

### Group U — Deliverables

| ID | Deliverable | Status |
|---|---|---|
| REQ-240 | `REVCORE_SENTINEL_IMPLEMENTATION_REPORT.md` | NOT_STARTED |
| REQ-241 | `REVCORE_TEN_GATE_MAPPING.md` | NOT_STARTED |
| REQ-242 | `REVCORE_UI_INTEGRITY_REPORT.md` | NOT_STARTED |
| REQ-243 | `REVCORE_TRUST_RECORD_LIFECYCLE_REPORT.md` | NOT_STARTED |
| REQ-244 | `REVCORE_STARTUP_LIFECYCLE_REPORT.md` | NOT_STARTED |
| REQ-245 | `REVCORE_TEST_REPORT.md` | NOT_STARTED |
| REQ-246 | Source diff summary + modified/new file list | NOT_STARTED |
| REQ-247 | Remaining risks and unverified scenarios | NOT_STARTED |
| REQ-248 | Reports state before/repaired/added/removed, tests run/passed/failed/not possible, measured time, limitations | NOT_STARTED |

### Group V — Build and release restrictions

| ID | Exact requirement | Status |
|---|---|---|
| REQ-250 | Do not build/sign/export/publish official APK before owner approval. | VERIFIED (compliance) |
| REQ-251 | Preserve applicationId, certificate, signing config, versioning, naming. | VERIFIED (current) |
| REQ-252 | Future authorized build named `RevCore build DDMMYY.apk` in `dist/`; preserve older builds; never leave debug APK as sole deliverable. | VERIFIED (existing convention) |
| REQ-253 | No GitHub/external uploads. | VERIFIED (compliance) |

---

## 2. AUDIT FINDINGS MAPPED TO REQUIREMENTS

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
10. Runtime monitor separation.
11. Tests (unit → instrumented), then reports.

Steps 1–3 are the largest change and must land together because the pipeline shape changes.

### 3.2 Conflicts requiring resolution (resolved in this plan)

| Conflict | Resolution |
|---|---|
| Current code writes `gptqdr.rvc` during FULL evaluation vs requirement “commit only after LANJUTKAN”. | Remove write from evaluation; commit in acknowledgement. |
| Failure screen currently exposes gate details vs non-disclosure. | Replace with generic screen; move details to log. |
| Runtime monitor calls `evaluateStartup(forceFull=true)` vs “no second examination screen”. | Monitor uses a silent FULL path with no observer; startup-only exam. |
| Debug BYPASS vs four visible states / success dialog. | Debug builds skip the examination/dialog and never show PASS; documented exception. Production release unaffected. |
| Gate 2/3/9 consume manifest evidence before Gate 5 verifies signature. | Each consuming gate requires a valid signature (`signatureValid`) as its own evidence precondition; Gate 5 independently re-verifies. No forward dependency. |
| Android/data survives updates vs fresh identity. | Build identity mismatch forces FULL and new `installId`; stale record rejected. |

### 3.3 Blockers / owner decisions

| ID | Blocker | Impact | Proposed default |
|---|---|---|---|
| B-1 | Success dialog, real FULL/TRUST_RECORD timing, MT Manager/resource mutation tests on the **new** code require a built/signed APK, which is prohibited until approval. | REQ-062/063, REQ-121, matrix 3–6, 17–23, REQ-226 rerun cannot be verified on-device now. | Implement + unit/instrumented tests; defer device/APK evidence until owner authorizes a build. Mark `BLOCKED` until then. |
| B-2 | No physical motorcycle/ECU adapter connected. | Matrix 24, diagnostic regression hardware evidence. | Mark `NOT TESTED`; preserve source and rerun emulator-level checks. |
| B-3 | Rooted-device/MT Manager repack tests need an artifact. | Real-world tamper evidence. | Defer with B-1. |
| B-4 | Choice of marker authentication primitive. | Design detail. | **Resolved:** HMAC-SHA256 with dedicated Keystore alias, approved. |
| B-5 | Behavior if marker/record commit fails after LANJUTKAN. | UX vs strictness. | **Resolved:** no persistent trust; continue only with a still-valid ten-PASS session decision; otherwise Failed; next launch FULL. |
| B-6 | Whether the examination screen is shown in debug builds. | Dev experience vs four-state contract. | **Resolved:** skip examination on debug; BYPASS path unchanged. |

No blocker prevents starting approved implementation except B-1/B-2 for final evidence.

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
   - show the generic failure screen;
   - require the user to press `PERIKSA ULANG`, which retries invalidation and FULL.
4. Only after verified absence may the staged gates run.

Rationale: deleting the marker first removes the link, so a surviving record cannot authorize
lightweight trust. Refusing to examine while an older valid pair may still exist guarantees that
process death before `LANJUTKAN` can never fall back to a previous trusted pair.

Consequences:

- The pair exists only while it represents a completed, acknowledged installation. During an
  examination the record is intentionally absent; it reappears only after `LANJUTKAN`.
- This covers `forceFull=true` retry: the old pair is removed before the real FULL run.
- A crash at any point leaves either nothing or a marker without a record, both of which force
  FULL.

The monitor path is separate: it never writes the pair, and on a genuine runtime failure it marks
the session untrusted and invalidates the pair so the next launch cannot reuse it.

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
| FULL required, invalidation cannot be verified | unchanged | unchanged | Examination refused; generic failure; retry required |
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
| `forceFull=true` retry | invalidated before gates | invalidated before gates | FULL if process dies |

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
| Invalidation leaves either file present | No gates run; Failed; retry required |
| Commit IO failure | No trusted pair; session-trusted only if ten PASS; next launch FULL |
| Digest bindings used without current verification | Must fail: record verification still mandatory |
| Double LANJUTKAN | Single commit; no duplicate files |
| Debug build | No marker/record written; BYPASS path unchanged |

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
  2. debug build ⇒ FULL (BYPASS, no exam);
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
- Failure: `Failed`; no commit; no init.
- `recheckIntegrity()`: `Examining` with reset phases; `forceFull=true`.
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

- exact title/message/button;
- no gate list/details;
- tags `integrity_failure_screen`, `btn_recheck_integrity`.

`MainActivity`: collect `startupState`; render exam / exam+dialog / LoadingScreen / failure /
terms / dashboard. Remove integrity-relevant `rememberSaveable` flags; keep terms state in VM.

### 4.8 Runtime monitor (REQ-160…163)

- Periodic monitor continues to use `verifyRuntimeIdentity` (cheap).
- On failure: call a silent FULL decision (`observer = null`), publish `Failed` without
  `Examining`; disconnect, stop live data, cancel monitor. No second examination screen.

### 4.9 Files expected to change / be created

Modified:

- `security/IntegrityModels.kt` — `GatePhase`, `GateEvent`, observer types, report helpers.
- `security/GateEvaluator.kt` — expose per-gate evaluation; signature prerequisites; aggregate.
- `security/RevCoreIntegrity.kt` — staged pipeline, startup outcome, forceFull, pending commit,
  silent runtime path, remove auto-persist.
- `security/TrustRecord.kt` — format 2 `installId`, loader compatibility rejection.
- `security/UiIntegrityManifest.kt` — split signature / UI resources / structure+identity / DEX.
- `ui/MainViewModel.kt` — state machine, ack commit, init continuation, retry, monitor.
- `MainActivity.kt` — state-driven rendering, start from Activity.
- `ui/screens/LoadingScreen.kt` — presentational progress.
- `ui/screens/IntegrityFailureScreen.kt` — generic rewrite.
- tests under `app/src/test/...` and `app/src/androidTest/...`.

New:

- `security/GateObserver.kt` (or inside `IntegrityModels.kt`).
- `security/InstallationStateStore.kt`.
- `security/InstallationCommit.kt` (if not nested).
- `ui/screens/IntegrityExaminationScreen.kt`.
- `ui/screens/IntegritySuccessDialog.kt`.
- test files listed in 4.10.

### 4.10 Test plan

Unit (JVM):

- gate observer ordering, RUNNING-before-terminal, staged order, Gate 8 last;
- no false PASS on thrown exception/unreadable archive/missing manifest/invalid signature;
- prerequisite downgrade;
- debug BYPASS ≠ PASS;
- forceFull with valid record ⇒ FULL (spy/counter);
- marker/record: valid pair, missing/corrupt marker, missing/corrupt record, installId mismatch,
  build/signer/policy/asset digest mismatch, format 1 rejected;
- commit only after acknowledgement (no files before ack; files after ack);
- state machine transitions (fresh, record, failure, retry, rotation idempotence);
- monitor failure does not emit examination events.

Instrumented (debug; synthetic states for UI):

- screen title, ten rows, exact states, tags, Gate 8 last, no disclosure text;
- dialog non-dismissible (back/outside don't close), LANJUTKAN triggers ack;
- failure screen exact strings and retry;
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
7. Runtime monitor separation; tests.
8. Full regression suite; instrumentation; report generation.
9. Stop. Present evidence. No APK build/sign.

### 4.12 Rollback

Changes are additive/refactor-level within the security package and startup UI. No Gradle,
signing, database, protocol, or asset changes. Rollback is a source-level revert of the listed
files; the existing `gptqdr.rvc` format 1 remains readable by the old code if the new code is
reverted, and format 2 files are simply rejected by old code (⇒ FULL), which is safe.

---

## 5. APPROVAL GATE

Implementation requires the owner to approve:

1. This requirement checklist and implementation plan.
2. The marker authentication choice (HMAC-SHA256, dedicated Keystore alias).
3. The commit-failure behavior (B-5).
4. The debug-build exemption from the visible exam/dialog (B-6).
5. The understanding that real success-dialog, timing, MT Manager, and physical ECU evidence
   remain **BLOCKED / NOT TESTED** until a build and hardware are authorized.

No source file will be modified and no APK will be built or signed before that approval.

> **Update (2026-11-15):** The owner approved the checklist, the marker authentication
> choice and the four required corrections. Phase C source and JVM tests were executed
> inside the stated boundary. No APK was built, signed, exported or published. Section 6
> below supersedes the Phase A status columns in Section 1.

---

## 6. PHASE C STATUS — AUTHORITATIVE

Evidence classes used here: **SRC** = reviewed source in this tree; **JVM** = executed
`:app:testDebugUnitTest` (result recorded in §6.2); **COMPILE** = `compileDebugKotlin` and
`compileReleaseKotlin` succeeded; **BLOCKED** = requires a built APK, an emulator, physical
hardware or an instrumented run that the approval boundary forbids right now.

### 6.1 Requirement-by-requirement status

| REQ | Now | Evidence |
|---|---|---|
| 002 | IMPLEMENTED | Additive refactor only; file list in `REVCORE_SENTINEL_IMPLEMENTATION_REPORT.md` §5 |
| 005 | SATISFIED | Owner approval recorded; this section is the post-approval status |
| 006, 007, 008 | SATISFIED | Every ID below carries an explicit status; unverified work is marked BLOCKED |
| 012 | IMPLEMENTED | `RevCoreIntegrity.STAGED_GATE_ORDER` (`RevCoreIntegrity.kt:100`), executed at `:622`; JVM `GateStagingTest.stagedOrderCoversExactlyTheTenGatesOnce` |
| 013 | IMPLEMENTED | `GateEvent`/`GateObserver` (`IntegrityModels.kt:75`), `emit` in `runStage` (`RevCoreIntegrity.kt:381`) |
| 014 | IMPLEMENTED (SRC) | `runStage` emits RUNNING before `acquire()` and the terminal phase only after `evaluateSingle` returns (`:386-402`) |
| 015 | IMPLEMENTED (JVM) | Exception → that gate FAIL (`:391-398`); no-false-PASS tests in `IntegrityGateTest` |
| 016 | IMPLEMENTED (JVM) | `policySignaturePrerequisite`/`uiSignaturePrerequisite` (`GateEvaluator.kt:177`,`:190`); `GateStagingTest.invalidPolicySignatureFailsEveryPolicyConsumer`, `invalidUiSignatureFailsItsConsumersButNotApkIdentity` |
| 017 | IMPLEMENTED | Loop continues after a FAIL; Gate 8 aggregates |
| 018 | IMPLEMENTED (JVM) | `debugWithoutPolicyReportsBypassAndNeverPass`, `debugBuildWithoutPolicyBypassesEveryGateIncludingFinalTrust` |
| 019 | IMPLEMENTED (JVM) | `IntegrityReport.passed`/`allowsRuntime` tests |
| 020 | IMPLEMENTED (SRC) | No delay/fake fill in the examination; `LoadingScreen` is presentational; rows come only from observer events |
| 021 | IMPLEMENTED (JVM) | `finalTrustPassesOnlyWhenAllNineGatesPassed`, `aBypassedGateBlocksFinalTrustInAReleaseBuild`, `anUncheckedGateBlocksFinalTrustInAReleaseBuild`, `anEmptyResultListFailsClosed` |
| 022 | IMPLEMENTED (SRC) | `IntegrityExaminationScreen` renders `phases[gate]`; instrumented assertion BLOCKED |
| 030–034 | VERIFIED (prior) | Unchanged byte-level manifest verification |
| 035 | IMPLEMENTED (JVM) | Per-gate signature prerequisites (see REQ-016) |
| 036–039 | VERIFIED (prior) | Unchanged digest/structure checks; result mutation matrix rerun BLOCKED |
| 040 | IMPLEMENTED (SRC) | Gate FAIL ⇒ `allowsRuntime=false` ⇒ generic failure screen (`IntegrityFailureScreen.kt`) |
| 041–045 | VERIFIED | `applicationId`, signing config, pin and signer checks untouched |
| 046 | IMPLEMENTED (JVM) | Policy/UI signatures must validate before their consumers can PASS |
| 050 | VERIFIED | `TrustRecordStore` path unchanged |
| 051 | IMPLEMENTED | `InstallationStateStore.markerFile()` (`InstallationStateStore.kt:217`) = `filesDir/.revcore/installation.state` |
| 052 | IMPLEMENTED (SRC+JVM) | Payload schema (`:40`), `pairMatches` (`RevCoreIntegrity.kt:264`); schema cases in `InstallationMarkerTest.authenticatedPayloadMustStillPassTheSchema` |
| 053 | VERIFIED | `buildIdentity` + `archiveFingerprint` retained in record and marker |
| 054 | IMPLEMENTED | Record AES-256-GCM (unchanged); marker HMAC-SHA256 with dedicated alias `revcore.installation.marker.v1` (`InstallationStateStore.kt:66`) |
| 055 | VERIFIED | AEAD tag verified before parse; marker authenticates before JSON parse (`InstallationMarker.open`) |
| 056 | IMPLEMENTED | Dedicated marker alias; no K1–K9 use, no K10 |
| 057 | IMPLEMENTED | `REVCORE_TRUST_RECORD_LIFECYCLE_REPORT.md` §3 |
| 060 | VERIFIED | Missing pair ⇒ FULL |
| 061 | IMPLEMENTED | Evaluation never writes; `commitInstallation` rejects any non-FULL-PASS report (`RevCoreIntegrity.kt:1065-1071`) |
| 062 | IMPLEMENTED (SRC) | `IntegritySuccessDialog` rendered only for `AwaitingAcknowledgement`; UI test BLOCKED |
| 063 | IMPLEMENTED | Dialog has no dismiss path; only `LANJUTKAN` calls `acknowledgeIntegrity` |
| 064 | IMPLEMENTED | Pending commit in memory; invalidation before every release FULL (`:164-172`,`:303`) |
| 065 | IMPLEMENTED | Marker written via temp+atomic move (`InstallationStateStore.kt:238-257`); record written after marker; reload + `pairMatches` (`:1118-1128`); `failCommit` deletes both (`:1134`) |
| 066 | IMPLEMENTED (SRC) | Nothing persisted before LANJUTKAN; old pair invalidated before gates; device process-death run BLOCKED |
| 067 | IMPLEMENTED (JVM) | `InstallationMarkerTest` tamper/truncate/wrong-key cases + existing record tests |
| 068 | IMPLEMENTED (SRC) | `pairMatches` compares marker/record `installId`; JVM needs a `Context`, instrumented BLOCKED |
| 069, 070 | IMPLEMENTED (SRC) | `pairMatches` compares build identity, signer, policy/UI/asset digests, archive fingerprint |
| 071 | IMPLEMENTED (JVM) | Fresh random id per commit (`:1075`); `everyCommitReceivesAFreshRandomInstallId` |
| 072 | IMPLEMENTED | Version/build mismatch rejects even when `Android/data` survives |
| 073 | IMPLEMENTED (SRC) | Clear-data removes marker and Keystore keys; emulator run BLOCKED |
| 074 | IMPLEMENTED | Missing either file ⇒ FULL |
| 075 | IMPLEMENTED | `invalidatePersistentTrust` deletes marker first, then record, verifies each (`:303-313`); refusal ⇒ `StartupOutcome.Failed` with generic screen |
| 076 | IMPLEMENTED | Invalidation happens before the first gate on every release FULL, including `forceFull` retries and the monitor path |
| 077 | IMPLEMENTED (SRC) | `acknowledgeIntegrity` continues only with `passed && FULL && !debug`; otherwise `Failed`; `failCommit` guarantees next launch FULL (`MainViewModel.kt:296-333`) |
| 078 | IMPLEMENTED | Digests only bind; lightweight path still runs `verifyStartupRecord` against the current APK |
| 079 | VERIFIED | No existing record check removed (`verifyStartupRecord` `:889-1057`) |
| 080–082 | VERIFIED | Record check inventory preserved; invalid record ⇒ FULL |
| 090 | IMPLEMENTED | `forceFull` skips `lastReport` and `loadTrustedRecord` (`:148-163`) |
| 091 | IMPLEMENTED | `recheckIntegrity()` only from `Failed`, always `forceFull = true` (`MainViewModel.kt:283`) |
| 092 | IMPLEMENTED (SRC) | Path is source-verified; a context-bearing JVM test is not possible, instrumented run BLOCKED |
| 100 | IMPLEMENTED | `StartupState` sealed interface (`MainViewModel.kt:87`) |
| 101 | IMPLEMENTED | `viewModel.startStartup()` in `onCreate` (`MainActivity.kt:108`) |
| 102 | IMPLEMENTED (SRC) | Job in `viewModelScope`; state survives recreation; rotation test BLOCKED |
| 103 | IMPLEMENTED | Rendering derives only from `startupState`; no integrity flag in `rememberSaveable` |
| 104 | VERIFIED | No startup call in `onResume` |
| 105 | IMPLEMENTED | Marker + record + full `verifyStartupRecord` before TRUST_RECORD |
| 106 | VERIFIED | Failed state denies dashboard and ECU |
| 107 | IMPLEMENTED | `startStartup`/`launchStartup` single-flight; ack idempotent flag |
| 108 | VERIFIED | DB/storage/USB init only inside `runInitialization` after the decision |
| 109 | IMPLEMENTED (SRC) | State lives in the ViewModel; new process ⇒ new VM ⇒ `Idle` |
| 110–118 | VERIFIED | Performance matrix unchanged; FULL only when trust cannot be re-established |
| 119 | IMPLEMENTED | Missing/corrupt/mismatched marker ⇒ FULL |
| 120 | VERIFIED | Corrupt record ⇒ FULL |
| 121 | BLOCKED | Requires a built APK + device; not measured and not invented |
| 130–137 | IMPLEMENTED (SRC) | Exact title, ten rows, labels, order, tags, no disclosure (`IntegrityExaminationScreen.kt:51-147`); instrumented assertions BLOCKED |
| 140 | IMPLEMENTED (SRC) | `AlertDialog(onDismissRequest = {})`, title/`LANJUTKAN` exact (`IntegritySuccessDialog.kt`); UI test BLOCKED |
| 141 | IMPLEMENTED | Commit only inside `acknowledgeIntegrity` |
| 142 | IMPLEMENTED | `runInitialization()` reuses `LoadingScreen` progress |
| 143 | IMPLEMENTED | Dashboard only in `Ready` |
| 144 | IMPLEMENTED (SRC) | Guard `evidence == FULL && passed && !debugBuild` (`MainViewModel.kt:305-307`) |
| 150–153 | IMPLEMENTED (SRC) | Exact strings; no gate list/details (`IntegrityFailureScreen.kt`); UI test BLOCKED |
| 154 | VERIFIED | No dialog, no commit, no dashboard, ECU disabled on failure |
| 160–163 | IMPLEMENTED (SRC) | Monitor re-checks signer/policy; silent FULL without observer; `applyIntegrity` failure path (`MainViewModel.kt:511-562`) |
| 170–172 | VERIFIED | No network, no root/ROM/ADB checks added |
| 180–183 | VERIFIED | Protocol, database, DTC, Live Data and donation content untouched |
| 190–202 | VERIFIED | Marker alias dedicated; no secret in source/logs/reports; REQ-196 now covers marker MAC |
| 210–212 | IMPLEMENTED (SRC) | Bypass-path and evidence-DAG analysis in `REVCORE_SENTINEL_IMPLEMENTATION_REPORT.md` §7 |
| 213 | IMPLEMENTED (JVM) | Prerequisite tests (REQ-016) |
| 214 | IMPLEMENTED | Residual risk section in the same report |
| 220 | IMPLEMENTED (JVM) | Order pinned by `GateStagingTest`; event timing is SRC because it needs `Context` |
| 221 | IMPLEMENTED (JVM) | Existing fault-injection tests remain green |
| 222 | IMPLEMENTED (JVM) | `GateStagingTest` prerequisite cases |
| 223 | IMPLEMENTED (JVM) | Four aggregation tests |
| 224 | IMPLEMENTED (JVM) | `statusToPhaseNeverTurnsABypassOrASkipIntoAPass` + debug tests |
| 225 | VERIFIED | Existing |
| 226 | VERIFIED (prior) | Mutation matrix must be rerun on an authorized build — BLOCKED |
| 227–233 | IMPLEMENTED (SRC+JVM part) | Marker container JVM-tested; store/pair/commit lifecycle needs `Context`/device — BLOCKED |
| 228, 229 | IMPLEMENTED (SRC) | State machine and monitor; instrumented runs BLOCKED |
| 230 | VERIFIED (JVM) | 295/295 pass, 0 failures, 0 errors (§6.2) |
| 240–248 | DELIVERED | Reports listed in §6.3 |
| 250 | VERIFIED | No `assembleRelease`, no signing, no artifact produced |
| 251 | VERIFIED | No change to `applicationId`, certificate, signing config, versioning |
| 252 | NOT APPLICABLE | No build authorized in this phase |
| 253 | VERIFIED | No external upload |

### 6.2 Test result (executed)

Command: `gradle.bat :app:testDebugUnitTest --offline --console=plain` — **BUILD SUCCESSFUL**.

`tests=295 skipped=0 failures=0 errors=0`.

New this phase: `InstallationMarkerTest` 10, `GateStagingTest` 13, `TrustRecordTest` +2
(format 2 / legacy rejection) — 25 new, 270 pre-existing still green.
`SecurityGsonModelTest` now also covers `InstallationMarkerPayload`.

Both `:app:compileDebugKotlin` and `:app:compileReleaseKotlin` succeeded.

### 6.3 Deliverables

- `REVCORE_SENTINEL_IMPLEMENTATION_REPORT.md`
- `REVCORE_TEN_GATE_MAPPING.md`
- `REVCORE_UI_INTEGRITY_REPORT.md`
- `REVCORE_TRUST_RECORD_LIFECYCLE_REPORT.md`
- `REVCORE_STARTUP_LIFECYCLE_REPORT.md`
- `REVCORE_TEST_REPORT.md`

### 6.4 Still unverified (must stay BLOCKED until authorized)

1. Any device/emulator behaviour: visible examination, dialog dismissal, rotation, process
   death before/after LANJUTKAN, Clear Data, update, force stop.
2. Keystore HMAC key behaviour and atomic-file replacement on real storage.
3. FULL vs TRUST_RECORD timing on hardware.
4. APK mutation matrix rerun against a new build.
5. MT Manager repack scenarios and physical ECU sessions.
