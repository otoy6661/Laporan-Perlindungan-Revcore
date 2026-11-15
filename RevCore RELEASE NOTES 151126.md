# RevCore — Release Notes

Build: `RevCore build 151126.apk`
Version: 1.0 (versionCode 1)
Package: `com.revcore.android`
Date: 15 November 2026

## JOB 1 — AFR in Live Monitor

- AFR is no longer derived on the host. The previous value came from a
  narrowband O2 voltage conversion, not from an ECU AFR/lambda channel.
- The rebuilt Honda tables (`dat17`, `dat13`, `dat11`, `dat10`, plus
  `dat16`, `dat20`, `datD1`) publish narrowband O2 voltage and short-term fuel
  trim only. No table carries an AFR or lambda field.
- Live Monitor now reports AFR as **not supported** and shows:
  “AFR TIDAK DIDUKUNG: ECU ini hanya mengirim tegangan O2 narrowband. AFR tidak
  dihitung dari RPM, TPS, atau suhu.” (English equivalent in EN mode).
- The O2 card is labelled “Narrowband O2 voltage (ECU)”.
- If a future ECU profile actually publishes AFR, the parsed value takes
  precedence; the unsupported state is only a fallback, never an override.
- No K-Line request, init timing, baud rate, or existing parameter was changed.

Evidence: Honda Beat K1A / Beat Deluxe 2020 CBS uses the flashpro-derived
narrowband tables. No ECU AFR PID is documented or observed.

## JOB 2 — Ten-Gate Integrity Protection

- Added a signed integrity policy generated at build time from the actual
  assets, identity, native libraries, and protocol constants.
- Added ten gates with a single trust anchor: the official APK signing
  certificate. No new key was generated; no operational key was reused.
- Identity gates pin package, versionCode, signer SHA-256, app label, icon, and
  non-debuggable status.
- Asset gates verify SHA-256 of the ECU database, FlashPro profiles, and MAP
  manifest; the ECU database additionally undergoes a schema check and is not
  loaded when untrusted.
- Native gate allows only `libandroidx.graphics.path.so`.
- Core gate checks framing (`72 05 71 17 01`), 10 400 baud, table inventory,
  RPM/ECT decoding, and the absence of a fabricated AFR channel.
- Inventory gate rejects added shadow assets; runtime gate re-verifies every
  60 seconds; the final gate fails closed and replaces the app surface with an
  integrity failure screen and a re-check action.
- Debug builds report signature/pin checks as BYPASS and are never presented as
  verified. Release builds require every gate to pass.
- See `RevCore SECURITY AUDIT 151126.md` for the full matrix and limitations.

## JOB 3 — Philosophy in About

- Added “Filosofi RevCore” between **Project Credits** and **Catatan** in
  Hamburger → Pengaturan → Info Aplikasi. No new menu was added.
- Content:
  - “Built to Inspire.”
  - “Not to Impersonate.”
  - “RevCore is free to inspire, not free to impersonate.”
  - “Learn from it. Build your own. Be proud of your work. Respect the original.”
  - Indonesian explanation of learning, original work, attribution, and the
    difference between freedom to learn and impersonation.

## Verified build

- Size: 39,623,151 bytes.
- SHA-256: `cd8ef5cbbdc0faebc13cc4dd39d59d8efaaaefda74221b36588201857609177d`.
- Signed with the official certificate (`SHA-256 c649cb4f…18d098`), APK
  Signature Scheme v2 + v3, one signer, not debuggable.
- The signed integrity policy inside the APK was verified with the public key of
  that certificate (`SHA256withRSA`, 165 assets, 3 protected, `debug=false`).
- Unit tests: 214 passed, 0 failed. No hardware verification was possible in
  this session (no adapter + ECU attached).
- Checksum file: `RevCore build 151126.sha256.txt`.
- Test report: `RevCore TEST REPORT 151126.md`.

## Preserved behaviour

- FTDI USB transport, K-Line init/timing/baud, ECU identification, DTC
  read/clear, Live Data tables, FlashPro MAP catalog and editor were not
  rewritten for these jobs.
- `dist/` now only receives signature-verified Release APKs; debug builds stay in
  `app/build/outputs/apk/debug/`.
- Application ID remains `com.revcore.android`, update-compatible with the
  archived 151126 official builds signed by the same key. The older
  `RevCore build 141126.apk` in `dist/` is debug-signed, so it must be
  uninstalled before installing this official build.
