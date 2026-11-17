'use strict';
/** Audit profil VomConfig RevCore: struktur, duplikat, placeholder, offset. */
const fs = require('fs');
const path = require('path');

const REQUIRED = [
  'label', 'ecmId', 'columnCount', 'rowCount', 'tpsh', 'rpmh', 'iaph',
  'feul1', 'feul2', 'feul3', 'iap', 'ig1', 'ig2', 'ig3', 'ig4',
  'limit1', 'limit2', 'limit3', 'limit4', 'limit5', 'limit6', 'limit7',
  'konversrpm', 'konversilmtr', 'o2', 'o2mask', 'o2c', 'o2cmask', 'immo', 'immomask',
  'mode0', 'mode1', 'mode2', 'mode3', 'mode4', 'bass', 'iacv', 'ect', 'iat', 'vss', 'mapp',
];

function audit(doc) {
  const profiles = doc.profiles || [];
  const problems = [];
  const byId = new Map();
  let placeholders = 0;
  let withOffsets = 0;
  let maxOffset = 0;

  if (doc.count !== profiles.length) problems.push(`count-mismatch count=${doc.count} actual=${profiles.length}`);

  profiles.forEach((p, i) => {
    for (const k of REQUIRED) {
      if (!(k in p)) problems.push(`missing:${k}@${i}`);
    }
    if (p.index !== i) problems.push(`index-order@${i} has ${p.index}`);
    if (!p.ecmId || p.ecmId === '0') placeholders++;
    if (p.ecmId) {
      if (byId.has(p.ecmId)) problems.push(`duplicate-ecmId:${p.ecmId}@${i}`);
      else byId.set(p.ecmId, i);
    }
    const offs = [p.tpsh, p.rpmh, p.iaph, p.feul1, p.iap, p.ig1, p.limit1, p.o2, p.immo, p.mode0, p.bass, p.iacv, p.ect, p.iat, p.vss, p.mapp]
      .filter((v) => typeof v === 'number' && v > 0);
    if (offs.length) withOffsets++;
    for (const v of offs) if (v > maxOffset) maxOffset = v;
  });

  return {
    count: profiles.length,
    uniqueEcmIds: byId.size,
    placeholders,
    withOffsets,
    maxOffset,
    maxOffsetHex: '0x' + maxOffset.toString(16).toUpperCase(),
    problems: problems.slice(0, 20),
    problemCount: problems.length,
  };
}

function main() {
  const root = path.resolve(__dirname, '..', '..');
  const file = path.join(root, '..', 'Qoder', 'work', 'revcore', 'app', 'src', 'main', 'assets', 'flashpro_profiles.json');
  const doc = JSON.parse(fs.readFileSync(file, 'utf8'));
  return audit(doc);
}

if (require.main === module) {
  console.log(JSON.stringify(main(), null, 2));
}

module.exports = { audit, main, REQUIRED };
