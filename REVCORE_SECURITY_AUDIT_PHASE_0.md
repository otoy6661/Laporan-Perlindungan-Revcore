# REVCORE — PHASE 0
# SECURITY ARCHITECTURE & SOURCE CODE AUDIT

**Document:** `REVCORE_SECURITY_AUDIT_PHASE_0.md`
**Project:** RevCore Android (`com.revcore.android`)
**Audit date:** 2026-11-14
**Auditor role:** Senior Android Security Architect / Reverse Engineering Specialist
**Phase status:** AUDIT ONLY — NO APPLICATION SOURCE, ASSET, KEY, BUILD, UI, PROTOCOL, OR SIGNING CONFIGURATION WAS MODIFIED

---

## 0. Scope, Method, Classification, and Evidence Baseline

### 0.1 Scope

This audit covers the **current workspace** at:

`C:\Users\Lord Otoy\Documents\Qoder\work\revcore`

The audit examined:

- the Android application source and resources;
- the build configuration and APK publishing logic;
- the currently distributed APK in `dist/`;
- bundled ECM, FlashPro profile, and MAP assets;
- the existing USB, FTDI, K-Line, identification, live-data, DTC, storage, and tuning code paths;
- the existing cryptographic and integrity-related code;
- workspace-level key material and build artifacts.

The audit did **not**:

- modify any application source file;
- create, delete, move, rename, encrypt, or decrypt any application asset;
- add any library, dependency, permission, activity, service, receiver, or provider;
- change the application ID, version, UI, theme, icon, signing configuration, USB layer, FTDI layer, K-Line timing, identification protocol, ECM database, or MAP data;
- request, read, copy, or access a developer nine-key file;
- generate any key;
- build a new APK or replace the existing release APK.

The only file created by this phase is this report.

### 0.2 Method

Evidence was gathered by direct read-only inspection:

- source and resource file reads;
- targeted symbol and string searches;
- asset counting and SHA-256 calculation;
- APK signature verification with `apksigner`;
- APK manifest inspection with `aapt2`;
- APK content listing;
- build-file and Gradle configuration inspection;
- comparison of the current APK against the current source tree.

No runtime instrumentation, decompilation to source, dynamic hooking, or device-side penetration test was performed in this phase. Claims about historical hardware behavior are treated as **claims**, not as current proof.

### 0.3 Classification Legend

| Classification | Meaning in this report |
|---|---|
| **VERIFIED** | Directly observed in the current source, resources, build files, assets, or APK. |
| **PARTIALLY VERIFIED** | Some direct evidence exists, but the property is incomplete, conditional, or not exercised end-to-end in this phase. |
| **NOT VERIFIED** | The property is claimed or historically reported, but no current evidence was produced in this audit. |
| **NOT IMPLEMENTED** | No implementation exists in the current workspace. |
| **RISK** | An observed condition that creates a security, integrity, compatibility, or deployment exposure. |

A finding can carry a classification and a severity. Severity is about impact if the condition is exploited or fails:

- **CRITICAL** — defeats the stated anti-repackaging / anti-tampering goal by itself.
- **HIGH** — makes protected data or behavior forgeable or extractable with ordinary tools.
- **MEDIUM** — raises attack surface or weakens defense in depth.
- **LOW** — hygiene, policy, or defense-in-depth issue.

### 0.4 Evidence Baseline

| Item | Observed value | Classification |
|---|---|---|
| Kotlin source files under `app/src/main/java` | 85 files, 23,624 lines | VERIFIED |
| UI framework | Jetpack Compose / Material3, single `MainActivity` | VERIFIED |
| Project-owned native code | None. No `jni/`, no CMake, no project `.c`/`.cpp`/`.so`. | VERIFIED |
| Native libraries in APK | Only four `libandroidx.graphics.path.so` files (arm64-v8a, armeabi-v7a, x86, x86_64) | VERIFIED |
| Current distributed APK | `dist/RevCore build 141126.apk`, 56,907,913 bytes | VERIFIED |
| Current APK SHA-256 | `ab3bc3c938c5516d750abc15932ef22f216119e3860e8f45203f6ff1e8e837b5` | VERIFIED |
| APK signing schemes | v1 false, v2 true, v3 false, v3.1 false, v4 false | VERIFIED |
| APK signer certificate | `CN=Android Debug, O=Android, C=US`, RSA 2048 | VERIFIED |
| APK certificate SHA-256 | `a57a28ec69fbdacc57f41610e67481a1a3ba7a1138eaed90ed438a33372f8ab4` | VERIFIED |
| APK debuggable | `true` | VERIFIED |
| APK allowBackup | `true` | VERIFIED |
| APK extractNativeLibs | `false` | VERIFIED |
| Application ID | `com.revcore.android` | VERIFIED |
| Version | versionCode 1, versionName 1.0 | VERIFIED |
| compileSdk / targetSdk / minSdk | 36 / 36 / 26 | VERIFIED |
| Release signing | Uses `../debug.keystore`, alias `androiddebugkey`, password `android` | VERIFIED |
| Release minification | `isMinifyEnabled = false` | VERIFIED |
| ECM database | `app/src/main/assets/ecm_database.json`, 748,580 bytes, 489 `partNumber` records | VERIFIED |
| ECM database SHA-256 | `7c7a2dd69b48e4257493c944b276ee7f3811c173f44c037f4d987c9b280b652a` | VERIFIED |
| FlashPro profiles | `app/src/main/assets/flashpro_profiles.json`, 127,269 bytes | VERIFIED |
| Profiles SHA-256 | `9c0be8649bdd1ef114fba6211f00f3733f4dcca0190ab9c7a173b45b3e703da4` | VERIFIED |
| Bundled MAP manifest | `app/src/main/assets/flashpro_maps/manifest.tsv`, 29,628 bytes, 163 lines (header + 162 entries) | VERIFIED |
| MAP manifest SHA-256 | `189593bb99217aa2650830b29d0d9018e42c3972ccdf4278b6296366becfdd41` | VERIFIED |
| Bundled MAP files | 162 `.map` files, 35,195,840 bytes total | VERIFIED |
| Git history | No `.git` directory in workspace | VERIFIED |
| Existing key-like file in workspace root | Only `debug.keystore` (plus no nine-key file was searched for, requested, or accessed) | VERIFIED |
| Existing release key | None separate from the debug key | VERIFIED |
| Baseline unit tests | 26 test source files; the preceding phase reported 196 passing tests | PARTIALLY VERIFIED (not re-run in Phase 0) |
| Historical hardware behavior | FT232RL over USB OTG, K-Line 10400 bps, Honda K1AA-N02, ECU ID 01037A0F02, Live Data | NOT VERIFIED in this phase |

---

## 1. Executive Summary

### 1.1 Bottom Line

RevCore currently has **functional application security only in the sense of safe feature behavior**. It has **no application-integrity architecture**. The current distributed APK is a **debug build, debuggable, signed with the public Android debug certificate, not minified, backup-enabled, and protected only by APK Signature Scheme v2**. Anyone who obtains the APK can decompile it, modify resources or DEX, re-sign it with the same public debug key, and distribute a functionally rebranded application. The app itself contains no check that would notice.

The most valuable bundled data is also not authenticated:

- `ecm_database.json` is loaded directly from assets with no hash or signature check.
- `flashpro_profiles.json` is loaded directly from assets with no hash or signature check.
- `flashpro_maps/manifest.tsv` is an **unsigned** hash list. It can be replaced together with any `.map` file.
- `.map` decryption uses a **hardcoded AES-128 key and fixed IV** with **no MAC**, so confidentiality and authenticity both fail against an attacker who reads the APK.
- The MAP editor and tuning metadata trust the ECM database for offsets and limits; tampering with that database can change what the user is shown and what values the app would be willing to accept.

There is **no project-owned native code**. Layer 6 (Native Code) cannot be implemented as-is without adding a JNI/NDK layer, which is a major compatibility and maintenance decision and is not justified for Phase 1 by itself.

### 1.2 Highest-Risk Findings

| ID | Finding | Severity | Classification |
|---|---|---|---|
| W-01 | Distributed APK is signed with the public Android debug certificate; release and debug share it. | CRITICAL | VERIFIED / RISK |
| W-02 | Distributed APK has `android:debuggable="true"`. | CRITICAL | VERIFIED / RISK |
| W-03 | No runtime APK certificate pinning or package-integrity verification exists. | CRITICAL | NOT IMPLEMENTED / RISK |
| W-04 | No signed integrity manifest exists for APK contents, ECM DB, profiles, or MAP assets. | CRITICAL | NOT IMPLEMENTED / RISK |
| W-05 | MAP encryption key and IV are hardcoded in `MapCrypto.kt`; AES-128-CBC has no MAC. | CRITICAL | VERIFIED / RISK |
| W-06 | MAP manifest is unsigned; hashes therefore have no trusted root. | HIGH | VERIFIED / RISK |
| W-07 | ECM database and FlashPro profiles are unauthenticated. | HIGH | VERIFIED / RISK |
| W-08 | `allowBackup="true"` and plaintext `SharedPreferences` expose local state. | MEDIUM | VERIFIED / RISK |
| W-09 | Release build has no R8/minification; Kotlin metadata and strings are easy to recover. | MEDIUM | VERIFIED / RISK |
| W-10 | `INTERNET` and `ACCESS_NETWORK_STATE` permissions are declared without a current network use. | MEDIUM | VERIFIED / RISK |
| W-11 | No native layer exists; Layer 6 is currently impossible without adding one. | MEDIUM | NOT IMPLEMENTED |
| W-12 | No controlled integrity-failure policy exists; there is no gate to fail closed. | HIGH | NOT IMPLEMENTED / RISK |
| W-13 | Compose UI text is hardcoded in DEX; launcher label and icon are OS resources and cannot be encrypted. | MEDIUM | VERIFIED |
| W-14 | A dynamic USB broadcast receiver is exported by default on API 26–32. | LOW | VERIFIED / RISK |
| W-15 | Developer signing material and build passwords are present in the workspace; workspace ZIPs may contain source and references. | HIGH | VERIFIED / RISK |

### 1.3 What Is Feasible

The following protections are technically feasible without changing USB, FTDI, K-Line, identification, live data, DTC, or ECM identity behavior:

1. A real release signing identity, v3/v4 signature, debuggable=false, allowBackup=false, and R8.
2. Runtime verification of the APK signing certificate against a pinned digest.
3. A signed integrity manifest (preferably asymmetric) covering the ECM database, profiles, MAP files, and selected resources.
4. AES-256-GCM encryption of the ECM database, profiles, and MAP packages, with per-file nonces and AAD.
5. A small, controlled trust gate that disables sensitive operations on integrity failure without crashing and without blocking legitimate USB/K-Line communication.
6. Android Keystore protection for device-bound local state.
7. Optional native hardening later, only after the non-native layers are stable.

### 1.4 What Is Not Feasible

- Making the application impossible to patch. Any client-side guard runs on hardware controlled by the attacker.
- Encrypting the launcher label, launcher icon, or manifest-declared theme in a way the OS can still use.
- Encrypting all Compose UI code or every XML resource without a packer/classloader, which would be high-risk and does not fit the current architecture.
- Keeping an offline runtime decryption key completely secret from a device-controlling attacker.
- Remote revocation or license enforcement without network access.
- Using root, KernelSU, custom ROM, USB debugging, or bootloader status as sufficient tamper evidence.

### 1.5 No Source Modified

No application source code, asset, resource, manifest, Gradle file, signing configuration, database, MAP file, or APK was modified during this phase. This report is the only new file.

---

## 2. Actual Architecture

### 2.1 Project and Build Shape

| Area | Current implementation | Evidence |
|---|---|---|
| Language | Kotlin 2.2.10 | Gradle/plugin configuration |
| UI | Jetpack Compose, Material3, single Activity | `MainActivity.kt`, `ui/` |
| Architecture | Activity + `AndroidViewModel` + Compose screens | `MainActivity.kt`, `ui/MainViewModel.kt` |
| Application class | None declared | `AndroidManifest.xml` has no `android:name` on `<application>` |
| Minimum SDK | 26 | `app/build.gradle.kts` |
| Compile/target SDK | 36 | `app/build.gradle.kts` |
| AGP / Gradle | AGP 9.1.1 / Gradle 9.6.0 (no wrapper) | project build setup |
| Native code | None | no `jni/`, CMake, or project `.so` |
| Localization | Compose hardcoded bilingual strings plus generated `values-*` strings | `ui/screens/*.kt`, `res/values-*/strings.xml` |
| Persistence | `SharedPreferences` for terms; `Internal Storage/Revcore/` for user files | `TermsStore.kt`, `RevCoreStorage.kt` |
| Network | No current HTTP client or endpoint observed | source search; `INTERNET` remains declared |

### 2.2 Runtime Component Map

```
MainActivity (ComponentActivity)
  ├─ registers USB attach/detach/permission BroadcastReceiver
  ├─ shows LoadingScreen → TermsScreen → MainAppScaffold
  ├─ requests storage access (legacy or MANAGE_EXTERNAL_STORAGE)
  └─ owns MainViewModel

MainViewModel (AndroidViewModel)
  ├─ initializeSession()
  │    ├─ EcmDatabase.init(application)          → assets/ecm_database.json
  │    ├─ RevCoreStorage.ensure(application)     → Internal Storage/Revcore/
  │    └─ USB scan / auto-connect state
  ├─ HondaProtocolEngine
  │    ├─ UsbSerialLibraryTransport              → usb-serial-for-android 3.8.0
  │    ├─ FtdiSerialDriver / FtdiConstants       → FTDI VID/PID, 10400/9600
  │    ├─ KlineTransceiver / KlineWireEngine     → K-Line framing/timing
  │    ├─ HondaIdentifierParser                  → 0x1A identification frames
  │    ├─ EcmIdentityMatcher                     → DB matching
  │    └─ HondaDtcDatabase                       → DTC descriptions
  ├─ FlashProProfile.loadFromAssets()            → assets/flashpro_profiles.json
  ├─ MapCatalog / BundledMapManifest / MapCrypto → assets/flashpro_maps/
  └─ TuningLog / export / backup / checksum operations

Compose screens
  ├─ DashboardScreen
  ├─ LiveDataScreen
  ├─ DiagnosticsScreen
  ├─ EcuInfoScreen
  ├─ TuningScreen (MAP Studio, operations, dialogs)
  ├─ SettingsScreen (language, storage, adapter schematic, about)
  ├─ LogScreen
  ├─ TermsScreen
  └─ LoadingScreen
```

### 2.3 Startup Flow

1. `MainActivity.onCreate()` registers the USB receiver.
2. `setContent` renders `LoadingScreen` while `MainViewModel.initializeSession()` runs.
3. `initializeSession()` calls `EcmDatabase.init()` and `RevCoreStorage.ensure()` on `Dispatchers.IO`.
4. After progress reaches 1.0, the splash is dismissed.
5. If terms are not accepted, `TermsScreen` is shown.
6. After acceptance, `MainAppScaffold` is shown.
7. `onResume()` refreshes storage and app-resume state.
8. USB attach events drive auto-connect; identification is attempted only after a device is connected.

**Security observation:** there is no integrity check anywhere in this startup sequence. All bundled data is trusted as-is. There is no custom `Application` class to centralize trust initialization.

### 2.4 Communication Architecture (Read-Only Audit)

The following behavior is treated as working functionality and must be preserved:

- `HondaProtocolEngine` is the high-level protocol owner.
- `UsbSerialLibraryTransport` uses `usb-serial-for-android` 3.8.0 and a custom FTDI driver.
- `FtdiConstants` defines `BAUD_KLINE_DEFAULT = 10400` and `BAUD_STANDARD = 9600`.
- `identifyEcu()` performs: wake pulse → baseline identification at 10400 → 9600 fallback → repeated wake + 10400 → `0x1A` diagnostic fallback.
- `HondaIdentifierParser` parses identification frames.
- `EcmIdentityMatcher` matches normalized ECM IDs exactly, or by a bounded prefix/suffix relation only when the shorter value is at least 8 characters and the length difference is at most 2.
- `readDtcs()`, `clearDtcs()`, and `queryLiveData()` are implemented in the same engine.
- `FlashEngine` is default-deny: `WRITE_PROTOCOL_PROVEN = false`, `READBACK_PROVEN = false`, and `startWrite()` always refuses because no erase/write routine exists.

**Security observation:** the communication layer itself is not the weak link for anti-repackaging. The weak link is that the APK and its data are unauthenticated. Security work must wrap asset/package loading and trust decisions, not insert checks inside K-Line timing or FTDI I/O.

### 2.5 Storage Architecture

- `RevCoreStorage.ROOT_NAME = "Revcore"`.
- Root is `Environment.getExternalStorageDirectory()/Revcore`.
- Folders: `Logs`, `Backup`, `Maps`, `Exports`, `Database`, `Config`.
- API ≤ 29 uses legacy external write permission.
- API ≥ 30 uses `Environment.isExternalStorageManager()` and `MANAGE_EXTERNAL_STORAGE`.
- Filenames are generated with unique suffixes to avoid silent overwrite.

**Security observation:** these are user-visible files. They are not protected by the application's future asset encryption. Backups and exports may contain proprietary MAP data and must be treated as user-controlled copies, not as protected app assets.

### 2.6 Build and Distribution Architecture

- `dist/` contains `RevCore build 141126.apk`.
- `dist/archive/RevCore build 141126_074543.apk` is an archived earlier build.
- `app/build.gradle.kts` copies successful debug and release APKs to `dist/` after `assembleDebug` / `assembleRelease`.
- The target name is `RevCore build DDMMYY.apk`; an existing same-day file is archived with an `HHmmss` suffix.
- Both `release` and `debug` build types use the same `signingConfigs.create("release")` pointing at `../debug.keystore`.
- `isMinifyEnabled = false`.
- No `proguard-rules.pro` hardening is active.
- `dist/` currently contains a debug APK, not a release build.

**Security observation:** the build pipeline preserves older builds, which is good for rollback, but it currently publishes a debug-signed artifact as the main deliverable. The filename rule is correct; the signing identity is not.

### 2.7 Trust Boundaries

```
[Untrusted]  Network (declared but unused)
[Untrusted]  USB device / K-Line frames
[Untrusted]  User-visible files in Internal Storage/Revcore
[Untrusted]  Any modified APK, DEX, resource, or asset

[Boundary 1] Android package manager / APK signature
[Boundary 2] App runtime: assets, SharedPreferences, Keystore
[Boundary 3] ECU protocol engine: frame validation, identity matching
[Boundary 4] Tuning safety: checksum, validator, default-deny flash engine
```

The current app has **no verification at Boundary 1**. Boundary 2 data is trusted without authentication. Boundary 3 is reasonably defensive against malformed frames but is not an authenticity boundary for the app package. Boundary 4 is conservative for flashing but trusts the ECM database for offsets and limits.

---

## 3. Complete Protected-Component Inventory

### 3.1 Application Identity and Build Artifacts

| Component | Path / identity | Current state | Protection today | Classification |
|---|---|---|---|---|
| Package name | `com.revcore.android` | Fixed | None beyond normal package isolation | VERIFIED |
| Version | 1 / 1.0 | Fixed | None | VERIFIED |
| Launcher label | `@string/app_name` = `RevCore` | Plain resource | OS must read it; cannot be encrypted in place | VERIFIED |
| Launcher icon | `@mipmap/ic_launcher`, adaptive icon | Plain resources | OS must read it; cannot be encrypted in place | VERIFIED |
| Theme | `@style/Theme.MyApplication` | Plain XML, platform light theme | None | VERIFIED |
| Release APK | `dist/RevCore build 141126.apk` | Debuggable, debug-signed | v2 signature only | VERIFIED |
| Release signing key | `debug.keystore` | Public debug key; password in build file | Not a release identity | VERIFIED / RISK |
| Debug keystore | `debug.keystore` | Present in workspace | Public debug key | VERIFIED / RISK |
| Dist archive | `dist/archive/` | Earlier builds preserved | None | VERIFIED |

### 3.2 Code and UI

| Component | Path | Format | Current protection | Classification |
|---|---|---|---|---|
| Activity | `app/src/main/java/com/revcore/android/MainActivity.kt` | Kotlin → DEX | None; debuggable APK | VERIFIED |
| ViewModel | `app/src/main/java/com/revcore/android/ui/MainViewModel.kt` | Kotlin → DEX | None | VERIFIED |
| Navigation/scaffold | `ui/MainAppScaffold.kt`, `ui/NavigationTab.kt` | Kotlin → DEX | None | VERIFIED |
| Screens | `ui/screens/DashboardScreen.kt`, `LiveDataScreen.kt`, `DiagnosticsScreen.kt`, `EcuInfoScreen.kt`, `TuningScreen.kt`, `SettingsScreen.kt`, `LogScreen.kt`, `TermsScreen.kt`, `LoadingScreen.kt`, `TuningLogPanel.kt` | Kotlin → DEX | None | VERIFIED |
| Theme/colors | `ui/theme/Theme.kt`, `ui/theme/Color.kt` | Kotlin → DEX | None | VERIFIED |
| Tuning state | `ui/tuning/TuningState.kt` | Kotlin → DEX | None | VERIFIED |
| Strings | `res/values/strings.xml` and generated locale files | XML → resources | None | VERIFIED |
| Styles | `res/values/styles.xml`, `res/values-v28/styles.xml` | XML → resources | None | VERIFIED |
| Logo | `res/drawable/revcore_logo.png` | PNG | None | VERIFIED |
| Splash reference | `res/drawable/revcore_splash_ref.jpg` | JPG | None | VERIFIED |
| Launcher image | `res/drawable/ic_launcher_img.jpg` | JPG | None | VERIFIED |
| Adapter schematic | `res/drawable/ftdi_adapter_schematic.png` | PNG | None | VERIFIED |
| Adaptive icon foreground | `res/drawable/ic_launcher_foreground.xml` | Vector/layer-list | None | VERIFIED |
| Mipmaps | `res/mipmap-*/ic_launcher*.png`, `mipmap-anydpi/ic_launcher*.xml` | PNG/XML | None | VERIFIED |
| Template/notification resources | `res/drawable/ic_call_*`, `notification_*` | XML | None | VERIFIED |

**Important:** most in-app text is **hardcoded in Kotlin**, not read from `strings.xml`. Encrypting `strings.xml` would not hide the visible UI text. The visible UI is DEX code and data.

### 3.3 Reference Data Assets

| Asset | Path | Size | Records / count | SHA-256 | Loader | Current protection | Classification |
|---|---|---|---|---|---|---|---|
| ECM database | `app/src/main/assets/ecm_database.json` | 748,580 B | 489 `partNumber` records | `7c7a2dd69b48e4257493c944b276ee7f3811c173f44c037f4d987c9b280b652a` | `EcmDatabase.loadFromAssets()` | None | VERIFIED / RISK |
| FlashPro profiles | `app/src/main/assets/flashpro_profiles.json` | 127,269 B | JSON profile catalog | `9c0be8649bdd1ef114fba6211f00f3733f4dcca0190ab9c7a173b45b3e703da4` | `FlashProProfile.loadFromAssets()` | None | VERIFIED / RISK |
| MAP manifest | `app/src/main/assets/flashpro_maps/manifest.tsv` | 29,628 B | 163 lines (header + 162 entries) | `189593bb99217aa2650830b29d0d9018e42c3972ccdf4278b6296366becfdd41` | `BundledMapManifest.parse()` | SHA-256 list, unsigned | VERIFIED / RISK |
| Original MAPs | `app/src/main/assets/flashpro_maps/ORIGINAL/*.map` | 35,195,840 B total | 162 files | Per-file hashes in manifest | `BundledMapStore.readVerified()` | Size + SHA-256 against unsigned manifest | VERIFIED / RISK |

### 3.4 Existing Cryptographic and Integrity Code

| Component | Path | What it does | What it does not do | Classification |
|---|---|---|---|---|
| `MapCrypto` | `data/flashpro/MapCrypto.kt` | AES-128-CBC encrypt/decrypt, PKCS#5 padding validation, SHA-256 helper | No MAC, no signature, fixed key/IV, no authenticity | VERIFIED / RISK |
| `MapCrypto.KEY_ASCII` | `MapCrypto.kt:23` | Hardcoded `"0123456789ABCDEF"` | Not secret from an APK reader | VERIFIED / RISK |
| `MapCrypto.IV_ASCII` | `MapCrypto.kt` constant | Hardcoded `"ABCDEF0123456789"` | Fixed IV for all files | VERIFIED / RISK |
| `BundledMapManifest` | `data/flashpro/BundledMapManifest.kt` | TSV parse/encode, per-entry size/hash/status | Manifest authenticity | VERIFIED |
| `BundledMapStore.readVerified` | `BundledMapManifest.kt:118` | Checks exact byte length and SHA-256 | Trusted root for manifest | VERIFIED |
| `MapCatalog.importEncrypted` / `open` | `data/flashpro/MapCatalog.kt:58,110` | Decrypts, hashes ciphertext/plaintext, re-verifies catalog hash | Vendor signature or trusted manifest | VERIFIED |
| `RomBinary` | `data/rom/RomBinary.kt` | Real ECU checksum calculation/verify/fix | App/asset authenticity | VERIFIED |
| `FlashEngine` | `data/flashpro/FlashEngine.kt` | Default-deny write state machine | N/A (safety, not integrity) | VERIFIED |
| Android Keystore | Not used | — | — | NOT IMPLEMENTED |
| APK signature verification | Not used | — | — | NOT IMPLEMENTED |
| Signed manifest verification | Not used | — | — | NOT IMPLEMENTED |

### 3.5 Hardware and Protocol Components That Must Not Be Altered

| Component | Path | Function | Security-relevant note | Classification |
|---|---|---|---|---|
| `HondaProtocolEngine` | `core/protocol/HondaProtocolEngine.kt` | Connect, identify, live data, DTC read/clear | No write capability; security must not change timing or sequence | VERIFIED |
| `UsbSerialLibraryTransport` | `core/usb/UsbSerialLibraryTransport.kt` | USB serial transport via usb-serial-for-android 3.8.0 | Do not replace or gate legitimate USB | VERIFIED |
| `FtdiSerialDriver` | `core/ftdi/FtdiSerialDriver.kt` | Custom FTDI control transfers | Do not rewrite | VERIFIED |
| `FtdiConstants` | `core/ftdi/FtdiConstants.kt` | 10400/9600 baud, 8N1 | Do not change | VERIFIED |
| `AdapterConnectionPolicy` | `core/usb/AdapterConnectionPolicy.kt` | Supported adapter vendors | Do not narrow legitimate adapters without evidence | VERIFIED |
| `KlineTransceiver` / `KlineWireEngine` | `core/protocol/`, `core/comm/` | K-Line framing, timing, timeouts | Do not insert crypto into I/O path | VERIFIED |
| `LiveDataProfile` | `core/comm/LiveDataProfile.kt` | Request bytes and decoders | Do not replace with simulated values | VERIFIED |
| `HondaIdentifierParser` | `core/protocol/HondaIdentifierParser.kt` | 0x1A frame parsing | Do not change identification protocol | VERIFIED |
| `EcmIdentityMatcher` | `data/ecu/EcmDatabase.kt:17` | Normalized exact/bounded matching | Do not hardcode one ECU ID | VERIFIED |
| `HondaDtcDatabase` | `core/protocol/HondaDtcDatabase.kt` | DTC descriptions | Leave behavior intact | VERIFIED |
| `MainViewModel` | `ui/MainViewModel.kt` | Startup, USB, live stream, storage, tuning operations | Add trust gate carefully; do not break startup/USB | VERIFIED |

### 3.6 Local State and Workspace Artifacts

| Component | Path | Current state | Risk | Classification |
|---|---|---|---|---|
| Terms acceptance | `data/local/TermsStore.kt` | Plain `SharedPreferences` `revcore_prefs`, key `terms_accepted_version` | Low; resettable by clearing data | VERIFIED |
| User storage | `Internal Storage/Revcore/` | Plain files in vendor folders | User-controlled; may contain MAP/backup data | VERIFIED |
| Debug keystore | `debug.keystore` | Present | Public debug key; cannot serve as release identity | VERIFIED / RISK |
| Build passwords | `app/build.gradle.kts` | `"android"` for store/key | Public debug credentials; unsafe for release | VERIFIED / RISK |
| Workspace ZIPs | `revcore.zip`, `revcore qoder.zip` | ~100–121 MB | May contain source, references, or stale keys if shared | VERIFIED / RISK |
| Reference evidence | `refs/` | FlashPro APK/firmware/MAP evidence | Proprietary/vendor material; distribution risk | VERIFIED / RISK |
| Test sources | `app/src/test` | 26 files | Baseline 196 tests reported | PARTIALLY VERIFIED |
| Nine-key file | Not present in the audited workspace paths | Not requested, not accessed | — | NOT VERIFIED |

---

## 4. Current Weaknesses

### 4.1 W-01 — Distributed APK Uses the Public Debug Certificate

**Evidence:** `app/build.gradle.kts:24-31` creates `signingConfigs.create("release")` with `storeFile = file("../debug.keystore")`, `storePassword = "android"`, `keyAlias = "androiddebugkey"`, `keyPassword = "android"`. Both `release` and `debug` build types use this config. `apksigner verify --print-certs` on `dist/RevCore build 141126.apk` reports `CN=Android Debug, O=Android, C=US` and certificate SHA-256 `a57a28ec69fbdacc57f41610e67481a1a3ba7a1138eaed90ed438a33372f8ab4`.

**Impact:** the signing identity is public and reproducible. Repackagers can sign modified APKs with the same key. There is no trusted identity to pin and no meaningful separation between developer build and release.

**Severity:** CRITICAL.
**Classification:** VERIFIED / RISK.
**Required direction:** generate and protect a real release key outside the repository; keep it separate from all nine operational keys; never commit it. This requires the developer, not this audit.

### 4.2 W-02 — Distributed APK Is Debuggable

**Evidence:** `aapt2 dump xmltree` on the APK reports `android:debuggable(0x0101000f)=true`. The current deliverable is a debug build.

**Impact:** debugger attachment, `run-as`, memory inspection, and easier extraction of runtime state. This defeats most client-side secrecy and makes runtime hooks easier.

**Severity:** CRITICAL.
**Classification:** VERIFIED / RISK.
**Required direction:** release builds must be non-debuggable. Debug builds may remain debuggable but must not be the distributed artifact.

### 4.3 W-03 — No APK Identity Verification at Runtime

**Evidence:** no reference to `PackageManager`, `GET_SIGNING_CERTIFICATES`, `signingInfo`, certificate digest, or `BuildConfig` integrity checks in the source. `MainActivity` starts directly into splash/terms/dashboard. No custom `Application` class exists.

**Impact:** a modified APK that keeps the application ID and signs with any key launches normally. The app never notices that its code or resources changed. This is the central failure against rebranding.

**Severity:** CRITICAL.
**Classification:** NOT IMPLEMENTED / RISK.
**Required direction:** pin the release certificate digest and check it at startup; treat mismatch as a controlled integrity failure. This is deterrence, not proof, because the check itself can be patched.

### 4.4 W-04 — No Signed Integrity Manifest

**Evidence:** no manifest signature verification exists. `BundledMapManifest` parses a TSV that contains SHA-256 values, but the TSV itself is not signed. `EcmDatabase` and `FlashProProfile` read JSON directly.

**Impact:** an attacker can replace both a data file and its hash entry. There is no trusted root for any asset.

**Severity:** CRITICAL.
**Classification:** NOT IMPLEMENTED / RISK.
**Required direction:** a signed manifest with a pinned verification key; manifest covers component ID, version, sizes, hashes, key IDs, and nonces. Prefer an asymmetric signature over a shared HMAC secret.

### 4.5 W-05 — Hardcoded MAP Key and Fixed IV; No Authenticity

**Evidence:** `data/flashpro/MapCrypto.kt:23` defines `KEY_ASCII = "0123456789ABCDEF"`; the IV is `"ABCDEF0123456789"`; `Cipher.getInstance("AES/CBC/NoPadding")` is used for both decrypt and encrypt. The comments explicitly state there is no MAC, signature, or per-file IV.

**Impact:**

- anyone who reads the APK can decrypt every bundled `.map`;
- anyone can encrypt a chosen payload that the app will accept as a valid MAP;
- CBC with a fixed IV leaks equality of plaintext blocks across files;
- padding validation detects malformed ciphertext but not malicious modification;
- there is no vendor authenticity, only structural plausibility.

**Severity:** CRITICAL.
**Classification:** VERIFIED / RISK.
**Required direction:** AES-256-GCM with a per-file nonce, AAD binding file name/version/component, and a signed manifest. Do not reuse the FlashPro static key as the RevCore production key.

### 4.6 W-06 — MAP Manifest Is Unsigned

**Evidence:** `BundledMapManifest.parse()` validates row shape, status, and SHA-256 length. `BundledMapStore.readVerified()` compares file size and SHA-256 to the entry. Neither verifies who produced the manifest.

**Impact:** replacing a `.map` file and its manifest row is trivial. The check provides only accidental-corruption detection.

**Severity:** HIGH.
**Classification:** VERIFIED / RISK.

### 4.7 W-07 — ECM Database and Profiles Are Unauthenticated

**Evidence:** `EcmDatabase.loadFromAssets()` opens `assets/ecm_database.json`, parses it with `org.json.JSONArray`, and uses the records directly. `FlashProProfile.loadFromAssets()` has the same pattern. No hash, signature, or version check exists before use.

**Impact:** modified tuning metadata, offsets, rev limits, sensor types, checksum types, verification flags, or vehicle identities are accepted. This can mislead the user or feed incorrect values into the editor. The validator checks schema/consistency, not authenticity.

**Severity:** HIGH.
**Classification:** VERIFIED / RISK.

### 4.8 W-08 — Backup and Local State Exposure

**Evidence:** `AndroidManifest.xml` has `android:allowBackup="true"`. `TermsStore` writes plain `SharedPreferences`.

**Impact:** app data can be backed up or extracted on debuggable builds; local state is not confidential or integrity-protected. Today the state is low-value, but future local integrity state must not repeat this pattern.

**Severity:** MEDIUM.
**Classification:** VERIFIED / RISK.

### 4.9 W-09 — No Minification or Obfuscation

**Evidence:** `release { isMinifyEnabled = false }`.

**Impact:** Kotlin class/method names, string constants, and control flow are easy to recover. This does not break security by itself, but it makes guard removal and key discovery cheaper.

**Severity:** MEDIUM.
**Classification:** VERIFIED / RISK.

### 4.10 W-10 — Unused Network Permissions

**Evidence:** `AndroidManifest.xml` declares `INTERNET` and `ACCESS_NETWORK_STATE`; no HTTP client, endpoint, socket, or network use was found in Kotlin source. The app is designed to be offline.

**Impact:** unnecessary attack surface and a misleading permission profile. If a dependency or future code exfiltrates data, the permission is already granted.

**Severity:** MEDIUM.
**Classification:** VERIFIED / RISK.
**Required direction:** remove only after confirming no dependency requires them; do not add any cloud dependency to compensate.

### 4.11 W-11 — No Native Layer

**Evidence:** no `app/src/main/jni`, no CMake, no project `.c`/`.cpp`/`.so`. The APK contains only AndroidX `libandroidx.graphics.path.so`.

**Impact:** Layer 6 cannot be implemented today. Checks live in DEX and are easier to patch. Adding native code introduces ABI, 16 KB page-size, crash, and build complexity.

**Severity:** MEDIUM.
**Classification:** NOT IMPLEMENTED.

### 4.12 W-12 — No Controlled Integrity-Failure Policy

**Evidence:** there is no trust gate, no integrity screen, and no fail-closed path. Errors in asset loading fall back to `EcmDatabase.MODELS` or log and continue.

**Impact:** if integrity checks are added carelessly, failures could crash, hang, or silently degrade. Today there is no policy at all.

**Severity:** HIGH.
**Classification:** NOT IMPLEMENTED / RISK.
**Required direction:** one controlled, user-visible failure path; no random crash; no partial trust; no release bypass flag.

### 4.13 W-13 — Compose UI and OS Resources Cannot Be Fully Encrypted

**Evidence:** UI text is hardcoded in Kotlin; images are loaded with `painterResource(R.drawable.revcore_logo)` and `painterResource(R.drawable.ftdi_adapter_schematic)`. Launcher label/icon/theme are read by the OS from resources.

**Impact:** encrypting every XML resource would not protect visible text and would break normal resource resolution. Rebranding a repackaged APK remains possible at the resource layer.

**Severity:** MEDIUM.
**Classification:** VERIFIED.

### 4.14 W-14 — Dynamic USB Receiver Exported by Default on API 26–32

**Evidence:** `MainActivity.kt:95-99` registers `usbReceiver` with `Context.RECEIVER_NOT_EXPORTED` only on API ≥ 33; otherwise it calls the two-argument `registerReceiver`, which is exported by default on older APIs. The receiver accepts the custom action `com.revcore.android.USB_PERMISSION` and trusts `EXTRA_PERMISSION_GRANTED` and `EXTRA_DEVICE`.

**Impact:** a malicious app on API 26–32 could send a crafted broadcast. The practical impact is limited because the app still needs a real USB device and permission state, but the receiver should not trust extras without validating the device against `UsbManager`.

**Severity:** LOW.
**Classification:** VERIFIED / RISK.
**Required direction:** validate the device and permission state; use an explicit/signature permission or a non-exported mechanism on older APIs where possible. Do not break the system USB permission flow.

### 4.15 W-15 — Workspace Key and Artifact Hygiene

**Evidence:** `debug.keystore` and plaintext build passwords are in the workspace. Large `revcore.zip` and `revcore qoder.zip` archives exist. `refs/` contains vendor evidence. There is no `.git`, so normal secret scanning and history control are absent.

**Impact:** if the workspace or ZIPs are shared, source, stale keys, and vendor material may leak. A future nine-key file dropped into this tree would be at risk.

**Severity:** HIGH.
**Classification:** VERIFIED / RISK.
**Required direction:** keep production keys outside the tree; add ignore rules; never place the nine-key file in the project; scan artifacts before distribution.

### 4.16 Additional Observations

| ID | Observation | Impact | Severity | Classification |
|---|---|---|---|---|
| W-16 | `MANAGE_EXTERNAL_STORAGE` is broad. | Necessary for the current shared-storage design, but broad if distributed through stores. | MEDIUM | VERIFIED |
| W-17 | `MapCatalog` trusts the manifest's profile mapping and hashes. | A modified catalog can point a MAP at a different profile. | HIGH | VERIFIED |
| W-18 | `EcmDatabase` falls back to three hardcoded models if the asset cannot be read. | Availability fallback, but also a way to force a limited catalog by deleting the asset. | MEDIUM | VERIFIED |
| W-19 | `FlashEngine` is default-deny. | Good safety property; not an integrity control. | — | VERIFIED |
| W-20 | APK v2 is the only signature scheme. | Integrity works for the signed bytes, but no key-rotation support; no v3/v4. | MEDIUM | VERIFIED |
| W-21 | No code-integrity check beyond APK signature. | DEX can be patched and re-signed. | HIGH | NOT IMPLEMENTED |
| W-22 | No log redaction policy for future keys. | A future implementation could leak secrets into logcat or exported logs. | MEDIUM | NOT IMPLEMENTED |
| W-23 | The app declares no custom `Application` class. | No central trust initialization point; easy to add later. | LOW | VERIFIED |
| W-24 | The user-visible `Revcore` folder is unencrypted. | Backups/exports are user-controlled and can contain proprietary MAP data. | MEDIUM | VERIFIED |

---

## 5. UI Protection Feasibility

### 5.1 What the Current UI Actually Is

The UI is **Jetpack Compose**. Almost all visible text is Kotlin string literals inside `ui/screens/*.kt`. Only a small set of strings is in `res/values/strings.xml` (for example `app_name`, `app_tagline`). Images are loaded through `painterResource` from `res/drawable`.

Therefore:

- `strings.xml` encryption would not hide most visible text;
- Compose layout, colors, text, and behavior are compiled into DEX;
- a repackager can change text, colors, and layout by patching DEX;
- the launcher label, launcher icon, round icon, and manifest theme are read by the Android package manager and **must remain resolvable resources**.

### 5.2 What Can Be Protected

| UI element | Can it be encrypted? | Can it be signed? | Security value |
|---|---|---|---|
| In-app strings hardcoded in Kotlin | No, without encrypting/packing DEX | Yes, indirectly via APK signature | Low; code is patchable |
| `res/values/strings.xml` | Technically possible, but not usable by the OS if encrypted | Yes, via APK signature | Very low; most UI text is not there |
| Auxiliary images (logo, schematic) | Yes, as encrypted assets loaded through a custom decoder | Yes, via signed manifest + hash | Low–medium; deters naive asset replacement |
| Launcher icon / adaptive icon | No, OS must read it | Yes, only via APK signature | Cannot protect against rebranding at resource level |
| Launcher label | No, OS must read it | Yes, only via APK signature | Cannot protect |
| Manifest theme | No, OS must resolve it | Yes, only via APK signature | Cannot protect |
| Compose layout/behavior | No, unless DEX packing | Yes, only via APK signature | Cannot protect against patching |

### 5.3 Android Keystore Suitability

Android Keystore is suitable for:

- device-bound symmetric keys for local state (`K5`, `K7` candidates);
- protecting preferences or cached verification results;
- detecting simple file extraction from the app sandbox.

Android Keystore is **not** suitable for:

- proving APK authenticity offline;
- attesting code integrity without a server;
- protecting UI code or resources from a device-controlling attacker;
- guaranteeing hardware backing on all API 26 devices (StrongBox is API 28+ and optional).

Keystore keys can be invalidated by lock-screen changes, factory reset, or app data clear. Any design that uses Keystore must define recovery behavior and must not treat key loss as tampering.

### 5.4 What Can Be Done Against Runtime Instrumentation

Nothing absolute. Frida, Xposed, debugger attachment, and custom ROMs can hook:

- `Cipher` and `MessageDigest`;
- signature verification methods;
- manifest parsing;
- the trust gate;
- Compose rendering.

A device-controlling attacker can always bypass client-side checks. The realistic goal is to raise cost and detect naive modification, not to make patching impossible. Root, KernelSU, custom ROM, USB debugging, or bootloader status **alone** must not be used as tamper evidence.

### 5.5 Recommendation

Do **not** encrypt every XML resource. Protect selected high-value assets (ECM DB, profiles, MAP packages) and rely on APK signature + signed manifest for identity. Optionally move the logo and schematic to encrypted assets later, but treat that as cosmetic deterrence, not security. Do not encrypt the launcher label/icon/theme.

---

## 6. ECU Database and MAP Protection Feasibility

### 6.1 ECM Database

**Current state:** `EcmDatabase.loadFromAssets()` reads `assets/ecm_database.json` (748,580 B, 489 records), parses it, and uses it for vehicle identity, tuning offsets, rev limits, sensor type, checksum type, and verification flags. No authenticity check exists.

**Feasible design:**

- Encrypt the JSON with AES-256-GCM under `K3`.
- Use a per-package nonce and AAD that binds the component name, schema version, and record count.
- Store the encrypted package as an asset; store its ciphertext SHA-256 and plaintext SHA-256 in a signed manifest.
- Decrypt once during `initializeSession()` on `Dispatchers.IO`; 748 KB is small.
- Verify the GCM tag and the plaintext hash before parsing.
- Keep the existing `EcmDatabaseValidator` as a second line of defense.
- On integrity failure, do not silently use the three-model fallback as if it were the real catalog. Show a controlled integrity state and disable DB-dependent tuning. Raw ECU identification can still be displayed if the identification path itself is intact.

**Safety constraints:**

- Do not change `EcmIdentityMatcher` semantics.
- Do not hardcode one ECU ID for all vehicles.
- Do not remove existing vehicle definitions; the encrypted package must contain the same 489 records.
- Do not let a DB integrity failure block USB attach, K-Line initialization, or basic diagnostics unless the developer explicitly chooses that policy.

### 6.2 FlashPro Profiles

**Current state:** `FlashProProfile.loadFromAssets()` reads `assets/flashpro_profiles.json` (127,269 B) without verification. Profiles drive MAP definitions and editor behavior.

**Feasible design:** treat this as part of the same protected data family as the ECM database. Encrypt with `K3` (or a dedicated sub-key), verify via the signed manifest, and decrypt once. Do not let profile names or labels become an unauthenticated path to a different MAP definition.

### 6.3 MAP Package

**Current state:**

- 162 `.map` files, 35,195,840 B total.
- `BundledMapManifest` lists file name, size, SHA-256, profile, match method, status, note.
- `BundledMapStore.readVerified()` checks size and SHA-256.
- `MapCrypto` decrypts with a hardcoded AES-128-CBC key and fixed IV.
- `MapCatalog` stores ciphertext and plaintext hashes and rechecks them on open.
- The manifest is unsigned.

**Feasible design:**

- Encrypt each `.map` independently with AES-256-GCM under `K4`.
- Per-file nonce; AAD = file name + package version + component ID.
- Signed manifest contains: file name, ciphertext size, ciphertext SHA-256, plaintext size, plaintext SHA-256, nonce, key ID, profile ID, match method, status, note.
- On open: verify the manifest signature (once per session), verify ciphertext hash, decrypt, verify plaintext hash, then parse.
- Do not decrypt or hash all 35 MB at startup. The manifest is 29 KB; per-file verification happens on demand.
- Keep the current `BundledMapStatus` semantics (`READY`, `AMBIGUOUS_PROFILE`, `UNRECOGNIZED`) and the current profile-matching rules.
- Keep map files in `assets/flashpro_maps/ORIGINAL/` architecture or move them only if the loader path is updated consistently. Do not change the user-visible MAP library behavior.

**Why not encrypt the whole 35 MB as one blob:** larger memory footprint, slower startup, harder partial failure handling, and a single corrupt block would invalidate the entire library. Per-file packages are better.

### 6.4 What Encryption Does and Does Not Solve

| Threat | AES-GCM package + signed manifest | Notes |
|---|---|---|
| Naive replacement of a `.map` file | Detected | Ciphertext hash and GCM tag fail |
| Replacement of map + manifest | Detected only if manifest signature verifies | Unsigned manifest provides no protection |
| Repackaged APK with patched verifier | Not prevented | Client-side check can be removed |
| Attacker with extracted key | Not prevented | Offline key must exist somewhere |
| Accidental corruption | Detected | Good availability benefit |
| User editing an exported BIN/MAP | Out of scope | Exports are user files |

### 6.5 Important Boundary

Encryption protects **data at rest inside the APK** and detects accidental or naive modification. It does not make the application unmodifiable. The signed manifest is the trust root; without it, GCM only proves that the attacker used the right key.

---

## 7. Eight-Layer Assessment

The requested eight layers are assessed below. “Feasible” means technically compatible with the current architecture; it does not mean it should be implemented in Phase 1.

### Layer 1 — APK Identity

| Aspect | Assessment |
|---|---|
| Current state | Debug certificate, v2-only, debuggable, no runtime check. |
| Purpose | Bind the running package to a known signing identity. |
| Feasibility | High. `PackageManager.getPackageInfo(..., GET_SIGNING_CERTIFICATES)` and SHA-256 of the signing certificate are available on API 26+. |
| What it protects | Detects naive repackaging and re-signing with a different key. |
| What it cannot do | A patched check can be removed; a repackaged APK signed with the original key (if the key leaks) passes. |
| Dependencies | Requires a real release key and a pinned digest. Without a release key, there is nothing meaningful to pin. |
| Main risks | Debug builds fail the check; signing-key migration breaks updates; false trust if the expected digest is stored in plain DEX and patched. |
| Verdict | **Must be first.** It is the anchor for every other layer. |
| Classification | NOT IMPLEMENTED / HIGH PRIORITY |

### Layer 2 — UI Integrity

| Aspect | Assessment |
|---|---|
| Current state | No UI integrity check. Compose text in DEX; images via `painterResource`. |
| Purpose | Detect modification of visible branding and layouts. |
| Feasibility | Partial. Auxiliary images can be hashed/encrypted; DEX UI behavior cannot be protected without packing; OS resources cannot be encrypted. |
| What it protects | Naive replacement of selected images/assets. |
| What it cannot do | Prevent text/layout patching, launcher icon/label replacement in a repackaged APK, or screenshots. |
| Dependencies | Layer 1 and Layer 5. |
| Main risks | Custom image loaders can break resource loading, offline rendering, or accessibility; encrypting OS resources breaks the app. |
| Verdict | **Low priority.** Do not encrypt all XML. Optional cosmetic asset protection only. |
| Classification | NOT IMPLEMENTED / LOW VALUE |

### Layer 3 — Resource Protection

| Aspect | Assessment |
|---|---|
| Current state | None. All resources are plain. |
| Purpose | Protect non-code resources from replacement. |
| Feasibility | Partial. Resources the OS must resolve (label, icon, theme) cannot be encrypted. Non-OS assets can be encrypted and loaded manually. |
| What it protects | Selected asset files. |
| What it cannot do | Protect manifest-declared identity or compiled resource tables from a repackager. |
| Dependencies | Signed manifest and a custom loader. |
| Main risks | Resource ID changes, build complexity, startup latency, broken previews/tests. |
| Verdict | **Selective only.** Prefer protecting data packages over resource tables. |
| Classification | NOT IMPLEMENTED / PARTIAL FEASIBILITY |

### Layer 4 — ECU Database

| Aspect | Assessment |
|---|---|
| Current state | Unauthenticated JSON, 489 records, direct asset load. |
| Purpose | Prevent tampering with vehicle identity and tuning metadata. |
| Feasibility | High. AES-256-GCM package + signed manifest; one-time 748 KB decrypt. |
| What it protects | Offsets, rev limits, sensor/checksum types, verification flags, vehicle names. |
| What it cannot do | Stop an attacker who patches the loader or extracts the key. |
| Dependencies | Layer 5 manifest, `K3`, and a controlled failure policy. |
| Main risks | Breaking identification if the DB is unavailable; changing records; blocking diagnostics unnecessarily. |
| Verdict | **High value, Phase 3.** |
| Classification | NOT IMPLEMENTED / HIGH PRIORITY |

### Layer 5 — Integrity Manifest

| Aspect | Assessment |
|---|---|
| Current state | Unsigned MAP TSV only; no general manifest. |
| Purpose | One authenticated list of component hashes, sizes, versions, and key IDs. |
| Feasibility | High. Prefer Ed25519 or ECDSA P-256 signature with a pinned public key; verify once per launch. |
| What it protects | All listed assets and the relationship between them. |
| What it cannot do | Protect itself if the verifier or pinned key is patched; HMAC with an embedded key is forgeable by extraction. |
| Dependencies | Layer 1 and a developer-held signing key. |
| Main risks | A single manifest becomes a single point of failure; a bad manifest can brick tuning; rotation requires app updates. |
| Verdict | **Must be second, after Layer 1.** |
| Classification | NOT IMPLEMENTED / HIGH PRIORITY |

### Layer 6 — Native Code

| Aspect | Assessment |
|---|---|
| Current state | No project native code. Only AndroidX path library. |
| Purpose | Move checks/keys into harder-to-patch native code. |
| Feasibility | Technically possible, but not currently present. Requires NDK, CMake, ABI builds, 16 KB page-size alignment on modern Android, crash handling, and test coverage. |
| What it protects | Raises reverse-engineering cost; can host a checker. |
| What it cannot do | Stop a determined attacker; native code can be patched or hooked too. |
| Dependencies | New build infrastructure and ABI policy. |
| Main risks | Crashes, ABI gaps, larger APK, build complexity, 16 KB page-size failures, harder debugging. |
| Verdict | **Not justified in Phase 1.** Revisit only after non-native layers are stable and measured. |
| Classification | NOT IMPLEMENTED / DEFER |

### Layer 7 — Runtime Protection

| Aspect | Assessment |
|---|---|
| Current state | None. |
| Purpose | Detect debugger, hooks, unexpected environment, or inconsistent state. |
| Feasibility | Partial. Basic checks are easy; reliable detection is not. Root/ROM/debug/bootloader alone must not be treated as tampering. |
| What it protects | Raises cost against casual instrumentation. |
| What it cannot do | Stop Frida/Xposed or a device-controlling attacker; false positives are a real risk. |
| Dependencies | Layer 1, Layer 5, Layer 8. |
| Main risks | Blocking legitimate users, detecting OEM debug settings, violating the “no random crashes” rule. |
| Verdict | **Minimal, evidence-based checks only.** No root-only verdicts. |
| Classification | NOT IMPLEMENTED / CAUTION |

### Layer 8 — Final Trust Gate

| Aspect | Assessment |
|---|---|
| Current state | None. |
| Purpose | Aggregate identity, manifest, asset, and runtime results into one controlled decision. |
| Feasibility | High if designed as a typed state machine with a dedicated UI and no crash paths. |
| What it protects | Prevents silent partial trust; makes failure explicit. |
| What it cannot do | Prevent bypass; it is still client-side code. |
| Dependencies | Layers 1, 4, 5, and optionally 3/6/7. |
| Main risks | Blocking USB/K-Line, blocking diagnostics, false positives on debug builds, unreadable error screens, release bypass flags. |
| Verdict | **Required before any protected feature ships.** Implement as fail-closed for sensitive operations, with a clear integrity screen. |
| Classification | NOT IMPLEMENTED / HIGH PRIORITY |

### 7.1 Layer Dependency Graph

```
Layer 1 (APK identity)
   │
   ├── Layer 5 (signed manifest)
   │      ├── Layer 4 (ECU DB / profiles)
   │      ├── Layer 3 (selected resources)
   │      └── Layer 2 (selected UI assets)
   │
   ├── Layer 7 (runtime checks) ── optional evidence
   │
   └── Layer 8 (final trust gate)
          └── aggregates 1, 4, 5, 3, 7

Layer 6 (native) — optional hardening; can host 1/7/8 checks later
```

### 7.2 Single Points of Failure

| Single point | Failure mode | Mitigation |
|---|---|---|
| Release signing key | Leak allows signing a malicious update that passes identity checks | Offline key, hardware token, strict access, rotation plan |
| Pinned certificate digest / public key | Patched in DEX | Multiple checks, obfuscation, optional native; still not absolute |
| Signed manifest | Corrupt or malicious manifest blocks all protected data | Versioned manifests, clear error, rollback build, offline recovery |
| Trust gate | Removed or bypassed | Multiple call sites, no release bypass flag, optional native checker |
| Embedded runtime key | Extracted | Per-build keys, wrapping, obfuscation, native; unavoidable offline limit |

### 7.3 Guard-Removal Detection

A guard can be removed by patching the branch that calls it. Useful countermeasures:

- call integrity checks from more than one independent path;
- verify the manifest before opening each protected asset, not only at startup;
- cross-check the manifest’s declared size/hash against the actual asset;
- verify the APK certificate and the manifest signature independently;
- keep a small native checker later if justified;
- make the failure state explicit and non-crashing.

None of this makes removal impossible. It raises cost and catches naive attempts. The report must not claim otherwise.

---

## 8. Nine-Key Allocation Assessment

The requested key set is assessed as a **design proposal**. No key was generated, requested, read, or embedded.

### 8.1 Key-by-Key Assessment

| Key | Intended component | Spec algorithm | Where it would live | Runtime need | Assessment | Classification |
|---|---|---|---|---|---|---|
| **K1** | UI assets | AES-256-GCM | Embedded or wrapped in APK | Yes, to render selected images/assets | Low security value: UI code is DEX; only auxiliary images can be protected. Optional. | FEASIBLE / LOW VALUE |
| **K2** | Resource bundle | AES-256-GCM | Embedded or wrapped | Yes, if custom resource loader | Partial: OS-resolved resources cannot be encrypted; encrypting all XML is not recommended. | PARTIAL |
| **K3** | ECU database | AES-256-GCM | Wrapped DEK in APK; root protected | Yes, at startup | High value; 748 KB one-time decrypt; must preserve 489 records and matching semantics. | RECOMMENDED |
| **K4** | MAP package | AES-256-GCM | Wrapped DEK | Yes, per file on open | High value; per-file packages; 35 MB lazy decrypt; must preserve 162 files and profiles. | RECOMMENDED |
| **K5** | Local config | AES-256-GCM | Prefer Android Keystore-wrapped, not a fixed embedded key | Yes, on device | Suitable for device-bound state. If it must survive reinstall/backup, a fixed key is extractable. | CONDITIONAL |
| **K6** | Integrity policy | HMAC-SHA-256 | Embedded shared secret | Yes | A shared HMAC secret in the APK is extractable; it cannot be a trustworthy root against a local attacker. Prefer an asymmetric signature for the manifest/policy. If HMAC is retained, treat it as corruption detection, not authenticity. | WEAK AS ROOT |
| **K7** | Runtime state | HMAC-SHA-256 | Prefer Keystore HMAC key | Yes, per state write | Good for detecting local state edits; device-bound Keystore HMAC is stronger than an embedded key. | CONDITIONAL |
| **K8** | Protected component | AES-256-GCM | TBD | TBD | The component is not defined in the current code. Assigning a key without a concrete component creates a single point of failure with no clear benefit. Define scope first. | UNDEFINED |
| **K9** | Core package | AES-256-GCM | TBD | TBD | Cannot encrypt DEX in a normal Android app without a packer/classloader. If “core package” means auxiliary data, it is feasible; if it means executable code, it is high-risk and not recommended. | NOT FOR CODE |

### 8.2 Does Every Layer Need AES?

No.

- **AES-256-GCM** is appropriate for data at rest: K1–K5, K8, K9 (if they protect data).
- **HMAC-SHA-256** is appropriate for local state and policy copies (K6/K7), but only as a tamper-evidence mechanism.
- **Asymmetric signatures** (Ed25519 or ECDSA P-256) are appropriate for the integrity manifest and policy root because the verification key can be public. This avoids the “shared secret in the APK” problem.
- **Keystore-backed keys** are appropriate for K5/K7 when state is device-bound and does not need to be portable.
- **Hashing (SHA-256)** is not encryption; it is used for manifests and file verification.
- **No key** is appropriate for launcher label/icon/theme, which the OS must read.

### 8.3 Circular Dependencies

Avoid these cycles:

1. **K6 must not authenticate the manifest that contains K6.** The manifest signature must be verified by a key that is independent of the manifest payload. Use a pinned public verification key, not a value inside the manifest.
2. **K3 must not decrypt the database that contains K3.** Keys must live outside the encrypted payload, in the manifest or in a wrapped key slot.
3. **K9 must not be required to verify K3/K4 if K9 itself is encrypted by K6.** Define a linear chain.
4. **The trust gate must not depend on an asset whose integrity it is supposed to establish.** Gate code should be minimal and independent.

A safe chain is:

```
Pinned release certificate digest (Layer 1)
        +
Pinned manifest verification public key
        ↓
Signed manifest (version, component IDs, hashes, key IDs, wrapped DEKs)
        ↓
Unwrap K3/K4/K1/K2/K8/K9 as needed
        ↓
Verify ciphertext hash → AES-256-GCM decrypt → verify plaintext hash
        ↓
Trust gate decides: allow / degrade / controlled failure
```

K6/K7 are outside this chain:

- K6 can HMAC a local copy of policy/state; it is not the root of manifest trust.
- K7 can HMAC runtime state with a Keystore key; it is not used to authenticate APK assets.

### 8.4 Single Points of Failure and Guard Removal

- The **manifest** is a single point: if it is unavailable, all protected data must fail closed or the app must enter a documented degraded mode.
- The **pinned public key** is a single point: if it is patched, all signature checks fail open. Multiple checks and obfuscation only raise cost.
- The **trust gate** is a single point: if it is removed, all downstream checks can be skipped. Call checks near the data, not only at startup.
- The **release signing key** is a single point: if it leaks, an attacker can sign a malicious update that passes identity pinning. Key custody is a developer-process control, not an app control.

### 8.5 Recommendation on the Nine-Key Scheme

- Implement **K3 and K4 first**; they protect the highest-value data.
- Use **K5/K7 with Android Keystore** where state is device-bound.
- Replace or supplement **K6 HMAC** with an asymmetric manifest signature. If the nine-key naming is fixed, keep K6 as an HMAC for local policy copies but do not treat it as the root of trust.
- Defer **K1/K2** until there is a concrete UI asset worth protecting.
- Define **K8** before assigning it; an undefined protected component is a single point of failure with no threat model.
- Do not use **K9** to encrypt DEX. If it protects an auxiliary core data package, document exactly what that package is.
- Do not assume all nine keys must be embedded in the APK. Prefer: public verification key in APK; wrapped DEKs in the manifest; device-bound keys in Keystore; private signing keys never in the APK.

---

## 9. Offline Key Management Design

### 9.1 Two Different Kinds of Secrets

| Category | Examples | Must never ship | Can ship |
|---|---|---|---|
| Developer packaging secrets | Release signing private key; manifest signing private key; key-encryption key; build credentials | Yes | No |
| Runtime decryption material | Wrapped data-encryption keys; public verification key; Keystore aliases; device-bound keys | — | Yes, by necessity |

The critical distinction: a **public verification key** can ship. A **private signing key** cannot. A **data-encryption key** needed offline must either ship (wrapped or obfuscated) or be derivable from something that ships. There is no third option without a network service.

### 9.2 Proposed Key Hierarchy

```
Offline root signing key (Ed25519 or ECDSA P-256, developer-held)
  └─ signs the integrity manifest
       ├─ component list + versions + hashes + key IDs
       ├─ wrapped DEKs for K1–K5, K8, K9 (as applicable)
       └─ policy version

APK ships:
  ├─ pinned release certificate digest (Layer 1)
  ├─ pinned manifest verification public key
  ├─ wrapped DEKs (not raw keys where avoidable)
  └─ optional embedded KEK (extractable; raises cost only)

Device:
  ├─ Android Keystore key for K5/K7 local state
  └─ no developer private key
```

### 9.3 Packaging Process

1. Build assets from a known-good, versioned source.
2. Generate a fresh data-encryption key per component per release (or rotate on a defined schedule).
3. Encrypt each component with AES-256-GCM using a random 96-bit nonce and AAD.
4. Compute ciphertext and plaintext SHA-256.
5. Generate the manifest with component IDs, versions, sizes, hashes, nonces, and key IDs.
6. Sign the manifest offline with the root signing key.
7. Wrap DEKs with the chosen key-encryption key; place only wrapped values in the APK.
8. Build the APK.
9. Verify the APK signature, manifest signature, and every asset hash before publishing.
10. Archive the verified build and the manifest; never publish an unverified artifact.

The process must run on a controlled machine. Keys must not appear in Gradle files, source, `strings.xml`, `BuildConfig`, CI logs, crash reports, or the APK’s assets.

### 9.4 Where Material Must Not Appear

- Git history or workspace ZIPs. The workspace currently has no `.git`, but it has large ZIPs and no key hygiene.
- `app/build.gradle.kts` (the current debug passwords are an example of what not to do for production).
- `AndroidManifest.xml`, `strings.xml`, `res/values`, or `BuildConfig` fields.
- Logcat, `TuningLog`, exported logs, or crash reporting.
- `SharedPreferences` in plaintext.
- APK assets in raw form.
- Filenames or comments that reveal key purpose.

### 9.5 Rotation

- Include a `keyId` and `version` in every encrypted package and manifest entry.
- Support the current key and one previous key during a migration window.
- Rotate data keys on a release cadence or after suspected exposure.
- Rotating the root signing key requires a new app build with a new pinned public key; old app versions cannot be revoked offline.
- Rotating the release APK signing key requires v3 key-rotation support or a new install identity; plan the user migration before changing it.
- There is no remote revocation. A compromised key can only be retired by shipping an update and, if necessary, a new package identity.

### 9.6 Leakage Prevention

- Keep production keys outside the workspace.
- Add ignore rules for keystores, key files, environment files, and build outputs.
- Scan release artifacts for accidental key material before publishing.
- Do not put keys in test fixtures that are shipped.
- Redact keys and plaintext from logs; never log a nonce + key together.
- Limit access to the signing machine and root key.
- Treat `refs/`, `revcore.zip`, and `revcore qoder.zip` as sensitive; do not distribute them with the APK.
- If a key is exposed, rotate it; do not rely on obfuscation after exposure.

### 9.7 Unavoidable Offline Limit

A fully offline app that decrypts data on the user’s device must contain or derive the decryption material on that device. A device-controlling attacker can extract it. Wrapping, obfuscation, splitting, native code, and white-box techniques raise the cost; they do not eliminate the limit. The design should state this explicitly and avoid claiming that offline DRM is unbreakable.

---

## 10. Runtime Decryption Feasibility

### 10.1 Platform Support

- `javax.crypto.Cipher` with `AES/GCM/NoPadding` is available on API 26+.
- `GCMParameterSpec` is available on API 21+.
- `SecureRandom` is available.
- Android Keystore is available on API 23+; StrongBox is API 28+ and optional.
- No new third-party crypto library is required for AES-GCM or HMAC.
- Ed25519 support depends on the platform/provider; ECDSA P-256 is broadly available. Verify the chosen signature algorithm on the minimum API before committing.

### 10.2 Performance and Memory

| Component | Size | Strategy | Expected impact |
|---|---|---|---|
| ECM DB | 748 KB | Decrypt once at startup on `Dispatchers.IO` | Low; milliseconds to low tens of milliseconds |
| Profiles | 127 KB | Decrypt once at startup or lazily | Low |
| Manifest | 29 KB | Verify signature once per launch | Low |
| MAP files | 162 files, 35 MB total; individual files ~49 KB–393 KB | Verify manifest once; decrypt one file on open | Low per open; avoids startup cost |
| UI assets | Small | Optional lazy decrypt | Low |

Do not hash or decrypt all 35 MB at startup. That would add avoidable latency and memory pressure to a splash screen that currently performs a small initialization. Verify the manifest once; verify each file when it is opened.

### 10.3 API Shape

A typed result is safer than exceptions leaking into UI:

```kotlin
sealed interface ProtectedAssetResult {
    data class Success(val bytes: ByteArray, val plaintextSha256: String) : ProtectedAssetResult
    data class Failure(val reason: String) : ProtectedAssetResult
}
```

Requirements:

- no partial plaintext returned on tag failure;
- verify ciphertext hash before decrypt;
- verify GCM tag;
- verify plaintext hash after decrypt;
- do not log key material or full plaintext;
- run off the main thread;
- surface a controlled failure state;
- never throw an uncaught exception into Compose.

### 10.4 GCM Details

- Key: 32 bytes (AES-256).
- Nonce: 12 random bytes per encryption; never reuse a nonce with the same key.
- Tag: 128 bits.
- AAD: stable, unambiguous encoding of component ID, file name, package version, and key ID.
- Do not use a fixed IV. The current `MapCrypto` fixed IV is unsafe for a new design.
- Store nonce and tag alongside ciphertext or encode them in a defined container.
- For each map file, a unique nonce is sufficient; do not derive a nonce from the file name alone.

### 10.5 What Cannot Be Decrypted at Runtime

- **DEX code**: Android must load it as code; encrypting it requires a custom classloader/packer, which is out of scope and high-risk.
- **OS-resolved resources**: label, icon, theme, manifest entries.
- **The verifier itself**: if the code that checks integrity is encrypted, something must decrypt it first; that bootstrap is always exposed.

### 10.6 Failure Behavior

| Failure | Correct behavior |
|---|---|
| Manifest missing/corrupt | Controlled integrity failure; no protected assets; no crash |
| Manifest signature invalid | Controlled integrity failure; no protected assets |
| Asset ciphertext hash mismatch | Reject that asset; controlled message |
| GCM tag mismatch | Reject; no plaintext; controlled message |
| Plaintext hash mismatch | Reject; controlled message |
| Key ID unknown | Controlled failure; do not guess |
| Unsupported version | Controlled failure; do not downgrade silently |
| Storage/permission error | Existing storage error path; do not conflate with tampering |

---

## 11. Anti-Tamper Limitations

### 11.1 The Fundamental Limit

RevCore runs entirely on hardware controlled by the user. Every check, key, and branch can be observed and modified by a sufficiently capable attacker. Client-side anti-tamper is a **deterrent and cost-raiser**, not a proof. The report must not claim that interconnected guards make the app impossible to patch.

### 11.2 Realistic Attack Scenarios

| Scenario | Tooling | Current result | After proposed layers |
|---|---|---|---|
| Rename/rebrand APK | apktool, jadx, resource editor, re-sign | Succeeds; app launches | Layer 1 detects different certificate; patched check can still be removed |
| Replace launcher icon/label | apktool | Succeeds | Layer 1 signature check detects repackaging; cannot protect OS resources themselves |
| Replace ECM DB | unzip/rezip | Succeeds; app uses modified data | Layer 4/5 detect hash/signature mismatch |
| Replace MAP + manifest | unzip/rezip | Succeeds; hashes recomputed | Signed manifest detects if manifest signature is verified |
| Patch write/remap guard | jadx/smali | Succeeds | No absolute prevention; default-deny code can be patched |
| Hook crypto/verify | Frida/Xposed | Succeeds | Runtime checks raise cost; no absolute prevention |
| Extract local keys | root/debugger | Succeeds | Keystore protects device-bound state; embedded keys remain extractable |
| Replay old manifest | file replacement | Succeeds if no version check | Manifest version/anti-rollback check detects |
| Downgrade app | install older APK | Possible | v3 rotation/version policy; no remote enforcement |

### 11.3 What Each Layer Actually Buys

| Layer | Realistic benefit |
|---|---|
| APK identity pinning | Catches naive repackaging/re-signing; forces attacker to patch the check |
| Signed manifest | Catches asset swaps and accidental corruption; forces verifier patch or key theft |
| AES-GCM | Catches ciphertext modification; hides data from casual inspection |
| Keystore | Protects local state from simple extraction; device-bound |
| R8/obfuscation | Raises reverse-engineering cost |
| Native checker | Raises patching cost; adds crash/compatibility risk |
| Runtime checks | Catches casual instrumentation; false-positive risk |
| Trust gate | Makes failure explicit and non-crashing; does not prevent bypass |

### 11.4 Root, KernelSU, Custom ROM, USB Debugging, Bootloader

These conditions are **not** sufficient evidence of tampering and must not be used alone to fail the app. They are common on developer devices and legitimate power-user devices. If used at all, they should be one weak signal among many, and never the sole reason to block USB/K-Line functionality.

### 11.5 Response Policy

Recommended policy:

- **Integrity failure** → dedicated screen with a clear message, no crash, no partial data.
- **Sensitive operations** (remap/write/export of protected assets) → disabled.
- **Basic diagnostics** → retain only if the developer explicitly decides that raw identification/diagnostics should remain available under integrity failure. This is a product decision, not a security requirement.
- **No release bypass flag.** A debug-only bypass is acceptable if it is compiled out of release builds.
- **No `System.exit`, no uncaught exception, no infinite loop.**
- **No false positive from root/ROM/debug/bootloader alone.**

### 11.6 Guard Removal

If the trust gate is removed, all downstream checks can be skipped. Mitigations:

- verify protected data at the point of use, not only at startup;
- use independent checks in separate components;
- keep a minimal native checker only if the cost/benefit is justified;
- do not publish a single boolean that controls everything;
- log integrity failures locally for diagnostics, without secrets.

Even with all of this, a determined attacker can patch the app. The honest claim is: “raises the cost and detects naive modification,” not “impossible to patch.”

---

## 12. Compatibility Risks

### 12.1 Highest Deployment Risk: Signing-Key Migration

The current install identity is a debug certificate. A future release signed with a real release key **cannot update** an existing debug-signed installation. Android will reject the update with a signature mismatch. The user must uninstall the old app (losing app-private data; shared `Internal Storage/Revcore/` files remain). This must be planned and communicated before the first release-signed build.

**Mitigations:** decide the migration path before Phase 1; keep the same `applicationId` (do not change it for the filename or for signing); document the uninstall step; preserve shared storage; test the update path on a clean device and on a device with the debug build installed.

### 12.2 Risk Table

| Risk | Affected area | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| New release key cannot update debug build | Installation/update | Certain | High | Plan uninstall/migration; do not change applicationId; announce |
| R8 removes/renames needed classes | Build/runtime | Medium | High | Keep rules for Compose, usb-serial, JSON; full regression |
| v3/v4 not supported on old devices | Signing | Low | Low | Keep v2; v3 is API 28+; v4 optional |
| 16 KB page size if native added | Native/ABI | Medium | High | Align native libs; test Android 15+; avoid native in Phase 1 |
| Startup latency from verification | UX | Medium | Medium | Verify manifest only; lazy per-file checks; measure |
| Memory pressure from MAP decryption | Tuning | Low | Medium | Per-file decrypt; avoid whole-library load |
| Keystore unavailable/invalidated | Local state | Medium | Medium | Detect, recover, do not treat as tampering |
| USB permission receiver behavior | Hardware | Low | High | Do not gate USB attach; preserve receiver flow; validate extras |
| K-Line timing altered by security work | Identification | Low if disciplined | Critical | No crypto in I/O path; no timeout changes |
| ECM DB failure blocks diagnostics | Identification | Medium | High | Define degraded mode; keep raw identification |
| MAP integrity failure blocks library | Tuning | Medium | Medium | Controlled per-file failure; keep other files usable if policy allows |
| False tamper positive on legitimate devices | All | Medium | High | Do not use root/ROM/debug/bootloader alone; test matrix |
| Language/resource regressions | UI | Low | Low | Do not encrypt OS resources; run locale smoke tests |
| Debug builds fail release checks | Development | High | Medium | `BuildConfig.DEBUG` bypass compiled only for debug; separate signing |
| Storage permission changes | Export/backup | Low | Medium | Preserve existing storage paths and permission flow |
| APK size growth | Distribution | Medium | Low | Per-file encryption overhead is small; avoid native bloat |
| Test-only keys leak into production | Security | Medium | High | Separate test fixtures; scan release assets |

### 12.3 Specific Compatibility Notes

- **`applicationId` must not change.** The filename is `RevCore build DDMMYY.apk`; the package identity is independent of the filename.
- **Keep minSdk 26.** AES-GCM and Keystore are available. Do not introduce a library that raises minSdk without approval.
- **targetSdk 36** requires attention to edge-to-edge and storage policy. The current storage design uses `MANAGE_EXTERNAL_STORAGE`; changing that is out of scope for security work.
- **`extractNativeLibs=false`** is current. Adding native code requires testing this setting and 16 KB alignment.
- **The USB receiver** is registered dynamically. Security initialization must not delay `onCreate` or interfere with USB attach.
- **K-Line identification** uses a wake/baseline/fallback sequence with 700 ms class timeouts. No integrity check may run on the I/O thread or alter the sequence.
- **MAP exports/backups** are user-visible files. Do not encrypt them in place without a product decision; users expect to open them.

---

## 13. Existing-Functionality Preservation Plan

### 13.1 Immutable Behavior

The following must remain functionally unchanged:

- FTDI USB transport and USB OTG attach/detach handling.
- K-Line initialization at 10400 bps with 9600 fallback.
- Wake pulse sequence, repeated wake, and `0x1A` fallback.
- Honda ECU identification and ECM ID parsing.
- ECM ID normalization and bounded matching.
- Live Data polling, decoding, and validity gating.
- DTC read and clear behavior.
- Vehicle information display.
- MAP parsing, editor, profile matching, and read-only views that currently work.
- Tuning operations and their honest unsupported states.
- Shared `Internal Storage/Revcore/` storage and folder creation.
- Log export, backup export, and MAP export behavior.
- Existing UI navigation and language selection.

### 13.2 Files That Must Not Be Rewritten for Security

| Area | Files |
|---|---|
| USB/FTDI | `core/usb/UsbSerialLibraryTransport.kt`, `core/usb/AdapterConnectionPolicy.kt`, `core/usb/UsbTransport.kt`, `core/ftdi/FtdiSerialDriver.kt`, `core/ftdi/FtdiConstants.kt` |
| K-Line/framing | `core/protocol/KlineTransceiver.kt`, `core/protocol/KlinePacket.kt`, `core/protocol/KlineEchoFilter.kt`, `core/comm/KlineWireEngine.kt`, `core/comm/HondaFrameCodec.kt` |
| Identification | `core/protocol/HondaIdentifierParser.kt`, `data/ecu/EcuIdCanonicalizer.kt`, `data/ecu/EcmDatabase.kt` (`EcmIdentityMatcher` only) |
| Live data | `core/comm/LiveDataProfile.kt`, `core/comm/LivePollPolicy.kt`, `core/protocol/LiveTelemetry.kt` |
| DTC | `core/protocol/HondaDtcDatabase.kt`, `core/protocol/DtcReadResult.kt`, `core/protocol/ClearDtcResult.kt` |
| Protocol engine | `core/protocol/HondaProtocolEngine.kt` |
| Storage | `core/storage/RevCoreStorage.kt` (paths/behavior; security wrappers may be added around it, not inside it) |

### 13.3 Safe Integration Points

- A new trust/integrity component called from `MainViewModel.initializeSession()` after storage initialization but before protected data is used.
- A wrapper around `EcmDatabase.loadFromAssets()` that verifies/decrypts the package before parsing.
- A wrapper around `FlashProProfile.loadFromAssets()`.
- A wrapper around `BundledMapManifest`/`BundledMapStore` that verifies the signed manifest and decrypts on demand.
- A dedicated integrity state exposed to Compose, rendered as a normal screen.
- A custom `Application` class or startup initializer if a single trust initialization point is needed. Adding an `Application` class is a structural change and should be tested for startup order.

### 13.4 No Single Hardcoded ECU ID

The current implementation does **not** hardcode one ECU ID for all vehicles. `EcmIdentityMatcher` compares normalized IDs and only accepts exact or bounded prefix/suffix relations when the shorter value is at least 8 characters and the difference is at most 2. The fallback `EcmDatabase.MODELS` contains three identity records, not a universal ID. Any security change must preserve this behavior and must not replace database matching with a single hardcoded value.

### 13.5 Historical Hardware Claims

The following are historical claims, not current proof:

- FT232RL adapter over USB OTG.
- K-Line at 10400 bps.
- Honda K1AA-N02.
- ECU ID `01037A0F02`.
- Live Data.

They must be re-verified on real hardware after any change that touches startup, USB, storage, or data loading. Phase 0 did not perform hardware tests.

### 13.6 Preservation Test Matrix

| Test | Expected result |
|---|---|
| Fresh install, no adapter | App launches, terms gate, dashboard, no crash |
| Storage permission denied | Existing prompt/behavior, no crash |
| Adapter attach | USB permission flow, auto-connect state |
| Identification | Same wake/10400/9600/0x1A sequence; no new blocking check |
| Valid ECU | Dashboard/Info/Live Data/DTC behave as before |
| ECM DB load | 489 records available; matching semantics unchanged |
| MAP library | 162 entries visible with same status semantics |
| MAP open | Same editor behavior; verified package decrypts on demand |
| Export/backup | Same file paths and names; no silent overwrite |
| Language switch | Same UI language behavior |
| No adapter / wrong adapter | Same honest failure states |
| Tampered asset (negative test) | Controlled integrity failure; no crash; no partial data |

---

## 14. Recommended Implementation Sequence

This is a recommendation for approval, not an implementation performed in Phase 0. Each phase should be independently testable and reversible.

### Phase 1 — Build and Release Identity Hardening

- Generate a real release signing key **outside** the repository; keep it separate from the nine operational keys.
- Make release builds non-debuggable.
- Set `allowBackup=false` for release (or define an explicit backup policy).
- Enable R8/minification with tested keep rules.
- Enable v3 (and optionally v4) signing while retaining v2 for older devices.
- Remove unused `INTERNET`/`ACCESS_NETWORK_STATE` permissions only after confirming no dependency needs them.
- Preserve `RevCore build DDMMYY.apk`, `dist/`, archive-on-collision, and no silent overwrite.
- Do not change `applicationId`.
- Document the debug-to-release migration (uninstall required).

**Why first:** without a real identity, Layer 1 cannot be meaningful, and every downstream check can be bypassed by re-signing.

### Phase 2 — Integrity Manifest and Certificate Pinning

- Define a versioned manifest schema.
- Sign it with an offline asymmetric key; pin the public key in the app.
- Pin the release certificate digest.
- Verify once at startup and before protected data use.
- Add a controlled integrity state and screen.
- Keep a debug-only bypass compiled out of release.

**Why second:** it establishes the trust root for all data packages.

### Phase 3 — ECM Database and Profiles

- Encrypt `ecm_database.json` and `flashpro_profiles.json` with AES-256-GCM.
- Add signed manifest entries with sizes, hashes, nonces, key IDs, and versions.
- Decrypt once on `Dispatchers.IO`; verify tag and plaintext hash.
- Preserve 489 records and all matching semantics.
- Define degraded behavior for DB failure without blocking raw identification.

**Why third:** highest-value data with the simplest integration.

### Phase 4 — MAP Package

- Encrypt each of the 162 `.map` files with AES-256-GCM.
- Sign the manifest; include ciphertext/plaintext hashes and nonces.
- Verify lazily on open; do not hash the full 35 MB at startup.
- Preserve `READY`/`AMBIGUOUS_PROFILE`/`UNRECOGNIZED` and profile matching.
- Migrate away from the hardcoded FlashPro AES-128-CBC key for RevCore assets.

**Why fourth:** larger, more complex, and depends on the manifest.

### Phase 5 — Local State and Keystore

- Protect local integrity/state with a Keystore-backed key (`K5`/`K7` candidates).
- Define behavior when the key is invalidated.
- Do not store production keys in `SharedPreferences`.
- Keep terms acceptance low-risk; do not over-engineer it.

**Why fifth:** lower risk, but do it before the trust gate depends on cached state.

### Phase 6 — Final Trust Gate

- Aggregate identity, manifest, asset, and optional runtime results.
- Fail closed for sensitive operations; no crash.
- Dedicated integrity screen.
- No release bypass flag.
- No root/ROM/debug/bootloader-only verdicts.
- Ensure USB attach and K-Line identification are not blocked by unrelated checks.

**Why sixth:** it needs the earlier layers to have meaningful inputs.

### Phase 7 — Selective UI/Resource Protection (Optional)

- Move selected auxiliary images to encrypted assets only if there is a concrete threat.
- Do not encrypt launcher label/icon/theme.
- Do not encrypt all XML.
- Measure startup and rendering impact.

**Why optional:** low security value; high compatibility risk if overdone.

### Phase 8 — Native Hardening (Deferred)

- Only if measurements show a real benefit.
- Add NDK/CMake, ABI policy, 16 KB alignment, crash handling, and tests.
- Do not move the FTDI/K-Line path into native code.
- Do not make native code mandatory for basic diagnostics.

**Why deferred:** high complexity and risk; not needed for the first meaningful protection layer.

### Phase 9 — Full Regression and Release

- Run unit, instrumentation, emulator, and real-hardware tests.
- Verify APK signature, debuggable flag, backup flag, permissions, and hashes.
- Tamper-test every protected asset.
- Build the release APK, archive the previous build, and publish to `dist/`.
- Update `REVCORE_PROJECT_RULES.md` by appending rules, never overwriting.
- Produce an evidence report with actual commands and outputs.

### 14.1 Order Rationale

```
Identity → Trust root → High-value data (DB) → High-value data (MAP)
→ Local state → Gate → Cosmetic UI → Native (optional) → Regression
```

Identity must come first because every other check is meaningless if an attacker can re-sign the APK. The manifest must come before data encryption because it is the trust root for the encryption keys and hashes. The gate must come after the data layers because it needs real inputs.

---

## 15. Testing and Rollback Strategy

### 15.1 Test Levels

| Level | Scope | Evidence required |
|---|---|---|
| JVM unit | Manifest parsing, signature verification, AES-GCM encrypt/decrypt, tamper detection, key-ID handling, version handling | Test output with pass/fail counts |
| Instrumentation | Asset loading, Keystore use, trust-gate UI, storage paths | Emulator/device log + screenshots |
| Emulator | API 26, 30, 34, 36; install, launch, terms, storage, UI | Screen recording or screenshots |
| Real hardware | FT232RL, USB OTG, K-Line 10400, identification, Live Data, DTC | Device log and observed values |
| Negative/tamper | Modified asset, wrong hash, wrong key, truncated ciphertext, bad tag, replaced manifest, old manifest version | Controlled failure evidence |
| Performance | Cold start, DB load, MAP open, memory | Timing and memory measurements |
| Compatibility | Locales, storage permissions, adapter variants, update path | Matrix results |

### 15.2 Required Negative Tests

1. Flip one byte in an encrypted ECM DB → GCM tag failure → controlled error.
2. Replace the ECM DB with a valid JSON of different content → hash/signature failure.
3. Replace the manifest and a MAP file together → signature failure.
4. Use an old manifest version → anti-rollback failure.
5. Remove the manifest → controlled failure, no crash.
6. Use an unknown key ID → controlled failure, no guess.
7. Truncate a ciphertext → failure before parse.
8. Wrong AAD/file name → GCM failure.
9. Nonce reuse in a test fixture → test must reject the design.
10. Zero-byte asset → failure, no crash.
11. Malformed JSON after decryption → validator failure, no crash.
12. Repackage APK with a different certificate → Layer 1 failure (if implemented).
13. Patch the trust gate in a test copy → document that it is bypassable; do not claim prevention.
14. Run on a rooted/debuggable device without other tamper evidence → must not fail solely for that reason.

### 15.3 Regression Tests

- All existing unit tests (baseline reported 196 passing; re-run and record actual count).
- Fresh install and upgrade path.
- Terms gate.
- Storage permission paths (API 26–29 legacy, API 30+ all-files).
- USB attach/detach/permission.
- Identification sequence.
- Live Data.
- DTC read/clear.
- Vehicle info.
- MAP library and editor.
- Tuning operations and honest failures.
- Log export, backup export, MAP export.
- Language switching.
- No network access required.

### 15.4 Performance Acceptance

- Cold start must not regress beyond an agreed threshold (measure baseline first).
- ECM DB decryption must not block the main thread.
- MAP open latency must remain acceptable for a single file.
- No full-library hash/decrypt at startup.
- Memory must not hold all 35 MB of plaintext simultaneously.

### 15.5 Rollback Strategy

- **No Git:** the workspace has no `.git`. Before Phase 1, create a verified source snapshot outside the build output and record its hash.
- **Preserve builds:** keep `dist/archive/` and never silently overwrite a same-day APK. The current `publishApkToDist` already archives on collision; preserve this behavior.
- **Feature isolation:** implement each security layer behind a clearly scoped integration point so it can be reverted without touching USB/K-Line code.
- **Debug bypass:** allow a debug-only verification bypass for development, compiled out of release. Do not add a runtime toggle that ships.
- **Recovery:** if a release fails integrity verification due to a packaging error, publish a corrected build with a higher version; do not disable verification in production.
- **User data:** do not delete or overwrite `Internal Storage/Revcore/` user files during rollback.
- **Test rollback:** restore the previous APK from `dist/archive/`, install it, and confirm the app still launches and communicates.
- **Evidence:** record the exact APK hash, signature, and test results for each build.

### 15.6 Release Acceptance Checklist

- [ ] Release APK is non-debuggable.
- [ ] Release APK is signed with the intended release key, v2 + v3 (and v4 if configured).
- [ ] Certificate digest matches the pinned value.
- [ ] `allowBackup` policy is intentional.
- [ ] R8/minification enabled and tested.
- [ ] Unused network permissions removed or justified.
- [ ] Manifest signature verifies.
- [ ] ECM DB ciphertext and plaintext hashes verify.
- [ ] Profiles ciphertext and plaintext hashes verify.
- [ ] All 162 MAP files verify on open.
- [ ] No full-library decryption at startup.
- [ ] Tamper tests produce controlled failures, not crashes.
- [ ] USB/K-Line identification tested on real hardware.
- [ ] Live Data and DTC tested on real hardware.
- [ ] Storage/export/backup tested.
- [ ] Previous build archived; no silent overwrite.
- [ ] `REVCORE_PROJECT_RULES.md` updated by append only.
- [ ] Audit/implementation report includes actual command output, not claims.

---

## Appendix A — Evidence Commands and Observations

### A.1 APK Signature

Command (read-only):

```
apksigner verify --verbose --print-certs "dist/RevCore build 141126.apk"
```

Observed:

```
Verifies
Verified using v1 scheme (JAR signing): false
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): false
Verified using v3.1 scheme (APK Signature Scheme v3.1): false
Verified using v4 scheme (APK Signature Scheme v4): false
Number of signers: 1
Signer #1 certificate DN: CN=Android Debug, O=Android, C=US
Signer #1 certificate SHA-256 digest: a57a28ec69fbdacc57f41610e67481a1a3ba7a1138eaed90ed438a33372f8ab4
Signer #1 key algorithm: RSA
Signer #1 key size (bits): 2048
```

### A.2 APK Manifest

Command (read-only):

```
aapt2 dump xmltree --file AndroidManifest.xml "dist/RevCore build 141126.apk"
```

Observed:

```
android:debuggable=true
android:allowBackup=true
android:extractNativeLibs=false
```

`aapt2 dump badging` observed:

```
package: name='com.revcore.android' versionCode='1' versionName='1.0'
targetSdkVersion:'36'
application-label:'RevCore'
application-debuggable
native-code: 'arm64-v8a' 'armeabi-v7a' 'x86' 'x86_64'
```

### A.3 APK Contents

Observed native libraries:

```
lib/arm64-v8a/libandroidx.graphics.path.so
lib/armeabi-v7a/libandroidx.graphics.path.so
lib/x86/libandroidx.graphics.path.so
lib/x86_64/libandroidx.graphics.path.so
```

Observed asset entries include:

```
assets/ecm_database.json
assets/flashpro_profiles.json
assets/flashpro_maps/manifest.tsv
assets/flashpro_maps/ORIGINAL/*.map
```

### A.4 Hashes and Sizes

```
ab3bc3c938c5516d750abc15932ef22f216119e3860e8f45203f6ff1e8e837b5  dist/RevCore build 141126.apk (56,907,913 B)
7c7a2dd69b48e4257493c944b276ee7f3811c173f44c037f4d987c9b280b652a  ecm_database.json (748,580 B)
9c0be8649bdd1ef114fba6211f00f3733f4dcca0190ab9c7a173b45b3e703da4  flashpro_profiles.json (127,269 B)
189593bb99217aa2650830b29d0d9018e42c3972ccdf4278b6296366becfdd41  flashpro_maps/manifest.tsv (29,628 B)
```

### A.5 Counts

- ECM records: 489 `partNumber` occurrences.
- MAP files: 162.
- MAP manifest lines: 163 (header + 162 entries).
- MAP total bytes: 35,195,840.
- Kotlin source: 85 files, 23,624 lines.
- Test source files: 26.

### A.6 Source References

| Reference | Location |
|---|---|
| Release signing config | `app/build.gradle.kts:24-31` |
| Release minify flag | `app/build.gradle.kts:35` |
| Debug/release signing assignment | `app/build.gradle.kts:36-40` |
| Dist publishing | `app/build.gradle.kts:61-115` |
| Manifest permissions/application flags | `app/src/main/AndroidManifest.xml` |
| USB receiver registration | `MainActivity.kt:90-99` |
| Terms store | `data/local/TermsStore.kt` |
| MAP crypto key/IV | `data/flashpro/MapCrypto.kt:23-27` |
| MAP decrypt/encrypt | `data/flashpro/MapCrypto.kt:46,93` |
| MAP manifest parse/verify | `data/flashpro/BundledMapManifest.kt` |
| MAP catalog import/open | `data/flashpro/MapCatalog.kt:58,110` |
| ECM DB loader | `data/ecu/EcmDatabase.kt:259` |
| ECM identity matcher | `data/ecu/EcmDatabase.kt:17` |
| Flash engine default-deny | `data/flashpro/FlashEngine.kt:29-30,204,252` |
| Storage root and folders | `core/storage/RevCoreStorage.kt:27-125` |
| Identification sequence | `core/protocol/HondaProtocolEngine.kt:428-460` |
| DTC/live data entry points | `core/protocol/HondaProtocolEngine.kt:980,1083,1202` |
| Baud constants | `core/ftdi/FtdiConstants.kt:41-42` |
| Startup initialization | `ui/MainViewModel.kt:213-234` |

---

## Appendix B — Test Baseline and Unverified Claims

### B.1 Test Baseline

- 26 test source files are present under `app/src/test`.
- The preceding phase reported 196 passing unit tests with 0 failures.
- **This Phase 0 audit did not re-run the tests**, because Phase 0 is audit-only and a test run would invoke the build. The count is therefore **PARTIALLY VERIFIED** for the current workspace state.

### B.2 Historical Hardware Claims

The following were reported as verified in earlier work, but were **not re-tested in Phase 0**:

- FT232RL USB OTG connection.
- K-Line initialization at 10400 bps.
- Honda K1AA-N02 identification.
- ECU ID `01037A0F02`.
- Live Data.

They are **NOT VERIFIED** in this report. Any implementation phase must re-run the real-hardware regression before claiming success.

### B.3 What Was Not Audited Dynamically

- Runtime behavior under Frida/Xposed.
- Actual decrypt/encrypt execution of every MAP file.
- APK installation and upgrade on a device.
- USB/K-Line timing on hardware.
- Behavior after a real release-key migration.
- Behavior with the nine-key file (not requested or accessed).

These are explicitly out of scope for Phase 0 and must be covered in the implementation phases.

---

## Appendix C — Decisions Required from the Developer Before Phase 1

1. **Release signing identity:** Will a new release key be generated and protected offline? The current debug key cannot be a release identity.
2. **Migration:** Is an uninstall/reinstall acceptable for existing users when the signing identity changes? Shared storage survives, but app-private data does not.
3. **Manifest trust root:** Approve an asymmetric signature (Ed25519/ECDSA) for the integrity manifest, or explicitly accept the weaker K6 HMAC model.
4. **K8 definition:** What exact component does K8 protect? The current code has no component with that name.
5. **K9 definition:** Does “core package” mean auxiliary data or executable DEX? Encrypting DEX is not recommended.
6. **Integrity-failure behavior:** Should raw diagnostics remain available when protected tuning data fails verification, or should the app fail closed entirely?
7. **Debug bypass:** Confirm that a debug-only bypass is acceptable and must be compiled out of release.
8. **Network permissions:** Confirm that `INTERNET` and `ACCESS_NETWORK_STATE` can be removed without breaking a dependency.
9. **Backup policy:** Confirm `allowBackup=false` for release, or define what may be backed up.
10. **Native layer:** Confirm that Layer 6 is deferred until after non-native layers are stable.
11. **Export policy:** Should exported MAP/BIN/backup files remain plaintext user files, or be protected? Plaintext is recommended for interoperability unless the product requires otherwise.
12. **Key custody:** Who holds the release key, manifest key, and key-encryption key, and on what hardware? This is a process decision outside the app.

---

## Final Statement

This Phase 0 audit found a functional but **security-architecture-absent** Android application. The most urgent problems are not in the ECU protocol code; they are in package identity, signing, asset authenticity, and data encryption. The existing FTDI, K-Line, identification, live-data, DTC, storage, and tuning behavior can be preserved if security is added around data loading and trust decisions rather than inside the communication path.

No source code, asset, key, build configuration, UI, protocol, or APK was modified. No nine-key file was requested or accessed. No security mechanism was implemented. This report is the only artifact of Phase 0.

**STOP — Phase 0 complete. Await developer approval before Phase 1.**