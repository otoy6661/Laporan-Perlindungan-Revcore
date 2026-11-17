'use strict';
/**
 * Prototipe checksum BE-12.
 * Implementasi ini adalah port 1:1 dari algoritma yang sudah ada di RevCore
 * (HondaChecksum.kt / RomBinary.kt) untuk tujuan pengujian vektor — bukan kode baru
 * untuk produksi. Tidak ada klaim bahwa algoritma ini identik dengan FLASHPRO.
 */

function sum8TwosComplement(bytes, offset = 0, length = bytes.length - offset) {
  let sum = 0;
  for (let i = offset; i < offset + length; i++) sum = (sum + (bytes[i] & 0xff)) & 0xff;
  return (256 - sum) & 0xff;
}

function keihin16Add(bytes, start = 0, end = bytes.length - 1) {
  let sum = 0;
  let i = start;
  const maxLen = Math.min(end, bytes.length - 1);
  while (i < maxLen) {
    const word = ((bytes[i] & 0xff) << 8) | (bytes[i + 1] & 0xff);
    sum = (sum + word) & 0xffff;
    i += 2;
  }
  return sum;
}

function inverted8(bytes, start = 0, end = bytes.length) {
  let sum = 0;
  const maxLen = Math.min(end, bytes.length);
  for (let i = start; i < maxLen; i++) sum = ((bytes[i] & 0xff) + sum) & 0xff;
  return sum ^ 0xff;
}

function shindengenCrc16(bytes, end = bytes.length) {
  let crc = 0xffff;
  const maxLen = Math.min(end, bytes.length);
  for (let i = 0; i < maxLen; i++) {
    crc = crc ^ (bytes[i] & 0xff);
    for (let j = 0; j < 8; j++) {
      crc = (crc & 1) !== 0 ? (crc >>> 1) ^ 0xa001 : crc >>> 1;
    }
  }
  return crc & 0xffff;
}

function shindengenAdditive(bytes, end = bytes.length) {
  let sum = 0;
  const maxLen = Math.min(end, bytes.length);
  for (let i = 0; i < maxLen; i++) sum = ((bytes[i] & 0xff) + sum) & 0xffff;
  return sum;
}

module.exports = { sum8TwosComplement, keihin16Add, inverted8, shindengenCrc16, shindengenAdditive };
