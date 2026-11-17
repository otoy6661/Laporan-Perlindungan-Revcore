'use strict';
const assert = require('assert');
const cs = require('../tools/checksum');
const fv = require('../tools/frame_validator');
const dg = require('../tools/dtc_gap');
const pa = require('../tools/profile_audit');
const path = require('path');

const results = [];
function test(name, fn) {
  try {
    const detail = fn();
    results.push({ name, ok: true, detail: detail === undefined ? '' : String(detail) });
  } catch (e) {
    results.push({ name, ok: false, detail: e.message });
  }
}

test('sum8 [01 02 03] = FA', () => {
  const v = cs.sum8TwosComplement([0x01, 0x02, 0x03]);
  assert.strictEqual(v, 0xfa);
  const framed = [0x01, 0x02, 0x03, v];
  assert.strictEqual(framed.reduce((a, b) => (a + b) & 0xff, 0), 0);
  return 'FA, appended sum=0';
});

test('keihin16 [12 34 56 78] = 68AC', () => {
  const v = cs.keihin16Add([0x12, 0x34, 0x56, 0x78]);
  assert.strictEqual(v, 0x68ac);
  return '0x68AC';
});

test('inverted8 edge cases', () => {
  assert.strictEqual(cs.inverted8([0x00]), 0xff);
  assert.strictEqual(cs.inverted8([0xff]), 0x00);
  assert.strictEqual(cs.inverted8([0x01, 0x02]), 0xfc);
  return 'FF, 00, FC';
});

test('CRC16/MODBUS check "123456789" = 4B37', () => {
  const bytes = Buffer.from('123456789', 'ascii');
  const v = cs.shindengenCrc16(bytes);
  assert.strictEqual(v, 0x4b37);
  return '0x4B37';
});

test('shindengenAdditive [FF FF] = 01FE', () => {
  assert.strictEqual(cs.shindengenAdditive([0xff, 0xff]), 0x01fe);
  return '0x01FE';
});

test('frame valid 72 04 03 87', () => {
  const f = [0x72, 0x04, 0x03, 0x87];
  const r = fv.validateFrame(f);
  assert.strictEqual(r.ok, true);
  return `service=0x${r.service.toString(16)}`;
});

test('frame reject bad checksum', () => {
  const r = fv.validateFrame([0x72, 0x04, 0x03, 0x00]);
  assert.strictEqual(r.ok, false);
  assert.ok(r.errors.includes('bad-checksum'));
  return r.errors.join(',');
});

test('frame reject length mismatch', () => {
  const r = fv.validateFrame([0x72, 0x05, 0x03, 0x87]);
  assert.ok(r.errors.includes('length-mismatch'));
  return r.errors.join(',');
});

test('frame reject unknown header', () => {
  const r = fv.validateFrame([0x99, 0x04, 0x03, 0x00]);
  assert.ok(r.errors.includes('bad-header'));
  return r.errors.join(',');
});

test('buildFrame roundtrip + negative response flag', () => {
  const f = fv.buildFrame(0x72, 0x7f, [0x10]);
  const r = fv.validateFrame(f);
  assert.strictEqual(r.ok, true);
  assert.strictEqual(r.negative, true);
  return Buffer.from(f).toString('hex').toUpperCase();
});

test('DTC catalogs parse and gap computed', () => {
  const root = path.resolve(__dirname, '..', '..');
  const fp = dg.loadFlashpro(path.join(root, '05_ECU_IDENTIFICATION', 'extract', 'DTC_CODES.csv'));
  const rc = dg.loadRevCore(path.join(root, '..', 'Qoder', 'work', 'revcore', 'app', 'src', 'main', 'java', 'com', 'revcore', 'android', 'core', 'protocol', 'HondaDtcDatabase.kt'));
  assert.strictEqual(fp.length, 37);
  assert.ok(rc.length >= 15);
  const rcSet = new Set(rc.map((x) => x.code));
  const missing = fp.filter((x) => !rcSet.has(x.code));
  assert.ok(missing.length > 0);
  assert.ok(missing.every((x) => /^\d+-\d+$/.test(x.code)));
  return `flashpro=${fp.length} revcore=${rc.length} missing=${missing.length}`;
});

test('profile audit structure', () => {
  const r = pa.main();
  assert.strictEqual(r.count, 163);
  assert.ok(r.withOffsets > 100);
  return `count=${r.count} withOffsets=${r.withOffsets} unique=${r.uniqueEcmIds} problems=${r.problemCount} maxOffset=${r.maxOffsetHex}`;
});

let pass = 0;
for (const r of results) {
  if (r.ok) pass++;
  console.log(`${r.ok ? 'PASS' : 'FAIL'} | ${r.name}${r.detail ? ' | ' + r.detail : ''}`);
}
console.log(`\nRESULT ${pass}/${results.length} passed`);
if (pass !== results.length) process.exit(1);
