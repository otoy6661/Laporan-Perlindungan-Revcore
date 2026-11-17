'use strict';
/**
 * Validator frame Honda ala RevCore (bukan spesifikasi FLASHPRO).
 * Struktur: [header, length, service, ...data, checksum]
 *  - length = ukuran frame keseluruhan
 *  - checksum = dua-komplemen jumlah byte 0..n-2
 *  - header harus salah satu dari whitelist RevCore
 */

const { sum8TwosComplement } = require('./checksum');

const ACCEPTED_HEADERS = new Set([0x72, 0x02, 0x7e, 0x7c, 0xfe, 0x7d, 0x7b]);
const NEGATIVE_RESPONSE = 0x7f;

function validateFrame(frame) {
  const errors = [];
  if (!frame || frame.length < 4) return { ok: false, errors: ['too-short'] };
  const header = frame[0] & 0xff;
  if (!ACCEPTED_HEADERS.has(header)) errors.push('bad-header');
  if ((frame[1] & 0xff) !== frame.length) errors.push('length-mismatch');
  const expected = sum8TwosComplement(frame, 0, frame.length - 1);
  if ((frame[frame.length - 1] & 0xff) !== expected) errors.push('bad-checksum');
  const service = frame[2] & 0xff;
  return {
    ok: errors.length === 0,
    errors,
    header,
    length: frame[1] & 0xff,
    service,
    negative: service === NEGATIVE_RESPONSE,
    expectedChecksum: expected,
  };
}

function buildFrame(header, service, data = []) {
  const body = [header, 0, service, ...data];
  body[1] = body.length + 1;
  body.push(sum8TwosComplement(body, 0, body.length));
  return body;
}

module.exports = { validateFrame, buildFrame, ACCEPTED_HEADERS, NEGATIVE_RESPONSE };
